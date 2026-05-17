# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Goal

Open-source macOS app analogous to the classic **Punto Switcher** and the modern (paid)
**Lang Switcher**: detects text typed in the wrong keyboard layout, rewrites it, and switches
the system input source, plus a manual gesture for the cases it gets wrong. EN↔RU (the layout
map is JSON-driven and extensible).

## Build & test

- `swift test` — fast pure-`Core` suite (TDD loop; no macOS APIs).
- `xcodegen generate` — regenerate the Xcode project. REQUIRED after adding/removing any
  source file (XcodeGen globs at generation time).
- `xcodebuild -project vjookh.xcodeproj -scheme vjookh -configuration Debug build`
- `xcodebuild -project vjookh.xcodeproj -scheme vjookh test` — full Xcode test run.
- Run a single test: `swift test --filter CoreTests/<Class>/<method>`.
- Built app: `~/Library/Developer/Xcode/DerivedData/vjookh-*/Build/Products/Debug/vjookh.app`.
- Env quirk: if `xcodebuild` fails loading a simulator plugin, run `xcodebuild -runFirstLaunch` once.

## Code signing (critical — Accessibility permission depends on it)

- The app needs Accessibility (CGEventTap); it is NOT sandboxed (no App Store).
- Ad-hoc signing makes the designated requirement a volatile `cdhash`, so every rebuild
  revokes the TCC grant and the app re-prompts. A stable local identity ("vjookh Dev", set up
  by `scripts/setup-dev-signing.sh`) fixes this; it is wired in `project.yml`
  (`CODE_SIGN_IDENTITY`).
- Clear stale grants: `tccutil reset Accessibility io.github.vjookh.app`.
- The update-signing private key (`privkey.pem`) lives OUTSIDE the repo and is
  never tracked — `*.pem` is gitignored. Don't add it back.

## Architecture

- `Sources/Core` — pure logic, NO system APIs, fully TDD'd: `LayoutMap`, `Lexicon` (hunspell
  `.dic` reader; named Lexicon to avoid stdlib clash), `Detector`, `KeystrokeBuffer`,
  `EventClassifier`, `InputSourceSelector`, `EditPlanner`, `ShiftDoubleTapDetector`,
  `Plausibility` (vowel-structure heuristic). Add tests here first.
- Detector asymmetry (intentional): RU-typed-in-EN is caught by dictionary
  cross-check AND a medium-confidence no-Latin-vowel heuristic; EN-typed-in-RU
  has no reliable structural signal so it stays dictionary-only. Don't add a
  symmetric heuristic — it causes false positives.
- `Sources/System` — thin macOS adapters, manually integration-tested (cannot be
  self-verified — CGEventTap/TIS need the user to run the app & report).
- `Sources/App` — `AppDelegate` (menu-bar agent) + `CorrectionPipeline`.
- Resources via `ResourceBundle.swift`: `Bundle.allBundles` excludes SwiftPM's `*_Core.bundle`,
  and the Xcode framework build flattens `Resources/` — use that helper, never `Bundle.module`
  directly.
- Privacy invariant: keystrokes in-memory only; no disk/network. Keep it.

## Workflow

- Strict TDD for `Core` (watch RED before GREEN). System adapters: build, then ask the user
  to run the checklist — never claim system behavior verified without their confirmation.
- The user is not a systems engineer and delegates macOS/tooling decisions to Claude — decide
  and justify briefly rather than asking.
