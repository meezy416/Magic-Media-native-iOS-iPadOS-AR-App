//
//  ViewController.swift
//  MagicKettle
//
//  Created by Vedant Shrivastava on 11/10/20.
//

import UIKit
import SceneKit
import ARKit
import RealityKit
import Speech
import AVFoundation
import AuthenticationServices
import Supabase
class ViewController: UIViewController, ARSCNViewDelegate, ARCoachingOverlayViewDelegate, SFSpeechRecognizerDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var coachingOverlay: ARCoachingOverlayView!
//    @IBOutlet var arView: ARView!
    
    @IBOutlet weak var recordingButton: UIButton!
    
//    let audioPlayer = AVQueuePlayer()
    
    // MARK: Speech Framework Properties
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    /// Speech variables
//    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    var recognitionTask: SFSpeechRecognitionTask?
//    let audioEngine = AVAudioEngine()
//    let speechRecognizer: SFSpeechRecognizer! =
//        SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    @IBOutlet weak var recognizedText: UITextView!
//    var cancelCalled = false
//    var audioSession = AVAudioSession.sharedInstance()
//    var timer: Timer?
  // let speechService: SpeechService = KeywordsSpeechService()
    
    var audioPlayer : AVPlayer!

    var newAudioPlayer: AVAudioPlayer!

    // MARK: Community Triggers (Supabase-backed)

    /// The community trigger currently being displayed, so Report can act on it.
    var activeDynamicTrigger: Trigger?

    private let signInButton = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
    private let uploadButton = UIButton(type: .system)
    private let reportButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.autoenablesDefaultLighting = true
        recordingButton.isEnabled = false
