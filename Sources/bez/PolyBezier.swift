//
//  PolyBezier.swift
//  
//
//  Created by Kieran Brown on 3/21/20.
//

import SwiftUI

// MARK: - PolyBézier Element

/// # Bézier Curve Element (Polybézier Format)
///
/// Created to be easily used with the path editior UI. Uses arrays of points in place of unique element types as to avoid
/// control statements when creating draggable points in the view hierarchy.
///
/// - important: The order of each array is [end, control(1), control2, ...], we will be using at most a cubic Bézier.
///              The starting point will not be used
/// - Note: If all arrays are empty, the given element is a closeSubpath command
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public struct PolyBezierElement: Identifiable {
    public let id = UUID()
    public var positions: [CGPoint] // Positions of the elements points [end, control(1), control2]
    public var offsets: [CGSize] // Offsets of the elements points [end, control(1), control2]
    public var isMoveTo: Bool = false // Boolean to remove ambiguity between a line and a moveTo element
    
    /// The sum of the position and offset for each point.
    public var currentPositions: [CGPoint] {
        if positions.isEmpty {
            return []
        }
        var tempPositions: [CGPoint] = []
        for (i, position) in positions.enumerated() {
            tempPositions.append(position + offsets[i].toPoint())
        }
        return tempPositions
    }
    
    public var type: CommandType {
        if isMoveTo {
            return .moveTo
        }
        if positions.count == 0 {
            return .closeSubpath
        }
        if positions.count == 1 {
            return .line
        }
        if positions.count == 2 {
            return .quad
        }
        return .cubic
    }

    public enum CommandType {
        case line, quad, cubic, moveTo, closeSubpath
    }
    
    
    public var description: String {
        switch type {
            
        case .line:
            return "l   " + currentPositions[0].description
        case .quad:
            return "q   " + currentPositions[0].description + " " + currentPositions[1].description
        case .cubic:
            return "c    " + currentPositions[0].description + "  " + currentPositions[1].description + "  " + currentPositions[2].description
        case .moveTo:
            return "m   " + currentPositions[0].description
        case .closeSubpath:
            return "h"
        }
    }
    
    // MARK: PolyBezierElement Init
    
    public init(positions: [CGPoint], offsets: [CGSize], isMoveTo: Bool) {
        self.positions = positions
        self.offsets = offsets
        self.isMoveTo = isMoveTo
    }
    
    public init(positions: [CGPoint], offsets: [CGSize]) {
        self.positions = positions
        self.offsets = offsets
    }
    
    
    // MARK: Convienience Functions
    
    /// Creates the `PolyBezierElement` equivalent of a `Path` `move(to: )` command
    public static func moveTo(to: CGPoint) -> PolyBezierElement {
        return PolyBezierElement(positions: [to], offsets: [.zero], isMoveTo: true)
    }
    /// Creates  the `PolyBezierElement` equivalent of a `Path` `closeSubpath` command
    public static func closedSubPath() -> PolyBezierElement {
        return PolyBezierElement(positions: [], offsets: [])
    }
    /// Creates the  `PolyBezierElement` equivalent of a `Path` `addLine(to: .zero)`
    public static func line() -> PolyBezierElement {
        return PolyBezierElement(positions: [.zero], offsets: [.zero])
    }
    /// Creates the `PolyBezierElement` equivalent of a `Path` `addLine(to: )`
    public static func line(to: CGPoint) -> PolyBezierElement {
        PolyBezierElement(positions: [to], offsets: [.zero])
    }
    /// Creates the `PolyBezierElement` equivalent of a `Path` `addQuadCurve(to: .zero, control: .zero)` command
    public static func quad() -> PolyBezierElement {
        return PolyBezierElement(positions: [.zero, .zero], offsets: [.zero, .zero])
    }
    /// Creates the `PolyBezierElement` equivalent of a `Path` `addQuadCurve(to: , control: )` command
    public static func quad(to: CGPoint, control: CGPoint) -> PolyBezierElement {
        PolyBezierElement(positions: [to, control], offsets: [.zero, .zero])
    }
    /// Creates the `PolyBezierElement` equivalent of a `Path` `addCurve(to: .zero, control1: .zero, control2: .zero)` command
    public static func cubic() -> PolyBezierElement {
        return PolyBezierElement(positions: [.zero, .zero, .zero], offsets: [.zero, .zero, .zero])
    }
    /// Creates the `PolyBezierElement` equivalent of a `Path` `addCurve(to: , control1: , control2: )` command
    public static func cubic(to: CGPoint, control1: CGPoint, control2: CGPoint) -> PolyBezierElement {
        PolyBezierElement(positions: [to, control1, control2], offsets: [.zero , .zero , .zero])
    }
    
    
}

// MARK: - PolyBézier

