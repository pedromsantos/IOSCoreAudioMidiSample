import Foundation
import AudioToolbox

public class MIDIDevice : NSObject {
    private var instrumentAudioUnit = AudioUnit()
    private var processingGraph = AUGraph()
    
    public override init() {
        super.init()
        setupAudioUnitGraph()
        initializeAudioUnitGraph()
        startAudioUnitGraph()
    }
    
    public func programChange(
        instrument:MIDIInstruments = MIDIInstruments.AcousticGrandPiano) {
        var midiCommand:UInt32 = 0xC0 | 0;
        let status:OSStatus = MusicDeviceMIDIEvent(
            self.instrumentAudioUnit,
            midiCommand,
            UInt32(instrument.rawValue),
            0,
            0)
        
        assert(status == noErr, "Could not change instrument")
    }
    
    public func noteOn(noteNum:UInt32, velocity:UInt32)    {
        var midiCommand:UInt32 = 0x90 | 0;
        let status:OSStatus = MusicDeviceMIDIEvent(
            self.instrumentAudioUnit,
            midiCommand,
            noteNum,
            velocity,
            0)
        assert(status == noErr, "Could not play note")
    }
    
    public func noteOff(noteNum:UInt32)    {
        var midiCommand:UInt32 = 0x80 | 0;
        let status:OSStatus = MusicDeviceMIDIEvent(self.instrumentAudioUnit, midiCommand, noteNum, 0, 0)
        assert(status == noErr, "Could not stop note")
    }
    
    private func setupAudioUnitGraph() {
        let status:OSStatus = NewAUGraph(&self.processingGraph)
        assert(status == noErr, "Could not create Audio Unit Graph")
        
        var instrumentNode = addSamplerAudioUnitNodeToGraph()
        var ioNode = addIOAudioUnitNodeToGraph()
        connectInstrumentNodeWithIONode(instrumentNode, ioNode: ioNode)
        
        self.instrumentAudioUnit = createAudioUnitFromGraphNode(instrumentNode)
    }
    
    private func addSamplerAudioUnitNodeToGraph() -> AUNode {
        var node = AUNode()
        
        var componentDescription = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_MusicDevice),
            componentSubType: OSType(kAudioUnitSubType_MIDISynth),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0,
            componentFlagsMask: 0)
        
        let status:OSStatus = AUGraphAddNode(self.processingGraph, &componentDescription, &node)
        assert(status == noErr, "Could not create kAudioUnitType_MusicDevice/kAudioUnitSubType_MIDISynth Node")
        
        return node
    }
    
    private func addIOAudioUnitNodeToGraph() -> AUNode {
        var node = AUNode()
        
        var ioUnitDescription = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_Output),
            componentSubType: OSType(kAudioUnitSubType_RemoteIO),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0,
            componentFlagsMask: 0)
        
        let status:OSStatus = AUGraphAddNode(self.processingGraph, &ioUnitDescription, &node)
        assert(status == noErr, "Could not create kAudioUnitType_Output/kAudioUnitSubType_RemoteIO Node")
        
        return node
    }
    
    private func createAudioUnitFromGraphNode(node:AUNode) -> AudioUnit {
        var audioUnit = AudioUnit()
        
        var status:OSStatus = AUGraphOpen(self.processingGraph)
        assert(status == noErr, "Could not open Audio Unit Graph")
        status = AUGraphNodeInfo(self.processingGraph, node, nil, &audioUnit)
        assert(status == noErr, "Could not get audio unit from graph node")
        
        return audioUnit
    }
    
    private func connectInstrumentNodeWithIONode(instrumentNode:AUNode, ioNode:AUNode) {
        var ioUnitOutputElement:AudioUnitElement = 0
        var instrumentOutputElement:AudioUnitElement = 0
        
        let status:OSStatus = AUGraphConnectNodeInput(
            self.processingGraph,
            instrumentNode,
            instrumentOutputElement,
            ioNode,
            ioUnitOutputElement)
        assert(status == noErr, "Could not connect sampler node with IO node")
    }
    
    private func initializeAudioUnitGraph() {
        var isInitialized:Boolean = 0
        var status:OSStatus = AUGraphIsInitialized(self.processingGraph, &isInitialized)
        assert(status == noErr, "Could find out if Audio Unit Graph is initialized")
        
        if isInitialized == 0 {
            status = AUGraphInitialize(self.processingGraph)
            assert(status == noErr, "Could not initialize Audio Unit Graph")
        }
    }
    
    private func startAudioUnitGraph() {
        var isRunning:Boolean = 0
        AUGraphIsRunning(self.processingGraph, &isRunning)
        if isRunning == 0 {
            var status:OSStatus = AUGraphStart(self.processingGraph)
            assert(status == noErr, "Could not start Audio Unit Graph")
        }
    }
}