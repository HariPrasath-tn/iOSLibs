//
//  CoredataWrapperLib.swift
//  CoredataWrapperLib
//
//  Created by Hari on 15/10/25.
//

import CoreData
import Foundation

enum DBStorageLocation {
    
    case appGroup(identifier: String), app
}

import CoreData
import Foundation

// MARK: - CoreDataDB Global Actor
/// A global actor responsible for managing CoreData operations.
///
/// All operations on persistent containers and NSManagedObjectContexts
/// should be confined to this actor to avoid concurrency issues.
@globalActor

public actor CoreDataDB {
    
    public static let shared = CoreDataDB()
    
    public typealias ActorType = CoreDataDB
    
    let dbStorageLocation: DBStorageLocation
    
    let isInMemoryOnlyMode: Bool
    
    // MARK: - Persistent Container
    /// The main persistent container used to manage the CoreData stack.
    /// Use `mainContext` or `newBackgroundContext()` for CRUD operations.
    nonisolated(unsafe) private var container: NSPersistentContainer
    
    // MARK: - Main Context (on MainActor)
    /// The main context associated with the container's viewContext.
    /// Must be accessed on the main actor.
    @MainActor
    public var mainContext: NSManagedObjectContext {
        container.viewContext
    }
    
    @MainActor public lazy var temporaryBackgroundContext: NSManagedObjectContext = {
        
        let context = container.newBackgroundContext()
        
        return context
    }()
    
    // MARK: - Initialization
    /// Initializes the global CoreDataDB actor and loads persistent stores.
    /// If loading fails, the app will terminate with a fatalError.
    private init(
        isInMemoryOnlyMode: Bool = false,
        containerName: String = "PhotosExplorer",
        registerTransformars: (() -> ())? = nil,
        dbStorageLocation: DBStorageLocation = .app
    ) {
        
        registerTransformars?()
        self.dbStorageLocation = dbStorageLocation
        self.isInMemoryOnlyMode = isInMemoryOnlyMode
        container = NSPersistentContainer(name: containerName)
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
//#if !WIDGET
//        Task {
//            try await UploadEntity.batchDelete()
//        }
//#endif
    }
    
    
    // MARK: - Context Creation
    /// Creates and returns a new background context configured for this container.
    /// Use this context for non-UI (background) operations to avoid blocking the main thread.
    private func newBackgroundContext() -> NSManagedObjectContext {
        
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        return context
    }
    
    // MARK: - Saving
    /// Saves the given context if there are changes. Throws on failure.
    private func saveContext(_ context: NSManagedObjectContext) throws {
        
        guard context.hasChanges
        else { return }
        try context.save()
    }
    
    // MARK: - ZillumDatabase Operations
    
    // MARK: Destroy Persistent Store
    /// Deletes all data for every entity in the main context, then resets the context.
    /// This should be called on the main actor as it operates on `mainContext`.
    @MainActor
    public func destroyPersistentStoreData() throws {
        
        let entities = Array(container.managedObjectModel.entitiesByName.keys)
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try mainContext.execute(batchDeleteRequest)
            } catch {
                debugPrint("[+] Error executing batch delete for \(entityName): \(error.localizedDescription)")
                throw error
            }
        }
        mainContext.reset()
    }
    
    // MARK: Delete All Data
    /// Deletes all instances of the given CoreData entity type in a background context,
    /// and then saves. This is an async method that will switch to a background context.
    func deleteAllData<Entity: CoreDataEntity>(_ type: Entity.Type) async throws {
        
        let bgContext = newBackgroundContext()
        let fetchRequest = Entity.entityFetchRequest(predicate: .none())
        do {
            
            let results = try bgContext.fetch(fetchRequest)
            for object in results {
                
                bgContext.delete(object)
            }
            try saveContext(bgContext)
        } catch {
            
            debugPrint("[-] Error deleting all data in \(type): \(error)")
            throw error
        }
    }
    
    /// Returns the count of entities matching the given `fetchRequest` in the main context.
    @MainActor
    public func fetchCount<T: NSManagedObject>(_ fetchRequest: NSFetchRequest<T>) throws -> Int {
        
        fetchRequest.resultType = .countResultType
        return try mainContext.count(for: fetchRequest)
    }
    
    // MARK: Fetching
    /// Fetches entities matching the given `fetchRequest`. If a context is provided,
    /// that context is used; otherwise, a new background context is used.
    public func fetch<T: NSManagedObject>(
        _ fetchRequest: NSFetchRequest<T>,
        context: NSManagedObjectContext? = nil
    ) async throws -> [T] {
        
        let contextToUse = context ?? newBackgroundContext()
        fetchRequest.returnsObjectsAsFaults = false
        
        return try contextToUse.fetch(fetchRequest)
    }
    
    // MARK: - Store URL Helpers
    /// Returns the file URL of the persistent store.
    /// Customize to point to an App Group or a local app container.
    nonisolated public func containerUrl(storeName: String) -> URL {
        
        let storeName = storeName + ".sqlite"
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
    
    /// Deletes the existing store at the specified path (if it exists).
    /// Typically used only for debugging or testing scenarios.
    private func deleteStoreIfExists(storeName: String) {
    
        let storeName = storeName + ".sqlite"
        let storePath = containerUrl(storeName: storeName).path
        
        if FileManager.default.fileExists(atPath: storePath) {
            
            do {
                
                try FileManager.default.removeItem(atPath: storePath)
                
            } catch {
                
                debugPrint("[-] Error removing existing store: \(error)")
                
            }
            
        }
        
    }
    
    public func backgroudContext() -> NSManagedObjectContext {
        
        let backgroundContext = newBackgroundContext()
        
        return backgroundContext
        
    }
    
}


