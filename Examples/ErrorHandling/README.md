# Travel Booking Error Handling Example

This example demonstrates Temporal's error handling and compensation patterns through an unrealistic travel booking workflow. It showcases two critical patterns: **automatic retry with exponential backoff** and the **Saga pattern for distributed transactions**. 

## Business Scenario

The workflow implements a travel booking system with three sequential steps:

```
1. Reserve Flight  → Book flight reservation
2. Reserve Hotel   → Book hotel reservation
3. Charge Payment  → Process customer payment
```

In a realistic example we would charge the payment first, but since this example is here to showcase error handling we'll do it unrealistical. 

If any step fails, the workflow must handle it appropriately:
- **Transient failures** (network timeout, service unavailable) → Retry automatically.
- **Business errors** (insufficient funds, invalid card) → Don't retry, compensate previous steps.

## Three Scenarios

### Scenario 1: Retry with Exponential Backoff

**What happens:**
- Flight reservation fails twice (connection timeout, service unavailable)
- Temporal automatically retries with exponential backoff
- Flight reservation succeeds on 3rd attempt
- Hotel reservation fails once (database timeout)
- Temporal retries, hotel reservation succeeds on 2nd attempt
- Payment processes successfully
- **Result**: Booking confirmed ✅

### Scenario 2: Saga Pattern / Compensation

**What happens:**
- Flight reservation succeeds (after retries)
- Hotel reservation succeeds (after retries)
- Payment fails with "Insufficient Funds" (non-retryable error)
- Temporal triggers compensation logic
    - Compensation happens in **reverse order** (hotel before flight).
    - Each compensation step is a separate activity with its own retry policy.
    - Workflow tracks reservation IDs using structured types.
- Hotel reservation cancelled
- Flight reservation cancelled
- **Result**: Booking cancelled, no partial state left behind 🔄

### Scenario 3: Workflow Failure (Compensation Fails)

**What happens:**
- Flight reservation succeeds (after retries)
- Hotel reservation succeeds (after retries)
- Payment fails with "Insufficient Funds" (non-retryable error)
- Temporal triggers compensation logic
    - Compensation happens in **reverse order** (hotel before flight).
    - Each compensation step is a separate activity with its own retry policy.
    - Workflow tracks reservation IDs using structured types.
- Hotel cancellation **fails** (hotel booking system down)
- Flight cancellation **fails** (airline API timeout)
- **Result**: Workflow FAILS with critical error ❌

## Workflow Logic

The workflow demonstrates proper compensation in the Saga pattern:

```swift
do {
    // Step 1: Reserve flight
    flightReservationId = try await reserveFlight(...)

    // Step 2: Reserve hotel
    hotelReservationId = try await reserveHotel(...)

    // Step 3: Charge payment
    paymentId = try await chargePayment(...)

    return .success

} catch {
    // Compensation: Rollback in reverse order

    if let hotelId = hotelReservationId {
        try await cancelHotel(hotelId)  // Cancel hotel first
    }

    if let flightId = flightReservationId {
        try await cancelFlight(flightId)  // Cancel flight second
    }

    return .cancelled
}
```

## Running the Example

### Prerequisites
Ensure you have a Temporal server running locally:
```bash
temporal server start-dev
```

### Execute the Workflow
```bash
swift run ErrorHandlingExample
```
You can inspect workflow execution history at http://localhost:8233.

### Expected Output

