# Child Workflows - Pizza Restaurant

Demonstrates parent and child workflow orchestration through a pizza restaurant order fulfillment system.

## Features

**Child Workflow Patterns:**
- Parallel child workflows for multiple pizzas
- Parallel execution of sides with pizza preparation
- Sequential child workflow for delivery after cooking
- Custom workflow IDs for tracking
- Result aggregation from multiple children

**Workflows:**
- `PizzaOrderWorkflow` (parent) - Orchestrates complete order
- `MakePizzaWorkflow` (child) - Prepares individual pizzas
- `PrepareSidesWorkflow` (child) - Prepares sides
- `AssignDeliveryWorkflow` (child) - Handles delivery

## Usage

Start Temporal server:
```bash
temporal server start-dev
```

Run the example:
```bash
swift run ChildWorkflowExample
```

The example demonstrates:
1. Order with 3 pizzas and sides received
2. Pizza child workflows execute in parallel
3. Sides child workflow executes concurrently
4. Delivery child workflow executes sequentially
5. Results aggregated and returned

## Key Patterns

**Starting parallel child workflows with task groups:**
```swift
let results = try await withThrowingTaskGroup(of: (Int, String).self) { group in
    for (index, pizzaSpec) in pizzas.enumerated() {
        group.addTask {
            let handle = try await Workflow.startChildWorkflow(
                MakePizzaWorkflow.self,
                options: .init(id: "order-\(orderID)-pizza-\(index + 1)"),
                input: pizzaSpec
            )
            return (index, try await handle.result())
        }
    }

    var results: [String] = Array(repeating: "", count: pizzas.count)
    for try await (index, result) in group {
        results[index] = result
    }
    return results
}
```

**Sequential child workflow execution:**
```swift
let deliveryHandle = try await Workflow.startChildWorkflow(
    AssignDeliveryWorkflow.self,
    options: .init(id: "\(orderId)-delivery"),
    input: deliveryInfo
)
let result = try await deliveryHandle.result()
```

**Using `executeChildWorkflow` convenience method:**
```swift
let result = try await Workflow.executeChildWorkflow(
    MakePizzaWorkflow.self,
    input: pizzaSpec
)
```

View workflows in Temporal UI: `http://localhost:8233`
- Parent workflow shows child workflow executions
- Each child appears as separate workflow
- Observe parallel execution timing

## Example Output

```
🍕 Pizza Restaurant - Child Workflows Example
============================================================

📝 New Order: ORDER-20568
   • 3 pizza(s)
     - Pizza #1: large with pepperoni, mushrooms, olives
     - Pizza #2: large with sausage, peppers, onions
     - Pizza #3: medium with margherita
   • Sides: wings, garlic bread
   • Delivery to: 123 Main St, Apt 4B

⏳ Executing workflow...

📦 Order ORDER-20568 - Starting fulfillment
   3 pizza(s), sides: wings, garlic bread

🍕 Stage 1: Kitchen preparation (parallel execution)
   ✓ Pizza #3 (medium, margherita) - ready
   ✓ Pizza #2 (large, sausage, peppers, onions) - ready
   ✓ Pizza #1 (large, pepperoni, mushrooms, olives) - ready
   ✓ Sides: wings, garlic bread - ready
   Kitchen preparation complete!

📦 Stage 2: Packaging order
   ✓ Order packaged and ready for delivery

🚗 Stage 3: Delivery assignment (sequential execution)
   ✓ David (Driver #49) - delivered to 123 Main St, Apt 4B

============================================================
✅ Order Completed!
============================================================
Child Workflows Demonstrated:
  • 3 MakePizzaWorkflow children (parallel)
  • 1 PrepareSidesWorkflow child (parallel with pizzas)
  • 1 AssignDeliveryWorkflow child (sequential)
```
