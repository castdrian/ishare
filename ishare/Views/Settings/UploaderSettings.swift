//
//  UploaderSettings.swift
//  ishare
//
//  Created by Adrian Castro on 15.07.23.
//

import SwiftUI
import Defaults

struct UploaderSettingsView: View {
    @Default(.activeCustomUploader) var activeCustomUploader
    @Default(.savedCustomUploaders) var savedCustomUploaders
    @Default(.uploadType) var uploadType

    @State private var isAddSheetPresented = false
    @State private var isImportSheetPresented = false

    var body: some View {
        VStack {
            if let uploaders = savedCustomUploaders {
                Text("Saved Custom Uploaders:")
                    .font(.headline)
                    .padding(.top)

                ForEach(uploaders.sorted(by: { $0.name < $1.name }), id: \.self) { uploader in
                    HStack {
                        Text(uploader.name)
                            .font(.subheadline)

                        Spacer()

                        Button(action: {
                            deleteCustomUploader(uploader)
                        }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .help("Delete Uploader")

                        Button(action: {
                            testCustomUploader(uploader)
                        }) {
                            Image(systemName: "icloud.and.arrow.up")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .help("Test Uploader")

                        Button(action: {
                            editCustomUploader(uploader) // Edit button added
                        }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .help("Edit Uploader")

                        Button(action: {
                            exportUploader(uploader) // Export button added
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .help("Export Uploader")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            } else {
                Text("No saved custom uploaders")
                    .foregroundColor(.secondary)
            }

            Divider()

            Button(action: {
                isAddSheetPresented.toggle()
            }) {
                Text("Add Custom Uploader")
            }
            .buttonStyle(DefaultButtonStyle())

            Button(action: {
                isImportSheetPresented.toggle()
            }) {
                Text("Import Custom Uploader")
            }
            .buttonStyle(DefaultButtonStyle())

            Button(action: {
                clearAllUploaders()
            }) {
                Text("Clear All Uploaders")
                    .foregroundColor(.red)
            }
            .buttonStyle(DefaultButtonStyle())
        }
        .sheet(isPresented: $isAddSheetPresented) {
            AddCustomUploaderView()
        }
        .sheet(isPresented: $isImportSheetPresented) {
            ImportCustomUploaderView()
        }
    }
    
    private func deleteCustomUploader(_ uploader: CustomUploader) {
        guard var uploaders = savedCustomUploaders else { return }
        uploaders = uploaders.filter { $0.id != uploader.id }
        savedCustomUploaders = uploaders

        if uploader.id == activeCustomUploader {
            savedCustomUploaders = nil
            activeCustomUploader = nil
            uploadType = .IMGUR
        }
    }
    
    private func testCustomUploader(_ uploader: CustomUploader) {
        let image = NSImage(named: "AppIcon")
        guard let imageData = image?.tiffRepresentation else { return }
        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
        let fileURL = temporaryDirectory.appendingPathComponent("appIconImage.jpg")
        do {
            try imageData.write(to: fileURL)
        } catch {
            print("Failed to write image file: \(error)")
            return
        }

        let callback: ((Error?, URL?) -> Void) = { error, finalURL in
            if let error = error {
                    print("Upload error: \(error)")
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.alertStyle = .critical
                        alert.messageText = "Upload Error"
                        alert.informativeText = "An error occurred during the upload process."
                        alert.runModal()
                    }
                } else if let url = finalURL {
                    print("Final URL: \(url)")
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.alertStyle = .informational
                        alert.messageText = "Upload Successful"
                        alert.informativeText = "The file was uploaded successfully."
                        alert.runModal()
                    }
                }
        }
        
        customUpload(fileURL: fileURL, specification: uploader, callback: callback) {}
        
        // Clean up temp
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("Failed to delete temporary file: \(error)")
        }
    }

    private func clearAllUploaders() {
        savedCustomUploaders = nil
        activeCustomUploader = nil
        uploadType = .IMGUR
    }
    
    private func editCustomUploader(_ uploader: CustomUploader) {
            isAddSheetPresented.toggle()
        }
        
        private func exportUploader(_ uploader: CustomUploader) {
            let data = try! JSONEncoder().encode(uploader)
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.init(filenameExtension: "iscu")!]
            savePanel.nameFieldStringValue = "\(uploader.name).iscu"

            savePanel.begin { result in
                if result == .OK, let url = savePanel.url {
                    do {
                        try data.write(to: url)
                    } catch {
                        print("Error exporting uploader: \(error)")
                    }
                }
            }
        }
}

struct AddCustomUploaderView: View {
    @Environment(\.presentationMode) var presentationMode
    @Default(.savedCustomUploaders) var savedCustomUploaders

    @State private var uploaderName = ""
    @State private var requestURL = ""
    @State private var responseURL = ""
    @State private var deletionURL = ""
    @State private var fileFormName = ""
    @State private var header: [CustomEntryModel] = []
    @State private var formData: [CustomEntryModel] = []

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("Name:")
                    TextField("Name", text: $uploaderName)
                }
                .padding()
                
                HStack {
                    Text("Request URL:")
                    TextField("Request URL", text: $requestURL)
                }
                .padding()
                
                HStack {
                    Text("Response URL:")
                    TextField("Response URL", text: $responseURL)
                }
                .padding()

                HStack {
                    Text("Deletion URL (optional):")
                    TextField("Deletion URL", text: $deletionURL)
                }
                .padding()
                
                HeaderView()
                
                FormDataView()
                
                Button(action: {
                    saveCustomUploader()
                }) {
                    Text("Save")
                }
                .padding()
            }
        }
    }
    
    private func HeaderView() -> some View {
        Section(header: Text("Header (optional)")) {
            ForEach(header.indices, id: \.self) { index in
                HStack(spacing: 10) {
                    Text("Header Name: \(header[index].key)")
                    Text("Header Value: \(header[index].value)")
                    
                    Button(action: {
                        header.remove(at: index)
                    }) {
                        Image(systemName: "minus.circle")
                    }
                }
                
            }
            
            ForEach(header) { entry in
                if (entry == header.last) {
                    CustomEntryView(entry: $header[header.firstIndex(of: entry)!])
                        .padding(.horizontal)
                }
            }
            
            Button(action: {
                header.append(CustomEntryModel(key: "", value: ""))
            }) {
                Text("Add Header")
            }
            .padding()
        }
    }
    
    private func FormDataView() -> some View {
        Section(header: Text("Form Data (optional)")) {
            ForEach(formData.indices, id: \.self) { index in
                HStack(spacing: 10) {
                    Text("Form Data Name: \(formData[index].key)")
                    Text("Form Data Value: \(formData[index].value)")
                    
                    Button(action: {
                        formData.remove(at: index)
                    }) {
                        Image(systemName: "minus.circle")
                    }
                }
                
            }
            
            ForEach(formData) { entry in
                if (entry == formData.last) {
                    CustomEntryView(entry: $formData[formData.firstIndex(of: entry)!])
                        .padding(.horizontal)
                }
            }
            
            Button(action: {
                formData.append(CustomEntryModel(key: "", value: ""))
            }) {
                Text("Add FormData")
            }
            .padding()
        }
    }

    private func saveCustomUploader() {
        var headerData: [String: String] {
            return header.reduce(into: [String: String]()) { result, entry in
                result[entry.key] = entry.value
            }
        }

        var formDataModel: [String: String] {
            return formData.reduce(into: [String: String]()) { result, entry in
                result[entry.key] = entry.value
            }
        }
        
        let uploader = CustomUploader(
            name: uploaderName,
            requestURL: requestURL,
            headers: header.count == 0 ? nil : headerData,
            formData: formData.count == 0 ? nil : formDataModel,
            fileFormName: fileFormName.isEmpty ? nil : fileFormName,
            responseURL: responseURL,
            deletionURL: deletionURL.isEmpty ? nil : deletionURL

        )

        if var uploaders = savedCustomUploaders {
            uploaders.remove(uploader)
            uploaders.insert(uploader)
            savedCustomUploaders = uploaders
        } else {
            savedCustomUploaders = Set([uploader])
        }

        presentationMode.wrappedValue.dismiss()
    }

    private struct CustomEntryView: View {
        @Binding var entry: CustomEntryModel
        
        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text("Name")
                    TextField("Name", text: $entry.key)
                }
                VStack(alignment: .leading) {
                    Text("Value")
                    TextField("Value", text: $entry.value)
                }
            }
        }
    }
}

