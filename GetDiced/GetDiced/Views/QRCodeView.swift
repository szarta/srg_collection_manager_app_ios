//
//  QRCodeView.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 12/8/24.
//

import SwiftUI

/// View for displaying a QR code with a shareable URL
struct QRCodeView: View {
    let url: String
    let title: String
    let onDismiss: () -> Void

    @State private var qrCodeImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)

                    // QR Code
                    if let qrImage = qrCodeImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 280, height: 280)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    } else {
                        ProgressView()
                            .frame(width: 280, height: 280)
                    }

                    // URL
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Shareable Link")
                            .font(.headline)

                        Link(destination: URL(string: url)!) {
                            Text(url)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }

                        Text("Scan this QR code or visit the link to import this deck/collection.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Share Button
                    ShareLink(item: url) {
                        Label("Share Link", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .task {
                // Generate QR code
                qrCodeImage = QRCodeGenerator.generateQRCode(from: url, size: CGSize(width: 512, height: 512))
            }
        }
    }
}

#Preview {
    QRCodeView(
        url: "https://get-diced.com/shared/abc123",
        title: "Share Deck",
        onDismiss: {}
    )
}
