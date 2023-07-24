//
//  Constants.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import Zip
import Carbon
import SwiftUI
import Defaults
import Alamofire
import SwiftyJSON
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let noKeybind = Self("noKeybind")
    static let toggleMainMenu = Self("toggleMainMenu", default: .init(.s, modifiers: [.option, .command]))
    static let captureRegion = Self("captureRegion", default: .init(.p, modifiers: [.option, .command]))
    static let captureWindow = Self("captureWindow", default: .init(.p, modifiers: [.control,.option]))
    static let captureScreen = Self("captureScreen", default: .init(.x, modifiers: [.option, .command]))
    static let recordRegion = Self("recordRegion", default: .init(.z, modifiers: [.option, .command]))
    static let recordScreen = Self("recordScreen", default: .init(.z, modifiers: [.control, .option,]))
}

extension Defaults.Keys {
    static let copyToClipboard = Key<Bool>("copyToClipboard", default: true)
    static let openInFinder = Key<Bool>("openInFinder", default: false)
    static let uploadMedia = Key<Bool>("uploadMedia", default: false)
    static let capturePath = Key<String>("capturePath", default: "~/Pictures/")
    static let captureFileType = Key<FileType>("captureFileType", default: .PNG)
    static let captureFileName = Key<String>("captureFileName", default: "ishare")
    static let imgurClientId = Key<String>("imgurClientId", default: "867afe9433c0a53")
    static let captureBinary = Key<String>("captureBinary", default: "/usr/sbin/screencapture")
    static let activeCustomUploader = Key<UUID?>("activeCustomUploader", default: nil)
    static let savedCustomUploaders = Key<Set<CustomUploader>?>("savedCustomUploaders")
    static let uploadType = Key<UploadType>("uploadType", default: .IMGUR)
    static let imageFileFormName = Key<String>("imageFileFormName", default: "image")
    static let menuBarAppIcon = Key<Bool>("menuBarAppIcon", default: true)
    static let uploadDestination = Key<UploadDestination>("uploadDestination", default: .builtIn(.IMGUR))
}

extension View {
    
    public func keyboardShortcut(_ shortcut: KeyboardShortcuts.Name) -> some View {
        if let shortcut = shortcut.shortcut {
            if let keyEquivalent = shortcut.toKeyEquivalent() {
                return AnyView(self.keyboardShortcut(keyEquivalent, modifiers: shortcut.toEventModifiers()))
            }
        }
        
        return AnyView(self)
    }
    
}

extension KeyboardShortcuts.Shortcut {
    
    func toKeyEquivalent() -> KeyEquivalent? {
        let carbonKeyCode = UInt16(self.carbonKeyCode)
        let maxNameLength = 4
        var nameBuffer = [UniChar](repeating: 0, count : maxNameLength)
        var nameLength = 0
        
        let modifierKeys = UInt32(alphaLock >> 8) & 0xFF // Caps Lock
        var deadKeys: UInt32 = 0
        let keyboardType = UInt32(LMGetKbdType())
        
        let source = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            NSLog("Could not get keyboard layout data")
            return nil
        }
        let layoutData = Unmanaged<CFData>.fromOpaque(ptr).takeUnretainedValue() as Data
        let osStatus = layoutData.withUnsafeBytes {
            UCKeyTranslate($0.bindMemory(to: UCKeyboardLayout.self).baseAddress, carbonKeyCode, UInt16(kUCKeyActionDown),
                           modifierKeys, keyboardType, UInt32(kUCKeyTranslateNoDeadKeysMask),
                           &deadKeys, maxNameLength, &nameLength, &nameBuffer)
        }
        guard osStatus == noErr else {
            NSLog("Code: 0x%04X  Status: %+i", carbonKeyCode, osStatus);
            return nil
        }
        
