//
//  FinderSync.swift
//  ishare-actions
//
//  Created by Adrian Castro on 18.07.23.
//

import FinderSync

class FinderSync: FIFinderSync {
    
    override init() {
        super.init()
        
        NSLog("FinderSync() launched from %@", Bundle.main.bundlePath as NSString)
        print("hello")
        
        // Set up the directory we are syncing
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")
        menu.addItem(withTitle: "Upload with ishare", action: #selector(uploadClicked(_:)), keyEquivalent: "")
        return menu
    }
    
    @objc func uploadClicked(_ sender: AnyObject?) {
        guard let target = FIFinderSyncController.default().targetedURL() else {
            NSLog("Failed to obtain targeted URL")
            return
        }
        
        print(target)
        
        // Perform your desired action with the file URL here
    }
}
