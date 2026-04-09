# Enso — Water Reminder App Design

## Overview
A minimal zen water reminder iPhone app. The entire UI centers on a single Japanese enso (ink brush circle) that represents daily hydration progress. Data flows dynamically from Apple Watch via HealthKit.

## Platform & Tech
- **Device:** iPhone (personal use, no App Store)
- **Framework:** SwiftUI (iOS 17+)
- **Data Sources:** HealthKit (Apple Watch), WeatherKit (device location)
- **Storage:** Local only (UserDefaults / SwiftData). No cloud.

## Design Language
- **Aesthetic:** Minimal zen — washi paper + sumi ink
- **Light mode:** Warm cream paper (#F2EDE3), charcoal ink (#2A2826)
- **Dark mode:** Near-black paper (#161514), warm white ink (#E4DFD6)
- **Accent:** Vermillion red (#C4453C) for completion seal and smart notes
- **Typography:** Serif throughout — thin/italic for labels, regular weight for values
- **Principle:** Every pixel serves a purpose. No decoration.

## Screens

### 1. Main (The Enso)
- Center: Brush stroke circle drawn on Canvas
- Stroke starts faded/incomplete, grows bolder as user drinks
- Tap anywhere on circle = log one glass (ink ripple + haptic)
- Progress text appears after first tap: `750 ml` / `of 2,000 ml`
- Red hanko seal stamps when goal reached + ink wash effect
- Theme toggle top-right
- "details" swipe cue at bottom

### 2. Stats (swipe up from main)
- Today's intake (hero number + progress bar)
- Weekly bar chart
- Apple Watch data (6-cell grid): sleep, wake time, steps, active cal, avg HR, workout
- Weather (3-cell grid): current temp, high, humidity
- Smart adjustment: summary + itemized breakdown of goal adjustments
- Back button + gear icon for settings

### 3. Settings (slide from right)
- Glass size (stepper: 50-1000ml)
- Daily base goal (stepper: 500-5000ml)
- Data sources status: Apple Watch, HealthKit, Weather
- Smart reminder toggles: adapt to activity, adapt to weather, quiet during sleep
- Notification and haptic toggles
- Reset today button

## Smart Goal Algorithm
- Base goal (user-set, default 2000ml)
- Weather: +50ml per degree above 24C (max +300)
- Steps: +75ml per 1000 steps above 4000 (max +375)
- Workout: +8ml per minute (max +250)
- Poor sleep (<6h): +100ml

## Data Flow
- HealthKit queries on app launch + background refresh
- Sleep analysis, step count, active calories, heart rate, workouts
- WeatherKit current conditions on launch + hourly
- All data displayed with "synced X min ago" freshness indicator

## Reference
Interactive mockup: `index.html` in project root
