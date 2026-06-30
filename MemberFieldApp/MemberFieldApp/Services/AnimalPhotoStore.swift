import Foundation
import UIKit

enum AnimalPhotoStore {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("AnimalPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    private static func fileURL(for animalID: UUID) -> URL {
        directory.appendingPathComponent("\(animalID.uuidString).jpg")
    }

    static func save(_ image: UIImage, for animalID: UUID) throws {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw AnimalPhotoStoreError.encodingFailed
        }
        try data.write(to: fileURL(for: animalID), options: .atomic)
    }

    static func load(for animalID: UUID) -> UIImage? {
        let url = fileURL(for: animalID)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    static func delete(for animalID: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: animalID))
    }
}

enum AnimalPhotoStoreError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: "Could not save the animal photo."
        }
    }
}
