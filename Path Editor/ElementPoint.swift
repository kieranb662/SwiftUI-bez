//
//  BezierPoint.swift
//  BezEditor
//
//  Created by Kieran Brown on 4/12/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI




/// Preference Key for merging values of sibling views into an array
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , *)
public struct BezierKey: PreferenceKey {
    public static var defaultValue: [UUID:[Anchor<CGPoint>]] { [:] }
    public static func reduce(value: inout [UUID:[Anchor<CGPoint>]], nextValue: () -> [UUID:[Anchor<CGPoint>]]) {
        // if the next value shares Keys with the current value append the elements
        // of the next values array onto the the current value array.
        value.merge(nextValue()) { (current, new) in
            var temp = current
            temp.append(contentsOf: new)
            return temp
        }
    }
}


#if os(iOS)
/// # Draggable Bézier Curve Points
///
///
/// Tap a point to select it. Once selected if the point has control points associated with it, they will become visible
///
/// Double tap a point to convert it to a different type
/// line ---> quad
/// quad --> cubic
/// cubic --> line
///
/// - note: The way to draw the actual path without having direct access to the drag Gesture State,
///         one needs to have a preference key that merges all point locations for a given element
///         into a single array. Then you set the anchor preference for the points with the value being the
///         centers `Anchor<CGPoint>` and the key being the elements id. This preference is accessed
///         in the `PathEditor` using `backgroundPreferenceValue` and a `GeometryReader`/ `GeometryProxy`
///         to convert the `Anchor<CGPoint>` into the position.
///
/// - parameters:
///  - element: A Binding to a  Bézier element
///  - selected: A Binding to the selected set
///
///
/// ## Style
///
/// Create a `PathEditorStyle` Conforming struct and then call the `pathEditorStyle` method
/// on the parent `PathEditor`
@available(iOS 13.0, *)
public struct ElementPoints: View {
    @Environment(\.pathEditorStyle) var style: AnyPathEditorStyle
    @Binding public var element: PolyBezierElement
    @Binding public var selected: Set<UUID>
    typealias Key = BezierKey
    var isSelected: Bool { self.selected.contains(self.element.id) }
    struct Draggable: ViewModifier {
        @Binding var position: CGPoint
        @Binding var offset: CGSize
        
        func body(content: Content) -> some View {
            content.simultaneousGesture(DragGesture()
                .onChanged({self.offset = $0.translation})
                .onEnded({
                    self.offset = .zero
                    self.position += $0.translation.toPoint()
                }))
        }
    }
    
    /// Selects the object if currently unselected or deselects the object if currently selected
    func select() {
        withAnimation(.easeIn) { () in
            if selected.contains(element.id) {
                self.selected.remove(element.id)
            } else {
                self.selected.insert(element.id)
            }
        }
    }
    /// Convert element to line.
    func toLine() {
        element = PolyBezierElement(positions: [element.positions[0]], offsets: [element.offsets[0]])
    }
    /// Convert element to Quadratic Bézier.
    func toQuad() {
        let points = [element.positions[0], element.positions[0] + CGPoint(x: 30, y: 30)]
        let offsets = [element.offsets[0], .zero]
        element = PolyBezierElement(positions: points, offsets: offsets)
    }
    /// Convert element to Cubic Bézier.
    func toCubic() {
        let points = [element.positions[0],
                      element.positions[0] + CGPoint(x: 30, y: 30),
                      element.positions[0] + CGPoint(x: -30, y: -30)]
        let offsets = [element.offsets[0], .zero, .zero]
        
        element = PolyBezierElement(positions: points, offsets: offsets)
    }
    func toggleType() {
        self.selected.remove(element.id)
        switch element.type {
        case .line:
            self.toQuad()
        case .quad:
            self.toCubic()
        case .cubic:
            self.toLine()
        default: break
        }
    }
    
    var gesture: some Gesture {
        TapGesture(count: 2).exclusively(before: TapGesture())
            .onEnded { (value) in
                switch value {
                case .first():
                    self.toggleType()
                case .second():
                    self.select()
                }
        }
    }
    
    public var body: some View {
        Group {
            ForEach(element.positions.indices, id: \.self) { i in
                self.style.makePoint(configuration: BezierPointConfiguration(isSelected: self.isSelected, isActive: self.element.offsets[i] != .zero, isControlPoint: i>0))
                    .anchorPreference(key: Key.self, value: .center, transform: { [self.element.id : [ $0 ]] }) // Get Points Center
                    .position( self.element.positions[i] )
                    .offset(self.element.offsets[i])
                    .animation(.none)
                    .gesture(self.gesture)
                    .modifier(Draggable(position: self.$element.positions[i], offset: self.$element.offsets[i]))
            }
        }
    }
}
#endif
