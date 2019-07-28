//
//  ApiManager.swift
//  GridTestAkr
//
//  Created by Andriy Kruglyanko on 7/28/19.
//  Copyright © 2019 andriyKruglyanko. All rights reserved.
//

import Foundation
import CoreData

class ApiManager {
    static let sharedInstance: ApiManager = {
        let instanse = ApiManager ()
        
        return instanse
    }()
    
    private init() {}
    
    class func shared() -> ApiManager {
        return sharedInstance
    }
    
    static let api_key = "YOUR_KEY_INPUT_PLEASE"
    static let baseURL = "https://api.unsplash.com/"
    static let perPage = 30
    
    public func  getPhotos(curPageNumber: Int, searchedText: String, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        var params = GridFirstViewController.parameters
        params["query"] = searchedText
        var urlString =  String(format: "%@search/photos/?client_id=%@&page=%@&per_page=%@&order_by=latest&query=%@", ApiManager.baseURL, ApiManager.api_key, String(describing:curPageNumber), String(describing:ApiManager.perPage), searchedText)
        if searchedText.count == 0 {
            urlString =  String(format: "%@photos/?client_id=%@&page=%@&per_page=%@&order_by=latest", ApiManager.baseURL, GridFirstViewController.api_key, String(describing:curPageNumber), String(describing:ApiManager.perPage))
        }
        print("urlString = \(urlString)")
        guard let url = URL(string: urlString) else {
            print(urlString)
            return
        }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            print("data = \(data)")
            print("response = \(response)")
            print("error = \(error)")
            return completion(data, response, error)
            
            }.resume()
    }
    
    private func treatmentPhotos(photosAr: [Dictionary<String, AnyObject>]) throws {
        //increase name up to photosArray.count
        let requestIncrease = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let titleSort = NSSortDescriptor(key: "created_at", ascending: true)
        requestIncrease.sortDescriptors = [titleSort]
        let managedObjectContext =
            CoredataStack.mainContext
        
        var curI = 0
        for el in photosAr {
            print("el = \(el)")
            print("el[\"id\"]  = \(String(describing: el["id"] ))  ")
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            request.predicate = NSPredicate(format: "(idEnt == %@)",
                                            argumentArray: [el["id"] ?? ""])
            do {
                let managedObjectContext = CoredataStack.mainContext
                if let fetchedObjects = try managedObjectContext.fetch(request) as? [Photo] {
                    if fetchedObjects.count == 0 {
                        //save new in local database
                        
                        let curPhoto = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: managedObjectContext) as? Photo
                        curPhoto?.likes = el["likes"]?.int64Value ?? 0
                        curPhoto?.height = el["height"]?.int64Value ?? 1
                        curPhoto?.width = el["width"]?.int64Value ?? 1
                        curPhoto?.created_at = el["created_at"] as? String
                        curPhoto?.deleted_local = false
                        curPhoto?.idEnt = el["id"] as? String
                        curPhoto?.url = el["urls"]?.object(forKey: "regular")  as? String
                        
                        managedObjectContext.performAndWait { () -> Void in
                            if managedObjectContext.hasChanges {
                                do {
                                    try managedObjectContext.save()
                                } catch let error {
                                    print(error)
                                }
                            }
                        }
                        curI = curI + 1
                    }
                }
            } catch {
                fatalError("Failed to fetch Photo: \(error)")
                //return nil
            }
        }
    }
    
    private func treatmentSearchPhotos(photosDict: Dictionary<String, AnyObject>) throws {
        //increase name up to photosArray.count
        let requestIncrease = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let titleSort = NSSortDescriptor(key: "created_at", ascending: true)
        requestIncrease.sortDescriptors = [titleSort]
        let managedObjectContext =
            CoredataStack.mainContext
        
        if let photosArr1 = photosDict["results"] as? [Dictionary<String, AnyObject>] {
            
            var curI = 0
            for el in photosArr1 {
                print("el = \(el)")
                print("el[\"id\"]  = \(String(describing: el["id"] ))  ")
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
                request.predicate = NSPredicate(format: "(idEnt == %@)",
                                                argumentArray: [el["id"] ?? ""])
                do {
                    let managedObjectContext = CoredataStack.mainContext
                    if let fetchedObjects = try managedObjectContext.fetch(request) as? [Photo] {
                        if fetchedObjects.count == 0 {
                            //save new in local database
                            
                            let curPhoto = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: managedObjectContext) as? Photo
                            curPhoto?.likes = el["likes"]?.int64Value ?? 0
                            curPhoto?.height = el["height"]?.int64Value ?? 1
                            curPhoto?.width = el["width"]?.int64Value ?? 1
                            curPhoto?.created_at = el["created_at"] as? String
                            curPhoto?.deleted_local = false
                            curPhoto?.idEnt = el["id"] as? String
                            curPhoto?.url = el["urls"]?.object(forKey: "regular")  as? String
                            
                            managedObjectContext.performAndWait { () -> Void in
                                if managedObjectContext.hasChanges {
                                    do {
                                        try managedObjectContext.save()
                                    } catch let error {
                                        print(error)
                                    }
                                }
                            }
                            curI = curI + 1
                        }
                    }
                } catch {
                    fatalError("Failed to fetch Photo: \(error)")
                }
            }
        }
    }

}
