import CoreHaptics
import HotwireNative
import UIKit

/// A bridge component that provides haptic feedback (vibrations) to the user.
/// This component responds to the "haptic" name from the web side.
final class HapticComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "haptic" }

    // MARK: - BridgeComponent

    /// Called when a message is received from the web side.
    /// - Parameter message: The message object containing the event and data.
    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .vibrate:
            handleVibrateEvent(with: message)
        }
    }

    // MARK: - Private Methods

    /// Triggers haptic feedback based on the feedback type provided in the message.
    /// - Parameter message: The message containing feedback type (success, warning, error).
    private func handleVibrateEvent(with message: Message) {
        guard let data: MessageData = message.data() else { return }

        // Use UINotificationFeedbackGenerator for predefined system haptic patterns
        switch FeedbackType(rawValue: data.feedback) {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        default:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Events

private extension HapticComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Triggers a vibration.
        case vibrate
    }
}

// MARK: - Data Models

private extension HapticComponent {
    /// The data structure expected in the message from the web side.
    struct MessageData: Decodable {
        /// The type of feedback to trigger.
        let feedback: String
    }

    /// Supported feedback types for haptic notifications.
    enum FeedbackType: String {
        case success
        case warning
        case error
    }
}
