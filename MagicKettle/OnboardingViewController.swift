//
//  OnboardingViewController.swift
//  MagicKettle
//
//  Shown once on first launch, before any permission prompts, so a first-time
//  user knows what to do with the camera instead of landing on a blank AR view.
//

import UIKit
import AVFoundation

final class OnboardingViewController: UIViewController {

    static let hasSeenOnboardingKey = "hasSeenOnboarding"

    var onGetStarted: (() -> Void)?

    private let previewView = LoopingVideoView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        modalPresentationStyle = .fullScreen

        previewView.layer.cornerRadius = 20
        previewView.clipsToBounds = true
        previewView.backgroundColor = .secondarySystemBackground
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.widthAnchor.constraint(equalToConstant: 220).isActive = true
        previewView.heightAnchor.constraint(equalToConstant: 220).isActive = true

        if let demoURL = Bundle.main.url(forResource: "kettle", withExtension: "mp4") {
            previewView.play(url: demoURL)
        }

        let titleLabel = UILabel()
        titleLabel.text = "Welcome to Magic Media"
        titleLabel.font = .preferredFont(forTextStyle: .title1).withWeight(.bold)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        let bodyLabel = UILabel()
        bodyLabel.text = "Point your camera at a supported photo, bill, or poster and watch it come alive with video, audio, or 3D — like the loop above.\n\nSign in with Apple to upload your own trigger for others to discover."
        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = .center

        let getStartedButton = UIButton(type: .system)
        getStartedButton.setTitle("Get Started", for: .normal)
        getStartedButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        getStartedButton.setTitleColor(.white, for: .normal)
        getStartedButton.backgroundColor = .black
        getStartedButton.layer.cornerRadius = 12
        getStartedButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
        getStartedButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [previewView, titleLabel, bodyLabel, getStartedButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 20
        stack.setCustomSpacing(28, after: previewView)
        stack.setCustomSpacing(32, after: bodyLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32)
        ])
    }

    @objc private func getStartedTapped() {
        UserDefaults.standard.set(true, forKey: Self.hasSeenOnboardingKey)
        dismiss(animated: true) { [weak self] in
            self?.onGetStarted?()
        }
    }
}

/// Plays a bundled video on a silent, seamless loop — used in place of an
/// actual GIF, which UIKit has no native support for animating.
private final class LoopingVideoView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    private var looper: AVPlayerLooper?

    func play(url: URL) {
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        looper = AVPlayerLooper(player: player, templateItem: item)
        player.play()
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
