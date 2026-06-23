# Changelog

All notable changes to Stance are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- GitHub Release workflow: tag `v*.*.*` builds a Release DMG and publishes to Releases
- `Scripts/package_dmg.sh` for local or CI DMG packaging

### Added (earlier)

- Public open-source repository setup (README, LICENSE, contributing guidelines)
- GitHub Actions CI (build + unit tests)
- Unit test suite for desk protocol, profiles, auto-stand scheduling, and hotkey conflicts
- Auto-stand custom schedule mode, active hours, weekdays, quiet hours, and Focus mode suppression
- Auto-stand push notifications with Skip, Snooze, and Stand Now actions
- Break reminders (optional, independent of auto-stand)
- Standing session tracking with daily and weekly summaries in settings
- Desk Spotlight entity with live height indexing
- Expanded Siri / Shortcuts phrases for all core intents
- GATT validation before marking desk as connected
- Exclusive-connection error messaging when BLE connect fails
- Input Monitoring permission check aligned with `CGEventTap` requirements
- Hotkey conflict detection in settings
- Haptic feedback when preset moves complete
- Keyboard shortcuts in menu bar popover
- Popover dismisses on outside click

### Changed

- GitHub repository URL updated to `stance-ikea-desk-controller`
- About screen reads version from app bundle
- Profile cycle hotkey scopes to profiles for the active desk

## [1.0.0] - 2026-06-11

### Added

- Initial release of **Stance** — menu bar controller for IKEA IDÅSEN / LINAK desks
- BLE connect, position read, move up/down/stop, reference-input presets
- Guided calibration wizard
- Profiles with sit/stand heights and custom positions
- Global hotkeys (per profile)
- Multi-desk registration and switching
- Auto-stand hourly and interval modes
- App Intents for Shortcuts and Siri
- Settings: General, Desk, Profiles, Hotkeys, Auto-Stand, About
