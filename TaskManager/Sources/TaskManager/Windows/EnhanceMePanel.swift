import AppKit
import SwiftUI

final class EnhanceMePanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        title = "Enhance Me"
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        hidesOnDeactivate = true
        
        minSize = NSSize(width: 500, height: 400)
        maxSize = NSSize(width: 1200, height: 800)
    }
    
    func setContent<V: View>(_ view: V) {
        contentView = NSHostingView(rootView: view)
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    
    override func resignKey() {
        super.resignKey()
        if attachedSheet == nil {
            orderOut(nil)
        }
    }
}
