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
import AVFoundation
import KeyboardShortcuts
import BezelNotification
import ScreenCaptureKit

extension KeyboardShortcuts.Name {
    static let noKeybind = Self("noKeybind")
    static let toggleMainMenu = Self("toggleMainMenu", default: .init(.s, modifiers: [.option, .command]))
    static let captureRegion = Self("captureRegion", default: .init(.p, modifiers: [.option, .command]))
    static let captureWindow = Self("captureWindow", default: .init(.p, modifiers: [.control,.option]))
    static let captureScreen = Self("captureScreen", default: .init(.x, modifiers: [.option, .command]))
    static let recordScreen = Self("recordScreen", default: .init(.z, modifiers: [.control, .option]))
    static let recordGif = Self("recordGif", default: .init(.g, modifiers: [.control, .option]))
}

extension Defaults.Keys {
    static let showMainMenu = Key<Bool>("showMainMenu", default: false)
    static let copyToClipboard = Key<Bool>("copyToClipboard", default: true)
    static let openInFinder = Key<Bool>("openInFinder", default: false)
    static let saveToDisk = Key<Bool>("saveToDisk", default: true)
    static let uploadMedia = Key<Bool>("uploadMedia", default: false)
    static let capturePath = Key<String>("capturePath", default: "~/Pictures/")
    static let recordingPath = Key<String>("recordingPath", default: "~/Pictures/")
    static let captureFileType = Key<FileType>("captureFileType", default: .PNG)
    static let captureFileName = Key<String>("captureFileName", default: "ishare")
    static let recordingFileName = Key<String>("recordingFileName", default: "ishare")
    static let imgurClientId = Key<String>("imgurClientId", default: "867afe9433c0a53")
    static let captureBinary = Key<String>("captureBinary", default: "/usr/sbin/screencapture")
    static let activeCustomUploader = Key<UUID?>("activeCustomUploader", default: nil)
    static let savedCustomUploaders = Key<Set<CustomUploader>?>("savedCustomUploaders")
    static let uploadType = Key<UploadType>("uploadType", default: .IMGUR)
    static let uploadDestination = Key<UploadDestination>("uploadDestination", default: .builtIn(.IMGUR))
    static let showRecordingPreview = Key<Bool>("showRecordingPreview", default: true)
    static let recordAudio = Key<Bool>("recordAudio", default: true)
    static let recordMP4 = Key<Bool>("recordMP4", default: true)
    static let useHEVC = Key<Bool>("useHEVC", default: false)
    static let compressVideo = Key<Bool>("compressVideo", default: false)
    static let builtInShare = Key<SharingPreferences>("builtInShare", default: .init())
    static let toastTimeout = Key<Double>("toastTimeout", default: 2)
    static let menuBarIcon = Key<MenuBarIcon>("menuBarIcon", default: .DEFAULT)
    static let uploadHistory = Key<Array<String>>("uploadHistory", default: [])
    static let ignoredBundleIdentifiers = Key<Array<String>>("ignoredApps", default: [])
    static let aussieMode = Key<Bool>("aussieMode", default: false)
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
            BezelNotification.show(messageText: "\(error)", icon: ToastIcon)
            completion(nil)
        }
    }
}

let AppIcon: NSImage = {
    let appIconImage = NSImage(named: "AppIcon")!
    let ratio = appIconImage.size.height / appIconImage.size.width
    let newSize = NSSize(width: 18, height: 18 / ratio)
    let resizedImage = NSImage(size: newSize)
    resizedImage.lockFocus()
    appIconImage.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: appIconImage.size), operation: .copy, fraction: 1.0)
    resizedImage.unlockFocus()
    return resizedImage
}()

let GlyphIcon: NSImage = {
    let appIconImage = NSImage(named: "GlyphIcon")!
    let ratio = appIconImage.size.height / appIconImage.size.width
    let newSize = NSSize(width: 18, height: 18 / ratio)
    let resizedImage = NSImage(size: newSize)
    resizedImage.lockFocus()
    appIconImage.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: appIconImage.size), operation: .copy, fraction: 1.0)
    resizedImage.unlockFocus()
    return resizedImage
}()

let ImgurIcon: NSImage = {
    let appIconImage = NSImage(named: "Imgur")!
    let ratio = appIconImage.size.height / appIconImage.size.width
    let newSize = NSSize(width: 18, height: 18 / ratio)
    let resizedImage = NSImage(size: newSize)
    resizedImage.lockFocus()
    appIconImage.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: appIconImage.size), operation: .copy, fraction: 1.0)
    resizedImage.unlockFocus()
    return resizedImage
}()

let ToastIcon: NSImage = {
    let toastIconImage = NSImage(named: "AppIcon")!
    let ratio = toastIconImage.size.height / toastIconImage.size.width
    let newSize = NSSize(width: 100, height: 100 / ratio)
    let resizedImage = NSImage(size: newSize)
    resizedImage.lockFocus()
    toastIconImage.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: toastIconImage.size), operation: .copy, fraction: 1.0)
    resizedImage.unlockFocus()
    return resizedImage
}()

