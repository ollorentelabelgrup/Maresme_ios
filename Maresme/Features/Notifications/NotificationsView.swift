import SwiftUI

// MARK: - Main view

struct NotificationsView: View {
    @Environment(NotificationStore.self)     private var notificationStore
    @Environment(NavigationCoordinator.self) private var coordinator
    @State private var viewModel: NotificationsViewModel?
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel?.isLoading == true && viewModel?.notifications.isEmpty == true {
                    LoadingView(message: "Cargando actividad...")
                } else if let vm = viewModel {
                    if vm.notifications.isEmpty && !vm.isLoading {
                        emptyState
                    } else {
                        notificationList(vm)
                    }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Actividad")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.maresmeBackground)
            .toolbar {
                if viewModel?.notifications.contains(where: { !$0.isRead }) == true {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Marcar todas") {
                            Task { await viewModel?.markAllRead() }
                        }
                        .font(.maresmeBodySm)
                    }
                }
            }
            .navigationDestination(for: Int.self) { notifId in
                if let vm = viewModel,
                   let notification = vm.notifications.first(where: { $0.id == notifId }) {
                    NotificationDetailView(notification: notification, viewModel: vm)
                }
            }
            .navigationDestination(for: String.self) { slug in
                PropertyDetailView(slug: slug)
            }
        }
        .onChange(of: coordinator.pendingNotificationId) { _, notifId in
            if let notifId {
                path.append(notifId)
                coordinator.pendingNotificationId = nil
            }
        }
        .task {
            if viewModel == nil {
                viewModel = NotificationsViewModel(store: notificationStore)
            }
            await viewModel?.loadIfNeeded()
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        EmptyStateView(
            icon:    "bell.slash",
            title:   "Sin actividad",
            message: "Aquí verás las notificaciones de tus alertas y recomendaciones."
        )
    }

    // MARK: - List

    private func notificationList(_ vm: NotificationsViewModel) -> some View {
        List {
            ForEach(vm.notifications) { notification in
                NavigationLink(value: notification.id) {
                    NotificationRowView(notification: notification)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.maresmeBackground)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        Task { await viewModel?.delete(id: notification.id) }
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    if !notification.isRead {
                        Button {
                            Task { await viewModel?.markRead(id: notification.id) }
                        } label: {
                            Label("Leída", systemImage: "checkmark.circle")
                        }
                        .tint(Color.maresmeSuccess)
                    }
                }
                .onAppear {
                    if notification.id == vm.notifications.last?.id {
                        Task { await viewModel?.loadMore() }
                    }
                }
            }

            if vm.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.maresmeBackground)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .background(Color.maresmeBackground)
        .refreshable { await viewModel?.refresh() }
    }
}

// MARK: - Notification row

private struct NotificationRowView: View {
    let notification: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            notifIcon
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(notification.isRead ? .maresmeBodySm : .maresmeLabel)
                        .foregroundStyle(Color.maresmeText)
                        .lineLimit(1)
                    Spacer()
                    if let date = notification.createdAt {
                        Text(date, style: .relative)
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeDisabled)
                    }
                }
                Text(notification.message)
                    .font(.maresmeBodySm)
                    .foregroundStyle(Color.maresmeSubtext)
                    .lineLimit(2)
            }
            if !notification.isRead {
                Circle()
                    .fill(Color.maresmeBlue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(12)
        .background(notification.isRead ? Color.maresmeSurface : Color.maresmeBlue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var notifIcon: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.12))
                .frame(width: 40, height: 40)
            Image(systemName: notification.sfSymbol)
                .font(.system(size: 16))
                .foregroundStyle(iconColor)
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case "recommendation":             return Color.maresmeBlue
        case "alert_match", "price_drop": return Color.maresmeSuccess
        case "alert_activated":            return Color.maresmeGold
        default:                           return Color.maresmeSubtext
        }
    }
}

// MARK: - Notification detail

struct NotificationDetailView: View {
    let notification: AppNotification
    let viewModel:    NotificationsViewModel
    @Environment(AlertStore.self)    private var alertStore
    @Environment(FavoriteStore.self) private var favoriteStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                messageCard
                actionSection
            }
            .padding(20)
            .padding(.bottom, 32)
        }
        .navigationTitle(notification.typeLabel)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.maresmeBackground)
        .task { await viewModel.markRead(id: notification.id) }
    }

    // MARK: - Header card

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: notification.sfSymbol)
                    .font(.system(size: 22))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(notification.title)
                    .font(.maresmeTitle3)
                    .foregroundStyle(Color.maresmeText)
                HStack(spacing: 6) {
                    Text(notification.typeLabel)
                        .font(.maresmeLabelSm)
                        .foregroundStyle(iconColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(iconColor.opacity(0.10))
                        .clipShape(Capsule())
                    if let date = notification.createdAt {
                        Text(date, style: .date)
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color.maresmeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Message card

    private var messageCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mensaje")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeSubtext)
            Text(notification.message)
                .font(.maresmeBody)
                .foregroundStyle(Color.maresmeText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.maresmeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Action section (deep link)

    @ViewBuilder
    private var actionSection: some View {
        if let meta = notification.metadata,
           let actionType = meta.actionType,
           let target = meta.actionTarget {
            actionButton(actionType: actionType, target: target)
        }
    }

    @ViewBuilder
    private func actionButton(actionType: String, target: String) -> some View {
        switch actionType {
        case "property", "recommendation", "price_drop":
            let slug = notification.metadata?.propertySlug ?? target
            NavigationLink(value: slug) {
                Label("Ver propiedad", systemImage: "house.fill")
                    .font(.maresmeLabel)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.maresmeBlue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        case "alert_match", "alert_activated", "alert_paused":
            if let alertId = Int(target),
               let alert = alertStore.alerts.first(where: { $0.id == alertId }) {
                NavigationLink(destination: AlertDetailView(alert: alert)) {
                    Label("Ver alerta", systemImage: "bell.fill")
                        .font(.maresmeLabel)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.maresmeBlue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "bell")
                        .foregroundStyle(Color.maresmeSubtext)
                    Text("Ve a la pestaña Alertas para ver más detalles.")
                        .font(.maresmeBodySm)
                        .foregroundStyle(Color.maresmeSubtext)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.maresmeSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        default:
            EmptyView()
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case "recommendation":             return Color.maresmeBlue
        case "alert_match", "price_drop": return Color.maresmeSuccess
        case "alert_activated":            return Color.maresmeGold
        default:                           return Color.maresmeSubtext
        }
    }
}

// MARK: - Previews

#Preview("NotificationsView") {
    NotificationsView()
        .environment(NotificationStore())
        .environment(AlertStore())
        .environment(FavoriteStore())
        .environment(NavigationCoordinator())
}

#Preview("NotificationDetailView") {
    NavigationStack {
        NotificationDetailView(
            notification: PreviewData.notification,
            viewModel:    NotificationsViewModel(store: NotificationStore())
        )
    }
    .environment(AlertStore())
    .environment(FavoriteStore())
}