        return KeyEquivalent(Character(String(utf16CodeUnits: nameBuffer, count: nameLength)))
    }
    
    func toEventModifiers() -> SwiftUI.EventModifiers {
        var modifiers: SwiftUI.EventModifiers = []
        
        if self.modifiers.contains(NSEvent.ModifierFlags.command) {
            modifiers.update(with: EventModifiers.command)
        }
        
        if self.modifiers.contains(NSEvent.ModifierFlags.control) {
            modifiers.update(with: EventModifiers.control)
        }
        
        if self.modifiers.contains(NSEvent.ModifierFlags.option) {
            modifiers.update(with: EventModifiers.option)
        }
        
        if self.modifiers.contains(NSEvent.ModifierFlags.shift) {
            modifiers.update(with: EventModifiers.shift)
        }
        
        if self.modifiers.contains(NSEvent.ModifierFlags.capsLock) {
            modifiers.update(with: EventModifiers.capsLock)
        }
        
        if self.modifiers.contains(NSEvent.ModifierFlags.numericPad) {
            modifiers.update(with: EventModifiers.numericPad)
        }
        
        return modifiers
    }
    
}

enum InstalledApp: String {
    case HOMEBREW
    case FFMPEG
}

func checkAppInstallation(_ app: InstalledApp) -> Bool {
    let fileManager = FileManager.default
    let homebrewPath = utsname.isAppleSilicon ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"
    let ffmpegPath = utsname.isAppleSilicon ? "/opt/homebrew/bin/ffmpeg" : "/usr/local/bin/ffmpeg"
    
    return fileManager.fileExists(atPath: app == InstalledApp.HOMEBREW ? homebrewPath : ffmpegPath)
}

extension utsname {
    static var sMachine: String {
        var utsname = utsname()
        uname(&utsname)
        return withUnsafePointer(to: &utsname.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                String(cString: $0)
            }
        }
    }
    static var isAppleSilicon: Bool {
        sMachine == "arm64"
    }
}

func selectFolder(completion: @escaping (URL?) -> Void) {
    let folderPicker = NSOpenPanel()
    folderPicker.canChooseDirectories = true
    folderPicker.canChooseFiles = false
    folderPicker.allowsMultipleSelection = false
    folderPicker.canDownloadUbiquitousContents = true
    folderPicker.canResolveUbiquitousConflicts = true
    
    folderPicker.begin { response in
        if response == .OK {
            completion(folderPicker.urls.first)
        } else {
            completion(nil)
        }
    }
}

func importIscu(_ url: URL) {
    if let keyWindow = NSApplication.shared.keyWindow {
        let alert = NSAlert()
        alert.messageText = "Import ISCU"
        alert.informativeText = "Do you want to import this custom uploader?"
        alert.addButton(withTitle: "Import")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: keyWindow) { (response) in
            if response == .alertFirstButtonReturn {
                alert.window.orderOut(nil)
                importFile(url) { success, error in
                    if success {
                        let successAlert = NSAlert()
                        successAlert.messageText = "Import Successful"
                        successAlert.informativeText = "The custom uploader has been imported successfully."
                        successAlert.addButton(withTitle: "OK")
                        successAlert.runModal()
                    } else if let error = error {
                        let errorAlert = NSAlert()
                        errorAlert.messageText = "Import Error"
                        errorAlert.informativeText = error.localizedDescription
                        errorAlert.addButton(withTitle: "OK")
                        errorAlert.runModal()
                    }
                }
            }
        }
    } else {
        let window = NSWindow(contentViewController: NSHostingController(rootView: EmptyView()))
        window.makeKeyAndOrderFront(nil)
        window.center()
        
        let alert = NSAlert()
        alert.messageText = "Import ISCU"
        alert.informativeText = "Do you want to import this custom uploader?"
        alert.addButton(withTitle: "Import")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { (response) in
            if response == .alertFirstButtonReturn {
                alert.window.orderOut(nil)
                importFile(url) { success, error in
                    if success {
                        let successAlert = NSAlert()
                        successAlert.messageText = "Import Successful"
                        successAlert.informativeText = "The custom uploader has been imported successfully."
                        successAlert.addButton(withTitle: "OK")
                        successAlert.runModal()
                    } else if let error = error {
                        let errorAlert = NSAlert()
                        errorAlert.messageText = "Import Error"
                        errorAlert.informativeText = error.localizedDescription
                        errorAlert.addButton(withTitle: "OK")
                        errorAlert.runModal()
                    }
                }
            }
            
            window.orderOut(nil)
        }
    }
}

