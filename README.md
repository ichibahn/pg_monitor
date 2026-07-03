# pg_monitor

An interactive, menu-driven PostgreSQL monitoring & troubleshooting shell for DBAs and SREs.
One bash script + 57 battle-tested SQL checks. No agents, no daemons — just `psql`.

*[한국어 문서 (Korean version)](README.ko.md)*

## Why pg_monitor?

Every PostgreSQL DBA carries a private stash of diagnostic queries — and mid-incident, at 3 AM, you end up digging through old notes for "that bloat query" or "the lock tree one". **pg_monitor packs that entire toolbox behind one numbered menu.** Connect, type a number, read the answer: sessions, locks, vacuum, WAL, replication, bloat, cloud specifics, and urgent actions — with nothing to memorize and no query files to carry. If you can read the menu below, you can troubleshoot.

This is the whole tool — the screen you see the moment you connect:

```
================================
 PostgreSQL Monitor Ver1.1.0
================================
  PostgreSQL Version: 18 | Environment: RDS
  Host: ********** | Port: **** | Database: ******** | User: ********
 ---------------------------------------------------------------------------------------
 1. GENERAL                                 | 2. PERFORMANCE METRICS
 ------------------------------------------ + ------------------------------------------
  11 - Cluster/Instance Info                |  21 - Buffer Cache Hit Ratio
  12 - Modified Parameter                   |  22 - TOP 30 Queries (pg_stat_statements)
  13 - Database Info                        |  23 - Transaction Stat By Database
  14 - User Privilege (Database)            |  24 - Unused Indexes
  15 - User Privilege (Schema)              |  25 - HOT Update Ratio
                                            |  26 - Index Bloat Estimate
                                            |  27 - Duplicate Indexes
                                            |  28 - Foreign Keys Without Index
                                            |  29 - I/O Statistics (PG16+)
 ---------------------------------------------------------------------------------------
 3. SESSION / QUERY ACTIVITY                | 4. SEGMENT & OBJECT INFO
 ------------------------------------------ + ------------------------------------------
  31 - Active Sessions                      |  41 - Table Size/Rows
  32 - Long Running Queries/Transactions    |  42 - Index Size/Rows
  33 - Blocking / Blocked Sessions          |  43 - Tablespace Size
  34 - Wait Event (Type)                    |  44 - Table Detail Info
  35 - Idle (in Transaction) Sessions       |  45 - Partition Table Info
  36 - Lock Wait Tree                       |  46 - Table Padding Info
  37 - Prepared Transactions (2PC)          |  47 - Table Bloat Estimate
  38 - Parallel Query Workers               |  48 - TOAST Size Info
 ---------------------------------------------------------------------------------------
 5. WAL & ARCHIVE                           | 6. VACUUM
 ------------------------------------------ + ------------------------------------------
  51 - Wal Status                           |  61 - Vacuuming Sessions
  52 - Archive Status                       |  62 - DeadTuple Ratio
  53 - Wal / Archive Setting (Parameter)    |  63 - Vacuum Eligible Tables
  54 - Checkpoint Statistics                |  64 - Vacuum Phase Info
  55 - WAL Generation Stat (PG14+)          |  65 - Vacuum Freeze Warning
                                            |  66 - Vacuum Setting (Database)
                                            |  67 - Vacuum Setting (Parameter)
                                            |  68 - Tables Not Vacuumed Recently
 ---------------------------------------------------------------------------------------
 7. REPLICATION                             | 8. URGENT ACTION (CAUTION!)
 ------------------------------------------ + ------------------------------------------
  71 - Replication Status (Primary)         |  81 - Session KILL (terminate)
  72 - Replication Status (Standby)         |  82 - Disable Autovacuum (Table)
  73 - Replication Slot Status              |  83 - Query Cancel (safer than KILL)
  74 - Logical Replication Status           |  84 - Kill Idle-in-Transaction Sessions
 ---------------------------------------------------------------------------------------
 9. CLOUD (RDS/AURORA ONLY)                 | 0. OTHER
 ------------------------------------------ + ------------------------------------------
  91 - Cloud Env Info          [RDS/Aurora] |  S - Save Report to File
  92 - Aurora Global DB Status [Aurora]     |  X or Q - EXIT
  93 - Aurora Memory Usage     [Aurora]     |
  94 - DB Log Files (log_fdw)  [RDS/Aurora] |
 ---------------------------------------------------------------------------------------

 Choose the Number or Command:
```

- Works on **vanilla PostgreSQL, Amazon RDS for PostgreSQL, and Amazon Aurora PostgreSQL** — the environment is auto-detected and shown in the header (`Environment:` above), and menu items branch accordingly (e.g. replication status on Aurora automatically shows `aurora_replica_status()`).
- Verified against **PostgreSQL 13–18** (tested on 14/15/16/17 containers + RDS/Aurora 18.3, writers and replicas).

