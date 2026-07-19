# Inline LiveKit Swift fork

This repository is Inline's source fork of LiveKit's Swift client SDK:

- Upstream: https://github.com/livekit/client-sdk-swift
- Inline: https://github.com/inline-chat/client-sdk-swift

The current branch merges upstream LiveKit `2.15.2` at
`77b5aad07909e23adf97d39f205ef7e18e2ceff5`. It includes LiveKit's merged
software audio-processing API from PR #1048 and keeps Inline's existing local
muted-track fixes.

## Audio device module diagnostics

Inline exposes the standard audio device module's `isRecording` and
`isPlaying` facts through `AudioManager`. LiveKit's existing
`isEngineRunning` API is specific to its custom AudioEngine device and always
reads false when WebRTC's platform-default audio device is selected.

`AudioManager.observeDeviceUpdates(_:)` provides independent, token-owned
device-update observations so one consumer cannot replace another consumer's
callback. The legacy `onDeviceUpdate` property remains source-compatible.

M144's current-device getters are imported as nonoptional even though their
Objective-C implementation can return `nil` during a hot-plug enumeration
race. Inline's Grid integration deliberately avoids polling those getters and
validates route policy using its stable Core Audio catalog plus ADM
recording/playing state.

Audio-device-module selection is atomic with peer-connection-factory
initialization. Reasserting the already-active module type is idempotent, while
attempting to change types after factory initialization still fails. This
prevents a Room startup race from creating one ADM while the SDK records
another type.

The fork does not modify WebRTC audio processing. In particular, the abandoned
transient-suppressor experiment is not part of this dependency line.

## Owned dependency chain

Inline maintains its LiveKit Swift integration while consuming LiveKit's
official M144 WebRTC binary:

1. https://github.com/inline-chat/client-sdk-swift
2. https://github.com/livekit/webrtc-xcframework (`144.7559.11`)

Both `Package.swift` and `Package@swift-6.2.swift` must pin the same immutable
official WebRTC XCFramework release.

## Upgrade procedure

1. Fetch and merge the intended upstream LiveKit SDK release.
2. Confirm that LiveKit's software audio-processing API remains present.
3. Verify the intended official LiveKit WebRTC XCFramework release against its
   matching source revision.
4. Update both package manifests to the exact official XCFramework tag.
5. Resolve dependencies and run the LiveKit build, formatting, lint, and
   `AudioProcessingOptionsTests`.
6. Update Inline's app package to the resulting exact client commit.