func importFile(_ url: URL, completion: @escaping (Bool, Error?) -> Void) {
    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let uploader = try decoder.decode(CustomUploader.self, from: data)
        
        @Default(.savedCustomUploaders) var savedCustomUploaders
        @Default(.activeCustomUploader) var activeCustomUploader
        @Default(.uploadType) var uploadType
        
        if var uploaders = savedCustomUploaders {
            uploaders.remove(uploader)
            uploaders.insert(uploader)
            savedCustomUploaders = uploaders
        } else {
            savedCustomUploaders = Set([uploader])
        }
        
        activeCustomUploader = uploader.id
        uploadType = .CUSTOM
        
        completion(true, nil) // Success callback
    } catch {
        completion(false, error) // Error callback
    }
}

func selfUpdate() {
    guard let releasesURL = URL(string: "https://api.github.com/repos/castdrian/ishare/releases") else {
        print("Invalid releases URL")
        return
    }
    
    AF.request(releasesURL).responseDecodable(of: JSON.self) { response in
        switch response.result {
        case .success(let value):
            let json = JSON(value)
            
            // Check if the response contains any releases
            guard let releases = json.array else {
                print("No releases found")
                return
            }
            
            // Check if there is at least one release
            guard let latestRelease = releases.first else {
                print("No latest release found")
                return
            }
            
            // Extract the creation date of the latest release
            if let createdAtString = latestRelease["created_at"].string,
               let releaseCreationDate = ISO8601DateFormatter().date(from: createdAtString) {
                print("Latest release creation date: \(releaseCreationDate)")
                
                // Get the bundle's creation date
                if let executableURL = Bundle.main.executableURL,
                   let bundleCreationDate = (try? executableURL.resourceValues(forKeys: [.creationDateKey]))?.creationDate {
                    print("Bundle creation date: \(bundleCreationDate)")
                    
                    // Compare the dates
                    let comparisonResult = releaseCreationDate.compare(bundleCreationDate)
                    
                    if comparisonResult == .orderedDescending {
                        print("Bundle is older than the latest release")
                        let alert = NSAlert()
                        alert.messageText = "Update Available"
                        alert.informativeText = "An update is available. Do you want to update ishare?"
                        alert.addButton(withTitle: "Yes")
                        alert.addButton(withTitle: "No")
                        
                        let modalResponse = alert.runModal()
                        if modalResponse == .alertFirstButtonReturn {
                            if let assetURL = latestRelease["assets"][0]["browser_download_url"].url {
                                print("Latest release asset URL: \(assetURL)")
                                downloadAndReplaceApp(assetURL: assetURL)
                            } else {
                                print("No assets found for the latest release")
                            }
                        }
                    } else if comparisonResult == .orderedAscending {
                        print("Bundle is newer than the latest release")
                        showAlert(title: "Up to Date", message: "Your version of ishare is up to date.")
                    } else {
                        print("Bundle and latest release have the same creation date")
                        showAlert(title: "Up to Date", message: "Your version of ishare is up to date.")
                    }
                }
            } else {
                print("Failed to extract release creation date")
                showAlert(title: "Error", message: "Failed to extract release creation date.")
            }
            
        case .failure(let error):
            print("Request failed with error: \(error)")
            showAlert(title: "Error", message: "Request failed with error: \(error)")
        }
    }
}

func showAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

func downloadAndReplaceApp(assetURL: URL) {
    let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("ishare.zip")
    
    AF.download(assetURL, to: { _, _ in (destinationURL, [.removePreviousFile]) })
        .response { response in
            if response.error == nil {
                if response.fileURL != nil {
                    replaceAppWithDownloadedArchive(zipURL: destinationURL)
                } else {
                    showAlert(title: "Download Failed", message: "Failed to download the update archive.")
                }
            } else {
                showAlert(title: "Download Failed", message: "Failed to download the update: \(response.error!.localizedDescription)")
            }
        }
}

