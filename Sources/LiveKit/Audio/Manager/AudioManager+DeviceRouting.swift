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

internal import LiveKitWebRTC

public extension AudioManager {
    /// Selects the output device and throws if WebRTC rejects the native
    /// transaction. Callers that need a verified physical route should still
    /// wait for Core Audio readback after this immediate acknowledgement.
    func set(outputDevice: AudioDevice) throws {
        guard RTC.audioDeviceModule.trySetOutputDevice(outputDevice._ioDevice) else {
            throw LiveKitError(.audioEngine, message: "WebRTC rejected the output-device selection")
        }
    }

    /// Selects the input device and throws if WebRTC rejects the native
    /// transaction. A successful return means the ADM accepted the change;
    /// physical route readback remains the commit proof.
    func set(inputDevice: AudioDevice) throws {
        guard RTC.audioDeviceModule.trySetInputDevice(inputDevice._ioDevice) else {
            throw LiveKitError(.audioEngine, message: "WebRTC rejected the input-device selection")
        }
    }

    /// Safe current output-device readback for route verification.
    ///
    /// WebRTC's Objective-C getter can transiently return `nil` during device
    /// churn even though its imported Swift signature is nonoptional. KVC
    /// preserves the underlying nullability and avoids constructing an
    /// `AudioDevice` around a missing native object.
    var currentOutputDevice: AudioDevice? {
        #if os(macOS)
        let module = RTC.audioDeviceModule as NSObject
        guard let device = module.value(forKey: "outputDevice") as? LKRTCIODevice
        else { return nil }
        return AudioDevice(ioDevice: device)
        #else
        return nil
        #endif
    }

    /// Safe current input-device readback for route verification. See
    /// ``currentOutputDevice`` for the Objective-C nullability rationale.
    var currentInputDevice: AudioDevice? {
        #if os(macOS)
        let module = RTC.audioDeviceModule as NSObject
        guard let device = module.value(forKey: "inputDevice") as? LKRTCIODevice
        else { return nil }
        return AudioDevice(ioDevice: device)
        #else
        return nil
        #endif
    }

    /// Whether the standard audio device module is actively rendering audio.
    ///
    /// Unlike ``isEngineRunning``, this is meaningful for every ADM.
    var isPlaying: Bool {
        RTC.audioDeviceModule.playing
    }

    /// Whether the standard audio device module is actively capturing audio.
    ///
    /// Unlike ``isEngineRunning``, this is meaningful for every ADM.
    var isRecording: Bool {
        RTC.audioDeviceModule.recording
    }

    /// Physical AudioEngine callback and measured-delay readback for the
    /// current graph generation. A zero/never-seen snapshot is returned when
    /// the process uses another AudioDeviceModule implementation.
    var audioEngineRuntimeDiagnostics: AudioEngineRuntimeDiagnostics {
        AudioEngineRuntimeDiagnostics(
            native: RTC.audioDeviceModule.audioEngineRuntimeDiagnostics,
        )
    }
}