struct ImportCustomUploaderView: View {
    @Environment(\.presentationMode) var presentationMode
    @Default(.savedCustomUploaders) var savedCustomUploaders
    @Default(.activeCustomUploader) var activeCustomUploader
    @Default(.uploadType) var uploadType

    @State private var selectedFileURLs: [URL] = []
    @State private var isImportSheetPresented = false
    @State private var importError: ImportError?

    var body: some View {
        VStack {
            Text("Import Custom Uploader")
                .font(.title)

            Divider()

            Button(action: {
                isImportSheetPresented.toggle()
            }) {
                Text("Select File")
            }
            .buttonStyle(DefaultButtonStyle())

            if let fileURL = selectedFileURLs.first {
                Text("Selected File: \(fileURL.lastPathComponent)")
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding(.bottom)
        }
        .padding()
        .fileImporter(
            isPresented: $isImportSheetPresented,
            allowedContentTypes: [.data],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let fileURLs):
                selectedFileURLs = fileURLs
                importUploader()
            case .failure(let error):
                importError = ImportError(error: error)
                print("Error selecting file: \(error)")
            }
        }
        .alert(item: $importError) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func importUploader() {
        guard let fileURL = selectedFileURLs.first else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let uploader = try decoder.decode(CustomUploader.self, from: data)

            if var uploaders = savedCustomUploaders {
                uploaders.remove(uploader)
                uploaders.insert(uploader)
                savedCustomUploaders = uploaders
            } else {
                savedCustomUploaders = Set([uploader])
            }
            
            activeCustomUploader = uploader.id
            uploadType = .CUSTOM
            presentationMode.wrappedValue.dismiss()
        } catch {
            importError = ImportError(error: error)
            print("Error importing custom uploader: \(error)")
            return
        }

        selectedFileURLs = []
        presentationMode.wrappedValue.dismiss()
    }
}

struct ImportError: Identifiable {
    let id = UUID()
    let error: Error

    var localizedDescription: String {
        error.localizedDescription
    }
}

struct CustomEntryModel: Identifiable, Equatable {
    let id = UUID()
    var key: String
    var value: String
}

#Preview {
    AddCustomUploaderView()
}
