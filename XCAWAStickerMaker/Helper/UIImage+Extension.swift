//
//  UIImage+Extension.swift
//  XCAWAStickerMaker
//
//  Created by Alfian Losari on 14/10/23.
//

import Foundation
import UIKit

extension UIImage {
    
    func scaleToFit(targetSize: CGSize = .init(width: 512, height: 512)) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let scaledImage = renderer.image { _ in
            self.draw(in: .init(
                origin: .init(
                    x: (targetSize.width - scaledImageSize.width) / 2.0,
                    y: (targetSize.height - scaledImageSize.height) / 2.0),
                size: scaledImageSize))
        }
        return scaledImage
    }
    
    func scaledPNGData() -> Data {
        let targetSize = CGSize(
            width: size.width / UIScreen.main.scale,
            height: size.height / UIScreen.main.scale)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            self.draw(in: .init(origin: .zero, size: targetSize))
        }
        return resized.pngData()!
    }
    
    func scaledJPGData(compressionQuality: CGFloat = 0.5) -> Data {
        let targetSize = CGSize(
            width: size.width / UIScreen.main.scale,
            height: size.height / UIScreen.main.scale)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            self.draw(in: .init(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: compressionQuality)!
    }
    
}
