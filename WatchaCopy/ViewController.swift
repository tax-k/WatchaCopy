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

class ViewController: UIViewController, UIGestureRecognizerDelegate{
    //MARK: - IBOutlet
    @IBOutlet weak var videoPlayView: UIView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var topControlView: UIView!
    @IBOutlet weak var bottomControlView: UIView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    
    @IBOutlet weak var controlLevelImageView: UIImageView!
    @IBOutlet weak var indicatorWrapperView: UIView!
    @IBOutlet weak var maxIndicatorView: UIView!
    
    @IBOutlet weak var indicatorWidthConst: NSLayoutConstraint!
    
    @IBOutlet weak var topViewPositionConst: NSLayoutConstraint!
    @IBOutlet weak var bottomViewPositionConst: NSLayoutConstraint!
    
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var lockButton: UIButton!
    
    @IBAction func lockAction(_ sender: Any) {
        if isLocked {
            lockButton.setImage(UIImage(named: "unlock"), for: .normal)
            overlayView.isUserInteractionEnabled = true
        }else {
            lockButton.setImage(UIImage(named: "lock"), for: .normal)
            overlayView.isUserInteractionEnabled = false
        }
        isLocked = !isLocked
    }
    
    var isLocked:Bool = false
    var isLeft:Bool = false
    var isTouching:Bool = false
    var panDir:Int = 0
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
    
    func setTopConbtrolViewGradient() {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0, green: 0, blue: 0, alpha: 0.8).cgColor,
            UIColor(red: 0, green: 0, blue: 0, alpha: 0.0).cgColor
        ]
        gradient.locations = [0.0 , 0.5]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.frame = topControlView.layer.frame
        topControlView.layer.insertSublayer(gradient, at: 0)
    }
    
    func setBottomControlViewGradient() {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0, green: 0, blue: 0, alpha: 0.0).cgColor,
            UIColor(red: 0, green: 0, blue: 0, alpha: 0.8).cgColor
        ]
        gradient.locations = [0.0 , 0.5]
        gradient.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.frame = bottomControlView.layer.frame
