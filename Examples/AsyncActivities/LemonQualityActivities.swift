//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

#if canImport(Vision)
import Foundation
import Temporal
import Vision

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Activities for analyzing lemon quality using computer vision
@ActivityContainer
public struct LemonQualityActivities {
    // MARK: - COCO Dataset Structures

    struct COCODataset: Codable {
        let images: [COCOImage]
        let annotations: [COCOAnnotation]
        let categories: [COCOCategory]
    }

    struct COCOImage: Codable {
        let id: Int
        let fileName: String

        enum CodingKeys: String, CodingKey {
            case id
            case fileName = "file_name"
        }
    }

    struct COCOAnnotation: Codable {
        let id: Int
        let imageId: Int
        let categoryId: Int

        enum CodingKeys: String, CodingKey {
            case id
            case imageId = "image_id"
            case categoryId = "category_id"
        }
    }

    struct COCOCategory: Codable {
        let id: Int
        let name: String
    }

    // MARK: - Input/Output Types

    public struct ImageMetadata: Codable, Sendable {
        let imageId: String
        let fileName: String
        let imagePath: String
    }

    public struct ImageQualityResult: Codable, Sendable {
        let imageId: String
        let isBlurry: Bool
        let brightness: Double
        let contrast: Double
        let qualityScore: Double
    }

    public struct DefectAnalysisResult: Codable, Sendable {
        let imageId: String
        let hasDefects: Bool
        let defectTypes: [String]
        let confidence: Double
    }

    public struct QualityAttributesResult: Codable, Sendable {
        let imageId: String
        let isHealthy: Bool
        let attributes: [String]
    }

    public struct QualityReport: Codable, Sendable {
        let imageId: String
        let fileName: String
        let qualityScore: Double
        let isBlurry: Bool
        let brightness: Double
        let contrast: Double
        let hasDefects: Bool
        let defectTypes: [String]
        let isHealthy: Bool
        let attributes: [String]
        let overallGrade: String
        let processingTime: Double
    }

    private let datasetPath: String
    private let annotationsByImageId: [Int: [COCOAnnotation]]
    private let imageIdByFileName: [String: Int]
    private let categoriesById: [Int: String]

    init(datasetPath: String) {
        self.datasetPath = datasetPath

        // Load and parse COCO annotations
        let annotationsPath = "\(datasetPath)/annotations/instances_default.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: annotationsPath)),
              let dataset = try? JSONDecoder().decode(COCODataset.self, from: data) else {
            print("⚠️  Failed to load COCO annotations, using filename-based fallback")
            self.annotationsByImageId = [:]
            self.imageIdByFileName = [:]
            self.categoriesById = [:]
            return
        }

        // Build lookup dictionaries
        var annotationsByImageId: [Int: [COCOAnnotation]] = [:]
        for annotation in dataset.annotations {
            annotationsByImageId[annotation.imageId, default: []].append(annotation)
        }
        self.annotationsByImageId = annotationsByImageId

        var imageIdByFileName: [String: Int] = [:]
        for image in dataset.images {
            // Extract just the filename from the full path
            let fileName = URL(fileURLWithPath: image.fileName).lastPathComponent
            imageIdByFileName[fileName] = image.id
        }
        self.imageIdByFileName = imageIdByFileName

        var categoriesById: [Int: String] = [:]
        for category in dataset.categories {
            categoriesById[category.id] = category.name
        }
        self.categoriesById = categoriesById

        print("✅ Loaded COCO annotations: \(dataset.images.count) images, \(dataset.annotations.count) annotations, \(dataset.categories.count) categories")
    }

    // MARK: - Activities

    /// Fetches image metadata from the dataset
    @Activity
    func fetchImageMetadata(input: String) async throws -> ImageMetadata {
        let workerId = ProcessInfo.processInfo.processIdentifier

        print("🔍 [Worker \(workerId)] Fetching metadata for image: \(input)")

        // Simulate network/disk I/O delay
        try await Task.sleep(for: .milliseconds(500))

        let imagePath = "\(datasetPath)/images/\(input)"

        guard FileManager.default.fileExists(atPath: imagePath) else {
            throw ApplicationError(
                message: "Image file not found: \(input)",
                type: "ImageNotFound",
                isNonRetryable: true
            )
        }

        return ImageMetadata(
            imageId: input,
            fileName: input,
            imagePath: imagePath
        )
    }

