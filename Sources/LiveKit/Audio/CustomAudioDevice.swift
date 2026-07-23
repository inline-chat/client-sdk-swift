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

import AudioToolbox
import Foundation

internal import LKRTCAudioDeviceCompat

/// Callback-scoped timing and sizing for custom-device audio IO.
///
/// The pointers are valid only for the duration of the audio callback. Do not
/// retain this value or any of its pointers.
public struct CustomAudioDeviceIOContext {
    /// Mutable Core Audio action flags for the current callback.
    public let actionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>
    /// Physical Core Audio timestamp for the current callback.
    public let timestamp: UnsafePointer<AudioTimeStamp>
    /// Audio Unit bus associated with the callback.
    public let inputBusNumber: Int
    /// Number of audio frames requested or supplied by the callback.
    public let frameCount: UInt32

    /// Creates callback-scoped IO context.
    public init(
        actionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        timestamp: UnsafePointer<AudioTimeStamp>,
        inputBusNumber: Int,
        frameCount: UInt32,
    ) {
        self.actionFlags = actionFlags
        self.timestamp = timestamp
        self.inputBusNumber = inputBusNumber
        self.frameCount = frameCount
    }
}

/// Callback-scoped recorded data passed from a custom device to WebRTC.
public struct CustomAudioDeviceRecordedData {
    /// Timing and sizing of the recorded packet.
    public let context: CustomAudioDeviceIOContext
    /// Pre-filled 16-bit interleaved recorded PCM.
    public let inputData: UnsafePointer<AudioBufferList>
    /// Optional custom context forwarded to WebRTC.
    public let renderContext: UnsafeMutableRawPointer?

    /// Creates callback-scoped recorded data.
    public init(
        context: CustomAudioDeviceIOContext,
        inputData: UnsafePointer<AudioBufferList>,
        renderContext: UnsafeMutableRawPointer? = nil,
    ) {
        self.context = context
        self.inputData = inputData
        self.renderContext = renderContext
    }
}

/// The WebRTC-facing callbacks supplied to a ``CustomAudioDevice``.
///
/// Calls made from a real-time audio callback must use ``getPlayoutData`` or
/// ``deliverRecordedData`` directly. Notification and dispatch methods belong
/// to the device control plane.
public protocol CustomAudioDeviceDelegate: AnyObject, Sendable {
    /// Preferred recording sample rate reported by WebRTC's audio device module.
    var preferredInputSampleRate: Double { get }

    /// Preferred recording IO duration reported by WebRTC's audio device module.
    var preferredInputIOBufferDuration: TimeInterval { get }

    /// Preferred playout sample rate reported by WebRTC's audio device module.
    var preferredOutputSampleRate: Double { get }

    /// Preferred playout IO duration reported by WebRTC's audio device module.
    var preferredOutputIOBufferDuration: TimeInterval { get }

    /// Pulls decoded 16-bit interleaved PCM directly into a playout buffer.
    func getPlayoutData(
        _ context: CustomAudioDeviceIOContext,
        outputData: UnsafeMutablePointer<AudioBufferList>,
    ) -> OSStatus

    /// Delivers recorded 16-bit interleaved PCM to WebRTC.
    ///
    /// The supplied buffer must already contain the recorded data. This focused
    /// API deliberately omits WebRTC's optional nested render block so custom
    /// devices can keep their real-time path allocation-free.
    func deliverRecordedData(_ data: CustomAudioDeviceRecordedData) -> OSStatus

    /// Notifies WebRTC that recording parameters or latency changed.
    func notifyAudioInputParametersChange()

    /// Notifies WebRTC that playout parameters or latency changed.
    func notifyAudioOutputParametersChange()

    /// Notifies WebRTC that future recording callbacks may use another thread.
    func notifyAudioInputInterrupted()

    /// Notifies WebRTC that future playout callbacks may use another thread.
    func notifyAudioOutputInterrupted()

    /// Executes work asynchronously on the native audio-device-module thread.
    func dispatchAsync(_ block: @escaping @Sendable () -> Void)

    /// Executes work synchronously on the native audio-device-module thread.
    func dispatchSync(_ block: @escaping @Sendable () -> Void)
}

/// A custom physical audio device used by WebRTC for recording and playout.
///
/// Configure one process-wide instance with
/// ``AudioManager/set(customAudioDevice:)`` before creating a Room or accessing
/// another API that initializes the peer-connection factory.
public protocol CustomAudioDevice: AnyObject, Sendable {
    /// Active WebRTC-facing recording sample rate.
    var deviceInputSampleRate: Double { get }
    /// Active recording IO buffer duration.
    var inputIOBufferDuration: TimeInterval { get }
    /// Active number of interleaved recording channels.
    var inputNumberOfChannels: Int { get }
    /// Estimated latency from physical capture to WebRTC delivery.
    var inputLatency: TimeInterval { get }

    /// Active WebRTC-facing playout sample rate.
    var deviceOutputSampleRate: Double { get }
    /// Active playout IO buffer duration.
    var outputIOBufferDuration: TimeInterval { get }
    /// Active number of interleaved playout channels.
    var outputNumberOfChannels: Int { get }
    /// Estimated latency from WebRTC playout pull to physical output.
    var outputLatency: TimeInterval { get }

    /// Whether the device currently owns a WebRTC delegate.
    var isInitialized: Bool { get }
    /// Initializes the device with WebRTC's callback delegate.
    func initialize(delegate: any CustomAudioDeviceDelegate) -> Bool
    /// Stops both directions and releases WebRTC's callback delegate.
    func terminate() -> Bool

