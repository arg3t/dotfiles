# SonyConnect MacOS

A macOS menu-bar app that controls Sony WH-1000XM4 headphones over Bluetooth — toggle the touch panel, switch between Noise Cancelling / Ambient Sound / Off, turn Speak-to-Chat on or off, and power the headphones off on demand or automatically after an idle window, all from the menu bar.

<img width="265" height="305" alt="image" src="https://github.com/user-attachments/assets/16ec2f0d-85c1-4ef6-abfa-af35522f731b" />



## Features

- Auto-connects to a paired Sony WH-1000XM4 as soon as the app starts
- Menu-bar UI:
  - **Touch Sensor** (enable / disable the right-earcup swipe panel)
  - **Noise Cancelling** — On / Ambient Sound / Off
  - **Speak-to-Chat** — On / Off
  - **Equalizer** — preset submenu (names pulled live from the device's capability table) plus a 6-band graphic EQ (5 frequency bands + Clear Bass) with sliders
  - **Volume** — full-width slider over the headphones' output level
  - **Power Off Headphones** on demand, or automatically after 30 min with no audio playing
  - Currently playing media is paused before sending the power-off command, so audio doesn't briefly blast through the internal speakers when A2DP drops
  - Connection status, reconnect, log access
- Picks up state changes coming from the headphones themselves (e.g. pressing the physical NC button) via Sony's NOTIFY packets
- Auto-discovers the firmware-specific "general settings" slot that holds the touch panel control — works across firmware revisions that hard-coded reverse-engineering does not
- Idle detection uses CoreAudio's `kAudioDevicePropertyDeviceIsRunningSomewhere` on the headphones' audio device — accurate, no polling of media keys or fragile private APIs

## Supported headphones

Built and tested on **Sony WH-1000XM4**. The name-matching list in [`BluetoothClient.swift`](Sources/SonyConnect/BluetoothClient.swift) also accepts WH-1000XM3 and WH-1000XM5. Other Sony MDR-family headphones may work — feature mapping (which opcode controls what) is partly device-specific.

## Requirements

- macOS 12 Monterey or newer
- Xcode Command Line Tools (`xcode-select --install`) — for `swift build`
- The headphones already paired in System Settings → Bluetooth

## Build & Run

```sh
make run
```

That:

1. Builds a release binary via `swift build -c release`
2. Wraps it in `SonyConnect.app` with `Info.plist` (the bundle and its `NSBluetoothAlwaysUsageDescription` are needed for the Bluetooth permission prompt)
3. Ad-hoc codesigns it
4. Kills any previously running instance and opens the new build

On first launch macOS will ask for Bluetooth permission — approve it once.

`make clean` removes build artefacts.

## Usage

After launch a headphones icon appears in the menu bar. Click it (left or right) to open the menu:

- **Touch Sensor: ON / OFF** — click to toggle
- **Noise Cancelling ▸** — submenu with three radio-style options (NC, Ambient, Off)
- **Speak-to-Chat: ON / OFF** — click to toggle
- **Power Off after 30 min idle** — checkbox; when on, the app sends the power-off command if no audio plays on the headphones' audio device for 30 minutes. Setting is persisted in `UserDefaults` and survives relaunch.
- **Power Off Headphones** — sends the power-off command immediately. The headphones shut down and Bluetooth disconnects.
- **Reconnect** — re-runs the discovery sequence (useful after the headphones suspend or get re-paired)
- **Open Log…** — reveals `~/Library/Logs/SonyConnect.log` in Finder

## How it works

Sony headphones expose a proprietary RFCOMM service (advertised as "Serial HPC", UUID `96CC203E-5068-46AD-B32D-E316F5E069BA`) on top of classic Bluetooth. Frames look like this:

```
0x3E  data_type  seq  len(BE32)  payload  checksum  0x3C
```

`0x3C` / `0x3D` / `0x3E` bytes inside the body are escape-encoded: prefixed with `0x3D` and XOR-ed with `0xEF`. The checksum is the sum of all body bytes mod 256.

After RFCOMM opens, the app:

1. Sends `INIT_REQUEST` (`00 00`) and waits for any response — different firmware revisions answer with anything from the canonical `01 00 40 10` to a stream of unsolicited state pushes.
2. Sends `GENERAL_SETTING_GET_CAPABILITY` (`D0 D1 00`, `D0 D2 00`, `D0 D3 00`) for each "general settings" slot, parses the responses, and looks for an ASCII `TOUCH_PANEL_SETTING` name — that's the slot used for the touch panel toggle on this particular device.
3. Queries NCASM (`66 02`) and Smart Talking Mode (`F6 05`) for initial state.
4. Acknowledges every non-ACK packet with the opposite sequence number (Sony's "expected next seq" convention).
5. Listens for NOTIFY opcodes (`D9`, `69`, `F9`) to keep the UI in sync when the user changes settings via the physical buttons or another connected device.

SET commands:

| Feature             | Payload                                                                   |
| ------------------- | ------------------------------------------------------------------------- |
| Touch panel         | `D8 <slot> <type> <value>` (slot/type from capability discovery)          |
| Noise Cancelling    | `68 02 11 <ncType> 02 <asmType> 00 00` (DUAL NC)                          |
| Ambient Sound       | `68 02 11 <ncType> 00 <asmType> 00 14` (asmLevel=20)                      |
| NC Off              | `68 02 00 <ncType> 00 <asmType> 00 00`                                    |
| Speak-to-Chat       | `F8 05 01 <0\|1>`                                                          |
| EQ preset           | `58 01 <presetId> 00` (`EQEBB_SET_PARAM` + `PRESET_EQ`)                   |
| EQ custom bands      | `58 01 A0 <nBands> <b0…bN>` (preset `CUSTOM`, band values 0…20, 10 = flat)|
| Power Off           | `22 00 01` (`COMMON_SET_POWER_OFF` + `USER_POWER_OFF`)                    |

`ncType` and `asmType` come from the device's GET response — different firmware uses different setting-type bytes (`LEVEL_ADJUSTMENT = 0x01` vs `DUAL_SINGLE_OFF = 0x02`), so they're read live rather than hardcoded.

## Project layout

```
Sources/SonyConnect/
  main.swift               — NSApplication bootstrap (.accessory mode, no Dock icon)
  AppDelegate.swift        — Owns the menu bar controller
  MenuBarController.swift  — NSStatusItem, menu, click routing
  HeadphonesController.swift — Protocol state machine
  BluetoothClient.swift    — IOBluetooth RFCOMM wrapper, SDP query, ACL reachability
  SonyPacket.swift         — Sony frame encoding / decoding (markers, escape, checksum)
  ConnectionPolicy.swift   — lazy connect + idle disconnect (battery saving)
  AudioActivityMonitor.swift — CoreAudio "is the device playing" probe
  AutoPowerOff.swift       — idle-based power-off timer
  MediaController.swift    — Pauses Now-Playing media via MediaRemote.framework
  VolumeController.swift   — CoreAudio output-volume get/set
  EqualizerView.swift      — graphic-EQ band sliders (custom menu-item view)
  SupportedDevices.swift   — device name hints
  FileLogger.swift         — Plain-text log to ~/Library/Logs/SonyConnect.log
Resources/Info.plist       — LSUIElement + NSBluetoothAlwaysUsageDescription
Makefile                   — build, app, run, clean
Package.swift              — Swift Package Manager manifest
```

## Limitations

- Ad-hoc codesigned only — not notarized, not signed for distribution. Re-sign before sharing the `.app` with anyone else.
- Connects to the first matching paired device. Multi-device routing not implemented.
- Only the features above are wired up. EQ, multipoint, firmware auto-power-off duration, voice guidance, wear-detection, etc. are protocol-supported but unimplemented.
- The Sony protocol is reverse-engineered — a firmware update can change opcodes. If the touch toggle stops doing anything physical, check `~/Library/Logs/SonyConnect.log` for the device's capability response and adapt.

## Credits

Protocol details built on prior reverse-engineering work:

- [Gadgetbridge](https://codeberg.org/Freeyourgadget/Gadgetbridge) — Android open-source companion app, source for the V1 opcode tables and `GsInquiredType` / capability negotiation logic
- [SonyHeadphonesClient](https://github.com/Plutoberth/SonyHeadphonesClient) — C++ client, source for the framing and NCASM payload structure

The auto-discovery of the touch panel general-settings slot via `GENERAL_SETTING_GET_CAPABILITY` was derived from the Sony Headphones Connect Android app via `jadx` decompilation when the hard-coded `D8 D2 01 xx` from the open-source clients turned out to be the wrong slot on the WH-1000XM4 firmware tested.
