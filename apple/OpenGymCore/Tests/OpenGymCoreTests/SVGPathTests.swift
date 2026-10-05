import CoreGraphics
import Foundation
import Testing
@testable import OpenGymCore

struct SVGPathTests {
    private func bounds(_ d: String) -> CGRect { SVGPath.parse(d).boundingBoxOfPath }
    private func close(_ a: CGRect, _ b: CGRect, _ eps: CGFloat = 0.01) -> Bool {
        abs(a.minX - b.minX) < eps && abs(a.minY - b.minY) < eps && abs(a.width - b.width) < eps && abs(a.height - b.height) < eps
    }

    @Test func linesAbsoluteAndRelative() {
        #expect(close(bounds("M10 20 L30 20 L30 50 Z"), CGRect(x: 10, y: 20, width: 20, height: 30)))
        #expect(close(bounds("m10 20 l20 0 0 30z"), CGRect(x: 10, y: 20, width: 20, height: 30)))
        #expect(close(bounds("M0 0H40V10h-40v-10"), CGRect(x: 0, y: 0, width: 40, height: 10)))
        // Implicit lineto after a moveto, and numbers run together.
        #expect(close(bounds("M1-1 5.5.5-2-3"), CGRect(x: -2, y: -3, width: 7.5, height: 3.5)))
        #expect(close(bounds("M1e1 0L2E1 1e-0"), CGRect(x: 10, y: 0, width: 10, height: 1)))
    }

    @Test func curvesAndReflections() {
        // A cubic from (0,0) to (100,0) with both controls at y=100 peaks at y=75.
        #expect(close(bounds("M0 0C0 100 100 100 100 0"), CGRect(x: 0, y: 0, width: 100, height: 75)))
        // S reflects the last control: a symmetric second hump below.
        #expect(close(bounds("M0 0c0 100 100 100 100 0s100-100 100 0"), CGRect(x: 0, y: -75, width: 200, height: 150)))
        // A quadratic with its control at y=100 peaks at y=50; T mirrors it below.
        #expect(close(bounds("M0 0Q50 100 100 0T200 0"), CGRect(x: 0, y: -50, width: 200, height: 100)))
    }

    @Test func arcsBecomeBeziers() {
        // A full circle of radius 50 drawn as two half arcs.
        let circle = bounds("M0 50A50 50 0 1 1 100 50A50 50 0 1 1 0 50z")
        #expect(close(circle, CGRect(x: 0, y: 0, width: 100, height: 100), 0.2))
        // Compact flags ("01") and a relative arc: a half circle above the chord.
        let half = bounds("M0 0a50 50 0 01100 0")
        #expect(close(half, CGRect(x: 0, y: -50, width: 100, height: 50), 0.2))
        // Radii too small to reach are scaled up: still a half circle.
        #expect(close(bounds("M0 0A1 1 0 0 1 100 0"), CGRect(x: 0, y: -50, width: 100, height: 50), 0.2))
    }

    @Test func malformedDataKeepsWhatWasDrawn() {
        #expect(close(bounds("M0 0L10 10L"), CGRect(x: 0, y: 0, width: 10, height: 10)))
        #expect(SVGPath.parse("").isEmpty)
        #expect(SVGPath.parse("12 34").isEmpty)
    }

    @Test func theBodyGeometryLoads() throws {
        let geo = BodyGeometry.shared
        for body in ["male", "female"] {
            for side in ["front", "back"] {
                let view = try #require(geo.view(body: body, side: side))
                #expect(view.viewBox.width > 600)
                // Every part sits inside its view box (a little slack for the outline's curves).
                for (slug, path) in view.parts {
                    let b = path.boundingBoxOfPath
                    #expect(!b.isEmpty, "\(body) \(side) \(slug)")
                    #expect(view.viewBox.insetBy(dx: -5, dy: -5).contains(b), "\(body) \(side) \(slug) \(b)")
                }
            }
        }
        #expect(geo.view(body: "male", side: "front")?.parts["chest"] != nil)
        #expect(geo.view(body: "other", side: "back")?.parts["gluteal"] != nil)   // falls back to male
    }
}