//        bottomControlView.layer.insertSublayer(gradient, at: 0)
        bottomControlView.layer.addSublayer(gradient)
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
    Add timer to check controlView Show/Hide
    */
    var seconds = 5
    var timer = Timer()
    var isTimerRunning:Bool = false
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        /*if touching end*/
        if !isTouching {
            seconds -= 1
            print(seconds)
            
            if seconds == 0 {
                UIView.animate(withDuration: 1, delay: 0.0, options: [], animations: {
                    self.topViewPositionConst.constant = -60
                    self.bottomViewPositionConst.constant = -50
                    self.view.layoutIfNeeded()
                }, completion: { (finished: Bool) in
                    self.timer.invalidate()
                    self.seconds = 5
                })
            }
        }
    }
    
    /**
     Conditional PLAY/PAUSE VIDEO
     
     - parameter sender(UIButton): nothing
     
     - returns: nope
     */
    @IBAction func playAction(_ sender: Any) {
        if isVideoPlaying {
            player.pause()
            playButton.setImage(UIImage(named: "play2"), for: .normal)
        }else {
            player.play()
            playButton.setImage(UIImage(named: "pause2"), for: .normal)
        }
        isVideoPlaying = !isVideoPlaying
    }
    
    @IBAction func rewindBackAction(_ sender: Any) {
        skipBackWard()
    }
    
    func addDoubleTapGesture() -> UITapGestureRecognizer{
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        tap.cancelsTouchesInView = true
        overlayView.addGestureRecognizer(tap)
        
        return tap
    }
    
    func addOneTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(oneTapped))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.require(toFail: addDoubleTapGesture())
        tap.cancelsTouchesInView = true
        overlayView.addGestureRecognizer(tap)
    }
    
    var player:AVPlayer!
    var playerLayer:AVPlayerLayer!
    var isVideoPlaying:Bool = false
    
    // MARK: - Volume Control
    let maxVal:Float = 1.0
    
    var volumeView = (MPVolumeView().subviews.filter{
        NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)
    var volume:Float = ((MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.value)!
    
    func checkCurrentControlLevel(_ isLeft: Bool){
        indicatorWrapperView.isHidden = false
        if isLeft {
            var brightness: Float = Float(UIScreen.main.brightness)
            if brightness >= 0.8 {
                controlLevelImageView.image = UIImage(named: "bright-high")
            }else if brightness > 0.2 && brightness < 0.8 {
                controlLevelImageView.image = UIImage(named: "bright-mid")
            }else {
                controlLevelImageView.image = UIImage(named: "bright-low")
            }
        }else {
            if volume >= 0.7 {
                controlLevelImageView.image = UIImage(named: "volume-high")
            }else if volume > 0.2 && volume < 0.7 {
                controlLevelImageView.image = UIImage(named: "volume-mid")
            }else {
                controlLevelImageView.image = UIImage(named: "volume-low")
            }
        }
    }
    
    
    // MARK: - Lifecycle - viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        titleLable.text = String(volume)
        checkCurrentControlLevel(isLeft)
        indicatorWrapperView.isHidden = true
        
        setTopConbtrolViewGradient()
        setBottomControlViewGradient()
        addOneTapGesture()
        addDoubleTapGesture()
        runTimer()
        
        let volumeView = MPVolumeView(frame: CGRect(x: -100, y: -100, width: 0, height: 0))
        view.addSubview(volumeView)
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
        setGestureRecog()
    }
    // MARK: - Lifecycle - viewWillApper()
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    // MARK: ovverride
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            isTouching = true
            let location = touch.location(in: self.view)
            
            if location.x < self.view.frame.size.width/2 {
                print("Left")
                isLeft = true
            }else {
                print("Right")
                isLeft = false
            }
        }
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        //        //첫번꺼 꺼
        if keyPath == "duration", let duration = player.currentItem?.duration.seconds, duration > 0.0{
            self.endTimeLabel.text = timeToString(from: player.currentItem!.duration)
        }
    }
    
    func setGestureRecog(){
        let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(pan(recognizer:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        self.overlayView.addGestureRecognizer(panGesture)
    }
    
    @objc
    func pan(recognizer:UIPanGestureRecognizer) {
        let maxIndcatorWidth = maxIndicatorView.frame.size.width
        
        if recognizer.state == UIGestureRecognizerState.changed {
            let velocity:CGPoint = recognizer.velocity(in: self.view)
//            let yTranslation = recognizer.translation(in: self.view).y
            
            
            let direction = recognizer.direction(in: self.view)
            
            print(direction)
            
            if direction.contains(.Right){
                if let currTime = player?.currentItem?.currentTime().seconds{
                    
                    let value = currTime + 5
                    let seekTime = CMTime(value: Int64(value), timescale: 1)
                    player.seek(to: seekTime, completionHandler: { (completedSeek) in

                    })
                }
            }else if direction.contains(.Left){
                if let currTime = player?.currentItem?.currentTime().seconds{
                    
                    let value = currTime - 5
                    let seekTime = CMTime(value: Int64(value), timescale: 1)
                    player.seek(to: seekTime, completionHandler: { (completedSeek) in
                        
                    })
                }
            }
            else if direction.contains(.Up){
                volume = volume + 0.01
                volumeView?.setValue(volume, animated: false)
            }
            
            if direction.contains(.Left) && direction.contains(.Down) {
                // do stuff
            } else if direction.contains(.Up) {
                // ...
            }
            
            if isLeft {
                if velocity.y > 0 {
                    var brightness: Float = Float(UIScreen.main.brightness)
                    
                    brightness = brightness - 0.01
                    
                    UIScreen.main.brightness = CGFloat(brightness)
                    
                    checkCurrentControlLevel(isLeft)
                    UIView.animate(withDuration: 0, delay: 0.0, options: [], animations: {
                        self.indicatorWidthConst.constant = maxIndcatorWidth * CGFloat(brightness)
                        self.view.layoutIfNeeded()
                    })
                }else {
                    var brightness: Float = Float(UIScreen.main.brightness)
                    brightness = brightness + 0.01
                    UIScreen.main.brightness = CGFloat(brightness)
                    checkCurrentControlLevel(isLeft)
                    UIView.animate(withDuration: 0, delay: 0.0, options: [], animations: {
                        self.indicatorWidthConst.constant = maxIndcatorWidth * CGFloat(brightness)
                        self.view.layoutIfNeeded()
                    })
                }
            }else {
                if velocity.y > 0 {
                    
                    volume = volume - 0.02
                    if volume < 0 {
                        volume = 0
                    }
                    checkCurrentControlLevel(isLeft)
                    UIView.animate(withDuration: 0, delay: 0.0, options: [], animations: {
                        self.indicatorWidthConst.constant = maxIndcatorWidth * CGFloat(self.volume)
                        self.view.layoutIfNeeded()
                    })
                    volumeView?.setValue(volume, animated: false)
                    print(volume)
                }else {
                    //음향 감소
                    
                    print("y else 0")
                    volume = volume + 0.02
                    if volume > 1 {
                        volume = 1
                    }
                    checkCurrentControlLevel(isLeft)
                    UIView.animate(withDuration: 0, delay: 0.0, options: [], animations: {
                        self.indicatorWidthConst.constant = maxIndcatorWidth * CGFloat(self.volume)
                        self.view.layoutIfNeeded()
                    })
                    volumeView?.setValue(volume, animated: false)
                    print(volume)
                }
            }
        }
        else if recognizer.state == .ended {
            isTouching = false
        }
    }
    
    // MARK: double tap to play/pause
    @objc
    func doubleTapped() {
        if isVideoPlaying {
            player.pause()
            playButton.setImage(UIImage(named: "play2"), for: .normal)
        }else {
            player.play()
            playButton.setImage(UIImage(named: "pause2"), for: .normal)
        }
        isVideoPlaying = !isVideoPlaying
    }
    
    @objc
    func oneTapped() {
        UIView.animate(withDuration: 1, delay: 0.0, options: [], animations: {
            self.topViewPositionConst.constant = 0
            self.bottomViewPositionConst.constant = 0
            self.view.layoutIfNeeded()
        }, completion: { (finished: Bool) in
//            UIView.animate(withDuration: 1, delay: 5.0, options: [], animations: {
//                self.topViewPositionConst.constant = -60
//                self.bottomViewPositionConst.constant = -50
//                self.view.layoutIfNeeded()
//            })
        })
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
    
    // MARK: - Device rotate default set
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
}

extension UIPanGestureRecognizer {
    
    public struct PanGestureDirection: OptionSet {
        public let rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        static let Up = PanGestureDirection(rawValue: 1 << 0)
        static let Down = PanGestureDirection(rawValue: 1 << 1)
        static let Left = PanGestureDirection(rawValue: 1 << 2)
        static let Right = PanGestureDirection(rawValue: 1 << 3)
    }
    
    private func getDirectionBy(velocity: CGFloat, greater: PanGestureDirection, lower: PanGestureDirection) -> PanGestureDirection {
        if velocity == 0 {
            return []
        }
        return velocity > 0 ? greater : lower
    }
    
    public func direction(in view: UIView) -> PanGestureDirection {
        let velocity = self.velocity(in: view)
        let yDirection = getDirectionBy(velocity: velocity.y, greater: PanGestureDirection.Down, lower: PanGestureDirection.Up)
        let xDirection = getDirectionBy(velocity: velocity.x, greater: PanGestureDirection.Right, lower: PanGestureDirection.Left)
        return xDirection.union(yDirection)
    }
}