// MARK: - Async Functionalities
public extension CoreDataDB {
    
    
    // MARK: Insert (Single Object)
    /// Inserts a single managed object (created via a closure) into a background context,
    /// saves it, and then returns it. Accepts a completion closure for further usage.
    @discardableResult
    func insert<T: NSManagedObject>(
        _ createBlock: @escaping (NSManagedObjectContext) async -> T,
        completion: @escaping (T) -> Void = { _ in }
    ) async throws -> T {
        
        let bgContext = newBackgroundContext()
        // Create the model inside the background context
        let model = await createBlock(bgContext)
        bgContext.insert(model)
        do {
            try saveContext(bgContext)
        } catch {
            debugPrint("[-] Error inserting object: \(error)")
            throw error
        }
        
        completion(model)
        return model
    }
    
    // MARK: Insert (Multiple Objects)
    /// Inserts multiple objects (created via a closure) into a background context,
    /// saves them, and then returns them. Accepts a completion closure for further usage.
    @discardableResult
    func insert<T: NSManagedObject>(
        _ createBlock: @escaping (NSManagedObjectContext) async -> [T],
        completion: @escaping () -> Void = {}
    ) async throws -> [T] {
        
        let bgContext = newBackgroundContext()
        let models = await createBlock(bgContext)
        
        for model in models {
            bgContext.insert(model)
        }
        
        do {
            try saveContext(bgContext)
        } catch {
            debugPrint("[-] Error inserting objects: \(error)")
            throw error
        }
        
        completion()
        return models
    }
    
    // MARK: Insert (Multiple Objects)
    /// Inserts multiple objects (created via a closure) into a background context,
    /// saves them, and then returns them. Accepts a completion closure for further usage.
    @discardableResult
    func insert<T: NSManagedObject>(
        _ createBlock: @escaping (NSManagedObjectContext) async throws -> [T],
        completion: @escaping () -> Void = {}
    ) async throws -> [T] {
        let bgContext = newBackgroundContext()
        let models = try await createBlock(bgContext)
        
        for model in models {
            bgContext.insert(model)
        }
        
        do {
            try saveContext(bgContext)
        } catch {
            debugPrint("[-] Error inserting objects: \(error)")
            throw error
        }
        
        completion()
        return models
    }
    
    // MARK: Delete (Single Object)
    /// Deletes a specific managed object from a background context and saves.
    func delete<T: NSManagedObject>(
        _ object: T
    ) async throws {
        let bgContext = newBackgroundContext()
        // Convert object to the background context if needed
        if let existingObject = bgContext.object(with: object.objectID) as? T {
            bgContext.delete(existingObject)
            do {
                try saveContext(bgContext)
            } catch {
                debugPrint("[-] Error deleting object: \(error)")
                throw error
            }
        }
    }
    
    // MARK: Delete (Multiple Objects)
    /// Deletes multiple managed objects from a background context and saves.
    func delete<T: NSManagedObject>(_ objects: [T]) async throws {
        let bgContext = newBackgroundContext()
        for object in objects {
            let existingObject = bgContext.object(with: object.objectID)
            bgContext.delete(existingObject)
        }
        do {
            try saveContext(bgContext)
        } catch {
            debugPrint("[-] Error deleting objects: \(error)")
            throw error
        }
    }
    
    
    // MARK: Delete by Predicate
    /// Deletes all objects that match a specific predicate for the given entity type.
    func delete<T: CoreDataEntity>(
        _ type: T.Type,
        predicate: PredicateSortDescriptor<T>
    ) async throws {
        let bgContext = newBackgroundContext()
        let request = T.entityFetchRequest(predicate: predicate)
        do {
            let models = try bgContext.fetch(request)
            for model in models {
                bgContext.delete(model)
            }
            try saveContext(bgContext)
        } catch {
            debugPrint("[-] Error deleting by predicate: \(error)")
            throw error
        }
    }
    
