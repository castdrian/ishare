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
#if NOT_APP_STORE
import Sparkle
#endif

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
        let historyView = HistoryGridView()
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
    
    var body: some View {
        VStack {
            Menu {
                Button {
                    captureScreen(type: .REGION)
                } label: {
                    Image(systemName: "uiwindow.split.2x1")
                    Text("Capture Region")
                }.keyboardShortcut(.captureRegion)
                
                Button {
                    captureScreen(type: .WINDOW)
                } label: {
                    Image(systemName: "macwindow.on.rectangle")
                    Text("Capture Window")
                }.keyboardShortcut(.captureWindow)
                
                ForEach(NSScreen.screens.indices, id: \.self) { index in
                    let screen = NSScreen.screens[index]
                    let screenName = screen.localizedName
                    Button {
                        captureScreen(type: .SCREEN, display: index + 1)
                    } label: {
                        Image(systemName: "macwindow")
                        Text("Capture \(screenName)")
                    }.keyboardShortcut(index == 0 ? .captureScreen : .noKeybind)
                }
            } label: {
                Image(systemName: "photo.on.rectangle.angled")
                Text("Capture")
            }
            
            Button {
                recordScreen()
            }
        label: {
            Image(systemName: "menubar.dock.rectangle.badge.record")
            Text("Record")
        }.keyboardShortcut(.recordScreen).disabled(AppDelegate.shared?.screenRecorder?.isRunning ?? false)
            
            Button {
                recordScreen(gif: true)
            }
        label: {
            Image(systemName: "photo.stack")
            Text("Record GIF")
        }.keyboardShortcut(.recordGif).disabled(AppDelegate.shared?.screenRecorder?.isRunning ?? false)        }
        VStack {
            Menu {
                Toggle(isOn: $copyToClipboard) {
                    Image(systemName: "clipboard")
                    Text("Copy to Clipboard")
                }.toggleStyle(.checkbox)
                
                Toggle(isOn: $saveToDisk) {
                    Image(systemName: "internaldrive")
                    Text("Save to Disk")
                }
                .toggleStyle(.checkbox)
                .onChange(of: saveToDisk) {
                    if !saveToDisk {
                        openInFinder = false
                    }
                }
                
                Toggle(isOn: $openInFinder) {
                    Image(systemName: "folder")
                    Text("Open in Finder")
                }
                .toggleStyle(.checkbox)
                .disabled(!saveToDisk)
                
                Toggle(isOn: $uploadMedia){
                    Image(systemName: "icloud.and.arrow.up")
                    Text("Upload Media")
                }.toggleStyle(.checkbox)
                
                Divider().frame(height: 1).foregroundColor(Color.gray.opacity(0.5))
                
                Toggle(isOn: $builtInShare.airdrop) {
                    Image(nsImage: airdropIcon ?? NSImage())
                    Text("AirDrop")
                }.toggleStyle(.checkbox)
                
                Toggle(isOn: $builtInShare.photos) {
                    Image(nsImage: icon(forAppWithName: "com.apple.Photos") ?? NSImage())
                    Text("Photos")
                }.toggleStyle(.checkbox)
                
                Toggle(isOn: $builtInShare.messages) {
                    Image(nsImage: icon(forAppWithName: "com.apple.MobileSMS") ?? NSImage())
                    Text("Messages")
                }.toggleStyle(.checkbox)
                
                Toggle(isOn: $builtInShare.mail) {
                    Image(nsImage: icon(forAppWithName: "com.apple.Mail") ?? NSImage())
                    Text("Mail")
                }.toggleStyle(.checkbox)
            } label: {
                Image(systemName: "list.bullet.clipboard")
                Text("Post Media Tasks")
            }
            
            Picker(selection: $uploadDestination) {
                ForEach(UploadType.allCases.filter { $0 != .CUSTOM }, id: \.self) { uploadType in
                    Button {} label: {
                        Image(nsImage: ImgurIcon)
                        Text(uploadType.rawValue.capitalized)
                    }.tag(UploadDestination.builtIn(uploadType))
                }
                if let customUploaders = savedCustomUploaders {
                    if !customUploaders.isEmpty {
                        Divider()
                        ForEach(CustomUploader.allCases, id: \.self) { uploader in
                            Button {} label: {
                                Image(nsImage: AppIcon)
                                Text(uploader.name)
                            }.tag(UploadDestination.custom(uploader.id))
                        }
                    }
                }
            }
        label: {
            Image(systemName: "icloud.and.arrow.up")
            Text("Upload Destination")
        }
        .onChange(of: uploadDestination) {
            if case .builtIn(_) = uploadDestination {
                activeCustomUploader = nil
                uploadType = .IMGUR
                BezelNotification.show(messageText: "Selected \(uploadType.rawValue.capitalized)", icon: ToastIcon)
            } else if case let .custom(customUploader) = uploadDestination {
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
                        Text("Open History Window")
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
                Text("History")
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
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
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
                Text("About ishare")
            }
            .keyboardShortcut("a")
            
#if NOT_APP_STORE
            Button {
                NSWorkspace.shared.open(URL(string: "https://github.com/sponsors/castdrian")!)
            } label: {
                Image(systemName: "heart.circle")
                Text("Donate")
            }.keyboardShortcut("d")
            
            Button {
                AppDelegate.shared.updaterController.updater.checkForUpdates()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("Check for Updates")
            }.keyboardShortcut("u")
            
#endif
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power.circle")
                Text("Quit")
            }.keyboardShortcut("q")
        }
    }
}
