import SwiftUI
import SpriteKit
import UIKit

struct GameView: View {
    @ObservedObject var gameState: GameState
    var onExit: (() -> Void)? = nil

    @State private var scene: GameScene?

    var body: some View {
        ZStack {
            // Gradient background behind the SpriteView
            LinearGradient(colors: [Color(red:0.55, green:0.85, blue:1.0), Color(red:0.9, green:0.95, blue:1.0)],
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()

            GeometryReader { geo in
                SpriteView(scene: scene ?? GameScene(size: geo.size, gameState: gameState))
                    .ignoresSafeArea()
                    .onAppear {
                        if scene == nil {
                            let newScene = GameScene(size: geo.size, gameState: gameState)
                            newScene.scaleMode = .resizeFill
                            self.scene = newScene
                        } else {
                            scene?.size = geo.size
                        }
                    }
                    .onChange(of: geo.size) { newSize in
                        scene?.size = newSize
                    }
            }

            // HUD overlay
            VStack {
                HStack {
                    HStack(spacing: 8) {
                        Text("Score:")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("\(gameState.score)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(10)

                    Spacer()

                    HStack(spacing: 8) {
                        Text("Best:")
                            .foregroundColor(.white.opacity(0.9))
                        Text("\(gameState.bestScore)")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.22))
                    .cornerRadius(10)

                    Spacer()

                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            Image(systemName: i < gameState.lives ? "heart.fill" : "heart")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.22))
                    .cornerRadius(10)

                    Button(action: {
                        gameState.togglePause()
                        scene?.isPaused = gameState.isPaused
                    }) {
                        Image(systemName: gameState.isPaused ? "play.fill" : "pause.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.25))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 48)

                Spacer()
            }

            // Pause overlay
            if gameState.isPaused && !gameState.isGameOver {
                Color.black.opacity(0.35).ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Paused")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    HStack(spacing: 12) {
                        Button("Resume") {
                            gameState.togglePause()
                            scene?.isPaused = false
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Quit") {
                            scene?.removeAllActions()
                            scene?.removeAllChildren()
                            onExit?()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }

            // Game Over overlay
            if gameState.isGameOver {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 18) {
                    Text("Game Over")
                        .font(.system(size: 44, weight: .black))
                        .foregroundColor(.white)
                    VStack {
                        Text("Final Score")
                            .foregroundColor(.white.opacity(0.9))
                        Text("\(gameState.score)")
                            .font(.title.weight(.bold))
                            .foregroundColor(.yellow)
                    }
                    VStack {
                        Text("Best")
                            .foregroundColor(.white.opacity(0.9))
                        Text("\(gameState.bestScore)")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                    }

                    HStack(spacing: 16) {
                        Button(action: {
                            gameState.resetForNewGame()
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                if let size = windowScene.screen.bounds.size as CGSize? {
                                    let newScene = GameScene(size: size, gameState: gameState)
                                    newScene.scaleMode = .resizeFill
                                    self.scene = newScene
                                } else {
                                    let newScene = GameScene(size: CGSize(width: 750, height: 1334), gameState: gameState)
                                    newScene.scaleMode = .resizeFill
                                    self.scene = newScene
                                }
                            } else {
                                let newScene = GameScene(size: CGSize(width: 750, height: 1334), gameState: gameState)
                                newScene.scaleMode = .resizeFill
                                self.scene = newScene
                            }
                        }) {
                            Text("Play Again")
                                .font(.headline)
                                .padding()
                                .frame(minWidth: 140)
                                .background(.linearGradient(colors: [Color.green, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            onExit?()
                        }) {
                            Text("Back to Menu")
                                .font(.headline)
                                .padding()
                                .frame(minWidth: 140)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
        }
        .onDisappear {
            scene?.removeAllActions()
            scene?.removeAllChildren()
            scene = nil
        }
    }
}
