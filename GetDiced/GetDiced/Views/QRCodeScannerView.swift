//
//  QRCodeScannerView.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 12/8/24.
//

import SwiftUI
@preconcurrency import AVFoundation
import AudioToolbox
import Combine

/// QR Code scanner view using AVFoundation
struct QRCodeScannerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var scanner = QRCodeScanner()

    let onCodeScanned: (String) -> Void

    var body: some View {
        ZStack {
            // Camera preview
            QRCodeScannerRepresentable(scanner: scanner)
                .edgesIgnoringSafeArea(.all)

            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    Spacer()
                }
                .padding()

                Spacer()

                // Instructions
                VStack(spacing: 12) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.white)

                    Text("Scan QR Code")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("Position the QR code within the frame")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding()
            }
        }
        .onAppear {
            scanner.startScanning()
        }
        .onDisappear {
            scanner.stopScanning()
        }
        .onChange(of: scanner.scannedCode) { newCode in
            if let code = newCode {
                onCodeScanned(code)
                dismiss()
            }
        }
        .alert("Camera Access Required", isPresented: .constant(scanner.permissionDenied)) {
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        } message: {
            Text("Please grant camera access in Settings to scan QR codes.")
        }
    }
}

/// UIViewRepresentable wrapper for AVFoundation camera preview
struct QRCodeScannerRepresentable: UIViewRepresentable {
    @ObservedObject var scanner: QRCodeScanner

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Remove old preview layers
        uiView.layer.sublayers?.forEach { layer in
            if layer is AVCaptureVideoPreviewLayer {
                layer.removeFromSuperlayer()
            }
        }

        // Add new preview layer if available
        if let previewLayer = scanner.previewLayer {
            previewLayer.frame = uiView.bounds
            previewLayer.videoGravity = .resizeAspectFill
            uiView.layer.insertSublayer(previewLayer, at: 0)
        }
    }
}

/// QR Code scanner using AVFoundation
@MainActor
class QRCodeScanner: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?
    @Published var permissionDenied = false
    @Published var previewLayer: AVCaptureVideoPreviewLayer?

    private var captureSession: AVCaptureSession?
    private var isSetupComplete = false

    override init() {
        super.init()
        checkPermissions()
    }

    private func checkPermissions() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("Camera permission status: \(status.rawValue)")

        switch status {
        case .authorized:
            print("Camera permission: authorized")
            setupCamera()
        case .notDetermined:
            print("Camera permission: not determined, requesting...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        print("Camera permission: granted")
                        self?.setupCamera()
                    } else {
                        print("Camera permission: denied by user")
                        self?.permissionDenied = true
                    }
                }
            }
        case .denied, .restricted:
            print("Camera permission: denied or restricted")
            permissionDenied = true
        @unknown default:
            print("Camera permission: unknown status")
            permissionDenied = true
        }
    }

    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let session = AVCaptureSession()

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                print("Failed to get video capture device")
                return
            }

            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                print("Failed to create video input: \(error)")
                return
            }

            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                print("Failed to add video input to session")
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()

            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                print("Failed to add metadata output to session")
                return
            }

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)

            DispatchQueue.main.async {
                self.captureSession = session
                self.previewLayer = previewLayer
                self.isSetupComplete = true
                print("Camera setup complete, ready to scan")
            }
        }
    }

    func startScanning() {
        guard isSetupComplete, let session = captureSession else {
            // If not ready yet, retry after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.startScanning()
            }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak session] in
            session?.startRunning()
            print("Camera session started")
        }
    }

    nonisolated func stopScanning() {
        Task { @MainActor [weak self] in
            guard let self = self,
                  let session = self.captureSession,
                  session.isRunning else { return }

            // Call stopRunning synchronously to prevent race conditions during deallocation
            // AVCaptureSession can crash if stopRunning is called async while deallocating
            session.stopRunning()
            print("Camera session stopped")
        }
    }

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            // Only capture once - must update on main actor
            Task { @MainActor in
                if scannedCode == nil {
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    scannedCode = stringValue
                    stopScanning()
                }
            }
        }
    }
}
