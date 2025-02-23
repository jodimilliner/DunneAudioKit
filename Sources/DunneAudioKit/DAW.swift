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

struct PlayButton: View{
    @ObservedObject var daw = DAW.shared
    
    var body: some View {
//        TimelineView(.animation){ _ in
//            Group{
//                if !daw._isPlaying{
                Rectangle().frame(width: 25, height: 25).opacity(0.001).overlay{
                    Image(systemName: daw._isPlaying ? "pause.fill" : "play.fill").font(.title3)
                }
//                }
//                else{
//                    HStack(spacing: 5){
//                        ForEach(0..<4, id: \.self){ i in
//                            Circle().frame(width: 5)
//                                .opacity(i == Int(daw.tracks.first!.currentPosition)%4 ? 1 : 0.25)
////                                .id(t.date)
//                        }
//                    }
//                    .padding(.vertical, 2)
//                    .background(Rectangle().opacity(0.001))
//                }
//            }
            .onTapGesture {
                daw._isPlaying.toggle()
            }
            .background{
                Button(".space"){ daw._isPlaying.toggle() }.keyboardShortcut(.space, modifiers: []).opacity(0.001)
            }
//        }
    }
}

class DAW: Sequencer, ObservableObject{
    static let shared = DAW()
    @Published var _isPlaying = false{ didSet{ _isPlaying ? _play() : pause()} }
    @Published var activeSong: CoreSong!
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
        FileManager.download("https://cdn.freesound.org/previews/250/250552_4570971-lq.mp3"){ [self] url, _ in
            if let url{
                samplers["click"] = Sampler()
                addTrack(for: samplers["click"]!)
                output.addInput(samplers["click"]!)
                samplers["click"]!.load(avAudioFile: try! AVAudioFile(forReading: url))
                let clickTrack = getTrackFor(node: samplers["click"]!)!
                clickTrack.length = 4
                for i in 0..<4{ clickTrack.add(noteNumber: 95, velocity: 70, position: Double(i), duration: 0.99) }
                samplers["click"]!.masterVolume = 0
            }
        }
    }
    
    func bounce(){
        bouncing = true
        let seconds = (tracks.last!.length/tempo) * 60.0 + 1
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(activeSong.data.id + "/mixes")
        let url = documentsDirectory.appendingPathComponent("songs/\(activeSong.data.id)/mixes/\(Date()).wav")
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
            FB.upload(url){ self.bouncing = false }
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
