# pg_monitor

DBA/SRE를 위한 대화형 메뉴 방식 PostgreSQL 모니터링·트러블슈팅 셸입니다.
bash 스크립트 하나 + 실전 검증된 SQL 57개. 에이전트도 데몬도 없이 `psql`만 있으면 됩니다.

*[English version](README.md)*

## 왜 pg_monitor 인가?

PostgreSQL DBA라면 누구나 자기만의 진단 쿼리 모음을 갖고 다닙니다 — 그리고 장애가 터진 새벽에는 "그 bloat 쿼리가 어디 있더라", "락 트리 쿼리가 뭐였지" 하며 옛 메모를 뒤지게 됩니다. **pg_monitor는 그 쿼리 툴박스 전체를 번호 메뉴 하나에 담았습니다.** 접속하고, 번호를 누르고, 결과를 읽으면 끝 — 세션, 락, vacuum, WAL, 복제, bloat, 클라우드 전용 항목, 긴급조치까지. 카탈로그 이름을 외울 필요도, 쿼리 파일을 들고 다닐 필요도 없습니다. 아래 메뉴만 읽을 수 있으면 트러블슈팅을 시작할 수 있습니다.

이것이 도구의 전부입니다 — 접속하는 순간 보이는 화면:

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

- **vanilla PostgreSQL / Amazon RDS / Amazon Aurora PostgreSQL** 모두 지원 — 접속 시 환경을 자동 감지해 헤더에 표시하고(위 `Environment:`), 항목별로 자동 분기합니다 (예: Aurora에서 복제 상태 조회 시 `aurora_replica_status()`를 자동 실행).
- **PostgreSQL 13~18** 검증 완료 (14/15/16/17 컨테이너 + RDS/Aurora 18.3, writer·replica 전부 실측).

## Quick Start — 명령어 3줄, 그대로 복사해서 실행

```bash
sudo apt install postgresql-client                                  # 최초 1회. RHEL/Rocky: sudo dnf install postgresql
git clone https://github.com/ichibahn/pg_monitor.git ~/pg_monitor
bash ~/pg_monitor/monitor
```

프롬프트에 host/port/database/user/password만 입력하면 위 메뉴가 바로 뜹니다. 세팅은 이게 전부입니다.

## 1. 요구사항

| 구성요소 | 요구사항 |
|---|---|
| 클라이언트 OS | Linux / macOS (bash 3.2+) |
| 클라이언트 도구 | `psql` 10 이상 |
| 서버 | PostgreSQL 13+ (vanilla, RDS, Aurora) |

`psql` 클라이언트가 없다면 먼저 설치합니다:

```bash
# Ubuntu / Debian
sudo apt install postgresql-client

# RHEL / Rocky / Alma
sudo dnf install postgresql

# macOS (Homebrew)
brew install libpq && brew link --force libpq
```

`psql`이 없으면 `monitor` 실행 시 접속 에러 대신 위 설치 안내를 출력하고 종료합니다.

## 2. 설치 (압축해제)

사용하는 OS 계정의 `$HOME` 경로에 풀면 별도 설정이 필요 없습니다:

```bash
git clone https://github.com/ichibahn/pg_monitor.git ~/pg_monitor
# 또는: tar -xvf pg_monitor_YYYYMMDD.tar -C ~

bash ~/pg_monitor/monitor
```

다른 경로에 설치할 경우 — 스크립트를 수정하지 말고 `PG_MONITOR_PATH` 환경변수를 사용하세요:

```bash
PG_MONITOR_PATH=/opt/pg_monitor bash /opt/pg_monitor/monitor
```

## 3. 환경설정 (선택)

OS 계정 `.profile`(또는 `.bashrc`)에 alias를 추가해 두면 편합니다:

```bash
#--------------------
# pg_monitor settings
#--------------------
alias pm='PG_MONITOR_PATH=$HOME/pg_monitor bash $HOME/pg_monitor/monitor'
```

## 4. 실행방법

1) alias 등록했다면 `pm`, 아니면 `bash ~/pg_monitor/monitor` 실행
2) DB 접속환경에 맞춰 접속정보 입력:

