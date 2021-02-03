//
//  MapViewController.swift
//  RouteTest
//
//  Created by Omer Katzir on 19/11/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import MapKit
import VideoToolbox
import CoreLocation
import GoogleMaps

protocol IMapDelegate {
    func onDirectionsChanged(coords: [CLocation], centerCoord: CLocation)
    
}


final class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    var delegate: IMapDelegate! = nil
    private var routePolyline: MKPolyline! = nil
    private var route: [CLLocationCoordinate2D]! = []
    private var locations: [CLocation] = []
    private var annotations: [Annotation]! = []
    @IBOutlet weak var longTouch: UILongPressGestureRecognizer!
    @IBOutlet weak var startBtn: UIButton!
    var locm: LocationEngine! = LocationEngine()

    
    private var arEngine: ARKitEngine!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //mapView.setUserTrackingMode(.followWithHeading, animated: true)
        mapView.camera.altitude = 100000
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        longTouch.addTarget(self, action: #selector(onLongPress))
        
        loadAnnotations()
     
    }
    
    
    @objc func onLongPress(gs: UILongPressGestureRecognizer) {
        mapView.removeAnnotations(mapView.annotations)
        
        var touch = gs.location(in: mapView)
        var coord = mapView.convert(touch, toCoordinateFrom: mapView)
        let src = Annotation(coord: mapView.userLocation.coordinate, title: "Start")
        touch.y += 50
        coord = mapView.convert(touch, toCoordinateFrom: mapView)
        let dst = Annotation(coord: coord, title: "Finish")
        
        annotations = [src, dst]
        mapView.addAnnotations([src, dst])
        calcDirections(src: annotations[0], dst: annotations[1])
    }
    
    @IBAction func onStart(sender: Any) {
        getElevations(route: route)
    }
    
    private func onGotElevations(_ route: [CLLocationCoordinate2D], _ elevations: [Float]) {
        self.route = route
        locations = []
        (0...route.count-1).forEach { (i) in
           locations.append(CLocation(route[i], alt: elevations[i]))
        }
        
        DispatchQueue.main.sync {
            self.performSegue(withIdentifier: "StartNavigation", sender: self)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "StartNavigation" {
            saveAnnotations()
            let vc: GraphicsViewController = (segue.destination as? GraphicsViewController)!
            
            vc.gisRoute = locations
        }
    }
    
}


extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        if mapView.annotations.count > 1 && newState == .ending {
            calcDirections(src: annotations[0], dst: annotations[1])
            
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else { return nil }


        let reuseId = "pin"
        var pav: MKMarkerAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        if pav == nil {
            pav = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pav?.isDraggable = true
            pav?.canShowCallout = true
        } else {
            pav?.annotation = annotation
        }

        return pav
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .blue
        renderer.lineWidth = 4
    
        return renderer
        
    }
    
    private func calcDirections(src: MKAnnotation, dst: MKAnnotation) {
        getGoogleRoute(src: src.coordinate, dst: dst.coordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: src.coordinate.latitude, longitude: src.coordinate.longitude), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: dst.coordinate.latitude, longitude: dst.coordinate.longitude), addressDictionary: nil))
        request.requestsAlternateRoutes = false
        request.transportType = .automobile

        let directions = MKDirections(request: request)

        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }

            self.mapView.removeOverlays(self.mapView.overlays)

            for route in unwrappedResponse.routes {
                self.mapView.addOverlay((route.polyline), level: .aboveRoads )
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                self.routePolyline = route.polyline
                self.route = []
                for i in 0...(route.polyline.pointCount-1) {
                    let pt = route.polyline.points()[i]
                    self.route.append(pt.coordinate)
                }
           }
        }
    }
}


extension MapViewController {
    func saveAnnotations() {
        
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("annotations.dat")

        let annData: [AnnotationData] = annotations.map { (ann) -> AnnotationData in
            return ann.getData()
        }
        
        let data = try! JSONEncoder().encode(annData)
        try! data.write(to: fileURL)
    }
    
