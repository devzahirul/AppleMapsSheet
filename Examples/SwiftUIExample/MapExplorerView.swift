//
//  SwiftUIExampleApp.swift
//  AppleMapsSheet
//
//  SwiftUI Example: Map Explorer with Place Search
//
//  This example demonstrates:
//  - Apple Maps integration
//  - Tap on map to search nearby places
//  - Category filters (Gas Stations, Restaurants, etc.)
//  - Results shown in AppleMapsSheetView
//  - Navigation to place details
//

import SwiftUI
import MapKit
import AppleMapsSheet

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
    
    @State private var sheetPosition: SheetPosition = .middle
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var searchLocation: CLLocationCoordinate2D?
    @State private var selectedCategory: PlaceCategory = .restaurant
    @State private var places: [Place] = []
    @State private var isSearching = false
    @State private var selectedPlace: Place?
    @State private var showPlaceDetail = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map
                mapView
                
                // Search indicator
                if let location = searchLocation {
                    searchPinOverlay(at: location)
                }
                
                // Bottom Sheet
                AppleMapsSheetView(
                    position: $sheetPosition,
                    configuration: AppleMapsSheetConfiguration(
                        snapPositions: [.bottom, .middle, .top],
                        animation: .smooth
                    )
                ) {
                    sheetContent
                }
                
                // Navigation to detail
                NavigationLink(
                    destination: PlaceDetailView(place: selectedPlace ?? Place.sample),
                    isActive: $showPlaceDetail
                ) {
                    EmptyView()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: places) { place in
            MapAnnotation(coordinate: place.coordinate) {
                PlaceAnnotationView(place: place) {
                    selectedPlace = place
                    showPlaceDetail = true
                }
            }
        }
        .ignoresSafeArea()
        .onTapGesture { location in
            // Convert tap to coordinate
            let coordinate = region.center // Simplified - in real app use gesture location
            searchNearby(at: coordinate)
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onEnded { value in
                    // Long press to place search pin
                    searchNearby(at: region.center)
                }
        )
    }
    
    // MARK: - Search Pin Overlay
    
    private func searchPinOverlay(at location: CLLocationCoordinate2D) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text("Searching here")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
                Spacer()
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Sheet Content
    
    private var sheetContent: some View {
        VStack(spacing: 0) {
            // Category Pills
            categoryPills
                .padding(.bottom, 16)
            
            // Search status or results
            if isSearching {
                loadingView
            } else if places.isEmpty {
                emptyStateView
            } else {
                placesList
            }
        }
    }
    
    // MARK: - Category Pills
    
    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    CategoryPillButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        if let location = searchLocation {
                            searchNearby(at: location)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching nearby...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Tap on the map to search nearby places")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Places List
    
    private var placesList: some View {
        LazyVStack(spacing: 0) {
            ForEach(places) { place in
                PlaceRowView(place: place) {
                    selectedPlace = place
                    showPlaceDetail = true
                }
                Divider()
                    .padding(.leading, 76)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Search Function
    
    private func searchNearby(at coordinate: CLLocationCoordinate2D) {
        searchLocation = coordinate
        isSearching = true
        sheetPosition = .middle
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            places = Place.mockPlaces(for: selectedCategory, near: coordinate)
            isSearching = false
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
        case .cafe: return .brown
        case .grocery: return .blue
        case .pharmacy: return .red
        case .parking: return .purple
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
