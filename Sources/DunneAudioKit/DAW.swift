//
//  DAW.swift
//  SimpleDaw
//
//  Created by Jodi Milliner on 12/02/2025.
//

import Foundation
import AudioKitEX
import DunneAudioKit
import AudioKit
import SwiftUI
import AVFAudio

public class DAW: Sequencer, ObservableObject{
    static public let shared = DAW()
    @Published public var _isPlaying = false{ didSet{ _isPlaying ? _play() : pause()} }
    var _tempo = 120.0{ didSet{tempo = _tempo} }
    @Published public var masters = [URL]()
    let engine = AudioEngine()
    let output = Mixer()
    var samplers = [String : Sampler]()
    @Published public var bouncing = false
    
    public init(){
        super.init()
        engine.output = output
        try! engine.start()
        initClick()
    }
    
    required init(targetNodes: [any Node]? = nil){ fatalError("init(targetNodes:) has not been implemented") }
    
    func initClick(){
        let session = URLSession.shared
        let task = session.downloadTask(with: URL(string: "https://cdn.freesound.org/previews/250/250552_4570971-lq.mp3")!){ [self] (tempLocalURL, response, error) in
            if let tempLocalURL{
                samplers["click"] = Sampler()
                addTrack(for: samplers["click"]!)
                output.addInput(samplers["click"]!)
                samplers["click"]!.load(avAudioFile: try! AVAudioFile(forReading: tempLocalURL))
                let clickTrack = getTrackFor(node: samplers["click"]!)!
                clickTrack.length = 4
                for i in 0..<4{ clickTrack.add(noteNumber: 95, velocity: 70, position: Double(i), duration: 0.99) }
                samplers["click"]!.masterVolume = 0
            }
        }
        task.resume()
    }
    
    func bounce(_ songId: String, completion: @escaping (URL)->()){
        bouncing = true
        let seconds = (tracks.last!.length/tempo) * 60.0 + 1
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(songId + "/mixes")
        let url = documentsDirectory.appendingPathComponent("songs/\(songId)/mixes/\(Date()).wav")
        try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 48000.0,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        do {
            let audioFile = try AVAudioFile(forWriting: url, settings: settings)
            try engine.renderToFile(audioFile, duration: seconds) { [self] in
                _isPlaying = false
                rewind()
                _isPlaying = true
            }
            _isPlaying = false
            try! engine.start()
            self.bouncing = false
            completion(url)
        } catch {
            print("xx Error during rendering: \(error)")
        }
    }
    
    func _play(){
        if _isPlaying{
            tempo = _tempo
            seek(to: tracks.first!.currentPosition)
            play()
        }
    }
}

extension SequencerTrack: @retroactive Identifiable, @retroactive Equatable{
    public static func == (lhs: AudioKitEX.SequencerTrack, rhs: AudioKitEX.SequencerTrack) -> Bool {
        lhs.id == rhs.id
    }
}
