# Plan: Dynamic Mixing Buses

## Summary

Change the number of mixing buses from a fixed 8 to a dynamic count where users can add/remove buses at runtime.

## Current State

- `MAX_BUSES = 8` constant defined in two places:
  - `src/state/instrument/mod.rs:21`
  - `src/state/session.rs:11`
- Buses created at startup via `(1..=MAX_BUSES).map(MixerBus::new).collect()`
- Each instrument has 8 pre-allocated send slots
- `bus()` and `bus_mut()` use `(id - 1)` indexing assuming contiguous IDs 1-8
- Mixer navigation hardcodes `MAX_BUSES` bounds

## Design Decisions

| Question | Decision |
|----------|----------|
| Bus ID reuse on delete | Never reuse - use incrementing `next_bus_id` counter |
| Instrument sends on bus delete | Disable send (`enabled = false`), keep the entry |
| Instrument output on bus delete | Reset to `OutputTarget::Master` |
| Initial bus count | Configurable via config (default: 8) |
| Bus limits | Min: 0, Max: 32 (practical limit) |

## Implementation Steps

### 1. State Changes

**`src/state/session.rs`**
- Remove `MAX_BUSES` constant
- Add `next_bus_id: u8` field to `SessionState`
- Change `bus()` and `bus_mut()` to find by ID instead of index math
- Add methods:
  - `add_bus(&mut self) -> u8` - creates bus with next_bus_id, returns ID
  - `remove_bus(&mut self, id: u8) -> bool` - removes bus by ID
  - `bus_ids(&self) -> impl Iterator<Item = u8>` - returns current bus IDs
- Update `mixer_cycle_section()` to use first bus ID (not hardcoded `1`)
- Update `new_with_defaults()` to accept configurable bus count

**`src/state/instrument/mod.rs`**
- Remove `MAX_BUSES` constant

**`src/state/mod.rs`**
- Remove `MAX_BUSES` from re-export (line 30)
- Update `mixer_move()` - for Bus, clamp to actual bus list bounds
- Update `mixer_jump()` - jump to first/last actual bus ID
- Update `mixer_cycle_output()` and `mixer_cycle_output_reverse()` - cycle through actual bus IDs

### 2. Actions

**`src/action.rs`**
- Add `BusAction` enum:
  ```rust
  pub enum BusAction {
      Add,
      Remove(u8),
      Rename(u8, String),
  }
  ```
- Add `Bus(BusAction)` variant to `Action` enum

### 3. Dispatch

**New file: `src/dispatch/bus.rs`**
- Handle `BusAction::Add`: create bus, sync instrument sends, mark routing dirty
- Handle `BusAction::Remove(id)`:
  - Reset instruments with `OutputTarget::Bus(id)` to Master
  - Disable sends to this bus
  - Remove automation lanes for this bus
  - Remove the bus
- Handle `BusAction::Rename`: update bus name

**`src/dispatch/mod.rs`**
- Add `mod bus;`
- Add match arm for `Action::Bus`

### 4. Instrument Send Sync

**`src/state/session.rs` or `mod.rs`**
- Add helper to ensure all instruments have sends for all current buses:
  ```rust
  pub fn sync_instrument_sends(instruments: &mut InstrumentState, buses: &[MixerBus])
  ```
- Called after adding a bus

### 5. Automation

**`src/state/automation/mod.rs`**
- Add `remove_lanes_for_bus(bus_id: u8)` method to `AutomationState`

### 6. Persistence

**`src/state/persistence/mod.rs`**
- Increment `BLOB_FORMAT_VERSION`
- Add migration: on load, compute `next_bus_id = buses.max_id + 1`

### 7. Config

**`src/config.rs`**
- Add `default_bus_count: Option<u8>` to defaults (default: 8)

### 8. Tests

Update tests in:
- `src/state/session.rs` - bus indexing tests
- `src/state/mod.rs` - mixer navigation tests

## Files to Modify

| File | Changes |
|------|---------|
| `src/state/session.rs` | Add `next_bus_id`, new methods, fix bus access |
| `src/state/instrument/mod.rs` | Remove `MAX_BUSES` |
| `src/state/mod.rs` | Fix mixer navigation, remove re-export |
| `src/action.rs` | Add `BusAction` and `Action::Bus` |
| `src/dispatch/mod.rs` | Add bus dispatch |
| `src/dispatch/bus.rs` | New file - bus action handling |
| `src/state/automation/mod.rs` | Add `remove_lanes_for_bus` |
| `src/state/persistence/mod.rs` | Version bump, migration |
| `src/config.rs` | Add `default_bus_count` |

## Verification

1. **Unit tests**: Run `cargo test` - all existing tests should pass after updates
2. **Manual testing**:
   - Create new project - should start with default 8 buses
   - Add bus - new bus appears, instruments get new send slot
   - Remove bus - instruments routing to it reset to Master, sends disabled
   - Save/load project - bus count persists correctly
   - Mixer navigation works with varying bus counts
3. **Audio**: Verify routing rebuilds correctly when buses change
