//
//  NCCreateFormUploadConflict+Alert.swift
//  Nextcloud
//
//  Created by A107161739 on 04/08/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation

extension NCCreateFormUploadConflict{
    func showSingleFileConflictAlert() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {

                let conflictAlert = UIAlertController(title: NSLocalizedString("_single_file_conflict_title_", comment: ""), message: "", preferredStyle: .alert)

                conflictAlert.addAction(UIAlertAction(title: NSLocalizedString("_replace_action_title_", comment: ""), style: .default, handler: { (_) in
                    for metadata in self.metadatasUploadInConflict {
                        self.metadatasNOConflict.append(metadata)
                    }
                    
                    self.metadatasNOConflict.append(contentsOf: self.metadatasMOV)
                    if self.delegate != nil {
                        
                        self.delegate?.dismissCreateFormUploadConflict(metadatas: self.metadatasNOConflict)
                        
                    } else {
                        
                        self.appDelegate.networkingProcessUpload?.createProcessUploads(metadatas: self.metadatasNOConflict)
                    }
                    self.dismiss(animated: true, completion: nil)
                    
                    //self.appDelegate.networkingProcessUpload?.createProcessUploads(metadatas: self.metadatasNOConflict)
                    self.dismiss(animated: true, completion: nil)
                }))
                
                conflictAlert.addAction(UIAlertAction(title: NSLocalizedString("_keep_both_action_title_", comment: ""), style: .default, handler: { (_) in
                    for metadata in self.metadatasUploadInConflict {
                        let fileNameMOV = (metadata.fileNameView as NSString).deletingPathExtension + ".mov"
                        
                        let newFileName = NCUtilityFileSystem.shared.createFileName(metadata.fileNameView, serverUrl: metadata.serverUrl, account: metadata.account)
                        metadata.ocId = UUID().uuidString
                        metadata.fileName = newFileName
                        metadata.fileNameView = newFileName
                        
                        self.metadatasNOConflict.append(metadata)
                        
                        // MOV
                        for metadataMOV in self.metadatasMOV {
                            if metadataMOV.fileName == fileNameMOV {
                                
                                let oldPath = CCUtility.getDirectoryProviderStorageOcId(metadataMOV.ocId, fileNameView: metadataMOV.fileNameView)
                                let newFileNameMOV = (newFileName as NSString).deletingPathExtension + ".mov"
                                
                                metadataMOV.ocId = UUID().uuidString
                                metadataMOV.fileName = newFileNameMOV
                                metadataMOV.fileNameView = newFileNameMOV
                                
                                let newPath = CCUtility.getDirectoryProviderStorageOcId(metadataMOV.ocId, fileNameView: newFileNameMOV)
                                CCUtility.moveFile(atPath: oldPath, toPath: newPath)
                                
                                break
                            }
                        }
                    }
    //
    //                self.metadatasNOConflict.append(contentsOf: self.metadatasMOV)
    //
    //                self.appDelegate.networkingProcessUpload?.createProcessUploads(metadatas: self.metadatasNOConflict)
                    if self.delegate != nil {
                        
                        self.delegate?.dismissCreateFormUploadConflict(metadatas: self.metadatasNOConflict)
                        
                    } else {
                        
                        self.appDelegate.networkingProcessUpload?.createProcessUploads(metadatas: self.metadatasNOConflict)
                    }
                    self.dismiss(animated: true, completion: nil)
                }))
                
                conflictAlert.addAction(UIAlertAction(title: NSLocalizedString("_cancel_keep_existing_action_title_", comment: ""), style: .cancel, handler: { (_) in
                    self.dismiss(animated: true, completion: nil)
                }))
                
    //            conflictAlert.addAction(UIAlertAction(title: "More", style: .default, handler: { (_) in
    //                if let conflict = UIStoryboard.init(name: "NCCreateFormUploadConflict", bundle: nil).instantiateInitialViewController() as? NCCreateFormUploadConflict {
    //
    //                    conflict.serverUrl = self.serverUrl
    //                    conflict.metadatasNOConflict = metadatasNOConflict
    //                    conflict.metadatasMOV = metadatasMOV
    //                    conflict.metadatasUploadInConflict = metadatasUploadInConflict
    //
    //                    self.appDelegate.window?.rootViewController?.present(conflict, animated: true, completion: nil)
    //                }
    //            }))
                
                //self.present(conflictAlert, animated: true, completion: nil)
               
                self.present(conflictAlert, animated: true)
            }

            }
}
