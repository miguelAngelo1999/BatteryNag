//
//  ContentView.swift
//  BatteryNag
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var batteryMonitor: BatteryMonitor

    var body: some View {
        VStack(spacing: 12) {
            // Status
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: batteryMonitor.menuBarIcon)
                        .font(.title)
                        .foregroundColor(statusColor)
                    Text("\(batteryMonitor.batteryLevel)%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                }
                Text(batteryMonitor.isCharging ? "Charging" : (batteryMonitor.isOnBattery ? "On Battery" : "On AC Power"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)

            Divider()

            // Settings
            VStack(alignment: .leading, spacing: 8) {
                Text("Thresholds").font(.headline)

                HStack {
                    Text("Warn at:")
                    Stepper("\(batteryMonitor.warnThreshold)%",
                            value: $batteryMonitor.warnThreshold, in: 10...80, step: 5)
                        .frame(width: 120)
                }

                HStack {
                    Text("Force sleep at:")
                    Stepper("\(batteryMonitor.criticalThreshold)%",
                            value: $batteryMonitor.criticalThreshold, in: 5...50, step: 5)
                        .frame(width: 120)
                }

                HStack {
                    Text("Check every:")
                    Stepper("\(batteryMonitor.checkInterval)s",
                            value: $batteryMonitor.checkInterval, in: 10...300, step: 10)
                        .frame(width: 120)
                }

                Toggle("Speak warnings", isOn: $batteryMonitor.speakWarnings)
                Toggle("Force sleep at critical", isOn: $batteryMonitor.forceSleepEnabled)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            Divider()

            // Log
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Log").font(.headline)
                    Spacer()
                    Button("Clear") { batteryMonitor.logEntries.removeAll() }
                        .buttonStyle(.borderless)
                        .font(.caption)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(batteryMonitor.logEntries, id: \.self) { entry in
                            Text(entry)
                                .font(.system(size: 10, design: .monospaced))
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(4)
                }
                .frame(maxHeight: 120)
                .background(Color.black.opacity(0.05))
                .cornerRadius(4)
            }

            Spacer()

            HStack {
                if let lastWarn = batteryMonitor.lastWarningTime {
                    Text("Last warning: \(timeAgo(lastWarn))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }

    private var statusColor: Color {
        if batteryMonitor.batteryLevel <= batteryMonitor.criticalThreshold {
            return .red
        } else if batteryMonitor.batteryLevel <= batteryMonitor.warnThreshold {
            return .orange
        }
        return .green
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "\(seconds)s ago" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }
}
