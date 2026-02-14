#!/usr/bin/env swift

import Cocoa

let resourcesPath = "VPNConnect/Resources"
let fileManager = FileManager.default
if !fileManager.fileExists(atPath: resourcesPath) {
    try? fileManager.createDirectory(atPath: resourcesPath, withIntermediateDirectories: true)
}

let size: CGFloat = 512

let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()

NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()

let inset: CGFloat = 50
let cornerRadius: CGFloat = 90

let rect = NSRect(x: inset, y: inset, width: size - inset*2, height: size - inset*2)
let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0).setFill()
path.fill()

let innerInset: CGFloat = 100
let innerCornerRadius = innerInset * 0.75
let innerRect = NSRect(x: innerInset, y: innerInset, width: size - innerInset*2, height: size - innerInset*2)
let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: innerCornerRadius, yRadius: innerCornerRadius)

NSColor(red: 0.18, green: 0.18, blue: 0.2, alpha: 1.0).setFill()
innerPath.fill()

let cx = CGFloat(size) / 2
let scale = CGFloat(size) / 512

let lockW: CGFloat = 135 * scale
let lockH: CGFloat = 115 * scale
let lockX = cx - lockW/2
let lockY: CGFloat = 170 * scale

let lockBody = NSBezierPath(roundedRect: NSRect(x: lockX, y: lockY, width: lockW, height: lockH), xRadius: 25*scale, yRadius: 25*scale)
NSColor(red: 0.75, green: 0.75, blue: 0.78, alpha: 1.0).setFill()
lockBody.fill()

let shackleW: CGFloat = 72 * scale
let shackleX = cx - shackleW/2
let shackleTop = lockY + lockH + 25*scale

let shacklePath = NSBezierPath()
shacklePath.move(to: NSPoint(x: shackleX, y: lockY + lockH*0.3))
shacklePath.line(to: NSPoint(x: shackleX, y: shackleTop))
shacklePath.appendArc(withCenter: NSPoint(x: cx, y: shackleTop), radius: shackleW/2, startAngle: 180, endAngle: 0, clockwise: true)
shacklePath.line(to: NSPoint(x: shackleX + shackleW, y: lockY + lockH*0.3))
shacklePath.lineWidth = 20 * scale
shacklePath.lineCapStyle = .round
NSColor(red: 0.75, green: 0.75, blue: 0.78, alpha: 1.0).setStroke()
shacklePath.stroke()

image.unlockFocus()

if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    let url = URL(fileURLWithPath: "\(resourcesPath)/AppIcon.png")
    try? pngData.write(to: url)
    print("Icon created successfully")
}
