# Enso — A Zen Water Reminder for iPhone

A minimal SwiftUI hydration app built around a single Japanese **ensō** (円相) — the ink brush circle drawn in one stroke. The circle is your daily water goal. Tap to drink, watch the ink fill. When the goal is reached, a vermillion hanko seal is stamped and the paper washes with ink.

No dashboards. No streaks. No gamification. Every pixel serves a purpose.

---

## Features

- **The Ensō** — a hand-drawn Canvas brush stroke that grows bolder with each glass. Tap anywhere on the circle to log water; an ink ripple and haptic confirm the tap.
- **Smart daily goal** — a base goal (default 2,000 ml) that adapts automatically to:
  - **Activity** — steps, workouts, and sleep from HealthKit / Apple Watch
  - **Weather** — current temperature via WeatherKit
  - **Recovery** — short sleep bumps the goal; good sleep leaves it alone
- **Weekly stats** — a sumi-ink bar chart of the last 7 days, plus a breakdown of how today's smart adjustments were calculated.
- **Settings** — glass size, base goal, adaptivity toggles, quiet-during-sleep, notifications, haptics.
- **Light & dark mode** — warm washi paper cream by day, near-black paper by night. Transitions with an ink-brush easing curve.
- **Local-only** — all state lives in `UserDefaults`. No accounts, no cloud, no telemetry.

## Design Language

| | |
|---|---|
| Aesthetic | Minimal zen — washi paper + sumi ink |
| Paper (light) | `#F2EDE3` |
| Ink (light) | `#2A2826` |
| Paper (dark) | `#161514` |
| Ink (dark) | `#E4DFD6` |
| Accent | Vermillion `#C4453C` (hanko seal, smart notes) |
| Typography | Shippori Mincho (serif) + Cormorant Garamond Light Italic |
| Principle | One circle. One stroke. No decoration. |

## Tech Stack

- **SwiftUI** (iOS 17+) with `@Observable` state
- **Canvas** for the hand-drawn ensō brush stroke
- **HealthKit** — steps, workouts, sleep (read-only)
- **WeatherKit** + **CoreLocation** — current conditions for hydration adjustment
- **UserNotifications** — gentle reminder scheduling, quiet during sleep hours
- **XcodeGen** (`project.yml`) for reproducible project generation

## Project Structure

```
Enso/
├── EnsoApp.swift              # @main entry point
├── Models/
│   ├── HealthData.swift       # Steps, workouts, sleep, weather
│   └── HydrationStore.swift   # @Observable app state + persistence
├── Services/
│   ├── HealthKitManager.swift # HealthKit queries
│   ├── WeatherManager.swift   # WeatherKit + CoreLocation
│   ├── SmartGoalEngine.swift  # Adaptive goal calculation
│   └── NotificationManager.swift
├── Theme/
│   └── EnsoTheme.swift        # Colors, typography, spacing, animation curves
└── Views/
    ├── RootView.swift         # Main ↔ Stats swipe container
    ├── MainScreen/            # Ensō canvas, ink ripples, hanko seal
    ├── StatsScreen/           # Weekly chart, smart breakdown, conditions
    └── SettingsScreen/
```

## How the Smart Goal Works

`SmartGoalEngine` starts from your base goal and layers in adjustments:

- **Warm weather** (> 24 °C) → up to +300 ml, scaled by temperature
- **Active day** (> 4,000 steps) → up to +375 ml, scaled by step count
- **Workouts** → +8 ml per minute, capped at +250 ml
- **Short sleep** (< 6 h) → +100 ml recovery bump

Each adjustment is shown on the stats screen with its reason, so the goal is never a black box.

## Building

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`.

```bash
brew install xcodegen
xcodegen generate
open Enso.xcodeproj
```

Requirements:
- Xcode 15+
- iOS 17 SDK
- An Apple Developer account (HealthKit and WeatherKit both require entitlements)

Set your own `DEVELOPMENT_TEAM` in `project.yml` before generating.

## Status

Personal-use iPhone app. Not published to the App Store.
