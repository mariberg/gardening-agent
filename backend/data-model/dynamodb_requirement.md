# DynamoDB Modeling Session

## Application Overview
- **Domain**: Gardening / Plant Care SaaS with family sharing
- **Key Entities**: User, Garden, GardenMember, PlantInstance, ActionLog, Photo, AIAnalysis, CareInstructions, Species (existing reference table)
- **Business Context**: AI-powered gardening assistant that provides personalized plant care advice. Multiple users (family) can share a garden. Data is partitioned by gardenId for shared access.
- **Scale**: 
  - Users: Hundreds initially (~200-500)
  - Gardens: ~100-300 (some users share gardens)
  - Plants per garden: ~30 avg
  - Action logs: Multiple per plant per week (~3-5/plant/week)
  - Total plants: ~3,000-9,000
  - Total logs/week: ~9,000-45,000
  - Peak RPS estimate: Low traffic (~1-10 RPS across all patterns). On-demand mode appropriate.

## Entity Relationships
- **User → Garden**: Many-to-One (user belongs to exactly one garden, garden has multiple members)
- **Garden → PlantInstance**: 1:Many (garden has many plant instances)
- **PlantInstance → ActionLog**: 1:Many (each plant has many care action logs)
- **PlantInstance → Photo**: 1:Many (each plant has many photos)
- **Photo → AIAnalysis**: 1:1 (each photo has one AI analysis)
- **Species → CareInstructions**: 1:Many (each species has care guides)
- **Species → PlantInstance**: 1:Many (reference data, each instance is of a species)

## Existing Tables
| Table | Key | Purpose |
|-------|-----|---------|
| `plant_database_users-dev` | `user_id` (String) | Stores lat/lon + list of plant IDs |
| `garden_plants-dev` | `plant_id` (String) | Stores plant species definitions (temp ranges, watering needs, etc.) |

## Access Patterns Analysis
| Pattern # | Description | RPS (Peak/Avg) | Type | Attributes Needed | Key Requirements | Design Considerations | Status |
|-----------|-------------|----------------|------|-------------------|------------------|----------------------|--------|
| 1 | List all plants for a garden (active only) | ~1 RPS | Read | gardenId, instanceId, nickname, speciesId, status, wateringSchedule | Paginated, exclude status=removed | Query by gardenId, filter status != removed | ⏳ |
| 2 | Get single plant instance by instanceId | TBD | Read | instanceId, all plant instance attrs | Direct lookup | Need GSI or key design for direct access | ⏳ |
| 3 | Dashboard summary for garden | TBD | Read | gardenId, plant count, recent logs, unresolved issues | Aggregated view | May need multiple queries | ⏳ |
| 4 | Get paginated logs for a plant instance | TBD | Read | instanceId, occurredAt, actionType, notes, loggedBy | Paginated, sorted by time desc | SK with timestamp | ⏳ |
| 5 | Get recent logs for a plant (limit=5) | TBD | Read | Same as #4 | Limit query, most recent first | Same table as #4, ScanIndexForward=false | ⏳ |
| 6 | Get unresolved issues across garden | ~1 RPS | Read | gardenId, instanceId, actionType=issue, resolved=false | Filter by status | Sparse GSI: only items with unresolved attribute get indexed. Removing attribute on resolve removes from GSI. | ⏳ |
| 7 | Today's watering tasks for garden | ~1 RPS | Read | gardenId, scheduledDate, instanceId, wateringDetails, completed | One item per plant per day | Query by gardenId + today's date, can mark individual plants as done | ⏳ |
| 8 | Create action log entry | TBD | Write | instanceId, gardenId, actionType, notes, loggedBy, occurredAt | Must record who did it | Write to logs table | ⏳ |
| 9 | Get care instructions for a plant instance | TBD | Read | speciesId (from instance), instructions | Lookup via species | Two-step: get instance → get species instructions | ⏳ |
| 10 | Get care instructions by species | TBD | Read | speciesId, instructionId, content, sourceType | Direct species lookup | Query by speciesId | ⏳ |
| 11 | List photos for a plant instance | TBD | Read | instanceId, photoId, takenAt, url, caption | Sorted by date | SK with timestamp | ⏳ |
| 12 | Get single photo by photoId | TBD | Read | photoId, all photo attrs | Direct lookup | Need GSI or key design | ⏳ |
| 13 | Get AI analysis for a photo | TBD | Read | photoId, analysisResult, analyzedAt | 1:1 with photo | Simple PK lookup | ⏳ |
| 14 | Get user profile | TBD | Read | userId, name, email, location, createdAt | Direct lookup | PK on userId | ⏳ |
| 15 | Get garden statistics | TBD | Read | gardenId, plant count, total logs, photos count | Aggregated | May need counter or compute on read | ⏳ |
| 16 | Create garden | TBD | Write | gardenId, gardenName, ownerUserId, createdAt | Generate gardenId | Write to gardens table | ⏳ |
| 17 | Get garden details + members | TBD | Read | gardenId, members list with roles | Joint query | Item collection candidate (garden + members) | ⏳ |
| 18 | Invite user to garden | TBD | Write | gardenId, inviteeEmail/code, invitedBy, status | Invitation flow | Need invitations storage | ⏳ |
| 19 | Join garden (accept invite) | TBD | Write | gardenId, userId, role, joinedAt | Update invitation + create membership | Transaction | ⏳ |
| 20 | Remove member from garden | TBD | Write | gardenId, userId | Delete membership | Conditional on role permissions | ⏳ |
| 21 | Lookup user's garden(s) | TBD | Read | userId → gardenId(s) | Resolve garden for auth | GSI on userId in members | ⏳ |
| 22 | Create plant instance | TBD | Write | gardenId, instanceId, speciesId, nickname, plantedAt | Add plant to garden | Write to PlantInstances | ⏳ |
| 23 | Upload photo metadata | TBD | Write | instanceId, gardenId, photoId, takenAt, url | Record photo | Write to Photos table | ⏳ |
| 24 | Create AI analysis | ~0.1 RPS | Write | photoId, analysisResult, analyzedAt | Store analysis result | Write to AIAnalysis table | ⏳ |
| 25 | Nightly job writes watering schedule | ~5 RPS (burst) | Write | gardenId, scheduledDate, instanceId, wateringDetails | EventBridge → Lambda batch write | One item per plant needing water, TTL after date passes | ⏳ |
| 26 | Mark watering task as completed | ~1 RPS | Write | gardenId, scheduledDate, instanceId, completed=true, completedBy | User marks plant as watered | Update item | ⏳ |
| 27 | Resolve an issue | ~0.5 RPS | Write | instanceId, actionId, remove unresolved attribute | Update original log entry | Removing sparse GSI attribute removes item from unresolved index | ⏳ |
| 28 | Remove a plant instance (soft delete) | ~0.1 RPS | Write | gardenId, instanceId, status=removed | Update status field | Soft delete: set status=removed. Logs/photos retained. List plants filters out removed. | ⏳ |

