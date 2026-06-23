#!/usr/bin/env swift
import AppKit

// Matches BrandTheme + BrandMark in the app.
private let accent = NSColor(red: 0.22, green: 0.42, blue: 0.36, alpha: 1)
private let accentSoft = NSColor(red: 0.22, green: 0.42, blue: 0.36, alpha: 0.14)

private struct IconSpec {
    let filename: String
    let pixelSize: Int
}

private let specs: [IconSpec] = [
    IconSpec(filename: "icon_16x16.png", pixelSize: 16),
    IconSpec(filename: "icon_16x16@2x.png", pixelSize: 32),
    IconSpec(filename: "icon_32x32.png", pixelSize: 32),
    IconSpec(filename: "icon_32x32@2x.png", pixelSize: 64),
    IconSpec(filename: "icon_128x128.png", pixelSize: 128),
    IconSpec(filename: "icon_128x128@2x.png", pixelSize: 256),
    IconSpec(filename: "icon_256x256.png", pixelSize: 256),
    IconSpec(filename: "icon_256x256@2x.png", pixelSize: 512),
    IconSpec(filename: "icon_512x512.png", pixelSize: 512),
    IconSpec(filename: "icon_512x512@2x.png", pixelSize: 1024),
]

private func renderIcon(pixelSize: Int) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Failed to create bitmap for \(pixelSize)px icon")
    }

    rep.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }

    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("Failed to create graphics context for \(pixelSize)px icon")
    }
    context.imageInterpolation = .high
    NSGraphicsContext.current = context

    let rect = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    let cornerRadius = CGFloat(pixelSize) * (12.0 / 44.0)

    NSColor.clear.setFill()
    rect.fill()

    let background = NSBezierPath(
        roundedRect: rect.insetBy(dx: 0.5, dy: 0.5),
        xRadius: cornerRadius,
        yRadius: cornerRadius
    )
    accentSoft.setFill()
    background.fill()

    let symbolPointSize = CGFloat(pixelSize) * 0.42
    var config = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .semibold)
    config = config.applying(NSImage.SymbolConfiguration(paletteColors: [accent]))
    guard let symbol = NSImage(systemSymbolName: "table.furniture.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else {
        return rep
    }

    let symbolSize = symbol.size
    let symbolRect = NSRect(
        x: (CGFloat(pixelSize) - symbolSize.width) / 2,
        y: (CGFloat(pixelSize) - symbolSize.height) / 2,
        width: symbolSize.width,
        height: symbolSize.height
    )

    symbol.draw(in: symbolRect)

    return rep
}

private func savePNG(_ rep: NSBitmapImageRep, to url: URL) throws {
    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "generate_app_icon", code: 1, userInfo: [NSLocalizedDescriptionKey: "PNG export failed"])
    }
    try png.write(to: url)
}

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0])
let repoRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let outputDir = repoRoot
    .appendingPathComponent("IKEADeskController/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

for spec in specs {
    let rep = renderIcon(pixelSize: spec.pixelSize)
    let url = outputDir.appendingPathComponent(spec.filename)
    try savePNG(rep, to: url)
    print("Wrote \(spec.filename) (\(spec.pixelSize)px)")
}

print("Done — AppIcon.appiconset updated.")
