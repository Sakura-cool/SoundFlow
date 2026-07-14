#!/usr/bin/env swift

import AppKit
import Foundation

let sizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

let outputDir = "Resources/AppIcon.appiconset"
try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

var images: [[String: Any]] = []

for (name, px) in sizes {
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
    let filePath = "\(outputDir)/\(name).png"
    try pngData.write(to: URL(fileURLWithPath: filePath))

    let filename = "\(name).png"
    var entry: [String: Any] = [
        "size": "\(Int(side))x\(Int(side))",
        "idiom": "mac",
        "filename": filename
    ]
    if px >= 32 && px % 2 == 0 {
        let pointSize = Int(side / 2)
        entry["scale"] = "\(px / pointSize)x"
    } else {
        entry["scale"] = "1x"
    }
    images.append(entry)
}

let contents: [String: Any] = [
    "images": images,
    "info": ["version": 1, "author": "xcode"]
]

let jsonData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
let jsonString = String(data: jsonData, encoding: .utf8)!.replacingOccurrences(of: "\\/", with: "/")
try jsonString.write(toFile: "\(outputDir)/Contents.json", atomically: true, encoding: .utf8)

print("Generated \(sizes.count) icon sizes in \(outputDir)")
