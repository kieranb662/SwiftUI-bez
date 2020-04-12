//
//  PathEditor.swift
//  BezEditor
//
//  Created by Kieran Brown on 4/12/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI
import CGExtender


#if os(iOS)
// MARK: Path Editor Views
@available(iOS 13.0, *)
public struct EditorButtonStyle: ButtonStyle {
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(height: 30)
            .padding()
            .foregroundColor(.white)
            .background(configuration.isPressed ?  Color.purple : Color.blue)
            .cornerRadius(5)
            .overlay(RoundedRectangle(cornerRadius: 5)
                .stroke(Color.white, lineWidth: 1))
    }
}


/// # Path Editor
///
/// Stores a single `PolyBezier` object for editing.
///
/// **Interactions**:
/// * Tap a point to select/deselect it
/// * Double tap a point to toggle its type (See `ElementPoints`) for details
/// * Double tap the canvas background to deselect all points
/// * If multiple points are selected drag on the canvas background to move all of them simultaneously
///
/// **Buttons**:
/// * The red button in the top left clears the canvas except for an initial starting point
/// * The plus button when tapped adds a new line from the last point in the polybezier
/// * Longpressing the plus button reveals the context menu with options to add a (line, quad, cubic, or new subpath)
/// * The "􀏠" button subdivides the path into twice the number of original points
/// * The "􀖄" button closes the subpath from any currently selected points to the last point in the curve. If none are selected then the second to last point connects to the last point
///
/// Features:
///     * Adding additional element components
///     * Close Path
///     * Subdivide elements
///     * Show/Hide points
///     * Delete element
///     * Clear PolyBezier
///     * Export to a SwiftUI `Shape`
///
@available(iOS 13.0, *)
public struct PathEditor: View {
    @Environment(\.pathEditorStyle) var style: AnyPathEditorStyle
    @ObservedObject var polyBezier: PolyBezier
    @State var name: String = ""
    var save: (String, String) -> () = { (name: String, path: String) in
        print("\(name):\n\(path)")
    }
    @State private var showPoints: Bool = false // For hiding/showing the draggable points
    @State private var showShareSheet = false
    @State private var canvasIsActive = false
    struct ShareSheet: UIViewControllerRepresentable {
        typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
          
        let activityItems: [Any]
        let applicationActivities: [UIActivity]? = nil
        let excludedActivityTypes: [UIActivity.ActivityType]? = nil
        let callback: Callback? = nil
          
