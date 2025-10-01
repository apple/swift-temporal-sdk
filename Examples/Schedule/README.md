# Schedule

Demonstrates Temporal's scheduling capabilities through a space mission control automation scenario using real NASA and space APIs to monitor the International Space Station.

## Features

This example monitors the International Space Station (ISS) with scheduled operations that execute real API calls to fetch live telemetry and crew data.

**Calendar-Based Scheduling:**
- System health check - Daily at 00:00 UTC
- Crew status verification - 3x daily (06:00, 14:00, 22:00 UTC)

**Interval-Based Scheduling:**
- Telemetry collection - Every 90 minutes (matches ISS orbital period)

**Real API Integration:**
- wheretheiss.at - Real-time ISS position, altitude, velocity, visibility
    - Endpoint: `https://api.wheretheiss.at/v1/satellites/25544`
    - Returns: Real-time ISS position, altitude (417 km), velocity (27,600 km/h), visibility
    - Rate limit: ~1 request per second
- open-notify.org - Current astronauts in space and their spacecraft
    - Endpoint: `http://api.open-notify.org/astros.json`
    - Returns: Current astronauts in space (shows both ISS and Tiangong crew)
    - Rate limit: ~1 request per 5 seconds
- Both APIs are free and require no registration.



**Durable Execution:**
- Automatic retries with exponential backoff for network failures
- Timeout handling for API calls
- Workflow orchestration ensures reliable operation execution
- Operations continue despite worker restarts
- Complete audit trail of all operations in Temporal UI

**Reliable Scheduling:**
- Never miss orbital windows or system checks
- Precise timing with calendar and interval specifications

**Automatic Retries:**
- Handle API timeouts and network failures gracefully
- Exponential backoff prevents overwhelming APIs

**Long-Running Operations:**
- Support for multi-minute operations (e.g., thruster burns)
- Workflow sleep for accurate timing





## Usage

Start Temporal server:
```bash
temporal server start-dev
```

Run the example:
```bash
cd Examples/Schedule
swift run ScheduleExample
```

View schedules in Temporal UI: `http://localhost:8233/schedules`

The example creates three schedules and triggers them immediately for demonstration:
1. Telemetry collection - Shows real ISS position changing over time
2. Crew status check - Lists current astronauts on ISS and other stations
3. System health check - Combines real telemetry with simulated subsystem status

**Stopping the example:**
Press `Ctrl+C` to stop. The schedules will remain active until manually deleted.

**Cleaning up schedules:**
If you need to manually delete the schedules (e.g., if the example was interrupted):
```bash
temporal schedule delete --schedule-id iss-telemetry-schedule
temporal schedule delete --schedule-id iss-crew-schedule
temporal schedule delete --schedule-id iss-health-schedule
```

Or delete all at once:
```bash
temporal schedule delete --schedule-id iss-telemetry-schedule && \
temporal schedule delete --schedule-id iss-crew-schedule && \
temporal schedule delete --schedule-id iss-health-schedule
```

## ISS Facts

The example uses real data from:
- Altitude: ~408 km (varies 400-420 km)
- Velocity: ~27,600 km/h (7.66 km/s)
- Orbital period: ~90 minutes (16 orbits per day)
- NORAD Catalog ID: 25544
- Current crew: 9 astronauts (as of example data)

## Key Patterns

**Interval-based schedule (every 90 minutes):**
```swift
Schedule(
    action: .startWorkflow(...),
    specification: .init(
        intervals: [.init(
            every: .seconds(90 * 60),
            offset: .zero
        )],
        timeZoneName: "UTC"
    )
)
```

**Calendar-based schedule (specific times):**
```swift
Schedule(
    action: .startWorkflow(...),
    specification: .init(
        calendars: [
            .init(hour: [.init(value: 6)], minute: [.init(value: 0)]),
            .init(hour: [.init(value: 14)], minute: [.init(value: 0)])
        ],
        timeZoneName: "UTC"
    )
)
```

**Creating schedule with immediate trigger:**
```swift
let handle = try await client.createSchedule(
    schedule: telemetrySchedule,
    options: .init(
        id: "iss-telemetry-schedule",
        triggerImmediately: true
    )
)
```

**Activity retry policy for API calls:**
```swift
ActivityOptions(
    startToCloseTimeout: .seconds(30),
    retryPolicy: RetryPolicy(
        maximumAttempts: 3,
        initialInterval: .seconds(1),
        backoffCoefficient: 2.0
    )
)
```

## Output

The example displays:
- Real-time ISS telemetry with formatted position and altitude status
- Complete list of astronauts currently in space (by station)
- System health assessment based on real orbital parameters
- Links to Temporal UI for viewing schedules and workflow executions

View all schedules in Temporal UI: `http://localhost:8233/schedules`
