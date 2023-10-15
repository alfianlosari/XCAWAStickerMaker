//
//  ViewModel.swift
//  XCAWAStickerMaker
//
//  Created by Alfian Losari on 14/10/23.
//

import Foundation
import Observation
import SwiftUI
import CoreImage
import UIKit
import SwiftWebP

@Observable
class ViewModel {
    
    private static let PasteboardStickerPackDataType = "net.whatsapp.third-party.sticker-pack"
    private static let whatsAPPURL = URL(string: "whatsapp://stickerPack")!
    private static let PasteboardExpirationSeconds: TimeInterval = 60
    let serialQueue = DispatchSerialQueue(label: "com.xca.bgserial")
    var trayIcon = Sticker(isTrayIcon: true)
    var stickers: [Sticker] = (0...29).map { i in Sticker(pos: i) }
    
    var showOriginalImage = false
    let imageHelper = ImageVisionHelper()
    
    var isAbleToExportAsStickers: Bool {
        let stickersCount = self.stickers.filter { $0.outputImage != nil }.count
        return stickersCount > 2 && trayIcon.outputImage != nil
    }
    
    func onInputImageSelected(_ image: CIImage, sticker: Sticker) {
        self.serialQueue.async { [unowned self] in
            let inputCIImage = image
            let inputImage = UIImage(cgImage: imageHelper.render(ciImage: inputCIImage))
            let outputImage = self.removeImageBackground(input: inputCIImage)
            var sticker = sticker
            
            let imageData = ImageData(inputCIImage: inputCIImage, inputImage: inputImage, outputImage: outputImage)
            sticker.state = .selected(imageData)
            
            DispatchQueue.main.async { [unowned self] in
                if sticker.isTrayIcon {
                    self.trayIcon = sticker
                } else {
                    self.stickers[sticker.pos] = sticker
                }
            }
           
        }
      
    }
    
    func removeImageBackground(input: CIImage) -> UIImage? {
        guard let maskedImage = imageHelper.removeBackground(from: input, croppedToInstanceExtent: true) else {
            return nil
        }
        return UIImage(cgImage: imageHelper.render(ciImage: maskedImage))
    }
    
    func sendToWhatsApp() {
        guard isAbleToExportAsStickers,
              let trayOutputImage = trayIcon.imageData?.outputImage
        else { return }
        
        let outputImageTrayData = trayOutputImage.scaleToFit(targetSize: .init(width: 96, height: 96))
            .scaledPNGData()
        print("Tray bytes size \(outputImageTrayData.count)")
        
        var json: [String: Any] = [:]
        json["identifier"] = "xcaID"
        json["name"] = "XCA"
        json["publisher"] = "Alfian Losari"
        json["tray_image"] = outputImageTrayData.base64EncodedString()
        
        var stickersArray: [[String: Any]] = []
        let stickersImage = self.stickers.compactMap { $0.imageData?.outputImage }
        
        for image in stickersImage {
            var stickersDict = [String: Any]()
            let outputPngData = image.scaleToFit(targetSize: .init(width: 512, height: 512))
                .scaledPNGData()
            print("Sticker size \(outputPngData.count)")
            
            if let imageData = WebPEncoder().encodePNG(data: outputPngData) {
                stickersDict["image_data"] = imageData.base64EncodedString()
                stickersDict["emojis"] = ["🤣"]
                stickersArray.append(stickersDict)
            }
        }
        json["stickers"] = stickersArray
        
        var jsonWithAppStoreLink: [String: Any] = json
        jsonWithAppStoreLink["ios_app_store_link"] = ""
        jsonWithAppStoreLink["android_play_store_link"] = ""
        
        guard let dataToSend = try? JSONSerialization.data(withJSONObject: jsonWithAppStoreLink, options: []) else {
            return
        }
        
        let pasteboard = UIPasteboard.general
        pasteboard.setItems([[ViewModel.PasteboardStickerPackDataType: dataToSend]],
                            options: [
                                UIPasteboard.OptionsKey.localOnly: true,
                                UIPasteboard.OptionsKey.expirationDate: Date(timeIntervalSinceNow: ViewModel.PasteboardExpirationSeconds)
                            ])
        
        
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(URL(string: "whatsapp://")!) {
                UIApplication.shared.open(ViewModel.whatsAPPURL)
            }
        }
    }
    
}
