import SwiftUI

/// Celebratory confetti animation for excellent scores (80+)
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                ConfettiShape()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .rotationEffect(.degrees(piece.rotation))
                    .offset(x: piece.x, y: piece.y)
                    .opacity(piece.opacity)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }

    private func generateConfetti() {
        // Generate 30 confetti pieces with random properties
        confettiPieces = (0..<30).map { index in
            ConfettiPiece(
                id: index,
                x: 0,
                y: 0,
                color: randomColor(),
                size: CGFloat.random(in: 6...12),
                rotation: 0,
                opacity: 1.0
            )
        }

        // Animate each piece
        for (index, _) in confettiPieces.enumerated() {
            let randomDelay = Double.random(in: 0...0.3)
            let randomDuration = Double.random(in: 1.0...1.5)
            let randomX = CGFloat.random(in: -100...100)
            let randomY = CGFloat.random(in: -150...50)
            let randomRotation = Double.random(in: 0...720)

            withAnimation(.easeOut(duration: randomDuration).delay(randomDelay)) {
                confettiPieces[index].x = randomX
                confettiPieces[index].y = randomY
                confettiPieces[index].rotation = randomRotation
            }

            // Fade out after reaching position
            withAnimation(.easeIn(duration: 0.4).delay(randomDelay + randomDuration - 0.4)) {
                confettiPieces[index].opacity = 0
            }
        }
    }

    private func randomColor() -> Color {
        let colors: [Color] = [
            .green,
            .mint,
            .teal,
            .blue,
            .purple,
            .pink,
            .yellow,
            .orange
        ]
        return colors.randomElement() ?? .green
    }
}

// MARK: - Supporting Types

struct ConfettiPiece: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var rotation: Double
    var opacity: Double
}

struct ConfettiShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Create a rounded rectangle confetti piece
        let cornerRadius = min(rect.width, rect.height) * 0.3
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: Spacing.xxl) {
            Text("Confetti Preview")
                .headlineMediumStyle()

            ConfettiView()
                .frame(width: 200, height: 200)
        }
    }
}
