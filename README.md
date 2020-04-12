<p align="center">
    <img src ="Media/bezLogo.svg" width=500 />
</p>

<p align="center">
    <img src="https://img.shields.io/badge/platform-SwiftUI-red.svg" alt="Swift UI" />
    <img src="https://img.shields.io/badge/Swift-5.1-orange.svg" alt="Swift 5.1" />
</p>


Bez is a swift package aimed at making Bézier curves easy to work with and manipulate. Try out the `PathEditor` for a quick way to get started! 
<p align="center">
<img src="Media/PathEditor.gif" alt="Path Slider Gif" height=500>
   </p>



The various utilities included are: 
* **Interpolation Functions**
* **Derivatives**
* **Arc Lengths**
* **Segmentation**
* **Subdivision** 
* **Lookup Table Generation**
* **Path Description -> Normalized SwiftUI Shape Conversion**

## Quick Start 

1. Snag that URL from the github repo 
2. In Xcode -> File -> Swift Packages -> Add Package Dependencies 
3. Paste the URL Into the box
4. Specify the minimum version number (1.0.5)
5. Copy/Paste the following snippet Into The ContentView.swift file

````Swift 
import SwiftUI
import bez

struct ContentView: View {
    @ObservedObject var polybezier: PolyBezier = PolyBezier(Circle().path(in: .init(x: 50, y: 100, width: 100, height: 100)))
    var body: some View {
        NavigationView {
            PathEditor(polybezier: _polybezier, name: "Shape",
                save:  { (name , path) in print(path)})
                .navigationBarTitle("Bez Editor", displayMode: .inline)
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().colorScheme(.dark)
    }
}
````

## Mathematical Background 

![bez Info](Media/bezMath.svg)


## Example Uses 

The `PSlider` component of the [Sliders](https://github.com/kieranb662/Sliders) SwiftUI Library 
<p align="center">
<img src="https://github.com/kieranb662/SlidersExamples/blob/master/Sliders%20Media/PSliderExample.gif" alt="Path Slider Gif" height=500>
   </p>
