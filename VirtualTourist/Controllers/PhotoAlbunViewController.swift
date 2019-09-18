//
//  PhotoAlbunViewController.swift
//  VirtualTourist
//
//  Created by Julio Cesar Whatley on 9/14/19.
//  Copyright © 2019 Capi. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UICollectionViewController, MKMapViewDelegate {
    
    @IBOutlet weak var noPictureLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionBtn: UIBarButtonItem!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
//    var fetchedResultsController: NSFetchedResultsController<PhotoD>!
    var mapAnnotation: MKPointAnnotation!
    var locationD: LocationD!
    var flickrPhotos: [Photo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // collection view setup
        setUpCollectionViewFlowLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setMapView()
        
        downloadPhotoMetadata()
    }
    
    func setUpCollectionViewFlowLayout() {
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func downloadPhotoMetadata() {
        
        print("About to start downloading of images metadata")
        
        FlickerClient.getPhotos(latitude: mapAnnotation.coordinate.latitude, longitude: mapAnnotation.coordinate.longitude) { (photos, error) in
//            print(photos.count)
            if photos.count > 0 {
                
                for photo in photos {
                    self.flickrPhotos.append(photo)
                }
                self.activityIndicator.isHidden = true
                self.noPictureLabel.isHidden = true
//                self.flickrPhotos = photos
                DispatchQueue.main.async {
                    self.photoCollectionView.reloadData()
                    print(self.flickrPhotos.count)
                    print("capi")
                }
            } else {
                print("There was an error!!")
            }
        }
    }
    
    func setMapView() {
        if let annotation = mapAnnotation {
            mapView.addAnnotations([annotation])
            
            mapView.centerCoordinate = annotation.coordinate
            mapView.region = MKCoordinateRegion(center: annotation.coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Being....")
        return self.flickrPhotos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("cAlle.d")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        print("collectionView is called")
        cell.backgroundColor = .lightGray
        
        let photo = self.flickrPhotos[(indexPath as NSIndexPath).row]
        if let image = photo.photoImage {
            cell.photoImageView.image = image
        } else {
            DispatchQueue.global(qos: .background).async {
                if let imageData = try? Data(contentsOf: URL(string: photo.urlM)!) {
                    DispatchQueue.main.async {
                        let image = UIImage(data: imageData)
                        print("index is : \(indexPath.row)")
                        cell.photoImageView.image = image
                    }
                }
            }
        }
        
        cell.backgroundColor = .none
        return cell
    }
}
