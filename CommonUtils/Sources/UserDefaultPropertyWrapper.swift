//
//  UserDefaultPropertyWrapper.swift
//  Libs
//
//  Created by Hari on 28/10/25.
//

import Foundation

public protocol UserDefaultKey: CaseIterable {
    
    var rawValue: String { get }
}

/// Property wrapper to easily store, and retrieve values from the userDefaults standard container.
/// - GenericTypes
///     - `Value`: Type of the Value to be stored and retrieved.
///     - `Key`: Key should confirm to the Type UserDefaultKey
@propertyWrapper public struct UserDefault<Value, Key: UserDefaultKey> {
    
    /// fallback value, used when there is no value in the store or the type mismatches
    var defaultValue: Value
    
    /// value stored in the user default
    public var wrappedValue: Value {
        
        get {
            
            UserDefaults.standard.object(forKey: projectedValue.rawValue) as? Value ?? defaultValue
        }
        
        set {
            
            UserDefaults.standard.set(newValue, forKey: projectedValue.rawValue)
        }
    }
    
    /// returns the String key used to store the property
    public var projectedValue: Key
    
    // MARK: init
    /// init
    /// - Parameters:
    ///     - defaultValue: UserDefault property wrapper uses this default value when no value is found with the give key or the type provided mismatches. Default value provided through init wont affect/reflect in the stored value.
    ///     - key: Key with which values are stored and retrieved from the user default.
    public init(defaultValue: Value, key: Key) {
        
        self.defaultValue = defaultValue
        self.projectedValue = key
    }
}


@propertyWrapper public struct SecureCodingUserDefault<Value: NSSecureCoding & NSObject, Key: UserDefaultKey> {
    
    /// fallback value, used when there is no value in the store or the type mismatches
    var defaultValue: Value
    
    /// value stored in the user default
    public var wrappedValue: Value {
        
        get {
            
            
            guard let data = UserDefaults.standard.data(forKey: projectedValue.rawValue)
            else {
                
                return defaultValue
            }
            
            do {
                
                let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: Value.self, from: data)
                
                return decoded ?? defaultValue
            } catch {
                
                return defaultValue
            }
        }
        
        set {
            
            let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: projectedValue.rawValue)
        }
    }
    
    /// returns the String key used to store the property
    public var projectedValue: Key
    
    // MARK: init
    /// init
    /// - Parameters:
    ///     - defaultValue: UserDefault property wrapper uses this default value when no value is found with the give key or the type provided mismatches. Default value provided through init wont affect/reflect in the stored value.
    ///     - key: Key with which values are stored and retrieved from the user default.
    public init(defaultValue: Value, key: Key) {
        
        self.defaultValue = defaultValue
        self.projectedValue = key
    }
}