    func loadAnnotations() {
        if let fileURL = try? FileManager.default
                  .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("annotations.dat") {
            
        

            var anns: [Annotation] = []
            if let data = try? Data(contentsOf: fileURL) {
                if let jsonData = try? JSONDecoder().decode([AnnotationData].self, from: data) {
                    for annData in jsonData {
                        let annotation = Annotation(from: annData)
                        anns.append(annotation)
                    }
                    
                    if anns.count >= 2 {
                        annotations = [anns[0], anns[1]]
                        mapView.addAnnotations([anns[0], anns[1]])
                        calcDirections(src: anns[0], dst: anns[1])
                    }
                }
            }
        }
            
    }
}


struct AnnotationData: Codable {
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var title: String?
}

class Annotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    
    var title: String? = ""

    var subtitle: String? = ""
    
    
    init(coord: CLLocationCoordinate2D, title: String?) {
        
        self.coordinate = coord
        self.title = title
    }
    
    convenience init(from: AnnotationData) {
        self.init(coord: CLLocationCoordinate2D(latitude: CLLocationDegrees(from.latitude), longitude: from.longitude), title: from.title)
    }
    
    func getData() -> AnnotationData {
        return AnnotationData(latitude: coordinate.latitude, longitude: coordinate.longitude, title: title)
    }
    
}


extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
       
        var cgImage_: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage_)
        
        guard let cgImage = cgImage_ else {
            return nil
        }
        
        self.init(cgImage: cgImage)
    }
}



private extension MapViewController {
    
    class JsonData: Codable {
        
        class ElevationData: Codable {
            var elevation: Float
            var location: [String: Float]
        }
        
        var results: [ElevationData]
    }
    
    func getElevations(route: [CLLocationCoordinate2D])  {
        
        let key: String = Bundle.main.object(forInfoDictionaryKey: "GoogleApiKey") as! String
        //let key = "AIzaSyBaTSnhVQJ7KeiiEG7ZMwhyNXfy69aXszg"
        let baseUrl = "https://maps.googleapis.com/maps/api/elevation/json"
        let coordsStr = route.map { (coord) -> String in
            return "\(coord.latitude),\(coord.longitude)"
            }.joined(separator: "|")
        
        var components = URLComponents(string: baseUrl)
        components?.queryItems = [
            URLQueryItem(name: "locations", value: "\(coordsStr)"),
            URLQueryItem(name: "key", value: key)
        ]
        
        let request = URLRequest(url: (components?.url)!)
        
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data else { return }
            
            let results = try! JSONDecoder().decode(JsonData.self, from: data)
            let elevations = results.results.map { (elevationData) -> Float in
                return elevationData.elevation
            }
            print(elevations)
            
            if elevations.count != route.count {
                return
            }
            
            self.onGotElevations(route, elevations)
        }

        task.resume()
    }
    
    class RouteData: Codable {
        
        class PolylineData: Codable {
            var points: String
        }
        class RouteData: Codable {
            var overview_polyline: PolylineData
        }
        
        var routes: [RouteData]
    }
    
    func getGoogleRoute(src: CLLocationCoordinate2D, dst: CLLocationCoordinate2D) {
        let key: String = Bundle.main.object(forInfoDictionaryKey: "GoogleApiKey") as! String
              //let key = "AIzaSyBaTSnhVQJ7KeiiEG7ZMwhyNXfy69aXszg"
        let baseUrl = "https://maps.googleapis.com/maps/api/directions/json"
        
        
        var components = URLComponents(string: baseUrl)
        components?.queryItems = [
            URLQueryItem(name: "origin", value: "\(src.latitude),\(src.longitude)"),
            URLQueryItem(name: "destination", value: "\(dst.latitude),\(dst.longitude)"),
            URLQueryItem(name: "key", value: key)
        ]
        
        let request = URLRequest(url: (components?.url)!)
        
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data else { return }
            
            let results = try! JSONDecoder().decode(RouteData.self, from: data)
           
            DispatchQueue.main.async {
                
                self.mapView.removeOverlays(self.mapView.overlays)
                
                for route in results.routes {
                    let path = GMSPath(fromEncodedPath: route.overview_polyline.points)!
                    self.route = []
                    for i in 0...path.count() {
                        self.route.append(path.coordinate(at: i))
                        
                    }
                   
                    let polyline = MKPolyline(coordinates: self.route, count: Int(path.count()))
                
                    self.mapView.addOverlay(polyline, level: .aboveRoads )
                    self.mapView.setVisibleMapRect(polyline.boundingMapRect, animated: true)
                    self.routePolyline = polyline
            
                }
            }
        }

        task.resume()
    }
    
}
