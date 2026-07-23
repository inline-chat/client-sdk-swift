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

internal import LiveKitWebRTC

public enum AudioDeviceModuleType: Equatable, Sendable {
    /// Use AVAudioEngine-based AudioDeviceModule internally which will be used for all platforms.
    case audioEngine
    /// Use WebRTC's default AudioDeviceModule internally, which uses AudioUnit for iOS, HAL APIs for macOS.
    case platformDefault
}

/// The process-wide audio-device runtime selected for LiveKit's peer-connection factory.
public enum AudioDeviceRuntimeKind: Equatable, Sendable {
    /// LiveKit's `AVAudioEngine`-backed standard audio device module.
    case audioEngine
    /// WebRTC's platform-default standard audio device module.
    case platformDefault
    /// An application-provided ``CustomAudioDevice``.
    case custom
}

/// Capabilities exposed by the selected process-wide audio-device runtime.
///
/// Use this snapshot before calling APIs that operate on LiveKit's standard
/// audio-device wrapper. A custom device owns its physical I/O and device
/// selection, while WebRTC sender and receiver demand owns its start/stop
/// lifecycle.
public struct AudioDeviceRuntimeCapabilities: Equatable, Sendable {
    /// Whether APIs backed by LiveKit's standard audio-device wrapper are available.
    public let hasStandardAudioDeviceModule: Bool

    /// Whether LiveKit can enumerate and select physical input and output devices.
    public let supportsSDKDeviceSelection: Bool

    /// Whether Apple's platform voice-processing controls are available.
    public let supportsPlatformVoiceProcessing: Bool

    /// Whether LiveKit's capture-post and render-pre processing delegates are connected.
    public let supportsAudioProcessingDelegates: Bool
}

extension AudioDeviceModuleType {
    func toRTCType() -> LKRTCAudioDeviceModuleType {
        switch self {
        case .audioEngine: LKRTCAudioDeviceModuleType.audioEngine
        case .platformDefault: LKRTCAudioDeviceModuleType.platformDefault
        }
    }

    var runtimeKind: AudioDeviceRuntimeKind {
        switch self {
        case .audioEngine: .audioEngine
        case .platformDefault: .platformDefault
        }
    }
}

extension AudioDeviceRuntimeKind {
    var capabilities: AudioDeviceRuntimeCapabilities {
        #if os(macOS)
        let supportsSDKDeviceSelection = self != .custom
        #else
        let supportsSDKDeviceSelection = false
        #endif

        switch self {
        case .audioEngine:
            return AudioDeviceRuntimeCapabilities(
                hasStandardAudioDeviceModule: true,
                supportsSDKDeviceSelection: supportsSDKDeviceSelection,
                supportsPlatformVoiceProcessing: true,
                supportsAudioProcessingDelegates: true,
            )
        case .platformDefault:
            return AudioDeviceRuntimeCapabilities(
                hasStandardAudioDeviceModule: true,
                supportsSDKDeviceSelection: supportsSDKDeviceSelection,
                supportsPlatformVoiceProcessing: false,
                supportsAudioProcessingDelegates: true,
            )
        case .custom:
            return AudioDeviceRuntimeCapabilities(
                hasStandardAudioDeviceModule: false,
                supportsSDKDeviceSelection: false,
                supportsPlatformVoiceProcessing: false,
                supportsAudioProcessingDelegates: false,
            )
        }
    }
}

public extension AudioManager {
    /// The audio-device runtime that will be used, or is already in use, process-wide.
    static var audioDeviceRuntimeKind: AudioDeviceRuntimeKind {
        RTC.audioDeviceRuntimeKind
    }

    /// Capabilities of the selected process-wide audio-device runtime.
    static var audioDeviceRuntimeCapabilities: AudioDeviceRuntimeCapabilities {
        RTC.audioDeviceRuntimeCapabilities
    }

    /// Sets the desired `AudioDeviceModuleType` to be used which handles all audio input / output.
    ///
    /// This method must be called before the peer connection is initialized. Changing the module type after
    /// initialization is not supported and will result in an error.
    ///
    /// Note: When using .platformDefault, AVAudioSession will not be automatically managed.
    /// Ensure to set session category when accessing the mic:
    /// `try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoChat, options: [])`
    static func set(audioDeviceModuleType: AudioDeviceModuleType) throws {
        let isCompatible = RTC.pcFactoryState.mutate {
            $0.selectAudioDeviceModuleType(audioDeviceModuleType)
        }
        guard isCompatible else {
            throw LiveKitError(.invalidState, message: "Cannot set this property after the peer connection has been initialized")
        }
    }

    /// Installs a process-wide custom physical audio device.
    ///
    /// This method must be called before the peer-connection factory is
    /// initialized. Reasserting the same device instance is idempotent; changing
    /// the device after initialization throws an invalid-state error.
    ///
    /// LiveKit strongly retains the device for the peer-connection factory's
    /// lifetime. The device is responsible for physical recording and playout;
    /// WebRTC continues to own transport, buffering, and audio processing.
    static func set(customAudioDevice: any CustomAudioDevice) throws {
        let isCompatible = RTC.pcFactoryState.mutate {
            $0.selectCustomAudioDevice(customAudioDevice)
        }
        guard isCompatible else {
            throw LiveKitError(.invalidState, message: "Cannot set this property after the peer connection has been initialized")
        }
    }
}
