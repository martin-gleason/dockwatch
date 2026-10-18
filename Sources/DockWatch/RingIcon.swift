// Created: 2026-10-18 17:03 -05:00 · Edited: 2026-10-18 17:28 -05:00
// F7-T2 — the hue ring, drawn for the menu bar at any phase (D16). CoreGraphics only.
import AppKit

enum RingIcon {
    /// Menu bar glyph size in points; drawn at the screen's scale by NSImage.
    static let size = CGSize(width: 18, height: 18)
    /// Same proportions as the owner's artwork: inner radius 0.55 of the outer.
    static let innerRatio: CGFloat = 0.55
    /// Red sits at the lower right, as in the artwork; the phase turns the whole wheel.
    static let redAngle: CGFloat = .pi / 4

    /// `dimmed` is the not-connected look: the same ring, desaturated and faint. `held` adds
    /// a filled hub, so FR1's third state reads in a still glance, motion or no motion.
    static func image(phase: Double, dimmed: Bool, held: Bool = false) -> NSImage {
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            draw(in: ctx, rect: rect, phase: CGFloat(phase), dimmed: dimmed)
            if held { drawHub(in: ctx, rect: rect) }
            return true
        }
        image.isTemplate = false
        image.accessibilityDescription = dimmed ? "Dock not connected" : (held ? "Dock connected, kept awake" : "Dock connected")
        return image
    }

    /// The held cue: a small filled disc in the hole, in the label colour so it follows the bar.
    static func drawHub(in ctx: CGContext, rect: CGRect) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2 - 0.5
        let r = outer * innerRatio * 0.5
        ctx.setFillColor(NSColor.labelColor.cgColor)
        ctx.fillEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
    }

    static func draw(in ctx: CGContext, rect: CGRect, phase: CGFloat, dimmed: Bool) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2 - 0.5
        let inner = outer * innerRatio
        let ring = CGMutablePath()
        ring.addEllipse(in: CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2))
        ring.addEllipse(in: CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2))
        ctx.saveGState()
        ctx.addPath(ring)
        ctx.clip(using: .evenOdd)
        if dimmed {
            ctx.setFillColor(NSColor.secondaryLabelColor.withAlphaComponent(0.55).cgColor)
            ctx.fill(rect)
        } else {
            // The wheel as `wedges` filled sectors: a conic sweep with no API dependency and no
            // bitmap rotation. Each sector overlaps the next by a hair so no seam shows.
            let overlap = (2 * CGFloat.pi / CGFloat(wedges)) * 0.15
            for i in 0..<wedges {
                let f = CGFloat(i) / CGFloat(wedges)
                // Clockwise on screen from red at the lower right, advanced by the phase.
                // CoreGraphics angles are counter-clockwise, hence the negation.
                let a0 = -(redAngle + (f + phase) * 2 * .pi)
                let a1 = a0 - 2 * .pi / CGFloat(wedges) - overlap
                ctx.setFillColor(NSColor(hue: f, saturation: 1, brightness: 1, alpha: 1).cgColor)
                ctx.move(to: center)
                ctx.addArc(center: center, radius: outer + 1, startAngle: a0, endAngle: a1, clockwise: true)
                ctx.closePath()
                ctx.fillPath()
            }
        }
        ctx.restoreGState()
    }

    /// Sectors per turn: 5° each, invisible at 18 pt.
    static let wedges = 72
}
