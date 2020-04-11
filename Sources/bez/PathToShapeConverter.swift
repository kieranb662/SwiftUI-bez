//
//  PathToShapeConverter.swift
//  
//
//  Created by Kieran Brown on 3/21/20.
//

import SwiftUI
import CGExtender
import simd

/// Takes in a `Path.description` string, normalizes it and then converts the normalized path into a SwiftUI `Shape` file. 
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func convertPath(path: String) -> String {
    var lookupTable = [CGPoint]()
    let p: Path = Path(path)!
    let elements = p.elements
    let threshold = 0.4
    var lastPoint: CGPoint = .zero
    var startingPoint: CGPoint = .zero
    let numOfDivisions: ClosedRange<Int> = 1...20
    
    for element in elements {
        switch element {
        case .move(let to):
            lookupTable.append(to)
            startingPoint = to
            lastPoint = to
        case .line(let to):
            numOfDivisions.forEach { (i) in
                let nextPossible = linearInterpolation(t: Float(i)/Float(numOfDivisions.upperBound), start: lastPoint, end: to)
                if sqrt((nextPossible - lookupTable.last!).magnitudeSquared) > threshold {
                    lookupTable.append(nextPossible)
                }
            }
            lastPoint = to
        case .quadCurve(let to, let control):
            numOfDivisions.forEach { (i) in
                let nextPossible = quadraticBezierInterpolation(t: Float(i)/Float(numOfDivisions.upperBound), start: lastPoint, control: control, end: to)
                if sqrt((nextPossible - lookupTable.last!).magnitudeSquared) > threshold {
                    lookupTable.append(nextPossible)
                }
            }
            lastPoint = to
        case .curve(let to, let control1, let control2):
            
            numOfDivisions.forEach { (i) in
                let nextPossible = cubicBezierInterpolation(t: Float(i)/Float(numOfDivisions.upperBound), start: lastPoint, control1: control1, control2: control2, end: to)
                if sqrt((nextPossible - lookupTable.last!).magnitudeSquared) > threshold {
                    lookupTable.append(nextPossible)
                }
            }
            lastPoint = to
        case .closeSubpath:
            numOfDivisions.forEach { (i) in
                let nextPossible = linearInterpolation(t: Float(i)/Float(numOfDivisions.upperBound), start: lastPoint, end: startingPoint)
                if sqrt((nextPossible - lookupTable.last!).magnitudeSquared) > threshold {
                    lookupTable.append(nextPossible)
                }
            }
        }
    }
    
    let minX: CGFloat = lookupTable.map({$0.x}).min() ?? 0
    let maxX: CGFloat = lookupTable.map({$0.x}).max() ?? 0
    let minY: CGFloat = lookupTable.map({$0.y}).min() ?? 0
    let maxY: CGFloat = lookupTable.map({$0.y}).max() ?? 0
    
    var shapeString: String = """

                    struct <#MyShape#>: Shape {
                        func path(in rect: CGRect) -> Path {
                            Path { path in
                                let w = rect.width
                                let h = rect.height

"""
    
    let endString: String = """

                            }
                        }
                    }
"""
    
    for element in elements {
        switch element {
        case .move(let to):
            let newX = (to.x - minX)/(maxX-minX)
            let newY = (to.y - minY)/(maxY-minY)
            shapeString.append(contentsOf: "\t\t\t\t\t\t\t\tpath.move(to: CGPoint(x: \(String(format: "%.3f" , Double(newX)))*w, y: \(String(format: "%.3f" , Double(newY)))*h)) \n")
        case .line(let to):
            let newX = (to.x - minX)/(maxX-minX)
            let newY = (to.y - minY)/(maxY-minY)
            shapeString.append(contentsOf: "\t\t\t\t\t\t\t\tpath.addLine(to: CGPoint(x: \(String(format: "%.3f" , Double(newX)))*w, y: \(String(format: "%.3f" , Double(newY)))*h)) \n")
        case .quadCurve(let to, let control):
            let newX = (to.x - minX)/(maxX-minX)
            let newY = (to.y - minY)/(maxY-minY)
            let newX1 = (control.x - minX)/(maxX-minX)
            let newY1 = (control.y - minY)/(maxY-minY)
            shapeString.append(contentsOf: "\t\t\t\t\t\t\t\tpath.addQuadCurve(to: CGPoint(x: \(String(format: "%.3f" , Double(newX)))*w, y: \(String(format: "%.3f" , Double(newY)))*h), control: CGPoint(x: \(String(format: "%.3f" , Double(newX1)))*w, y: \(String(format: "%.3f" , Double(newY1)))*h)) \n")
        case .curve(let to, let control1, let control2):
            let newX = (to.x - minX)/(maxX-minX)
            let newY = (to.y - minY)/(maxY-minY)
            let newX1 = (control1.x - minX)/(maxX-minX)
            let newY1 = (control1.y - minY)/(maxY-minY)
            let newX2 = (control2.x - minX)/(maxX-minX)
            let newY2 = (control2.y - minY)/(maxY-minY)
            shapeString.append(contentsOf: "\t\t\t\t\t\t\t\tpath.addCurve(to: CGPoint(x: \(String(format: "%.3f" , Double(newX)))*w, y: \(String(format: "%.3f" , Double(newY)))*h), control1: CGPoint(x: \(String(format: "%.3f" , Double(newX1)))*w, y: \(String(format: "%.3f" , Double(newY1)))*h), control2: CGPoint(x: \(String(format: "%.3f" , Double(newX2)))*w, y: \(String(format: "%.3f" , Double(newY2)))*h)) \n")
        case .closeSubpath:
            shapeString.append(contentsOf: "\t\t\t\t\t\t\t\tpath.closeSubpath()")
        }
    }
    return shapeString + endString
}
