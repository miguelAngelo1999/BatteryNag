<p align="center">
  <img src="icon-512.png" width="200" alt="BatteryNag Icon">
</p>

# BatteryNag

A lightweight macOS menubar app that aggressively warns you when your battery is low and force-sleeps the Mac at a critical threshold.

## Features

- Lives in the menubar with battery icon and percentage
- Configurable warning threshold (default: 40%)
- Configurable force-sleep threshold (default: 20%)
- Spoken warnings via macOS text-to-speech
- Popup dialog alerts that steal focus
- All settings adjustable from the menubar dropdown
- Settings persist between launches
- No dependencies — pure Swift + AppKit

## Build

```bash
./build.sh
```

## Install

```bash
cp -r BatteryNag.app /Applications/
```

## Requirements

- macOS 13.0+
- Apple Silicon (arm64)
