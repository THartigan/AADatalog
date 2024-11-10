//
//  FileController.swift
//  ActiveAlarm
//
//  Created by Thomas Hartigan on 09/07/2024.
//

import Foundation

struct FileController {
    func saveFileToDocuments(sourceURL: URL, fileName: String, extension: String) {
        let fileManager = FileManager.default

        do {
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let destinationURL = documentsURL.appendingPathComponent(fileName).appendingPathExtension("mov")

            // Copy the file to the documents directory
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("File saved to documents directory at \(destinationURL)")
        } catch {
            print("Error saving file: \(error)")
        }
    }
}
