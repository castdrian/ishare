//
//  Constants.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
import Defaults
@testable import KeyboardShortcuts

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
    static let imgurClientId = Key<String>("imgurClientId", default: "867afe9433c0a53")
    static let captureBinary = Key<String>("captureBinary", default: "/usr/sbin/screencapture")
    static let activeCustomUploader = Key<CustomUploader?>("activeCustomUploader", default: nil)
    static let savedCustomUploaders = Key<Set<CustomUploader>?>("savedCustomUploaders")
    static let uploadType = Key<UploadType>("uploadType", default: .IMGUR)
    static let imageFormFileName = Key<String>("imageFormFileName", default: "image")
}

extension KeyboardShortcuts.Shortcut {
    var swiftUI: SwiftUI.KeyboardShortcut? {
        guard let key = keyEquivalent.first else { return nil }
        return .init(.init(key), modifiers: modifiers.swiftUI)
    }
}

extension NSEvent.ModifierFlags {
    var swiftUI: SwiftUI.EventModifiers {
        var modifiers: SwiftUI.EventModifiers = []
        if contains(.shift) {
            modifiers.insert(.shift)
        }
        if contains(.command) {
            modifiers.insert(.command)
        }
        if contains(.capsLock) {
            modifiers.insert(.capsLock)
        }
        if contains(.function) {
            modifiers.insert(.function)
        }
        if contains(.option) {
            modifiers.insert(.option)
        }
        if contains(.control) {
            modifiers.insert(.control)
        }
        return modifiers
    }
}

extension View {
    @ViewBuilder
    /// Assigns the global keyboard shortcut to the modified control.
    ///
    /// Only assigns a keyboard shortcut, if one was defined (or it has a default shortcut).
    ///
    /// - Parameter shortcut: Strongly-typed name of the shortcut
    public func keyboardShortcut(_ shortcut: KeyboardShortcuts.Name) -> some View {
        if let shortcut = (shortcut.shortcut ?? shortcut.defaultShortcut)?.swiftUI {
            self.keyboardShortcut(shortcut)
        } else {
            self
        }
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

        activeCustomUploader = uploader
        uploadType = .CUSTOM

        completion(true, nil) // Success callback
    } catch {
        completion(false, error) // Error callback
    }
}
