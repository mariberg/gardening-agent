# DynamoDB Data Model

## Design Philosophy & Approach

This design uses a **single-table approach** for all core garden entities (gardens, members, plants, action logs, photos, AI analyses) unified under `garden_id` as the partition key. Two entities are kept as separate tables due to fundamentally different operational characteristics.

**Key principles:**
1. **Single table for the garden aggregate**: All user-facing data that belongs to a garden lives in one table. This enables efficient queries across related entities and reduces the number of tables to manage.
2. **SK taxonomy for entity separation**: Sort key prefixes distinguish entity types while enabling flexible query patterns via `begins_with`.
3. **Separate tables only when operationally necessary**: WateringSchedule and CareInstructions are kept separate for specific technical reasons documented below.

## Why WateringSchedule Is a Separate Table

The WateringSchedule table is kept separate from the main garden table for these reasons:

1. **TTL requirement**: Watering tasks auto-expire after their scheduled date using DynamoDB TTL. If these items lived in the main table, TTL would be enabled table-wide. A bug or misconfiguration setting a TTL attribute on a plant or photo item would silently delete permanent data. Isolating TTL to a dedicated table eliminates this risk entirely.

2. **Burst write pattern**: The nightly EventBridge job writes ~30 items per garden in a short burst. In the main table, these writes would compete with user-facing reads on the same `garden_id` partition. A separate table provides isolated throughput for the batch job.

3. **Transient vs permanent data**: Watering tasks are ephemeral (generated nightly, expire daily). All other garden data is permanent. Mixing transient and permanent data in one table complicates backup/restore — restoring the main table shouldn't bring back expired watering tasks, and restoring watering tasks shouldn't roll back user edits.

## Why CareInstructions Is a Separate Table

1. **Different partition key domain**: CareInstructions are keyed by `species_id`, not `garden_id`. They're reference data shared across all gardens — not owned by any single garden. Forcing them into the garden table would require duplicating instructions into every garden that grows that species, or using a completely different PK pattern that breaks the single-table model.

2. **Independent lifecycle**: Care instructions are authored/updated by admins or AI, independently of any user activity. They have different access control, update frequency, and scaling characteristics from user-generated garden data.

3. **Clean separation of reference vs user data**: Species definitions (existing `garden_plants-dev` table) and care instructions are a shared catalog. Garden data is user-owned. These are different bounded contexts that shouldn't be operationally coupled.

## Table Designs

### GardenData Table (Single Table)

This table stores all core entities for a garden: garden metadata, members, plant instances, action logs, photos, and AI analyses.

| garden_id | sort_key | entity_type | data |
|-----------|----------|-------------|------|
| garden_001 | GARDEN | garden | `{garden_name: "Rose Garden", owner_user_id: "user_001", created_at: "2026-01-15T10:00:00Z"}` |
| garden_001 | MEMBER#user_001 | member | `{user_id: "user_001", role: "owner", joined_at: "2026-01-15T10:00:00Z", email: "alice@example.com", display_name: "Alice"}` |
| garden_001 | MEMBER#user_002 | member | `{user_id: "user_002", role: "member", joined_at: "2026-02-01T09:00:00Z", email: "bob@example.com", display_name: "Bob"}` |
| garden_001 | PLANT#plant_inst_001 | plant | `{species_id: "plant#rose", nickname: "My Red Rose", status: "active", planted_at: "2026-02-15", watering_frequency_days: 3, last_watered_at: "2026-05-14T08:00:00Z", notes: "East-facing bed"}` |
| garden_001 | PLANT#plant_inst_002 | plant | `{species_id: "plant#grapevine", nickname: "Backyard Vine", status: "active", planted_at: "2025-06-01", watering_frequency_days: 7, last_watered_at: "2026-05-10T08:00:00Z", notes: "Needs trellis repair"}` |
| garden_001 | LOG#plant_inst_001#2026-05-14T08:00:00Z#log_001 | log | `{instance_id: "plant_inst_001", action_type: "watering", notes: "Gave 500ml", logged_by: "user_001"}` |
| garden_001 | LOG#plant_inst_001#2026-05-12T10:00:00Z#log_002 | log | `{instance_id: "plant_inst_001", action_type: "issue", notes: "Aphids spotted", logged_by: "user_002", resolved: false}` |
| garden_001 | LOG#plant_inst_002#2026-05-13T07:30:00Z#log_004 | log | `{instance_id: "plant_inst_002", action_type: "pruning", notes: "Trimmed dead branches", logged_by: "user_001"}` |
| garden_001 | PHOTO#plant_inst_001#2026-05-14T08:00:00Z#photo_001 | photo | `{instance_id: "plant_inst_001", photo_id: "photo_001", taken_at: "2026-05-14T08:00:00Z", url: "s3://bucket/photo_001.jpg", caption: "Morning bloom"}` |
| garden_001 | ANALYSIS#photo_001 | analysis | `{photo_id: "photo_001", instance_id: "plant_inst_001", analysis_result: "Healthy growth, no disease detected", analyzed_at: "2026-05-14T08:05:00Z"}` |

