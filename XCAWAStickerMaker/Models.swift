//
//  Models.swift
//  XCAWAStickerMaker
//
//  Created by Alfian Losari on 14/10/23.
//

import Foundation
import CoreImage
import UIKit
import SwiftUI

enum StickerState {
    case none
    case generating(Task<Void, Never>)
    case completed(ImageData)
    case failure(Error)
}

struct ImageData {
    var inputCIImage: CIImage?
    var inputImage: UIImage
    var outputImage: UIImage?
}

struct Sticker: Identifiable {
    
    let id = UUID()
    var pos: Int = 0
    var state = StickerState.none
    var isTrayIcon = false

    var imageData: ImageData? {
        if case let .completed(imageData) = state {
            return imageData
        }
        return nil
    }
    
    var isGeneratingImage: Bool {
        if case .generating = state {
            return true
        }
        return false
    }
    
    var inputImage: Image? {
        guard let imageData else { return nil }
        return Image(uiImage: imageData.inputImage)
    }
    
    var outputImage: Image? {
        guard let imageData, let outputImage = imageData.outputImage else { return nil }
        return Image(uiImage: outputImage)
    }
    
    var errorText: String? {
        if case let .failure(error) = state {
            return error.localizedDescription
        }
        return nil
    }
    
    var ongoingTask: Task<Void, Never>? {
        if case let .generating(task) = state {
            return task
        }
        return nil
    }
    
    func cancelOngoingTask() {
        self.ongoingTask?.cancel()
    }
   
}
