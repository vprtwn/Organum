//
//  AKWhiteNoise.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright (c) 2016 Aurelius Prochazka. All rights reserved.
//

import AVFoundation

/// White noise generator
///
/// - parameter amplitude: Amplitude. (Value between 0-1).
///
public class AKWhiteNoise: AKVoice {

    // MARK: - Properties

    internal var internalAU: AKWhiteNoiseAudioUnit?
    internal var token: AUParameterObserverToken?

    private var amplitudeParameter: AUParameter?

    /// Inertia represents the speed at which parameters are allowed to change
    public var inertia: Double = 0.0002 {
        willSet(newValue) {
            if inertia != newValue {
                internalAU?.inertia = newValue
                internalAU?.setUpParameterRamp()
            }
        }
    }
    
    /// Amplitude. (Value between 0-1).
    public var amplitude: Double = 1 {
        willSet(newValue) {
            if amplitude != newValue {
                amplitudeParameter?.setValue(Float(newValue), originator: token!)
            }
        }
    }

    /// Tells whether the node is processing (ie. started, playing, or active)
    override public var isStarted: Bool {
        return internalAU!.isPlaying()
    }
    
    // MARK: - Initialization
    
    /// Initialize the noise generator with defaults
    public convenience override init() {
        self.init(amplitude: 1.0)
    }

    /// Initialize this noise node
    ///
    /// - parameter amplitude: Amplitude. (Value between 0-1).
    ///
    public init(amplitude: Double) {

        self.amplitude = amplitude

        var description = AudioComponentDescription()
        description.componentType         = kAudioUnitType_Generator
        description.componentSubType      = 0x776e6f7a /*'wnoz'*/
        description.componentManufacturer = 0x41754b74 /*'AuKt'*/
        description.componentFlags        = 0
        description.componentFlagsMask    = 0

        AUAudioUnit.registerSubclass(
            AKWhiteNoiseAudioUnit.self,
            asComponentDescription: description,
            name: "Local AKWhiteNoise",
            version: UInt32.max)

        super.init()
        AVAudioUnit.instantiateWithComponentDescription(description, options: []) {
            avAudioUnit, error in

            guard let avAudioUnitGenerator = avAudioUnit else { return }

            self.avAudioNode = avAudioUnitGenerator
            self.internalAU = avAudioUnitGenerator.AUAudioUnit as? AKWhiteNoiseAudioUnit

            AudioKit.engine.attachNode(self.avAudioNode)
        }

        guard let tree = internalAU?.parameterTree else { return }

        amplitudeParameter = tree.valueForKey("amplitude") as? AUParameter

        token = tree.tokenByAddingParameterObserver {
            address, value in

            dispatch_async(dispatch_get_main_queue()) {
                if address == self.amplitudeParameter!.address {
                    self.amplitude = Double(value)
                }
            }
        }
        amplitudeParameter?.setValue(Float(amplitude), originator: token!)
    }

    /// Function create an identical new node for use in creating polyphonic instruments
    public override func duplicate() -> AKVoice {
        let copy = AKWhiteNoise(amplitude: self.amplitude)
        return copy
    }

    /// Function to start, play, or activate the node, all do the same thing
    public override func start() {
        self.internalAU!.start()
    }

    /// Function to stop or bypass the node, both are equivalent
    public override func stop() {
        self.internalAU!.stop()
    }
}
