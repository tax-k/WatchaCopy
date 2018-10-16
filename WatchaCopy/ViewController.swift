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

enum panAxis : Int {
    case upDown
    case leftRight
    case defaults
}

enum detailDirAxis : Int {
    case top
    case right
    case bottom
    case left
}

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
    
    var axis:Int = 0
    var startingPoint:CGPoint?
    var startingCenter:CGPoint?
    
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
    var panDir:String = ""
    
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
        
//        makeSwipaActionStable()
        setGestureRecog()
//        let swipeGestures = setupSwipeGestures()
//        setupPanGestures(swipeGestures: swipeGestures)
    }
    
    /// set swipe direction
    ///
    /// - Parameter: nope
    /// - Returns: list of gesturerecognizer
    /// - not used
    private func setupSwipeGestures() -> [UISwipeGestureRecognizer] {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        overlayView.addGestureRecognizer(swipeUp)
        overlayView.addGestureRecognizer(swipeDown)
        overlayView.addGestureRecognizer(swipeRight)
        overlayView.addGestureRecognizer(swipeLeft)
        
        return [swipeUp, swipeDown, swipeRight, swipeLeft]
    }
    
    /// set swipe gesture recognizer
    ///
    /// - Parameter: list of gesturerecognizer
    /// - Returns: nope
    /// - not used
    private func setupPanGestures(swipeGestures: [UISwipeGestureRecognizer]) {
        let panGesture = UIPanGestureRecognizer.init(target: self, action:#selector(pan(recognizer:)))
        for swipeGesture in swipeGestures {
            panGesture.require(toFail: swipeGesture)
        }
        overlayView.addGestureRecognizer(panGesture)
    }
    
    
    // MARK: - Make Swipe Action Stable
    /// - not used
    @objc
    func swiped(gesture: UIGestureRecognizer)
    {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer
        {
            switch swipeGesture.direction
            {
                
            case UISwipeGestureRecognizerDirection.right:
                print("Swiped Right")
                panDir = "right"
            case UISwipeGestureRecognizerDirection.left:
                print("Swiped Left")
                panDir = "left"
            case UISwipeGestureRecognizerDirection.up:
                print("Swiped Up")
                panDir = "up"
            case UISwipeGestureRecognizerDirection.down:
                print("Swiped Down")
                panDir = "down"
            default:
                break
            }
        }
    }
    
    
    
    /// set horizontal gesture to control Seek
    ///
    /// - Parameter: (recognizer: PangestureRecognizer)
    /// - Returns: nope
    func controlHorizonSeek(_ recognizer: UIPanGestureRecognizer) {
        let Translation = recognizer.translation(in: self.view)
        let hrPoint = CGPoint(x: Translation.x, y:0)
        let detectionLimit:CGFloat = 10
        if hrPoint.x > detectionLimit {
            print("Gesture went right")
            if let currTime = player?.currentItem?.currentTime().seconds{
                
                let value = currTime + 5
                let seekTime = CMTime(value: Int64(value), timescale: 1)
                player.seek(to: seekTime, completionHandler: { (completedSeek) in
                    
                })
            }
            
        }else if hrPoint.x < -detectionLimit {
            print("Gesture went left")
            if let currTime = player?.currentItem?.currentTime().seconds{
                
                let value = currTime - 5
                let seekTime = CMTime(value: Int64(value), timescale: 1)
                player.seek(to: seekTime, completionHandler: { (completedSeek) in
                    
                })
            }
        }
    }
    
    /// set vertical gesture to control Brightness
    ///
    /// - Parameter: (recognizer: PangestureRecognizer)
    /// - Returns: nope
    func controlVerticalBrightness(_ recognizer: UIPanGestureRecognizer) {
        let maxIndcatorWidth = maxIndicatorView.frame.size.width
        let vtDetectionLimit:CGFloat = 5
        let Translation = recognizer.translation(in: self.view)
        let vrPoint = CGPoint(x: 0, y:Translation.y)
        if vrPoint.y > 0 {
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
    }
    /// set vertical gesture to control Volume
    ///
    /// - Parameter: (recognizer: PangestureRecognizer)
    /// - Returns: nope
    func controlVerticalVolume(_ recognizer: UIPanGestureRecognizer) {
        let maxIndcatorWidth = maxIndicatorView.frame.size.width
        let vtDetectionLimit:CGFloat = 5
        let Translation = recognizer.translation(in: self.view)
        let vrPoint = CGPoint(x: 0, y:Translation.y)
        if vrPoint.y > 0 {
            
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
        }else {
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
        }
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
        self.view.addGestureRecognizer(panGesture)
    }
    
    @objc
    func pan(recognizer:UIPanGestureRecognizer) {
        
        let detectionLimit:CGFloat = 10
        let tempPoint: CGPoint = recognizer.location(in: view)
        switch recognizer.state {
        case .began:
            axis = panAxis.defaults.rawValue
            startingPoint = tempPoint
            startingCenter = recognizer.view?.center
        case .changed:
            switch axis {
            case panAxis.defaults.rawValue:
                if fabsf(Float(tempPoint.x - startingPoint!.x)) > fabsf(Float(tempPoint.y - startingPoint!.y)) && fabs(Float(tempPoint.x - (startingPoint?.x)!)) > 20 {
                    axis = panAxis.leftRight.rawValue
                }else if fabsf(Float(tempPoint.x - startingPoint!.x)) < fabsf(Float(tempPoint.y - startingPoint!.y)) && fabs(Float(tempPoint.y - (startingPoint?.y)!)) > 20 {
                    axis = panAxis.upDown.rawValue
                }
            case panAxis.leftRight.rawValue:
                print("hr")
                controlHorizonSeek(recognizer)
            case panAxis.upDown.rawValue:
                print("vr")
                if isLeft {
                    controlVerticalVolume(recognizer)
                }else {
                    controlVerticalVolume(recognizer)
                }
            default:
                break
            }
        case .ended:
            axis = panAxis.defaults.rawValue
        default:
            break
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

