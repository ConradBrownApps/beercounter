import SwiftUI

struct PourAnimationView: View {
    let color: Color
    let label: String
    var onComplete: (() -> Void)?

    @State private var fill: CGFloat = 0.06
    @State private var opacity: Double = 1
    @State private var verticalOffset: CGFloat = 16

    var body: some View {
        VStack(spacing: 10) {
            BeerMugView(fillLevel: fill, fillColor: color)
                .frame(width: 84, height: 98)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(14)
        .background(AppTheme.cardBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.outline.opacity(0.55), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
        .opacity(opacity)
        .offset(y: verticalOffset)
        .onAppear {
            withAnimation(.timingCurve(0.2, 0.9, 0.2, 1.0, duration: 0.5)) {
                fill = 0.92
                verticalOffset = 0
            }

            withAnimation(.easeInOut(duration: 0.3).delay(0.95)) {
                opacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                onComplete?()
            }
        }
    }
}

private struct BeerMugView: View {
    let fillLevel: CGFloat
    let fillColor: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let mugBodyRect = CGRect(
                x: width * 0.06,
                y: height * 0.04,
                width: width * 0.7,
                height: height * 0.88
            )
            let mugBodyCornerRadius = width * 0.11
            let interiorInset: CGFloat = 3.5
            let mugInteriorRect = mugBodyRect.insetBy(dx: interiorInset, dy: interiorInset)
            let mugInteriorCornerRadius = max(mugBodyCornerRadius - interiorInset, 0)
            let liquidHeight = mugInteriorRect.height * max(fillLevel, 0.02)

            ZStack {
                Capsule(style: .continuous)
                    .stroke(AppTheme.outline, lineWidth: 5)
                    .frame(width: width * 0.22, height: height * 0.42)
                    .offset(x: width * 0.35, y: height * 0.02)

                MugBodyShape()
                    .fill(Color.white.opacity(0.45))

                // Rising beer fill clipped to the mug body to keep the animation inside the glass.
                RoundedRectangle(cornerRadius: mugInteriorCornerRadius, style: .continuous)
                    .fill(fillColor.gradient)
                    .frame(height: liquidHeight)
                    .frame(width: mugInteriorRect.width, height: mugInteriorRect.height, alignment: .bottom)
                    .position(x: mugInteriorRect.midX, y: mugInteriorRect.midY)
                    .clipShape(
                        RoundedRectangle(cornerRadius: mugInteriorCornerRadius, style: .continuous)
                    )

                Rectangle()
                    .fill(Color.white.opacity(0.33))
                    .frame(width: width * 0.12, height: height * 0.62)
                    .blur(radius: 2)
                    .offset(x: -width * 0.18)

                MugBodyShape()
                    .stroke(AppTheme.outline, lineWidth: 2)
            }
        }
    }
}

private struct MugBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let mugRect = CGRect(
            x: rect.minX + rect.width * 0.06,
            y: rect.minY + rect.height * 0.04,
            width: rect.width * 0.7,
            height: rect.height * 0.88
        )

        return RoundedRectangle(cornerRadius: rect.width * 0.11, style: .continuous)
            .path(in: mugRect)
    }
}
