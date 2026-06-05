//
//  BatteryMonitor.swift
//  BatteryNag
//
//  Monitors battery level and triggers warnings/sleep.
//

import Foundation
import AppKit
import IOKit.ps
import Combine
import UserNotifications
import ServiceManagement

class BatteryMonitor: ObservableObject {
    // MARK: - Settings (persisted)
    @Published var warnThreshold: Int {
        didSet { UserDefaults.standard.set(warnThreshold, forKey: "warnThreshold") }
    }
    @Published var criticalThreshold: Int {
        didSet { UserDefaults.standard.set(criticalThreshold, forKey: "criticalThreshold") }
    }
    @Published var checkInterval: Int {
        didSet { UserDefaults.standard.set(checkInterval, forKey: "checkInterval"); restartTimer() }
    }
    @Published var speakWarnings: Bool {
        didSet { UserDefaults.standard.set(speakWarnings, forKey: "speakWarnings") }
    }
    @Published var forceSleepEnabled: Bool {
        didSet { UserDefaults.standard.set(forceSleepEnabled, forKey: "forceSleepEnabled") }
    }
    @Published var launchAtLogin: Bool = false

    // MARK: - State
    @Published var batteryLevel: Int = 100
    @Published var isOnBattery: Bool = false
    @Published var isCharging: Bool = false
    @Published var lastWarningTime: Date? = nil
    @Published var logEntries: [String] = []

    private var timer: Timer?
    private var hasNaggedThisCycle = false  // reset when plugged back in
    private let synthesizer = NSSpeechSynthesizer()

    // MARK: - Computed
    var menuBarIcon: String {
        if isCharging {
            return "battery.100.bolt"
        }
        if batteryLevel <= criticalThreshold {
            return "battery.0"
        } else if batteryLevel <= warnThreshold {
            return "battery.25"
        } else if batteryLevel <= 60 {
            return "battery.50"
        } else if batteryLevel <= 80 {
            return "battery.75"
        }
        return "battery.100"
    }

    // MARK: - Init
    init() {
        let defaults = UserDefaults.standard
        self.warnThreshold = defaults.object(forKey: "warnThreshold") as? Int ?? 40
        self.criticalThreshold = defaults.object(forKey: "criticalThreshold") as? Int ?? 20
        self.checkInterval = defaults.object(forKey: "checkInterval") as? Int ?? 30
        self.speakWarnings = defaults.object(forKey: "speakWarnings") as? Bool ?? true
        self.forceSleepEnabled = defaults.object(forKey: "forceSleepEnabled") as? Bool ?? true

        requestNotificationPermission()
        checkBattery()
        startTimer()
    }

    // MARK: - Timer
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(checkInterval), repeats: true) { [weak self] _ in
            self?.checkBattery()
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        startTimer()
    }

    // MARK: - Battery Check
    func checkBattery() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let firstSource = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, firstSource)?.takeUnretainedValue() as? [String: Any]
        else {
            log("⚠️ Could not read battery info")
            return
        }

        let level = info[kIOPSCurrentCapacityKey] as? Int ?? 0
        let powerSource = info[kIOPSPowerSourceStateKey] as? String ?? ""
        let charging = info[kIOPSIsChargingKey] as? Bool ?? false

        DispatchQueue.main.async {
            self.batteryLevel = level
            self.isOnBattery = (powerSource == kIOPSBatteryPowerValue)
            self.isCharging = charging

            // Reset nag cycle when plugged back in
            if !self.isOnBattery || charging {
                self.hasNaggedThisCycle = false
                return
            }

            // Only act when on battery
            self.evaluateLevel(level)
        }
    }

    private func evaluateLevel(_ level: Int) {
        if level <= criticalThreshold && forceSleepEnabled {
            log("🚨 CRITICAL: \(level)% — forcing sleep!")
            showAlert(title: "⚠️ CRITICAL BATTERY", message: "Battery at \(level)%. Sleeping NOW to protect battery.", critical: true)
            if speakWarnings {
                synthesizer.startSpeaking("Critical battery. Sleeping now.")
            }
            // Give 3 seconds for the alert/speech then sleep
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.forceSleep()
            }
        } else if level <= warnThreshold {
            // Nag every check cycle
            log("⚠️ WARNING: \(level)% — connect charger!")
            showAlert(title: "🔋 Low Battery", message: "Battery at \(level)%. Please connect the charger.", critical: false)
            if speakWarnings {
                synthesizer.startSpeaking("Battery at \(level) percent. Connect charger.")
            }
            sendNotification(title: "🔋 Battery Low", body: "Battery at \(level)%. Connect charger!")
            lastWarningTime = Date()
        }
    }

    // MARK: - Actions
    private func forceSleep() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["sleepnow"]
        try? task.run()
    }

    private func showAlert(title: String, message: String, critical: Bool) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = critical ? .critical : .warning
        alert.addButton(withTitle: "OK")
        // Run non-modally so it doesn't block the timer
        alert.runModal()
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Logging
    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let entry = "[\(formatter.string(from: Date()))] \(message)"
        DispatchQueue.main.async {
            self.logEntries.append(entry)
            if self.logEntries.count > 200 {
                self.logEntries.removeFirst()
            }
        }
    }

    // MARK: - Launch at Login
    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                log("⚠️ Launch at login error: \(error.localizedDescription)")
            }
        }
    }
}
