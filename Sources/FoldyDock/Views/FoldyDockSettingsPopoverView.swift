import SwiftUI
import AppKit

public struct FoldyDockSettingsPopoverView: View {
    @ObservedObject var viewModel: DockViewModel
    public var onClose: (() -> Void)?

    @State private var showingResetConfirmation: Bool = false

    public init(viewModel: DockViewModel, onClose: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Paramètres FoldyDock")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                if let onClose = onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
                .background(Color.white.opacity(0.15))

            // Section 1: Masquage automatique
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Masquage automatique (Autohide)", isOn: Binding(
                    get: { viewModel.config.autohideEnabled },
                    set: { _ in viewModel.toggleAutohide() }
                ))
                .toggleStyle(.switch)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)

                if viewModel.config.autohideEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                             Text("Délai de masquage :")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))
                            Spacer()
                            Text("\(String(format: "%.1f", viewModel.config.autohideDelay)) s")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        Slider(
                            value: Binding(
                                get: { viewModel.config.autohideDelay },
                                set: { newValue in
                                    viewModel.config.autohideDelay = newValue
                                    viewModel.saveConfig()
                                }
                            ),
                            in: 0.1...1.5,
                            step: 0.1
                        )
                    }
                    .padding(.leading, 4)
                }
            }

            Divider()
                .background(Color.white.opacity(0.15))

            // Section 2: Taille des icônes
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Taille des icônes :")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(viewModel.config.iconSize)) pt")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Slider(
                    value: Binding(
                        get: { viewModel.config.iconSize },
                        set: { newValue in
                            viewModel.config.iconSize = newValue
                            viewModel.saveConfig()
                        }
                    ),
                    in: 32...96,
                    step: 2
                )
            }

            Divider()
                .background(Color.white.opacity(0.15))

            // Section 3: Actions
            VStack(spacing: 8) {
                Button(action: {
                    showingResetConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Réinitialiser les applications")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
                    .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .alert(isPresented: $showingResetConfirmation) {
                    Alert(
                        title: Text("Réinitialiser le Dock"),
                        message: Text("Voulez-vous restaurer la configuration et les applications par défaut de FoldyDock ?"),
                        primaryButton: .destructive(Text("Réinitialiser")) {
                            viewModel.resetToDefaults()
                            onClose?()
                        },
                        secondaryButton: .cancel(Text("Annuler"))
                    )
                }

                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quitter FoldyDock")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(6)
                    .foregroundStyle(.red.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(white: 0.14).opacity(0.75))
        )
    }
}