## Enhanced Aggregate Analysis

### Garden + GardenMembers Item Collection Analysis
- **Access Correlation**: 90%+ of queries need garden details with members together (pattern #17)
- **Query Patterns**:
  - Garden only: 10% (just checking garden exists)
  - Members only: 5% (rare)
  - Both together: 85% (main use case)
- **Size Constraints**: Garden ~1KB + avg 4 members × 0.5KB = ~3KB total, bounded (one garden per user)
- **Update Patterns**: Garden rarely updated, members added/removed infrequently
- **Identifying Relationship**: Members cannot exist without a Garden, always have gardenId
- **Decision**: Item Collection Aggregate
- **Justification**: 85% joint access + identifying relationship + small bounded size

### PlantInstance (standalone per garden)
- **Access Correlation with ActionLogs**: ~30% (dashboard shows recent logs alongside plants)
- **Query Patterns**:
  - Plants only: 70% (list plants, get single plant)
  - Logs only: 50% (paginated logs, unresolved issues)
  - Both together: 30% (dashboard)
- **Size Constraints**: Plant ~2KB, logs unbounded over time
- **Update Patterns**: Plants updated occasionally, logs appended frequently
- **Decision**: Separate Tables
- **Justification**: <50% correlation, unbounded log growth, different update frequencies, independent scaling

### Photo + AIAnalysis
- **Access Correlation**: 40% (sometimes view photo with analysis, sometimes just browsing photos)
- **Query Patterns**:
  - Photo only: 60% (browsing gallery)
  - Analysis only: 10% (rare)
  - Both together: 40%
- **Size Constraints**: Photo metadata ~1KB, Analysis ~2-5KB, bounded 1:1
- **Update Patterns**: Both write-once (immutable after creation)
- **Decision**: Item Collection Aggregate (Photo table with analysis as separate SK)
- **Justification**: 1:1 relationship, both immutable, bounded size, simplifies direct photo lookup

### WateringSchedule (standalone)
- **Access Correlation with other entities**: Low — only read by "today's watering" endpoint
- **Decision**: Separate table or item collection within a garden-scoped table
- **Justification**: Transient data (TTL), generated nightly, independent lifecycle

## Table Consolidation Analysis

### Consolidation Candidates Review
| Parent | Child | Relationship | Access Overlap | Consolidation Decision | Justification |
|--------|-------|--------------|----------------|----------------------|---------------|
| Garden | GardenMembers | 1:Many | 85% | ✅ Consolidate (item collection) | Always accessed together, bounded, identifying relationship |
| Garden | PlantInstances | 1:Many | 30% | ❌ Separate | Low overlap, plants queried independently |
| PlantInstance | ActionLogs | 1:Many | 30% | ❌ Separate | Unbounded growth, different access patterns, independent scaling |
| PlantInstance | Photos | 1:Many | 20% | ❌ Separate | Photos browsed independently, different lifecycle |
| Photo | AIAnalysis | 1:1 | 40% | ✅ Consolidate (item collection) | 1:1, immutable, bounded, simplifies lookup |
| Garden | WateringSchedule | 1:Many | Low | ❌ Separate | Transient TTL data, nightly batch writes |

## Validation Checklist
- [x] Application domain and scale documented
- [x] All entities and relationships mapped
- [x] Aggregate boundaries identified based on access patterns
- [x] Identifying relationships checked for consolidation opportunities
- [x] Table consolidation analysis completed
- [ ] Every access pattern has RPS estimates
- [x] Write pattern exists for every read pattern
- [ ] Hot partition risks evaluated
