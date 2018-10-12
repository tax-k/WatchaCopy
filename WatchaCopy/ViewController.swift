//
//  ViewController.swift
//  WatchaCopy
//
//  Created by tax_k on 12/10/2018.
//  Copyright © 2018 tax_k. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {

    @IBOutlet weak var videoPlayView: UIView!
    @IBOutlet weak var overlayView: UIView!
    
    @IBOutlet weak var bottomControlView: UIView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var rewindButton: UIButton!
    
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    
    @IBAction func timeSlideAction(_ sender: Any) {
        if let duration = player?.currentItem?.duration {
            print(duration)
            let totalSeconds = CMTimeGetSeconds(duration)
            
            let value = Float64(timeSlider.value) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            
            player.seek(to: seekTime, completionHandler: { (completedSeek) in
                
            })
        }
    }
    
    func skipForward(){
        guard let duration = player.currentItem?.duration else {
            return
        }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + 5.0
        
        if newTime < (CMTimeGetSeconds(duration) - 5.0) {
            let time: CMTime = CMTimeMake(Int64(newTime*1000), 1000)
            player.seek(to: time)
        }
    }
    func skipBackWard(){
        guard let duration = player.currentItem?.duration else {
            return
        }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - 5.0
        
        if newTime < 0 {
            newTime = 0
        }
        let time:CMTime =  CMTimeMake(Int64(newTime*1000), 1000)
        player.seek(to: time)
    }
    
    /**
     Conditional PLAY/PAUSE VIDEO
     
     - parameter sender(UIButton): nothing
     
     - returns: nope
     */
    @IBAction func playAction(_ sender: Any) {
        if isVideoPlaying {
            player.pause()
        }else {
            player.play()
//            sender.setImage(UIImage(named: "pause"), for: .normal)
        }
        
        isVideoPlaying = !isVideoPlaying
    }
    
    
    @IBAction func rewindBackAction(_ sender: Any) {
        skipBackWard()
    }
    
    var player:AVPlayer!
    var playerLayer:AVPlayerLayer!
    
    var isVideoPlaying:Bool = false
//    var isPortraitMode:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        currentTimeLabel.text = "00:00"
        
        
        timeSlider.maximumTrackTintColor = UIColor.white
//        timeSlider.minimumTrackTintColor = Colors.watchaPink
        timeSlider.setThumbImage(UIImage(named: "slider_thumb"), for: .normal)
        
        guard let path = Bundle.main.path(forResource: "game", ofType:"mp4") else {
            debugPrint("video not found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        print(url)
        player = AVPlayer(url: url)
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize
        playerLayer.frame = videoPlayView.bounds
        videoPlayView.layer.addSublayer(playerLayer)
        print("here")
        
        addTimeObserver()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        //        //첫번꺼 꺼
        if keyPath == "duration", let duration = player.currentItem?.duration.seconds, duration > 0.0{
            self.endTimeLabel.text = timeToString(from: player.currentItem!.duration)
        }
    }
    
    func timeToString(from time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let hours = Int(totalSeconds/3600)
        let minutes = Int(totalSeconds/60) % 60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hours, minutes, seconds])
        }else {
            return String(format: "%02i:%02i", arguments: [ minutes, seconds])
        }
    }
    
    func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main
        _ = player.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue, using: { [weak self] time in
            guard let currentItem = self?.player.currentItem else {return}
            self?.timeSlider.value =  Float(currentItem.currentTime().seconds / currentItem.duration.seconds)
            self?.currentTimeLabel.text = self?.timeToString(from: currentItem.currentTime())
        })
    }
    
//MARK: - Device rotate default set
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
}

