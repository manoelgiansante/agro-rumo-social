import SwiftUI

struct CreatePostView: View {
    let viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: PostCategory = .dicaManutencao
    @State private var customPrompt = ""
    @State private var scheduledDate = Date()
    @State private var scheduledTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var platforms: Set<SocialPlatform> = [.instagram, .facebook, .tiktok]
    @State private var useAI = true
    @State private var manualCaption = ""
    @State private var isGenerating = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                categorySection
                contentSection
                scheduleSection
                platformSection
                previewSection
            }
            .navigationTitle("Novo Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await createPost() }
                    } label: {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Text("Criar")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isGenerating || (!useAI && manualCaption.isEmpty))
                }
            }
            .alert("Post Criado!", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Seu post foi agendado para \(scheduledDate.formatted(.dateTime.day().month(.wide))) às \(combinedDateTime.formatted(.dateTime.hour().minute())).")
            }
        }
    }

    private var categorySection: some View {
        Section {
            Picker("Categoria", selection: $selectedCategory) {
                ForEach(PostCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.icon)
                        .tag(category)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("Categoria do Conteúdo")
        } footer: {
            Text("Escolha o tipo de conteúdo que será publicado.")
        }
    }

    private var contentSection: some View {
        Section {
            Toggle(isOn: $useAI) {
                Label("Gerar com IA", systemImage: "sparkles")
            }
            .tint(.green)

            if useAI {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instruções para a IA (opcional)")
                        .font(.subheadline.weight(.medium))
                    TextEditor(text: $customPrompt)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 8))
                }

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    Text("Legenda, hashtags e imagem gerados automaticamente")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Legenda")
                        .font(.subheadline.weight(.medium))
                    TextEditor(text: $manualCaption)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 8))
                }

                HStack {
                    Text("\(manualCaption.count)/2200")
                        .font(.caption)
                        .foregroundStyle(manualCaption.count > 2200 ? .red : .secondary)
                    Spacer()
                }
            }
        } header: {
            Text("Conteúdo")
        }
    }

    private var scheduleSection: some View {
        Section {
            DatePicker("Data", selection: $scheduledDate, in: Date()..., displayedComponents: .date)
            DatePicker("Horário", selection: $scheduledTime, displayedComponents: .hourAndMinute)

            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text("Melhor horário para engajamento: 7h-8h manhã")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Agendamento")
        } footer: {
            Text("Horário de Brasília (BRT)")
        }
    }

    private var platformSection: some View {
        Section {
            ForEach(SocialPlatform.allCases, id: \.self) { platform in
                let isOn = platforms.contains(platform)
                Button {
                    if isOn {
                        platforms.remove(platform)
                    } else {
                        platforms.insert(platform)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: platform.icon)
                            .foregroundStyle(platformColor(platform))
                            .frame(width: 24)
                        Text(platform.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isOn ? .green : .secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
        } header: {
            Text("Publicar em")
        }
    }

    private var previewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedCategory.tintColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: selectedCategory.icon)
                                .foregroundStyle(selectedCategory.tintColor)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedCategory.displayName)
                            .font(.subheadline.weight(.semibold))
                        Text(combinedDateTime.formatted(.dateTime.day().month(.abbreviated).hour().minute()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 6) {
                    ForEach(Array(platforms).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { platform in
                        HStack(spacing: 4) {
                            Image(systemName: platform.icon)
                            Text(platform.displayName)
                        }
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(platformColor(platform).opacity(0.1))
                        .foregroundStyle(platformColor(platform))
                        .clipShape(Capsule())
                    }
                }

                if useAI {
                    Label("Conteúdo será gerado por IA", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.purple)
                } else if !manualCaption.isEmpty {
                    Text(String(manualCaption.prefix(100)) + (manualCaption.count > 100 ? "..." : ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
        } header: {
            Text("Resumo")
        }
    }

    private var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: scheduledDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        return calendar.date(from: combined) ?? scheduledDate
    }

    private func platformColor(_ platform: SocialPlatform) -> Color {
        switch platform {
        case .instagram: return .pink
        case .facebook: return .blue
        case .tiktok: return .primary
        }
    }

    private func createPost() async {
        isGenerating = true
        defer { isGenerating = false }

        if useAI {
            await viewModel.generateContent()
        }
        showSuccess = true
    }
}
