//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Podul on 2018/1/5.
//  Copyright © 2018年 Podul. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices.UTCoreTypes
import Photos

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        
        return true
    }

    override func didSelectPost() {
        
        guard let items = self.extensionContext?.inputItems as? [NSExtensionItem] else { return }
        guard let item = items.first else { return }
        guard let dict = item.userInfo else { return }
        guard let providers = dict[NSExtensionItemAttachmentsKey] as? [NSItemProvider] else { return }
        for provider in providers {
            
//            provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String)
            provider.hasItemConformingToTypeIdentifier(kUTTypeLivePhoto as String)
//            provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String)
            
            provider.loadItem(forTypeIdentifier: ((kUTTypeLivePhoto as String)), options: nil) { (data, error) in
                print(data ?? "kUTTypeQuickTimeImage")
                print(error);
            }
            
            
            if provider.hasItemConformingToTypeIdentifier(kUTTypeQuickTimeMovie as String) {
                provider.loadItem(forTypeIdentifier: kUTTypeQuickTimeMovie as String, options: nil) { (image, error) in
                    print(image ?? "normal image")
                    print("-----normal image-----")
                }
                print("-----no kUTTypeQuickTimeMovie-----")
            }
            
            if provider.hasItemConformingToTypeIdentifier(kUTTypeLivePhoto as String) {
                provider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { (image, error) in
                    guard let url = image as? URL else { print("no live photo"); return }
                    PHLivePhoto.request(withResourceFileURLs: [url], placeholderImage: nil, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, resultHandler: { (livePhoto, info) in
                        
                        print(info);
                        print(livePhoto ?? "no live photo2")
                        print("----has live photo222------")
                    })
                    
                    
                }
                
                
                provider.loadItem(forTypeIdentifier: "public.heic", options: nil) { (data, error) in
                    
                    print(data ?? " public.heic")
                    print(error);
                    
                    //                    guard let url = image as? URL else { print("no live photo"); return }
                    //
                    //                    PHLivePhoto.request(withResourceFileURLs: [url], placeholderImage: nil, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, resultHandler: { (livePhoto, info) in
                    //
                    //                        print(info);
                    //                        print(livePhoto ?? "no live photo2")
                    //                        print("----has live photo222------")
                    //                    })
                    
                    
                }
                
                
            }
            
        }
        
//        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
