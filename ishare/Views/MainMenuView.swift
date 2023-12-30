//
//  MainMenuView.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import BezelNotification
import SwiftUI
import Defaults
import ScreenCaptureKit
import SettingsAccess
import UniformTypeIdentifiers

enum UploadDestination: Equatable, Hashable, Codable, Defaults.Serializable {
    case builtIn(UploadType)
    case custom(UUID?)
}

class HistoryWindowController: NSWindowController {
    convenience init(contentView: NSView) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        window.center()
        window.contentView = contentView
        self.init(window: window)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
}

class WindowHolder {
    static let shared = WindowHolder()
    var historyWindowController: HistoryWindowController?
}

func openHistoryWindow(uploadHistory: [HistoryItem]) {
    if WindowHolder.shared.historyWindowController == nil {
        let historyView = HistoryGridView(uploadHistory: uploadHistory)
        let hostingController = NSHostingController(rootView: historyView)
        let windowController = HistoryWindowController(contentView: hostingController.view)
        windowController.window?.title = "History"
        
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        WindowHolder.shared.historyWindowController = windowController
    } else {
        WindowHolder.shared.historyWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct MainMenuView: View {
    @Default(.copyToClipboard) var copyToClipboard
    @Default(.openInFinder) var openInFinder
    @Default(.saveToDisk) var saveToDisk
    @Default(.uploadMedia) var uploadMedia
    @Default(.uploadType) var uploadType
    @Default(.activeCustomUploader) var activeCustomUploader
    @Default(.savedCustomUploaders) var savedCustomUploaders
    @Default(.uploadDestination) var uploadDestination
    @Default(.builtInShare) var builtInShare
    @Default(.uploadHistory) var uploadHistory
    
    @StateObject private var availableContentProvider = AvailableContentProvider()
    
    var body: some View {
        VStack {
            Menu {
                Button {
                    captureScreen(type: .REGION)
                } label: {
                    Image(systemName: "uiwindow.split.2x1")
                    Label("Capture Region", image: String())
                }.keyboardShortcut(.captureRegion)
                
                Button {
                    captureScreen(type: .WINDOW)
                } label: {
                    Image(systemName: "macwindow.on.rectangle")
                    Label("Capture Window", image: String())
                }.keyboardShortcut(.captureWindow)
                
                ForEach(NSScreen.screens.indices, id: \.self) { index in
                    let screen = NSScreen.screens[index]
                    let screenName = screen.localizedName
                    Button {
                        captureScreen(type: .SCREEN, display: index + 1)
                    } label: {
                        Image(systemName: "macwindow")
                        Label("Capture \(screenName)", image: String())
                    }.keyboardShortcut(index == 0 ? .captureScreen : .noKeybind)
                }
            } label: {
                Image(systemName: "photo.on.rectangle.angled")
                Label("Capture", image: String())
            }
            
            if #available(macOS 13.0, *) {
                Menu {
                    if let availableContent = availableContentProvider.availableContent {
                        ForEach(availableContent.displays, id: \.self) { display in
                            Button {
                                recordScreen(display: display)
                            } label: {
                                Image(systemName: "menubar.dock.rectangle.badge.record")
                                Label("Record \(display.displayName)", image: String())
                            }.keyboardShortcut(display.displayID == 1 ? .recordScreen : .noKeybind).disabled(AppDelegate.shared.screenRecorder.isRunning)
                        }
                        Divider()
                        ForEach(availableContent.windows, id: \.self) { window in
                            Button {
                                recordScreen(window: window)
                            } label: {
                                Image(systemName: "menubar.dock.rectangle.badge.record")
                                Label("Record \(window.displayName)", image: String())
                            }.disabled(AppDelegate.shared.screenRecorder.isRunning)
                        }
                    }
                }
            label: {
                Image(systemName: "menubar.dock.rectangle.badge.record")
                Label("Record", image: String())
            }
                
                Menu {
                    if let availableContent = availableContentProvider.availableContent {
                        ForEach(availableContent.displays, id: \.self) { display in
                            Button {
                                recordScreen(display: display, gif: true)
                            } label: {
                                Image(systemName: "menubar.dock.rectangle.badge.record")
                                Label("Record \(display.displayName)", image: String())
                            }.keyboardShortcut(display.displayID == 1 ? .recordGif : .noKeybind).disabled(AppDelegate.shared.screenRecorder.isRunning)
                        }
                        Divider()
                        ForEach(availableContent.windows, id: \.self) { window in
                            Button {
                                recordScreen(window: window, gif: true)
                            } label: {
                                Image(systemName: "menubar.dock.rectangle.badge.record")
                                Label("Record \(window.displayName)", image: String())
                            }.disabled(AppDelegate.shared.screenRecorder.isRunning)
                        }
                    }
                }
            label: {
                Image(systemName: "photo.stack")
                Label("Record GIF", image: String())
            }
            }
        }
        VStack {
            Menu {
                Toggle(isOn: $copyToClipboard) {
                    Image(systemName: "clipboard")
                    Label("Copy to Clipboard", image: String())
                }.toggleStyle(.checkbox)
                
                Toggle(isOn: $saveToDisk) {
                    Image(systemName: "internaldrive")
                    Label("Save to Disk", image: String())
                }
                .toggleStyle(.checkbox)
                .onChange(of: saveToDisk) { newValue in
                    if !newValue {
                        openInFinder = false
                    }
                }
                
                Toggle(isOn: $openInFinder) {
                    Image(systemName: "folder")
                    Label("Open in Finder", image: String())
                }
                .toggleStyle(.checkbox)
                .disabled(!saveToDisk)
                
                Toggle(isOn: $uploadMedia){
                    Image(systemName: "icloud.and.arrow.up")
                    Label("Upload Media", image: String())
                }.toggleStyle(.checkbox)
                
                Divider().frame(height: 1).foregroundColor(Color.gray.opacity(0.5))
                
                Toggle(isOn: $builtInShare.airdrop) {
                    Image(nsImage: airdropIcon ?? NSImage())
                    Label("AirDrop", image: String())
                }.toggleStyle(.checkbox)
                
                Toggle(isOn: $builtInShare.photos) {
                    Image(nsImage: icon(forAppWithName: "com.apple.Photos") ?? NSImage())
                    Label("Photos", image: String())
                }.toggleStyle(.checkbox)
                
                Toggle(isOn: $builtInShare.messages) {
                    Image(nsImage: icon(forAppWithName: "com.apple.MobileSMS") ?? NSImage())
                    Label("Messages", image: String())
                }.toggleStyle(.checkbox)
                
                Toggle(isOn: $builtInShare.mail) {
                    Image(nsImage: icon(forAppWithName: "com.apple.Mail") ?? NSImage())
                    Label("Mail", image: String())
                }.toggleStyle(.checkbox)
            } label: {
                Image(systemName: "list.bullet.clipboard")
                Label("Post Media Tasks", image: String())
            }
            
            Picker(selection: $uploadDestination) {
                ForEach(UploadType.allCases.filter { $0 != .CUSTOM }, id: \.self) { uploadType in
                    Button {} label: {
                        Image(nsImage: ImgurIcon)
                        Label(uploadType.rawValue.capitalized, image: String())
                    }.tag(UploadDestination.builtIn(uploadType))
                }
                if let customUploaders = savedCustomUploaders {
                    if !customUploaders.isEmpty {
                        Divider()
                        ForEach(CustomUploader.allCases, id: \.self) { uploader in
                            Button {} label: {
                                Image(nsImage: AppIcon)
                                Label(uploader.name, image: String())
                            }.tag(UploadDestination.custom(uploader.id))
                        }
                    }
                }
            }
        label: {
            Image(systemName: "icloud.and.arrow.up")
            Label("Upload Destination", image: String())
        }
        .onChange(of: uploadDestination) { newValue in
            if case .builtIn(_) = newValue {
                activeCustomUploader = nil
                uploadType = .IMGUR
                BezelNotification.show(messageText: "Selected \(uploadType.rawValue.capitalized)", icon: ToastIcon)
            } else if case let .custom(customUploader) = newValue {
                activeCustomUploader = customUploader
                uploadType = .CUSTOM
                BezelNotification.show(messageText: "Selected Custom", icon: ToastIcon)
            }
        }
        .pickerStyle(MenuPickerStyle())
            
            if !uploadHistory.isEmpty {
                Menu {
                    Button {
                        openHistoryWindow(uploadHistory: uploadHistory)
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                        Label("Open History Window", image: String())
                    }.keyboardShortcut(.openHistoryWindow)
                    
                    Divider()
                    
                    ForEach(uploadHistory.prefix(10), id: \.self) { item in
                        Button {
                            NSPasteboard.general.declareTypes([.string], owner: nil)
                            NSPasteboard.general.setString(item.fileUrl ?? "", forType: .string)
                            BezelNotification.show(messageText: "Copied URL", icon: ToastIcon)
                        } label: {
                            HStack {
                                if let urlStr = item.fileUrl, let url = URL(string: urlStr), url.pathExtension.lowercased() == "mp4" || url.pathExtension.lowercased() == "mov" {
                                    Image(systemName: "video")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                } else {                                                                   PreviewImage(url: URL(string: item.fileUrl ?? "")) { phase in
                                    switch phase {
                                    case .success(let nsImage):
                                        Image(nsImage: nsImage)                                                .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                    case .failure:
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 30, height: 30)
                                    }
                                }
                                .frame(width: 30, height: 30)
                                }
                            }
                        }
                    }
                }
            label: {
                Image(systemName: "clock.arrow.circlepath")
                Label("History", image: String())
            }
            }
            
            Divider()
            
            if #available(macOS 14.0, *) {
                SettingsLink {
                    Image(systemName: "gearshape")
                    Text("Settings")
                } preAction: {
                    NSApp.activate(ignoringOtherApps: true)
                } postAction: {
                }
                .keyboardShortcut("s")
            }
            else {
                Button(action: {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    if #available(macOS 13.0, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } else {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                }) {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }.keyboardShortcut("s")
            }
            
            Button {
                NSApplication.shared.activate(ignoringOtherApps: true)
                
                let options: [NSApplication.AboutPanelOptionKey: Any] = [
                    NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© \(Calendar.current.component(.year, from: Date())) ADRIAN CASTRO"
                ]
                
                NSApplication.shared.orderFrontStandardAboutPanel(options: options)
            } label: {
                Image(systemName: "info.circle")
                Label("About ishare", image: String())
            }
            .keyboardShortcut("a")
            
            Button {
                NSWorkspace.shared.open(URL(string: "https://github.com/sponsors/castdrian")!)
            } label: {
                Image(systemName: "heart.circle")
                Label("Donate", image: String())
            }.keyboardShortcut("d")
            
            Button {
                AppDelegate.shared.updaterController.updater.checkForUpdates()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                Label("Check for Updates", image: String())
            }.keyboardShortcut("u")
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power.circle")
                Label("Quit", image: String())
            }.keyboardShortcut("q")
                .onAppear {
                    availableContentProvider.refreshContent()
                    Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                        availableContentProvider.refreshContent()
                    }
                }
        }
    }
}
