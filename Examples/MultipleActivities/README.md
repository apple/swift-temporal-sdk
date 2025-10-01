# Order Fulfillment Example

This example demonstrates how to orchestrate multiple activities in a Temporal workflow to implement a realistic e-commerce order fulfillment process. It showcases Temporal's reliability, retry handling, and activity orchestration patterns using the Swift Temporal SDK.

## What You'll Learn

1. **Activity Orchestration**: Coordinating multiple external service calls in a reliable sequence
2. **Retry Policies**: Configuring appropriate retry strategies for different types of operations
3. **Error Handling**: Distinguishing between retryable and non-retryable errors
4. **Best Practices**: When to use activities vs. workflow code, and how to structure inputs/outputs
5. **Real-World Patterns**: Implementing a complete business process with external dependencies

## Business Process

The workflow implements a complete order fulfillment flow with six sequential steps:

```
1. Check Inventory    → Verify all items are in stock
2. Process Payment    → Charge customer via payment gateway
3. Reserve Inventory  → Update stock levels in inventory system
4. Create Shipment    → Generate tracking number from shipping provider
5. Send Confirmation  → Notify customer via email/SMS
6. Update Order       → Mark order as fulfilled in database
```

## Activities

Each activity represents a call to an external service, benefiting from Temporal's automatic retry and observability:

### `checkInventory`
- **Purpose**: Validates inventory availability with external inventory management system
- **Retry Strategy**: 3 attempts with exponential backoff
- **Error Handling**: Out-of-stock errors are non-retryable business errors

### `processPayment`
- **Purpose**: Charges customer through payment gateway (e.g., Stripe, PayPal)
- **Retry Strategy**: 5 attempts with longer timeouts to handle payment gateway delays
- **Error Handling**: `InsufficientFunds` and `InvalidCard` are non-retryable
- **Special Feature**: Demonstrates idempotent payment processing

### `reserveInventory`
- **Purpose**: Updates stock levels in inventory database after successful payment
- **Retry Strategy**: 3 attempts with quick retries for database operations

### `createShipment`
- **Purpose**: Creates shipment and returns tracking number from shipping provider API
- **Retry Strategy**: 4 attempts with moderate timeouts for external API calls

### `sendConfirmation`
- **Purpose**: Sends order confirmation to customer via notification service
- **Retry Strategy**: 3 attempts (notifications can be retried safely)

### `updateOrderStatus`
- **Purpose**: Updates order status in order management database
- **Retry Strategy**: 3 attempts with quick retries for database operations

## Retry Configuration

Each activity uses tailored retry policies. For example:

```swift
// Payment processing - longer timeouts, non-retryable business errors
retryPolicy: .init(
    initialInterval: .seconds(1),
    backoffCoefficient: 2.0,
    maximumInterval: .seconds(30),
    maximumAttempts: 5,
    nonRetryableErrorTypes: ["InsufficientFunds", "InvalidCard"]
)

// Database operations - quick retries, shorter timeouts
retryPolicy: .init(
    initialInterval: .milliseconds(500),
    backoffCoefficient: 2.0,
    maximumInterval: .seconds(10),
    maximumAttempts: 3
)
```

## Fake Services

The example includes realistic fake implementations of external services:

- **`FakeInventoryService`**: Simulates inventory management system with stock tracking
- **`FakePaymentService`**: Simulates payment gateway with idempotency handling
- **`FakeShippingService`**: Simulates shipping provider API with tracking numbers
- **`FakeNotificationService`**: Simulates email/SMS notification service
- **`FakeOrderDatabase`**: Simulates order management database

Each service includes realistic delays to simulate network calls.

## Running the Example

### Prerequisites
Ensure you have a Temporal server running locally:
```bash
temporal server start-dev
```

### Execute the Workflow
```bash
swift run MultipleActivitiesExample
```

### Expected Output

```
🛒 Starting Order Fulfillment Workflow Example
============================================================

📋 Order Details:
  Order ID: ORD-DD22C618
  Customer: customer-123
  Items: laptop, mouse, keyboard
  Total: $1299.99

📦 Checking inventory for 3 item(s)...
✅ All items in stock
💳 Processing payment of $1299.99 for customer customer-123...
✅ Payment successful: pay_AEF5A9AF-678
📦 Reserving inventory for order ORD-DD22C618...
✅ Inventory reserved
📮 Creating shipment for order ORD-DD22C618...
✅ Shipment created: TRK996996117
📧 Sending confirmation to customer customer-123...
✅ Confirmation sent
💾 Updating order ORD-DD22C618 status to 'fulfilled'...
✅ Order status updated

============================================================
✅ Order Fulfilled Successfully!
============================================================
📦 Order Status: fulfilled
💳 Payment ID: pay_AEF5A9AF-678
🚚 Tracking Number: TRK996996117
```

## Key Concepts Demonstrated

### Why Activities?
Each operation is an activity because it:
- Calls an external service (payment gateway, shipping API, database)
- Can fail transiently and needs retry logic
- Should be tracked and monitored independently
- Benefits from Temporal's reliability guarantees

### Why Not Workflow Code?
Operations like string concatenation or simple calculations should happen in workflow code, not activities. Activities are for operations with side effects or external dependencies.

### Structured Input/Output
All activity inputs and outputs use Codable structs rather than tuples:
```swift
struct PaymentInput: Codable {
    let customerId: String
    let amount: Double
}
```

This ensures proper serialization and makes the API clear and type-safe.

## Further Exploration

Try modifying this example to:
- Add parallel activity execution (check inventory and validate address simultaneously)
- Implement compensation/rollback (refund payment if shipment fails)
- Add a signal to cancel an order mid-fulfillment
- Use a query to check order status while workflow is running
