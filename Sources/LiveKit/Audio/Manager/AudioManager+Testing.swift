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

// Only internal testing.
extension AudioManager {
    var engineState: LKRTCAudioEngineState {
        get { RTC.audioDeviceModule?.engineState ?? LKRTCAudioEngineState() }
        set { RTC.audioDeviceModule?.engineState = newValue }
    }

    var isPlayoutInitialized: Bool {
        RTC.audioDeviceModule?.isPlayoutInitialized ?? false
    }

    var isPlaying: Bool {
        RTC.audioDeviceModule?.isPlaying ?? false
    }

    var isRecordingInitialized: Bool {
        RTC.audioDeviceModule?.isRecordingInitialized ?? false
    }

    var isRecording: Bool {
        RTC.audioDeviceModule?.isRecording ?? false
    }

    @discardableResult
    func initPlayout() -> Int {
        RTC.audioDeviceModule?.initPlayout() ?? -1
    }

    @discardableResult
    func startPlayout() -> Int {
        RTC.audioDeviceModule?.startPlayout() ?? -1
    }

    @discardableResult
    func stopPlayout() -> Int {
        RTC.audioDeviceModule?.stopPlayout() ?? -1
    }

    @discardableResult
    func initRecording() -> Int {
        RTC.audioDeviceModule?.initRecording() ?? -1
    }

    @discardableResult
    func startRecording() -> Int {
        RTC.audioDeviceModule?.startRecording() ?? -1
    }

    @discardableResult
    func stopRecording() -> Int {
        RTC.audioDeviceModule?.stopRecording() ?? -1
    }
}
