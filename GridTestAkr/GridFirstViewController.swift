//
//  GridFirstViewController.swift
//  GridTestAkr
//
//  Created by Andriy Kruglyanko on 7/27/19.
//  Copyright © 2019 andriyKruglyanko. All rights reserved.
//

import UIKit
import CoreData
import Kingfisher
import forNetworkImage

class GridFirstViewController: UIViewController, UISearchBarDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DeleteOneImageDelegate {
    
    
    @IBOutlet weak var curCollectionView: UICollectionView!
    @IBOutlet weak var curSearchBar: UISearchBar!
    private var cellWidth: CGFloat {
        return UIScreen.main.bounds.width * Constants.relativeCellSize
    }
    
    private enum Constants {
        static let relativeCellSize: CGFloat = 0.9
        static let numberOfElementsInLine: CGFloat = 1.0
    }
    let numberOfElementsInLineDefault: CGFloat = 3.0
    var curNumberOfElementsInLineDefault: CGFloat = 3.0
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    var curPageNumber: Int = 1
    var curSearchText : String = ""
    static let limitPageNumber: Int = 10
    static let perPage: Int = 30
    
     static let baseURL = "https://api.unsplash.com/"
    static let api_key = "YOUR_KEY_INPUT_PLEASE"
    
    static let parameters = [
        "api_key": api_key,
        "page": 0,
        "per_page": perPage,
        "order_by": "latest"
        ] as [String : Any]
    
    static let parametersStart = [
        "api_key": api_key,
        "page": 0,
        "per_page": perPage,
        "order_by": "latest",
        "query": ""
        ] as [String : Any]
    
