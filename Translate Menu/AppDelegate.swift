/*
* Copyright (c) 2015 Adrián Moreno Peña
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var statusMenu: NSMenu!
    
    var statusItem: NSStatusItem!
    let popover = NSPopover()
    var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: 32)
        
        let image = NSImage(named: "TranslateStatusBarButtonImage")
        image?.isTemplate = true
        
        if let button = statusItem.button {
            button.image = image
            button.action = #selector(statusItemButtonActivated(sender:))
            
            button.sendAction(on: [ .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp ])
        }
        
        popover.contentViewController = TranslateViewController(nibName: "TranslateViewController", bundle: nil)
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [unowned self] event in
            if self.popover.isShown {
                self.closePopover(sender: event)
            }
        }
        
        eventMonitor?.start()
        
        NSApplication.shared.servicesProvider = self
    }
    
    @IBAction
    func statusItemButtonActivated(sender: AnyObject?) {
        let buttonMask = NSEvent.pressedMouseButtons
        var primaryDown = ((buttonMask & (1 << 0)) != 0)
        var secondaryDown = ((buttonMask & (1 << 1)) != 0)
        
        // Treat a control-click as a secondary click
        if (primaryDown && (NSEvent.modifierFlags == NSEvent.ModifierFlags.control)) {
            primaryDown = false;
            secondaryDown = true;
        }
        
        if (primaryDown) {
            if popover.isShown {
                closePopover(sender: sender)
            } else {
                showPopover(sender: sender)
            }
        } else if (secondaryDown) {
            self.statusItem.popUpMenu(self.statusMenu)
        }
    }
    
    func showPopover(sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        
        eventMonitor?.start()
    }
    
    func closePopover(sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
    
    func translateService(pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        NSLog("Opening MenuTranslate")
        
        popover.show(relativeTo: NSRect.init(x: 0, y: 0, width: 100, height: 100), of: (NSApp.mainWindow?.contentView)!, preferredEdge: NSRectEdge.minY)
    }
    
    @IBAction func quitApp(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
}
