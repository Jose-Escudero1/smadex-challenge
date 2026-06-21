//
//  ContentView.swift
//  FeatureFlagsDemo
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = FlagsViewModel()
    @State private var showingCreateRequest = false

    private let line = Color.primary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("FEATURE FLAGS KIT")
                    .font(.system(size: 26, weight: .black))
                    .padding(.top, 4)

                if let error = viewModel.errorMessage {
                    errorBanner(error)
                }

                // Cada flag etiquetado por su tipo, para que quede claro qué es cada uno.
                block(title: "new_home_enabled") {
                    cell {
                        Text("Estado")
                        Spacer()
                        Text(viewModel.isHomeEnabled ? "ON" : "OFF")
                            .fontWeight(.bold)
                            .foregroundStyle(viewModel.isHomeEnabled ? Color.green : Color.secondary)
                    }
                }

                block(title: "home_title") {
                    cell {
                        Text(viewModel.homeTitle)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }

                block(title: "home_max_items") {
                    cell {
                        Text("Máximo de elementos")
                        Spacer()
                        Text("\(viewModel.maxItems)").fontWeight(.bold)
                    }
                }

                outlineButton(title: "CREAR RESPONSE") {
                    showingCreateRequest = true
                }
                .disabled(viewModel.isLoading)
                .padding(.top, 4)
            }
            .font(.system(.body))
            .padding(20)
        }
        .background(Color(white: 0.96))
        .task { await viewModel.reloadValues() }
        .sheet(isPresented: $showingCreateRequest) {
            CreateRequestSheet { json in
                Task { await viewModel.applyPastedJSON(json) }
            }
        }
    }

    // MARK: - Bloques con borde recto (sin esquinas redondeadas)

    @ViewBuilder
    private func block<Content: View>(
        title: String,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(.caption).weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)

            VStack(spacing: 0) { content() }
                .overlay(Rectangle().stroke(line, lineWidth: 1))
                .background(Color(white: 1.0))
        }
    }

    @ViewBuilder
    private func cell<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack { content() }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message).font(.system(.footnote))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.black)
        .background(Color(red: 1.0, green: 0.86, blue: 0.55))
        .overlay(Rectangle().stroke(line, lineWidth: 1))
    }

    // MARK: - Botones rectos

    private func outlineButton(
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title).fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(line)
        .overlay(Rectangle().stroke(line, lineWidth: 1))
    }
}

// MARK: - Modal "Crear petición"

struct CreateRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var jsonText: String = CreateRequestSheet.sample
    let onApply: (String) -> Void

    static let sample = """
    {
      "new_home_enabled": FALE,
      "home_title": "Hola!",
      "home_max_items": 5
    }
    """

    private let line = Color.primary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("CREAR PETICIÓN")
                    .font(.system(.headline).weight(.black))
                Spacer()
                Button("Cancelar") { dismiss() }
                    .font(.system(.body))
            }
            .padding(16)

            TextEditor(text: $jsonText)
                .font(.system(.callout))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 220)
                .overlay(Rectangle().stroke(line, lineWidth: 1))
                .padding(.horizontal, 16)

            Spacer(minLength: 16)

            Button {
                let text = jsonText
                dismiss()
                onApply(text)
            } label: {
                Text("Enviar")
                    .font(.system(.body).weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(white: 0.96))
            .background(line)
            .padding(16)
        }
        .background(Color(white: 0.96))
    }
}

#Preview {
    ContentView()
}