        func makeUIViewController(context: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: applicationActivities)
            controller.excludedActivityTypes = excludedActivityTypes
            controller.completionWithItemsHandler = callback
            return controller
        }
          
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
            // nothing to do here
        }
    }
    typealias Key = BezierKey
    var points: some View {
        ZStack {
            ForEach(polyBezier.elements.indices, id: \.self) { (i)  in
                ElementPoints(element: self.$polyBezier.elements[i], selected: self.$polyBezier.selected)
            }
        }.opacity(showPoints ? 0 : 1)
    }
    func makePath(_ proxy: GeometryProxy, _ centers: [UUID: [Anchor<CGPoint>]]) -> some View {
        let p = Path { path in
            for element in self.polyBezier.elements {
                switch element.type {
                case .line:
                    guard let anchor = centers[element.id] else {break}
                    path.addLine(to: proxy[anchor[0]])
                case .quad:
                    guard let anchors = centers[element.id] else {break}
                    path.addQuadCurve(to: proxy[anchors[0]],
                                      control: proxy[anchors[1]])
                case .cubic:
                    guard let anchors = centers[element.id] else {break}
                    path.addCurve(to: proxy[anchors[0]],
                                  control1: proxy[anchors[1]],
                                  control2: proxy[anchors[2]])
                case .moveTo:
                    guard let anchor = centers[element.id] else {break}
                    path.move(to: proxy[anchor[0]])
                case .closeSubpath:
                    path.closeSubpath()
                }
            }
        }
        return style.makePath(configuration: .init(path: p))
    }
    var canvas: some View {
        style.makeCanvas(configuration: .init(isActive: self.canvasIsActive))
        .onTapGesture(count: 2, perform: {self.polyBezier.selected = []})
        .simultaneousGesture(DragGesture().onChanged({ (drag) in
            let selected = self.polyBezier.selected
            if selected.count > 1 {
                self.canvasIsActive = true
                let selectedIndices = self.polyBezier.elements
                    .enumerated()
                    .filter({selected.contains($0.element.id)})
                    .map({$0.offset})
                for i in selectedIndices {
                    self.polyBezier.elements[i].offsets = self.polyBezier.elements[i].offsets.map({_ in drag.translation})
                }
            }
        }).onEnded({ (drag) in
            self.canvasIsActive = false
            let selected = self.polyBezier.selected
            if selected.count > 1 {
                let selectedIndices = self.polyBezier.elements
                    .enumerated()
                    .filter({selected.contains($0.element.id)})
                    .map({$0.offset})
                for i in selectedIndices {
                    self.polyBezier.elements[i].offsets = self.polyBezier.elements[i].offsets.map({_ in .zero})
                    self.polyBezier.elements[i].positions = self.polyBezier.elements[i].positions.map({ $0 + drag.translation.toPoint() })
                }
            }
        }))
    }
    var filesToShare: URL? {
        let pathFile = "import SwiftUI \n\n\n" +  self.polyBezier.convertToShape()
        let documentsDirectoryURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        do {
            try FileManager().removeItem(at: documentsDirectoryURL.appendingPathComponent("MyCurve.swift"))
        } catch {
            print("No File MyCurve.swift Needs To Be Removed: \(error)")
        }
        let file2ShareURL = documentsDirectoryURL.appendingPathComponent("MyCurve.swift")
        do {
            try pathFile.write(to: file2ShareURL, atomically: false, encoding: .utf8)
        } catch {
            print(error)
        }
        
        return file2ShareURL
    }
    var shareButton: some View {
        Button(action: { self.showShareSheet = true }) {
            Image(systemName: "square.and.arrow.up")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [self.filesToShare!])
        }
    }
    
    var overlayControls: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Button(action: {
                    self.polyBezier.clear()
                    self.polyBezier.selected = []
                }, label: {
                    Image(systemName: "clear")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                    
                })
                    .frame(width: 30, height: 30)
                    .foregroundColor(.red)
                    .position(x: 30, y: 30)
                Button(!self.showPoints ? "Hide Points" : "Show Points") {
                    self.showPoints.toggle()
                }.position(x: proxy.size.width - 70, y: 30)
            }
        }
    }
    var bottomControls: some View {
        HStack {
            Button(action: {self.polyBezier.add(type: .line)}, label: {
                Image(systemName: "plus")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                
            }).contextMenu {
                self.contextOptions
            }
            Spacer()
            Button(action: {self.polyBezier.subdivide()}, label: {
                Image(systemName: "square.split.2x1")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                
            })
            Spacer()
            Button(action: {self.polyBezier.closeSubpath(self.polyBezier.selected)}, label: {
                Image(systemName: "arrow.merge")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                
            })
            Spacer()
            Button(action: {self.polyBezier.delete(id: self.polyBezier.selected)}, label: {
                Image(systemName: "delete.left")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                
            }).disabled(self.polyBezier.selected.isEmpty)
        }.buttonStyle(EditorButtonStyle()).padding()
    }
    var contextOptions: some View {
        Group {
            Button("Line", action: { self.polyBezier.add(type: .line)})
            Button("Quad", action: { self.polyBezier.add(type: .quad)})
            Button("Cubic", action: { self.polyBezier.add(type: .cubic) })
            Button("New Subpath", action: { self.polyBezier.newSubpath() })
        }
    }
    public var body: some View {
        ZStack {
            Color(white: 0.2).edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    TextField("Untitled", text: self.$name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {print("save")}) {
                        Image(systemName: "arrow.down.doc")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                    }
                    
                }.padding(.horizontal)
                .frame(height: 50)
                self.points
                    .backgroundPreferenceValue(Key.self) { (centers: [UUID: [Anchor<CGPoint>]])  in
                        GeometryReader { proxy in
                            self.makePath(proxy, centers)
                        }
                }.overlay(overlayControls)
                    .background(canvas)
                
                self.bottomControls
            }
        }
        .navigationBarItems(trailing: shareButton)
    }
    
    public init(path: Path) {
        self.polyBezier = PolyBezier(path)
    }
    
    public init(polybezier: ObservedObject<PolyBezier> , name: String, save: @escaping (_ name: String, _ path: String) -> ()) {
        self._polyBezier = polybezier
        self.name = name
        self.save = save
    }
}
#endif