```
✈️  Travel Booking Error Handling Example
============================================================

📋 Scenario 1: Retry with Exponential Backoff
------------------------------------------------------------
✈️  Reserving flight FL-NYC-LAX-101 for customer customer-001...
⚠️  Flight reservation attempt 1 failed: Connection timeout
✈️  Reserving flight FL-NYC-LAX-101 for customer customer-001...
⚠️  Flight reservation attempt 2 failed: Service temporarily unavailable
✈️  Reserving flight FL-NYC-LAX-101 for customer customer-001...
✅ Flight reserved: FLIGHT-RES-B9BDA0E6
🏨 Reserving hotel HOTEL-LAX-DOWNTOWN for customer customer-001...
⚠️  Hotel reservation attempt 1 failed: Database connection timeout
🏨 Reserving hotel HOTEL-LAX-DOWNTOWN for customer customer-001...
✅ Hotel reserved: HOTEL-RES-AB0EDE18
💳 Charging payment of $999.99 for customer customer-001...
✅ Payment successful: PAY-0F9A70C7-806

============================================================
✅ Scenario 1 Complete!
============================================================
Status: confirmed
Message: Travel booking completed successfully
Flight: FLIGHT-RES-B9BDA0E6
Hotel: HOTEL-RES-AB0EDE18
Payment: PAY-0F9A70C7-806

📋 Scenario 2: Saga Pattern / Compensation
------------------------------------------------------------
✈️  Reserving flight FL-LAX-NYC-202 for customer customer-002...
⚠️  Flight reservation attempt 1 failed: Connection timeout
✈️  Reserving flight FL-LAX-NYC-202 for customer customer-002...
⚠️  Flight reservation attempt 2 failed: Service temporarily unavailable
✈️  Reserving flight FL-LAX-NYC-202 for customer customer-002...
✅ Flight reserved: FLIGHT-RES-9289531D
🏨 Reserving hotel HOTEL-NYC-TIMES-SQUARE for customer customer-002...
⚠️  Hotel reservation attempt 1 failed: Database connection timeout
🏨 Reserving hotel HOTEL-NYC-TIMES-SQUARE for customer customer-002...
✅ Hotel reserved: HOTEL-RES-20BA3B0E
💳 Charging payment of $1499.99 for customer customer-002...
❌ Payment failed: Insufficient funds
🔄 Cancelling hotel reservation HOTEL-RES-20BA3B0E...
✅ Hotel reservation cancelled
🔄 Cancelling flight reservation FLIGHT-RES-9289531D...
✅ Flight reservation cancelled

============================================================
🔄 Scenario 2 Complete!
============================================================
Status: cancelled
Message: Booking failed: Insufficient funds. All reservations cancelled.
Flight (cancelled): FLIGHT-RES-9289531D
Hotel (cancelled): HOTEL-RES-20BA3B0E

📋 Scenario 3: Workflow Failure (Compensation Fails)
------------------------------------------------------------
✈️  Reserving flight FL-SFO-BOS-303 for customer customer-003...
⚠️  Flight reservation attempt 1 failed: Connection timeout
✈️  Reserving flight FL-SFO-BOS-303 for customer customer-003...
⚠️  Flight reservation attempt 2 failed: Service temporarily unavailable
✈️  Reserving flight FL-SFO-BOS-303 for customer customer-003...
✅ Flight reserved: FLIGHT-RES-66721C55
🏨 Reserving hotel HOTEL-BOS-HARBOR for customer customer-003...
⚠️  Hotel reservation attempt 1 failed: Database connection timeout
🏨 Reserving hotel HOTEL-BOS-HARBOR for customer customer-003...
✅ Hotel reserved: HOTEL-RES-08381B80
💳 Charging payment of $1899.99 for customer customer-003...
❌ Payment failed: Insufficient funds
🔄 Cancelling hotel reservation HOTEL-RES-08381B80...
❌ Hotel cancellation failed: Hotel booking system unavailable
🔄 Cancelling flight reservation FLIGHT-RES-66721C55...
❌ Flight cancellation failed: Airline API timeout

============================================================
❌ Scenario 3: WORKFLOW FAILED
============================================================
This is expected! The workflow failed because compensation
was impossible. In production, this would trigger alerts
for manual intervention.

Error details:
Critical: Booking failed AND compensation failed. Manual intervention required.
Reservations requiring manual cleanup:
  - Flight: FLIGHT-RES-66721C55
  - Hotel: HOTEL-RES-08381B80
```

## Key Concepts Demonstrated

### Automatic Retry
Temporal automatically retries failed activities according to the retry policy with exponential backoff. No manual retry code needed.

### Non-Retryable Errors
Business logic errors (like `InsufficientFunds`, `InvalidCard`) are marked as non-retryable and trigger compensation instead of retry.

### Saga Pattern
Distributed transactions require compensation when later steps fail:
- Track what was successfully completed (reservation IDs)
- On failure, undo in reverse order
- Each compensation is a separate activity (can be retried)

**What if compensation fails?** The workflow itself fails (Scenario 3), providing details about what needs manual cleanup. This is correct behavior - better to fail loudly than leave inconsistent state.

## Production Considerations

When compensation fails (Scenario 3), production systems should:
- Trigger alerts (PagerDuty/Slack) to operations team
- Create support tickets with reservation details for manual cleanup
- Log failed compensations for analysis

The workflow provides all necessary information in the error message for manual intervention.

