//
//  UploadViewController.swift
//  MagicKettle
//
//  A user picks a target photo + a video/audio clip, and it's uploaded to Supabase
//  Storage with a `triggers` row in "pending" status, awaiting manual approval.
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers
import Supabase

final class UploadViewController: UIViewController {

    private let titleField = UITextField()
    private let widthField = UITextField()
    private let chooseImageButton = UIButton(type: .system)
    private let chooseContentButton = UIButton(type: .system)
    private let uploadButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()

    private var pickedImage: UIImage?
    private var pickedContentURL: URL?
    private var pickedContentType: TriggerContentType?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Upload a Trigger"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped)
        )

        titleField.placeholder = "Title (e.g. \"My Poster\")"
        titleField.borderStyle = .roundedRect

        widthField.placeholder = "Physical width in meters (e.g. 0.21)"
        widthField.borderStyle = .roundedRect
        widthField.keyboardType = .decimalPad

        chooseImageButton.setTitle("Choose Target Image", for: .normal)
        chooseImageButton.addTarget(self, action: #selector(chooseImageTapped), for: .touchUpInside)

        chooseContentButton.setTitle("Choose Video/Audio", for: .normal)
        chooseContentButton.addTarget(self, action: #selector(chooseContentTapped), for: .touchUpInside)

        uploadButton.setTitle("Upload", for: .normal)
        uploadButton.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)

        statusLabel.numberOfLines = 0
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = .preferredFont(forTextStyle: .footnote)

        let stack = UIStackView(arrangedSubviews: [
            titleField, widthField, chooseImageButton, chooseContentButton,
            uploadButton, activityIndicator, statusLabel
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func chooseImageTapped() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func chooseContentTapped() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie, .audio])
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func uploadTapped() {
        guard let title = titleField.text, !title.isEmpty else {
            showStatus("Please enter a title.")
            return
        }
        guard let widthText = widthField.text, let width = Float(widthText), width > 0 else {
            showStatus("Please enter a valid physical width in meters.")
            return
        }
        guard let image = pickedImage, let jpegData = image.jpegData(compressionQuality: 0.85) else {
            showStatus("Please choose a target image.")
            return
        }
        guard let contentURL = pickedContentURL, let contentType = pickedContentType else {
            showStatus("Please choose a video or audio file.")
            return
        }

        activityIndicator.startAnimating()
        uploadButton.isEnabled = false
        showStatus("Uploading…")

        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id

                let targetPath = "\(userId)/\(UUID().uuidString).jpg"
                try await SupabaseManager.shared.client.storage
                    .from("trigger-targets")
                    .upload(targetPath, data: jpegData, options: FileOptions(contentType: "image/jpeg"))

                let contentData = try Data(contentsOf: contentURL)
                let ext = contentURL.pathExtension.isEmpty ? "mp4" : contentURL.pathExtension
                let contentPath = "\(userId)/\(UUID().uuidString).\(ext)"
                try await SupabaseManager.shared.client.storage
                    .from("trigger-content")
                    .upload(contentPath, data: contentData)

                let newTrigger = NewTrigger(
                    ownerId: userId,
                    title: title,
                    targetImagePath: targetPath,
                    physicalWidthMeters: width,
                    contentType: contentType,
                    contentPath: contentPath
                )

                try await SupabaseManager.shared.client
                    .from("triggers")
                    .insert(newTrigger)
                    .execute()

                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.showStatus("Uploaded! It'll appear once it's been reviewed.")
                    self.uploadButton.isEnabled = true
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.uploadButton.isEnabled = true
                    self.showStatus("Upload failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showStatus(_ text: String) {
        statusLabel.text = text
    }
}

extension UploadViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                self?.pickedImage = object as? UIImage
                if self?.pickedImage != nil {
                    self?.chooseImageButton.setTitle("Target Image Selected ✓", for: .normal)
                }
            }
        }
    }
}

extension UploadViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        // Security-scoped access is only needed while we read the file; we copy the
        // bytes out synchronously in uploadTapped(), so we don't retain access beyond this.
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let localCopy = try? copyToTemporaryLocation(url) else { return }

        pickedContentURL = localCopy
        if let utType = UTType(filenameExtension: localCopy.pathExtension), utType.conforms(to: .audio) {
            pickedContentType = .audio
        } else {
            pickedContentType = .video
        }
        chooseContentButton.setTitle("Content File Selected ✓", for: .normal)
    }

    private func copyToTemporaryLocation(_ url: URL) throws -> URL {
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: url, to: destination)
        return destination
    }
}
