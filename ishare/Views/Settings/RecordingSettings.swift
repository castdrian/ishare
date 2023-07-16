//
//  RecordingSettings.swift
//  ishare
//
//  Created by Adrian Castro on 15.07.23.
//

import SwiftUI

struct RecordingSettingsView: View {
    @State private var showingAlert: Bool = false
    @State private var isInstalling = false
    @State private var errorAlert: ErrorAlert? = nil
    @State private var isFFmpegInstalled: Bool = false
    
    private var alertTitle: String = "Install ffmpeg"
    private var alertMessage: String = "Do you want to install ffmpeg on this Mac?"
    private var alertButtonText: String = "Confirm"
    
    var body: some View {
        VStack {
            HStack {
                Text("ffmpeg status:")
                Button(isFFmpegInstalled ? "installed" : "not installed") {
                    showingAlert = true
                }
                .buttonStyle(.borderedProminent)
                .tint(isFFmpegInstalled ? .green : .pink)
                .disabled(isFFmpegInstalled)
                .alert(Text(alertTitle),
                       isPresented: $showingAlert,
                       actions: {
                    Button(alertButtonText) {
                        showingAlert = false
                        // installFFmpeg() doesn't work yet, might not do this
                    }
                    Button("Cancel", role: .cancel) {
                        showingAlert = false
                    }
                }, message: {
                    Text(alertMessage)
                }
                )
            }.onAppear {
                isFFmpegInstalled = checkAppInstallation(.FFMPEG)
            }
            if isInstalling {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color(NSColor.windowBackgroundColor))
                    .frame(width: 200, height: 180)
                    .overlay(
                        VStack {
                            ProgressView {
                                Text("Installing ffmpeg...")
                                    .foregroundColor(.primary)
                            }
                            .progressViewStyle(CircularProgressViewStyle())
                            .accentColor(.blue)
                            .padding(.horizontal)
                        }
                            .padding()
                    )
            }
        }
        .alert(item: $errorAlert) { error in
            error.alert
        }
    }
    
    func installFFmpeg() {
        if !checkAppInstallation(.HOMEBREW) {
            errorAlert = ErrorAlert(
                title: "Installation Failed",
                message: "Homebrew is not installed on this Mac."
            )
            return
        }
        
        isInstalling = true
        
        DispatchQueue.global().async {
            let process = Process()
            process.launchPath = utsname.isAppleSilicon ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"
            process.arguments = ["install", "ffmpeg"]
            
            process.launch()
            process.waitUntilExit()
            
            DispatchQueue.main.async {
                isInstalling = false
                isFFmpegInstalled = checkAppInstallation(.FFMPEG)
                
                if process.terminationStatus != 0 {
                    errorAlert = ErrorAlert(
                        title: "Installation Failed",
                        message: "Failed to install ffmpeg. Please try again."
                    )
                }
            }
        }
    }
}

struct ErrorAlert: Identifiable {
    var id = UUID()
    var title: String
    var message: String
    
    var alert: Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text("OK"))
        )
    }
}
