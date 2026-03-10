![](https://repository-images.githubusercontent.com/1173163487/584308b6-310b-4091-9434-d6a6b120d3dd)

## Pickleball Score

This is a data field for Garmin watches that tracks your pickleball score in real time. It supports both **singles** and **doubles** game modes.

The app provides a touch-based split-screen interface: tap the top half to score for the opponent, tap the bottom half to score for yourself. A yellow serving indicator shows who is currently serving and on which court side.

Scores are saved into FIT files when you press the lap button, so you can review your games later in Garmin Connect.

[<img src="https://developer.garmin.com/static/available-badge-9e49ebfb7336ce47f8df66dfe45d28ae.svg" width="250">](https://apps.garmin.com/apps/62a9b9b6-8707-43b2-be75-adc52111f37c)

---

## How to install

This app is a **data field** for Garmin devices. To use it, you need to follow these steps:

1. **Install the data field** from the Connect IQ Store
2. **Add the data field to your activity's data screen** - it must be added as a **full-screen single field** for the data field to work
3. **Configure game type** - choose Singles or Doubles in the data field settings (defaults to Doubles)

### Playing a Game

- **First tap** establishes who serves first (tap your side or opponent's side)
- **Tap the serving side** to award a point
- **Tap the non-serving side** to signal a rally loss (serve switches)
- **Press the lap button** to save the score and start a new game

### Serving Indicator

A yellow circle shows who is serving and their court position (left or right). In doubles, the server number is displayed inside the indicator.

---

## Supported devices and beta program

This data field uses touch screen to interact with. Unfortunatelly not all Garmin watches support touch screen for a data field, even those which have touch screens. For example, this field will *not* work on epix 2, even if it is supports touch screen.

There's no easy way for me to figure out what watch can do that without testing on a physical device. If you own a watch not listed below and you want this data field, drop me a message to join beta testing.

### Works on

- ✅ fenix 8 Pro

### Does not work on

- ❌ epix 2

---

## Changelog

### Version 0.3.0

- Fixed: scores now display correctly as separate fields in Garmin Connect activity laps
- Added: score cap at 99 points

### Version 0.2.0

- Fixed: potential fix to display laps in Garmin Connect
- Changed: better app name to display
- Changed: bigger serve indicator
- Changed: screen size variable optimization

### Version 0.1.0

- Added: touch-based pickleball score tracking
- Added: singles and doubles game modes
- Added: proper doubles serving rules with 0-0-2 start
- Added: visual serving indicator with court side positioning
- Added: FIT file integration for saving scores to Garmin Connect