func exportUserDefaults() {
    let settings = UserDefaults.standard.dictionaryRepresentation()
    let data: Data
    do {
        data = try PropertyListSerialization.data(fromPropertyList: settings, format: .binary, options: 0)
    } catch {
        print("Error exporting UserDefaults: \(error)")
        BezelNotification.show(messageText: "\(error)", icon: ToastIcon)
        return
    }
    
    let savePanel = NSSavePanel()
    savePanel.title = "Export Settings"
    savePanel.allowedContentTypes = [.propertyList]
    savePanel.directoryURL = URL(string: NSString(string: "~/Documents").expandingTildeInPath)
    
    savePanel.begin { result in
        if result == .OK, let fileURL = savePanel.url {
            do {
                try data.write(to: fileURL)
                print("UserDefaults exported to file: \(fileURL.absoluteString)")
                BezelNotification.show(messageText: "Exported settings", icon: ToastIcon)
            } catch {
                print("Error exporting UserDefaults: \(error)")
                BezelNotification.show(messageText: "\(error)", icon: ToastIcon)
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
                    BezelNotification.show(messageText: "Imported settings", icon: ToastIcon)
                } else {
                    print("Error: Unable to import settings. Invalid data format.")
                    BezelNotification.show(messageText: "Invalid data format.", icon: ToastIcon)
                }
            } catch {
                print("Error importing UserDefaults: \(error)")
                BezelNotification.show(messageText: "\(error)", icon: ToastIcon)
            }
        }
    }
}

func filterWindows(_ windows: [SCWindow]) -> [SCWindow] {
    @Default(.ignoredBundleIdentifiers) var ignoredBundleIdentifiers

    return windows
    // Sort the windows by app name.
        .sorted { $0.owningApplication?.applicationName ?? "" < $1.owningApplication?.applicationName ?? "" }
    // Remove windows that don't have an associated .app bundle.
        .filter { $0.owningApplication != nil && $0.owningApplication?.applicationName != "" }
    // Remove this app's window from the list.
        .filter { $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier }
        .filter { item in
            !ignoredBundleIdentifiers.contains(where: { $0 == item.owningApplication?.bundleIdentifier })
        }
}

struct AvailableContent {
    let displays: [SCDisplay]
    let windows: [SCWindow]
    let applications: [SCRunningApplication]
}

func refreshAvailableContent() async throws -> AvailableContent {
    do {
        // Retrieve the available screen content to capture.
        let availableContent = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
        let availableDisplays = availableContent.displays
        
        // Declare availableWindows before its usage
        var availableWindows = [SCWindow]()
        
        let windows = filterWindows(availableContent.windows)
        if windows != availableWindows {
            availableWindows = windows
        }
        let availableApps = availableContent.applications
        
        return AvailableContent(displays: availableDisplays,
                                windows: availableWindows,
                                applications: availableApps)
    } catch {
        throw error // Rethrow the error to the caller
    }
}

@MainActor
class AvailableContentProvider: ObservableObject {
    @Published var availableContent: AvailableContent?

    init() {
        refreshContent()
    }

    func refreshContent() {
        Task.detached {
            do {
                let content = try await refreshAvailableContent()
                DispatchQueue.main.async {
                    self.availableContent = content
                }
            } catch {
                print("Error refreshing content: \(error)")
            }
        }
    }
}

func icon(forAppWithName appName: String) -> NSImage? {
    if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appName) {
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
    return nil
}

let airdropIconPath = Bundle.path(forResource: "AirDrop", ofType: "icns", inDirectory: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources")

let airdropIcon = NSImage(contentsOfFile: airdropIconPath!)

struct SharingPreferences: Codable, Defaults.Serializable {
    var airdrop: Bool = false
    var photos: Bool = false
    var messages: Bool = false
    var mail: Bool = false
}

func shareBasedOnPreferences(_ fileURL: URL) {
    @Default(.builtInShare) var preferences
    
    if preferences.airdrop {
        NSSharingService(named: .sendViaAirDrop)?.perform(withItems: [fileURL])
    }
    
    if preferences.photos {
        NSSharingService(named: .addToIPhoto)?.perform(withItems: [fileURL])
    }
    
    if preferences.messages {
        NSSharingService(named: .composeMessage)?.perform(withItems: [fileURL])
    }
    
    if preferences.mail {
        NSSharingService(named: .composeEmail)?.perform(withItems: [fileURL])
    }
}

enum MenuBarIcon: Codable, CaseIterable, Identifiable, Defaults.Serializable {
    case DEFAULT
    case APPICON
    case SYSTEM
    var id: Self { self }
}

func addToUploadHistory(_ entry: String) {
    @Default(.uploadHistory) var uploadHistory
    
    uploadHistory.removeAll(where: { $0 == entry })
    uploadHistory.insert(entry, at: 0)

    if uploadHistory.count > 50 {
        uploadHistory.removeLast()
    }
}

struct ExcludedAppsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Default(.ignoredBundleIdentifiers) var ignoredBundleIdentifiers

    var body: some View {
            VStack {
                Text("Select apps to exclude")
                    .font(.title)

                Divider()
                
                ScrollView {
                    ForEach(NSWorkspace.shared.runningApplications.sorted { $0.localizedName ?? "" < $1.localizedName ?? "" }.filter { $0.bundleIdentifier != Bundle.main.bundleIdentifier }, id: \.self) { app in
                        Toggle(isOn: Binding(
                            get: {
                                ignoredBundleIdentifiers.contains(app.bundleIdentifier ?? "")
                            },
                            set: { newValue in
                                if newValue {
                                    ignoredBundleIdentifiers.append(app.bundleIdentifier ?? "")
                                } else {
                                    ignoredBundleIdentifiers.removeAll { $0 == app.bundleIdentifier }
                                }
                            }
                        )) {
                            Text(app.localizedName ?? app.bundleIdentifier ?? "unknown")
                        }
                        .toggleStyle(.checkbox)
                    }
                }
                
                Spacer()

                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding(.bottom)
            }
            .padding()
    }
}
