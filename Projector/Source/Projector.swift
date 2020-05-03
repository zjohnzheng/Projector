//
//  Projector.swift
//  Projector
//
//  Created by Zheng on 5/2/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

import UIKit


protocol ReturnCode: class {
    func returnCode(image: UIImage)
}
class Projector {
    
    weak var returnAztecCode: ReturnCode?
    static var collectionWindow: UIWindow?
        
    static func showFakeStatusBar() {
        if projectorActivated {
            
        }
    }
    
    static func makeControlsView(rootWindow: UIWindow) {
        if projectorActivated {
            #if DEBUG
            if let currentScene = rootWindow.windowScene {
                collectionWindow = OverlayControlsWindow(windowScene: currentScene)
                collectionWindow?.frame = UIScreen.main.bounds
                collectionWindow?.windowLevel = UIWindow.Level.alert + 1
                
                let collectionView = ProjectorCollectionViewController()
                collectionWindow?.rootViewController = collectionView
                collectionWindow?.makeKeyAndVisible()
                
                if let window = self.collectionWindow {
                    ProjectorConfiguration.collectionWindow = window
                }
            }
            #endif
        }
    }
    static func display(rootWindow: UIWindow, settings: ProjectorSettings) {
        if projectorActivated {
            #if DEBUG
            
            
            
            ProjectorConfiguration.rootWindow = rootWindow
            ProjectorConfiguration.settings = settings
            
            if let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
                if orientation.isLandscape {
                    ProjectorConfiguration.isLandscape = true
                } else {
                    ProjectorConfiguration.isLandscape = false
                }
            }
            
            let realOriginalAspectRatio = rootWindow.frame.size.width / rootWindow.frame.size.height
            var allowedDevices = [DeviceType]()
            let invalidRange = realOriginalAspectRatio - 0.015...realOriginalAspectRatio + 0.015
            for device in ProjectorConfiguration.devices {
                let deviceSize = device.getSize()
                let deviceAspectRatio = deviceSize.width / deviceSize.height
                if !invalidRange.contains(deviceAspectRatio) {
                    allowedDevices.append(device)
                }
            }
            ProjectorConfiguration.devices = allowedDevices
            
            var statusBarHeight = CGFloat(0)
            var originalSize = CGSize(width: rootWindow.frame.size.width, height: rootWindow.frame.size.height)
            if settings.shouldStopAtStatusBar == true {
                statusBarHeight = ProjectorConfiguration.rootWindow.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
                originalSize.height -= statusBarHeight
                ProjectorConfiguration.statusBarHeight = statusBarHeight
            }
            
            ProjectorConfiguration.originalSize = originalSize
            Projector.project(device: settings.defaultDeviceToProject)
            
            if settings.shouldShowControls {
                Projector.makeControlsView(rootWindow: rootWindow)
            }
            
            #endif
        }
    }
    static func project(device: DeviceType) {
        
        let settings = ProjectorConfiguration.settings
        ProjectorConfiguration.simulatedDevice = device
        var newSize = device.getSize()
        
        let originalSize = ProjectorConfiguration.originalSize
        
        if ProjectorConfiguration.isLandscape {
            print("LAND")
            newSize = CGSize(width: newSize.height, height: newSize.width)
        }
    
        let originalWidth = originalSize.width
        let originalHeight = originalSize.height
        let originalAspectRatio = originalWidth / originalHeight
        
        let newWidth = newSize.width
        let newHeight = newSize.height
        let newAspectRatio = newWidth / newHeight
        
        let halfOrigWidth = originalWidth / 2
        let halfOrigHeight = originalHeight / 2
        
        let halfNewWidth = newWidth / 2
        let halfNewHeight = newHeight / 2
        
        var percentOfNew = CGFloat(0)
        var percentOfOld = CGFloat(0)
        
//        var originalToNewWidthRatio =
        
        var projectedDeviceIsSkinnier = false
        if originalAspectRatio < newAspectRatio {
            projectedDeviceIsSkinnier = false
            percentOfNew = originalWidth / newWidth
            percentOfOld = newWidth / originalWidth
        } else if originalAspectRatio > newAspectRatio {
            projectedDeviceIsSkinnier = true
            percentOfNew = originalHeight / newHeight
            percentOfOld = newHeight / originalHeight
        }
        
        var newOrigin = CGPoint(x: 0, y: 0)
        
        let normalX = halfOrigWidth - halfNewWidth
        let normalY = halfOrigHeight - halfNewHeight
        
        let newWidthConvertedToOriginal = newWidth * percentOfNew
        let newHeightConvertedToOriginal = newHeight * percentOfNew
        
        print("CROPPP: width: \(newWidthConvertedToOriginal), height: \(newHeightConvertedToOriginal)")
        print("POSITION:: \(settings.position)")
        var frameForCropping = CGRect()
        switch settings.position {
        case .centered:
            newOrigin.x = normalX
            newOrigin.y = normalY
            if projectedDeviceIsSkinnier {
                let xValue = (originalWidth - newWidthConvertedToOriginal) / 2
                frameForCropping = CGRect(x: xValue, y: 0, width: percentOfNew * newWidth, height: percentOfNew * newHeight)
            } else {
                let yValue = (originalHeight - newHeightConvertedToOriginal) / 2
                frameForCropping = CGRect(x: 0, y: yValue, width: percentOfNew * newWidth, height: percentOfNew * newHeight)
            }
        case .left:
            let convertedOriginalWidth = originalHeight * newAspectRatio
            let newConverted = convertedOriginalWidth * percentOfOld
            let diff = (convertedOriginalWidth - newConverted) / 2
            newOrigin.x = diff
            newOrigin.y = normalY
            frameForCropping = CGRect(x: 0, y: 0, width: percentOfNew * newWidth, height: percentOfNew * newHeight)
        case .right:
            let convertedOriginalWidth = originalHeight * newAspectRatio
            let newConverted = convertedOriginalWidth * percentOfOld
            let normalXCoordinate = originalWidth - convertedOriginalWidth
            var diff = (convertedOriginalWidth - newConverted) / 2
            diff += normalXCoordinate
            newOrigin.x = diff
            newOrigin.y = normalY
            let xValue = originalWidth - newWidthConvertedToOriginal
            frameForCropping = CGRect(x: xValue, y: 0, width: percentOfNew * newWidth, height: percentOfNew * newHeight)
        case .top:
            let convertedOriginalHeight = originalWidth * (1 / newAspectRatio)
            let newConverted = convertedOriginalHeight * percentOfOld
            let diff = (convertedOriginalHeight - newConverted) / 2
            newOrigin.x = normalX
            newOrigin.y = diff
            frameForCropping = CGRect(x: 0, y: 0, width: percentOfNew * newWidth, height: percentOfNew * newHeight)
        case .bottom:
            let convertedOriginalHeight = originalWidth * (1 / newAspectRatio)
            let newConverted = convertedOriginalHeight * percentOfOld
            let normalYCoordinate = originalHeight - convertedOriginalHeight
            var diff = (convertedOriginalHeight - newConverted) / 2
            diff += normalYCoordinate
            newOrigin.x = normalX
            newOrigin.y = diff
            let yValue = originalHeight - newHeightConvertedToOriginal
            frameForCropping = CGRect(x: 0, y: yValue, width: percentOfNew * newWidth, height: percentOfNew * newHeight)
        }
    
        frameForCropping.origin.y += ProjectorConfiguration.statusBarHeight
        ProjectorConfiguration.currentFrameForCropping = frameForCropping
        
//        if let data = "Xiuhcoatl, the turquoise serpent of the fires".data(using: .utf8) {
//            if let aztec = CIFilter(name: "CIAztecCodeGenerator", parameters: [ "inputMessage" : data ])?.outputImage {
//
//
//
//            }
//
//        }
        
        newOrigin.y += ProjectorConfiguration.statusBarHeight
        
        UIView.animate(withDuration: 0.2, animations: {
            ProjectorConfiguration.rootWindow.transform = CGAffineTransform.identity
        }) { _ in
            UIView.animate(withDuration: 0.5, animations: {
                ProjectorConfiguration.rootWindow.frame.origin = newOrigin
                ProjectorConfiguration.rootWindow.frame.size.width = newWidth
                ProjectorConfiguration.rootWindow.frame.size.height = newHeight
                ProjectorConfiguration.rootWindow.transform = CGAffineTransform(scaleX: percentOfNew, y: percentOfNew)
            })
        }
        ProjectorConfiguration.projectedScreenPortraitSize.width = device.getSize().width
        ProjectorConfiguration.projectedScreenPortraitSize.height = device.getSize().height
    }
}
