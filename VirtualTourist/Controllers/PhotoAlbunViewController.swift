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

class PhotoAlbumViewController: UICollectionViewController {
    
    @IBOutlet weak var noPictureLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionBtn: UIBarButtonItem!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var mapAnnotation: MKPointAnnotation!
    var locationD: LocationD!
    var photosArray = [Photo]()
    
    var fetchedResultsController: NSFetchedResultsController<PhotoD>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self

        // collection view setup
        photoCollectionView.allowsMultipleSelection = true // Multiple images can be selected to remove
        setUpCollectionViewFlowLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setMapView()
        setupFetchedResultsController()
        downloadPhotoMetadata()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    @IBAction func RemoveImages(_ sender: Any) {
        if newCollectionBtn.title == "New Collection" {
            removeExistingImages()
            downloadPhotoMetadata()
        } else {
            removeSelectedImages()
        }
        configureButtonText()
    }
    // Setting up fetched results controller
    private func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<PhotoD> = PhotoD.fetchRequest()
       
        if let pin = locationD {
            let predicate = NSPredicate(format: "location == %@", pin)
            fetchRequest.predicate = predicate
        }
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photod")
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func downloadPhotoMetadata() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        noPictureLabel.isHidden = true
        guard (fetchedResultsController.fetchedObjects?.isEmpty)! else {
            activityIndicator.isHidden = true
            activityIndicator.stopAnimating()
            print("image metadata is already present. no need to re download")
            return
        }
        
        print("About to start downloading of images metadata")
        let pagesCount = Int(self.locationD.pages)
        
        FlickerClient.getPhotos(latitude: mapAnnotation.coordinate.latitude, longitude: mapAnnotation.coordinate.longitude, totalPageAmount: pagesCount) { (photos, totalPages, error) in
            if photos.count > 0 {
                DispatchQueue.main.async {
                    if (pagesCount == 0) {
                        self.locationD.pages = Int32(Int(totalPages))
                    }
                    for photo in photos {
                        let newPhoto = PhotoD(context: self.dataController.viewContext)
                        newPhoto.imageUrl = URL(string: photo.urlM)
                        newPhoto.imageData = nil
                        newPhoto.location = self.locationD
                        newPhoto.imageId = UUID().uuidString
                        
                        do {
                            try self.dataController.viewContext.save()
                        } catch {
                            print("Unable to save the photo")
                        }
                    }
                    
                    print("capi")
                }
            } else {
                self.noPictureLabel.isHidden = false
                print("There was an error!!")
            }
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
        }
    }
    
    // Removes all the existing images for the current location
    private func removeExistingImages() {
        if let removeImages = fetchedResultsController.fetchedObjects {
            for image in removeImages {
                dataController.viewContext.delete(image)
                do {
                    try dataController.viewContext.save()
                } catch {
                    print("Unable to delete images")
                }
            }
        }
    }
    
    // Remove selected images for the current location
    private func removeSelectedImages() {
        var imageIds: [String] = []
        
        // All the index paths for the selected images are returned
        if let selectedImagesIndexPaths = photoCollectionView.indexPathsForSelectedItems {
            for indexPath in selectedImagesIndexPaths {
                let selectedImageToRemove = fetchedResultsController.object(at: indexPath)
                
                if let imageId = selectedImageToRemove.imageId {
                    imageIds.append(imageId)
                }
            }
            
            for imageId in imageIds {
                if let selectedImages = fetchedResultsController.fetchedObjects {
                    for image in selectedImages {
                        if image.imageId == imageId {
                            dataController.viewContext.delete(image)
                        }
                        do {
                            try dataController.viewContext.save()
                            newCollectionBtn.title = "New Collection"
                        } catch {
                            print("Unable to remove the photo")
                        }
                    }
                }
            }
        }
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    func setMapView() {
        if let annotation = mapAnnotation {
            mapView.addAnnotations([annotation])
            mapView.centerCoordinate = annotation.coordinate
            mapView.region = MKCoordinateRegion(center: annotation.coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
        }
    }
}


extension PhotoAlbumViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        print("collectionView is called")
        
        guard !(self.fetchedResultsController.fetchedObjects?.isEmpty)! else {
            print("images are already present.")
            return cell
        }
        
        let photo = self.fetchedResultsController.object(at: indexPath)
        
        if photo.imageData == nil {
            newCollectionBtn.isEnabled = false
            cell.imageOverlay.backgroundColor = UIColor.customColor(red: 242, green: 242, blue: 254, alpha: 0.85)
            DispatchQueue.global(qos: .background).async {
                if let imageData = try? Data(contentsOf: photo.imageUrl!) {
                    DispatchQueue.main.async {
                        photo.imageData = imageData
                        do {
                            try self.dataController.viewContext.save()
                        } catch {
                            print("error in saving image data")
                        }
                        let image = UIImage(data: imageData)
                        print("index is : \(indexPath.row)")
                        cell.photoImageView.image = image
                        cell.photoImageView.sizeToFit()
                        cell.imageOverlay.backgroundColor = UIColor.customColor(red: 255, green: 255, blue: 255, alpha: 0)
                   }
               }
            }
        } else {
            if let imageData = photo.imageData {
                let image = UIImage(data: imageData)
                cell.photoImageView.image =  image
                cell.imageOverlay.backgroundColor = UIColor.customColor(red: 255, green: 255, blue: 255, alpha: 0)
            }
        }
        
        newCollectionBtn.isEnabled = true
        return cell
    }
    
    func setUpCollectionViewFlowLayout() {
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        configureSelectionUI(collectionView: collectionView, indexPath: indexPath, isSelected: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        configureSelectionUI(collectionView: collectionView, indexPath: indexPath, isSelected: false)
    }
    
    private func configureButtonText() {
        if photoCollectionView.indexPathsForSelectedItems!.isEmpty {
            newCollectionBtn.title = "New Collection";
        } else {
            newCollectionBtn.title = "Remove";
        }
    }
    
    private func configureSelectionUI(collectionView: UICollectionView, indexPath: IndexPath, isSelected: Bool) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        if isSelected {
            cell.imageOverlay.backgroundColor = UIColor.customColor(red: 242, green: 242, blue: 254, alpha: 0.85)
        } else {
            cell.imageOverlay.backgroundColor = UIColor.customColor(red: 255, green: 255, blue: 255, alpha: 0)
        }
        configureButtonText()
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            photoCollectionView.insertItems(at: [newIndexPath!])
        case .delete:
            photoCollectionView.deleteItems(at: [indexPath!])
        case .update:
            photoCollectionView.reloadItems(at: [newIndexPath!])
        default:
            break
        }
    }
}
