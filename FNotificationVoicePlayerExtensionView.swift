//
//  FNotificationVoicePlayerExtensionView.swift
//  FInAppNotification
//
//  Created by Firas Al Khatib Al Khalidi on 7/5/17.
//  Copyright © 2017 Firas Al Khatib Al Khalidi. All rights reserved.
//

import UIKit
import AVFoundation
class FNotificationVoicePlayerExtensionView: FNotificationExtensionView {
    var audioPlayer                   : AVPlayer!
    var timeObserver                  : Any?
    var didPlayRecording              : (()-> Void)?
    override var height  : CGFloat{
        return 100
    }
    var dataUrl: String!{
        didSet{
            guard dataUrl != nil else {
                return
            }
            audioPlayer = AVPlayer(playerItem: AVPlayerItem(asset: AVAsset(url: URL(fileURLWithPath: dataUrl))))
            NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: audioPlayer.currentItem!)
            timeSlider.minimumValue = 0
            timeSlider.maximumValue = Float(audioPlayer.currentItem!.asset.duration.seconds)
            timeSlider.value = Float(audioPlayer.currentTime().seconds)
            timeSlider.isEnabled      = true
            playPauseButton.isEnabled = true
            addTimeObserver()
            timeLabel.text = initialTimeString
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
            addGestureRecognizer(tapGestureRecognizer)
            tapGestureRecognizer.delegate = self
        }
    }
    func viewTapped(){
        
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    @IBOutlet weak var timeSlider     : UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    var didFinishPlaying = false
    @objc private func itemDidFinishPlaying(){
        timeSlider.setValue(0, animated: true)
        playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        audioPlayer.currentItem?.seek(to: CMTime(seconds: 0, preferredTimescale: 1), completionHandler: { (completed) in
            self.didFinishPlaying = true
            self.timeLabel.text = self.initialTimeString
        })
    }
    private var initialTimeString: String{
        let time    = Int(audioPlayer.currentItem!.asset.duration.seconds)
        let minutes = time/60
        let seconds = time-(minutes*60)
        var timeString = ""
        if minutes < 10{
            timeString = "0\(minutes)"
        }
        else{
            timeString = "\(minutes)"
        }
        if seconds < 10{
            timeString = timeString + ":0\(seconds)"
        }
        else{
            timeString = timeString + ":\(seconds)"
        }
        return timeString
    }
    private var currentTimeString: String{
        let time    = Int(audioPlayer.currentItem!.currentTime().seconds)
        let minutes = time/60
        let seconds = time-(minutes*60)
        var timeString = ""
        if minutes < 10{
            timeString = "0\(minutes)"
        }
        else{
            timeString = "\(minutes)"
        }
        if seconds < 10{
            timeString = timeString + ":0\(seconds)"
        }
        else{
            timeString = timeString + ":\(seconds)"
        }
        if audioPlayer.rate == 0 && seconds == 0{
            return initialTimeString
        }
        return timeString
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        addPlayPauseButtonBorder()
    }
    
    private func addPlayPauseButtonBorder(){
        playPauseButton.layer.cornerRadius  = 5
        playPauseButton.layer.masksToBounds = true
        playPauseButton.layer.borderColor   = UIColor.white.cgColor
        playPauseButton.layer.borderWidth   = 1
    }
    
    private func addTimeObserver(){
        timeObserver = audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.main) { (time) in
            if !self.timeSlider.isHighlighted{
                DispatchQueue.main.async {
                    guard self.audioPlayer != nil else{
                        return
                    }
                    self.timeSlider.value = Float(self.audioPlayer.currentTime().seconds)
                    self.timeLabel.text = self.currentTimeString
                }
            }
        }
    }
    @IBAction func timeSliderValueChanged(_ sender: UISlider) {
        guard audioPlayer != nil else{
            return
        }
        var wasPlaying = false
        if audioPlayer.rate != 0{
            audioPlayer.pause()
            wasPlaying = true
        }
        if timeObserver != nil{
            audioPlayer.removeTimeObserver(timeObserver!)
        }
        audioPlayer.currentItem?.seek(to: CMTime(seconds: Double(sender.value)+0.5, preferredTimescale: 1), completionHandler: { (Bool) in
            guard self.audioPlayer != nil else{
                return
            }
            self.addTimeObserver()
            self.timeLabel.text = self.currentTimeString
            if wasPlaying{
                self.audioPlayer.play()
                self.playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            }
        })
    }
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        didPlayRecording?()
        didPlayRecording = nil
        if audioPlayer.rate != 0{
            audioPlayer.pause()
            playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        }
        else{
            audioPlayer.play()
            playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        }
    }
}
extension FNotificationVoicePlayerExtensionView: UIGestureRecognizerDelegate{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