    var selectedPhoto: Photo!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        curCollectionView.register(UINib(nibName: "CollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "photoCollectionCell")
        initializeFetchedResultsController()
curPageNumber = 1
        let inset = (UIScreen.main.bounds.width * (1 -  Constants.relativeCellSize))/(numberOfElementsInLineDefault + 1)
        curCollectionView.contentInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        if self.curCollectionView.numberOfSections > 0 {
            self.curCollectionView.reloadSections(IndexSet(integer: 0))
        }
        curCollectionView.setNeedsLayout()
        ApiManager.shared().getPhotos(curPageNumber: curPageNumber, searchedText: "", completion: {  (data, response, error) in
            print("data = \(data)")
            print("response = \(response)")
            print("error = \(error)")
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, //mimeType.hasPrefix("application/json"),
                let data = data, error == nil
                
                else {  if (error?.localizedDescription) != nil {
                    print((error?.localizedDescription)! as String)
                    }
                    return
            }
            
            
            do {
                if response?.url?.pathComponents.contains("search") ?? false {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
                    print("total = \(json["total"] as? Int), total_pages = \(json["total_pages"] as? Int)")
                    if let  total = json["total"] as? Int,
                        total > 0 {
                        do {
                            try self.treatmentSearchPhotos(photosDict: json as! Dictionary<String, AnyObject>)
                        } catch  {
                            print(error)
                        }
                    } else {
                    }
                    
                } else {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSArray
                    
                    if json.count > 0 {
                        do {
                            try self.treatmentPhotos(photosAr: json as! [Dictionary<String, AnyObject>])
                        } catch  {
                            print(error)
                        }
                    } else {
                    }
                }
                
                
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
        })
        //ApiManager.shared().getPhotos(curPageNumber: curPageNumber, searchedText: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //curCollectionView.reloadData()
        if self.curCollectionView.numberOfSections > 0 {
            self.curCollectionView.reloadSections(IndexSet(integer: 0))
        }
        curCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - DeleteOneImageDelegate
    
    func deleteOneImageClicked(tag: Int, idEnt: String) {
        if let curPhotoForDeleteLocal = fetchedResultsController.object(at: IndexPath.init(row: tag, section: 0)) as? Photo,
            curPhotoForDeleteLocal.idEnt == idEnt {
            let managedObjectContext = CoredataStack.mainContext
           managedObjectContext.performAndWait { () -> Void in
            managedObjectContext.delete(curPhotoForDeleteLocal)
            do {
                try managedObjectContext.save()
            } catch {
                print("error delete image save error = \(error)")
            }
            }
        }
    }
    
    // MARK: - actions
    
    @IBAction func deleteAll(_ sender: Any) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        let managedObjectContext =
            CoredataStack.mainContext
        do {
            _ = try managedObjectContext.execute(request)
            KingfisherManager.shared.cache.clearMemoryCache()
            KingfisherManager.shared.cache.clearDiskCache()
            DispatchQueue.main.async {
                self.curCollectionView.reloadData()
                self.curCollectionView.collectionViewLayout.invalidateLayout()
            }
        } catch {
            fatalError("Failed to execute request: \(error)")
        }
        fetchedResultsController.managedObjectContext.reset()
        let imageFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        do {
            let managedObjectContext = CoredataStack.mainContext
            if let fetchedImage = try managedObjectContext.fetch(imageFetch) as? [Photo] ,
                fetchedImage.count > 0 {
                for curImage in (fetchedImage) {
                    print("deleteAll = \(curImage)")
                    let managedObjectContext = CoredataStack.mainContext
                    managedObjectContext.performAndWait { () -> Void in
                        //managedObjectContext.reset()
                        print("deleteAll curImage = \(curImage)")
                        managedObjectContext.delete(curImage)
                        do {
                            try managedObjectContext.save()
                            
                        } catch {
                            print(error)
                        }
                    }
                    
                }
            } else {
                DispatchQueue.main.async {
                    self.curCollectionView.reloadData()
                    self.curCollectionView.collectionViewLayout.invalidateLayout()
                }
            }
        } catch {
            fatalError("Failed to fetch remove ImageObject: \(error)")
        }
    }
    
    // MARK: - download
    
    func  getPhotos(searchText: String)/*, completion: @escaping (Data?, URLResponse?, Error?) -> ())*/ {
        var params = GridFirstViewController.parameters
        params["query"] = searchText
        var urlString =  String(format: "%@search/photos/?client_id=%@&page=%@&per_page=%@&order_by=latest&query=%@", GridFirstViewController.baseURL, GridFirstViewController.api_key, String(describing:curPageNumber), String(describing:GridFirstViewController.perPage), searchText)
        if searchText.count == 0 {
            urlString =  String(format: "%@photos/?client_id=%@&page=%@&per_page=%@&order_by=latest", GridFirstViewController.baseURL, GridFirstViewController.api_key, String(describing:curPageNumber), String(describing:GridFirstViewController.perPage))
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
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, //mimeType.hasPrefix("application/json"),
                let data = data, error == nil
                
                else {  if (error?.localizedDescription) != nil {
                    print((error?.localizedDescription)! as String)
                    }
                    return
            }
            
            
            do {
                if response?.url?.pathComponents.contains("search") ?? false {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
                    print("total = \(json["total"] as? Int), total_pages = \(json["total_pages"] as? Int)")
                    if let  total = json["total"] as? Int,
                        total > 0 {
                        do {
                            try self.treatmentSearchPhotos(photosDict: json as! Dictionary<String, AnyObject>)
                        } catch  {
                            print(error)
                        }
                    } else {
                    }
                    
                } else {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSArray
                    
                    if json.count > 0 {
                        do {
                            try self.treatmentPhotos(photosAr: json as! [Dictionary<String, AnyObject>])
                        } catch  {
                            print(error)
                        }
                    } else {
                    }
                }
                
                
            } catch let error as NSError {
                print(error.localizedDescription)
            }
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
        
        let fetchedResultsControllerIncr = NSFetchedResultsController(fetchRequest: requestIncrease, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
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
    
    func saveImage(image: UIImage, name: String) -> Bool {
        
        guard let data = image.jpegData(compressionQuality: 1) ?? image.jpegData(compressionQuality: 0.5) else {
            return false
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        var saved = false
        if let n = "\(name).jpg" as? String,
            let url1 = URL(string: n) as? URL
        {
            DispatchQueue(label: "com.andriyKruglyanko.OxWish.saveImage", qos: DispatchQoS.background).async {[weak self] () -> Void in
                
                //let fileManager = FileManager.default
                let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("\(name).jpg")
                //let image = UIImage(named: “apple.jpg”)
                print(paths)
                //fileManager.createFile(atPath: paths as String, contents: data, attributes: nil)
                
                do {
                    try data.write(to: (directory.appendingPathComponent("\(url1.absoluteString)") ?? nil)!)
                    //} as! @convention(block) () -> Void
                    saved = true
                    DispatchQueue.main.async {
                        self?.curCollectionView.reloadData()
                    }
                    //return true
                    //return true
                } catch {
                    print(error.localizedDescription)
                    saved = false
                    //return false
                    //return false
                }
            }
            return saved
        } else {
            return saved
        }
    }
    
    func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    
    // MARK: - UISearchBarDelegate
    
    func  searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        curNumberOfElementsInLineDefault = 1.0
        let inset = (UIScreen.main.bounds.width * (1 -  Constants.relativeCellSize))/(curNumberOfElementsInLineDefault + 1)
        curCollectionView.contentInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        if self.curCollectionView.numberOfSections > 0 {
            self.curCollectionView.reloadSections(IndexSet(integer: 0))
        }
        curCollectionView.setNeedsLayout()
        
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        let managedObjectContext =
            CoredataStack.mainContext
        do {
            _ = try managedObjectContext.execute(request)
            if self.curCollectionView.numberOfSections > 0 {
                self.curCollectionView.reloadSections(IndexSet(integer: 0))
            }
            curCollectionView.collectionViewLayout.invalidateLayout()
        } catch {
            fatalError("Failed to execute request: \(error)")
        }
        NSLog("The default search bar keyboard search button was tapped: \(String(describing: searchBar.text)).")
        if let aString = searchBar.text {
            searchBar.resignFirstResponder()
            curPageNumber = 1
            curSearchText = searchBar.text ?? ""
            ApiManager.shared().getPhotos(curPageNumber: curPageNumber, searchedText: aString, completion: {  (data, response, error) in
                print("data = \(data)")
                print("response = \(response)")
                print("error = \(error)")
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, //mimeType.hasPrefix("application/json"),
                    let data = data, error == nil
                    
                    else {  if (error?.localizedDescription) != nil {
                        print((error?.localizedDescription)! as String)
                        }
                        return
                }
                
                
                do {
                    if response?.url?.pathComponents.contains("search") ?? false {
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
                        print("total = \(json["total"] as? Int), total_pages = \(json["total_pages"] as? Int)")
                        if let  total = json["total"] as? Int,
                            total > 0 {
                            do {
                                try self.treatmentSearchPhotos(photosDict: json as! Dictionary<String, AnyObject>)
                            } catch  {
                                print(error)
                            }
                        } else {
                        }
                        
                    } else {
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSArray
                        
                        if json.count > 0 {
                            do {
                                try self.treatmentPhotos(photosAr: json as! [Dictionary<String, AnyObject>])
                            } catch  {
                                print(error)
                            }
                        } else {
                        }
                    }
                    
                    
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
                
            })
            //ApiManager.shared().getPhotos(curPageNumber: curPageNumber, searchedText: aString)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String) {
        print("textDidChange searchText = \(searchText) , searchText.count = \(searchText.count)")
        curSearchText = ""
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        let managedObjectContext =
            CoredataStack.mainContext
        managedObjectContext.performAndWait { () -> Void in
            do {
                _ = try managedObjectContext.execute(request)
                KingfisherManager.shared.cache.clearMemoryCache()
                KingfisherManager.shared.cache.clearDiskCache()
                DispatchQueue.main.async {
                    self.curCollectionView.reloadData()
                    self.curCollectionView.collectionViewLayout.invalidateLayout()
                }
            } catch {
                fatalError("Failed to execute request: \(error)")
            }
        }
        if searchText.count > 3 {
            //search request
            curNumberOfElementsInLineDefault = 1.0
            let inset = (UIScreen.main.bounds.width * (1 -  Constants.relativeCellSize))/(curNumberOfElementsInLineDefault + 1)
            curCollectionView.contentInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
            if self.curCollectionView.numberOfSections > 0 {
                self.curCollectionView.reloadSections(IndexSet(integer: 0))
            }
            curCollectionView.setNeedsLayout()
            curPageNumber = 1
            curSearchText = searchText
            ApiManager.shared().getPhotos(curPageNumber: curPageNumber, searchedText: curSearchText, completion: {  (data, response, error) in
                print("data = \(data)")
                print("response = \(response)")
                print("error = \(error)")
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, //mimeType.hasPrefix("application/json"),
                    let data = data, error == nil
                    
                    else {  if (error?.localizedDescription) != nil {
                        print((error?.localizedDescription)! as String)
                        }
                        return
                }
                
                
                do {
                    if response?.url?.pathComponents.contains("search") ?? false {
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
                        print("total = \(json["total"] as? Int), total_pages = \(json["total_pages"] as? Int)")
                        if let  total = json["total"] as? Int,
                            total > 0 {
                            do {
                                try self.treatmentSearchPhotos(photosDict: json as! Dictionary<String, AnyObject>)
                            } catch  {
                                print(error)
                            }
                        } else {
                        }
                        
                    } else {
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSArray
                        
                        if json.count > 0 {
                            do {
                                try self.treatmentPhotos(photosAr: json as! [Dictionary<String, AnyObject>])
                            } catch  {
                                print(error)
                            }
                        } else {
                        }
                    }
                    
                    
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
                
            })
            //ApiManager.shared().getPhotos(curPageNumber: curPageNumber, searchedText: curSearchText)
        }
        if searchText.count == 0 {
            //remove in local
            
            
            curNumberOfElementsInLineDefault = 3.0
            let inset = (UIScreen.main.bounds.width * (1 -  Constants.relativeCellSize))/(curNumberOfElementsInLineDefault + 1)
            curCollectionView.contentInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
            if self.curCollectionView.numberOfSections > 0 {
                self.curCollectionView.reloadSections(IndexSet(integer: 0))
            }
            curCollectionView.setNeedsLayout()
            
            let fetch1 = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            let request1 = NSBatchDeleteRequest(fetchRequest: fetch1)
            managedObjectContext.performAndWait { () -> Void in
                do {
                    _ = try managedObjectContext.execute(request1)
                    if self.curCollectionView.numberOfSections > 0 {
                        self.curCollectionView.reloadSections(IndexSet(integer: 0))
                    }
                    curCollectionView.collectionViewLayout.invalidateLayout()
                } catch {
                    fatalError("Failed to execute request: \(error)")
                }
            }
            NSLog("The default search bar keyboard search button was tapped: \(String(describing: searchBar.text)).")
            if let aString = searchBar.text {
                searchBar.resignFirstResponder()
                curPageNumber = 1
                curSearchText = searchBar.text ?? ""
                ApiManager.shared().getPhotos(curPageNumber: curPageNumber, searchedText: aString, completion: {  (data, response, error) in
                    print("data = \(data)")
                    print("response = \(response)")
                    print("error = \(error)")
                    guard
                        let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                        let mimeType = response?.mimeType, //mimeType.hasPrefix("application/json"),
                        let data = data, error == nil
                        
                        else {  if (error?.localizedDescription) != nil {
                            print((error?.localizedDescription)! as String)
                            }
                            return
                    }
                    
                    
                    do {
                        if response?.url?.pathComponents.contains("search") ?? false {
                            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
                            print("total = \(json["total"] as? Int), total_pages = \(json["total_pages"] as? Int)")
                            if let  total = json["total"] as? Int,
                                total > 0 {
                                do {
                                    try self.treatmentSearchPhotos(photosDict: json as! Dictionary<String, AnyObject>)
                                } catch  {
                                    print(error)
                                }
                            } else {
                            }
                            
                        } else {
                            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSArray
                            
                            if json.count > 0 {
                                do {
                                    try self.treatmentPhotos(photosAr: json as! [Dictionary<String, AnyObject>])
                                } catch  {
                                    print(error)
                                }
                            } else {
                            }
                        }
                        
                        
                    } catch let error as NSError {
                        print(error.localizedDescription)
                    }
                    
                })
                //ApiManager.shared().getPhotos(curPageNumber: curPageNumber, searchedText: aString)
            }
            
        }
    }

    //MARK: - fetched controller
    
    func initializeFetchedResultsController() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let created_atSort = NSSortDescriptor(key: "created_at", ascending: true)
        request.sortDescriptors = [created_atSort]
        let managedObjectContext =
            CoredataStack.mainContext
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        
        do {
            try fetchedResultsController.performFetch()
            curCollectionView.reloadData()
            curCollectionView.collectionViewLayout.invalidateLayout()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        print("photo didChange sectionInfo type = \(type)")
        self.curCollectionView.reloadData()
        switch type {
        case .insert:
            self.curCollectionView?.performBatchUpdates({
                curCollectionView.insertSections(IndexSet(integer: sectionIndex))
                curCollectionView.reloadData()
            }, completion: nil)
            
        case .delete:
            self.curCollectionView?.performBatchUpdates({
                curCollectionView.deleteSections(IndexSet(integer: sectionIndex))
                curCollectionView.reloadData()
            }, completion: nil)
            
        case .move:
            if self.curCollectionView.numberOfSections > 0 {
                self.curCollectionView.reloadSections(IndexSet(integer: 0))
            }
            curCollectionView.collectionViewLayout.invalidateLayout()
            break
        case .update:
            break
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        DispatchQueue.main.async {
            self.curCollectionView.reloadData()
            self.curCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("post create edit didChange indexPath type = \(type.rawValue)")
        switch type {
        case .insert:
            DispatchQueue.main.async {
                self.curCollectionView.reloadData()
            }
            break
            
        case .delete:
            DispatchQueue.main.async {
                self.curCollectionView.reloadData()
            }
        case .move:
            self.curCollectionView.reloadData()
            break
        case .update:
            DispatchQueue.main.async {
                self.curCollectionView.reloadData()
            }
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        print("controllerDidChangeContent  fetchedResultsController.fetchedObjects?.count =  \(fetchedResultsController.fetchedObjects?.count)")
        DispatchQueue.main.async {
            self.curCollectionView.reloadData()
            self.curCollectionView.collectionViewLayout.invalidateLayout()
            self.curCollectionView.layoutIfNeeded()
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        print("cellWidth = \(cellWidth)")
        var picDimension = (UIScreen.main.bounds.width * (Constants.relativeCellSize))/(curNumberOfElementsInLineDefault)
        if curNumberOfElementsInLineDefault == 3 {
            picDimension = (UIScreen.main.bounds.width * (Constants.relativeCellSize))/(curNumberOfElementsInLineDefault)
        } else {
            picDimension = (UIScreen.main.bounds.width * ( Constants.relativeCellSize))/(curNumberOfElementsInLineDefault)
        }
        print("picDimension = \(picDimension)")
        return CGSize(width: picDimension, height: picDimension)
    }
    
    //MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        curCollectionView.collectionViewLayout.invalidateLayout()
        self.curCollectionView.layoutIfNeeded()
        print(" numberOfSections = \(fetchedResultsController.sections!.count)")
        
            return fetchedResultsController.sections!.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
         fatalError("No sections in fetchedResultsController")
         }
         let sectionInfo = sections[section]
         print("sectionInfo.numberOfObjects = \(sectionInfo.numberOfObjects)")
         return sectionInfo.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCollectionCell", for: indexPath) as! CollectionViewCell
        if curNumberOfElementsInLineDefault == 1 {
            cell.deleteOneImageButton.isEnabled  = true
            cell.deleteOneImageButton.isHidden = false
        } else {
            cell.deleteOneImageButton.isEnabled  = false
            cell.deleteOneImageButton.isHidden = true
        }
        cell.setNeedsDisplay()
        cell.delegateDeleteOneImage = self
        if (cell as? CollectionViewCell) != nil {
            if let el =  self.fetchedResultsController?.object(at: indexPath) as? Photo,
                cell.curImageView?.image != nil {
                cell.tag = indexPath.row
                cell.idEnt = el.idEnt
                if el.idEnt != nil,
                let curIm = self.getSavedImage(named: "\(el.idEnt!).jpg" ?? "")
            /*if let el = self.fetchedResultsController?.object(at: indexPath) as? Photo*/ {
                cell.curImageView?.image = curIm
                } else {
                }
            } else {
                
                cell.curImageView?.image = nil
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // This will cancel all unfinished downloading task when the cell disappearing.
        if let photoCell = cell as? CollectionViewCell {
            (cell as! CollectionViewCell).curImageView.kf.cancelDownloadTask()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        print("willDisplay indexPath.row = \(indexPath.row)")
        if indexPath.row == ((GridFirstViewController.perPage * curPageNumber) - 1),
            curPageNumber < 10 {
            //load next page
            curPageNumber = curPageNumber + 1
            print("willDisplay curPageNumber = \(curPageNumber)")
            ApiManager.shared().getPhotos(curPageNumber: curPageNumber, searchedText: curSearchText, completion: {  (data, response, error) in
                print("data = \(data)")
                print("response = \(response)")
                print("error = \(error)")
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, //mimeType.hasPrefix("application/json"),
                    let data = data, error == nil
                    
                    else {  if (error?.localizedDescription) != nil {
                        print((error?.localizedDescription)! as String)
                        }
                        return
                }
                
                
                do {
                    if response?.url?.pathComponents.contains("search") ?? false {
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
                        print("total = \(json["total"] as? Int), total_pages = \(json["total_pages"] as? Int)")
                        if let  total = json["total"] as? Int,
                            total > 0 {
                            do {
                                try self.treatmentSearchPhotos(photosDict: json as! Dictionary<String, AnyObject>)
                            } catch  {
                                print(error)
                            }
                        } else {
                        }
                        
                    } else {
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSArray
                        
                        if json.count > 0 {
                            do {
                                try self.treatmentPhotos(photosAr: json as! [Dictionary<String, AnyObject>])
                            } catch  {
                                print(error)
                            }
                        } else {
                        }
                    }
                    
                    
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
                
            })
            //ApiManager.shared().getPhotos(curPageNumber: curPageNumber, searchedText: curSearchText)
            
        }
        (cell as! CollectionViewCell).curImageView.kf.indicatorType = IndicatorType.activity
        let numberEl: Int = (fetchedResultsController.fetchedObjects?.count ?? 0)
        if let el =  self.fetchedResultsController?.object(at: indexPath) as? Photo
        {
            guard let _ = el.idEnt as? String
                else {
                    return
            }
            var urlString =  String(format: el.url ?? "-")
            //https://api.unsplash.com/photos/q3o_8MteFM0/download
            print(urlString)
            let url = URL(string:urlString)!
            
            _ = (cell as! CollectionViewCell).curImageView.kf.setImage(with: url)
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
            if let el = self.fetchedResultsController?.object(at: indexPath) as? Photo{
                selectedPhoto = el
                performSegue(withIdentifier: "showDetails", sender: self)
                
            }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showDetails" {
            if let vc = segue.destination as? DetailsViewController {
                vc.selectedPhoto = selectedPhoto
            }
        }
    }
 

}
