import AppIntents
import WidgetKit
import ActivityKit

@available(iOS 17.0, *)
struct RecordVoiceExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Voice Expense"
    static var description = IntentDescription("Triggers quick voice capture overlay without opening Kharcha.")
    
    // Keeps execution backgrounded without foregrounding the main Flutter scene
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        // Start an ActivityKit Live Activity on Dynamic Island & Lock Screen
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let attributes = VoiceCaptureWidgetAttributes(sessionTitle: "Quick Expense")
            let initialContentState = VoiceCaptureWidgetAttributes.ContentState(
                status: "Listening...",
                amplitude: 0.8,
                detectedAmount: 0.0,
                detectedMerchant: ""
            )
            
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: initialContentState, staleDate: nil),
                    pushType: nil
                )
                print("Voice capture Live Activity initiated: \(activity.id)")
            } catch {
                print("Live Activity request failed: \(error.localizedDescription)")
            }
        }
        
        // Notify WidgetKit to re-evaluate state
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
