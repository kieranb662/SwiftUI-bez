//
//  File.swift
//  
//
//  Created by Kieran Brown on 3/21/20.
//

import SwiftUI
import CGExtender
import simd


// MARK: - LookUp Table Utilities
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func segmentLength(lastPoint: CGPoint, element: Path.Element) -> Double {
    switch element {
        
    case .move(_):
        return 0
    case .line(let to):
        return sqrt((to - lastPoint).magnitudeSquared)
    case .quadCurve(let to, let control):
        var tempTotal: Double = 0
        var tempLast: CGPoint = lastPoint
        for i in 1...20 {
            let new = quadraticBezierInterpolation(t: Float(i)/Float(20), start: lastPoint, control: control, end: to)
            tempTotal += sqrt((new-tempLast).magnitudeSquared)
            tempLast = new
        }
        return tempTotal
    case .curve(let to, let control1, let control2):
        var tempTotal: Double = 0
        var tempLast: CGPoint = lastPoint
        for i in 1...20 {
            let new = cubicBezierInterpolation(t: Float(i)/Float(20), start: lastPoint, control1: control1, control2: control2, end: to)
            tempTotal += sqrt((new-tempLast).magnitudeSquared)
            tempLast = new
        }
        return tempTotal
    case .closeSubpath:
        return 0
    }
}
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func quickLengths(path: Path) -> [Double] {
    let elements = path.elements
    var lastPoint: CGPoint = .zero
    var startingPoint: CGPoint = .zero
    var segmentLengths: [Double] = []
    for element in elements {
        switch element {
            
        case .move(let to):
            startingPoint = to
            lastPoint = to
        case .line(let to):
            segmentLengths.append(sqrt((to - lastPoint).magnitudeSquared))
            lastPoint = to
        case .quadCurve(let to, let control):
            var tempTotal: Double = 0
            var tempLast: CGPoint = lastPoint
            for i in 1...20 {
                let new = quadraticBezierInterpolation(t: Float(i)/Float(20), start: lastPoint, control: control, end: to)
                tempTotal += sqrt((new-tempLast).magnitudeSquared)
                tempLast = new
            }
            segmentLengths.append(tempTotal)
            lastPoint = to
            
        case .curve(let to, let control1, let control2):
            var tempTotal: Double = 0
            var tempLast: CGPoint = lastPoint
            for i in 1...20 {
                let new = cubicBezierInterpolation(t: Float(i)/Float(20), start: lastPoint, control1: control1, control2: control2, end: to)
                tempTotal += sqrt((new-tempLast).magnitudeSquared)
                tempLast = new
            }
            segmentLengths.append(tempTotal)
            lastPoint = to
        case .closeSubpath:
            segmentLengths.append(sqrt((lastPoint - startingPoint).magnitudeSquared))
            lastPoint = startingPoint
        }
    }
    return segmentLengths
}

/// Iterates through all path elements and samples interpolated points on that segment (1 + numberOfDivisions) times
/// using the parametric representation of the specific Bézier curve.
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func generateLookupTable(path: Path) -> [CGPoint] {
    let elements = path.elements
    let lookupTableCapacity = 300
    var lookupTable = [CGPoint]()
    let threshold: Double = 1
    
    let count = elements.count
    guard count > 0 else { return [] }
    var lastPoint: CGPoint = .zero
    var startingPoint: CGPoint = .zero
    let totalLength = quickLengths(path: path).reduce(0, +)
    guard totalLength > 0 else {return []}
    for element in elements {
        switch element {
            
        case .move(let to):
            lookupTable.append(to)
            startingPoint = to
            lastPoint = to
            
        case .line(let to):
            let numOfDivisions = Double(lookupTableCapacity)*segmentLength(lastPoint: lastPoint, element: element)/totalLength
            let divisions = 0...Int(numOfDivisions)
            
            divisions.forEach { (i) in
                
                let nextPossible = linearInterpolation(t: Float(i)/Float(numOfDivisions), start: lastPoint, end: to)
                if sqrt((nextPossible - lookupTable.last!).magnitudeSquared) > threshold {
                    lookupTable.append(nextPossible)
                }
            }
            lastPoint = to
            
        case .quadCurve(let to, let control):
            let numOfDivisions = Double(lookupTableCapacity)*segmentLength(lastPoint: lastPoint, element: element)/totalLength
            let divisions = 0...Int(numOfDivisions)
            
            divisions.forEach { (i) in
                let nextPossible = quadraticBezierInterpolation(t: Float(i)/Float(numOfDivisions), start: lastPoint, control: control, end: to)
                if sqrt((nextPossible - lookupTable.last!).magnitudeSquared) > threshold {
                    lookupTable.append(nextPossible)
                }
            }
            lastPoint = to
            
        case .curve(let to, let control1, let control2):
            let numOfDivisions = Double(lookupTableCapacity)*segmentLength(lastPoint: lastPoint, element: element)/totalLength
            let divisions = 0...Int(numOfDivisions)
            divisions.forEach { (i) in
                let nextPossible = cubicBezierInterpolation(t: Float(i)/Float(numOfDivisions), start: lastPoint, control1: control1, control2: control2, end: to)
                if sqrt((nextPossible - lookupTable.last!).magnitudeSquared) > threshold {
                    lookupTable.append(nextPossible)
                }
            }
            lastPoint = to
            
        case .closeSubpath:
            let length: Double = sqrt((lastPoint-startingPoint).magnitudeSquared)
            let numOfDivisions = Double(lookupTableCapacity)*length/totalLength
            let divisions = 0...Int(numOfDivisions)
            divisions.forEach { (i) in
                let nextPossible = linearInterpolation(t: Float(i)/Float(numOfDivisions), start: lastPoint, end: startingPoint)
                if sqrt((nextPossible - lookupTable.last!).magnitudeSquared) > threshold {
                    lookupTable.append(nextPossible)
                }
            }
            
        }
    }
    return lookupTable
}

/// Returns the approximate closest point on the path from the given point
public func getClosestPoint(_ from: CGPoint, lookupTable: [CGPoint]) -> CGPoint {
    
    let minimum = {
        (0..<lookupTable.count).map {
            (distance: distance_squared(simd_double2(x: Double(from.x), y:Double(from.y)), simd_double2(x: Double(lookupTable[$0].x), y: Double(lookupTable[$0].y))), index: $0)
        }.min {
            $0.distance < $1.distance
        }
    }()
    
    return lookupTable[minimum!.index]
}
/// Returns the percent based location in the lookup table 
public func getPercent(_ from: CGPoint, lookupTable: [CGPoint]) -> CGFloat {
    let minimum = {
        (0..<lookupTable.count).map {
            (distance: distance_squared(simd_double2(x: Double(from.x), y:Double(from.y)), simd_double2(x: Double(lookupTable[$0].x), y: Double(lookupTable[$0].y))), index: $0)
        }.min {
            $0.distance < $1.distance
        }
    }()
    guard lookupTable.count >= 2 && minimum != nil else {return 0}
    
    return CGFloat(minimum!.index)/CGFloat(lookupTable.count-1)
}