- **Purpose**: Single table storing all garden-scoped entities. Enables efficient access to related data within a garden using sort key prefixes.
- **Partition Key**: `garden_id` (String) — All data for a garden shares one partition. At prototype scale (~2 gardens), this is fine. At scale with hundreds of gardens, each garden's data is isolated in its own partition.
- **Sort Key**: `sort_key` (String) — Entity type prefix + identifiers for hierarchical querying.
- **SK Taxonomy**:
  - `GARDEN` — Garden metadata (one item per garden)
  - `MEMBER#<userId>` — Garden members
  - `PLANT#<instanceId>` — Plant instances
  - `LOG#<instanceId>#<occurredAt>#<actionId>` — Action logs (sorted by plant, then time)
  - `PHOTO#<instanceId>#<takenAt>#<photoId>` — Photos (sorted by plant, then time)
  - `ANALYSIS#<photoId>` — AI analysis results
- **Attributes**:
  - `garden_id` (String): Partition key
  - `sort_key` (String): Composite sort key with entity prefix
  - `entity_type` (String): Discriminator for application code (`garden`, `member`, `plant`, `log`, `photo`, `analysis`)
  - `instance_id` (String): Plant instance ID (on logs, photos, analyses)
  - `photo_id` (String): Photo ID (on photos and analyses)
  - `species_id` (String): Species reference (on plants)
  - `nickname` (String): Plant display name (on plants)
  - `status` (String): `active` or `removed` (on plants)
  - `action_type` (String): Log type (on logs)
  - `notes` (String): Free text (on logs, plants)
  - `logged_by` (String): User who created log (on logs)
  - `resolved` (Boolean): Issue resolution status (on issue logs)
  - `url` (String): S3 URL (on photos)
  - `caption` (String): Photo caption (on photos)
  - `analysis_result` (String): AI analysis text (on analyses)
  - Plus other entity-specific attributes as shown in sample data above
- **Bounded Read Strategy**:
  - Garden metadata: GetItem(PK=gardenId, SK="GARDEN")
  - All members: Query(PK=gardenId, SK begins_with "MEMBER#")
  - All plants: Query(PK=gardenId, SK begins_with "PLANT#")
  - Logs for a plant: Query(PK=gardenId, SK begins_with "LOG#instanceId#")
  - Photos for a plant: Query(PK=gardenId, SK begins_with "PHOTO#instanceId#")
  - Specific analysis: GetItem(PK=gardenId, SK="ANALYSIS#photoId")
  - Garden + members + plants (dashboard): Query(PK=gardenId, SK between "GARDEN" and "PLANT#\xff")
- **Access Patterns Served**: #1-6, #8, #11-13, #16-20, #22-24, #27-28
- **Capacity Planning**: ~5 RPS reads, ~2 RPS writes total across all patterns. On-demand mode.

#### Unresolved Issues — Application-Level Query (GSI DEFERRED)

> **How it works without a GSI:** To get unresolved issues for a garden, the application queries `Query(PK=gardenId, SK begins_with "LOG#")` and filters with `FilterExpression: action_type = :issue AND resolved = :false`. At prototype scale with ~30 plants and a few logs each, this scans a manageable number of items.
>
> **Why a GSI would help at scale:** With thousands of logs per garden, scanning all logs to find the few unresolved issues becomes expensive (you pay for all items read, even filtered ones). A sparse GSI with `unresolved_garden_id` as PK would index only unresolved items.
>
> **When to add:** When logs per garden exceed ~500 items and the FilterExpression is discarding >90% of items read.

### UserProfiles Table

