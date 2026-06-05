<p align="center">
  <img src="icon-512.png" width="200" alt="BatteryNag Icon">
</p>

# BatteryNag

A lightweight macOS menubar app that aggressively warns you when your battery is low and force-sleeps the Mac at a critical threshold.

## Why

macOS only shows a small, easy-to-miss banner at 20% and 10% battery, and its built-in low-battery sleep triggers at around 2-5%. There's no native way to get aggressive warnings at a higher threshold or to force sleep before the battery drops dangerously low.

If you don't notice the charger got disconnected, the Mac quietly drains all the way down — which stresses the battery (deep discharges degrade lithium cells faster) and can cause data loss from a hard power-off instead of a graceful sleep.

BatteryNag fills that gap: it nags you loudly (dialog + voice) starting at 40% so you actually notice, and force-sleeps the Mac at 20% as a safety net. All configurable from the menubar.

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
