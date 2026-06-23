# Contributing to Stance

Thank you for your interest in contributing. Stance is an unofficial macOS menu bar app for IKEA IDÅSEN / LINAK sit-stand desks.

## Getting started

### Requirements

- macOS 15 or later
- Xcode 26 or later (Xcode beta is fine)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build from source

```bash
git clone https://github.com/alexandrustefan/stance-ikea-desk-controller.git
cd stance-ikea-desk-controller
xcodegen generate
open IKEADeskController.xcodeproj
```

In Xcode, select the **IKEADeskController** scheme, set your **Development Team** under Signing if you want stable Bluetooth permissions during development, then build and run.

### Run tests

```bash
xcodegen generate
xcodebuild test \
  -project IKEADeskController.xcodeproj \
  -scheme IKEADeskController \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO
```

## Pull requests

1. Fork the repository and create a feature branch from `main`.
2. Keep changes focused — one logical change per PR when possible.
3. Match existing Swift style and naming in the surrounding code.
4. Add or update unit tests for logic changes (see `IKEADeskControllerTests/`).
5. Ensure the project builds and tests pass locally before opening a PR.
6. Write a clear PR description: what changed, why, and how you tested it.

## Code areas

| Area | Path |
|------|------|
| App lifecycle & state | `IKEADeskController/App/` |
| BLE / desk protocol | `IKEADeskController/BLE/` |
| Menu bar UI | `IKEADeskController/Features/MenuBar/` |
| Settings | `IKEADeskController/Features/Settings/` |
| Services (hotkeys, auto-stand, notifications) | `IKEADeskController/Services/` |

## Reporting bugs

Open a [GitHub issue](https://github.com/alexandrustefan/stance-ikea-desk-controller/issues) and include:

- macOS version
- Stance version (About → Settings)
- Desk model if known
- Steps to reproduce
- Whether another app (IKEA Home smart, phone LINAK app) was connected to the desk

## Releases

Published builds are attached to [GitHub Releases](https://github.com/alexandrustefan/stance-ikea-desk-controller/releases) as unsigned DMGs. Pushing a version tag triggers the release workflow:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow runs tests, builds Release, packages `Stance-VERSION.dmg`, and publishes it. To package locally:

```bash
xcodegen generate
xcodebuild build -project IKEADeskController.xcodeproj -scheme IKEADeskController \
  -configuration Release -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
./Scripts/package_dmg.sh 1.0.0 build/DerivedData/Build/Products/Release/Stance.app
```

Official releases are unsigned until Apple Developer signing is set up. Users must **Right-click → Open** the first time. Building from source with a Personal Team gives a smoother permission experience for developers.
