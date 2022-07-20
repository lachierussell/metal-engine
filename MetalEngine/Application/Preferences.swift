//
//  Preferences.swift
//  MetalEngine
//
//  Created by Lachlan Russell on 20/7/2022.
//
import Cocoa
import SwiftUI

struct Preferences: View {
    var body: some View {
        VStack {
            Text("Size")
//            Slider(value: $model.size, in: 0...500)
        }
    }
}


class SwiftUIWindowCtrl<RootView: View>: NSWindowController {
    convenience init(rootView: RootView) {
        let hostingCtrl = NSHostingController(rootView: rootView.frame(width: 400, height: 300))
        let window = NSWindow(contentViewController: hostingCtrl)
        window.setContentSize(NSSize(width: 400, height: 300))
        self.init(window: window)
    }
}

@objc class PrefsWindowObjCBridge: NSView {

    @objc class func makePrefsWindow() -> NSWindowController {
        SwiftUIWindowCtrl(rootView: Preferences())
    }
}
