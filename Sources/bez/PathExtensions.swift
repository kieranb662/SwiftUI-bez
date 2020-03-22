//
//  File.swift
//  
//
//  Created by Kieran Brown on 3/21/20.
//

import SwiftUI


// MARK: Path Extensions

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public extension Path {
    /// The array of `Path.Elements` describing the path
    var elements: [Path.Element] {
        var temp = [Path.Element]()
        forEach { (element) in
            temp.append(element)
        }
        return temp
    }
    
    /// Returns the starting point of the path
    func getStartPoint() -> CGPoint? {
        if isEmpty {
            return nil
        }
        
        guard let first = elements.first(where: {
            switch $0 {
            case .move(_):
                return true
            default:
                return false
            }
        }) else {
            return nil
        }
        
        switch first {
        case .move(let to):
            return to
        default:
            return nil
        }
    }
    
    /// Returns the last point on the path rom the last curve command
    func getEndPoint() -> CGPoint? {
        if isEmpty {
            return nil
        }
        
        guard let last = elements.reversed().first(where: { (element) in
            switch element {
            case .line(_), .quadCurve(_, _), .curve(_, _, _):
                return true
            case .move(_), .closeSubpath:
                return false
            }
        }) else {
            return nil
        }
        
        switch last {
        case .line(let to), .quadCurve(let to, _), .curve(let to, _, _):
            return to
        default:
            return nil
            
        }
    }
}
