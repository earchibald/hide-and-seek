---
project: hide-and-seek
type: doc
doc_type: spec
issue: "[[HS-2 cloud storage for settings and stats]]"
created: 2026-04-18
status: draft
tags:
  - project/hide-and-seek
  - doc
---
# Cloud storage for settings and stats

## Goal

Persist `GameSettings` and `GameStats` to the user's iCloud so preferences and lifetime progress follow them across devices and survive reinstall.

## Current state

- `GameSettings` lives in memory on `GameViewModel` — nothing persisted. A new install starts at defaults.
- `GameStats` is JSON-encoded into `UserDefaults` under `hideAndSeek.playerStats` (StatsManager.swift:14). Local-only.
- No iCloud/CloudKit entitlements on the target.

Payload sizes:
- Settings: 6 scalar fields, <100 bytes encoded.
- Stats: counters + `[GameResult]` capped at 100 entries (`won`, `turnsRemaining`, `date`). Worst case ≈ 5 KB JSON.

Both payloads are tiny and owned by a single user.

## Options considered

### 1. NSUbiquitousKeyValueStore (iCloud KVS)
- **Capacity**: 1 MB total, 1024 keys, 1 MB/value. Comfortable fit.
- **API**: drop-in replacement shape for UserDefaults.
- **Sync**: automatic, eventual-consistency, triggered on app foreground and on `synchronize()`. Change notifications via `NSUbiquitousKeyValueStore.didChangeExternallyNotification`.
- **Conflict model**: last-writer-wins per key. No merge semantics.
- **Offline**: writes persist locally and replay when network returns.
- **Cost**: one entitlement, ~50 LOC wrapper.

### 2. CloudKit private DB (direct or via `CKSyncEngine`)
- **Capacity**: effectively unlimited for our payload.
- **API**: records, zones, subscriptions, change tokens. `CKSyncEngine` (iOS 17+) hides most of it.
- **Conflict model**: per-record change tokens; app resolves merges.
- **Offline**: first-class queueing.
- **Cost**: CloudKit container + schema in dashboard, significant glue code, async lifecycle to reason about.

### 3. SwiftData + CloudKit (`ModelConfiguration(cloudKitDatabase: .private)`)
- **API**: model the stats as `@Model` types; SwiftData+CloudKit syncs automatically.
- **Constraints**: every attribute must be optional or have a default; no `@Attribute(.unique)`; no inverse-less relationships. Schema migrations are rigid.
- **Cost**: restructures the model layer. Overkill for one struct with a 100-entry history.

## Recommendation

**Use NSUbiquitousKeyValueStore for both settings and stats**, with explicit reconciliation on external-change notifications.

Rationale:
- Payloads are well under KVS limits.
- "Last-writer-wins" is acceptable for settings (single user, infrequent edits).
- Stats need merge semantics, but we can apply domain-level reconciliation on top of KVS (take `max` of lifetime counters and best streak, union+dedup history by `date`, trim to 100). KVS is the message bus; the merge is ours.
- Avoids CloudKit schema maintenance and SwiftData's modeling constraints for a tiny dataset.

If history ever grows past ~1000 entries, revisit with SwiftData+CloudKit.

## Design

### Entitlements & capabilities
- Add **iCloud → Key-Value storage** capability to the target. No CloudKit container needed.
- `com.apple.developer.ubiquity-kvstore-identifier` auto-generated from the bundle ID.

### Keys
- `hideAndSeek.settings.v1` — JSON-encoded `GameSettings` (make it `Codable`).
- `hideAndSeek.stats.v1` — JSON-encoded `GameStats` (already `Codable`).

Bumping the suffix handles forward-incompatible schema changes without colliding with old installs.

### Wrapper: `CloudStore`
A thin actor/class wrapping `NSUbiquitousKeyValueStore.default`:
- `load<T: Codable>(_ key: String) -> T?`
- `save<T: Codable>(_ value: T, for key: String)` — writes, calls `synchronize()`.
- Publishes `didChangeExternallyNotification` as an `AsyncStream` of changed keys.

### Settings persistence
- `GameViewModel.settings` becomes a persisted property. On init: load from KVS, fall back to local `UserDefaults` mirror, fall back to defaults.
- Mirror to `UserDefaults` on every change so the app functions when signed out of iCloud.
- On external change: overwrite in-memory settings (last-writer-wins is fine).

### Stats persistence — reconciliation
`StatsManager` keeps the local `UserDefaults` cache as ground truth while online, but on external change from KVS merges:

```
merged.lifetimeWins    = max(local.lifetimeWins,    remote.lifetimeWins)
merged.lifetimeLosses  = max(local.lifetimeLosses,  remote.lifetimeLosses)
merged.bestStreak      = max(local.bestStreak,      remote.bestStreak)
merged.currentStreak   = local.currentStreak  // device-local concept
merged.lastMilestone   = max-by-value
merged.gameHistory     = union by (date, won, turnsRemaining), sorted by date, tail 100
```

Write the merged result back to both local cache and KVS.

### First-launch / signed-out handling
- On launch: load local cache first (fast path, no blocking on iCloud).
- Register for KVS change notifications; merge when they arrive.
- Call `synchronize()` on `scenePhase == .active`.
- If iCloud is signed out (`FileManager.default.ubiquityIdentityToken == nil`), skip KVS reads/writes and log; resume when the token appears.

### Sign-in migration
On first KVS change after a previously-local-only install, run the same merge: local UserDefaults vs. incoming KVS. No special one-shot code path — the steady-state merge covers it.

### Testing
- Unit-test the merge function against hand-crafted `(local, remote)` pairs.
- Integration check: two simulators signed into the same iCloud account, verify convergence.
- `StatsManager` gets a `CloudStoreProtocol` injection point so existing tests using in-memory `UserDefaults` continue to pass; a `MockCloudStore` covers the sync path.

## Out of scope

- CloudKit sharing, public DB, per-device settings, account-switching UX, exporting stats.
- Server-side analytics.

## Rollout

1. Add entitlement + `CloudStore` wrapper.
2. Migrate `StatsManager` to `CloudStore` with the merge function; keep UserDefaults as offline cache.
3. Persist `GameSettings` via `CloudStore`; wire into `GameViewModel`.
4. Manual two-device verification.