```
================================
 PostgreSQL Monitor Ver1.1.0
================================
==================================================
 (Disclaimer)
 These scripts come without warranty of any kind.
 Use them at your own risk.
==================================================

Enter PostgreSQL Host (default: localhost): mydb.xxxx.us-east-1.rds.amazonaws.com
Enter PostgreSQL Port (default: 5432):
Enter PostgreSQL Database (default: postgres):
Enter PostgreSQL User (default: postgres):
Enter PostgreSQL Password:
PostgreSQL Major Version: 17 (RDS)
```

3) 원하는 번호 입력 후 엔터 → 항목별 내용 확인, 엔터로 메뉴 복귀. `S`는 리포트 저장(`log/`), `X`/`Q`는 종료.

읽기 항목 전체는 `pg_monitor` 롤(PG10+)이면 조회 가능하고, 8번대 조치 항목은
`pg_signal_backend` 롤 또는 테이블 owner 권한이 필요합니다.

## 5. 각 항목 설명

### 1. GENERAL
- 11) Cluster/Instance Info : 접속한 PostgreSQL 정보 (버전/가동시간/인코딩/TZ/Primary·Standby 역할/최대 XID age)
- 12) Modified Parameter : 기본값 대비 변경된 파라미터 (pending_restart 포함)
- 13) Database Info : 각 Database 별 정보
- 14) User Privilege (Database) : 유저에 대한 database 권한
- 15) User Privilege (Schema) : 유저에 대한 schema 권한 (현재 접속 DB 기준)

### 2. PERFORMANCE METRICS
- 21) Buffer Cache Hit Ratio : Buffer Cache Hit율 (pg_stat_database 기반 — 익스텐션 불필요)
- 22) TOP 30 Queries : 누적시간 상위 30개 쿼리 (pg_stat_statements 익스텐션 必, 미설치 시 설치 안내 출력)
- 23) Transaction Stat By Database : 각 Database 별 stat (+ temp 파일, deadlock)
- 24) Unused Indexes : 미사용 인덱스 (stats reset 이후 기준)
- 25) HOT Update Ratio : 전체 업데이트 대비 HOT update 비율 + fillfactor 제안
- 26) Index Bloat Estimate : B-tree 인덱스 bloat 추정 (pgstattuple 불필요)
- 27) Duplicate Indexes : 정의가 동일한 중복 인덱스
- 28) Foreign Keys Without Index : 인덱스 없는 FK (락/삭제 성능 사고 예방)
- 29) I/O Statistics : pg_stat_io 요약 (PG16+, 미만 버전은 안내)

### 3. SESSION / QUERY ACTIVITY
- 31) Active Sessions : 활성 세션 조회
- 32) Long Running Queries/Transactions : 5분 초과 쿼리 + 15분 초과 열린 트랜잭션 (vacuum 지연 원인 탐지)
- 33) Blocking Sessions : Blocking & Blocked 세션 조회
- 34) Wait Event (Type) : wait event 별 그룹핑 + 샘플 쿼리
- 35) Idle (in Transaction) Sessions : idle / idle in transaction 세션 조회
- 36) Lock Wait Tree : pg_blocking_pids 기반 락 대기 트리 (루트 blocker 우선)
- 37) Prepared Transactions (2PC) : 잔존 2PC 트랜잭션 (락/vacuum 홀드 탐지)
- 38) Parallel Query Workers : PG 네이티브 병렬쿼리 실행 현황 (Aurora "Parallel Query"는 MySQL 전용)

### 4. SEGMENT & OBJECT INFO
- 41) Table Size/Rows : 테이블 별 size, rows 상위 50개
- 42) Index Size/Rows : 인덱스 별 size, rows 상위 50개
- 43) Tablespace Size : tablespace 사용 용량 및 경로
- 44) Table Detail Info : 특정 테이블의 상세 정보 (값 입력형; 파티션 루트는 자식 합산 크기 표시)
- 45) Partition Table Info : 파티션 테이블 hierarchy (파티션별 크기 포함)
- 46) Table Padding Info : 컬럼 순서에 따른 Padding 정보와 컬럼 순서 권고 (값 입력형)
- 47) Table Bloat Estimate : 테이블 bloat 추정 (pgstattuple 불필요)
- 48) TOAST Size Info : 테이블별 TOAST 크기 상세

