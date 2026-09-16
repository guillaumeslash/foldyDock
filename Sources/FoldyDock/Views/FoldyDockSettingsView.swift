import SwiftUI
import AppKit

public struct FoldyDockSettingsView: View {
    @ObservedObject var viewModel: DockViewModel
    public var onClose: (() -> Void)?

    @State private var showingResetConfirmation: Bool = false

    public init(viewModel: DockViewModel, onClose: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Window Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .shadow(color: Color.blue.opacity(0.35), radius: 6, x: 0, y: 3)

                    Image(systemName: "dock.rectangle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("FoldyDock")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Paramètres & Personnalisation")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("v1.0")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(6)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    // Section 1: Masquage automatique
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Masquage automatique (Autohide)", isOn: Binding(
                                get: { viewModel.config.autohideEnabled },
                                set: { _ in viewModel.toggleAutohide() }
                            ))
                            .toggleStyle(.switch)
                            .font(.system(size: 13, weight: .medium))

                            Text("Rétracte automatiquement le dock vers le bas de l'écran lorsque le curseur quitte la zone.")
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)

                            if viewModel.config.autohideEnabled {
                                Divider()

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Délai avant masquage")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(String(format: "%.1f", viewModel.config.autohideDelay)) s")
                                            .font(.system(size: 12, weight: .semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.12))
                                            .cornerRadius(4)
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
                            }
                        }
                        .padding(8)
                    } label: {
                        Label("Comportement", systemImage: "eye")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    // Section 2: Taille des icônes
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Taille des icônes")
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Text("\(Int(viewModel.config.iconSize)) pt")
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.12))
                                    .cornerRadius(4)
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

                            HStack(spacing: 8) {
                                ForEach([40, 56, 72, 88], id: \.self) { size in
                                    Button("\(size) pt") {
                                        viewModel.config.iconSize = Double(size)
                                        viewModel.saveConfig()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(Int(viewModel.config.iconSize) == size ? Color.accentColor : Color.secondary)
                                }
                            }
                        }
                        .padding(8)
                    } label: {
                        Label("Apparence", systemImage: "aspectratio")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    // Section 3: Organisation du Dock
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Personnalisez l'agencement du dock avec des séparateurs et des dossiers.")
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                Button {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                        viewModel.insertSeparator(at: viewModel.items.count)
                                    }
                                } label: {
                                    Label("Ajouter un séparateur", systemImage: "line.diagonal")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                        viewModel.createEmptyFolder(at: viewModel.items.count)
                                    }
                                } label: {
                                    Label("Nouveau dossier", systemImage: "folder.badge.plus")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }

                            Divider()

                            Toggle("Afficher la corbeille", isOn: Binding(
                                get: { viewModel.config.showTrash },
                                set: { _ in
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                        viewModel.toggleTrash()
                                    }
                                }
                            ))
                            .toggleStyle(.switch)
                            .font(.system(size: 13, weight: .medium))

                            Text("Affiche la corbeille macOS à l'extrémité droite du dock.")
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                    } label: {
                        Label("Organisation", systemImage: "square.grid.2x2")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    // Section 4: Maintenance & Quitter
                    VStack(spacing: 10) {
                        Button(action: {
                            showingResetConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Restaurer les applications par défaut")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .alert(isPresented: $showingResetConfirmation) {
                            Alert(
                                title: Text("Réinitialiser le Dock"),
                                message: Text("Voulez-vous restaurer la configuration et les applications par défaut de FoldyDock ?"),
                                primaryButton: .destructive(Text("Réinitialiser")) {
                                    viewModel.resetToDefaults()
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
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 400, height: 500)
    }
}
