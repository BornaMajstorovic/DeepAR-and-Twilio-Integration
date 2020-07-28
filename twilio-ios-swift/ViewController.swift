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


class ViewController: UIViewController, VideoViewDelegate {
    
    // MARK: - IBOutlets -
    @IBOutlet weak var arView: ARView!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var roomTF: UITextField!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    
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
    private var currentMode: Mode!
    private var cameraController: CameraController!
    
    private var accessToken = "TWILIO_ACCESS_TOKEN"
    private var room: Room?
    internal weak var sink: VideoSink?
    private var frame: VideoFrame?
    private var displayLink: CADisplayLink?
    private var tokenUrl = "http://localhost:8000/token.php"
    
    private var videoTrack: LocalVideoTrack?
    private var audioTrack: LocalAudioTrack?
    private var remoteParticipant: RemoteParticipant?
    private var remoteView: VideoView?
    
    // MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupArView()
        setupTwilio()
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        
    }
    
    deinit {
        stop()
    }
    @IBAction func connectTapped(_ sender: UIButton) {
        
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
            builder.roomName = self.roomTF.text
        })
        
        self.room = TwilioVideoSDK.connect(options: options, delegate: self)
        self.showRoomUI(inRoom: true)
        logMessage(messageText: "Attempting to connect to room \(String(describing: self.roomTF.text))")
        
    }
    
    @IBAction func disconnectTapped(_ sender: Any) {
        self.room?.disconnect()
        logMessage(messageText: "Attempting to disconnect from room \(room!.name)")
    }
    
    @IBAction func micTapped(_ sender: Any) {
        if (self.audioTrack != nil) {
            self.audioTrack?.isEnabled = !(self.audioTrack?.isEnabled)!
            
           
            if (self.audioTrack?.isEnabled == true) {
                self.micButton.setTitle("Mute", for: .normal)
            } else {
                self.micButton.setTitle("Unmute", for: .normal)
            }
        }
    }
    
    // MARK: - Private Methods -
    private func setupTwilio(){
        
        
        self.micButton.isHidden = false
        self.disconnectButton.isHidden = false
        
        
    }
    
    private func setupArView() {
        arView.setLicenseKey("f64c4138f9309686ac9fceed46031639629f54b669cae716ca089d0c207c77059703f1e997dbd04d")
        arView.delegate = self
        cameraController = CameraController()
        cameraController.arview = arView
        
        arView.initialize()
        cameraController.startCamera()
    }
    
    func showRoomUI(inRoom: Bool) {
        self.connectButton.isHidden = inRoom
        self.roomTF.isHidden = inRoom
        self.roomLabel.isHidden = inRoom
        self.roomLabel.isHidden = inRoom
        self.micButton.isHidden = !inRoom
        self.disconnectButton.isHidden = !inRoom
        
       
        self.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    @objc private func dismissKeyboard() {
          if (self.roomTF.isFirstResponder) {
              self.roomTF.resignFirstResponder()
          }
      }
    
    
    private func start(){
        
        self.displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkDidFire))
        self.displayLink?.preferredFramesPerSecond = 15
        
        displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
    }
    
    private func stop(){
        self.sink = nil
        self.displayLink?.invalidate()
        self.cleanupRemoteParticipant()
        arView.pause()
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
    
    func setupRemoteVideoView() {
        
        self.remoteView = VideoView(frame: CGRect.zero, delegate: self)
        
        self.view.insertSubview(self.remoteView!, at: 0)
        self.remoteView?.backgroundColor = .red
        
        self.remoteView!.contentMode = .scaleAspectFit;
        
        let centerX = NSLayoutConstraint(item: self.remoteView!,
                                         attribute: NSLayoutConstraint.Attribute.centerX,
                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                         toItem: self.view,
                                         attribute: NSLayoutConstraint.Attribute.centerX,
                                         multiplier: 1,
                                         constant: 0);
        self.view.addConstraint(centerX)
        let centerY = NSLayoutConstraint(item: self.remoteView!,
                                         attribute: NSLayoutConstraint.Attribute.centerY,
                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                         toItem: self.view,
                                         attribute: NSLayoutConstraint.Attribute.centerY,
                                         multiplier: 1,
                                         constant: 0);
        self.view.addConstraint(centerY)
        let width = NSLayoutConstraint(item: self.remoteView!,
                                       attribute: NSLayoutConstraint.Attribute.width,
                                       relatedBy: NSLayoutConstraint.Relation.equal,
                                       toItem: self.view,
                                       attribute: NSLayoutConstraint.Attribute.width,
                                       multiplier: 1,
                                       constant: 0);
        self.view.addConstraint(width)
        let height = NSLayoutConstraint(item: self.remoteView!,
                                        attribute: NSLayoutConstraint.Attribute.height,
                                        relatedBy: NSLayoutConstraint.Relation.equal,
                                        toItem: self.view,
                                        attribute: NSLayoutConstraint.Attribute.height,
                                        multiplier: 1,
                                        constant: 0);
        self.view.addConstraint(height)
    }
    
    
    func renderRemoteParticipant(participant : RemoteParticipant) -> Bool {
        
        let videoPublications = participant.remoteVideoTracks
        for publication in videoPublications {
            if let subscribedVideoTrack = publication.remoteTrack,
                publication.isTrackSubscribed {
                setupRemoteVideoView()
                subscribedVideoTrack.addRenderer(self.remoteView!)
                self.remoteParticipant = participant
                return true
            }
        }
        return false
    }
    
    func renderRemoteParticipants(participants : Array<RemoteParticipant>) {
        for participant in participants {
        
            if participant.remoteVideoTracks.count > 0,
                renderRemoteParticipant(participant: participant) {
                break
            }
        }
    }
    
    func cleanupRemoteParticipant() {
        if self.remoteParticipant != nil {
            self.remoteView?.removeFromSuperview()
            self.remoteView = nil
            self.remoteParticipant = nil
        }
    }
    
    func videoViewDimensionsDidChange(view: VideoView, dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
    func logMessage(messageText: String) {
        NSLog(messageText)
        messageLabel.text = messageText
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
    
    func didInitialize() {
        currentMode = .masks
        let path = maskPaths[4]
        arView.switchEffect(withSlot: currentMode.rawValue, path: path)
        
    }
    
    func faceVisiblityDidChange(_ faceVisible: Bool) {
    }
}

// MARK:- RoomDelegate
extension ViewController: RoomDelegate {
    func roomDidConnect(room: Room) {
        logMessage(messageText: "Connected to room \(room.name) as \(room.localParticipant?.identity ?? "")")
        
        // This example only renders 1 RemoteVideoTrack at a time. Listen for all events to decide which track to render.
        for remoteParticipant in room.remoteParticipants {
            remoteParticipant.delegate = self
        }
        
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
        self.showRoomUI(inRoom: false)
    }
    
        func roomDidDisconnect(room: Room, error: Error?) {
             logMessage(messageText: "Disconnected from room \(room.name), error = \(String(describing: error))")
    
            self.cleanupRemoteParticipant()
            self.room = nil
    
            self.showRoomUI(inRoom: false)
        }
    
    func roomIsReconnecting(room: Room, error: Error) {
        logMessage(messageText: "Reconnecting to room \(room.name), error = \(String(describing: error))")
    }
    
    func roomDidReconnect(room: Room) {
        logMessage(messageText: "Reconnected to room \(room.name)")
    }
    
    func participantDidConnect(room: Room, participant: RemoteParticipant) {
        participant.delegate = self
        
        logMessage(messageText: "Participant \(participant.identity) connected with \(participant.remoteAudioTracks.count) audio and \(participant.remoteVideoTracks.count) video tracks")    }
    
    func participantDidDisconnect(room: Room, participant: RemoteParticipant) {
        logMessage(messageText: "Room \(room.name), Participant \(participant.identity) disconnected")
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


// MARK:- RemoteParticipantDelegate
extension ViewController : RemoteParticipantDelegate {
    func remoteParticipantDidPublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        // Remote Participant has offered to share the video Track.
        
        logMessage(messageText: "Participant \(participant.identity) published \(publication.trackName) video track")
    }
    
    func remoteParticipantDidUnpublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        // Remote Participant has stopped sharing the video Track.
        
        logMessage(messageText: "Participant \(participant.identity) unpublished \(publication.trackName) video track")
    }
    
    func remoteParticipantDidPublishAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        // Remote Participant has offered to share the audio Track.
        
        logMessage(messageText: "Participant \(participant.identity) published \(publication.trackName) audio track")
    }
    
    func remoteParticipantDidUnpublishAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        // Remote Participant has stopped sharing the audio Track.
        
        logMessage(messageText: "Participant \(participant.identity) unpublished \(publication.trackName) audio track")
    }
    
    func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        // The LocalParticipant is subscribed to the RemoteParticipant's video Track. Frames will begin to arrive now.
        
        logMessage(messageText: "Subscribed to \(publication.trackName) video track for Participant \(participant.identity)")
        
        if (self.remoteParticipant == nil) {
            _ = renderRemoteParticipant(participant: participant)
        }
    }
    
    func didUnsubscribeFromVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
        // remote Participant's video.
        
        logMessage(messageText: "Unsubscribed from \(publication.trackName) video track for Participant \(participant.identity)")
        
        if self.remoteParticipant == participant {
            cleanupRemoteParticipant()
            
            // Find another Participant video to render, if possible.
            if var remainingParticipants = room?.remoteParticipants,
                let index = remainingParticipants.firstIndex(of: participant) {
                remainingParticipants.remove(at: index)
                renderRemoteParticipants(participants: remainingParticipants)
            }
        }
    }
    
    func didSubscribeToAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        // We are subscribed to the remote Participant's audio Track. We will start receiving the
        // remote Participant's audio now.
        
        logMessage(messageText: "Subscribed to \(publication.trackName) audio track for Participant \(participant.identity)")
    }
    
    func didUnsubscribeFromAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
        // remote Participant's audio.
        
        logMessage(messageText: "Unsubscribed from \(publication.trackName) audio track for Participant \(participant.identity)")
    }
    
    func remoteParticipantDidEnableVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) enabled \(publication.trackName) video track")
    }
    
    func remoteParticipantDidDisableVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) disabled \(publication.trackName) video track")
    }
    
    func remoteParticipantDidEnableAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) enabled \(publication.trackName) audio track")
    }
    
    func remoteParticipantDidDisableAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) disabled \(publication.trackName) audio track")
    }
    
    func didFailToSubscribeToAudioTrack(publication: RemoteAudioTrackPublication, error: Error, participant: RemoteParticipant) {
        logMessage(messageText: "FailedToSubscribe \(publication.trackName) audio track, error = \(String(describing: error))")
    }
    
    func didFailToSubscribeToVideoTrack(publication: RemoteVideoTrackPublication, error: Error, participant: RemoteParticipant) {
        logMessage(messageText: "FailedToSubscribe \(publication.trackName) video track, error = \(String(describing: error))")
    }
}
