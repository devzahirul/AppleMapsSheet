//
//  UIKitExampleViewController.swift
//  AppleMapsSheet
//
//  UIKit Example: Map Explorer with Place Search
//
//  This example demonstrates:
//  - Apple Maps integration (MKMapView)
//  - Tap on map to search nearby places
//  - Category filters (Gas Stations, Restaurants, etc.)
//  - Results shown in AppleMapsSheetViewController
//  - Navigation to place details
//

import UIKit
import MapKit
import AppleMapsSheet

// MARK: - Main View Controller

/// Example UIKit View Controller demonstrating AppleMapsSheetViewController
///
/// To run this example:
/// 1. Create a new iOS App project in Xcode (UIKit)
/// 2. Add AppleMapsSheet package
/// 3. Set this as your root view controller
class MapExplorerViewController: UIViewController {
    
    // MARK: - Properties
    
    private let mapView = MKMapView()
    private let sheetController = AppleMapsSheetViewController()
    private let categoryCollectionView: UICollectionView
    private let placesTableView = UITableView()
    
    private var places: [PlaceModel] = []
    private var selectedCategory: PlaceCategoryModel = .restaurant
    private var searchLocation: CLLocationCoordinate2D?
    private var isSearching = false
    
    // MARK: - Initialization
    
    init() {
        // Setup collection view layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        categoryCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSheet()
        setupMapView()
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Map View
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupSheet() {
        // Configure sheet
        sheetController.configuration = AppleMapsSheetConfiguration(
            snapPositions: [.bottom, .middle, .top],
            cornerRadius: 20,
            animation: .smooth,
            showScrollIndicator: true
        )
        sheetController.delegate = self
        
        // Add sheet as child
        addChild(sheetController)
        view.addSubview(sheetController.view)
        sheetController.didMove(toParent: self)
        
        // Layout sheet
        sheetController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sheetController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetController.view.topAnchor.constraint(equalTo: view.topAnchor),
            sheetController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Set content
        let contentVC = SheetContentViewController()
        contentVC.delegate = self
        sheetController.setContentViewController(contentVC)
        
        // Set initial position
        sheetController.setPosition(.middle, animated: false)
    }
    
    private func setupMapView() {
        // Set initial region (San Francisco)
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(region, animated: false)
        mapView.delegate = self
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        // Add long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - Map Gestures
    
    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        searchNearby(at: coordinate)
    }
    
    @objc private func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        searchNearby(at: coordinate)
    }
    
    // MARK: - Search
    
    private func searchNearby(at coordinate: CLLocationCoordinate2D) {
        searchLocation = coordinate
        
        // Add pin annotation
        let existingAnnotations = mapView.annotations.filter { $0 is SearchPinAnnotation }
        mapView.removeAnnotations(existingAnnotations)
        
        let pin = SearchPinAnnotation()
        pin.coordinate = coordinate
        pin.title = "Searching here"
        mapView.addAnnotation(pin)
        
        // Notify content
        if let contentVC = sheetController.children.first as? SheetContentViewController {
            contentVC.setSearching(true)
            contentVC.selectedCategory = selectedCategory
        }
        
        // Move sheet to middle
        sheetController.setPosition(.middle, animated: true)
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            let places = PlaceModel.mockPlaces(for: self.selectedCategory, near: coordinate)
            
            // Add place annotations
            let placeAnnotations = places.map { place -> PlaceAnnotation in
                let annotation = PlaceAnnotation()
                annotation.place = place
                annotation.coordinate = place.coordinate
                annotation.title = place.name
                return annotation
            }
            
            let oldPlaceAnnotations = self.mapView.annotations.filter { $0 is PlaceAnnotation }
            self.mapView.removeAnnotations(oldPlaceAnnotations)
            self.mapView.addAnnotations(placeAnnotations)
            
            // Update content
            if let contentVC = self.sheetController.children.first as? SheetContentViewController {
                contentVC.setPlaces(places)
                contentVC.setSearching(false)
            }
        }
    }
    
    private func showPlaceDetail(_ place: PlaceModel) {
        let detailVC = PlaceDetailViewController(place: place)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - MKMapViewDelegate

extension MapExplorerViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is SearchPinAnnotation {
            let identifier = "SearchPin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.markerTintColor = .systemRed
                view?.glyphImage = UIImage(systemName: "magnifyingglass")
            } else {
                view?.annotation = annotation
            }
            return view
        }
        
        if let placeAnnotation = annotation as? PlaceAnnotation {
            let identifier = "PlacePin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
                view?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                view?.annotation = annotation
            }
            view?.markerTintColor = placeAnnotation.place?.category.uiColor
            view?.glyphImage = UIImage(systemName: placeAnnotation.place?.category.icon ?? "mappin")
            return view
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let placeAnnotation = view.annotation as? PlaceAnnotation,
           let place = placeAnnotation.place {
            showPlaceDetail(place)
        }
    }
}

