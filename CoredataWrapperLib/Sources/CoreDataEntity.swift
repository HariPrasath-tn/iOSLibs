//
//  CoreDataEntity.swift
//  CoredataWrapperLib
//
//  Created by Hari on 23/10/25.
//


import CoreData
import Foundation


// MARK: - CoreDataEntity Protocol
/// Protocol to unify entity-related methods and defaults.
nonisolated public protocol CoreDataEntity: NSManagedObject {
    
    static var entityName: String { get }
    
    var cUniqueid: String? { get }

    nonisolated static func entityFetchRequest(predicate: PredicateSortDescriptor<Self>?) -> NSFetchRequest<Self>
    
    init(context: NSManagedObjectContext)
}

// MARK: - CoreDataEntity Default Implementations
extension CoreDataEntity {
    
    public static var entityName: String {
        
        String(describing: Self.self)
    }
    
    func delete() async throws {
        
//        try await CoreDataDB.shared.delete([self])
    }
    
    // MARK: Save
    /// Saves the current context if it has changes.
    public func save() throws {
        
        guard let context = self.managedObjectContext, context.hasChanges else { return }
        try context.save()
    }
    
    // MARK: Refresh
    /// Ensures the entity is in a non-faulted state in the main context.
    @MainActor func refresh() -> Self {
        
        guard isFault else { return self }
        let context = CoreDataDB.shared.mainContext
        
        return context.object(with: objectID) as! Self
    }
    
    // MARK: Update
    /// Saves the context if there are changes.
    public func update() throws {
        
        try save()
    }
    
    @MainActor public static func get(fetchRequest: NSFetchRequest<Self>) throws -> [Self] {
        
        do {
            
            return try CoreDataDB.shared.mainContext.fetch(fetchRequest)
        } catch {
            
            debugPrint("[CoreDataEntity] Failed to fetch entities: \(error)")
            throw error
        }
    }
    
    // MARK: entityFetchRequest
    /// Method to generate the fetch request for the current NSManagedObject
    public static func entityFetchRequest(predicate: PredicateSortDescriptor<Self>?) -> NSFetchRequest<Self> {
        
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.returnsObjectsAsFaults = false
        if let predicate = predicate?.predicate {
            
            request.predicate = NSPredicate(predicate)
        }
        if let sortDescriptors = predicate?.sortDescriptors  {
            
            request.sortDescriptors = sortDescriptors.compactMap { NSSortDescriptor($0) }
        }
        if let limit = predicate?.limit {
            
            request.fetchLimit = limit
        }
        
        return request
    }
    
    // FIXME: Code below and the code in the context extenxion are having the same repetative code so need to make the code's source of truth one
    // TODO: Need to optimise these function usage by providing support for fetch from background thread too
    // MARK: Get First
    /// Returns the first entity matching the given predicate in the main context.
    @MainActor public static func GetFirst(predicate: PredicateSortDescriptor<Self>? = nil) throws -> Self? {
        
        do {
            
            return try CoreDataDB.shared.mainContext.fetch(entityFetchRequest(predicate: predicate)).first
        } catch {
            
            debugPrint("[CoreDataEntity] Failed to fetch entities: \(error)")
            throw error
        }
    }
    
    // FIXME: Code below and the code in the context extenxion are having the same repetative code so need to make the code's source of truth one
    // MARK: Get
    /// Returns all entities matching the given predicate in the main context.
    @MainActor public static func Get(predicate: PredicateSortDescriptor<Self>? = nil) throws -> [Self] {
        
        do {
            
            return try CoreDataDB.shared.mainContext.fetch(entityFetchRequest(predicate: predicate))
        } catch {
            
            debugPrint("[CoreDataEntity] Failed to fetch entities: \(error)")
            throw error
        }
    }
    
    // FIXME: Code below and the code in the context extenxion are having the same repetative code so need to make the code's source of truth one
    // MARK: Get Count
    /// Returns the count of entities matching the given predicate in the main context.
    @MainActor public static func GetCount(predicate: PredicateSortDescriptor<Self>? = nil) throws -> Int {
        
        do {
            
            return try CoreDataDB.shared.fetchCount(entityFetchRequest(predicate: predicate))
        } catch {
            
            debugPrint("[CoreDataEntity] Failed to fetch entity count: \(error)")
            throw error
        }
    }
    
    // FIXME: Code below and the code in the context extenxion are having the same repetative code so need to make the code's source of truth one
    // MARK: Batch Delete Objects
    /// Performs a batch delete for the entity, using the given predicate if provided.
    public static func batchDelete(
        _ predicate: PredicateSortDescriptor<Self>? = nil
    ) async throws {
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        if let predicate = predicate?.nsPredicate {
            
            fetchRequest.predicate = predicate
        }
        if let limit = predicate?.limit { // TODO: Need to verify whether this is useful in batch delete. if may be use ful to delete first particular number of items
            
            fetchRequest.fetchLimit = limit
        }
        try await CoreDataDB.shared.batchDelete(fetchRequest)
    }
    
//    TODO: Need to find a best solution for this
//    static func delete(predicate: PredicateSortDescriptor<Self>? = nil) async throws {
//
//        let objects = try Get(predicate: predicate)
//        for object in objects {
//
//            try CoreDataDB.shared.delete(objects)
//        }
//    }
}
