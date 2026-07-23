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

/// Realtime physical-I/O callback truth for the current AudioEngine graph.
///
/// Callback counts reset on every directional graph rebuild. `isPlaying` and
/// `isRecording` report ADM intent; these values prove that the corresponding
/// AVAudioEngine hardware callback has actually advanced recently.
public struct AudioEngineRuntimeDiagnostics: Equatable, Sendable {
    public let playoutCallbackSeen: Bool
    public let recordingCallbackSeen: Bool
    public let playoutCallbackCount: UInt64
    public let recordingCallbackCount: UInt64
    public let playoutCallbackAgeMilliseconds: UInt64
    public let recordingCallbackAgeMilliseconds: UInt64
    public let measuredPlayoutDelayMilliseconds: UInt16
    public let measuredRecordingDelayMilliseconds: UInt16

    init(native: LKRTCAudioEngineRuntimeDiagnostics) {
        playoutCallbackSeen = native.playoutCallbackSeen.boolValue
        recordingCallbackSeen = native.recordingCallbackSeen.boolValue
        playoutCallbackCount = native.playoutCallbackCount
        recordingCallbackCount = native.recordingCallbackCount
        playoutCallbackAgeMilliseconds = native.playoutCallbackAgeMilliseconds
        recordingCallbackAgeMilliseconds = native.recordingCallbackAgeMilliseconds
        measuredPlayoutDelayMilliseconds = native.measuredPlayoutDelayMilliseconds
        measuredRecordingDelayMilliseconds = native.measuredRecordingDelayMilliseconds
    }
}