## Quick Start — 3 commands, copy & run

```bash
sudo apt install postgresql-client                                  # once. RHEL/Rocky: sudo dnf install postgresql
git clone https://github.com/ichibahn/pg_monitor.git ~/pg_monitor
bash ~/pg_monitor/monitor
```

Type your host/port/database/user/password at the prompt — the menu above appears. That's the entire setup.

## Requirements

| Component | Requirement |
|---|---|
| Client OS | Linux / macOS (bash 3.2+) |
| Client tool | `psql` 10 or later |
| Server | PostgreSQL 13+ (vanilla, RDS, Aurora) |

Install the `psql` client if you don't have it:

```bash
# Ubuntu / Debian
sudo apt install postgresql-client

# RHEL / Rocky / Alma
sudo dnf install postgresql

# macOS (Homebrew)
brew install libpq && brew link --force libpq
```

If `psql` is missing, `monitor` exits with the same guidance instead of failing on connection.

## Installation

```bash
# clone (or extract the tar) into your home directory
git clone https://github.com/ichibahn/pg_monitor.git ~/pg_monitor
# or: tar -xvf pg_monitor_YYYYMMDD.tar -C ~

bash ~/pg_monitor/monitor
```

Installed somewhere else? Don't edit the script — set `PG_MONITOR_PATH`:

```bash
PG_MONITOR_PATH=/opt/pg_monitor bash /opt/pg_monitor/monitor
```

Optional `.profile` / `.bashrc` alias:

```bash
alias pm='PG_MONITOR_PATH=$HOME/pg_monitor bash $HOME/pg_monitor/monitor'
```

## Usage

Run `pm` (or `bash ~/pg_monitor/monitor`), then enter connection info:

```
Enter PostgreSQL Host (default: localhost): mydb.xxxx.us-east-1.rds.amazonaws.com
Enter PostgreSQL Port (default: 5432):
Enter PostgreSQL Database (default: postgres):
Enter PostgreSQL User (default: postgres):
Enter PostgreSQL Password:
PostgreSQL Major Version: 17 (RDS)
```

Pick a menu number, read the output, press Enter to go back. `S` saves a full report to `log/`, `X`/`Q` exits.

A user with the `pg_monitor` role (PG10+) can run every read-only item; `8x` action items need
`pg_signal_backend` / table ownership.

## Menu Reference

### 1. GENERAL
| # | Item | Notes |
|---|---|---|
| 11 | Cluster/Instance Info | version, uptime, encoding, TZ, Primary/Standby role, max XID age |
| 12 | Modified Parameter | parameters that differ from defaults, incl. pending_restart |
| 13 | Database Info | `\list` |
| 14 | User Privilege (Database) | per-user database privileges |
| 15 | User Privilege (Schema) | per-user schema privileges (current DB only) |

### 2. PERFORMANCE METRICS
| # | Item | Notes |
|---|---|---|
| 21 | Buffer Cache Hit Ratio | from `pg_stat_database` (no extension needed) |
| 22 | TOP 30 Queries | needs `pg_stat_statements`; prints install guide if missing |
| 23 | Transaction Stat By Database | commits/rollbacks/IO + temp files, deadlocks |
| 24 | Unused Indexes | `idx_scan = 0` since stats reset |
| 25 | HOT Update Ratio | with fillfactor suggestion |
| 26 | Index Bloat Estimate | statistics-based estimation (no pgstattuple) |
| 27 | Duplicate Indexes | identical column/opclass/predicate definitions |
| 28 | Foreign Keys Without Index | lock/seq-scan accident prevention |
| 29 | I/O Statistics | `pg_stat_io` (PG16+; guided message below 16) |

### 3. SESSION / QUERY ACTIVITY
| # | Item | Notes |
|---|---|---|
| 31 | Active Sessions | counts by state + active list |
| 32 | Long Running Queries/Transactions | queries > 5 min AND transactions open > 15 min (vacuum blockers) |
| 33 | Blocking / Blocked Sessions | lock conflict matrix tree |
| 34 | Wait Event (Type) | grouped wait events with sample queries |
| 35 | Idle (in Transaction) Sessions | idle / idle-in-tx list |
| 36 | Lock Wait Tree | `pg_blocking_pids()`-based; root blockers first |
| 37 | Prepared Transactions (2PC) | orphaned 2PC holds locks & blocks vacuum |
| 38 | Parallel Query Workers | native parallel query activity by leader (note: Aurora "Parallel Query" is MySQL-only) |

