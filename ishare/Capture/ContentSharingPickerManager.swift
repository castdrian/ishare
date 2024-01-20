//
//  ContentSharingPickerManager.swift
//  ishare
//
//  Created by Adrian Castro on 20.01.24.
//

import Foundation
import Defaults
import ScreenCaptureKit

@MainActor
class ContentSharingPickerManager: NSObject, SCContentSharingPickerObserver {
    static let shared = ContentSharingPickerManager()
    private let picker = SCContentSharingPicker.shared
    
    var contentSelected: ((SCContentFilter, SCStream?) -> Void)?
    var contentSelectionFailed: ((Error) -> Void)?
    var contentSelectionCancelled: ((SCStream?) -> Void)?
    
    @Default(.ignoredBundleIdentifiers) var ignoredBundleIdentifiers
    
    func setupPicker(stream: SCStream) {
        picker.add(self)
        picker.isActive = true
        
        var pickerConfig = SCContentSharingPickerConfiguration()
        pickerConfig.excludedBundleIDs = ignoredBundleIdentifiers
        pickerConfig.allowsChangingSelectedContent = true
        
        picker.setConfiguration(pickerConfig, for: stream)
    }
    
    func showPicker() {
        picker.present()
    }
    
    func deactivatePicker() {
        picker.isActive = false
        picker.remove(self)
    }
    
    nonisolated func contentSharingPicker(_ picker: SCContentSharingPicker, didUpdateWith filter: SCContentFilter, for stream: SCStream?) {
        DispatchQueue.main.async {
            self.contentSelected?(filter, stream)
        }
    }
    
    nonisolated func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?) {
        DispatchQueue.main.async {
            self.contentSelectionCancelled?(stream)
        }
    }
    
    nonisolated func contentSharingPickerStartDidFailWithError(_ error: Error) {
        DispatchQueue.main.async {
            self.contentSelectionFailed?(error)
        }
    }
}
