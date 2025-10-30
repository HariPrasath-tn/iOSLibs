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
            
            if let cls = (Value.self as Any) as? AnyClass, (cls is NSSecureCoding.Type) {
                        
                guard let data = UserDefaults.standard.data(forKey: projectedValue.rawValue)
                else {
                    
                    return defaultValue
                }
                
                do {
                    
                    // Allow only the target class (add container classes if you store collections)
                    let allowed: [AnyClass] = [cls]
                    let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClasses: allowed, from: data)
                    
                    return (decoded as? Value) ?? defaultValue
                } catch {
                    
                    return defaultValue
                }
            }
            
            return UserDefaults.standard.object(forKey: projectedValue.rawValue) as? Value ?? defaultValue
        }
        
        set {
            
            if let cls = (Value.self as Any) as? AnyClass, (cls is NSSecureCoding.Type) {
                        
                // newValue must be an NSObject & NSSecureCoding at runtime to archive it
                if let obj = newValue as? (NSObject & NSSecureCoding) {
                    do {
                        let data = try NSKeyedArchiver.archivedData(withRootObject: obj, requiringSecureCoding: true)
                        UserDefaults.standard.set(data, forKey: projectedValue.rawValue)
                        
                        return
                    } catch {
                        // fall through to clear if we can’t archive
                        UserDefaults.standard.removeObject(forKey: projectedValue.rawValue)
                        
                        return
                    }
                } else {
                    // Value was declared NSSecureCoding-capable, but the instance isn’t – clear to be safe
                    UserDefaults.standard.removeObject(forKey: projectedValue.rawValue)
                    
                    return
                }
            }
            
            // Plist-compatible path
            UserDefaults.standard.set(newValue, forKey: projectedValue.rawValue)
            
            return
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
