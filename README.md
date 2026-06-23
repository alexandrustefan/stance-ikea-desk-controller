# Stance

**Control your IKEA IDÅSEN or LINAK sit-stand desk from your Mac menu bar.**

Sit · Stand · Move — without opening your phone, creating an account, or sending data to the cloud.

<p align="center">
  <img src="IKEADeskController/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" alt="Stance app icon" width="128" />
</p>

<p align="center">
  <a href="https://github.com/alexandrustefan/stance-ikea-desk-controller/releases/latest"><strong>Download Stance for Mac</strong></a>
  &nbsp;·&nbsp;
  macOS 15+
  &nbsp;·&nbsp;
  Free & open source
</p>

<p align="center">
  <img src="screenshots/menu-bar-popover.png" alt="Stance menu bar popover showing desk height and sit/stand controls" width="320" />
</p>

> **Unofficial project.** Not affiliated with or endorsed by IKEA or LINAK. IKEA® and IDÅSEN® are trademarks of Inter IKEA Systems B.V.

---

## Why Stance?

You bought a desk that moves — but controlling it from your Mac usually means juggling the IKEA or LINAK phone app, or giving up altogether.

Stance stays in your menu bar and talks to your desk over **Bluetooth**. Connect once, calibrate your sit and stand heights, then:

- **Click** the menu bar icon to move the desk
- **Press a hotkey** to jump to sit or stand without switching apps
- **Ask Siri** or use Shortcuts to move the desk hands-free
- **Set a schedule** that nudges you to stand throughout the day

Everything runs on your Mac. No account. No cloud sync.

---

## Get Stance (about 2 minutes)

**Best for most people:** download the app. No Xcode, no Terminal, no compiling.

