//
//  DBContainer.swift
//  CoredataWrapperLib
//
//  Created by Hari on 23/10/25.
//


import CoreData


class PersistenceManager {
    
    var container: NSPersistentContainer
    
    private var registerTransformars: (() -> ())? = nil
    
    private let containerName: String
    
    private let dbStorageLocation: DBStorageLocation
    
    init(
        isInMemoryOnlyMode: Bool = false,
        containerName: String = "Model",
        registerTransformars: (() -> ())? = nil,
        dbStorageLocation: DBStorageLocation = .app
    ) {
        
        self.container = .init(name: containerName)
        self.containerName = containerName
        self.dbStorageLocation = dbStorageLocation
        self.registerTransformars = registerTransformars
    }
    
    func initialseNewContainer(
        newDBStorageLocation: DBStorageLocation,
        containerName: String,
        _ isInMemoryOnlyMode: Bool = false
    ) throws {
        
        try? self.deleteStoreIfExists(storeName: containerName)
        // TODO: Need to find a way to work with multiple container and multiple persistent stores
        if isInMemoryOnlyMode {
            
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            
        } else {
            
            let url = containerUrl(storeName: containerName)
            let storeDescription = NSPersistentStoreDescription(url: url)
            container.persistentStoreDescriptions = [storeDescription]
        }
        container.loadPersistentStores { _, error in
            
            if let error {
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        // Merge policy ensures local changes have priority in conflict
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.automaticallyMergesChangesFromParent = true
        #if DEBUG
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            
            debugPrint("[+] CoreData Store Location: \(storeURL.absoluteString)")
            _ = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                
                debugPrint("[+] CoreData Store Location: \(storeURL.absoluteString)")
            }
        }
        #endif
    }
    
    // MARK: - Store URL Helpers
    /// Returns the file URL of the persistent store.
    /// Customize to point to an App Group or a local app container.
    private func containerUrl(storeName: String) -> URL {
        
        if case let .appGroup(appGroup) = dbStorageLocation,
           let containerURL = FileManager.default
               .containerURL(forSecurityApplicationGroupIdentifier: appGroup){
            
            return containerURL.appendingPathComponent(storeName)
        } else {
            
            // Default storage path - using application support directory
            let fileManager = FileManager.default
            let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            let appSupportURL = urls[0]
            // Ensure the directory exists
            try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            
            return appSupportURL.appendingPathComponent(storeName)
        }
    }
    
    
    func deleteStoreIfExists(storeName: String) throws {
        
        let storePath = containerUrl(storeName: storeName).path
        
        if FileManager.default.fileExists(atPath: storePath) {
            
            do {
                
                try FileManager.default.removeItem(atPath: storePath)
                
            } catch {
                
                debugPrint("[-] Error removing existing store: \(error)")
                
            }
            
        }
    }
}
