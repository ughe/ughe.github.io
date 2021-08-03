---
title: "Create a Wi-Fi QR Code in Swift"
---

The goal of this post is to create a QR code to automatically log into a Wi-Fi network. This is inspired by a recent [HackerNews post][0].

The QR Code contains the following text (with `NetworkName` and `Password` replaced with the correct values):

>`WIFI:T:WPA;S:NetworkName;P:Password;;`

Any QR code generator could be used (we use Swift).

Create a Swift Playground in Xcode (File > New > Playground). Select `macos` and `Blank` and save the playground. Then add the code:

```swift
import Cocoa

/* Fill Me In */
let ssid = "NetworkName"
let code = "Password"

// Save to Downloads
let dest = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0].appendingPathComponent("\(ssid).png")

// https://stackoverflow.com/a/48945637
func QR(from string: String, size len:CGFloat) -> NSImage? {
    let data = string.data(using: String.Encoding.ascii)
    if let filter = CIFilter(name: "CIQRCodeGenerator") {
        filter.setValue(data, forKey: "inputMessage")
        let trans = CGAffineTransform(scaleX: len, y: len)
        if let output = filter.outputImage?.transformed(by: trans) {
            let rep = NSCIImageRep(ciImage: output)
            let img = NSImage(size: rep.size)
            img.addRepresentation(rep)
            return img
        }
    }
    return nil
}

func WifiQR(name ssid: String, password code: String, size: CGFloat = 10) -> NSImage? {
    return QR(from: "WIFI:T:WPA;S:\(ssid);P:\(code);;", size: size)
}

func SavePNG(image img: NSImage?, path dst: URL) {
    if let bits = NSBitmapImageRep(data: (img?.tiffRepresentation)!) {
        let data = bits.representation(using: .png, properties: [:])!
        try! data.write(to: dst)
    }
}

let img = WifiQR(name: ssid, password: code, size:15)
SavePNG(image: img, path: dest)
print("Done. QR Code is at: \(dest)")
```

Modify the `ssid` and `code` variables. Run the playground (i.e. Editor > Run Playground). The QR code will be saved in `~/Downloads` and represents the SSID and password in plain text.

[0]: https://news.ycombinator.com/item?id=27803146
