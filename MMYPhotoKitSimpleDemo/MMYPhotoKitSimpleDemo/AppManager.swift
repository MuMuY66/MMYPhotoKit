//
//  AppManager.swift
//  MMYPhotoKitSimpleDemo
//
//  Created by alimysoyang on 7/5/25.
//

import Foundation
import MMYPhotoKit
import UIKit

@MainActor
@Observable
class AppManager {
    var sourceImage: UIImage?
    
    var destinationImage: UIImage?
    
    private let photoKitManager = MMYPhotoKitManager()
    
    func photoProcess(_ backgroundColor: UIColor) {
        guard let sourceImage = sourceImage else {
            return
        }
        
        destinationImage = photoKitManager.photoProcess(sourceImage, backgroundColor: backgroundColor)
    }
}
