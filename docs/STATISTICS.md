# Dashboard Statistics Explained

## How Statistics Are Calculated

The dashboard displays 7 key metrics that give you complete visibility into your task workflow:

### 1. Total Tasks
**Count:** All tasks across all statuses  
**Formula:** backlog + todo + in_progress + stalled + done  
**Purpose:** Overall workload visibility

### 2. Backlog
**Count:** Tasks in `backlog` status  
**Meaning:** Future work that isn't ready to start yet  
**Not Active:** These haven't been started  
**Example:** "Research new firewall" - need to do this eventually

### 3. To Do
**Count:** Tasks in `todo` status  
**Meaning:** Work that's ready to start when you have time  
**Not Active:** Prioritized but not started yet  
**Example:** "Study CCNP Chapter 3" - ready to go, just need to start

### 4. Active
**Count:** Tasks in `in_progress` status ONLY  
**Meaning:** Work you are actively doing right now  
**Why This Matters:** This is the true "WIP" (Work In Progress)  
**Example:** "Configure TrueNAS SMB" - currently working on this

**Important:** Backlog and Todo are NOT counted as "Active" because:
- Backlog = not ready to start
- Todo = ready but not started
- In Progress = actually working on it ← Only these are "active"

### 5. Stalled
**Count:** Tasks in `stalled` status  
**Meaning:** Work that's blocked or waiting  
**Not Active:** Can't work on these right now  
**Not Done:** Still need to complete them eventually  
**Example:** "Build CCIE lab" - waiting for equipment delivery

### 6. Completed
**Count:** Tasks in `done` status  
**Meaning:** Finished work  
**Purpose:** Track accomplishments

### 7. Completion Rate
**Formula:** (Completed / Total) × 100  
**Purpose:** Measure overall progress  
**Example:** 1 done out of 7 total = 14.3%

## Visual Example

With the example tasks provided:

```
┌─────────────┬──────────┬─────────┬────────┬─────────┬───────────┬─────────────┐
│    Total    │ Backlog  │  To Do  │ Active │ Stalled │ Completed │ Completion  │
├─────────────┼──────────┼─────────┼────────┼─────────┼───────────┼─────────────┤
│      7      │    2     │    2    │   1    │    1    │     1     │    14.3%    │
└─────────────┴──────────┴─────────┴────────┴─────────┴───────────┴─────────────┘
```

**Breakdown:**
- **7 total tasks** = 2 backlog + 2 todo + 1 in_progress + 1 stalled + 1 done
- **1 active task** = Only the 1 task in "In Progress" column
- **14.3% complete** = 1 done ÷ 7 total

## Dashboard Colors

Statistics cards use colored left borders for quick visual identification:

- **Active** - Blue border (in progress work)
- **Stalled** - Orange/yellow border (blocked work)
- **Completed** - Green border (finished work)
- Others - Gray (neutral)

## Task Workflow

Understanding how tasks flow through statuses:

```
Backlog → To Do → In Progress → Done
              ↓         ↓
            Stalled  ← ↙
              ↓
        In Progress (when unblocked)
```

**Key Points:**
1. Tasks start in Backlog (not ready)
2. Move to To Do when ready (prioritized but not started)
3. Move to In Progress when actively working (THIS IS "ACTIVE")
4. May move to Stalled if blocked (remove from "active" count)
5. Return to In Progress when unblocked
6. Finally move to Done when complete

## Use Cases

### Scenario 1: High Active Count
```
Active: 5 tasks
```
**Meaning:** You're trying to work on 5 things at once  
**Action:** Consider moving some back to Todo to focus

### Scenario 2: High Stalled Count
```
Stalled: 8 tasks
```
**Meaning:** Lots of blocked work  
**Action:** Identify and remove blockers, or move to backlog if long-term blocked

### Scenario 3: Growing Backlog
```
Backlog: 50 tasks
```
**Meaning:** Lots of ideas but not prioritized  
**Action:** Review and move ready tasks to Todo, delete irrelevant ones

### Scenario 4: Low Completion Rate
```
Completion Rate: 5%
Done: 2 tasks, Total: 40 tasks
```
**Meaning:** Just getting started or too many tasks  
**Action:** Focus on completing more tasks, or clean up backlog

## Dashboard Best Practices

1. **Keep Active (In Progress) low** - Focus on finishing over starting
2. **Review Stalled regularly** - Unblock or move to backlog
3. **Prioritize from Backlog to Todo** - Only move when truly ready to start
4. **Celebrate Completed** - Track your accomplishments
5. **Watch Completion Rate** - Aim for steady progress

## Technical Details

The statistics are calculated in `scripts/generate-dashboard.py`:

```python
def calculate_stats(tasks, include_private=True):
    for column, task_list in tasks.items():
        for task in task_list:
            if column == 'backlog':
                backlog_count += 1
            elif column == 'todo':
                todo_count += 1
            elif column == 'in_progress':
                active_count += 1  # Only these are "active"
            elif column == 'stalled':
                stalled_count += 1
            elif column == 'done':
                done_count += 1
```

The key is that `active_count` only increments for `in_progress` tasks.

## Summary

**Active** = Currently working on (In Progress only)  
**Not Active** = Backlog (not ready) + Todo (not started) + Stalled (blocked)  
**Complete** = Done tasks

This gives you accurate visibility into:
- What you're actually working on now (Active)
- What's ready to start (Todo)
- What's blocked (Stalled)
- What's not ready yet (Backlog)
- What's finished (Completed)

The corrected statistics help you manage your actual workload, not just count tasks.