// MARK: - AppleMapsSheetViewControllerDelegate

extension MapExplorerViewController: AppleMapsSheetViewControllerDelegate {
    func sheetDidChangePosition(_ position: SheetPosition) {
        print("Sheet position changed to: \(position)")
    }
}

// MARK: - SheetContentViewControllerDelegate

extension MapExplorerViewController: SheetContentViewControllerDelegate {
    func didSelectCategory(_ category: PlaceCategoryModel) {
        selectedCategory = category
        if let location = searchLocation {
            searchNearby(at: location)
        }
    }
    
    func didSelectPlace(_ place: PlaceModel) {
        showPlaceDetail(place)
    }
}

// MARK: - Annotations

class SearchPinAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var title: String?
}

class PlaceAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var title: String?
    var place: PlaceModel?
}

// MARK: - Sheet Content View Controller

protocol SheetContentViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: PlaceCategoryModel)
    func didSelectPlace(_ place: PlaceModel)
}

class SheetContentViewController: UIViewController {
    
    weak var delegate: SheetContentViewControllerDelegate?
    
    var selectedCategory: PlaceCategoryModel = .restaurant {
        didSet {
            categoryCollectionView.reloadData()
        }
    }
    
    private var places: [PlaceModel] = []
    private var isSearching = false
    
    private let categoryCollectionView: UICollectionView
    private let tableView = UITableView()
    private let loadingView = UIActivityIndicatorView(style: .large)
    private let emptyLabel = UILabel()
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        categoryCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Category Collection View
        categoryCollectionView.translatesAutoresizingMaskIntoConstraints = false
        categoryCollectionView.backgroundColor = .clear
        categoryCollectionView.showsHorizontalScrollIndicator = false
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource = self
        categoryCollectionView.register(CategoryCell.self, forCellWithReuseIdentifier: "CategoryCell")
        view.addSubview(categoryCollectionView)
        
        // Table View
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 76, bottom: 0, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PlaceCell.self, forCellReuseIdentifier: "PlaceCell")
        view.addSubview(tableView)
        
        // Loading View
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.hidesWhenStopped = true
        view.addSubview(loadingView)
        
        // Empty Label
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "Tap on the map to search nearby places"
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            categoryCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            loadingView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 60),
            
            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 60),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        updateUI()
    }
    
    func setSearching(_ searching: Bool) {
        isSearching = searching
        updateUI()
    }
    
    func setPlaces(_ places: [PlaceModel]) {
        self.places = places
        tableView.reloadData()
        updateUI()
    }
    
    private func updateUI() {
        if isSearching {
            loadingView.startAnimating()
            tableView.isHidden = true
            emptyLabel.isHidden = true
        } else if places.isEmpty {
            loadingView.stopAnimating()
            tableView.isHidden = true
            emptyLabel.isHidden = false
        } else {
            loadingView.stopAnimating()
            tableView.isHidden = false
            emptyLabel.isHidden = true
        }
    }
}

// MARK: - UICollectionViewDelegate & DataSource

extension SheetContentViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return PlaceCategoryModel.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        let category = PlaceCategoryModel.allCases[indexPath.item]
        cell.configure(with: category, isSelected: category == selectedCategory)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = PlaceCategoryModel.allCases[indexPath.item]
        selectedCategory = category
        delegate?.didSelectCategory(category)
    }
}

// MARK: - UITableViewDelegate & DataSource