| user_id | garden_id | display_name | email | latitude | longitude | created_at |
|---------|-----------|--------------|-------|----------|-----------|------------|
| user_001 | garden_001 | Alice | alice@example.com | 41.8967 | 12.4822 | 2026-01-15T10:00:00Z |
| user_002 | garden_001 | Bob | bob@example.com | 41.8967 | 12.4822 | 2026-02-01T09:00:00Z |
| user_003 | garden_002 | Carol | carol@example.com | 51.5074 | -0.1278 | 2026-03-01T12:00:00Z |

- **Purpose**: Stores user profile data and provides the user→garden lookup needed for auth flow. Kept separate from the garden table because users are looked up by `user_id`, not `garden_id`.
- **Partition Key**: `user_id` (String) — Direct lookup by authenticated user ID.
- **Sort Key**: None — Single item per user.
- **Attributes**:
  - `user_id` (String): Unique user identifier (from Cognito)
  - `garden_id` (String): The garden this user belongs to
  - `display_name` (String): User's display name
  - `email` (String): User's email
  - `latitude` (String): Location latitude
  - `longitude` (String): Location longitude
  - `created_at` (String, ISO 8601): Account creation timestamp
- **Access Patterns Served**: #14 (get user profile), #21 (lookup user's garden)
- **Capacity Planning**: ~0.3 RPS reads, ~0.1 RPS writes. On-demand mode.

### WateringSchedule Table (Separate — see justification above)

| garden_id | scheduled_date#instance_id | instance_id | plant_nickname | watering_notes | completed | completed_by | completed_at | ttl |
|-----------|---------------------------|-------------|----------------|----------------|-----------|--------------|--------------|-----|
| garden_001 | 2026-05-16#plant_inst_001 | plant_inst_001 | My Red Rose | Normal watering | false | | | 1747526400 |
| garden_001 | 2026-05-16#plant_inst_002 | plant_inst_002 | Backyard Vine | Light watering, rain expected | false | | | 1747526400 |
| garden_002 | 2026-05-16#plant_inst_004 | plant_inst_004 | Mojito Mint | Extra water, hot day | false | | | 1747526400 |

- **Purpose**: Stores daily watering tasks generated by the nightly EventBridge job. TTL auto-expires old entries.
- **Partition Key**: `garden_id` (String) — Query all watering tasks for a garden.
- **Sort Key**: `scheduled_date#instance_id` (String) — Enables "today's tasks" via `begins_with` on today's date.
- **SK Taxonomy**: `<YYYY-MM-DD>#<instanceId>`
- **Attributes**:
  - `garden_id` (String): Garden these tasks belong to
  - `scheduled_date#instance_id` (String): Composite sort key
  - `instance_id` (String): Plant instance needing water
  - `plant_nickname` (String): Denormalized for display (avoids join to main table)
  - `watering_notes` (String): Weather-aware instructions from nightly job
  - `completed` (Boolean): Whether task was completed
  - `completed_by` (String): userId who marked it done
  - `completed_at` (String, ISO 8601): When it was completed
  - `ttl` (Number): Unix epoch timestamp, set to end of scheduled_date + 1 day
- **Bounded Read Strategy**: Query PK=gardenId, SK begins_with today's date. Returns ~30 items max.
- **Access Patterns Served**: #7 (today's watering), #25 (nightly write), #26 (mark completed)
- **Capacity Planning**: ~0.1 RPS reads, ~1 RPS burst writes (nightly job). On-demand mode.

### CareInstructions Table (Separate — see justification above)

| species_id | instruction_id | title | content | source_type | created_at |
|------------|---------------|-------|---------|-------------|------------|
| plant#rose | instr_001 | Spring Pruning Guide | Prune in early spring before new growth... | expert | 2026-01-01T00:00:00Z |
| plant#rose | instr_002 | Winter Protection | Apply mulch around base in late autumn... | ai_generated | 2026-02-01T00:00:00Z |
| plant#grapevine | instr_003 | Trellis Training | Train new shoots along horizontal wires... | expert | 2026-01-15T00:00:00Z |

- **Purpose**: Stores care instruction guides per species. Reference data shared across all gardens.
- **Partition Key**: `species_id` (String) — Instructions belong to a species, not a garden.
- **Sort Key**: `instruction_id` (String) — Unique instruction identifier.
- **Attributes**:
  - `species_id` (String): Species this instruction applies to
  - `instruction_id` (String): Unique instruction ID
  - `title` (String): Instruction title
  - `content` (String): Full instruction text
  - `source_type` (String): `expert` or `ai_generated`
  - `created_at` (String, ISO 8601): When instruction was created