    /// Whether playout resources are ready to start.
    var isPlayoutInitialized: Bool { get }
    /// Prepares playout resources without claiming active playout.
    func initializePlayout() -> Bool
    /// Whether WebRTC currently demands playout and the device is playing.
    var isPlaying: Bool { get }
    /// Starts physical playout.
    func startPlayout() -> Bool
    /// Stops physical playout and releases its hardware ownership.
    func stopPlayout() -> Bool

    /// Whether recording resources are ready to start.
    var isRecordingInitialized: Bool { get }
    /// Prepares recording resources without claiming active recording.
    func initializeRecording() -> Bool
    /// Whether WebRTC currently demands recording and the device is recording.
    var isRecording: Bool { get }
    /// Starts physical recording.
    func startRecording() -> Bool
    /// Stops physical recording and releases its hardware ownership.
    func stopRecording() -> Bool
}

final class RTCCustomAudioDeviceAdapter: NSObject, LKRTCAudioDevice, @unchecked Sendable {
    private let device: any CustomAudioDevice
    private var delegateAdapter: RTCCustomAudioDeviceDelegateAdapter?

    init(device: any CustomAudioDevice) {
        self.device = device
        super.init()
    }

    var deviceInputSampleRate: Double { device.deviceInputSampleRate }
    var inputIOBufferDuration: TimeInterval { device.inputIOBufferDuration }
    var inputNumberOfChannels: Int { device.inputNumberOfChannels }
    var inputLatency: TimeInterval { device.inputLatency }

    var deviceOutputSampleRate: Double { device.deviceOutputSampleRate }
    var outputIOBufferDuration: TimeInterval { device.outputIOBufferDuration }
    var outputNumberOfChannels: Int { device.outputNumberOfChannels }
    var outputLatency: TimeInterval { device.outputLatency }

    var isInitialized: Bool { device.isInitialized }

    func initialize(with delegate: any LKRTCAudioDeviceDelegate) -> Bool {
        guard delegateAdapter == nil else { return false }
        let adapter = RTCCustomAudioDeviceDelegateAdapter(delegate: delegate)
        guard device.initialize(delegate: adapter) else { return false }
        delegateAdapter = adapter
        return true
    }

    func terminateDevice() -> Bool {
        guard device.terminate() else { return false }
        delegateAdapter = nil
        return true
    }

    var isPlayoutInitialized: Bool { device.isPlayoutInitialized }
    func initializePlayout() -> Bool { device.initializePlayout() }
    var isPlaying: Bool { device.isPlaying }
    func startPlayout() -> Bool { device.startPlayout() }
    func stopPlayout() -> Bool { device.stopPlayout() }

    var isRecordingInitialized: Bool { device.isRecordingInitialized }
    func initializeRecording() -> Bool { device.initializeRecording() }
    var isRecording: Bool { device.isRecording }
    func startRecording() -> Bool { device.startRecording() }
    func stopRecording() -> Bool { device.stopRecording() }
}

private final class RTCCustomAudioDeviceDelegateAdapter: CustomAudioDeviceDelegate, @unchecked Sendable {
    private let delegate: any LKRTCAudioDeviceDelegate
    private let getPlayoutDataBlock: LKRTCAudioDeviceGetPlayoutDataBlock
    private let deliverRecordedDataBlock: LKRTCAudioDeviceDeliverRecordedDataBlock

    init(delegate: any LKRTCAudioDeviceDelegate) {
        self.delegate = delegate
        getPlayoutDataBlock = delegate.getPlayoutData
        deliverRecordedDataBlock = delegate.deliverRecordedData
    }

    var preferredInputSampleRate: Double { delegate.preferredInputSampleRate }
    var preferredInputIOBufferDuration: TimeInterval { delegate.preferredInputIOBufferDuration }
    var preferredOutputSampleRate: Double { delegate.preferredOutputSampleRate }
    var preferredOutputIOBufferDuration: TimeInterval { delegate.preferredOutputIOBufferDuration }

    func getPlayoutData(
        _ context: CustomAudioDeviceIOContext,
        outputData: UnsafeMutablePointer<AudioBufferList>,
    ) -> OSStatus {
        getPlayoutDataBlock(
            context.actionFlags,
            context.timestamp,
            context.inputBusNumber,
            context.frameCount,
            outputData,
        )
    }

    func deliverRecordedData(_ data: CustomAudioDeviceRecordedData) -> OSStatus {
        deliverRecordedDataBlock(
            data.context.actionFlags,
            data.context.timestamp,
            data.context.inputBusNumber,
            data.context.frameCount,
            data.inputData,
            data.renderContext,
            nil,
        )
    }

    func notifyAudioInputParametersChange() {
        delegate.notifyAudioInputParametersChange()
    }

    func notifyAudioOutputParametersChange() {
        delegate.notifyAudioOutputParametersChange()
    }

    func notifyAudioInputInterrupted() {
        delegate.notifyAudioInputInterrupted()
    }

    func notifyAudioOutputInterrupted() {
        delegate.notifyAudioOutputInterrupted()
    }

    func dispatchAsync(_ block: @escaping @Sendable () -> Void) {
        delegate.dispatchAsync(block)
    }

    func dispatchSync(_ block: @escaping @Sendable () -> Void) {
        delegate.dispatchSync(block)
    }
}
