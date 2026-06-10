import SwiftUI

struct LeadDetailView: View {
    let leadId: Int

    @State private var vm: LeadDetailViewModel

    init(leadId: Int) {
        self.leadId = leadId
        self._vm    = State(initialValue: LeadDetailViewModel(leadId: leadId))
    }

    var body: some View {
        Group {
            if vm.isLoading {
                loadingView
            } else if let error = vm.errorMessage {
                errorView(error)
            } else if let lead = vm.lead {
                leadContent(lead)
            }
        }
        .navigationTitle("Lead")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .refreshable { await vm.reload() }
    }

    // MARK: - Content

    private func leadContent(_ l: AgencyLeadDetail) -> some View {
        List {
            contactSection(l)
            statusSection(l)
            if let prop = l.property {
                propertySection(prop)
            }
            qualitySection(l)
            if let assigned = l.assignedTo {
                assignmentSection(l, assigned: assigned)
            }
            if !l.notes.isEmpty {
                notesSection(l.notes)
            }
            actionsSection
        }
        .listStyle(.insetGrouped)
        .background(Color.maresmeBackground)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Contact

    private func contactSection(_ l: AgencyLeadDetail) -> some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.maresmeBlue, Color.maresmeSea],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 52, height: 52)
                    Text(String(l.name.prefix(1)).uppercased())
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(l.name)
                        .font(.maresmeTitle3)
                        .foregroundStyle(Color.maresmeText)
                    Text(l.email)
                        .font(.maresmeBodySm)
                        .foregroundStyle(Color.maresmeSubtext)
                    if let phone = l.phone {
                        Text(phone)
                            .font(.maresmeBodySm)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                }
            }
            .padding(.vertical, 6)

            if let message = l.message, !message.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mensaje")
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeSubtext)
                    Text(message)
                        .font(.maresmeBodySm)
                        .foregroundStyle(Color.maresmeText)
                }
            }
        } header: {
            Text("Contacto")
        }
    }

    // MARK: - Status

    private func statusSection(_ l: AgencyLeadDetail) -> some View {
        Section("Estado") {
            let fg = leadStatusColor(l.statusColor)
            HStack {
                Text("Estado")
                    .font(.maresmeBodySm)
                    .foregroundStyle(Color.maresmeText)
                Spacer()
                Text(l.statusLabel)
                    .font(.maresmeLabelSm)
                    .foregroundStyle(fg)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(fg.opacity(0.12))
                    .clipShape(Capsule())
            }

            if let source = l.source {
                LabeledContent("Fuente", value: source.capitalized)
            }
            if let created = l.createdAt {
                LabeledContent("Recibido", value: created.formatted(date: .abbreviated, time: .shortened))
            }
        }
    }

    // MARK: - Property

    private func propertySection(_ prop: AgencyLeadDetail.PropertyRef) -> some View {
        Section("Propiedad") {
            NavigationLink {
                AgencyPropertyDetailView(slug: prop.slug)
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(prop.title)
                        .font(.maresmeBodySm)
                        .foregroundStyle(Color.maresmeText)
                    if let municipality = prop.municipality {
                        Text(municipality)
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                    if let price = prop.price {
                        Text(formatPrice(price))
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeBlue)
                    }
                }
            }
        }
    }

    // MARK: - Quality

    private func qualitySection(_ l: AgencyLeadDetail) -> some View {
        Section("Calificación") {
            if let quality = l.leadQualityLabel ?? l.leadQuality {
                LabeledContent("Calidad", value: quality.capitalized)
            }
            if let score = l.leadScore {
                LabeledContent("Puntuación", value: "\(score)")
            }
            if let stage = l.buyerStageLabel ?? l.buyerStage {
                LabeledContent("Fase compra", value: stage)
            }
            if let matching = l.matchingScore {
                LabeledContent("Match", value: "\(matching)%")
            }
        }
    }

    // MARK: - Assignment

    private func assignmentSection(_ l: AgencyLeadDetail, assigned: AgencyLeadDetail.AssignedUser) -> some View {
        Section("Asignación") {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.maresmeBlue.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Text(String(assigned.name.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.maresmeBlue)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(assigned.name)
                        .font(.maresmeBodySm)
                        .foregroundStyle(Color.maresmeText)
                    if let role = assigned.role {
                        Text(role.capitalized)
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                }
                Spacer()
                if let at = l.assignedAt {
                    Text(at.formatted(date: .abbreviated, time: .omitted))
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeSubtext)
                }
            }
        }
    }

    // MARK: - Notes

    private func notesSection(_ notes: [AgencyLeadNote]) -> some View {
        Section("Notas (\(notes.count))") {
            ForEach(notes) { note in
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.note)
                        .font(.maresmeBodySm)
                        .foregroundStyle(Color.maresmeText)
                    HStack {
                        if let user = note.user {
                            Text(user.name)
                                .font(.maresmeCaption)
                                .foregroundStyle(Color.maresmeSubtext)
                        }
                        Spacer()
                        if let date = note.createdAt {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.maresmeCaption)
                                .foregroundStyle(Color.maresmeSubtext)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Actions (MB-PRO-2)

    private var actionsSection: some View {
        Section {
            Button {
                // MB-PRO-2: PATCH /leads/{id} — cambiar estado
            } label: {
                Label("Actualizar estado", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundStyle(Color.maresmeBlue)
            }
            .disabled(true)
            .opacity(0.5)

            Button {
                // MB-PRO-2: POST /leads/{id}/assign
            } label: {
                Label("Asignar a agente", systemImage: "person.badge.plus")
                    .foregroundStyle(Color.maresmeBlue)
            }
            .disabled(true)
            .opacity(0.5)

            Button {
                // MB-PRO-2: POST /leads/{id}/notes
            } label: {
                Label("Añadir nota", systemImage: "note.text.badge.plus")
                    .foregroundStyle(Color.maresmeBlue)
            }
            .disabled(true)
            .opacity(0.5)
        } header: {
            Text("Acciones")
        } footer: {
            Text("Las acciones estarán disponibles en la próxima versión.")
                .font(.maresmeCaption)
        }
    }

    // MARK: - Helpers

    private func leadStatusColor(_ colorName: String) -> Color {
        switch colorName {
        case "green":  return .maresmeSuccess
        case "blue":   return .maresmeBlue
        case "yellow": return .maresmeWarning
        case "red":    return .maresmeError
        default:       return .maresmeSubtext
        }
    }

    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        return "\(formatter.string(from: NSNumber(value: price)) ?? "\(price)") €"
    }

    private var loadingView: some View {
        VStack { Spacer(); ProgressView(); Spacer() }
            .frame(maxWidth: .infinity)
            .background(Color.maresmeBackground)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(Color.maresmeWarning)
            Text(message)
                .font(.maresmeBodySm)
                .foregroundStyle(Color.maresmeSubtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Reintentar") { Task { await vm.reload() } }
                .buttonStyle(.bordered)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.maresmeBackground)
    }
}

#Preview {
    NavigationStack {
        LeadDetailView(leadId: 1)
    }
}