/// # PolyBézier Curve
///
/// A view model for an individual poly-Bézier curve.
/// The data structure is made to be well suited for UI Maniipulation.
///
/// Only holds the minimal amount of data, an array of elements
///
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public class PolyBezier: ObservableObject {
    
    @Published public var elements: [PolyBezierElement]
    
    public var path: Path {
        Path { (path) in
            for element in elements {
                switch element.type {
                case .line: path.addLine(to: element.currentPositions[0])
                case .quad: path.addQuadCurve(to: element.currentPositions[0],
                                      control: element.currentPositions[1])
                case .cubic: path.addCurve(to: element.currentPositions[0],
                                  control1: element.currentPositions[1],
                                  control2: element.currentPositions[2])
                case .moveTo: path.move(to: element.currentPositions[0])
                case .closeSubpath: path.closeSubpath()
                }
            }
        }
    }
    /// String representation of the current path
   public var string: String { path.description }
    
    public init(elements: [PolyBezierElement]) { self.elements = elements }
    
    public init(_ path: Path) {
        elements = []
        path.forEach({ (element) in
            switch element {
            case .move(let to): self.elements.append(.moveTo(to: to))
            case .line(let to): self.elements.append(.line(to: to))
            case .quadCurve(let to, let control): self.elements.append(.quad(to: to, control: control))
            case .curve(let to, let c1, let c2): self.elements.append(.cubic(to: to, control1: c1, control2: c2))
            case .closeSubpath: self.elements.append(.closedSubPath())
            }
        })
    }
    
    // MARK: Path Manipulation Functions
    public func update(string: String) {
        elements = []
        let p = Path(string)
        p!.forEach({ (element) in
            switch element {
            case .move(let to): self.elements.append(.moveTo(to: to))
            case .line(let to): self.elements.append(.line(to: to))
            case .quadCurve(let to, let control): self.elements.append(.quad(to: to, control: control))
            case .curve(let to, let c1, let c2): self.elements.append(.cubic(to: to, control1: c1, control2: c2))
            case .closeSubpath: self.elements.append(.closedSubPath())
            }
        })
    }
    
    /// Cleans up the path by removing superfluous elements.
    public func cleanUp() {
        var temp: [PolyBezierElement] = [elements[0]]
        var previous = elements[0]
        for i in 1..<elements.count {
            let current = elements[i]
            if !(previous.type == .closeSubpath && current.type == .closeSubpath) {
                temp.append(current)
                previous = current
            }
        }
        elements = temp
    }
    
    // FIXME: Fix The Edge Cases for Deletions
    
    /// Deletes the path element with the specified ID
    ///
    /// check if elements array is greater than 1
    /// a. not greater do nothing
    /// b. is  = 2
    ///      a. if last element or first element is a closesubPath: clear
    ///      b. if the selected element is a moveTo, create a new moveTo with the opposite element and replace elements array with that
    /// c. is > 2
    ///      a. Filter elements array and remove selected elements
    ///      b. check that first element in new array is moveTo
    ///          a. if is : do nothing
    ///          b. if isnot: replace first element with moveTo at that location
    ///
    public func delete(id: Set<UUID>) {
        if elements.count == 2 {
            if !elements.filter({$0.type == .closeSubpath}).isEmpty {
                clear()
            } else {
                let new: PolyBezierElement = .moveTo(to: elements.filter({ !id.contains($0.id) })[0].currentPositions[0])
                elements = [new]
            }
        } else if elements.count > 2 {
            var remainder = elements.filter({ !id.contains($0.id) })
            if remainder.isEmpty {
                clear()
            } else {
                if !remainder.first!.isMoveTo {
                    if remainder.first!.type == .closeSubpath {
                        remainder[0] = .moveTo(to: CGPoint(x: 100, y: 100))
                    } else {
                        remainder[0] = .moveTo(to: remainder[0].currentPositions[0])
                    }
                }
                elements = remainder
            }
        }
        cleanUp()
    }
    
    /// Adds a curve element onto the end of the PolyBézier curve
    public func add(type: PolyBezierElement.CommandType) {
        let range: Range<CGFloat> = 100..<300
        switch type {
        case .moveTo, .closeSubpath: break
        case .line: elements.append(.line(to: .random(from: range)))
        case .quad: elements.append(.quad(to: .random(from: range), control: .random(from: range)))
        case .cubic: elements.append(.cubic(to:  .random(from: range), control1: .random(from: range), control2: .random(from: range)))
        }
    }
    
    /// Creates a new subpath, basically adds a moveTo `PolyBezierElement` to the end of the PolyBézier curve
    public func newSubpath() {
        let range: Range<CGFloat> = 100..<300
        elements.append(.moveTo(to: .random(from: range)))
    }
    
    // FIXME: Go back and make sure this works
    /// if an `id` is provided the subPath is closed from the selected point to the previous moveTo point
    ///
    /// 1. if no UUID is in the set
    ///      a. if last element is close subpath: do nothing
    ///      b. else append the close subPath to the end of elements
    /// 2. if 1 UUID is in the set
    ///      a. if element is moveTo: Do nothing
    ///      b. else insert closeSubpath after selection
    /// 3. if > 1 UUID in the set
    ///    1. get the selections indexs in reverse order
    ///    2. filter for moveTos
    ///    3. insert close subpath after each
    ///
    public func closeSubpath(_ id: Set<UUID>) {
        if id.isEmpty {
            if elements.last!.type != .closeSubpath { elements.append(.closedSubPath()) }
        } else if id.count == 1 {
            let element = elements.enumerated().first(where: { id.contains($0.element.id) })
            if element!.element.type != .moveTo { elements.insert(.closedSubPath(), at: element!.offset+1) }
        } else {
            let selected = elements.enumerated()
                                .filter({ id.contains($0.element.id) })
                                .filter({$0.element.type != .moveTo})
                                .reversed()
                                .map({$0.offset})
            selected.forEach({ self.elements.insert(.closedSubPath(), at: $0+1)})
        }
        cleanUp()
    }
    
    /// Clears the `elements` array to the last point, performs the clearing iteratively to give the view hierarchy time to adjust.
    public func clear() {
        if !elements.first!.isMoveTo {
            let newStart = elements.first(where: {$0.type != .closeSubpath})?.currentPositions[0]
            elements[0] = .moveTo(to: newStart!)
        }
        for i in (1..<elements.count).reversed() {
            self.elements.remove(at: i)
        }
        cleanUp()
    }
    
    /// Subdivides the PolyBézier into `2*elements.count` segments.
    public func subdivide() {
        let new = subdividePath(elements: elements, numberOfSegments: 2)
        elements = new
        cleanUp()
    }
    
    public func convertToShape() -> String {
        convertPath(path: self.string)
    }
}
