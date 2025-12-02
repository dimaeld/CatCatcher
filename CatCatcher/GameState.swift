import SwiftUI
import Combine

// GameState is the single source of truth for UI about the running game.
final class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var lives: Int = 3
    @Published var isGameOver: Bool = false
    @Published var isPaused: Bool = false

    // Persisted best score (AppStorage persists via UserDefaults)
    @AppStorage("CatCatcherBestScore") var bestScore: Int = 0

    // Reset for a new play session
    func resetForNewGame() {
        score = 0
        lives = 3
        isGameOver = false
        isPaused = false
    }

    // Called when player catches a good item
    func addPoints(_ points: Int = 1) {
        guard !isGameOver else { return }
        score += points
    }

    // Called when hit by a bad item
    func loseLife() {
        guard !isGameOver else { return }
        lives -= 1
        if lives <= 0 {
            triggerGameOver()
        }
    }

    // Mark game over and persist best score if needed
    func triggerGameOver() {
        isGameOver = true
        if score > bestScore {
            bestScore = score
        }
    }

    // Toggle pause state
    func togglePause() {
        guard !isGameOver else { return }
        isPaused.toggle()
    }
}
