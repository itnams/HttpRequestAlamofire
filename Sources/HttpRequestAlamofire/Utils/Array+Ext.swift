//
//  File.swift
//  
//
//  Created by ERM on 20/04/2022.
//

import Foundation

extension Array where Element == String {
    public func joined(with separator: String) -> String {
        return joined(separator: separator)
            .trimmingCharacters(in: CharacterSet.init(charactersIn: separator))
    }
}

