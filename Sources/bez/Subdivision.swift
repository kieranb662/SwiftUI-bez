//
//  Subdivision.swift
//  
//
//  Created by Kieran Brown on 3/21/20.
//

import CoreGraphics



/// # Line Subdivision
/// Divides a line into `n` equal segments
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func subdivideLine(start: CGPoint, end: CGPoint, numberOfSegments n: Int) -> [PolyBezierElement] {
    if n <= 0 { return [.line(to: end)] }
    var segments: [PolyBezierElement] = []
    for i in 1...n {
        segments.append(makeLineSegment(start: start, end: end, from: CGFloat(i-1)/CGFloat(n), to: CGFloat(i)/CGFloat(n)))
    }
    return segments
}


/// # Quadratic Bezier Subdivision
///
/// Subdivides a quadratic bezier into `n` segments of varying lengths, this is do to the nature of the parametric curve.
/// Equal line segments would require a number of calculations including numerical integration
///
/// - parameters:
///     - start: The starting point of the quadratic bézier curve
///     - end: The ending point of the quadratic bézier curve
///     - control: The control point of the quadratic bézier curve
///     - numberOfSegments: The number of quadratic bézier curves that the given curve will be divided into
///
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func subdivideQuadraticBezier(start: CGPoint, end: CGPoint, control: CGPoint, numberOfSegments n: Int) -> [PolyBezierElement] {
    if n <= 0 { return [.quad(to: end, control: control)] }
    var segments: [PolyBezierElement] = []
    for i in 1...n {
        segments.append(makeQuadSegment(start: start, end: end, control: control, from: CGFloat(i-1)/CGFloat(n), to: CGFloat(i)/CGFloat(n)))
    }
    return segments
}


/// # Cubic Bézier Subdivision
///
/// Subdivides a cubic bezier into `n` segments of varying lengths, this is do to the nature of the parametric curve.
/// Equal line segments would require a number of calculations including numerical integration
///
/// - parameters:
///     - start: The starting point for the Bézier curve
///     - end: The end point of the cubic Bézier
///     - control1: The first control point of the cubic bézier
///     - control2: The second control point of the cubic bézier
///     - numberOfSegments: The number of cubic bézier curves that the given curve will be divided into
///
///
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func subdivideCubicBezier(start: CGPoint, end: CGPoint, control1: CGPoint, control2: CGPoint, numberOfSegments n: Int) -> [PolyBezierElement] {
    if n <= 0 { return [.cubic(to: end, control1: control1, control2: control2)] }
    var segments: [PolyBezierElement] = []
    for i in 1...n {
        segments.append(makeCubicSegment(start: start, end: end, control1: control1, control2: control2, from: CGFloat(i-1)/CGFloat(n), to: CGFloat(i)/CGFloat(n)))
    }
    return segments
}


/// # Subdivide The Line Closing A Subpath
///
/// Similar to the ` subdivideLine` function with the only difference being that instead of creating `n` line segments this makes
/// `n-1` line segments and then appends a closeSubpath `PolyBezierElement`
///
/// - parameters:
///     - start: The starting point of the line. This generally will be the end point of the previous element in a `PolyBezierElement` array
///     - end: The end point of the line. This will be the position of the most recent moveTo command in a `PolyBezierElement`
///     - numberOfSegments: The number of segments the line will be divided into
///
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func subdivideClosingLine(start: CGPoint, end: CGPoint, numberOfSegments n: Int) -> [PolyBezierElement] {
    if n <= 0 { return [.closedSubPath()]}
    var segments: [PolyBezierElement] = []
    for i in 1..<n {
        segments.append(makeLineSegment(start: start, end: end, from: CGFloat(i-1)/CGFloat(n), to: CGFloat(i)/CGFloat(n)))
    }
    segments.append(.closedSubPath())
    return segments
}

/// # Subdivide Path
///
/// Given a set of `PolyBezierElements` generated from a path, this function divides each component into n segments.
/// No amount of fine grain control is given, this is a very simple subdivision.
///
/// - parameters:
///     - elements: The `PolyBezierElements` from the path to be subdivided
///     - numberOfSegments: The number of segments each individual element will be divided into
///
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func subdividePath(elements: [PolyBezierElement], numberOfSegments n: Int) -> [PolyBezierElement] {
    var newElements: [PolyBezierElement] = []
    var start: CGPoint = elements[0].currentPositions[0]
    var lastMoveTo: PolyBezierElement = elements[0]
    for element in elements {
        switch element.type {
        
        case .line:
            newElements.append(contentsOf: subdivideLine(start: start, end: element.currentPositions[0], numberOfSegments: n))
            start = element.currentPositions[0]
        case .quad:
            newElements.append(contentsOf: subdivideQuadraticBezier(start: start,
                                                                    end: element.currentPositions[0],
                                                                    control: element.currentPositions[1],
                                                                    numberOfSegments: n))
            start = element.currentPositions[0]
        case .cubic:
            newElements.append(contentsOf: subdivideCubicBezier(start: start,
                                                                end: element.currentPositions[0],
                                                                control1: element.currentPositions[1],
                                                                control2: element.currentPositions[2],
                                                                numberOfSegments: n))
            start = element.currentPositions[0]
        case .moveTo:
            newElements.append(element)
            start = element.currentPositions[0]
            lastMoveTo = element
        case .closeSubpath:
            newElements.append(contentsOf: subdivideClosingLine(start: start,
                                                                end: lastMoveTo.currentPositions[0],
                                                                numberOfSegments: n))
            start = lastMoveTo.currentPositions[0]
        }
    }
    return newElements
}
