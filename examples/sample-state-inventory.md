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