    /// Analyzes image quality using Vision framework (blur, brightness, contrast)
    @Activity
    func analyzeImageQuality(input: ImageMetadata) async throws -> ImageQualityResult {
        let context = ActivityExecutionContext.current!
        let workerId = ProcessInfo.processInfo.processIdentifier

        print("📊 [Worker \(workerId)] Analyzing image quality: \(input.imageId)")

        let startTime = Date()

        #if canImport(AppKit)
        guard let image = NSImage(contentsOfFile: input.imagePath),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ApplicationError(
                message: "Failed to load image: \(input.imageId)",
                type: "ImageLoadError",
                isNonRetryable: true
            )
        }
        #elseif canImport(UIKit)
        guard let image = UIImage(contentsOfFile: input.imagePath),
              let cgImage = image.cgImage else {
            throw ApplicationError(
                message: "Failed to load image: \(input.imageId)",
                type: "ImageLoadError",
                isNonRetryable: true
            )
        }
        #endif

        // For blur detection, we'll use the contrast from image statistics
        // Low contrast often indicates blur
        let (brightness, contrast) = try calculateImageStatistics(cgImage: cgImage)

        let blurScore = 1.0 - min(1.0, contrast * 5.0)  // Lower contrast = higher blur score
        let isBlurry = contrast < 0.15  // Low contrast threshold indicates blur

        // Calculate overall quality score (0-100)
        let qualityScore = calculateQualityScore(
            isBlurry: isBlurry,
            blurScore: blurScore,
            brightness: brightness,
            contrast: contrast
        )

        // Record heartbeat with processing time
        context.heartbeat()

        let processingTime = Date().timeIntervalSince(startTime)
        print("✅ [Worker \(workerId)] Image quality analyzed in \(String(format: "%.2f", processingTime))s - Score: \(String(format: "%.1f", qualityScore))")

