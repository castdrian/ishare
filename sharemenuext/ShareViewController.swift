//
//  ShareViewController.swift
//  sharemenuext
//
//  Created by Adrian Castro on 19.07.24.
//

import Cocoa
import Social
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    override func loadView() {
        // Do nothing to avoid displaying any UI
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        sendFileToApp()
    }

    func sendFileToApp() {
        let supportedTypes: [UTType] = [
            .quickTimeMovie,
            .mpeg4Movie,
            .png,
            .jpeg,
            .heic,
            .tiff,
            .gif,
            .webP
        ]

        if let item = (extensionContext!.inputItems as? [NSExtensionItem])?.first,
           let provider = item.attachments?.first(where: { provider in
               supportedTypes.contains(where: { provider.hasItemConformingToTypeIdentifier($0.identifier) })
           })
        {
            let typeIdentifier = supportedTypes.first { provider.hasItemConformingToTypeIdentifier($0.identifier) }?.identifier ?? UTType.data.identifier
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                var url: URL?

                if let urlItem = item as? URL {
                    url = urlItem
                } else if let data = item as? Data {
                    guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as! String) else {
                        NSLog("Failed to get shared container URL")
                        return
                    }

                    let tempDir = sharedContainerURL.appendingPathComponent("tmp", isDirectory: true)

                    let fileManager = FileManager.default
                    do {
                        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        NSLog("Failed to create temporary directory in shared container: \(error)")
                        return
                    }

                    let utType = UTType(typeIdentifier)
                    let fileExtension = utType?.preferredFilenameExtension ?? "dat"

                    let fileName = UUID().uuidString + "." + fileExtension
                    let fileURL = tempDir.appendingPathComponent(fileName)

                    do {
                        try data.write(to: fileURL)
                        url = fileURL
                    } catch {
                        NSLog("Failed to write data to shared container URL: \(error)")
                    }
                }

                if let url = url {
                    if let encodedURLString = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let shareURL = URL(string: "ishare://upload?file=\(encodedURLString)")
                    {
                        NSWorkspace.shared.open(shareURL)
                    }
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                } else {
                    NSLog("No valid URL found")
                }
            }
        }
    }
}