//        presentCoachingOverlay()

        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
     //   sceneView.showsStatistics = true

        setUpCommunityUI()

            }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Configure the SFSpeechRecognizer object already
        // stored in a local member variable.
        speechRecognizer.delegate = self
        
        // Asynchronously make the authorization request.
        SFSpeechRecognizer.requestAuthorization { authStatus in

            // Divert to the app's main thread so that the UI
            // can be updated.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.recordingButton.isEnabled = true
                    
                case .denied:
                    self.recordingButton.isEnabled = false
                    self.recordingButton.setTitle("User denied access to speech recognition", for: .disabled)
                    
                case .restricted:
                    self.recordingButton.isEnabled = false
                    self.recordingButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    self.recordingButton.isEnabled = false
                    self.recordingButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                    
                default:
                    self.recordingButton.isEnabled = false
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
//        if let trackOneDollarFront = ARReferenceImage.referenceImages(inGroupNamed: "oneDollar", bundle: Bundle.main) {
//
//        configuration.trackingImages = trackOneDollarFront
//
//            configuration.maximumNumberOfTrackedImages = 3
//
//            print("One Dollar Bill Front Tracked Successfully!")
//
//        }
        
        if let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "kettleImages", bundle: Bundle.main) {
            configuration.trackingImages = trackedImages

            configuration.maximumNumberOfTrackedImages = 10

            print("Images found")


        }

        
        // Run the view's session
        sceneView.session.run(configuration)

       implementCoaching()

        loadCommunityTriggers()
        refreshAuthUI()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        implementCoaching()
    }

    // MARK: - ARSCNViewDelegate
 
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        
        let node = SCNNode()
      
        if let imageAnchor = anchor as? ARImageAnchor {
            
          // print(imageAnchor.referenceImage.name)
            
          //  coachingOverlayViewDidDeactivate(coachingOverlayTemp)
            
            if imageAnchor.referenceImage.name == "one-dollar-front" {

                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)

                plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)

                let planeNode = SCNNode(geometry: plane)

                planeNode.eulerAngles.x = -.pi/2

                node.addChildNode(planeNode)

                if let noteScene = SCNScene(named: "art.scnassets/george.scn") {

                    if let noteNode = noteScene.rootNode.childNodes.first {
                        
                        noteNode.eulerAngles.x = .pi/2

                        //noteNode.position = SCNVector3(x: planeNode.position.x, y: planeNode.position.y + 2, z: planeNode.position.z)
                        
                        planeNode.addChildNode(noteNode)

                    }
                }
                
                playWashingtonAudio()
            }
            
            
            if imageAnchor.referenceImage.name == "ten-dollar-front" {

                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)

                plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)

                let planeNode = SCNNode(geometry: plane)

                planeNode.eulerAngles.x = -.pi/2

                node.addChildNode(planeNode)

                if let noteScene = SCNScene(named: "art.scnassets/hamilton.scn") {

                    if let noteNode = noteScene.rootNode.childNodes.first {
                        
                        noteNode.eulerAngles.x = .pi/2

                        //noteNode.position = SCNVector3(x: planeNode.position.x, y: planeNode.position.y + 2, z: planeNode.position.z)
                        
                        planeNode.addChildNode(noteNode)

                    }
                }
                
                playHamiltonAudio()
            }
            
            
            
            if imageAnchor.referenceImage.name == "twenty-front" {

                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)

                plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)

                let planeNode = SCNNode(geometry: plane)

                planeNode.eulerAngles.x = -.pi/2

                node.addChildNode(planeNode)

                if let noteScene = SCNScene(named: "art.scnassets/jackson.scn") {

                    if let noteNode = noteScene.rootNode.childNodes.first {
                        
                        noteNode.eulerAngles.x = .pi/2

                        //noteNode.position = SCNVector3(x: planeNode.position.x, y: planeNode.position.y + 2, z: planeNode.position.z)
                        
                        planeNode.addChildNode(noteNode)

                    }
                }
                
                playJacksonAudio()
            }
            
            if imageAnchor.referenceImage.name == "listerine" {

                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)

                plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)

                let planeNode = SCNNode(geometry: plane)

                planeNode.eulerAngles.x = -.pi/2

                node.addChildNode(planeNode)

                if let noteScene = SCNScene(named: "art.scnassets/listerine.scn") {

                    if let noteNode = noteScene.rootNode.childNodes.first {
                        
                        noteNode.eulerAngles.x = .pi/2

                        //noteNode.position = SCNVector3(x: planeNode.position.x, y: planeNode.position.y + 2, z: planeNode.position.z)
                        
                        planeNode.addChildNode(noteNode)

                    }
                }
                
                // playJacksonAudio()
            }

            if imageAnchor.referenceImage.name == "salmon" {

                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)

                plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)

                let planeNode = SCNNode(geometry: plane)

                planeNode.eulerAngles.x = -.pi/2

                node.addChildNode(planeNode)

                if let noteScene = SCNScene(named: "art.scnassets/salmon.scn") {

                    if let noteNode = noteScene.rootNode.childNodes.first {
                        
                        noteNode.eulerAngles.x = .pi/2

                        //noteNode.position = SCNVector3(x: planeNode.position.x, y: planeNode.position.y + 2, z: planeNode.position.z)
                        
                        planeNode.addChildNode(noteNode)

                    }
                }
                
                // playJacksonAudio()
            }

            if imageAnchor.referenceImage.name == "obama-model" {

                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)

                plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)

                let planeNode = SCNNode(geometry: plane)

                planeNode.eulerAngles.x = -.pi/2

                node.addChildNode(planeNode)

                if let noteScene = SCNScene(named: "art.scnassets/obama.scn") {

                    if let noteNode = noteScene.rootNode.childNodes.first {
                       
                        
                       // noteNode.position = SCNVector3(x: planeNode.position.x, y: (planeNode.position.y + noteNode.boundingSphere.radius), z: planeNode.position.z)
                        
                        noteNode.eulerAngles.x = .pi/2

                                                
                     //   pokeNode.position = SCNVector3(x: planeNode.position.x, y: planeNode.position.x + pokeNode.boundingSphere.radius, z: planeNode.position.x)
                        
                        planeNode.addChildNode(noteNode)

                    }
                }
                
                // playJacksonAudio()
            }

            
            if imageAnchor.referenceImage.name == "furniture" {

                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)

                plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)

                let planeNode = SCNNode(geometry: plane)

                planeNode.eulerAngles.x = -.pi/2

                node.addChildNode(planeNode)

                if let noteScene = SCNScene(named: "art.scnassets/coffee-table.scn") {
                    
                    if let noteNode = noteScene.rootNode.childNodes.first {
                        
                        noteNode.eulerAngles.x = .pi/2

                        planeNode.addChildNode(noteNode)

                    }
                }
                
                // playJacksonAudio()
            }
            
            
            if imageAnchor.referenceImage.name == "kettle" {
                            
            let videoNode = SKVideoNode(fileNamed: "kettle.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = -1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            }
            
            if imageAnchor.referenceImage.name == "mandarinrest" {
                            
            let videoNode = SKVideoNode(fileNamed: "mandarin2.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = 1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            }
            
            if imageAnchor.referenceImage.name == "mandarinrest2" {
                            
            let videoNode = SKVideoNode(fileNamed: "mandarin3.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = 1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            }
            
            if imageAnchor.referenceImage.name == "one-dollar-back" {
                            
            let videoNode = SKVideoNode(fileNamed: "one-dollar.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = -1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            }
            
            if imageAnchor.referenceImage.name == "ten-dollar-back" {
                            
            let videoNode = SKVideoNode(fileNamed: "ten-dollar.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = -1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            }
            
            if imageAnchor.referenceImage.name == "twenty-dollar-back" {
                            
            let videoNode = SKVideoNode(fileNamed: "twenty-dollar.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = -1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            }
            
            if imageAnchor.referenceImage.name == "twister" {
                            
            let videoNode = SKVideoNode(fileNamed: "twister.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = -1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            }
            
            if imageAnchor.referenceImage.name == "TimH" {
                            
            let videoNode = SKVideoNode(fileNamed: "timmes.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = -1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            }
            
            if imageAnchor.referenceImage.name == "Timmes20" {
                            
            let videoNode = SKVideoNode(fileNamed: "Timmes20.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = -1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            }

            if imageAnchor.referenceImage.name == "costco-auto-program-image" {
                            
            let videoNode = SKVideoNode(fileNamed: "costco-auto-program.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = -1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            }

            if imageAnchor.referenceImage.name == "costco-mexico" {
                            
            let videoNode = SKVideoNode(fileNamed: "mexico.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = -1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            }

            if imageAnchor.referenceImage.name == "sensodyne" {
                            
            let videoNode = SKVideoNode(fileNamed: "sensodyne.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = -1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            }
            
            if imageAnchor.referenceImage.name == "promised-land" {
                            
            let videoNode = SKVideoNode(fileNamed: "promised-land.mp4")
            
            videoNode.play()
            
            let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
            
            videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
            
            videoNode.yScale = -1.0
            
            videoScene.addChild(videoNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = videoScene
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)

            }

            if let trigger = TriggerService.shared.triggersByReferenceName[imageAnchor.referenceImage.name ?? ""] {

                activeDynamicTrigger = trigger

                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)

                plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)

                let planeNode = SCNNode(geometry: plane)

                planeNode.eulerAngles.x = -.pi/2

                node.addChildNode(planeNode)

                let contentURL = TriggerService.shared.cachedContentURL(for: trigger)

                switch trigger.contentType {
                case .video:
                    let videoNode = SKVideoNode(url: contentURL)

                    videoNode.play()

                    let videoScene = SKScene(size: CGSize(width: 1280, height: 720))

                    videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)

                    videoNode.yScale = -1.0

                    videoScene.addChild(videoNode)

                    plane.firstMaterial?.diffuse.contents = videoScene

                case .audio:
                    do {
                        newAudioPlayer = try AVAudioPlayer(contentsOf: contentURL)
                        newAudioPlayer.play()
                    } catch {
                        print("Failed to play community audio: \(error)")
                    }

                case .model:
                    if let modelScene = try? SCNScene(url: contentURL, options: nil),
                       let modelNode = modelScene.rootNode.childNodes.first {
                        modelNode.eulerAngles.x = .pi / 2
                        planeNode.addChildNode(modelNode)
                    }
                }
            }

    }

        return node

    }
    

    
    private func playWashingtonAudio() {
        guard let url = Bundle.main.url(forResource: "washington-quote 2", withExtension: "mp3") else {
                print("error to get the mp3 file")
                return
            }

            do {
                audioPlayer = try AVPlayer(url: url)
            } catch {
                print("audio file error")
            }
            audioPlayer?.play()
      
        }
    
    private func playHamiltonAudio() {
        guard let url = Bundle.main.url(forResource: "hamilton-quote 2", withExtension: "mp3") else {
                print("error to get the mp3 file")
                return
            }

            do {
                audioPlayer = try AVPlayer(url: url)
            } catch {
                print("audio file error")
            }
            audioPlayer?.play()
        }
    
    private func playJacksonAudio() {
        guard let url = Bundle.main.url(forResource: "jackson-quote 2", withExtension: "mp3") else {
                print("error to get the mp3 file")
                return
            }

            do {
                audioPlayer = try AVPlayer(url: url)
            } catch {
                print("audio file error")
            }
            audioPlayer?.play()
        }

    private func whatCanYouDo() {
        guard let url = Bundle.main.url(forResource: "whatcanido", withExtension: "mp3") else {
                print("error to get the mp3 file")
                return
            }

            do {
                audioPlayer = try AVPlayer(url: url)
            } catch {
                print("audio file error")
            }
            audioPlayer?.play()
        }
    
    private func salmonRecipe() {
        guard let url = Bundle.main.url(forResource: "salmonrecipe", withExtension: "mp3") else {
                print("error to get the mp3 file")
                return
            }

            do {
                audioPlayer = try AVPlayer(url: url)
            } catch {
                print("audio file error")
            }
            audioPlayer?.play()
        }
   
    private func oprahInterview() {
        guard let url = Bundle.main.url(forResource: "oprah", withExtension: "mp3") else {
                print("error to get the mp3 file")
                return
            }

            do {
                audioPlayer = try AVPlayer(url: url)
            } catch {
                print("audio file error")
            }
            audioPlayer?.play()
        }
    
    private func waterKettle() {
        guard let url = Bundle.main.url(forResource: "waterKettle", withExtension: "mp3") else {
                print("error to get the mp3 file")
                return
            }

            do {
                audioPlayer = try AVPlayer(url: url)
            } catch {
                print("audio file error")
            }
            audioPlayer?.play()
        }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        if node.isHidden == true {
            if let imageAnchor = anchor as? ARImageAnchor {
                sceneView.session.remove(anchor: imageAnchor)
                }
                }
            }
    

    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        coachingOverlayView.activatesAutomatically = true    }
    
    public func implementCoaching() {
    let coachingOverlayTemp = ARCoachingOverlayView()
    coachingOverlayTemp.session = sceneView.session
   coachingOverlayTemp.delegate = self
    coachingOverlayTemp.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleTopMargin] //to make sure it resizes if device orientation changes
    coachingOverlayTemp.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(coachingOverlayTemp)
    
 //   Rendering the Coaching Session to the Screen Size
    NSLayoutConstraint.activate([
        coachingOverlayTemp.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        coachingOverlayTemp.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        coachingOverlayTemp.widthAnchor.constraint(equalTo: view.widthAnchor),
        coachingOverlayTemp.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    
   coachingOverlayTemp.activatesAutomatically = false
    
    coachingOverlayTemp.setActive(true, animated: true)
    
    coachingOverlayTemp.goal = .anyPlane
        
        let seconds = 5.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            coachingOverlayTemp.activatesAutomatically = true
        }
    }
    
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {

        // Reset the session.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        implementCoaching()

        // Custom actions to restart the AR experience.
        // ...
    }

    func sessionWasInterrupted(_ session: ARSession) {
        implementCoaching()
    }
    
   // MARK: Speech Implementation
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode

        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep speech recognition data on device
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.recognizedText.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
                print("Text \(result.bestTranscription.formattedString)")
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.recordingButton.isEnabled = true
                self.recordingButton.setTitle("Start Recording", for: [])
            }
            
            
  // MARK: Voice Command Actions
            
            if self.recognizedText.text == "Moon" {
                let sphere = SCNSphere(radius: 0.2)
                let material = SCNMaterial()
                material.diffuse.contents = UIImage(named: "art.scnassets/8k_moon.jpg")
                sphere.materials = [material]
                let node = SCNNode()

                node.position = SCNVector3(x: 0, y: 0.1, z: -0.5)
                node.geometry = sphere
                self.sceneView.scene.rootNode.addChildNode(node)

            }
            
            if self.recognizedText.text == "What can you do" {
                self.recognizedText.text = "You can say things like: Any book recommendations, Any good recipes, Instructions for the kettle, I am hungry, and more"
                self.whatCanYouDo()
            }
            
            if (self.recognizedText.text == "I am hungry") || (self.recognizedText.text == "I'm hungry") || (self.recognizedText.text == "What's for dinner") || (self.recognizedText.text == "Any good recipes")  {
                self.recognizedText.text = "Check out the awesome recipe for salmon in the Costco Connection 2020 file provided with this app"
                self.salmonRecipe()
            }
            
            if (self.recognizedText.text == "Any book recommendations"){
                self.recognizedText.text = "Check out President Obama's interview with Oprah on his new book in the Costco Connection 2020 file provided with this app"
                self.oprahInterview()
            }
            
            if (self.recognizedText.text == "How to use water kettle") || (self.recognizedText.text == "Instructions for the kettle"){
                self.recognizedText.text = "Detect the image on the Water Kettle Instructions Manual file provided with this app for the video"
                self.waterKettle()
            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
        recognizedText.text = "(Go ahead, I'm listening) \nSay (What can you do) in order to learn more"
                      
    }
    
   
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordingButton.isEnabled = true
            recordingButton.setTitle("Start Recording", for: [])
        } else {
            recordingButton.isEnabled = false
            recordingButton.setTitle("Recognition Not Available", for: .disabled)
        }
    }
    
    // MARK: Interface Builder actions
    
    
    @IBAction func recordingButtonTapped() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordingButton.isEnabled = false
            recordingButton.setTitle("Stopping", for: .disabled)
            let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(AVAudioSession.Category.playback)
                    try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                } catch {
                    // handle errors
                }
            recognizedText.text = ""
        } else {
            do {
                try startRecording()
                recordingButton.setTitle("Stop Recording", for: [])
            } catch {
                recordingButton.setTitle("Recording Not Available", for: [])
            }
        }

    }

    // MARK: Community Trigger UI

    private func setUpCommunityUI() {
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)

        uploadButton.setTitle("Upload", for: .normal)
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        uploadButton.layer.cornerRadius = 8
        uploadButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        uploadButton.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)

        reportButton.setTitle("Report", for: .normal)
        reportButton.setTitleColor(.white, for: .normal)
        reportButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        reportButton.layer.cornerRadius = 8
        reportButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [signInButton, uploadButton, reportButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12)
        ])
    }

    private func loadCommunityTriggers() {
        Task {
            do {
                let dynamicImages = try await TriggerService.shared.fetchApprovedTriggers()
                guard !dynamicImages.isEmpty else { return }

                await MainActor.run {
                    let configuration = ARImageTrackingConfiguration()
                    let bundledImages = ARReferenceImage.referenceImages(inGroupNamed: "kettleImages", bundle: Bundle.main) ?? []
                    configuration.trackingImages = bundledImages.union(Set(dynamicImages))
                    configuration.maximumNumberOfTrackedImages = 10
                    self.sceneView.session.run(configuration)
                }
            } catch {
                print("Failed to load community triggers: \(error)")
            }
        }
    }

    private func refreshAuthUI() {
        Task {
            let signedIn = await SupabaseManager.shared.isSignedIn
            await MainActor.run {
                self.signInButton.isHidden = signedIn
                self.uploadButton.isHidden = !signedIn
                self.reportButton.isHidden = !signedIn
            }
        }
    }

    @objc private func signInTapped() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    @objc private func uploadTapped() {
        let uploadVC = UploadViewController()
        let nav = UINavigationController(rootViewController: uploadVC)
        present(nav, animated: true)
    }

    @objc private func reportTapped() {
        guard let trigger = activeDynamicTrigger else {
            let alert = UIAlertController(
                title: "Nothing to report",
                message: "Point the camera at a community trigger first.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        ReportContentHelper.presentReportFlow(for: trigger, from: self)
    }

}

extension ViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window ?? ASPresentationAnchor()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let identityTokenData = credential.identityToken,
            let identityToken = String(data: identityTokenData, encoding: .utf8)
        else { return }

        Task {
            do {
                try await SupabaseManager.shared.client.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(provider: .apple, idToken: identityToken)
                )
                await MainActor.run { self.refreshAuthUI() }
            } catch {
                print("Sign in with Apple failed: \(error)")
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple error: \(error)")
    }
}