extension SheetContentViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for: indexPath) as! PlaceCell
        cell.configure(with: places[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.didSelectPlace(places[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - Category Cell

class CategoryCell: UICollectionViewCell {
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let containerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 20
        contentView.addSubview(containerView)
        
        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        containerView.addSubview(stack)
        
        iconImageView.contentMode = .scaleAspectFit
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 40),
            
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    func configure(with category: PlaceCategoryModel, isSelected: Bool) {
        iconImageView.image = UIImage(systemName: category.icon)
        iconImageView.tintColor = isSelected ? .white : .label
        titleLabel.text = category.rawValue
        titleLabel.textColor = isSelected ? .white : .label
        containerView.backgroundColor = isSelected ? category.uiColor : .systemGray5
    }
}

// MARK: - Place Cell

class PlaceCell: UITableViewCell {
    
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let ratingView = UIStackView()
    private let starImageView = UIImageView()
    private let ratingLabel = UILabel()
    private let distanceLabel = UILabel()
    private let statusLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        accessoryType = .disclosureIndicator
        
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.layer.cornerRadius = 28
        contentView.addSubview(iconContainer)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconImageView)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        contentView.addSubview(nameLabel)
        
        ratingView.translatesAutoresizingMaskIntoConstraints = false
        ratingView.axis = .horizontal
        ratingView.spacing = 4
        contentView.addSubview(ratingView)
        
        starImageView.image = UIImage(systemName: "star.fill")
        starImageView.tintColor = .systemYellow
        ratingView.addArrangedSubview(starImageView)
        
        ratingLabel.font = .systemFont(ofSize: 12)
        ratingLabel.textColor = .secondaryLabel
        ratingView.addArrangedSubview(ratingLabel)
        
        distanceLabel.font = .systemFont(ofSize: 12)
        distanceLabel.textColor = .secondaryLabel
        ratingView.addArrangedSubview(distanceLabel)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        contentView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 56),
            iconContainer.heightAnchor.constraint(equalToConstant: 56),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            ratingView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            ratingView.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: ratingView.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor)
        ])
    }
    
    func configure(with place: PlaceModel) {
        iconContainer.backgroundColor = place.category.uiColor.withAlphaComponent(0.15)
        iconImageView.image = UIImage(systemName: place.category.icon)
        iconImageView.tintColor = place.category.uiColor
        
        nameLabel.text = place.name
        ratingLabel.text = String(format: "%.1f (%d) •", place.rating, place.reviewCount)
        distanceLabel.text = place.distance
        
        statusLabel.text = place.isOpen ? "Open" : "Closed"
        statusLabel.textColor = place.isOpen ? .systemGreen : .systemRed
    }
}

// MARK: - Place Category Model

enum PlaceCategoryModel: String, CaseIterable {
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
    
    var uiColor: UIColor {
        switch self {
        case .restaurant: return .systemOrange
        case .gasStation: return .systemGreen
        case .cafe: return .systemBrown
        case .grocery: return .systemBlue
        case .pharmacy: return .systemRed
        case .parking: return .systemPurple
        }
    }
}

// MARK: - Place Model

struct PlaceModel {
    let id: String
    let name: String
    let category: PlaceCategoryModel
    let address: String
    let distance: String
    let rating: Double
    let reviewCount: Int
    let isOpen: Bool
    let coordinate: CLLocationCoordinate2D
    
    static func mockPlaces(for category: PlaceCategoryModel, near coordinate: CLLocationCoordinate2D) -> [PlaceModel] {
        let names: [PlaceCategoryModel: [String]] = [
            .restaurant: ["Golden Gate Grill", "Bay Area Bistro", "Pacific Plates", "Sunset Sushi", "Marina Mexican"],
            .gasStation: ["Shell Station", "Chevron", "76 Gas", "Arco", "Valero"],
            .cafe: ["Blue Bottle Coffee", "Philz Coffee", "Starbucks Reserve", "Peet's Coffee", "Ritual Coffee"],
            .grocery: ["Whole Foods", "Trader Joe's", "Safeway", "Gus's Market", "Rainbow Grocery"],
            .pharmacy: ["Walgreens", "CVS Pharmacy", "Rite Aid", "Costco Pharmacy", "Target Pharmacy"],
            .parking: ["City Parking Garage", "Union Square Parking", "Moscone Parking", "SFMTA Lot", "Impark"]
        ]
        
        return (names[category] ?? []).enumerated().map { index, name in
            PlaceModel(
                id: UUID().uuidString,
                name: name,
                category: category,
                address: "\(100 + index * 50) Market St, San Francisco",
                distance: String(format: "%.1f mi", 0.2 + Double(index) * 0.3),
                rating: 4.0 + Double.random(in: 0...1),
                reviewCount: Int.random(in: 20...500),
                isOpen: Bool.random(),
                coordinate: CLLocationCoordinate2D(
                    latitude: coordinate.latitude + Double.random(in: -0.01...0.01),
                    longitude: coordinate.longitude + Double.random(in: -0.01...0.01)
                )
            )
        }
    }
}

