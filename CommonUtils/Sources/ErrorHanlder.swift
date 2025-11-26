//
//  ErrorHandler.swift
//  Libs
//
//  Created by Hari on 25/11/25.
//

import Foundation

public func handleError(caller: String, block: @escaping () throws -> Void, errorBlock: ((Error) -> Void)? = nil) {
    
    do {
        
        try block()
    } catch {
        
        if let errorBlock {
            
            errorBlock(error)
        } else {
            
            debugPrint("[-] execution Failed in \(caller): \(error)")
        }
    }
}

public func handleError(caller: String, block: @escaping () async throws -> Void, errorBlock: ((Error) async -> Void)? = nil) async {
    
    do {
        
        try await block()
    } catch {
        
        if let errorBlock {
            
            await errorBlock(error)
        } else {
            
            debugPrint("[-] execution Failed in \(caller): \(error)")
        }
    }
}
