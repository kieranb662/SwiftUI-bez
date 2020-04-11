//
//  File.swift
//  
//
//  Created by Kieran Brown on 3/21/20.
//

import CoreGraphics
import simd


// MARK: Bézier Segmentation

/// # Makes a Line Segment From The Parameters
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func makeLineSegment(start: CGPoint, end: CGPoint, from: CGFloat, to: CGFloat) -> PolyBezierElement {
    let s = Float(from)
    let f = Float(to)
    let p0 = start.tosimd()
    let p1 = end.tosimd()
    let newPoints = [mix(p0, p1, t: s), mix(p0, p1, t: f)]
    
    let newEnd = CGPoint(x: CGFloat(newPoints[1].x), y: CGFloat(newPoints[1].y))
    
    return .line(to: newEnd)
}


/// # Make Segment From Quadratic Bézier
///
/// Creates a new quadratic bézier curve from a section of the given curve. Uses the matrix representation of
/// the bézier curve to create a transformation matrix that converts the original curves points to the points
/// of the wanted segment.
///
/// - parameters:
///     - start: The starting point of the quadratic bézier curve
///     - end: The ending point of the quadratic bézier curve
///     - control: The control point of the quadratic bézier curve
///     - from: The lower bound of the segment. Should be between `[0, 1)` .
///     - to: The upper bound of the segment . Should be between `(0, 1]`.
///
/// - important: *to* must be greater than *from*
///
/// - returns: The quadratic `PolyBezierElement` segment defined between the from and to values
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func makeQuadSegment(start: CGPoint, end: CGPoint, control: CGPoint, from: CGFloat, to: CGFloat) -> PolyBezierElement {
    
    let s = Float(from)
    let f = Float(to)
    let p0 = start.tosimd()
    let p1 = control.tosimd()
    let p2 = end.tosimd()
    let points = simd_float2x3(rows: [p0, p1, p2])
 
    
    let coefficientMatrix = simd_float3x3(rows: [ simd_float3(arrayLiteral:  1,  0,  0),
                                                  simd_float3(arrayLiteral: -2,  2,  0),
                                                  simd_float3(arrayLiteral:  1, -2,  1)])

    
    let restrictionMatrix = simd_float3x3(rows: [ simd_float3(arrayLiteral: 1, s,   s*s),
                                                  simd_float3(arrayLiteral: 0, f-s, 2*s*(f-s)),
                                                  simd_float3(arrayLiteral: 0, 0,   (f-s)*(f-s)) ])
    
    let transformMatrix = coefficientMatrix.inverse*restrictionMatrix*coefficientMatrix
    
    let newPoints = transformMatrix*points
    
    let newControl = CGPoint(x: CGFloat(newPoints.columns.0.y),
                             y: CGFloat(newPoints.columns.1.y))
    let newEnd = CGPoint(x: CGFloat(newPoints.columns.0.z),
                         y: CGFloat(newPoints.columns.1.z))
    
    
    return .quad(to: newEnd, control: newControl)
    
}



/// # Make Segment From Cubic Bézier
///
/// Creates a new cubic bézier curve from a section of the given curve. Uses the matrix representation of
/// the bézier curve to create a transformation matrix that converts the original curves points to the points
/// of the wanted segment.
///
/// - parameters:
///     - start: The starting point for the Bézier curve
///     - end: The end point of the cubic Bézier
///     - control1: The first control point of the cubic bézier
///     - control2: The second control point of the cubic bézier
///     - from: The lower bound of the segment. Should be between `[0, 1)` .
///     - to: The upper bound of the segment . Should be between `(0, 1]`.
///
/// - important: *to* must be greater than *from*
///
/// - returns: The cubic `PolyBezierElement` segment defined between the from and to values
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func makeCubicSegment(start: CGPoint, end: CGPoint, control1: CGPoint, control2: CGPoint, from: CGFloat, to: CGFloat) -> PolyBezierElement {
    
    let s = Float(from)
    let f = Float(to)
    let p0 = start.tosimd()
    let p1 = control1.tosimd()
    let p2 = control2.tosimd()
    let p3 = end.tosimd()
    let points = simd_float2x4(rows: [p0, p1, p2, p3])
 
    
    let coefficientMatrix = simd_float4x4(rows: [ simd_float4(arrayLiteral:  1,  0,  0, 0),
                                                  simd_float4(arrayLiteral: -3,  3,  0, 0),
                                                  simd_float4(arrayLiteral:  3, -6,  3, 0),
                                                  simd_float4(arrayLiteral: -1,  3, -3, 1) ])

    
    let restrictionMatrix = simd_float4x4(rows: [ simd_float4(arrayLiteral: 1, s,   s*s,         s*s*s),
                                                  simd_float4(arrayLiteral: 0, f-s, 2*s*(f-s),   3*s*s*(f-s)),
                                                  simd_float4(arrayLiteral: 0, 0,   (f-s)*(f-s), 3*s*(f-s)*(f-s)),
                                                  simd_float4(arrayLiteral: 0, 0,   0,           powf((f-s), 3)) ])
    
    let transformMatrix = coefficientMatrix.inverse*restrictionMatrix*coefficientMatrix
    
    let newPoints = transformMatrix*points
    
    let newControl1 = CGPoint(x: CGFloat(newPoints.columns.0.y), y: CGFloat(newPoints.columns.1.y))
    let newControl2 = CGPoint(x: CGFloat(newPoints.columns.0.z), y: CGFloat(newPoints.columns.1.z))
    let newEnd = CGPoint(x: CGFloat(newPoints.columns.0.w), y: CGFloat(newPoints.columns.1.w))
    
    return .cubic(to: newEnd, control1: newControl1, control2: newControl2)
    
}



/// # Make Segment From Any Bézier Curve
///
///  This function acts as an interface for each of the individual segmentation functions (`makeLineSegment`, `makeQuadSegment`, `makeCubicSegment`)
///
/// - parameters:
///     - start: The starting point of the Bézier curve
///     - element: The `PolyBezierElement` containing rest of  the curves points
///     - from: The lower bound of the segment. Should be between `[0, 1)` .
///     - to: The upper bound of the segment . Should be between `(0, 1]`.
///
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func makeSegment(start: CGPoint, element: PolyBezierElement, from: CGFloat, to: CGFloat) -> PolyBezierElement {
    switch element.type {

    case .line:
       return  makeLineSegment(start: start, end: element.currentPositions[0], from: from, to: to)
    case .quad:
        return makeQuadSegment(start: start,
                               end: element.currentPositions[0],
                               control: element.currentPositions[1],
                               from: from,
                               to: to)
    case .cubic:
        return makeCubicSegment(start: start,
                                end: element.currentPositions[0],
                                control1: element.currentPositions[1],
                                control2: element.currentPositions[2],
                                from: from,
                                to: to)
    case .moveTo:
        return element
    case .closeSubpath:
        return makeLineSegment(start: start,
                               end: element.currentPositions[0],
                               from: from,
                               to: to)
    }
}
