# Async Activities Example - Lemon Quality Control

Demonstrates parallel and concurrent activity execution in Temporal workflows using a computer vision pipeline. This example processes images from the [lemon-dataset](https://github.com/softwaremill/lemon-dataset) using Apple's Vision framework.

## Features Demonstrated

### Parallel Activity Execution
- **`async let`**: Run multiple analysis activities concurrently per image
- **Task Groups**: Process multiple images in parallel with `withThrowingTaskGroup`
- **Multiple Workers**: Distribute activity execution across 5 worker instances

### Computer Vision with COCO Annotations
- Uses Apple's Vision framework for image quality analysis
- Analyzes 2,690 annotated lemon images from COCO dataset
- Uses ground truth labels for defect detection (illness, gangrene, mould)
- Calculates blur, brightness, and contrast metrics

### Performance Comparison
- Sequential vs parallel processing modes
- Timing metrics showing speedup from parallelization
- Demonstrates Temporal's scalability

## Activities

### `fetchImageMetadata`
Fetches image metadata and validates file existence.
- **Input**: Image ID (filename)
- **Output**: Image metadata with file path
- **Simulated delay**: 500ms (network/disk I/O)

### `analyzeImageQuality`
Analyzes image quality using Vision framework.
- **Input**: Image metadata
- **Output**: Quality metrics (blur, brightness, contrast, quality score)
- **Image processing**: Loads image, samples pixels, calculates statistics

### `detectDefects`
Detects lemon defects using COCO ground truth annotations.
- **Input**: Image metadata
- **Output**: Defect analysis with confidence scores
- **Categories detected**: illness (category 2), gangrene (category 3), mould (category 4)

### `checkQualityAttributes`
Checks quality attributes using COCO annotations.
- **Input**: Image metadata
- **Output**: Quality attributes and health status
- **Categories checked**: image_quality (category 1), condition (category 8)

### `generateQualityReport`
Generates comprehensive quality report with overall grade.
- **Input**: Metadata, quality, defects, attributes
- **Output**: Final quality report with grade (A-F)

## Workflow Execution Patterns

### Sequential Mode
Processes images one at a time:
```swift
for imageId in input.imageIds {
    let report = try await processImage(imageId: imageId)
    reports.append(report)
}
```

### Parallel Mode
Processes all images concurrently using task groups:
```swift
try await withThrowingTaskGroup(of: QualityReport?.self) { group in
    for imageId in input.imageIds {
        group.addTask {
            try await self.processImage(imageId: imageId)
        }
    }
    // Collect results as they complete
}
```

### Per-Image Concurrency
Each image runs multiple analyses in parallel:
```swift
async let qualityResult = Workflow.executeActivity(analyzeImageQuality, ...)
async let defectsResult = Workflow.executeActivity(detectDefects, ...)
async let attributesResult = Workflow.executeActivity(checkQualityAttributes, ...)

let (quality, defects, attributes) = try await (qualityResult, defectsResult, attributesResult)
```

## Setup

### Prerequisites
1. Temporal server running locally:
```bash
temporal server start-dev
```

2. Lemon dataset submodule and extraction:
```bash
git submodule update --init --recursive
cd Examples/AsyncActivities/lemon-dataset/data
unzip lemon-dataset.zip
```

## Running the Example

```bash
swift run AsyncActivitiesExample
```

This runs a single worker that demonstrates both sequential and parallel activity execution patterns within workflows.

### Expected Output

```
🍋 Lemon Quality Control - Async Activities Example
======================================================================

📊 Dataset Information:
  Total images in dataset: 2690
  Images for this demo: 15
  Dataset path: Examples/AsyncActivities/lemon-dataset/data/lemon-dataset

🚀 Starting Workers:
  ✅ Worker 1 started (PID: 12345)
  ✅ Worker 2 started (PID: 12345)
  ✅ Worker 3 started (PID: 12345)
  ✅ Worker 4 started (PID: 12345)
  ✅ Worker 5 started (PID: 12345)

======================================================================

⏳ Test 1: Sequential Processing
----------------------------------------------------------------------
🔗 View in Temporal UI:
  http://localhost:8233/namespaces/default/workflows/BATCH-SEQ-...

✅ Sequential Processing Complete:
  Success: 15/15
  Total time: 8.70s
  Average per image: 0.58s

======================================================================

⚡ Test 2: Parallel Processing (5 Workers)
----------------------------------------------------------------------
🔗 View in Temporal UI:
  http://localhost:8233/namespaces/default/workflows/BATCH-PAR-...

📊 Processing 15 images across 5 workers...

✅ Parallel Processing Complete:
  Success: 15/15
  Total time: 1.74s
  Average per image: 0.12s

  Sample Results:
    • 0003_A_V_150_A.jpg: Grade A, Quality: 87.3, ✅ Clean
    • 0003_A_V_75_A.jpg: Grade B, Quality: 72.1, ✅ Clean
    • 0004_A_H_60_A.jpg: Grade A, Quality: 91.5, ✅ Clean

======================================================================

📈 Performance Summary:
----------------------------------------------------------------------
  Sequential: 8.70s for 15 images
  Parallel:   1.74s for 15 images

  Speedup: 5.0x
  (Parallel processing is 5.0x faster)

✅ Example completed successfully!
```

## Key Patterns

### Multiple Workers
Worker instances share the same task queue. Temporal automatically distributes activities across available workers for parallel execution.

### Workflow Concurrency
Leverages Swift's async/await and Structured Concurrency within workflows while maintaining Temporal's deterministic execution guarantees. See [Workflow Concurrency](../../Sources/Temporal/Documentation.docc/Workflows/Workflow-Concurrency.md) for details.

### Application
Demonstrates a quality control pipeline that could be adapted for:
- Manufacturing defect detection
- Agricultural product grading
- Medical image analysis
- Document processing at scale
