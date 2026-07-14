#!/usr/bin/env swift

import AppKit
import Foundation

struct IconEntry {
    let filename: String
    let pointSize: Int
    let scale: Int
    var pixelSize: Int { pointSize * scale }

    var jsonEntry: [String: Any] {
        [
            "filename": filename,
            "idiom": "universal",
            "scale": "\(scale)x",
            "size": "\(pointSize)x\(pointSize)",
        ]
    }
}

let entries: [IconEntry] = [
    IconEntry(filename: "icon_16x16.png", pointSize: 16, scale: 1),
    IconEntry(filename: "icon_16x16@2x.png", pointSize: 16, scale: 2),
    IconEntry(filename: "icon_32x32.png", pointSize: 32, scale: 1),
    IconEntry(filename: "icon_32x32@2x.png", pointSize: 32, scale: 2),
    IconEntry(filename: "icon_128x128.png", pointSize: 128, scale: 1),
    IconEntry(filename: "icon_128x128@2x.png", pointSize: 128, scale: 2),
    IconEntry(filename: "icon_256x256.png", pointSize: 256, scale: 1),
    IconEntry(filename: "icon_256x256@2x.png", pointSize: 256, scale: 2),
    IconEntry(filename: "icon_512x512.png", pointSize: 512, scale: 1),
    IconEntry(filename: "icon_512x512@2x.png", pointSize: 512, scale: 2),
]

let outputDir = "Resources/AppIcon.appiconset"
try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

var images: [[String: Any]] = []

for entry in entries {
    let px = entry.pixelSize
    let side = CGFloat(px)
    let config = NSImage.SymbolConfiguration(pointSize: side * 0.55, weight: .regular)
    guard let symbol = NSImage(systemSymbolName: "waveform", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else {
        fatalError("Failed to load waveform symbol")
    }

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: px,
        pixelsHigh: px,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: px * 4,
        bitsPerPixel: 32
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let bg = NSColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
    bg.setFill()
    NSRect(x: 0, y: 0, width: side, height: side).fill()

    let symbolRect = NSRect(
        x: (side - side * 0.7) / 2,
        y: (side - side * 0.7) / 2,
        width: side * 0.7,
        height: side * 0.7
    )
    symbol.draw(in: symbolRect)

    NSGraphicsContext.restoreGraphicsState()

    let pngData = rep.representation(using: .png, properties: [:])!
    try pngData.write(to: URL(fileURLWithPath: "\(outputDir)/\(entry.filename)"))
    images.append(entry.jsonEntry)
}

let contents: [String: Any] = [
    "images": images,
    "info": ["version": 1, "author": "xcode"],
]

let jsonData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
let jsonString = String(data: jsonData, encoding: .utf8)!.replacingOccurrences(of: "\\/", with: "/") + "\n"
try jsonString.write(toFile: "\(outputDir)/Contents.json", atomically: true, encoding: .utf8)

print("Generated \(entries.count) icon sizes in \(outputDir)")
