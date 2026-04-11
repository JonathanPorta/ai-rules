# Sample State Inventory: Device Cleanup Utility

## Flow: Scan Machine

### Entry states
- first run with no prior data
- repeat run with previous summary available

### Loading states
- scan starting
- scan in progress by subsystem
- scan paused or interrupted

### Empty states
- no cleanup opportunities found
- permissions not granted yet

### Partial states
- some categories scanned, some pending
- some categories unavailable due to permissions

### Success states
- scan complete with summarized findings
- cleanup complete with space reclaimed summary

### Failure states
- scan failed globally
- single category failed
- cleanup failed for one or more items

### Recovery states
- retry failed category
- rescan machine
- review skipped items

### Destructive / Confirmation states
- confirm cleanup before removing selected files
- warn when cleanup may remove items permanently
- offer cancel path before destructive actions begin
- confirm completion when cleanup cannot be undone

## Notes
- indicate which cleanup actions are reversible vs permanent
- call out permission-dependent states and recovery paths
- preserve enough detail for users to understand skipped or failed items
