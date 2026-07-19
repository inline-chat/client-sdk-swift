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

@testable import LiveKit
import Testing

@Suite(.serialized)
struct AudioManagerDeviceObserverTests {
    @Test
    func deviceUpdatesAreMulticastAndIndependentlyCancelled() {
        let manager = AudioManager.shared
        let counts = StateSync([0, 0, 0])
        manager.onDeviceUpdate = { _ in
            counts.mutate { $0[0] += 1 }
        }
        defer { manager.onDeviceUpdate = nil }

        let first = manager.observeDeviceUpdates { _ in
            counts.mutate { $0[1] += 1 }
        }
        let second = manager.observeDeviceUpdates { _ in
            counts.mutate { $0[2] += 1 }
        }

        manager.notifyDevicesDidUpdate()
        #expect(counts.copy() == [1, 1, 1])

        first.cancel()
        manager.notifyDevicesDidUpdate()
        #expect(counts.copy() == [2, 1, 2])

        withExtendedLifetime(second) {}
    }
}
