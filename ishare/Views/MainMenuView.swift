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

enum UploadDestination: Equatable, Hashable, Codable, Defaults.Serializable {
    case builtIn(UploadType)
    case custom(UUID?)
}

struct MainMenuView: View {    
    @Default(.copyToClipboard) var copyToClipboard
    @Default(.openInFinder) var openInFinder
    @Default(.uploadMedia) var uploadMedia
    @Default(.uploadType) var uploadType
    @Default(.activeCustomUploader) var activeCustomUploader
    @Default(.savedCustomUploaders) var savedCustomUploaders
    @Default(.uploadDestination) var uploadDestination
    
    @StateObject private var availableContentProvider = AvailableContentProvider()
    
    var body: some View {
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
        
        Menu {
            if let availableContent = availableContentProvider.availableContent {
                ForEach(availableContent.displays, id: \.self) { display in
                    Button {
                        recordScreen(display: display)
                    } label: {
                        Image(systemName: "menubar.dock.rectangle.badge.record")
                        Label("Record \(display.displayName)", image: String())
                    }.keyboardShortcut(display.displayID == 1 ? .recordScreen : .noKeybind)
                }
                Divider()
                ForEach(availableContent.windows, id: \.self) { window in
                    Button {
                        recordScreen(window: window)
                    } label: {
                        Image(systemName: "menubar.dock.rectangle.badge.record")
                        Label("Record \(window.displayName)", image: String())
                    }
                }
            }
        }
    label: {
        Image(systemName: "menubar.dock.rectangle.badge.record")
        Label("Record", image: String())
    }
        
        Menu {
            Toggle(isOn: $copyToClipboard) {
                Image(systemName: "clipboard")
                Label("Copy to clipboard", image: String())
            }.toggleStyle(.checkbox)
            
            Toggle(isOn: $openInFinder){
                Image(systemName: "folder")
                Label("Open in Finder", image: String())
            }.toggleStyle(.checkbox)
            
            Toggle(isOn: $uploadMedia){
                Image(systemName: "icloud.and.arrow.up")
                Label("Upload media", image: String())
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
        
        Button {
            NSApplication.shared.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } label: {
            Image(systemName: "gearshape")
            Label("Settings", image: String())
        }.keyboardShortcut("s")
        
        Divider()
        
        Button {
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            fetchContributors { contributors in
                if let contributors = contributors {
                    var credits = "isharemac.app\n\nContributors: "
                    
                    for (index, contributor) in contributors.enumerated() {
                        if index == contributors.count - 1 {
                            credits += contributor.login
                        } else {
                            credits += "\(contributor.login), "
                        }
                    }
                    
                    let creditsAttributedString = NSAttributedString(string: credits, attributes: [
                        NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)
                    ])
                    
                    let options: [NSApplication.AboutPanelOptionKey: Any] = [
                        NSApplication.AboutPanelOptionKey.credits: creditsAttributedString,
                        NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© \(Calendar.current.component(.year, from: Date())) ADRIAN CASTRO"
                    ]
                    
                    NSApplication.shared.orderFrontStandardAboutPanel(options: options)
                } else {
                    print("Failed to fetch contributors")
                }
            }
        } label: {
            Image(systemName: "info.circle")
            Label("About ishare", image: String())
        }
        .keyboardShortcut("a")
        
        Button {
            AppDelegate.shared.updaterController.updater.checkForUpdates()
        } label: {
            Image(systemName: "arrow.down.app")
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
