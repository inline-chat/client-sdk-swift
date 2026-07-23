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

public extension AudioManager {
    var onDeviceUpdate: OnDevicesDidUpdate? {
        get { _state.onDevicesDidUpdate }
        set { _state.mutate { $0.onDevicesDidUpdate = newValue } }
    }

    /// Adds an independent audio-device update observer.
    ///
    /// Unlike ``onDeviceUpdate``, observations registered here do not replace
    /// one another. The callback runs on WebRTC's worker thread and must return
    /// promptly.
    ///
    /// - Parameter observer: Callback invoked when WebRTC reports an audio-device update.
    /// - Returns: A handle that owns the observation.
    func observeDeviceUpdates(
        _ observer: @escaping OnDevicesDidUpdate,
    ) -> AudioDeviceUpdateObserverHandle {
        let id = UUID()
        _state.mutate { $0.deviceUpdateObservers[id] = observer }
        let state = _state
        return AudioDeviceUpdateObserverHandle {
            state.mutate { $0.deviceUpdateObservers[id] = nil }
        }
    }
}

extension AudioManager {
    func notifyDevicesDidUpdate() {
        let observers = _state.read { state -> [OnDevicesDidUpdate] in
            var observers = Array(state.deviceUpdateObservers.values)
            if let legacyObserver = state.onDevicesDidUpdate {
                observers.append(legacyObserver)
            }
            return observers
        }
        observers.forEach { $0(self) }
    }
}
