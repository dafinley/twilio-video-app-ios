//
//  Copyright (C) 2020 Twilio, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import TwilioVideo

@objc class VideoAppCameraSource: NSObject, VideoAppCamera {
    private(set) var localVideoTrack: LocalVideoTrack?
    private let appSettingsStore: AppSettingsStoreWriting = AppSettingsStore.shared
    private weak var localMediaController: LocalMediaController!
    private var cameraSource: CameraSource?

    @objc init(localMediaController: LocalMediaController) {
        self.localMediaController = localMediaController
        super.init()
        createCameraSource()
    }
    
    deinit {
        cameraSource?.stopCapture()
    }

    func destroyLocalVideoTrack() {
        cameraSource?.stopCapture() { [weak self] _ in
            self?.localVideoTrack = nil
            self?.cameraSource = nil
        }
    }
    
    func flip() {
        guard
            let cameraSource = cameraSource,
            let position = cameraSource.device?.position,
            let captureDevice = CameraSource.captureDevice(position: position == .front ? .back : .front)
            else {
                return
        }
        
        cameraSource.selectCaptureDevice(captureDevice) { [weak self] _, _, error in
            guard error == nil else { return }
            
            self?.localMediaController.videoCaptureStarted()
        }
    }

    func shouldMirrorLocalVideoView() -> Bool {
        localVideoTrack?.shouldMirror ?? false
    }

    private func createCameraSource() {
        let options = CameraSourceOptions() { builder in
            if #available(iOS 13, *) {
                builder.orientationTracker = UserInterfaceTracker(scene: UIApplication.shared.keyWindow!.windowScene!)
            }
            
            switch self.appSettingsStore.topology {
            case .group: builder.rotationTags = .remove
            case .peerToPeer: break
            }
        }
        
        cameraSource = CameraSource(options: options, delegate: self)
        
        if let cameraSource = cameraSource {
            localVideoTrack = LocalVideoTrack(source: cameraSource, enabled: true, name: "camera")
            startCameraSource()
        }
    }
    
    private func startCameraSource() {
        guard let cameraSource = cameraSource else { return }

        let targetSize: CMVideoDimensions
        let cropRatio: CGFloat
        let frameRate: UInt
        
        switch appSettingsStore.videoCodec {
        case .h264, .vp8:
            targetSize = CMVideoDimensions(width: 544, height: 480)
            cropRatio = CGFloat(targetSize.width) / CGFloat(targetSize.height)
            frameRate = 20
        case .vp8Simulcast:
            targetSize = CMVideoDimensions(width: 900, height: 720)
            cropRatio = CGFloat(targetSize.width) / CGFloat(targetSize.height)
            frameRate = 24
        }
        
        let captureDevice = CameraSource.captureDevice(position: .front)!
        let preferredFormat = selectVideoFormatBySize(captureDevice: captureDevice, targetSize: targetSize)
        preferredFormat.frameRate = min(preferredFormat.frameRate, frameRate)
        
        let cropDimensions: CMVideoDimensions
        
        if preferredFormat.dimensions.width > preferredFormat.dimensions.height {
            cropDimensions = CMVideoDimensions(
                width: Int32(CGFloat(preferredFormat.dimensions.height) * cropRatio),
                height: preferredFormat.dimensions.height
            )
        } else {
            cropDimensions = CMVideoDimensions(
                width: preferredFormat.dimensions.width,
                height: Int32(CGFloat(preferredFormat.dimensions.width) * cropRatio)
            )
        }
        
        let outputFormat = VideoFormat()
        outputFormat.dimensions = cropDimensions
        outputFormat.pixelFormat = preferredFormat.pixelFormat
        outputFormat.frameRate = 0
        
        cameraSource.requestOutputFormat(outputFormat)
        
        cameraSource.startCapture(device: captureDevice, format: preferredFormat) { [weak self] _, _, error in
            guard error == nil else { return }
            
            self?.localMediaController.videoCaptureStarted()
        }
    }
        
    private func selectVideoFormatBySize(captureDevice: AVCaptureDevice, targetSize: CMVideoDimensions) -> VideoFormat {
        let supportedFormats = Array(CameraSource.supportedFormats(captureDevice: captureDevice)) as! [VideoFormat]
        
        for format in supportedFormats {
            guard
                format.pixelFormat == .formatYUV420BiPlanarFullRange &&
                    format.dimensions.width >= targetSize.width &&
                    format.dimensions.height >= targetSize.height
                else {
                    continue
            }
            
            return format
        }
        
        fatalError()
    }
}

extension VideoAppCameraSource: CameraSourceDelegate {
    func cameraSourceInterruptionEnded(source: CameraSource) {
        localMediaController.cameraSourceInterruptionEnded()
    }

    func cameraSourceWasInterrupted(source: CameraSource, reason: AVCaptureSession.InterruptionReason) {
        localMediaController.cameraSourceWasInterrupted()
    }
}
