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
import XCAOpenAIClient
import PhotosUI

@Observable
class ViewModel {
    
    private static let PasteboardStickerPackDataType = "net.whatsapp.third-party.sticker-pack"
    private static let whatsAPPURL = URL(string: "whatsapp://stickerPack")!
    private static let PasteboardExpirationSeconds: TimeInterval = 60
    let serialQueue = DispatchSerialQueue(label: "com.xca.bgserial")
    var trayIcon = Sticker(isTrayIcon: true)
    var stickers: [Sticker] = (0...29).map { i in Sticker(pos: i) }
    
    let openAIClient = OpenAIClient(apiKey: "YOUR_API_KEY")
    
    var showOriginalImage = false
    var shouldPresentPhotoPicker = false
    var selectedPhotoPickerItem: PhotosPickerItem?
    var selectedStickerForPhotoPicker: Sticker?
    var promptText = ""
    let minImagesInBatch = 3
    let maxImagesInBatch = 30
    var imagesInBatch: Double = 3
    var isHD = false
    var isVivid = true
    var isAISectionExpanded = true
    
    let imageHelper = ImageVisionHelper()
    
    var isPromptValid: Bool { promptText.trimmingCharacters(in: .whitespacesAndNewlines).count > 1}
    
    var isAbleToExportAsStickers: Bool {
        let stickersCount = self.stickers.filter { $0.outputImage != nil }.count
        return stickersCount > 2 && trayIcon.outputImage != nil
    }
    
    func deleteImage(sticker: Sticker) {
        updateSticker(sticker) { $0.state = .none }
    }
    
    func generateDallE3ImagesInBatch() {
        guard promptText.count > 1 else { return }
        (0..<Int(imagesInBatch)).forEach { index in
            self.stickers[index].cancelOngoingTask()
            generateDallE3Image(sticker: self.stickers[index])
        }
    }
    
    func generateDallE3ImageTask(prompt: String, sticker: Sticker) -> Task<Void, Never> {
        Task {
            do {
                let imageResponse = try await self.openAIClient.generateDallE3Image(
                    prompt: prompt, quality: isHD ? .hd : .standard, style: isVivid ? .vivid : .natural)
                try Task.checkCancellation()
                guard let urlString = imageResponse.url,
                      let url = URL(string: urlString)
                else {
                    throw "Image response is null"
                }
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = CIImage(data: data) else {
                    throw "failed to download image"
                }
                let imageData = self.generateImageData(image)
                try Task.checkCancellation()
                self.updateSticker(sticker, shouldSwitchToUIThread: true) {
                    $0.state = .completed(imageData)
                    if self.trayIcon.imageData == nil {
                        self.updateSticker(self.trayIcon) {
                            $0.state = .completed(imageData)
                        }
                    }
                }
            } catch {
                if error is CancellationError { return }
                self.updateSticker(sticker, shouldSwitchToUIThread: true) {
                    $0.state = .failure(error)
                }
            }
        }
    }
    
    func generateDallE3Image(sticker: Sticker) {
        guard isPromptValid else { return }
        let task = generateDallE3ImageTask(prompt: promptText, sticker: sticker)
        self.updateSticker(sticker) {
            $0.state = .generating(task)
        }
    }
    
    func generateImageData(_ image: CIImage) -> ImageData {
        let inputCIImage = image
        let inputImage = UIImage(cgImage: imageHelper.render(ciImage: inputCIImage))
        let outputImage = self.removeImageBackground(input: inputCIImage)
        let imageData = ImageData(inputCIImage: inputCIImage, inputImage: inputImage, outputImage: outputImage)
        return imageData
    }
    
    func onInputImageSelected(_ image: CIImage, sticker: Sticker) {
        let task = Task {
            do {
                let imageData = self.generateImageData(image)
                try Task.checkCancellation()
                self.updateSticker(sticker) {
                    $0.state = .completed(imageData)
                }
            } catch let error {
                if error is CancellationError { return }
                self.updateSticker(sticker) {
                    $0.state = .failure(error)
                }
            }
        }
        self.updateSticker(sticker) { $0.state = .generating(task) }
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
    
    func updateSticker(_ sticker: Sticker, shouldSwitchToUIThread: Bool = false, updateHandler: (( _ sticker: inout Sticker) -> Void)? = nil) {
        func update() {
            var sticker = sticker
            updateHandler?(&sticker)
            if sticker.isTrayIcon {
                self.trayIcon = sticker
            } else {
                self.stickers[sticker.pos] = sticker
            }
        }
        
        if shouldSwitchToUIThread {
            DispatchQueue.main.async { update() }
        } else {
            update()
        }
    }
    
}
