import SwiftUI
import PhotosUI

struct AnimalPhotoPickerSection: View {
    @Binding var selectedImage: UIImage?
    var existingAnimalID: UUID?
    var onPhotoRemoved: () -> Void = {}
    var onPhotoSelected: () -> Void = {}

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        Section("Photo") {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                Button("Remove Photo", role: .destructive) {
                    selectedImage = nil
                    photoPickerItem = nil
                    onPhotoRemoved()
                }
            } else {
                ContentUnavailableView(
                    "No photo",
                    systemImage: "photo",
                    description: Text("Add a photo of this animal from your library or camera.")
                )
                .frame(maxWidth: .infinity)
                .frame(height: 140)
            }

            Button {
                showCamera = true
            } label: {
                Label(selectedImage == nil ? "Take Photo" : "Retake Photo", systemImage: "camera.fill")
            }

            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker(image: $selectedImage, onPhotoPicked: onPhotoSelected)
                .ignoresSafeArea()
        }
        .onChange(of: photoPickerItem) { _, newItem in
            Task { await loadPhoto(from: newItem) }
        }
        .onAppear {
            if selectedImage == nil, let existingAnimalID {
                selectedImage = AnimalPhotoStore.load(for: existingAnimalID)
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedImage = image
            onPhotoSelected()
        }
    }
}

struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onPhotoPicked: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraImagePicker

        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            defer { parent.dismiss() }
            if let edited = info[.editedImage] as? UIImage {
                parent.image = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.image = original
            }
            parent.onPhotoPicked()
        }
    }
}
