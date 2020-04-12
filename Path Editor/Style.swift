//
//  Style.swift
//  BezEditor
//
//  Created by Kieran Brown on 4/12/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , *)
public struct BezierPointConfiguration {
    /// Whether the point is selected
    public let isSelected: Bool
    /// Whether the point is currently dragging
    public let isActive: Bool
    /// If the point is a control
    public let isControlPoint: Bool
}
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , *)
public struct BezierPathConfiguration {
    public let path: Path
}
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , *)
public struct CanvasConfiguration {
    public let isActive: Bool
}


// MARK: - PathEditor Style
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , *)
public protocol PathEditorStyle {
    associatedtype Point: View
    associatedtype BezierPath: View
    associatedtype Canvas: View
    
    func makePoint(configuration:  BezierPointConfiguration) -> Self.Point
    func makePath(configuration:  BezierPathConfiguration) -> Self.BezierPath
    func makeCanvas(configuration:  CanvasConfiguration) -> Self.Canvas
}
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , *)
public extension PathEditorStyle {
    func makePointTypeErased(configuration:  BezierPointConfiguration) -> AnyView {
        AnyView(self.makePoint(configuration: configuration))
    }
    func makePathTypeErased(configuration:  BezierPathConfiguration) -> AnyView {
        AnyView(self.makePath(configuration: configuration))
    }
    func makeCanvasTypeErased(configuration:  CanvasConfiguration) -> AnyView {
        AnyView(self.makeCanvas(configuration: configuration))
    }
}
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , *)
public struct AnyPathEditorStyle: PathEditorStyle {
    private let _makePoint: (BezierPointConfiguration) -> AnyView
    public func makePoint(configuration: BezierPointConfiguration) -> some View {
        self._makePoint(configuration)
    }
    private let _makePath: (BezierPathConfiguration) -> AnyView
    public func makePath(configuration: BezierPathConfiguration) -> some View {
        self._makePath(configuration)
    }
    
    private let _makeCanvas: (CanvasConfiguration) -> AnyView
    public func makeCanvas(configuration: CanvasConfiguration) -> some View {
        self._makeCanvas(configuration)
    }
    
    public init<S: PathEditorStyle>(_ style: S) {
        self._makePoint = style.makePointTypeErased
        self._makePath = style.makePathTypeErased
        self._makeCanvas = style.makeCanvasTypeErased
    }
}
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , *)
public struct PathEditorStyleKey: EnvironmentKey {
    public static let defaultValue: AnyPathEditorStyle = AnyPathEditorStyle(DefaultPathEditorStyle())
}
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , *)
extension EnvironmentValues {
    public var pathEditorStyle: AnyPathEditorStyle {
        get {
            return self[PathEditorStyleKey.self]
        }
        set {
            self[PathEditorStyleKey] = newValue
        }
    }
}
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , *)
extension View {
    public func pathEditorStyle<S>(_ style: S) -> some View where S: PathEditorStyle {
        self.environment(\.pathEditorStyle, AnyPathEditorStyle(style))
    }
}
// MARK: - Default PathEditor Style
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , *)
public struct DefaultPathEditorStyle: PathEditorStyle {
    public init() {}
    
    public func makePoint(configuration:  BezierPointConfiguration) -> some View {
        Circle()
            .fill(configuration.isActive ? Color.white : Color.blue)
            .frame(width: 40, height: 40)
            .shadow(color: configuration.isSelected ? Color.yellow : Color.black, radius: 2, x: 0, y: 0)
            .opacity(configuration.isSelected || !configuration.isControlPoint ? 1 : 0)
    }
    public func makePath(configuration: BezierPathConfiguration) -> some View {
        configuration.path.stroke(Color.white)
    }
    public func makeCanvas(configuration: CanvasConfiguration) -> some View {
        Rectangle().fill(Color(white: 0.1))
    }
}
