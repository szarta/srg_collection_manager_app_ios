//
//  QRCodeGenerator.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 12/8/24.
//

import UIKit
import CoreImage

/// Utility for generating QR codes
class QRCodeGenerator {

    /// Generate a QR code image from a string
    /// - Parameters:
    ///   - string: The string to encode in the QR code
    ///   - size: The desired size of the QR code image
    /// - Returns: UIImage of the QR code, or nil if generation fails
    static func generateQRCode(from string: String, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }

        // Create CIFilter for QR code generation
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel") // High error correction

        guard let qrCodeImage = qrFilter.outputImage else {
            return nil
        }

        // Scale the QR code to the desired size
        let scaleX = size.width / qrCodeImage.extent.width
        let scaleY = size.height / qrCodeImage.extent.height
        let scale = max(scaleX, scaleY)

        let transformedImage = qrCodeImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Convert CIImage to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Generate a high-resolution QR code for sharing
    /// - Parameter string: The string to encode
    /// - Returns: UIImage of the QR code at 512x512 resolution
    static func generateHighResQRCode(from string: String) -> UIImage? {
        return generateQRCode(from: string, size: CGSize(width: 512, height: 512))
    }
}
