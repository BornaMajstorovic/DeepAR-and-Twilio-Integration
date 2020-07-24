//
//  ViewController.swift
//  twilio-ios-swift
//
//  Created by Borna on 23/07/2020.
//  Copyright © 2020 hr.fer.majstorovic.borna. All rights reserved.
//

import UIKit
import DeepAR
import TwilioVideo


class ViewController: UIViewController {
    
    // MARK: - IBOutlets -
    
    @IBOutlet weak var switchCameraButton: UIButton!
    @IBOutlet weak var masksButton: UIButton!
    @IBOutlet weak var effectsButton: UIButton!
    @IBOutlet weak var filtersButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var arView: ARView!
    
    
    // MARK: - Private properties -
    
    private var maskIndex: Int = 0
    private var maskPaths: [String?] {
        return Masks.allCases.map { $0.rawValue.path }
    }
    
    private var effectIndex: Int = 0
    private var effectPaths: [String?] {
        return Effects.allCases.map { $0.rawValue.path }
    }
    
    private var filterIndex: Int = 0
    private var filterPaths: [String?] {
        return Filters.allCases.map { $0.rawValue.path }
    }
    
    private var buttonModePairs: [(UIButton, Mode)] = []
    private var currentMode: Mode! {
        didSet {
            updateModeAppearance()
        }
    }
    private var cameraController: CameraController!
    
    private var accessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTS2M1ZGRiZTFhM2NkZTUzNWQwMmQ2ZGY2YzhjYzY2MTc4LTE1OTU1OTAyMjMiLCJpc3MiOiJTS2M1ZGRiZTFhM2NkZTUzNWQwMmQ2ZGY2YzhjYzY2MTc4Iiwic3ViIjoiQUNkYjQ0YzMxOTAxNjUyYmVkZTAxNDk3YjVlNDdiNWFmYiIsImV4cCI6MTU5NTU5MzgyMywiZ3JhbnRzIjp7ImlkZW50aXR5IjoiemVkYXJhIiwidmlkZW8iOnsicm9vbSI6ImRlZXBBUiJ9fX0.NfO9hO5KLaCVPPfzOvJ2PQHJbp8qKw2_q2p4ddtcOAc"
    private var room: Room?
    internal weak var sink: VideoSink?
    private var frame: VideoFrame?
    private var displayLink: CADisplayLink?
    
    private var videoTrack: LocalVideoTrack?
    private var audioTrack: LocalAudioTrack?
    
    // MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupArView()
        setupTwilio()
        addTargets()
        
        buttonModePairs = [(masksButton, .masks), (effectsButton, .effects), (filtersButton, .filters)]
        currentMode = .masks
        
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Private Methods -
    private func setupTwilio(){
        self.videoTrack = LocalVideoTrack(source: self)
        let format = VideoFormat()
        format.frameRate = 15
        format.pixelFormat = PixelFormat.format32BGRA
        format.dimensions = CMVideoDimensions(width: Int32(arView.bounds.width),
                                              height: Int32(arView.bounds.height))
        self.requestOutputFormat(format)
        start()
        
        self.audioTrack = LocalAudioTrack()
        
        let options = ConnectOptions(token: accessToken, block: { (builder) in
            if let videoTrack = self.videoTrack {
                builder.videoTracks = [videoTrack]
            }
            if let audioTrack = self.audioTrack {
                builder.audioTracks = [audioTrack]
            }
            builder.roomName = "deepAR"
        })
        
        self.room = TwilioVideoSDK.connect(options: options, delegate: self)
    }
    
    private func setupArView() {
        arView.setLicenseKey("f64c4138f9309686ac9fceed46031639629f54b669cae716ca089d0c207c77059703f1e997dbd04d")
        arView.delegate = self
        cameraController = CameraController()
        cameraController.arview = arView
        
        arView.initialize()
        cameraController.startCamera()
    }
    