        return ImageQualityResult(
            imageId: input.imageId,
            isBlurry: isBlurry,
            brightness: brightness,
            contrast: contrast,
            qualityScore: qualityScore
        )
    }

    /// Detects defects using COCO annotations (illness, gangrene, mould)
    @Activity
    func detectDefects(input: ImageMetadata) async throws -> DefectAnalysisResult {
        let workerId = ProcessInfo.processInfo.processIdentifier

        print("🔬 [Worker \(workerId)] Detecting defects: \(input.imageId)")

        // Look up annotations for this image
        var defectTypes: [String] = []

        if let imageId = imageIdByFileName[input.fileName],
           let annotations = annotationsByImageId[imageId] {
            // Defect categories: 2=illness, 3=gangrene, 4=mould
            let defectCategoryIds: Set<Int> = [2, 3, 4]

            for annotation in annotations {
                if defectCategoryIds.contains(annotation.categoryId),
                   let categoryName = categoriesById[annotation.categoryId] {
                    if !defectTypes.contains(categoryName) {
                        defectTypes.append(categoryName)
                    }
                }
            }
        }

        let hasDefects = !defectTypes.isEmpty
        let confidence = hasDefects ? 0.85 : 0.95

        print("✅ [Worker \(workerId)] Defect detection complete - Defects found: \(hasDefects) \(defectTypes.isEmpty ? "" : "(\(defectTypes.joined(separator: ", ")))")")

        return DefectAnalysisResult(
            imageId: input.imageId,
            hasDefects: hasDefects,
            defectTypes: defectTypes,
            confidence: confidence
        )
    }

    /// Checks quality attributes using COCO annotations (image_quality, condition)
    @Activity
    func checkQualityAttributes(input: ImageMetadata) async throws -> QualityAttributesResult {
        let workerId = ProcessInfo.processInfo.processIdentifier

        print("🍋 [Worker \(workerId)] Checking quality attributes: \(input.imageId)")

        // Look up annotations for this image
        var attributes: [String] = []

        if let imageId = imageIdByFileName[input.fileName],
           let annotations = annotationsByImageId[imageId] {
            // Quality categories: 1=image_quality, 8=condition
            let qualityCategoryIds: Set<Int> = [1, 8]

            for annotation in annotations {
                if qualityCategoryIds.contains(annotation.categoryId),
                   let categoryName = categoriesById[annotation.categoryId] {
                    if !attributes.contains(categoryName) {
                        attributes.append(categoryName)
                    }
                }
            }
        }

        // Consider healthy if no defects detected and has quality annotations
        let isHealthy = !attributes.isEmpty

        print("✅ [Worker \(workerId)] Quality attributes checked - Healthy: \(isHealthy) \(attributes.isEmpty ? "" : "(\(attributes.joined(separator: ", ")))")")

        return QualityAttributesResult(
            imageId: input.imageId,
            isHealthy: isHealthy,
            attributes: attributes
        )
    }

    struct GenerateReportInput: Codable, Sendable {
        let metadata: ImageMetadata
        let quality: ImageQualityResult
        let defects: DefectAnalysisResult
        let attributes: QualityAttributesResult
    }

    /// Generates a comprehensive quality report
    @Activity
    func generateQualityReport(input: GenerateReportInput) async throws -> QualityReport {
        let workerId = ProcessInfo.processInfo.processIdentifier

        print("📝 [Worker \(workerId)] Generating quality report: \(input.metadata.imageId)")

        // Calculate overall grade based on all factors
        let overallGrade: String
        if input.quality.qualityScore > 80 && !input.defects.hasDefects && input.attributes.isHealthy {
            overallGrade = "A"
        } else if input.quality.qualityScore > 60 && !input.defects.hasDefects {
            overallGrade = "B"
        } else if input.quality.qualityScore > 40 {
            overallGrade = "C"
        } else {
            overallGrade = "F"
        }

        print("✅ [Worker \(workerId)] Report generated - Grade: \(overallGrade)")

        return QualityReport(
            imageId: input.metadata.imageId,
            fileName: input.metadata.fileName,
            qualityScore: input.quality.qualityScore,
            isBlurry: input.quality.isBlurry,
            brightness: input.quality.brightness,
            contrast: input.quality.contrast,
            hasDefects: input.defects.hasDefects,
            defectTypes: input.defects.defectTypes,
            isHealthy: input.attributes.isHealthy,
            attributes: input.attributes.attributes,
            overallGrade: overallGrade,
            processingTime: 0  // Will be calculated in workflow
        )
    }

    // MARK: - Helper Methods

    private func calculateImageStatistics(cgImage: CGImage) throws -> (brightness: Double, contrast: Double) {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )

        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Calculate brightness and contrast from a sample of pixels
        let sampleSize = min(1000, width * height)
        var totalBrightness: Double = 0
        var brightnessValues: [Double] = []

        for _ in 0..<sampleSize {
            let x = Int.random(in: 0..<width)
            let y = Int.random(in: 0..<height)
            let pixelIndex = (y * width + x) * bytesPerPixel

            let r = Double(pixelData[pixelIndex])
            let g = Double(pixelData[pixelIndex + 1])
            let b = Double(pixelData[pixelIndex + 2])

            // Calculate perceived brightness
            let brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
            totalBrightness += brightness
            brightnessValues.append(brightness)
        }

        let avgBrightness = totalBrightness / Double(sampleSize)

        // Calculate standard deviation for contrast
        let variance = brightnessValues.reduce(0.0) { sum, value in
            let diff = value - avgBrightness
            return sum + (diff * diff)
        } / Double(sampleSize)

        let contrast = sqrt(variance)

        return (brightness: avgBrightness, contrast: contrast)
    }

    private func calculateQualityScore(isBlurry: Bool, blurScore: Double, brightness: Double, contrast: Double) -> Double {
        var score: Double = 100.0

        // Penalize for blur
        if isBlurry {
            score -= 30.0
        } else {
            score -= (blurScore * 20.0)  // Partial penalty for slight blur
        }

        // Penalize for poor brightness (ideal is around 0.5)
        let brightnessDiff = abs(brightness - 0.5)
        score -= (brightnessDiff * 40.0)

        // Penalize for low contrast
        if contrast < 0.1 {
            score -= 20.0
        } else if contrast < 0.15 {
            score -= 10.0
        }

        return max(0, min(100, score))
    }
}

#else
// Fallback for platforms without Vision framework
@ActivityContainer
struct LemonQualityActivities {
    struct ImageMetadata: Codable, Sendable {
        let imageId: String
        let fileName: String
        let imagePath: String
    }

    init(datasetPath: String) {}
}
#endif
