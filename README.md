<p align="center">
    <img src ="Media/bezLogo.svg" />
</p>

<p align="center">
    <img src="https://img.shields.io/badge/platforms-iOS_13_|macOS_10.15_| watchOS_6.0-blue.svg" alt="SwiftUI" />
    <img src="https://img.shields.io/badge/Swift-5.1-orange.svg" alt="Swift 5.1" />
    <img src="https://img.shields.io/badge/SwiftPM-compatible-green.svg" alt="Swift 5.1" />
    <img src="https://img.shields.io/github/followers/kieranb662?label=Follow" alt="kieranb662 followers" />
</p>


Bez is a swift package aimed at making Bézier curves easy to work with and manipulate. 

Try out all that bez has to offer by creating your own shapes using the [bez editor](https://apps.apple.com/us/app/bez-editor/id1508764103) app available for free on iOS 13.4 and greater. 

<p align="center">
  <a href="https://apps.apple.com/us/app/bez-editor/id1508764103">
  <img width="300px" src="https://github.com/kieranb662/kieranb662.github.io/blob/master/assets/bezeditorPreview.gif">
  </a>
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