// MARK: - Place Detail View Controller

class PlaceDetailViewController: UIViewController {
    
    private let place: PlaceModel
    
    init(place: PlaceModel) {
        self.place = place
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = place.name
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let contentStack = UIStackView()
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .leading
        scrollView.addSubview(contentStack)
        
        // Header
        let headerView = UIView()
        headerView.backgroundColor = place.category.uiColor.withAlphaComponent(0.2)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconImage = UIImageView(image: UIImage(systemName: place.category.icon))
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        iconImage.tintColor = place.category.uiColor
        iconImage.contentMode = .scaleAspectFit
        headerView.addSubview(iconImage)
        
        contentStack.addArrangedSubview(headerView)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = place.name
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        contentStack.addArrangedSubview(titleLabel)
        
        // Category
        let categoryLabel = UILabel()
        categoryLabel.text = place.category.rawValue
        categoryLabel.font = .systemFont(ofSize: 16)
        categoryLabel.textColor = place.category.uiColor
        contentStack.addArrangedSubview(categoryLabel)
        
        // Rating
        let ratingLabel = UILabel()
        ratingLabel.text = String(format: "⭐️ %.1f (%d reviews)", place.rating, place.reviewCount)
        ratingLabel.font = .systemFont(ofSize: 14)
        ratingLabel.textColor = .secondaryLabel
        contentStack.addArrangedSubview(ratingLabel)
        
        // Address
        let addressLabel = UILabel()
        addressLabel.text = "📍 \(place.address)"
        addressLabel.font = .systemFont(ofSize: 14)
        addressLabel.textColor = .secondaryLabel
        contentStack.addArrangedSubview(addressLabel)
        
        // Distance
        let distanceLabel = UILabel()
        distanceLabel.text = "🚶 \(place.distance) away"
        distanceLabel.font = .systemFont(ofSize: 14)
        distanceLabel.textColor = .secondaryLabel
        contentStack.addArrangedSubview(distanceLabel)
        
        // Status
        let statusLabel = UILabel()
        statusLabel.text = place.isOpen ? "✅ Open Now" : "❌ Closed"
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = place.isOpen ? .systemGreen : .systemRed
        contentStack.addArrangedSubview(statusLabel)
        
        // Buttons
        let buttonsStack = UIStackView()
        buttonsStack.axis = .horizontal
        buttonsStack.distribution = .fillEqually
        buttonsStack.spacing = 16
        
        let directionsButton = createActionButton(title: "Directions", icon: "arrow.triangle.turn.up.right.diamond.fill", color: .systemBlue)
        let callButton = createActionButton(title: "Call", icon: "phone.fill", color: .systemGreen)
        let shareButton = createActionButton(title: "Share", icon: "square.and.arrow.up", color: .systemOrange)
        
        buttonsStack.addArrangedSubview(directionsButton)
        buttonsStack.addArrangedSubview(callButton)
        buttonsStack.addArrangedSubview(shareButton)
        
        contentStack.addArrangedSubview(buttonsStack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            headerView.heightAnchor.constraint(equalToConstant: 200),
            headerView.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            
            iconImage.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            iconImage.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            iconImage.widthAnchor.constraint(equalToConstant: 80),
            iconImage.heightAnchor.constraint(equalToConstant: 80),
            
            buttonsStack.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ])
    }
    
    private func createActionButton(title: String, icon: String, color: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 12
        
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        container.addSubview(stack)
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12)
        label.textColor = .label
        
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            container.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        return container
    }
}
