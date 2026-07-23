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

#if os(macOS)
internal import LiveKitWebRTC

public extension AudioManager {
    /// Stops and uninitializes the standard audio device module's playout side.
    ///
    /// This is a low-level macOS route-transition API. Use it only to bracket a
    /// hardware change that can alter the active output stream format, and call
    /// ``startLocalPlayout()`` afterward only if playout was active beforehand.
    func stopLocalPlayout() throws {
        let result = RTC.audioDeviceModule.stopPlayout()
        try checkAdmResult(code: result)
    }

    /// Initializes and starts the standard audio device module's playout side.
    ///
    /// - SeeAlso: ``stopLocalPlayout()``
    func startLocalPlayout() throws {
        try checkAdmResult(code: RTC.audioDeviceModule.initPlayout())
        try checkAdmResult(code: RTC.audioDeviceModule.startPlayout())
    }
}
#endif
