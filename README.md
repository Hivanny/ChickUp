# PuffPet

PuffPet is a SwiftUI iOS app (iOS 16+) with a cute chick companion that reminds users to stand up or drink water during work hours.

## Setup
1. Open `PuffPet.xcodeproj` in Xcode 16+.
2. Add chick images to `Assets.xcassets` with these exact names:
   - `chick_stretch`
   - `chick_listening`
   - `chick_standup`
   - `chick_reading`
   - `chick_takingnote`
   - `chick_happy`
3. Build and run the `PuffPet` target.

## Default behavior
On first launch, PuffPet:
- creates default settings (9:00 AM to 5:00 PM, weekdays only, 30-minute interval),
- requests notification permission,
- schedules rolling local reminders for the next 48 hours.

## Notes
- Use a real device to fully test local notification delivery and actions (`DONE`, `SNOOZE 10 MIN`).
- Settings changes are saved with SwiftData and trigger immediate re-scheduling.
