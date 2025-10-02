# Async Activities Example - NYC Film Permit Processing

Demonstrates parallel and concurrent activity execution in Temporal workflows using NYC's Open Data API to process film permits.

## Features Demonstrated

### Parallel Activity Execution
- **`async let`**: Run multiple analysis activities concurrently per permit
- **Task Groups**: Process multiple permits in parallel with `withThrowingTaskGroup`
- **Multiple Workers**: Distribute activity execution across 5 worker instances

### External API Integration
- Fetches data from NYC Open Data API
- HTTP requests with timeout and retry policies
- Handles network errors and API failures gracefully
- No external dependencies or submodules required

### Performance Comparison
- Sequential vs parallel processing modes
- Timing metrics showing speedup from parallelization
- Demonstrates Temporal's scalability

## Activities

### `fetchFilmPermits`
Fetches film permits from NYC Open Data API.
- **Input**: Number of permits to fetch
- **Output**: Array of film permit records
- **API**: `https://data.cityofnewyork.us/resource/tg4x-b46p.json`
- **Retry Policy**: 3 attempts with exponential backoff

### `validatePermit`
Validates permit data quality.
- **Input**: Film permit record
- **Output**: Validation result with issues list
- **Checks**: Required fields, date formats, data completeness

### `analyzeLocation`
Analyzes permit location details.
- **Input**: Film permit record
- **Output**: Location analysis (borough, precinct, street count)
- **Processing**: Parses location strings and extracts geographic data

### `categorizePermit`
Categorizes permit by type and commercial status.
- **Input**: Film permit record
- **Output**: Category classification
- **Classification**: Film, TV, Commercial, Still Photography, etc.

### `generateAnalyticsReport`
Generates summary report from all permit analyses.
- **Input**: Array of permit analyses
- **Output**: Analytics report with aggregated statistics
- **Metrics**: Counts by borough, category, validation status

## Workflow Execution Patterns

### Sequential Mode
Processes permits one at a time:
```swift
for permit in permits {
    let analysis = try await processPermit(permit: permit)
    analyses.append(analysis)
}
```

### Parallel Mode
Processes all permits concurrently using task groups:
```swift
try await withThrowingTaskGroup(of: PermitAnalysis.self) { group in
    for permit in permits {
        group.addTask {
            try await self.processPermit(permit: permit)
        }
    }
    // Collect results as they complete
}
```

### Per-Permit Concurrency
Each permit runs multiple analyses in parallel:
```swift
async let validation = Workflow.executeActivity(validatePermit, ...)
async let location = Workflow.executeActivity(analyzeLocation, ...)
async let category = Workflow.executeActivity(categorizePermit, ...)

let (v, l, c) = try await (validation, location, category)
```

## Setup

### Prerequisites
1. Temporal server running locally:
```bash
temporal server start-dev
```

2. Internet connection for API access (no authentication required)

## Running the Example

```bash
swift run AsyncActivitiesExample
```

This runs 5 workers that demonstrate both sequential and parallel activity execution patterns.

### Expected Output

```
🎬 NYC Film Permit Processing - Async Activities Example
======================================================================

🚀 Starting Workers:
  ✅ Worker 1 started (PID: 12345)
  ✅ Worker 2 started (PID: 12345)
  ✅ Worker 3 started (PID: 12345)
  ✅ Worker 4 started (PID: 12345)
  ✅ Worker 5 started (PID: 12345)

======================================================================

📥 Fetching film permits from NYC API...
✅ Fetched 100 permits

======================================================================

⏳ Test 1: Sequential Processing
----------------------------------------------------------------------
🔗 View in Temporal UI:
  http://localhost:8233/namespaces/default/workflows/PERMITS-SEQ-...

✅ Sequential Processing Complete:
  Total permits: 100
  Valid permits: 100
  Total time: 9.17s
  Average per permit: 0.09s

  By Borough:
    • Manhattan: 42 permits
    • Brooklyn: 28 permits
    • Queens: 18 permits
    • Bronx: 8 permits
    • Staten Island: 4 permits

======================================================================

⚡ Test 2: Parallel Processing
----------------------------------------------------------------------
🔗 View in Temporal UI:
  http://localhost:8233/namespaces/default/workflows/PERMITS-PAR-...

📊 Processing 100 permits in parallel...

✅ Parallel Processing Complete:
  Total permits: 100
  Valid permits: 100
  Total time: 0.73s
  Average per permit: 0.01s

  By Category:
    • Television: 38 permits
    • Film: 24 permits
    • WEB: 16 permits
    • Commercial: 12 permits
    • Still Photography: 10 permits

======================================================================

📈 Performance Summary:
----------------------------------------------------------------------
  Sequential: 9.17s for 100 permits
  Parallel:   0.73s for 100 permits

  Speedup: 12.6x
  (Parallel processing is 12.6x faster)

✅ Example completed successfully!
```

## Key Patterns

### Multiple Workers
Worker instances share the same task queue. Temporal automatically distributes activities across available workers for parallel execution.

### Workflow Concurrency
Leverages Swift's async/await and Structured Concurrency within workflows while maintaining Temporal's deterministic execution guarantees. See [Workflow Concurrency](../../Sources/Temporal/Documentation.docc/Workflows/Workflow-Concurrency.md) for details.

### External API Integration
Demonstrates best practices for calling external APIs in activities:
- Timeout configuration (30s for API calls)
- Retry policies with exponential backoff
- Proper error handling and classification
- Heartbeats for long-running operations

### Application
Demonstrates a data processing pipeline that could be adapted for:
- Government data analysis and reporting
- Location-based event aggregation
- Permit and licensing workflows
- Real-time city services monitoring
