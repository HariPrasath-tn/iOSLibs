//
//  PredicateSortDescriptor.swift
//  CoredataWrapperLib
//
//  Created by Hari on 23/10/25.
//


import Foundation
import CoreData


// TODO: Need to implement this and change all the model to use this
// MARK: - PredicateSortDescriptor
/// PredicateSortDescriptor is a type safe predicate generator, to reduce the predicate mismatch
public struct PredicateSortDescriptor<T: NSManagedObject> {
    
    public var predicate: Predicate<T>?
    
    public var sortDescriptors: [SortDescriptor<T>] = []
    
    public var limit: Int?
    
    private var _nsPredicate: NSPredicate?
    
    private var _nsSortDescriptor: [NSSortDescriptor] = []
    

    public init(predicate: Predicate<T>?, sortDescriptors: [SortDescriptor<T>], limit: Int? = nil) {
        
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.limit = limit
    }
    
    public init(nsPredicate: NSPredicate?, nsSortDescriptors: [NSSortDescriptor] = [], limit: Int? = nil) {
        
        self._nsPredicate = nsPredicate
        self._nsSortDescriptor = nsSortDescriptors
        self.limit = limit
    }
    
    public var nsPredicate: NSPredicate? {
        
        return if let _nsPredicate { _nsPredicate } else if let predicate { NSPredicate(predicate) }
            else { nil }
    }
    
    public var nsSortDescriptors: [NSSortDescriptor]? {
        
        return if !_nsSortDescriptor.isEmpty { _nsSortDescriptor } else if !sortDescriptors.isEmpty { sortDescriptors.map { NSSortDescriptor($0) } }
        else { nil }
    }
}


// MARK: - General Custom predicate
extension PredicateSortDescriptor {
    
    public static func none() -> PredicateSortDescriptor {
        
        .init(predicate: nil, sortDescriptors: [])
    }
    
    public static func custom(
        predicate: Predicate<T>?,
        sortDescriptors: [SortDescriptor<T>],
        limit: Int? = nil
    ) -> PredicateSortDescriptor {
        
        .init(predicate: predicate, sortDescriptors: sortDescriptors, limit: limit)
    }
    
    public static func custom(
        nsPredicate: NSPredicate?,
        nsSortDescriptors: [NSSortDescriptor] = [],
        limit: Int? = nil
    ) -> PredicateSortDescriptor {
        
        .init(nsPredicate: nsPredicate, nsSortDescriptors: nsSortDescriptors, limit: limit)
    }
}
