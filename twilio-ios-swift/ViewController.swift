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
            //            updateModeAppearance()
        }
    }
    
    private var accessToken = "TWILIO_ACCESS_TOKEN"
    private var room: Room?
    internal weak var sink: VideoSink?
    private var frame: VideoFrame?
    private var displayLink: CADisplayLink?
    
    private var videoTrack: LocalVideoTrack?
    private var audioTrack: LocalAudioTrack?
    
    // MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // MARK: - Private Methods -
    
    private func setupArView() {
        arView.setLicenseKey("your_license_key_goes_here")
        arView.delegate = self
        arView.initialize()
        arView.isHidden = true
    }
    
    private func addTargets() {
        switchCameraButton.addTarget(self, action: #selector(didTapSwitchCameraButton), for: .touchUpInside)
        previousButton.addTarget(self, action: #selector(didTapPreviousButton), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didTapNextButton), for: .touchUpInside)
        masksButton.addTarget(self, action: #selector(didTapMasksButton), for: .touchUpInside)
        effectsButton.addTarget(self, action: #selector(didTapEffectsButton), for: .touchUpInside)
        filtersButton.addTarget(self, action: #selector(didTapFiltersButton), for: .touchUpInside)
    }
    
    private func switchMode(_ path: String?) {
        arView.switchEffect(withSlot: currentMode.rawValue, path: path)
    }
    
    private func start(){
        
    }
    
    private func stop(){
        
    }
    
    @objc
    private func didTapSwitchCameraButton() {
        //        let position: AVCaptureDevice.Position = arView.getCameraPosition() == .back ? .front : .back
        //        arView.switchCamera(position)
        //        camera controleru je sad to
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
    
    
}

// MARK: - ARViewDelegate -

extension ViewController: ARViewDelegate {
    func didFinishPreparingForVideoRecording() {}
    
    func didStartVideoRecording() {}
    
    func frameAvailable(_ sampleBuffer: CMSampleBuffer!) {
        
        //        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
        //            print("*** NO BUFFER ERROR")
        //            return
        //        }
        //
        //        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        //
        //        let videoFrame = AgoraVideoFrame()
        //        videoFrame.format = 12
        //        videoFrame.textureBuf = pixelBuffer
        //        videoFrame.time = time
        //        agoraKit?.pushExternalVideoFrame(videoFrame)
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
        // We want fluid AR content, maintaining the original frame rate.
        return false
    }
    
    func requestOutputFormat(_ outputFormat: VideoFormat) {
        if let sink = sink {
            sink.onVideoFormatRequest(outputFormat)
        }
    }
}
