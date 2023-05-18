//
//  NCDocumentCamera.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 03/01/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import Foundation
import VisionKit

class NCDocumentCamera: NSObject, VNDocumentCameraViewControllerDelegate {
    static let shared: NCDocumentCamera = {
        let instance = NCDocumentCamera()
        return instance
    }()

    var viewController: UIViewController?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func openScannerDocument(viewController: UIViewController) {

        self.viewController = viewController

        guard VNDocumentCameraViewController.isSupported else { return }

        let controller = VNDocumentCameraViewController()
        controller.delegate = self

        self.viewController?.present(controller, animated: true)
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {

        for pageNumber in 0..<scan.pageCount {
            let fileName = CCUtility.createFileName("scan.png",
                                                    fileDate: Date(),
                                                    fileType: PHAssetMediaType.image,
                                                    keyFileName: NCGlobal.shared.keyFileNameMask,
                                                    keyFileNameType: NCGlobal.shared.keyFileNameType,
                                                    keyFileNameOriginal: NCGlobal.shared.keyFileNameOriginal,
                                                    forcedNewFileName: true)!
            let fileNamePath = CCUtility.getDirectoryScan() + "/" + fileName
            let image = scan.imageOfPage(at: pageNumber)
            do {
                try image.pngData()?.write(to: NSURL.fileURL(withPath: fileNamePath))
            } catch { }
        }

        controller.dismiss(animated: true) {
            if let viewController = self.viewController as? NCScan {
                viewController.loadImage()
            } else {
                self.reDirectToSave()
            }
        }
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func reDirectToSave(){
        var itemsSource: [String] = []
        
        //Data Source for collectionViewDestination
        var imagesDestination: [UIImage] = []
        var itemsDestination: [String] = []
        
        do {
            let atPath = CCUtility.getDirectoryScan()!
            let directoryContents = try FileManager.default.contentsOfDirectory(atPath: atPath)
            for fileName in directoryContents {
                if fileName.first != "." {
                    itemsSource.append(fileName)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        itemsSource = itemsSource.sorted()
        
        for fileName in itemsSource {
            
            if !itemsDestination.contains(fileName) {
                
                let fileNamePathAt = CCUtility.getDirectoryScan() + "/" + fileName
                
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: fileNamePathAt)) else { return }
                guard let image = UIImage(data: data) else { return }
                
                imagesDestination.append(image)
                itemsDestination.append(fileName)
            }
        }
        
        if imagesDestination.count > 0 {
            
            var images: [UIImage] = []
            var serverUrl = appDelegate.activeServerUrl
            
            for image in imagesDestination {
                images.append(image)
            }
            
            let formViewController = NCCreateFormUploadScanDocument.init(serverUrl: serverUrl, arrayImages: images)
            
            formViewController.modalPresentationStyle = UIModalPresentationStyle.pageSheet
            
            let navigationController = UINavigationController(rootViewController: formViewController)
            
            //controller.addChild(formViewController)
            //controller.pushViewController(formViewController, animated: true)
            self.viewController?.present(navigationController, animated: true, completion: nil)
        }
    }
}