    private func addTargets() {
        switchCameraButton.addTarget(self, action: #selector(didTapSwitchCameraButton), for: .touchUpInside)
        previousButton.addTarget(self, action: #selector(didTapPreviousButton), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didTapNextButton), for: .touchUpInside)
        masksButton.addTarget(self, action: #selector(didTapMasksButton), for: .touchUpInside)
        effectsButton.addTarget(self, action: #selector(didTapEffectsButton), for: .touchUpInside)
        filtersButton.addTarget(self, action: #selector(didTapFiltersButton), for: .touchUpInside)
    }
    
    private func updateModeAppearance() {
        buttonModePairs.forEach { (button, mode) in
            button.isSelected = mode == currentMode
        }
    }
    
    private func switchMode(_ path: String?) {
        arView.switchEffect(withSlot: currentMode.rawValue, path: path)
    }
    
    private func start(){
        
        self.displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkDidFire))
        self.displayLink?.preferredFramesPerSecond = 15
        
        displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
    }
    
    private func stop(){
        self.sink = nil
        self.displayLink?.invalidate()
        arView.pause()
    }
    
    @objc
    private func didTapSwitchCameraButton() {
        cameraController.position = cameraController.position == .back ? .front : .back
    }
    
    
    @objc
    private func didTapPreviousButton() {
        var path: String?
        
        switch currentMode! {
        case .effects:
            effectIndex = (effectIndex - 1 < 0) ? (effectPaths.count - 1) : (effectIndex - 1)
            path = effectPaths[effectIndex]
        case .masks:
            maskIndex = (maskIndex - 1 < 0) ? (maskPaths.count - 1) : (maskIndex - 1)
            path = maskPaths[maskIndex]
        case .filters:
            filterIndex = (filterIndex - 1 < 0) ? (filterPaths.count - 1) : (filterIndex - 1)
            path = filterPaths[filterIndex]
        }
        
        switchMode(path)
    }
    
    @objc
    private func didTapNextButton() {
        var path: String?
        
        switch currentMode! {
        case .effects:
            effectIndex = (effectIndex + 1 > effectPaths.count - 1) ? 0 : (effectIndex + 1)
            path = effectPaths[effectIndex]
        case .masks:
            maskIndex = (maskIndex + 1 > maskPaths.count - 1) ? 0 : (maskIndex + 1)
            path = maskPaths[maskIndex]
        case .filters:
            filterIndex = (filterIndex + 1 > filterPaths.count - 1) ? 0 : (filterIndex + 1)
            path = filterPaths[filterIndex]
        }
        
        switchMode(path)
    }
    
    @objc
    private func didTapMasksButton() {
        currentMode = .masks
    }
    
    @objc
    private func didTapEffectsButton() {
        currentMode = .effects
    }
    
    @objc
    private func didTapFiltersButton() {
        currentMode = .filters
    }
    
    func copyPixelbufferFromCGImageProvider(image: CGImage) -> CVPixelBuffer? {
        let dataProvider: CGDataProvider? = image.dataProvider
        let data: CFData? = dataProvider?.data
        let baseAddress = CFDataGetBytePtr(data!)
        
        
        let unmanagedData = Unmanaged<CFData>.passRetained(data!)
        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreateWithBytes(nil,
                                                  image.width,
                                                  image.height,
                                                  PixelFormat.format32BGRA.rawValue,
                                                  UnsafeMutableRawPointer( mutating: baseAddress!),
                                                  image.bytesPerRow,
                                                  { releaseContext, baseAddress in
                                                    let contextData = Unmanaged<CFData>.fromOpaque(releaseContext!)
                                                    contextData.release() },
                                                  unmanagedData.toOpaque(),
                                                  nil,
                                                  &pixelBuffer)
        
        if (status != kCVReturnSuccess) {
            return nil;
        }
        
        return pixelBuffer
    }
    
    @objc func displayLinkDidFire(timer: CADisplayLink) {
        
        let myImage = self.arView.snapshotView(afterScreenUpdates: true) as? UIImageView
        
        guard let imageRef = myImage?.image?.cgImage else {
            return
        }
        
        // A VideoSource must deliver CVPixelBuffers (and not CGImages) to a VideoSink.
        if let pixelBuffer = self.copyPixelbufferFromCGImageProvider(image: imageRef) {
            self.frame = VideoFrame(timeInterval: timer.timestamp,
                                    buffer: pixelBuffer,
                                    orientation: VideoOrientation.up)
            self.sink!.onVideoFrame(self.frame!)
        }
    }
    
}

// MARK: - ARViewDelegate -

extension ViewController: ARViewDelegate {
    func didFinishPreparingForVideoRecording() {}
    
    func didStartVideoRecording() {}
    
    func frameAvailable(_ sampleBuffer: CMSampleBuffer!) {
        
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if let pixelBuff = CMSampleBufferGetImageBuffer(sampleBuffer) {
            self.frame = VideoFrame(timeInterval: CFTimeInterval(time.value),
                                    buffer: pixelBuff,
                                    orientation: VideoOrientation.up)
            self.sink!.onVideoFrame(self.frame!)
        }
    
    }
    
    func didFinishVideoRecording(_ videoFilePath: String!) {}
    
    func recordingFailedWithError(_ error: Error!) {}
    
    func didTakeScreenshot(_ screenshot: UIImage!) {}
    
    func didInitialize() {}
    
    func faceVisiblityDidChange(_ faceVisible: Bool) {
    }
}

// MARK:- RoomDelegate
extension ViewController: RoomDelegate {
    func roomDidConnect(room: Room) {
        print("Connected to room \(room.name) as \(room.localParticipant?.identity ?? "")")
    }
    
    func roomDidFailToConnect(room: Room, error: Error) {
        print("Failed to connect to a Room: \(error).")
        
        let alertController = UIAlertController(title: "Connection Failed",
                                                message: "Couldn't connect to Room \(room.name). code:\(error._code) \(error.localizedDescription)",
            preferredStyle: UIAlertController.Style.alert)
        
        let cancelAction = UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true) {
            self.room = nil
            self.setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }
    
    func roomDidDisconnect(room: Room, error: Error?) {
        if let error = error {
            print("Disconnected from the Room with an error:", error)
        } else {
            print("Disconnected from the Room.")
        }
        self.room = nil
        self.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    func roomIsReconnecting(room: Room, error: Error) {
        print("Reconnecting to room \(room.name), error = \(String(describing: error))")
    }
    
    func roomDidReconnect(room: Room) {
        print("Reconnected to room \(room.name)")
    }
    
    func participantDidConnect(room: Room, participant: RemoteParticipant) {
        print("Participant \(participant.identity) connected to \(room.name).")
    }
    
    func participantDidDisconnect(room: Room, participant: RemoteParticipant) {
        print("Participant \(participant.identity) disconnected from \(room.name).")
    }
}

// MARK:- VideoSource
extension ViewController: VideoSource {
    var isScreencast: Bool {
        return false
    }
    
    func requestOutputFormat(_ outputFormat: VideoFormat) {
        if let sink = sink {
            sink.onVideoFormatRequest(outputFormat)
        }
    }
}
