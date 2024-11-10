import SwiftUI
import AVKit

func getDocumentsDirectory() -> URL? {
    let fileManager = FileManager.default
    do {
        let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        return documentsURL
    } catch {
        print("Error getting documents directory: \(error)")
        return nil
    }
}

func fetchFilesInDocumentsDirectory() -> [URL] {
    guard let documentsURL = getDocumentsDirectory() else { return [] }

    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        return fileURLs
    } catch {
        print("Error fetching files: \(error)")
        return []
    }
}

struct FileBrowserView: View {
    @State private var files: [URL] = []

    var body: some View {
        NavigationView {
            List(files, id: \.self) { file in
                NavigationLink(destination: FileDetailView(fileURL: file)) {
                    Text(file.lastPathComponent)
                }
            }
            .navigationTitle("Documents")
            .onAppear {
                self.files = fetchFilesInDocumentsDirectory()
            }
        }
    }
}

struct FileDetailView: View {
    let fileURL: URL

    var body: some View {
        VStack {
            Text(fileURL.lastPathComponent)
                .font(.title)
                .padding()

            if fileURL.pathExtension == "mov" {
                VideoPlayer(player: AVPlayer(url: fileURL))
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("Preview not available")
            }

            Spacer()
        }
        .navigationTitle(fileURL.lastPathComponent)
    }
}

struct FileBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        FileBrowserView()
    }
}
