# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | Yes       |

## Reporting a vulnerability

If you discover a security issue in Stance, please report it responsibly.

**Do not** open a public GitHub issue for security vulnerabilities.

Instead, use [GitHub Security Advisories](https://github.com/alexandrustefan/stance-ikea-desk-controller/security/advisories/new) to report the issue privately, or contact the repository owner through GitHub.

Include:

- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You should receive a response within a reasonable timeframe. We will work with you to understand and address the issue before any public disclosure.

## Scope

Stance is a local-only macOS application. It:

- Connects to desks over Bluetooth (CoreBluetooth)
- Stores profiles and settings in local UserDefaults / app group storage
- Does not transmit data to external servers
- Does not use network permissions

Reports about desk BLE protocol behavior or physical desk safety (e.g. collision risk) are welcome but may be out of scope for code fixes — we will still triage them.

## Safe disclosure

We appreciate researchers and users who report issues in good faith. We will not pursue legal action against good-faith security research on this open-source project.
