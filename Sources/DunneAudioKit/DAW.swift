//
//  DAW.swift
//  SimpleDaw
//
//  Created by Jodi Milliner on 12/02/2025.
//  Da Fuq?

import Foundation
import AudioKitEX
import DunneAudioKit
import AudioKit
import SwiftUI
import AVFAudio

class DAW: Sequencer, ObservableObject{
    static let shared = DAW()
    @Published var _isPlaying = false{ didSet{ _isPlaying ? _play() : pause()} }
    @Published var masters = [URL]()
    let engine = AudioEngine()
    let output = Mixer()
    var samplers = [String : Sampler]()
    @Published var bouncing = false
    
    init(){
        super.init()
        engine.output = output
        try! engine.start()
        initClick()
    }
    
    required init(targetNodes: [any Node]? = nil){ fatalError("init(targetNodes:) has not been implemented") }
    
    func initClick(){
        samplers["click"] = Sampler()
        addTrack(for: samplers["click"]!)
        output.addInput(samplers["click"]!)
        samplers["click"]!.load(avAudioFile: try! AVAudioFile(forReading: Bundle.module.url(forResource: "click", withExtension: "wav")!))
        let clickTrack = getTrackFor(node: samplers["click"]!)!
        clickTrack.length = 4
        for i in 0..<4{ clickTrack.add(noteNumber: 95, velocity: 70, position: Double(i), duration: 0.99) }
        samplers["click"]!.masterVolume = 0
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
//            FB.upload(url){  }
        } catch {
            print("xx Error during rendering: \(error)")
        }
    }
    
    func _play(){
        if _isPlaying{
//            if let tempo = activeSong?.parameters["tempo"]?.value.d{
//                self.tempo = tempo
//            }
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
