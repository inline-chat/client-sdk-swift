# Inline LiveKit Swift fork

This repository is Inline's source fork of LiveKit's Swift client SDK:

- Upstream: https://github.com/livekit/client-sdk-swift
- Inline: https://github.com/inline-chat/client-sdk-swift

The current branch merges upstream LiveKit `2.15.2` at
`77b5aad07909e23adf97d39f205ef7e18e2ceff5`. It includes LiveKit's merged
software audio-processing API from PR #1048 and keeps Inline's existing local
muted-track fixes.

## Native typing-noise suppression

The upstream `AudioCaptureOptions.typingNoiseDetection` constraint does not
activate typing suppression in WebRTC M144. Inline maps that option to
`RTCAudioProcessingConfig.isTransientSuppressionEnabled` before microphone
capture starts.

On macOS, Inline's WebRTC fork supplies live hardware-key state to the audio
processing module for every captured microphone frame. This is wired into both
the ordinary AVAudioEngine input sink and the manual-render loop used by
Inline's AUHAL-backed Grid audio path. Apple mobile platforms force transient
suppression off because they do not supply that signal. Transient suppression
is independent of Apple Voice Processing I/O and does not enable VPIO.

WebRTC's audio-processing module is shared by local tracks. If multiple local
audio tracks use different capture options, the most recently started track's
typing-noise setting wins.

### Operational characteristics

- The suppressor adds about 11.3 ms of capture delay at 48 kHz and 6 ms at
  8/16/32 kHz whenever it is configured, including while no key is pressed.
- Two consecutive 10 ms key-held frames enable suppression. Detection and
  suppression remain active for about four seconds after typing stops.
- The macOS audio device scans virtual key codes `0...0x5D` once per capture
  frame and stops at the first pressed key.
- Only an `any key is held` boolean reaches WebRTC. Key codes and typed content
  are neither retained nor passed into audio processing.

## Owned dependency chain

Inline maintains all source and binary inputs needed for this behavior:

1. https://github.com/inline-chat/webrtc
2. https://github.com/inline-chat/webrtc-build
3. https://github.com/inline-chat/webrtc-xcframework
4. https://github.com/inline-chat/client-sdk-swift

Both `Package.swift` and `Package@swift-6.2.swift` must pin the same immutable
Inline WebRTC XCFramework release.

## Upgrade procedure

1. Fetch and merge the intended upstream LiveKit SDK release.
2. Confirm that LiveKit's software audio-processing API remains present.
3. Build the matching WebRTC source revision through Inline's owned source,
   build, and XCFramework repositories.
4. Update both package manifests to the exact new Inline XCFramework tag.
5. Resolve dependencies and run the LiveKit build, formatting, lint, and
   `AudioProcessingOptionsTests`.
6. Update Inline's app package to the resulting exact client commit.
