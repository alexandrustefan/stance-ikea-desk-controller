import Foundation

enum DeskConnectionState: String, Sendable, Equatable {
    case disconnected
    case scanning
    case connecting
    case connected
}

struct DeskPosition: Sendable, Equatable {
    var heightCM: Float
    var speed: Float
}