func replaceAppWithDownloadedArchive(zipURL: URL) {
    let fileManager = FileManager.default
    let appSupportDirectoryURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let extractedAppDirectoryURL = appSupportDirectoryURL.appendingPathComponent("ishare_extracted")
    
    do {
        try fileManager.createDirectory(at: extractedAppDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        
        try Zip.unzipFile(zipURL, destination: extractedAppDirectoryURL, overwrite: true, password: nil)
        
        let extractedAppURLs = try fileManager.contentsOfDirectory(at: extractedAppDirectoryURL, includingPropertiesForKeys: nil)
        print(extractedAppURLs)
        guard let extractedAppURL = extractedAppURLs.first(where: { $0.pathExtension == "app" }) else {
            print("Failed to find extracted ishare.app")
            showAlert(title: "Update Failed", message: "Failed to find the extracted iShare app.")
            return
        }
        
        let extractedAppBundleURL = extractedAppURL.appendingPathComponent("Contents").appendingPathComponent("MacOS")
        let extractedAppExecutableURL = extractedAppBundleURL.appendingPathComponent("ishare")
        
        guard fileManager.fileExists(atPath: extractedAppExecutableURL.path) else {
            print("Failed to find extracted ishare.app executable")
            showAlert(title: "Update Failed", message: "Failed to find the extracted ishare app executable.")
            return
        }
        
        let currentAppURL = Bundle.main.bundleURL
        let currentAppBundleURL = currentAppURL.appendingPathComponent("Contents").appendingPathComponent("MacOS")
        let currentAppExecutableURL = currentAppBundleURL.appendingPathComponent("ishare")
        
        
        do {
            _ = try fileManager.replaceItemAt(currentAppExecutableURL, withItemAt: extractedAppExecutableURL)
            
            showAlert(title: "Update Successful", message: "ishare has been updated successfully. The app will now restart.")
            
            let appURL = Bundle.main.bundleURL
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open(appURL, configuration: configuration) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    NSApplication.shared.terminate(nil)
                }
            }
            
        } catch {
            print("Failed to replace the current ishare.app: \(error.localizedDescription)")
            showAlert(title: "Update Failed", message: "Failed to replace the current ishare app: \(error.localizedDescription)")
        }
        
        try fileManager.removeItem(at: extractedAppDirectoryURL)
    } catch {
        print("Failed to extract the update archive: \(error.localizedDescription)")
        showAlert(title: "Update Failed", message: "Failed to extract the update archive: \(error.localizedDescription)")
    }
}

struct Contributor: Codable {
    let login: String
    let avatarURL: URL

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
    }
}

func fetchContributors(completion: @escaping ([Contributor]?) -> Void) {
    guard let contributorsURL = URL(string: "https://api.github.com/repos/castdrian/ishare/contributors") else {
        completion(nil)
        return
    }
    
    AF.request(contributorsURL).responseDecodable(of: [Contributor].self) { response in
        switch response.result {
        case .success(let contributors):
            completion(contributors)
        case .failure(let error):
            print("Failed to fetch contributors: \(error)")
            completion(nil)
        }
    }
}

let AppIcon: NSImage = {
        let ratio = $0.size.height / $0.size.width
        $0.size.height = 18
        $0.size.width = 18 / ratio
        return $0
    }(NSImage(named: "AppIcon")!)

func exportUserDefaults() {
    let settings = UserDefaults.standard.dictionaryRepresentation()
    let data: Data
    do {
        data = try PropertyListSerialization.data(fromPropertyList: settings, format: .binary, options: 0)
    } catch {
        print("Error exporting UserDefaults: \(error)")
        return
    }
    
    let savePanel = NSSavePanel()
    savePanel.title = "Export Settings"
    savePanel.allowedContentTypes = [.propertyList]
    
    savePanel.begin { result in
        if result == .OK, let fileURL = savePanel.url {
            do {
                try data.write(to: fileURL)
                print("UserDefaults exported to file: \(fileURL.absoluteString)")
            } catch {
                print("Error exporting UserDefaults: \(error)")
            }
        }
    }
}

func importUserDefaults() {
    let openPanel = NSOpenPanel()
    openPanel.title = "Import Settings"
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseFiles = true
    openPanel.canChooseDirectories = false
    openPanel.allowedContentTypes = [.propertyList]

    openPanel.begin { result in
        if result == .OK, let fileURL = openPanel.url {
            do {
                let data = try Data(contentsOf: fileURL)
                if let settings = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                    UserDefaults.standard.setPersistentDomain(settings, forName: Bundle.main.bundleIdentifier!)
                    print("UserDefaults imported from file: \(fileURL.absoluteString)")
                } else {
                    print("Error: Unable to import settings. Invalid data format.")
                }
            } catch {
                print("Error importing UserDefaults: \(error)")
            }
        }
    }
}
