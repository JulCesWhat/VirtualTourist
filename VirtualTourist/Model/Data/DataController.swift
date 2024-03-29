//
//  DataController.swift
//  VirtualTourist
//
//  Created by Julio Cesar Whatley on 9/14/19.
//  Copyright © 2019 Capi. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    let persistentContainer:NSPersistentContainer
    
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    let backgroundContext:NSManagedObjectContext!
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
        
        backgroundContext = persistentContainer.newBackgroundContext()
    }
    
    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext()
            self.configureContexts()
            completion?()
        }
    }
}

// MARK: - Autosaving

extension DataController {
    func autoSaveViewContext(interval:TimeInterval = 30) {
        print("autosaving")
        
        guard interval > 0 else {
            print("cannot set negative autosave interval")
            return
        }
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}

extension DataController {
    func fetchLocationD(_ predicate: NSPredicate, sorting: NSSortDescriptor? = nil) throws -> LocationD? {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationD")
        fr.predicate = predicate
        if let sorting = sorting {
            fr.sortDescriptors = [sorting]
        }
        guard let locationD = (try viewContext.fetch(fr) as! [LocationD]).first else {
            return nil
        }
        return locationD
    }
    
    func fetchAllLocationD() throws -> [LocationD]? {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationD")
        guard let locationD = try viewContext.fetch(fr) as? [LocationD] else {
            return nil
        }
        return locationD
    }
    
    func fetchAllPhotoD(_ predicate: NSPredicate? = nil, sorting: NSSortDescriptor? = nil) throws -> [PhotoD]? {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "PhotoD")
        fr.predicate = predicate
        if let sorting = sorting {
            fr.sortDescriptors = [sorting]
        }
        guard let allPhotoD = try viewContext.fetch(fr) as? [PhotoD] else {
            return nil
        }
        return allPhotoD
    }
}