    // MARK: Batch Delete
    /// Performs a batch delete for the given fetch request in a background context.
    /// Resets both the background and main contexts to ensure consistency.
    nonisolated func batchDelete(
        _ fetchRequest: NSFetchRequest<NSFetchRequestResult>
    ) async throws {
        
        let bgContext = await newBackgroundContext()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        do {
            // Execute batch delete in background context
            let result = try bgContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
            if let ids = result?.result as? [NSManagedObjectID] {
                
                let changes: [AnyHashable: Any] = [ NSDeletedObjectsKey: ids ]
                await NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [mainContext])
            } else {
                
                try await saveContext(bgContext)
                bgContext.reset()
                // Reset main context on the main actor
                await MainActor.run {
                    
                    do {
                        
                        if self.mainContext.hasChanges {
                            
                            try self.mainContext.save()
                        }
                        self.mainContext.reset()
                    } catch {
                        debugPrint("[-] Error saving mainContext after batch delete: \(error)")
                    }
                }
            }
        } catch {
            
            debugPrint("[-] Error executing batch delete: \(error)")
            throw error
        }
    }
    
    // MARK: Counting
    /// Returns the count of entities matching the given `fetchRequest` in a background context.
    func fetchEntitiesCount<T: NSManagedObject>(
        _ fetchRequest: NSFetchRequest<T>
    ) async throws -> Int {
        
        let bgContext = newBackgroundContext()
        fetchRequest.resultType = .countResultType
        return try bgContext.count(for: fetchRequest)
    }
}



// MARK: - Context Data fetch operations
public extension NSManagedObjectContext {
    
    func getObject<T: NSManagedObject & CoreDataEntity>(predicate: PredicateSortDescriptor<T>) -> T {
        
        let obj = (try? self.GetFirst(type: T.self, predicate: predicate)) ?? T.init(context: self)
        
        return obj
    }
    
    /*
     TODO: Need to optimise all the function in this extension duplicating the following code. need to reuse the code in the CoreDatEntity protocol
     
     let fetchRequest: NSFetchRequest<T> = NSFetchRequest<T>(entityName: T.description())
     fetchRequest.predicate = predicate.nsPredicate
     fetchRequest.sortDescriptors = predicate.nsSortDescriptors
     
     */
    func GetFirst<T: NSManagedObject>(type: T.Type, predicate: PredicateSortDescriptor<T>) throws -> T? {
        
        let fetchRequest: NSFetchRequest<T> = NSFetchRequest<T>(entityName: T.description())
        fetchRequest.predicate = predicate.nsPredicate
        fetchRequest.sortDescriptors = predicate.nsSortDescriptors
        
        return try fetch(fetchRequest).first
    }
    
    // TODO: For now providing limit wont have any effect. but need to fix this in future.
    func getEntitiesCount<T: NSManagedObject>(type: T.Type, predicate: PredicateSortDescriptor<T>) throws -> Int {
        
        let fetchRequest: NSFetchRequest<T> = NSFetchRequest<T>(entityName: T.description())
        fetchRequest.predicate = predicate.nsPredicate
        fetchRequest.sortDescriptors = predicate.nsSortDescriptors
        fetchRequest.resultType = .countResultType
        
        return try count(for: fetchRequest)
    }
    
    
    func Get<T: NSManagedObject>(type: T.Type, predicate: PredicateSortDescriptor<T>) throws -> [T] {
        
        let fetchRequest: NSFetchRequest<T> = NSFetchRequest<T>(entityName: T.description())
        fetchRequest.predicate = predicate.nsPredicate
        fetchRequest.sortDescriptors = predicate.nsSortDescriptors
        if let limit = predicate.limit {
            fetchRequest.fetchLimit = limit
        }
        
        return try fetch(fetchRequest)
    }
    
    func batchDelete<T: NSManagedObject>(type: T.Type, predicate: PredicateSortDescriptor<T>) async throws {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.description())
        
        fetchRequest.predicate = predicate.nsPredicate
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            
            try self.execute(batchDeleteRequest)
            
        } catch {
            
            debugPrint("[+] Error executing batch delete for \(T.self): \(error.localizedDescription)")
            
            throw error
            
        }
    }
}
