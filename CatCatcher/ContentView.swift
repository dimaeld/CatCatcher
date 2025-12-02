import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var showGame = false
    @State private var showHowToPlay = false

    // Show best score via AppStorage so menu reads same key
    @AppStorage("CatCatcherBestScore") private var storedBestScore: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(colors: [Color(red:0.4, green:0.8, blue:1.0), Color(red:0.8, green:0.9, blue:1.0)],
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()
                    // Title
                    Text("CatCatcher Deluxe")
                        .font(.largeTitle.weight(.black))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(LinearGradient(colors: [.white, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(radius: 6)

                    // Cute subtitle
                    Text("Catch goodies. Avoid the bad stuff!")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Spacer()

                    VStack(spacing: 12) {
                        // Play button
                        Button(action: {
                            gameState.resetForNewGame()
                            showGame = true
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                Text("Play")
                                    .font(.title2.weight(.semibold))
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.linearGradient(colors: [Color.orange, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 6)
                        }
                        .padding(.horizontal, 24)

                        // How to play
                        Button(action: { showHowToPlay = true }) {
                            Text("How to play")
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer()

                    // Best score display
                    VStack(spacing: 6) {
                        Text("Best Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(storedBestScore)")
                            .font(.title.weight(.bold))
                            .foregroundColor(.primary)
                            .padding(.bottom, 8)
                    }

                    Spacer(minLength: 30)

                    // Small credit / hint
                    Text("Drag or tap left/right to move the cat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 24)
                }
                .padding()
            }
            .fullScreenCover(isPresented: $showGame) {
                GameView(gameState: gameState) {
                    showGame = false
                }
            }
            .sheet(isPresented: $showHowToPlay) {
                HowToPlayView()
            }
        }
    }
}

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("How to play")
                    .font(.title2).bold()
                Text("• Drag your finger left and right (or tap left/right) to move the cat.")
                Text("• Catch good items (fish, coins) to score points.")
                Text("• Avoid bad items (bombs, boots). Each hit costs a life.")
                Text("• The game speeds up as your score increases.")
                Text("• You have 3 lives. Game ends when lives reach 0.")
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