### 5. WAL & ARCHIVE
- 51) Wal Status : wal 파일 상태/생성 지연 (Aurora는 안내 메시지)
- 52) Archive Status : archive 상태/정보
- 53) Wal / Archive Setting : wal, archive 관련 파라미터
- 54) Checkpoint Statistics : 체크포인트 통계 (PG17+ pg_stat_checkpointer / 이하 pg_stat_bgwriter 자동 분기)
- 55) WAL Generation Stat : WAL 생성량 (PG14+ pg_stat_wal; Aurora는 안내 메시지)

### 6. VACUUM
- 61) Vacuuming Sessions : vacuum 수행중인 세션
- 62) DeadTuple Ratio : dead tuple 상위 50개 테이블
- 63) Vacuum Eligible Tables : 현재 설정 기준 vacuum 대상 테이블 (테이블별 reloption 반영)
- 64) Vacuum Phase Info : vacuum 진행률
- 65) Vacuum Freeze Warning : relfrozenxid age 경보 (eager mode 대상)
- 66) Vacuum Setting (Database) : database 별 vacuum 세팅
- 67) Vacuum Setting (Parameter) : vacuum 파라미터
- 68) Tables Not Vacuumed Recently : 7일+ (auto)vacuum/analyze 미수행 테이블

### 7. REPLICATION
- 71) Replication Status (Primary) : 복제 상태 — **Aurora 접속 시 aurora_replica_status()로 자동 전환**
- 72) Replication Status (Standby) : standby 수신 상태 — **Aurora 접속 시 자동 전환 + 접속 인스턴스 식별**
- 73) Replication Slot Status : replication slot 상태 (physical slot NULL 안전 처리)
- 74) Logical Replication Status : publication / subscription / worker 상태

### 8. URGENT ACTION (주의!)
- 81) Session KILL : 세션 종료 (pid 입력형)
- 82) Disable Autovacuum : 테이블 단위 autovacuum off (standby에서는 안내)
- 83) Query Cancel : 쿼리만 취소, 세션 유지 — 81보다 안전한 선행 수단 (pid 입력형)
- 84) Kill Idle-in-Transaction Sessions : N분 초과 idle-in-tx 일괄 종료 (대상 미리보기 → 확인 후 실행)

### 9. CLOUD (RDS/AURORA 전용)
- 91) Cloud Env Info : 엔진 감지, aurora_version, 접속 인스턴스(writer/reader), rds.* 파라미터, rds_superuser 여부
- 92) Aurora Global DB Status : 리전 간 durability/RPO lag
- 93) Aurora Memory Usage : 백엔드별 메모리 컨텍스트 (OOM 트러블슈팅)
- 94) DB Log Files (log_fdw) : SQL로 DB 로그 파일 조회 — log_fdw 미설치 시 설치 안내 (**익스텐션은 DB별 설치**)

vanilla PostgreSQL에서 9번대를 실행하면 "클라우드 전용" 안내와 대체 메뉴를 알려줍니다 (raw 에러 없음).

## 6. 환경별 동작

| | vanilla | RDS | RDS replica | Aurora writer | Aurora reader |
|---|---|---|---|---|---|
| 57개 전 항목 정상 동작 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Aurora 자동 분기 (71/72) | 해당없음 | 해당없음 | 해당없음 | ✅ | ✅ |
| WAL 파일 항목 (51/55) | ✅ | ✅ | ✅ | 안내 | 안내 |
| 클라우드 항목 (91~94) | 안내 | ✅ | ✅ | ✅ | ✅ |

"안내" = 해당 환경에서 왜 적용이 안 되는지 + 대신 볼 메뉴를 출력합니다.

## 7. 트러블슈팅

- **psql not found** : 클라이언트 미설치 — 요구사항의 배포판별 명령으로 설치 (스크립트도 동일 안내 출력)
- **SQL scripts not found at ...** : 패키지가 `$HOME/pg_monitor`에 없음 — `PG_MONITOR_PATH` 지정
- **could not connect** : host/port/계정/패스워드, `pg_hba.conf`, RDS/Aurora는 보안그룹 인바운드(클라이언트 IP) 확인
- **22번에서 pg_stat_statements 미설치 안내** : `shared_preload_libraries` 등록(RDS/Aurora는 파라미터 그룹) 후 `CREATE EXTENSION pg_stat_statements;`
- **세션 뷰가 일부만 보임** : 접속 유저에 `pg_monitor` 롤 부여

## Disclaimer

These scripts come without warranty of any kind. Use them at your own risk.

## License

MIT
