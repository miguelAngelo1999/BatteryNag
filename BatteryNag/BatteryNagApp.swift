//
//  BatteryNagApp.swift
//  BatteryNag
//
//  Menu bar app that nags when battery is low and force-sleeps at critical level.
//

import SwiftUI
import AppKit

@main
struct BatteryNagApp: App {
    @StateObject private var batteryMonitor = BatteryMonitor()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(batteryMonitor)
                .frame(width: 320, height: 400)
        } label: {
            HStack(spacing: 2) {
                if let iconImage = loadMenuBarIcon() {
                    Image(nsImage: iconImage)
                } else {
                    Image(systemName: batteryMonitor.menuBarIcon)
                }
                if batteryMonitor.isOnBattery {
                    Text("\(batteryMonitor.batteryLevel)%")
                }
            }
        }
        .menuBarExtraStyle(.window)
    }

    private func loadMenuBarIcon() -> NSImage? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        let iconPath = resourcePath + "/MenuBarIcon.png"
        guard let image = NSImage(contentsOfFile: iconPath) else { return nil }
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true  // Adapts to light/dark menubar
        return image
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSEvent.addLocalMonitorForEvents(matching: .rightMouseUp) { event in
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit BatteryNag",
                                    action: #selector(NSApplication.terminate(_:)),
                                    keyEquivalent: "q"))
            NSMenu.popUpContextMenu(menu, with: event, for: event.window?.contentView ?? NSView())
            return event
        }
    }
}
