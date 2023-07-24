//
//  MainMenuView.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
import Defaults

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
    
    var body: some View {
        Menu("Capture/Record") {
            Button("Capture Region") {
                captureScreen(type: .REGION)
            }.keyboardShortcut(.captureRegion)
            Button("Capture Window") {
                captureScreen(type: .WINDOW)
            }.keyboardShortcut(.captureWindow)
            ForEach(NSScreen.screens.indices, id: \.self) { index in
                let screen = NSScreen.screens[index]
                let screenName = screen.localizedName
                Button("Capture \(screenName)") {
                    captureScreen(type: .SCREEN, display: index + 1)
                }.keyboardShortcut(index == 0 ? .captureScreen : .noKeybind)
            }
            Divider()
            Button("Record Region") {
            }.keyboardShortcut(.recordRegion).disabled(true)
            ForEach(NSScreen.screens.indices, id: \.self) { index in
                let screen = NSScreen.screens[index]
                let screenName = screen.localizedName
                Button("Record \(screenName)") {
                    // captureScreen(type: .SCREEN, display: index + 1)
                }.keyboardShortcut(index == 0 ? .recordScreen : .noKeybind)
            }
        }
        
        Menu("Post Media Tasks") {
            Toggle("Copy to clipboard", isOn: $copyToClipboard).toggleStyle(.checkbox)
            Toggle("Open in Finder", isOn: $openInFinder).toggleStyle(.checkbox)
            Toggle("Upload media", isOn: $uploadMedia).toggleStyle(.checkbox)
        }
        
        Picker("Upload Destination", selection: $uploadDestination) {
                   ForEach(UploadType.allCases.filter { $0 != .CUSTOM }, id: \.self) { uploadType in
                       Text(uploadType.rawValue.capitalized)
                           .tag(UploadDestination.builtIn(uploadType))
                   }
            if let customUploaders = savedCustomUploaders {
                       if !customUploaders.isEmpty {
                           Divider()
                           ForEach(CustomUploader.allCases, id: \.self) { uploader in
                               Text(uploader.name)
                                   .tag(UploadDestination.custom(uploader.id))
                           }
                       }
                   }
               }
               .onChange(of: uploadDestination) { newValue in
                   if case .builtIn(_) = newValue {
                       activeCustomUploader = nil
                       uploadType = .IMGUR
                   } else if case let .custom(customUploader) = newValue {
                       activeCustomUploader = customUploader
                       uploadType = .CUSTOM
                   }
               }
               .pickerStyle(MenuPickerStyle())
                
        Button("Settings") {
            NSApplication.shared.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }.keyboardShortcut("s")
        
        Divider()
        
        Button("About ishare") {
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
        }
        .keyboardShortcut("a")
        
        
        Button("Check for Updates") {
            selfUpdate()
        }.keyboardShortcut("u")
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}
