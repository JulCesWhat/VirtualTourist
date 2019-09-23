//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Julio Cesar Whatley on 9/13/19.
//  Copyright © 2019 Capi. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    var dataController: DataController!
    
    var selectedAnnotation: MKPointAnnotation?
    var fetchedResultsController: NSFetchedResultsController<LocationD>!
    var selectedLocationD: LocationD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
        restoreMapRegion()
        loadMapLocations()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    // MARK: Setting up the fetched results controller
    private func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<LocationD> = LocationD.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "locationd")
        
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("TravelLocationsVC: Unable to fetch the results")
        }
    }
    
    @IBAction func onPress(_ sender: UILongPressGestureRecognizer) {
        let touchPoint = sender.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        //mapView.addAnnotation(annotation)
        
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude), completionHandler: {(placemarks, error) -> Void in
            if let err = error {
                print("Reverse geocoder failed with error" + err.localizedDescription)
                return
            } else {
                if let placemarks = placemarks, let placemark = placemarks.first {
                    annotation.title = (placemark.name ?? "Not Known")
                    annotation.subtitle = (placemark.country ?? "")
                } else {
                    annotation.title = "Unknown Place"
                    annotation.subtitle = "Unknown Location"
                }
                self.mapView.addAnnotation(annotation)
                self.addLocationD(annotation);
            }
        })
    }
    
    func saveMapRegion() {
        let mapRegion = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        UserDefaults.standard.set (mapRegion, forKey: "mapRegion")
    }
    
    func restoreMapRegion()
    {
        if let mapRegion = UserDefaults.standard.dictionary(forKey: "mapRegion")
        {
            
            let longitude = mapRegion["longitude"] as! CLLocationDegrees
            let latitude = mapRegion["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = mapRegion["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = mapRegion["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            self.mapView.setRegion(savedRegion, animated: false)
        }
    }
    
    func addLocationD(_ annotation: MKPointAnnotation) {
        let locationD = LocationD(context: dataController.viewContext)
        locationD.creationDate = Date()
        locationD.longitude = annotation.coordinate.longitude
        locationD.latitude = annotation.coordinate.latitude
        locationD.title = annotation.title
        locationD.subTitle = annotation.subtitle
        try? dataController.viewContext.save()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoAlbumSegue" {
            let controller = segue.destination as! PhotoAlbumViewController
            controller.mapAnnotation = selectedAnnotation
            controller.locationD = selectedLocationD
            controller.dataController = self.dataController
        }
    }
}


extension MapViewController: MKMapViewDelegate  {
    
    // Fetch pins and add them to map view
    func loadMapLocations() {
        if let locationsD = fetchedResultsController.fetchedObjects {
            for location in locationsD  {
                let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = location.title
                annotation.subtitle = location.subTitle
                DispatchQueue.main.async {
                    self.mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        guard let _ = view.annotation else {
            return
        }
        
        if let annotation = view.annotation as? MKPointAnnotation {
            do {
                let predicate = NSPredicate(format: "longitude = %@ AND latitude = %@", argumentArray: [annotation.coordinate.longitude, annotation.coordinate.latitude])
                selectedLocationD = try dataController.fetchLocationD(predicate)
                selectedAnnotation = annotation
                self.performSegue(withIdentifier: "photoAlbumSegue", sender: self)
            } catch {
                print("There was an error!!")
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        saveMapRegion();
    }
}

extension MapViewController: NSFetchedResultsControllerDelegate {

}
