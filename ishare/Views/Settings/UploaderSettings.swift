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

    private func clearAllUploaders() {
        savedCustomUploaders = nil
        activeCustomUploader = nil
        uploadType = .IMGUR
    }
}

struct AddCustomUploaderView: View {
    @Environment(\.presentationMode) var presentationMode
    @Default(.savedCustomUploaders) var savedCustomUploaders

    @State private var uploaderName = ""
    @State private var requestUrl = ""
    @State private var headers: [String: String] = [:]
    @State private var formData: [String: String] = [:]
    @State private var fileFormName = ""
    @State private var responseProp = ""

    var body: some View {
        VStack {
            HStack {
                Text("Name:")
                TextField("Name", text: $uploaderName)
            }
            .padding()

            HStack {
                Text("Request URL:")
                TextField("Request URL", text: $requestUrl)
            }
            .padding()

            HStack {
                Text("Response Property:")
                TextField("Response Property", text: $responseProp)
            }
            .padding()

            Section(header: Text("Headers (optional)")) {
                ForEach(Array(headers.keys), id: \.self) { key in
                    HStack {
                        Text("Header Name:")
                        TextField("Header Name", text: Binding(
                            get: { key },
                            set: { newKey in headers[newKey] = headers.removeValue(forKey: key) }
                        ))

                        Text("Header Value:")
                        TextField("Header Value", text: Binding(
                            get: { headers[key] ?? "" },
                            set: { headers[key] = $0 }
                        ))
                    }
                    .padding(.horizontal)
                }

                Button(action: {
                    headers[""] = ""
                }) {
                    Text("Add Header")
                }
                .padding()
            }

            Section(header: Text("Form Data (optional)")) {
                ForEach(Array(formData.keys), id: \.self) { key in
                    HStack {
                        Text("Field Name:")
                        TextField("Field Name", text: Binding(
                            get: { key },
                            set: { newKey in formData[newKey] = formData.removeValue(forKey: key) }
                        ))

                        Text("Field Value:")
                        TextField("Field Value", text: Binding(
                            get: { formData[key] ?? "" },
                            set: { formData[key] = $0 }
                        ))
                    }
                    .padding(.horizontal)
                }

                Button(action: {
                    formData[""] = ""
                }) {
                    Text("Add Field")
                }
                .padding()
            }

            Button(action: {
                saveCustomUploader()
            }) {
                Text("Save")
            }
            .padding()
        }
    }

    private func saveCustomUploader() {
        let uploader = CustomUploader(
            name: uploaderName,
            requestUrl: requestUrl,
            headers: headers.isEmpty ? nil : headers,
            formData: formData.isEmpty ? nil : formData,
            fileFormName: fileFormName.isEmpty ? nil : fileFormName,
            responseProp: responseProp
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