### 4. SEGMENT & OBJECT INFO
| # | Item | Notes |
|---|---|---|
| 41 | Table Size/Rows | top 50 |
| 42 | Index Size/Rows | top 50 |
| 43 | Tablespace Size | size and location |
| 44 | Table Detail Info | one table deep-dive (size/options/vacuum history/indexes/constraints/triggers/columns); partition-aware total size |
| 45 | Partition Table Info | partition hierarchy with per-partition size |
| 46 | Table Padding Info | alignment padding calc + column order suggestion |
| 47 | Table Bloat Estimate | statistics-based estimation |
| 48 | TOAST Size Info | out-of-line storage per table |

### 5. WAL & ARCHIVE
| # | Item | Notes |
|---|---|---|
| 51 | Wal Status | WAL segment files + creation latency (Aurora: guided message) |
| 52 | Archive Status | `pg_stat_archiver` health |
| 53 | Wal / Archive Setting | related parameters |
| 54 | Checkpoint Statistics | `pg_stat_checkpointer` (PG17+) / `pg_stat_bgwriter` (≤16) |
| 55 | WAL Generation Stat | `pg_stat_wal` (PG14+; Aurora: guided message) |

### 6. VACUUM
| # | Item | Notes |
|---|---|---|
| 61 | Vacuuming Sessions | running vacuums |
| 62 | DeadTuple Ratio | top 50 by dead tuples |
| 63 | Vacuum Eligible Tables | threshold math incl. per-table reloptions |
| 64 | Vacuum Phase Info | `pg_stat_progress_vacuum` |
| 65 | Vacuum Freeze Warning | relfrozenxid age alerts |
| 66 | Vacuum Setting (Database) | freeze age / eager-mode probability |
| 67 | Vacuum Setting (Parameter) | autovacuum parameters |
| 68 | Tables Not Vacuumed Recently | 7+ days without (auto)vacuum/analyze |

### 7. REPLICATION
| # | Item | Notes |
|---|---|---|
| 71 | Replication Status (Primary) | `pg_stat_replication`; **on Aurora auto-switches to `aurora_replica_status()`** |
| 72 | Replication Status (Standby) | `pg_stat_wal_receiver`; **on Aurora auto-switches to `aurora_replica_status()`** |
| 73 | Replication Slot Status | slot health, retained WAL, NULL-safe for physical slots |
| 74 | Logical Replication Status | publications / subscriptions / workers |

### 8. URGENT ACTION (CAUTION!)
| # | Item | Notes |
|---|---|---|
| 81 | Session KILL | `pg_terminate_backend(pid)` |
| 82 | Disable Autovacuum (Table) | table-level `autovacuum_enabled=false` (guided on standby) |
| 83 | Query Cancel | `pg_cancel_backend(pid)` — cancels the query, keeps the session (try before 81) |
| 84 | Kill Idle-in-Transaction Sessions | preview targets → confirm → terminate |

### 9. CLOUD (RDS/AURORA ONLY)
| # | Item | Notes |
|---|---|---|
| 91 | Cloud Env Info | engine detection, `aurora_version()`, connected instance & role, `rds.*` params, rds_superuser check |
| 92 | Aurora Global DB Status | cross-region durability/RPO lag |
| 93 | Aurora Memory Usage | `aurora_stat_memctx_usage()` per-backend memory contexts |
| 94 | DB Log Files (log_fdw) | list/read DB logs via SQL; install guide if `log_fdw` missing (extensions are per-database) |

On vanilla PostgreSQL these items print a clear "cloud only" message with the closest standard alternative.

## Environment Support Matrix

| | vanilla | RDS | RDS replica | Aurora writer | Aurora reader |
|---|---|---|---|---|---|
| All 57 items run cleanly | ✅ | ✅ | ✅ | ✅ | ✅ |
| Aurora auto-branching (71/72) | n/a | n/a | n/a | ✅ | ✅ |
| WAL file items (51/55) | ✅ | ✅ | ✅ | guided msg | guided msg |
| Cloud items (91–94) | guided msg | ✅ | ✅ | ✅ | ✅ |

"Guided msg" = the item explains why it doesn't apply and where to look instead — no raw errors.

## Troubleshooting

- **`psql` not found** — install the client (see Requirements); the script prints per-distro commands.
- **`SQL scripts not found at ...`** — the package isn't at `$HOME/pg_monitor`; set `PG_MONITOR_PATH`.
- **`could not connect`** — check host/port/user/password, `pg_hba.conf`, and for RDS/Aurora the security group inbound rule for your client IP.
- **Menu 22 says pg_stat_statements missing** — add it to `shared_preload_libraries` (parameter group on RDS/Aurora) and `CREATE EXTENSION pg_stat_statements;`.
- **Limited rows in session views** — grant the `pg_monitor` role to your user.

## Disclaimer

These scripts come without warranty of any kind. Use them at your own risk.

## License

MIT
