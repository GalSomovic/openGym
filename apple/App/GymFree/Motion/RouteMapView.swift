import MapKit
import OpenGymCore
import SwiftUI

/// A saved route on a map: each stretch as a line (a pause leaves a gap), start and finish
/// marked, framed to fit. Static in a list; the full-screen one can be moved and zoomed.
struct RouteMapView: View {
    let segments: [[TrackPoint]]
    var interactive = false

    var body: some View {
        Map(initialPosition: .automatic, interactionModes: interactive ? .all : []) {
            RouteLines(segments: segments)
            if let first = segments.first(where: { !$0.isEmpty })?.first {
                Annotation("Start", coordinate: first.coordinate, anchor: .center) {
                    Circle().fill(.green).stroke(.white, lineWidth: 2).frame(width: 14, height: 14)
                }
            }
            if let last = segments.last(where: { !$0.isEmpty })?.last {
                Annotation("Finish", coordinate: last.coordinate, anchor: .center) {
                    Circle().fill(.red).stroke(.white, lineWidth: 2).frame(width: 14, height: 14)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .accessibilityElement()
        .accessibilityLabel(Text("Route map"))
        .accessibilityIdentifier("route.map")
    }
}

/// The route's stretches as lines.
struct RouteLines: MapContent {
    let segments: [[TrackPoint]]

    var body: some MapContent {
        ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
            if seg.count > 1 {
                MapPolyline(coordinates: seg.map(\.coordinate))
                    .stroke(Color("AccentColor"), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

/// A saved activity's route, loaded from its file; nothing when there is none.
struct SavedRouteMap: View {
    let key: String
    @State private var route: RouteStore.Route?
    @State private var loaded = false
    @State private var expanded = false

    var body: some View {
        Group {
            if let route, route.segments.contains(where: { $0.count > 1 }) {
                RouteMapView(segments: route.segments)
                    .frame(height: 240)
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(alignment: .topTrailing) {
                        Button { expanded = true } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .padding(8)
                                .background(.regularMaterial, in: .circle)
                        }
                        .padding(8)
                        .accessibilityLabel(Text("Show the map full screen"))
                    }
                    .fullScreenCover(isPresented: $expanded) {
                        NavigationStack {
                            RouteMapView(segments: route.segments, interactive: true)
                                .ignoresSafeArea(edges: .bottom)
                                .navigationTitle("Route")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) { Button("Done") { expanded = false } }
                                }
                        }
                    }
            } else if loaded {
                Label("No route was recorded.", systemImage: "location.slash").foregroundStyle(.secondary)
            } else {
                // Something to hang the loading task on: an empty view never runs it.
                Color.clear.frame(height: 240)
            }
        }
        .task(id: key) {
            let store = RouteStore.standard
            route = await Task.detached { store.load(key) }.value
            loaded = true
        }
    }
}
