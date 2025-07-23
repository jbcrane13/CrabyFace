//
//  MapAnnotationViews.swift
//  JubileeMobileBay
//
//  Custom annotation views for map features with clustering support
//

import SwiftUI
import MapKit

// MARK: - Camera Annotation View

class CameraAnnotationView: MKAnnotationView {
    static let identifier = MKMapView.AnnotationIdentifier.camera
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        canShowCallout = true
        displayPriority = .required
        clusteringIdentifier = "camera_cluster"
        
        // Set up the icon
        image = UIImage(systemName: "video.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        )
        
        // Configure appearance based on online status
        if let cameraAnnotation = annotation as? CameraAnnotation {
            if cameraAnnotation.isOnline {
                tintColor = .systemBlue
            } else {
                tintColor = .systemGray
            }
        }
        
        // Add right callout accessory
        let button = UIButton(type: .detailDisclosure)
        rightCalloutAccessoryView = button
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        image = nil
        tintColor = nil
    }
}

// MARK: - Weather Station Annotation View

class WeatherStationAnnotationView: MKAnnotationView {
    static let identifier = MKMapView.AnnotationIdentifier.weatherStation
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        canShowCallout = true
        displayPriority = .defaultHigh
        clusteringIdentifier = "station_cluster"
        
        // Set up the icon
        image = UIImage(systemName: "cloud.sun.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        )
        tintColor = .systemOrange
        
        // Add left callout accessory showing temperature
        if let stationAnnotation = annotation as? WeatherStationAnnotation,
           let temp = stationAnnotation.currentTemperature {
            let tempLabel = UILabel()
            tempLabel.text = "\(Int(temp))°"
            tempLabel.font = .systemFont(ofSize: 14, weight: .medium)
            tempLabel.textColor = .systemOrange
            leftCalloutAccessoryView = tempLabel
        }
        
        // Add right callout accessory
        let button = UIButton(type: .detailDisclosure)
        rightCalloutAccessoryView = button
    }
}

// MARK: - Jubilee Report Annotation View

class JubileeReportAnnotationView: MKAnnotationView {
    static let identifier = MKMapView.AnnotationIdentifier.jubileeReport
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        canShowCallout = true
        displayPriority = .defaultHigh
        clusteringIdentifier = "report_cluster"
        
        // Custom view for jubilee reports
        if let reportAnnotation = annotation as? JubileeReportAnnotation {
            frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            
            // Create custom view
            let containerView = UIView(frame: bounds)
            containerView.backgroundColor = UIColor(named: reportAnnotation.intensity.colorName) ?? .systemGray
            containerView.layer.cornerRadius = 20
            containerView.layer.borderWidth = 3
            containerView.layer.borderColor = UIColor.white.cgColor
            
            // Add fish icon
            let imageView = UIImageView(image: UIImage(systemName: "fish.fill"))
            imageView.tintColor = .white
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 8, y: 8, width: 24, height: 24)
            containerView.addSubview(imageView)
            
            // Add verified badge if applicable
            if reportAnnotation.verificationStatus == .verified {
                let badgeView = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
                badgeView.tintColor = .systemGreen
                badgeView.backgroundColor = .white
                badgeView.layer.cornerRadius = 8
                badgeView.frame = CGRect(x: 26, y: -4, width: 16, height: 16)
                containerView.addSubview(badgeView)
            }
            
            addSubview(containerView)
            
            // Configure callout
            if reportAnnotation.imageURL != nil {
                // Add image preview in callout
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 5
                imageView.backgroundColor = .systemGray5
                leftCalloutAccessoryView = imageView
                
                // Load image asynchronously
                if let url = reportAnnotation.imageURL {
                    loadImage(from: url, into: imageView)
                }
            }
            
            // Add detail button
            let button = UIButton(type: .detailDisclosure)
            rightCalloutAccessoryView = button
        }
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }.resume()
    }
}

// MARK: - Cluster Annotation View

