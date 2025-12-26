//
//  SwiftUIExampleApp.swift
//  AppleMapsSheet
//
//  SwiftUI Example: Map Explorer with Place Search
//
//  This example demonstrates:
//  - Apple Maps integration with current location
//  - Tap on map to search nearby places
//  - Category filters (Gas Stations, Restaurants, etc.)
//  - Results shown in AppleMapsSheetView
//  - Navigation to place details
//

import SwiftUI
import MapKit
import CoreLocation
import Combine
import AppleMapsSheet

// MARK: - Location Manager

/// Observable location manager for tracking user's current location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                self.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - CLLocationCoordinate2D Extension

extension CLLocationCoordinate2D {
    /// Calculate distance to another coordinate in meters
    func distance(to other: CLLocationCoordinate2D) -> Double {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return from.distance(from: to)
    }
}

// MARK: - Example App Entry Point

/// Example SwiftUI App demonstrating AppleMapsSheetView
///
/// To run this example:
/// 1. Create a new iOS App project in Xcode
/// 2. Add AppleMapsSheet package
/// 3. Replace the App file content with this code
@main
struct MapExplorerApp: App {
    var body: some Scene {
        WindowGroup {
            MapExplorerView()
        }
    }
}

// MARK: - Main View

/// Map Explorer View with interactive bottom sheet
struct MapExplorerView: View {
    
    // MARK: - State
    
    @StateObject private var locationManager = LocationManager()
    @State private var sheetPosition: SheetPosition = .middle
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedCategory: PlaceCategory = .restaurant
    // Static places array - like ExploreView's services
    @State private var places: [Place] = Place.mockPlaces(for: .restaurant, near: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
    @State private var selectedPlace: Place?
    @State private var showPlaceDetail = false
    @State private var hasCenteredOnUser = false
    // Search counter - incrementing this forces AppleMapsSheetView to recreate with fresh scroll offset
    @State private var searchId: Int = 0
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map
                mapView
                
                // Current location button
                VStack {
                    HStack {
                        Spacer()
                        currentLocationButton
                            .padding(.trailing, 16)
                            .padding(.top, 60)
                    }
                }
                
                // Bottom Sheet - .id(searchId) forces recreation to reset scroll offset
                AppleMapsSheetView(
                    position: $sheetPosition,
                    configuration: AppleMapsSheetConfiguration(
                        snapPositions: [.bottom, .custom(heightRatio: 0.5), .top],
                        animation: .smooth
                    )
                ) {
                    sheetContent
                }
                .id(searchId)
                
                // Navigation to detail
                NavigationLink(
                    destination: PlaceDetailView(place: selectedPlace ?? Place.sample),
                    isActive: $showPlaceDetail
                ) {
                    EmptyView()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                locationManager.requestPermission()
            }
            .onReceive(locationManager.$userLocation) { newLocation in
                // Center map on user location the first time
                if let location = newLocation, !hasCenteredOnUser {
                    region.center = location
                    hasCenteredOnUser = true
                }
            }
        }
    }
    
    // MARK: - Current Location Button
    
    private var currentLocationButton: some View {
        Button(action: {
            if let location = locationManager.userLocation {
                withAnimation {
                    region.center = location
                }
            }
        }) {
            Image(systemName: "location.fill")
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color(.systemBackground))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        Map(
            coordinateRegion: $region,
            showsUserLocation: true,
            annotationItems: places
        ) { place in
            MapAnnotation(coordinate: place.coordinate) {
                PlaceAnnotationView(place: place) {
                    selectedPlace = place
                    showPlaceDetail = true
                }
            }
        }
        .ignoresSafeArea()
        .onTapGesture {
            // Search at current map center using Apple Maps API
            searchPlaces(for: selectedCategory, near: region.center)
        }
    }
    
    // MARK: - Sheet Content
    
    private var sheetContent: some View {
        VStack(spacing: 0) {
            // Category Pills - matches ExploreView filter pills pattern
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PlaceCategory.allCases, id: \.self) { category in
                        CategoryPillButton(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                            searchPlaces(for: category, near: region.center)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
            
            // Places List - matches ExploreView service list pattern
            VStack(spacing: 0) {
                ForEach(places) { place in
                    PlaceRowView(place: place) {
                        selectedPlace = place
                        showPlaceDetail = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Search Function
    
    private func searchPlaces(for category: PlaceCategory, near coordinate: CLLocationCoordinate2D) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = category.searchQuery
        request.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                // Fallback to mock data if search fails
                places = Place.mockPlaces(for: category, near: coordinate)
                searchId += 1
                sheetPosition = .top
                return
            }
            
            // Convert MKMapItems to Place models
            places = response.mapItems.prefix(10).map { item in
                let distance = coordinate.distance(to: item.placemark.coordinate)
                let distanceString = distance < 1609.34 
                    ? String(format: "%.1f mi", distance / 1609.34)
                    : String(format: "%.0f mi", distance / 1609.34)
                
                return Place(
                    name: item.name ?? "Unknown",
                    category: category,
                    address: item.placemark.title ?? "",
                    distance: distanceString,
                    rating: Double.random(in: 3.5...5.0),
                    reviewCount: Int.random(in: 10...500),
                    isOpen: item.isCurrentLocation ? true : Bool.random(),
                    coordinate: item.placemark.coordinate,
                    imageURL: nil
                )
            }
            
            // Increment searchId to force AppleMapsSheetView recreation (resets scroll offset)
            searchId += 1
            
            // Expand sheet to show results
            sheetPosition = .top
        }
    }
}

// MARK: - Place Category

enum PlaceCategory: String, CaseIterable {
    case restaurant = "Restaurants"
    case gasStation = "Gas Stations"
    case cafe = "Cafes"
    case grocery = "Grocery"
    case pharmacy = "Pharmacy"
    case parking = "Parking"
    
    var icon: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .gasStation: return "fuelpump.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .grocery: return "cart.fill"
        case .pharmacy: return "cross.case.fill"
        case .parking: return "p.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .restaurant: return .orange
        case .gasStation: return .green
        case .cafe: return Color(red: 0.6, green: 0.4, blue: 0.2) // Brown color for iOS 14+
        case .grocery: return .blue
        case .pharmacy: return .red
        case .parking: return .purple
        }
    }
    
    /// Search query for MKLocalSearch
    var searchQuery: String {
        switch self {
        case .restaurant: return "restaurant"
        case .gasStation: return "gas station"
        case .cafe: return "cafe coffee"
        case .grocery: return "grocery store supermarket"
        case .pharmacy: return "pharmacy"
        case .parking: return "parking"
        }
    }
}

