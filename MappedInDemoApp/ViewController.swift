//
//  ViewController.swift
//  MappedInDemoApp
//
//  Created by muhammed.nadeem.m.a on 10/06/26.
//

import UIKit
import Mappedin

class ViewController: UIViewController {

    let mapView = MapView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapViewLayout()
        loadMap()
    }

    private func setupMapViewLayout() {
        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func loadMap() {
        let grocery = GetMapDataWithCredentialsOptions(
            key: "mik_yeBk0Vf0nNJtpesfu560e07e5",
            secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022",
            mapId: "6679882a8298d5000b85ee89"
        )
        mapView.getMapData(options: grocery) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(_):
                self.mapView.show3dMap(options: Show3DMapOptions()) { mapResult in
                    if case .success = mapResult {
                        self.onMapReady()
                    }
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func onMapReady() {
        renderSpaces()
        renderMapObjects()
        renderPOIs()
        renderAnnotations()
        testNavigation()
        enableClickEvents()
    }

    func enableClickEvents() {
        // Interactive
        mapView.mapData.getByType(.space) { [weak self] (result: Result<[Space], Error>) in
            if case .success(let spaces) = result {
                spaces.forEach { space in
                    self?.mapView.updateState(space: space, state: GeometryUpdateState(interactive: true))
                }
            }
        }
        // Click Events
        mapView.on(Events.click) { [weak self] clickPayload in
            guard let self, let click = clickPayload else { return }
            if let value = clickPayload?.toJson() {
                print(value)
            }
            self.handleClick(click)
        }
    }

    func renderSpaces() {
        mapView.mapData.getByType(.space) { [weak self] (result: Result<[Space], Error>) in
            switch result {
            case .success(let spaces):
                spaces.forEach { space in
                    dump(space)
                    guard !space.name.isEmpty else { return }
                    let appearance = LabelAppearance(icon: space.images.first?.url ?? "")
                    self?.mapView.labels.add(target: space, text: space.name,  options: AddLabelOptions(labelAppearance: appearance, interactive: true))
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    func renderMapObjects() {
        mapView.mapData.getByType(.mapObject) { [weak self] (result: Result<[MapObject], Error>) in
            switch result {
            case .success(let objects):
                objects.forEach { obj in
                    guard !obj.name.isEmpty else { return }
                    let appearance = LabelAppearance(icon: obj.images.first?.url ?? "")
                    self?.mapView.labels.add(target: obj, text: obj.name, options: AddLabelOptions(labelAppearance: appearance, interactive: true))
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    func renderPOIs() {
        mapView.mapData.getByType(.pointOfInterest) { (result: Result<[PointOfInterest], Error>) in
            switch result {
            case .success(let pois):
                pois.forEach { poi in
                    guard !poi.name.isEmpty else { return }
                    self.mapView.labels.add(
                        target: poi,
                        text: poi.name
                    )
                }
            case .failure(let error):
                print("Error mapping POI's: \(error.localizedDescription)")
            }
        }
    }

    func renderAnnotations() {
        mapView.mapData.getByType(.annotation) { [weak self] (result: Result<[Annotation], Error>) in
            guard let self = self else { return }
            if case .success(let annotations) = result {
                let opts = AddMarkerOptions(
                    interactive: .True,
                    placement: .single(.center),
                    rank: .tier(.high)
                )
                // Add markers for all annotations that have icons
                annotations.forEach { annotation in
                    let iconUrl = annotation.icon?.url ?? ""
                    let markerHtml = """
                    <div class='mappedin-annotation-marker'>
                        <div style='width: 30px; height: 30px'>
                        <img src='\(iconUrl)' alt='\(annotation.name)' width='30' height='30' />
                        </div>
                    </div>
                    """
                    self.mapView.markers.add(target: annotation, html: markerHtml, options: opts) { _ in }
                }
            }
        }
    }

}

extension ViewController {

    private func handleClick(_ clickPayload: ClickPayload) {
        var message = ""
        // Use the map name as the title (from floors)
        message.append("Floor Name: \(clickPayload.floors?.first?.name ?? "Map Click")\n")
        // If a label was clicked, add its text to the message
        if let labels = clickPayload.labels, !labels.isEmpty {
            message.append("Label Clicked: ")
            message.append(labels.first?.text ?? "")
            message.append("\n")
        }
        // If a space was clicked, add its location name to the message
        if let spaces = clickPayload.spaces, !spaces.isEmpty {
            message.append("Space clicked: ")
            message.append(spaces.first?.name ?? "")
            message.append("\n")
        }

        // If a path was clicked, add it to the message
        if let paths = clickPayload.paths, !paths.isEmpty {
            message.append("You clicked a path.\n")
        }
        // Add the coordinates clicked to the message
        message.append("Coordinate Clicked: \nLatitude: ")
        message.append(clickPayload.coordinate.latitude.description)
        message.append("\nLongitude: ")
        message.append(clickPayload.coordinate.longitude.description)
        print("============")
        print(message)
        print("============")
    }
}

// MARK: NAVIGATION PATH
// MARK: ITERATION 1 (SINGLE POINT NAVIGATION)
extension ViewController {

//    func testNavigation() {
//        mapView.mapData.getByType(.mapObject) { (result: Result<[MapObject], Error>) in
//            guard case .success(let objects) = result else {
//                return
//            }
//            guard let startObject = objects.first(where: { $0.name == "Bread" }),
//                  let endObject = objects.first(where: { $0.name == "Chocolate bar" }) else {
//                print("Objects not found")
//                return
//            }
//
//            print("START:", startObject.name)
//            print("END:", endObject.name)
//
//            // start and stop
//            let start: NavigationTarget = .mapObject(startObject)
//            let destination: NavigationTarget = .mapObject(endObject)
//
//            self.mapView.mapData.getDirections(from: start, to: destination) { [weak self] result in
//                guard let self else { return }
//                switch result {
//                case .success(let directions):
//                    guard let directions else {
//                        print("No directions")
//                        return
//                    }
//
//                    let pathOption = AddPathOptions(
//                        accentColor: "#ffffff",
//                        animateArrowsOnPath: true,
//                        animateDrawing: true,
//                        color: "#4b90e2",
//                        displayArrowsOnPath: true
//                    )
//
//                    let options = NavigationOptions(pathOptions: pathOption)
//                    self.mapView.navigation.draw(directions: directions, options: options) { drawResult in
//                        print("Path Drawn: \(drawResult)")
//                    }
//                case .failure(let error):
//                    print(error)
//                }
//            }
//        }
//    }

//    func testNavigation() {
//
//        let shoppingList = [
//            "Mop",
//            "Lotion",
//            "Sugar",
//        ]
//
//        mapView.mapData.getByType(.mapObject) {
//            (result: Result<[MapObject], Error>) in
//
//            guard case .success(let objects) = result else {
//                return
//            }
//
//            let resolvedObjects = shoppingList.compactMap { item in
//                objects.first {
//                    $0.name.caseInsensitiveCompare(item) == .orderedSame
//                }
//            }
//
//            guard resolvedObjects.count == shoppingList.count else {
//                print("Some products could not be resolved")
//                return
//            }
//
//            guard let startObject = resolvedObjects.first else {
//                return
//            }
//
//            let startTarget: NavigationTarget =
//                .mapObject(startObject)
//
//            let destinations: [MultiDestinationTarget] =
//                resolvedObjects
//                    .dropFirst()
//                    .map {
//                        .single(.mapObject($0))
//                    }
//
//            self.mapView.mapData.getDirectionsMultiDestination(
//                from: startTarget,
//                to: destinations
//            ) { [weak self] result in
//
//                guard let self else { return }
//
//                switch result {
//
//                case .success(let directionsList):
//
//                    let pathOption = AddPathOptions(
//                        accentColor: "#ffffff",
//                        animateArrowsOnPath: true,
//                        animateDrawing: true,
//                        color: "#4b90e2",
//                        displayArrowsOnPath: true
//                    )
//
//                    let options = NavigationOptions(
//                        pathOptions: pathOption
//                    )
//
//                    guard let directionsList, !directionsList.isEmpty else {
//                        print("No Directions")
//                        return
//                    }
//
//                    self.mapView.navigation.draw(
//                        directions: directionsList,
//                        options: options
//                    ) { drawResult in
//
//                        print("Path Drawn:", drawResult)
//                    }
//
//                case .failure(let error):
//                    print(error)
//                }
//            }
//        }
//    }

}

// MARK: ITERATION 2 (MULTIPLE DESTINATION NAVIGATION)
extension ViewController {

    func navigationTarget(for item: RouteItem) -> NavigationTarget {
        switch item {
        case .mapObject(let object):
            return .mapObject(object)
        case .space(let space):
            return .space(space)
        }
    }

    func distance(from: RouteItem, to: RouteItem) async -> Double {
        await withCheckedContinuation { continuation in
            mapView.mapData.getDistance(from: navigationTarget(for: from), to: navigationTarget(for: to)) { result in
                switch result {
                case .success(let distance):
                    continuation.resume(
                        returning: distance ?? .greatestFiniteMagnitude
                    )
                case .failure:
                    continuation.resume(
                        returning: .greatestFiniteMagnitude
                    )
                }
            }
        }
    }

    func optimizeRoute(items: [RouteItem]) async -> [RouteItem] {

        guard items.count > 1 else {
            return items
        }

        var optimized: [RouteItem] = []

        var remaining = items

        let first = remaining.removeFirst()

        optimized.append(first)

        var current = first

        while !remaining.isEmpty {

            var nearestIndex = 0
            var nearestDistance = Double.greatestFiniteMagnitude

            for (index, candidate) in remaining.enumerated() {

                let distance = await distance(
                    from: current,
                    to: candidate
                )

                if distance < nearestDistance {

                    nearestDistance = distance
                    nearestIndex = index
                }
            }

            let next = remaining.remove(at: nearestIndex)

            optimized.append(next)

            current = next
        }

        return optimized
    }

    func testNavigation() {

        let shoppingList = [
            "Mop",
            "Lotion",
            "Sugar",
            "☕️ Cafe"
        ]

        mapView.mapData.getByType(.mapObject) { [weak self] (objectResult: Result<[MapObject], Error>) in

            guard let self else { return }

            guard case .success(let objects) = objectResult else {
                return
            }

            self.mapView.mapData.getByType(.space) { (spaceResult: Result<[Space], Error>) in

                guard case .success(let spaces) = spaceResult else {
                    return
                }

                Task {

                    var resolvedItems: [RouteItem] = []

                    shoppingList.forEach { itemName in

                        if let object = objects.first(where: {
                            $0.name.caseInsensitiveCompare(itemName) == .orderedSame
                        }) {

                            resolvedItems.append(
                                .mapObject(object)
                            )

                            return
                        }

                        if let space = spaces.first(where: {
                            $0.name.caseInsensitiveCompare(itemName) == .orderedSame
                        }) {

                            resolvedItems.append(
                                .space(space)
                            )

                            return
                        }

                        print("Could not resolve:", itemName)
                    }

                    let optimizedItems = await self.optimizeRoute(
                        items: resolvedItems
                    )

                    print("===== OPTIMIZED =====")

                    optimizedItems.forEach {
                        print($0.name)
                    }

                    // First Item
                    guard let startItem = optimizedItems.first else {
                        return
                    }

                    let startTarget = self.navigationTarget(for: startItem)

                    let destinations: [MultiDestinationTarget] =
                        optimizedItems
                            .dropFirst()
                            .map {
                                .single(
                                    self.navigationTarget(for: $0)
                                )
                            }

                    self.mapView.mapData.getDirectionsMultiDestination(
                        from: startTarget,
                        to: destinations
                    ) { result in

                        switch result {

                        case .success(let directions):

                            let pathOption = AddPathOptions(
                                accentColor: "#ffffff",
                                animateArrowsOnPath: true,
                                animateDrawing: true,
                                color: "#4b90e2",
                                displayArrowsOnPath: true
                            )

                            let options = NavigationOptions(
                                pathOptions: pathOption
                            )

                            guard let directions, !directions.isEmpty else {
                                print("No directions to draw")
                                return
                            }

                            self.mapView.navigation.draw(
                                directions: directions,
                                options: options
                            ) { drawResult in

                                print(
                                    "Path Drawn:",
                                    drawResult
                                )
                            }

                        case .failure(let error):
                            print(error)
                        }
                    }
                }
            }
        }
    }

}
