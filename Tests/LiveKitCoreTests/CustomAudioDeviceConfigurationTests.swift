/*
 * Copyright 2026 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
@testable import LiveKit
import Testing

@Suite("Custom audio device configuration")
struct CustomAudioDeviceConfigurationTests {
    @Test("custom device selection is idempotent by identity")
    func customDeviceIdentity() {
        let device = StubCustomAudioDevice()
        var state = RTC.PeerConnectionFactoryState()

        let selectedBeforeInitialization = state.selectCustomAudioDevice(device)
        #expect(selectedBeforeInitialization)
        state.isInitialized = true
        let reselectedSameDevice = state.selectCustomAudioDevice(device)
        let selectedDifferentDevice = state.selectCustomAudioDevice(StubCustomAudioDevice())
        let selectedStandardDevice = state.selectAudioDeviceModuleType(.audioEngine)
        #expect(reselectedSameDevice)
        #expect(!selectedDifferentDevice)
        #expect(!selectedStandardDevice)
        #expect(state.audioDeviceRuntimeKind == .custom)
        #expect(!state.shouldStartRecordingBeforeSenderAttachment)
    }

    @Test("standard selection clears a pre-initialization custom device")
    func standardSelectionClearsCustomDevice() {
        var state = RTC.PeerConnectionFactoryState()
        let selectedCustomDevice = state.selectCustomAudioDevice(StubCustomAudioDevice())
        let selectedStandardDevice = state.selectAudioDeviceModuleType(.platformDefault)
        #expect(selectedCustomDevice)
        #expect(selectedStandardDevice)
        #expect(state.customAudioDevice == nil)
        #expect(state.admType == .platformDefault)
        #expect(state.audioDeviceRuntimeKind == .platformDefault)
        #expect(state.shouldStartRecordingBeforeSenderAttachment)
    }

    @Test("runtime capabilities distinguish standard and custom ownership")
    func runtimeCapabilities() {
        let audioEngine = AudioDeviceRuntimeKind.audioEngine.capabilities
        #expect(audioEngine.hasStandardAudioDeviceModule)
        #if os(macOS)
        #expect(audioEngine.supportsSDKDeviceSelection)
        #else
        #expect(!audioEngine.supportsSDKDeviceSelection)
        #endif
        #expect(audioEngine.supportsPlatformVoiceProcessing)
        #expect(audioEngine.supportsAudioProcessingDelegates)

        let platformDefault = AudioDeviceRuntimeKind.platformDefault.capabilities
        #expect(platformDefault.hasStandardAudioDeviceModule)
        #if os(macOS)
        #expect(platformDefault.supportsSDKDeviceSelection)
        #else
        #expect(!platformDefault.supportsSDKDeviceSelection)
        #endif
        #expect(!platformDefault.supportsPlatformVoiceProcessing)
        #expect(platformDefault.supportsAudioProcessingDelegates)

        let custom = AudioDeviceRuntimeKind.custom.capabilities
        #expect(!custom.hasStandardAudioDeviceModule)
        #expect(!custom.supportsSDKDeviceSelection)
        #expect(!custom.supportsPlatformVoiceProcessing)
        #expect(!custom.supportsAudioProcessingDelegates)
    }
}

private final class StubCustomAudioDevice: CustomAudioDevice, @unchecked Sendable {
    var deviceInputSampleRate: Double { 48000 }
    var inputIOBufferDuration: TimeInterval { 0.01 }
    var inputNumberOfChannels: Int { 1 }
    var inputLatency: TimeInterval { 0.01 }
    var deviceOutputSampleRate: Double { 48000 }
    var outputIOBufferDuration: TimeInterval { 0.01 }
    var outputNumberOfChannels: Int { 2 }
    var outputLatency: TimeInterval { 0.01 }
    var isInitialized: Bool { false }
    func initialize(delegate _: any CustomAudioDeviceDelegate) -> Bool { true }
    func terminate() -> Bool { true }
    var isPlayoutInitialized: Bool { false }
    func initializePlayout() -> Bool { true }
    var isPlaying: Bool { false }
    func startPlayout() -> Bool { true }
    func stopPlayout() -> Bool { true }
    var isRecordingInitialized: Bool { false }
    func initializeRecording() -> Bool { true }
    var isRecording: Bool { false }
    func startRecording() -> Bool { true }
    func stopRecording() -> Bool { true }
}