class ClusterAnnotationView: MKAnnotationView {
    static let identifier = MKMapView.AnnotationIdentifier.cluster
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        displayPriority = .defaultHigh
        collisionMode = .circle
        
        if let cluster = annotation as? MKClusterAnnotation {
            let count = cluster.memberAnnotations.count
            
            // Create cluster view
            frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            
            let circle = UIView(frame: bounds)
            circle.layer.cornerRadius = 25
            circle.backgroundColor = determineClusterColor(for: cluster)
            
            // Add count label
            let countLabel = UILabel(frame: bounds)
            countLabel.text = "\(count)"
            countLabel.textAlignment = .center
            countLabel.textColor = .white
            countLabel.font = .systemFont(ofSize: 16, weight: .bold)
            circle.addSubview(countLabel)
            
            addSubview(circle)
        }
    }
    
    private func determineClusterColor(for cluster: MKClusterAnnotation) -> UIColor {
        // Determine predominant type
        let cameraCount = cluster.memberAnnotations.filter { $0 is CameraAnnotation }.count
        let stationCount = cluster.memberAnnotations.filter { $0 is WeatherStationAnnotation }.count
        let reportCount = cluster.memberAnnotations.filter { $0 is JubileeReportAnnotation }.count
        
        if cameraCount > stationCount && cameraCount > reportCount {
            return .systemBlue
        } else if stationCount > cameraCount && stationCount > reportCount {
            return .systemOrange
        } else if reportCount > cameraCount && reportCount > stationCount {
            return .systemPurple
        } else {
            return .systemGray
        }
    }
}

// MARK: - Map View Extension for Registration

extension MKMapView {
    func registerAnnotationViews() {
        register(CameraAnnotationView.self,
                forAnnotationViewWithReuseIdentifier: AnnotationIdentifier.camera)
        register(WeatherStationAnnotationView.self,
                forAnnotationViewWithReuseIdentifier: AnnotationIdentifier.weatherStation)
        register(JubileeReportAnnotationView.self,
                forAnnotationViewWithReuseIdentifier: AnnotationIdentifier.jubileeReport)
        register(ClusterAnnotationView.self,
                forAnnotationViewWithReuseIdentifier: AnnotationIdentifier.cluster)
    }
}

// MARK: - SwiftUI Wrapper for Annotation Configuration

struct MapAnnotationConfigurator: UIViewRepresentable {
    let mapView: MKMapView
    
    func makeUIView(context: Context) -> UIView {
        mapView.registerAnnotationViews()
        mapView.delegate = context.coordinator
        return UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            switch annotation {
            case is CameraAnnotation:
                return mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapView.AnnotationIdentifier.camera,
                    for: annotation
                )
            case is WeatherStationAnnotation:
                return mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapView.AnnotationIdentifier.weatherStation,
                    for: annotation
                )
            case is JubileeReportAnnotation:
                return mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapView.AnnotationIdentifier.jubileeReport,
                    for: annotation
                )
            case is MKClusterAnnotation:
                return mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapView.AnnotationIdentifier.cluster,
                    for: annotation
                )
            default:
                return nil
            }
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                     calloutAccessoryControlTapped control: UIControl) {
            // Handle callout accessory taps
            guard let annotation = view.annotation else { return }
            
            switch annotation {
            case let camera as CameraAnnotation:
                NotificationCenter.default.post(
                    name: .cameraAnnotationTapped,
                    object: camera
                )
            case let station as WeatherStationAnnotation:
                NotificationCenter.default.post(
                    name: .weatherStationAnnotationTapped,
                    object: station
                )
            case let report as JubileeReportAnnotation:
                NotificationCenter.default.post(
                    name: .jubileeReportAnnotationTapped,
                    object: report
                )
            default:
                break
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cameraAnnotationTapped = Notification.Name("cameraAnnotationTapped")
    static let weatherStationAnnotationTapped = Notification.Name("weatherStationAnnotationTapped")
    static let jubileeReportAnnotationTapped = Notification.Name("jubileeReportAnnotationTapped")
}