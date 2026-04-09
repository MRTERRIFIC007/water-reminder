import SwiftUI

struct MainView: View {
    @Bindable var store: HydrationStore
    let isDark: Bool
    let onToggleTheme: () -> Void
    let onSwipeUp: () -> Void

    @State private var animatedProgress: Double = 0
    @State private var ripples: [(id: UUID, position: CGPoint)] = []
    @State private var showInkWash = false
    @State private var toastText: String? = nil

    var body: some View {
        let inkColor = EnsoTheme.adaptive(EnsoTheme.ink, EnsoTheme.inkDark, isDark: isDark)
        let inkLight = EnsoTheme.adaptive(EnsoTheme.inkLight, EnsoTheme.inkLightDark, isDark: isDark)

        ZStack {
            // Ink wash (completion effect)
            if showInkWash {
                RadialGradient(
                    colors: [inkColor.opacity(0.06), .clear],
                    center: UnitPoint(x: 0.5, y: 0.42),
                    startRadius: 0,
                    endRadius: 300
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }

            VStack(spacing: 0) {
                Spacer()

                // The Enso
                ZStack {
                    EnsoCanvasView(progress: animatedProgress, isDark: isDark)

                    // Ink ripples
                    ForEach(ripples, id: \.id) { ripple in
                        InkRippleView(position: ripple.position, isDark: isDark)
                    }

                    // Completion seal
                    SealView(isVisible: store.isComplete, isDark: isDark)
                }
                .frame(width: EnsoTheme.ensoSize, height: EnsoTheme.ensoSize)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    logWater(at: location)
                }
                .offset(y: -30)

                // Progress label
                if store.glasses > 0 {
                    VStack(spacing: 6) {
                        Text("\(store.todayMl.formatted())")
                            .font(EnsoTheme.heroFont(32))
                            .foregroundStyle(inkColor)
                            .tracking(-0.5)

                        Text("of \(store.dailyBaseGoal.formatted()) ml")
                            .font(EnsoTheme.labelFont(12))
                            .foregroundStyle(inkLight)
                            .tracking(0.7)
                    }
                    .padding(.top, 32)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 6)),
                        removal: .opacity
                    ))
                }

                Spacer()
            }

            // Theme toggle (top right)
            VStack {
                HStack {
                    Spacer()
                    Button(action: onToggleTheme) {
                        Image(systemName: isDark ? "moon" : "sun.max")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(inkColor)
                    }
                    .frame(width: EnsoTheme.themeButtonSize, height: EnsoTheme.themeButtonSize)
                    .opacity(0.2)
                    .padding(.top, 58)
                    .padding(.trailing, 24)
                }
                Spacer()
            }

            // Toast
            if let toast = toastText {
                VStack {
                    Text(toast)
                        .font(EnsoTheme.labelFont(13))
                        .foregroundStyle(EnsoTheme.adaptive(EnsoTheme.inkMid, EnsoTheme.inkMidDark, isDark: isDark))
                        .tracking(1)
                        .padding(.top, 68)
                    Spacer()
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: -12)),
                    removal: .opacity
                ))
            }

            // Swipe cue (bottom)
            VStack {
                Spacer()
                VStack(spacing: 6) {
                    Rectangle()
                        .fill(inkLight)
                        .frame(width: 28, height: 1)
                    Text("details")
                        .font(EnsoTheme.labelFont(9))
                        .tracking(1.6)
                        .foregroundStyle(inkLight)
                }
                .opacity(0.25)
                .padding(.bottom, 36)
                .onTapGesture { onSwipeUp() }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height < -50 { onSwipeUp() }
                }
        )
        .onChange(of: store.progress) { _, newVal in
            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.8)) {
                animatedProgress = newVal
            }
        }
        .onAppear {
            animatedProgress = store.progress
        }
    }

    // MARK: - Log Water

    private func logWater(at location: CGPoint) {
        store.logGlass()

        if store.hapticsEnabled {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }

        let ripple = (id: UUID(), position: location)
        ripples.append(ripple)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ripples.removeAll { $0.id == ripple.id }
        }

        withAnimation(.easeOut(duration: 0.3)) {
            toastText = "\(store.todayMl.formatted()) ml"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeIn(duration: 0.3)) { toastText = nil }
        }

        if store.isComplete && store.glasses == store.maxGlasses {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.5)) { showInkWash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation(.easeInOut(duration: 0.5)) { showInkWash = false }
                }
            }
        }
    }
}