// MARK: - Place Model

struct Place: Identifiable {
    let id = UUID()
    let name: String
    let category: PlaceCategory
    let address: String
    let distance: String
    let rating: Double
    let reviewCount: Int
    let isOpen: Bool
    let coordinate: CLLocationCoordinate2D
    let imageURL: String?
    
    static var sample: Place {
        Place(
            name: "Sample Place",
            category: .restaurant,
            address: "123 Main St",
            distance: "0.5 mi",
            rating: 4.5,
            reviewCount: 120,
            isOpen: true,
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            imageURL: nil
        )
    }
    
    static func mockPlaces(for category: PlaceCategory, near coordinate: CLLocationCoordinate2D) -> [Place] {
        let names: [PlaceCategory: [String]] = [
            .restaurant: ["Golden Gate Grill", "Bay Area Bistro", "Pacific Plates", "Sunset Sushi", "Marina Mexican"],
            .gasStation: ["Shell Station", "Chevron", "76 Gas", "Arco", "Valero"],
            .cafe: ["Blue Bottle Coffee", "Philz Coffee", "Starbucks Reserve", "Peet's Coffee", "Ritual Coffee"],
            .grocery: ["Whole Foods", "Trader Joe's", "Safeway", "Gus's Market", "Rainbow Grocery"],
            .pharmacy: ["Walgreens", "CVS Pharmacy", "Rite Aid", "Costco Pharmacy", "Target Pharmacy"],
            .parking: ["City Parking Garage", "Union Square Parking", "Moscone Parking", "SFMTA Lot", "Impark"]
        ]
        
        return (names[category] ?? []).enumerated().map { index, name in
            Place(
                name: name,
                category: category,
                address: "\(100 + index * 50) Market St, San Francisco",
                distance: "\(0.2 + Double(index) * 0.3) mi",
                rating: 4.0 + Double.random(in: 0...1),
                reviewCount: Int.random(in: 20...500),
                isOpen: Bool.random(),
                coordinate: CLLocationCoordinate2D(
                    latitude: coordinate.latitude + Double.random(in: -0.01...0.01),
                    longitude: coordinate.longitude + Double.random(in: -0.01...0.01)
                ),
                imageURL: nil
            )
        }
    }
}

// MARK: - Category Pill Button

struct CategoryPillButton: View {
    let category: PlaceCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : Color(.systemGray5))
            )
        }
    }
}

// MARK: - Place Row View

struct PlaceRowView: View {
    let place: Place
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(place.category.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: place.category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(place.category.color)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        // Rating
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", place.rating))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("(\(place.reviewCount))")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        // Distance
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(place.distance)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    // Status
                    Text(place.isOpen ? "Open" : "Closed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(place.isOpen ? .green : .red)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Place Annotation View

struct PlaceAnnotationView: View {
    let place: Place
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(place.category.color)
                        .frame(width: 36, height: 36)
                    Image(systemName: place.category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                // Pin tail
                Triangle()
                    .fill(place.category.color)
                    .frame(width: 12, height: 8)
                    .rotationEffect(.degrees(180))
            }
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Place Detail View

struct PlaceDetailView: View {
    let place: Place
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Image
                ZStack {
                    Rectangle()
                        .fill(place.category.color.opacity(0.2))
                        .frame(height: 200)
                    
                    Image(systemName: place.category.icon)
                        .font(.system(size: 80))
                        .foregroundColor(place.category.color)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(place.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Category & Status
                    HStack {
                        Label(place.category.rawValue, systemImage: place.category.icon)
                            .foregroundColor(place.category.color)
                        
                        Spacer()
                        
                        Text(place.isOpen ? "Open Now" : "Closed")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(place.isOpen ? .green : .red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(place.isOpen ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            )
                    }
                    
                    // Rating
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(place.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                        Text(String(format: "%.1f", place.rating))
                            .fontWeight(.semibold)
                        Text("(\(place.reviewCount) reviews)")
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Address
                    Label(place.address, systemImage: "mappin.and.ellipse")
                        .foregroundColor(.secondary)
                    
                    // Distance
                    Label("\(place.distance) away", systemImage: "figure.walk")
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        ActionButton(title: "Directions", icon: "arrow.triangle.turn.up.right.diamond.fill", color: .blue) {}
                        ActionButton(title: "Call", icon: "phone.fill", color: .green) {}
                        ActionButton(title: "Share", icon: "square.and.arrow.up", color: .orange) {}
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview {
    MapExplorerView()
}