- **Bounded Read Strategy**: Query PK=speciesId returns all instructions for a species (~5-10).
- **Access Patterns Served**: #9 (care instructions for plant instance, via species lookup), #10 (care instructions by species)
- **Capacity Planning**: ~0.1 RPS reads, rare writes. On-demand mode.

### Species Table (Existing — garden_plants-dev)

| plant_id | common_name | scientific_name | plant_type | min_temp_c | max_temp_c | watering_frequency_days | sunlight_requirement |
|----------|-------------|-----------------|------------|------------|------------|------------------------|---------------------|
| plant#rose | Rose | Rosa spp. | shrub | -15 | 35 | 3 | full sun |
| plant#grapevine | Grapevine | Vitis vinifera | vine | -10 | 40 | 7 | full sun |
| plant#basil | Basil | Ocimum basilicum | herb | 10 | 35 | 2 | full sun |
| plant#mint | Mint | Mentha | herb | -20 | 35 | 2 | partial shade |

- **Purpose**: Existing reference catalog of plant species. Used by AI agent and nightly watering job.
- **Partition Key**: `plant_id` (String)
- **Sort Key**: None
- **Access Patterns Served**: Species lookup for AI advice, nightly watering job, care instruction resolution.
- **Capacity Planning**: ~0.1 RPS reads. Keep as-is.

## Access Pattern Mapping

| Pattern # | Description | Type | Peak RPS | Items Returned | Avg Item Size | Table Used | DynamoDB Operations | Implementation Notes |
|-----------|-------------|------|----------|----------------|---------------|------------|---------------------|----------------------|
| 1 | List all plants for garden (active) | Query | 0.1 | 30 | 500 B | GardenData | Query(PK=gardenId, SK begins_with "PLANT#"), filter status!=removed | |
| 2 | Get single plant | GetItem | 0.1 | 1 | 500 B | GardenData | GetItem(PK=gardenId, SK="PLANT#instanceId") | Frontend has gardenId from auth |
| 3 | Dashboard summary | Query | 0.1 | 40 | 500 B | GardenData | Query(PK=gardenId, SK between "GARDEN" and "PLANT#\xff") | Gets garden + members + plants in one query |
| 4 | Get paginated logs for plant | Query | 0.1 | 20 | 300 B | GardenData | Query(PK=gardenId, SK begins_with "LOG#instanceId#"), ScanIndexForward=false, Limit=20 | |
| 5 | Get recent logs (limit=5) | Query | 0.1 | 5 | 300 B | GardenData | Query(PK=gardenId, SK begins_with "LOG#instanceId#"), ScanIndexForward=false, Limit=5 | |
| 6 | Unresolved issues for garden | Query | 0.1 | 50 | 300 B | GardenData | Query(PK=gardenId, SK begins_with "LOG#"), filter action_type=issue AND resolved=false | Scans all logs, filters in DynamoDB |
| 7 | Today's watering for garden | Query | 0.1 | 30 | 400 B | WateringSchedule | Query(PK=gardenId, SK begins_with "2026-05-16") | |
| 8 | Create action log | PutItem | 0.1 | - | 300 B | GardenData | PutItem(PK=gardenId, SK="LOG#instanceId#occurredAt#actionId") | |
| 9 | Care instructions for plant instance | Query | 0.1 | 5 | 1000 B | CareInstructions | Query(PK=speciesId) | Resolve speciesId from plant first |
| 10 | Care instructions by species | Query | 0.1 | 5 | 1000 B | CareInstructions | Query(PK=speciesId) | |
| 11 | List photos for plant | Query | 0.1 | 10 | 500 B | GardenData | Query(PK=gardenId, SK begins_with "PHOTO#instanceId#"), ScanIndexForward=false | |
| 12 | Get single photo | GetItem | 0.1 | 1 | 500 B | GardenData | GetItem(PK=gardenId, SK="PHOTO#instanceId#takenAt#photoId") | Frontend has context |
| 13 | Get AI analysis for photo | GetItem | 0.1 | 1 | 2000 B | GardenData | GetItem(PK=gardenId, SK="ANALYSIS#photoId") | |
| 14 | Get user profile | GetItem | 0.1 | 1 | 300 B | UserProfiles | GetItem(PK=userId) | |
| 15 | Garden statistics | Query | 0.1 | 100 | 400 B | GardenData | Query(PK=gardenId), count by entity_type in app | Single query gets everything |
| 16 | Create garden | PutItem | 0.01 | - | 500 B | GardenData | PutItem(SK="GARDEN") + PutItem(SK="MEMBER#userId") | Transaction for both |
| 17 | Get garden + members | Query | 0.1 | 5 | 400 B | GardenData | Query(PK=gardenId, SK between "GARDEN" and "MEMBER#\xff") | |
| 18 | Invite user to garden | PutItem | 0.01 | - | 300 B | GardenData | PutItem(PK=gardenId, SK="MEMBER#userId") | |
| 19 | Join garden | UpdateItem | 0.01 | - | 300 B | GardenData + UserProfiles | Update member + set gardenId on profile | Transaction |
| 20 | Remove member | DeleteItem | 0.01 | - | 300 B | GardenData | DeleteItem(PK=gardenId, SK="MEMBER#userId") | |
| 21 | Lookup user's garden | GetItem | 0.2 | 1 | 300 B | UserProfiles | GetItem(PK=userId) → gardenId | Auth flow |
| 22 | Create plant instance | PutItem | 0.05 | - | 500 B | GardenData | PutItem(PK=gardenId, SK="PLANT#instanceId") | |
| 23 | Upload photo metadata | PutItem | 0.02 | - | 500 B | GardenData | PutItem(PK=gardenId, SK="PHOTO#instanceId#takenAt#photoId") | |
| 24 | Create AI analysis | PutItem | 0.02 | - | 2000 B | GardenData | PutItem(PK=gardenId, SK="ANALYSIS#photoId") | |
| 25 | Nightly write watering schedule | PutItem | 1 | - | 400 B | WateringSchedule | BatchWriteItem | Burst during nightly job |
| 26 | Mark watering completed | UpdateItem | 0.1 | - | 400 B | WateringSchedule | UpdateItem(completed=true) | |
| 27 | Resolve issue | UpdateItem | 0.05 | - | 300 B | GardenData | UpdateItem(resolved=true) on LOG item | |
| 28 | Remove plant (soft delete) | UpdateItem | 0.01 | - | 500 B | GardenData | UpdateItem(status="removed") on PLANT item | |

