import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

public struct VoiceCaptureWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var amplitude: Double
        var detectedAmount: Double
        var detectedMerchant: String
    }
    var sessionTitle: String
}

@available(iOS 17.0, *)
struct VoiceLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VoiceCaptureWidgetAttributes.self) { context in
            // Lock Screen Floating Banner
            HStack(spacing: 16) {
                Circle()
                    .fill(Color(hex: 0xE65100))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "waveform.badge.mic")
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.status)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    if context.state.detectedAmount > 0 {
                        Text("\(context.state.detectedMerchant) • Rs. \(Int(context.state.detectedAmount))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: 0x2E7D32))
                    } else {
                        Text("Speak merchant and amount...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(16)
            .activityBackgroundTint(Color(hex: 0xFBF9F5))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(Color(hex: 0xE65100))
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.detectedAmount > 0 {
                        Text("Rs. \(Int(context.state.detectedAmount))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: 0x2E7D32))
                            .padding(.trailing, 8)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.status)
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Button(intent: CommitExpenseIntent()) {
                            Text("Save")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: 0x1A1A1A))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                Image(systemName: "mic.fill")
                    .foregroundColor(Color(hex: 0xE65100))
            } compactTrailing: {
                Text(context.state.detectedAmount > 0 ? "Rs. \(Int(context.state.detectedAmount))" : "•••")
                    .font(.system(size: 12, weight: .bold))
            } minimal: {
                Image(systemName: "waveform")
                    .foregroundColor(Color(hex: 0xE65100))
            }
        }
    }
}

@available(iOS 17.0, *)
struct CommitExpenseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Save Voice Expense"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        for activity in Activity<VoiceCaptureWidgetAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
        return .result()
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
