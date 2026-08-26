# DietBuddy

A SwiftUI + SwiftData iOS app for tracking food, weight, and nutrition goals.

## Motivation

DietBuddy is a **"no-code" experiment**: the entire app was built by directing an AI
coding assistant rather than by writing the code by hand. The goals of the project are to:

- See how far a fully AI-driven workflow can go in building a real, functional iOS app.
- Learn how to use AI effectively in day-to-day software development — how to prompt,
  review, iterate, and course-correct.
- Explore modern SwiftUI, SwiftData, and Swift concurrency along the way.

Every feature, refactor, and bug fix in this repository was produced through that
human-in-the-loop, AI-assisted process.

## Features

- **Weight tracking** — log weigh-ins, see a trend chart over an adjustable period, and
  browse/edit full history.
- **Food logging** — build up a day from user-created meals (Breakfast, Lunch, or numbered),
  with macro progress rings that fill toward your goal and shift red → green → purple.
- **Adding food** — scan a barcode (looked up via Open Food Facts) or enter nutrition by
  hand; portions in grams or ounces.
- **Saved meals** — save a logged meal and re-add it later as a single collapsible bundle.
- **Goals** — keep multiple nutrition goals with one "active" goal driving the day's targets.
- **Account & settings** — a local account with light/dark/system appearance, an accent
  color, and unit preference.

## Requirements

- iOS 26.0+
- Xcode with the iOS 26 SDK

## Project structure

```
DietBuddy/
├── App/         # App entry point and root tab view
├── Models/      # SwiftData models (Food, Meal, WeightEntry, Goal, SavedMeal, …)
├── Services/    # Networking / lookup (Open Food Facts)
├── Support/     # Theme, reusable views, DEBUG sample data
└── Views/       # Feature screens: Weight, Food, Goals, SavedMeals, Account
```

## Notes

- Nutrition for logged items is **snapshotted** at log time, so editing the Food library
  later never changes past entries.
- Sample data is seeded only in **DEBUG** builds and never ships in release.
- To run on a physical device you'll need to set your own bundle identifier and signing team.

## Development

See [AGENTS.md](AGENTS.md) for the conventions the AI assistant follows when working in
this repository.