1. Go to **[Releases](https://github.com/alexandrustefan/stance-ikea-desk-controller/releases/latest)** and download **`Stance-x.x.x.dmg`**.
2. Open the DMG and **drag Stance to Applications**.
3. **First launch:** macOS will warn that the app is from an unidentified developer. That is normal for unsigned open-source Mac apps.
   - **Right-click Stance** in Applications → **Open** → click **Open** again, **or**
   - Open Stance once, then go to **System Settings → Privacy & Security → Open Anyway**.
4. Open Stance from Applications or Spotlight (⌘Space → “Stance”).
5. Click **Allow** when macOS asks for **Bluetooth**.
6. Look for the **table icon** in your menu bar (top-right).

**Updating later?** Download the new DMG, replace the app in Applications, and use **Right-click → Open** once if macOS blocks it again.

<details>
<summary><strong>Other install options</strong> (build from source, developers)</summary>

### Which path is for you?

| | **Download (above)** | **Build from source** | **Dev quick try** |
|---|------------------------|----------------------|-------------------|
| **Who** | Most people | Power users who want signing or latest code | People editing the repo |
| **Needs Xcode?** | No | Yes | Yes |
| **Bluetooth permission** | Once per install | Best if signed with Apple ID | May ask every launch |

### Build from source

Use this if you want **Launch at login**, the most reliable Bluetooth behavior, or code that is not released yet.

**1. Get the project** — open Terminal and run:

```bash
brew install xcodegen
git clone https://github.com/alexandrustefan/stance-ikea-desk-controller.git
cd stance-ikea-desk-controller
xcodegen generate
open IKEADeskController.xcodeproj
```

**2. Sign with your Apple ID (one-time)** — in Xcode: select the **IKEADeskController** target → **Signing & Capabilities** → enable **Automatically manage signing** → choose your **Team** (free Apple ID works).

**3. Install to Applications** — either:

- **In Xcode:** Product → Build (⌘B) → Product → Show Build Folder in Finder → drag **Stance.app** to Applications, **or**
- **In Terminal:** `./Scripts/install.sh` (builds Release and copies to `/Applications/Stance.app`)

**4. Open Stance** from Applications and allow Bluetooth once.

### Dev quick try

For active development only. The app runs from a build folder, is not really “installed,” and Bluetooth may prompt every launch:

```bash
xcodegen generate
xcodebuild build -project IKEADeskController.xcodeproj -scheme IKEADeskController \
  -configuration Debug -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
open build/DerivedData/Build/Products/Debug/Stance.app
```

### Why does Bluetooth keep asking?

macOS remembers Bluetooth access based on **where the app lives** and **how it was signed**.

- **Downloaded or in Applications** → usually asked once per version.
- **Signed with your Apple ID in Applications** → most reliable.
- **Run from Xcode or a `build/` folder** → macOS treats each build as a new app.

Use the download or signed build path for daily use.

**Launch at login** (Settings → General) may not work with unsigned downloads until Apple Developer signing is added.

</details>

---

## Set up your desk (first run)

1. Click the **Stance** icon in the menu bar.
2. Open **Settings → Desk** and connect your desk.
   - Connection failed? Quit the **IKEA Home smart** or **LINAK** app on your phone — only one device can control the desk at a time.
3. Run **Calibration** to set your desk’s range and your sit/stand heights.
4. Move the desk from the **popover**, **keyboard shortcuts**, or **Siri** (“Stand up with Stance”).

---

## What you can do

### Control from the menu bar

- See live height and connection status
- Tap **Sit**, **Stand**, or custom positions (Lunch, Focus, etc.)
- Hold **Up/Down** to nudge, **Stop** to cancel
- Right-click the icon for quick actions without opening the popover
- Optionally show current height next to the icon (Settings → General)

### Keyboard shortcuts

Fully remappable per profile. Defaults use ⌃⌥⌘:

| Action | Default |
|--------|---------|
| Move to Sit | ⌃⌥⌘S |
| Move to Stand | ⌃⌥⌘D |
| Move Up (hold to repeat) | ⌃⌥⌘↑ |
| Move Down (hold to repeat) | ⌃⌥⌘↓ |
| Cycle profiles | ⌃⌥⌘P |
| Emergency stop | ⌃⌥⌘. |

Turn on hotkeys in Settings — macOS will ask for **Input Monitoring** permission.

### Auto-Stand reminders

Gentle nudges to change posture on a schedule:

| Mode | What it does |
|------|----------------|
| **Hourly** | Stand for a few minutes at the top of each hour |
| **Interval** | Alternate sit and stand blocks |
| **Custom** | Your own time blocks |

Optional rules: active hours, weekdays only, quiet hours, pause when inactive, respect Focus/DND, break reminders, and notifications with **Stand Now**, **Snooze**, or **Skip**.

Track today’s standing time in Settings → Auto-Stand.

### Profiles & multiple desks

- **Profiles** — Work, Home, etc., each with its own sit/stand heights and hotkeys
- **Multiple desks** — register more than one LINAK desk and switch between them
- **Import / export** — back up profiles as JSON

### Siri, Shortcuts & Spotlight

- “Stand up with Stance”, move to a height, switch profiles, get current height, and more
- Find your desk and profiles from Spotlight

---

## Screenshots

| Menu bar popover | Settings — Desk | Calibration |
|------------------|-----------------|-------------|
| ![Popover](screenshots/menu-bar-popover.png) | ![Desk settings](screenshots/settings-desk.png) | ![Calibration](screenshots/calibration.png) |

| Profiles | Auto-Stand | Hotkeys |
|----------|------------|---------|
| ![Profiles](screenshots/settings-profiles.png) | ![Auto-Stand](screenshots/settings-auto-stand.png) | ![Hotkeys](screenshots/settings-hotkeys.png) |

---

## Requirements

| You need | Notes |
|----------|--------|
| **Mac with macOS 15+** (Sequoia or later) | Works on macOS 15–25 with standard Mac styling; enhanced visuals on macOS 26+ |
| **IKEA IDÅSEN** or compatible **LINAK** sit-stand desk | Bluetooth-enabled |
| **Bluetooth on** | Required to find and control the desk |
| **Xcode** | Only if building from source (see **Other install options** above) — not needed for the download |

---

## Permissions

| Permission | When | Why |
|------------|------|-----|
| **Bluetooth** | First launch | Connect to your desk |
| **Input Monitoring** | When you enable hotkeys | Global shortcuts while other apps are open |
| **Notifications** | When Auto-Stand alerts are on | Reminders with Stand / Snooze / Skip |

Change these anytime in **System Settings → Privacy & Security**.

---

## Technical notes

<details>
<summary>For the curious — connection behavior, calibration, and design details</summary>

### Connection

- Auto-connects to your last desk and retries after sleep or disconnect
- Manual scan to add new desks
- Shows **Connected** only when the desk is actually ready
- Clear errors when another app is already connected to the desk
- Optional legacy movement mode for desks that need up/down impulses instead of target heights

### Calibration

- Guided wizard for min/max travel and comfortable sit/stand heights
- Per-desk measurements instead of generic factory offsets
- Recalibrate anytime from Settings → Desk

### Design

- Native Mac menu bar app (no Dock icon unless the popover is open)
- Sage green app icon — same desk/table symbol as the menu bar
- Haptic feedback when preset moves finish

</details>

---

## Development

Contributors: see [CONTRIBUTING.md](CONTRIBUTING.md).

```bash
xcodegen generate
xcodebuild test \
  -project IKEADeskController.xcodeproj \
  -scheme IKEADeskController \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO
```

60+ unit tests cover desk protocol, calibration, profiles, auto-stand scheduling, hotkeys, and more. BLE and UI need a real desk for manual testing.

---

## License

[MIT](LICENSE) — Copyright (c) 2026 Alexandru Stefan
