# Order Fulfillment Example

This example demonstrates how to orchestrate multiple activities in a Temporal workflow to implement a realistic e-commerce order fulfillment process. It showcases Temporal's reliability, retry handling, and activity orchestration patterns using the Swift Temporal SDK.

## Activities

The workflow implements a complete order fulfillment flow with six sequential steps. Each activity represents a call to an external service, benefiting from Temporal's automatic retry and observability:

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