## Hot Partition Analysis

- **GardenData**: All data for a garden lives in one partition. With ~30 plants, ~100 logs, ~50 photos per garden, total item collection size is ~50-100KB — well within DynamoDB's partition limits. At 5 users / 2 gardens, RPS per partition is negligible. ✅
- **WateringSchedule**: Nightly burst of ~1 RPS per garden during batch job. ✅
- **No hot partition risks** at this scale.
- **Future consideration**: If a single garden grows to thousands of logs/photos, the `begins_with "LOG#"` query for unresolved issues (pattern #6) will read many items. At that point, add a sparse GSI.

## Trade-offs and Optimizations

- **Single table for garden aggregate**: All garden data in one table enables powerful query patterns (dashboard in one query) and reduces table management overhead. Trade-off: DynamoDB Streams will contain mixed entity types requiring filtering in consumers.
- **SK hierarchy enables efficient queries**: `LOG#instanceId#timestamp` allows querying logs per plant with `begins_with`, and all logs with a broader prefix. Same for photos.
- **No GSIs at prototype scale**: All access patterns solved via PK + SK prefix queries. Saves ~$0.43/month in write amplification costs. Trade-off: unresolved issues query scans all logs (acceptable at <500 logs per garden).
- **Denormalization in WateringSchedule**: `plant_nickname` avoids a cross-table lookup for display.
- **TTL isolation**: Keeping WateringSchedule separate prevents accidental TTL deletion of permanent garden data.
- **UserProfiles as separate table**: Different PK domain (userId vs gardenId). Cannot be efficiently queried from the garden table without a GSI.

## Validation Results 🔴

- [x] Reasoned step-by-step through design decisions ✅
- [x] Aggregate boundaries clearly defined based on access pattern analysis ✅
- [x] Every access pattern solved or alternative provided ✅
- [x] Unnecessary GSIs removed — zero GSIs in prototype ✅
- [x] Base table keys use single attributes or composite strings ✅
- [x] All tables documented with full justification ✅
- [x] Hot partition analysis completed ✅
- [x] Trade-offs explicitly documented and justified ✅
- [x] No Scans used to solve access patterns ✅
- [x] Cross-referenced against `dynamodb_requirement.md` for accuracy ✅
- [ ] Capacity and cost analysis completed using `compute_performances_and_costs` tool


## Cost Report

> **Disclaimer:** This estimate covers **read/write request costs** and **storage costs** only,
> based on DynamoDB Standard table class on-demand pricing for the **US East (N. Virginia) /
> us-east-1** region. Prices were last verified in **January 2026**. Additional features such as
> Point-in-Time Recovery (PITR), backups, streams, and data transfer may incur additional costs.
> Actual costs may also vary based on your AWS region, pricing model (on-demand vs. provisioned),
> reserved capacity, and real-world traffic patterns. This report assumes constant RPS and average
> item sizes. For the most current pricing, refer to the
> [Amazon DynamoDB Pricing](https://aws.amazon.com/dynamodb/pricing/) page.

**Total Monthly Cost: $2.78**

| Source                  | Monthly Cost |
| ----------------------- | ------------ |
| Storage                 | $0.00        |
| Read and write requests | $2.78        |

### Storage Costs

**Monthly Cost:** $0.00

| Resource         | Type  | Storage (GB) | Monthly Cost |
| ---------------- | ----- | ------------ | ------------ |
| GardenData       | Table | 0.00         | $0.00        |
| UserProfiles     | Table | 0.00         | $0.00        |
| WateringSchedule | Table | 0.00         | $0.00        |
| CareInstructions | Table | 0.00         | $0.00        |

### Read and Write Request Costs

**Monthly Cost:** $2.78

| Resource         | Type  | Monthly Cost |
| ---------------- | ----- | ------------ |
| GardenData       | Table | $0.84        |
| UserProfiles     | Table | $0.05        |
| WateringSchedule | Table | $1.86        |
| CareInstructions | Table | $0.03        |

#### GardenData Table

**Monthly Cost:** $0.84

| Pattern            | Operation  | RPS  | RRU / WRU | Monthly Cost |
| ------------------ | ---------- | ---- | --------- | ------------ |
| list-plants        | Query      | 0.1  | 2.00      | $0.07        |
| get-plant          | GetItem    | 0.1  | 0.50      | $0.02        |
| dashboard          | Query      | 0.1  | 2.50      | $0.08        |
| paginated-logs     | Query      | 0.1  | 1.00      | $0.03        |
| recent-logs        | Query      | 0.1  | 0.50      | $0.02        |
| unresolved-issues  | Query      | 0.1  | 2.00      | $0.07        |
| create-log         | PutItem    | 0.1  | 1.00      | $0.16        |
| list-photos        | Query      | 0.1  | 1.00      | $0.03        |
| get-photo          | GetItem    | 0.1  | 0.50      | $0.02        |
| get-analysis       | GetItem    | 0.1  | 0.50      | $0.02        |
| get-garden-members | Query      | 0.1  | 0.50      | $0.02        |
| create-garden      | PutItem    | 0.01 | 1.00      | $0.02        |
| invite-member      | PutItem    | 0.01 | 1.00      | $0.02        |
| create-plant       | PutItem    | 0.05 | 1.00      | $0.08        |
| upload-photo       | PutItem    | 0.02 | 1.00      | $0.03        |
| create-analysis    | PutItem    | 0.02 | 2.00      | $0.07        |
| resolve-issue      | UpdateItem | 0.05 | 1.00      | $0.08        |
| soft-delete-plant  | UpdateItem | 0.01 | 1.00      | $0.02        |

#### UserProfiles Table

**Monthly Cost:** $0.05

| Pattern            | Operation | RPS | RRU / WRU | Monthly Cost |
| ------------------ | --------- | --- | --------- | ------------ |
| get-user-profile   | GetItem   | 0.1 | 0.50      | $0.02        |
| lookup-user-garden | GetItem   | 0.2 | 0.50      | $0.03        |

#### WateringSchedule Table

**Monthly Cost:** $1.86

| Pattern                 | Operation  | RPS | RRU / WRU | Monthly Cost |
| ----------------------- | ---------- | --- | --------- | ------------ |
| todays-watering         | Query      | 0.1 | 1.50      | $0.05        |
| write-watering-schedule | PutItem    | 1.0 | 1.00      | $1.65        |
| mark-watering-done      | UpdateItem | 0.1 | 1.00      | $0.16        |

#### CareInstructions Table

**Monthly Cost:** $0.03

| Pattern           | Operation | RPS | RRU / WRU | Monthly Cost |
| ----------------- | --------- | --- | --------- | ------------ |
| care-instructions | Query     | 0.1 | 1.00      | $0.03        |

<!-- end-cost-report -->