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

/// Opaque handle for an audio-device update observation.
///
/// Retain the handle for as long as updates are needed. Call ``cancel()`` to stop
/// observing early; otherwise observation ends automatically when the handle is
/// released.
public final class AudioDeviceUpdateObserverHandle: @unchecked Sendable {
    private struct State {
        var cancelImpl: (@Sendable () -> Void)?
    }

    private let _state: StateSync<State>

    init(cancelImpl: @escaping @Sendable () -> Void) {
        _state = StateSync(State(cancelImpl: cancelImpl))
    }

    deinit {
        cancel()
    }

    /// Stops this observer from receiving future device updates.
    ///
    /// Calling this method more than once is a no-op.
    public func cancel() {
        let cancelImpl = _state.mutate { state -> (@Sendable () -> Void)? in
            let cancelImpl = state.cancelImpl
            state.cancelImpl = nil
            return cancelImpl
        }
        cancelImpl?()
    }
}
