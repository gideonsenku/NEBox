//
//  MacSubscribeListView.swift
//  RelayMac
//

import SDWebImageSwiftUI
import SwiftUI

struct MacSubscribeListView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var chrome: WindowChromeModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var subscriptions: [AppSub] = []
    @State private var isEditing: Bool = false
    @State private var showAddDialog: Bool = false
    @State private var draftURL: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    ContentUnavailableView(
                        "暂无订阅源",
                        systemImage: "rectangle.stack",
                        description: Text("添加订阅源后会显示在这里")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(subscriptions.enumerated()), id: \.element.url) { pair in
                                let index = pair.offset
                                let sub = pair.element
                                if let summary = summary(for: sub) {
                                    if let url = summary.url, !url.isEmpty, !isEditing {
                                        NavigationLink(value: MacRoute.subscription(url: url)) {
                                            SubscribeRow(sub: summary)
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button("刷新") { reloadSubscription(url) }
                                            Button("删除", role: .destructive) { deleteSubscription(url) }
                                        }
                                    } else {
                                        SubscribeRow(sub: summary)
                                            .foregroundStyle(sub.enable ? .primary : .secondary)
                                    }

                                    if index < subscriptions.count - 1 {
                                        Divider()
                                            .padding(.leading, 48)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationDestination(for: MacRoute.self) { route in
                MacRouteDestination(route: route)
            }
            .onAppear {
                subscriptions = boxModel.boxData.usercfgs?.appsubs ?? []
                updateChrome()
            }
            .onReceive(boxModel.$boxData) { data in
                guard !isEditing else { return }
                subscriptions = data.usercfgs?.appsubs ?? []
                updateChrome()
            }
            .onChange(of: isEditing) { _, _ in updateChrome() }
            .alert("添加订阅", isPresented: $showAddDialog) {
                TextField("https://example.com/boxjs.json", text: $draftURL)
                Button("取消", role: .cancel) {}
                Button("添加") { addSubscription() }
            } message: {
                Text("请输入订阅链接地址")
            }
        }
    }

    private func summary(for sub: AppSub) -> AppSubSummary? {
        boxModel.boxData.displayAppSubSummaries.first(where: { $0.url == sub.url })
    }

    private func moveSubscriptions(from source: IndexSet, to destination: Int) {
        subscriptions.move(fromOffsets: source, toOffset: destination)
        persistSubscriptions(message: "订阅顺序已更新")
    }

    private func deleteSubscriptions(at offsets: IndexSet) {
        let urls = offsets.map { subscriptions[$0].url }
        subscriptions.remove(atOffsets: offsets)
        boxModel.updateData(path: "usercfgs.appsubs", data: subscriptions)
        for url in urls {
            Task { await boxModel.deleteAppSub(url: url) }
        }
        toastManager.showToast(message: "已删除订阅")
    }

    private func deleteSubscription(_ url: String) {
        subscriptions.removeAll { $0.url == url }
        boxModel.updateData(path: "usercfgs.appsubs", data: subscriptions)
        Task { await boxModel.deleteAppSub(url: url) }
        toastManager.showToast(message: "已删除订阅")
    }

    private func persistSubscriptions(message: String) {
        boxModel.updateData(path: "usercfgs.appsubs", data: subscriptions)
        toastManager.showToast(message: message)
        Task { await boxModel.flushPendingDataUpdates() }
    }

    private func addSubscription() {
        let url = draftURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return }
        Task {
            await boxModel.addAppSub(url: url)
            await MainActor.run {
                toastManager.showToast(message: "订阅已添加")
            }
        }
    }

    private func reloadAll() {
        Task {
            await boxModel.reloadAllAppSub()
            await MainActor.run {
                toastManager.showToast(message: "已刷新全部订阅")
            }
        }
    }

    private func reloadSubscription(_ url: String) {
        Task {
            await boxModel.reloadAppSub(url: url)
            await MainActor.run {
                toastManager.showToast(message: "订阅已刷新")
            }
        }
    }

    private func updateChrome() {
        var actions: [WindowChromeAction] = [
            WindowChromeAction(
                title: "刷新全部",
                systemImage: "arrow.triangle.2.circlepath",
                kind: .button(action: reloadAll)
            ),
            WindowChromeAction(
                title: "添加订阅",
                systemImage: "plus",
                isPrimary: true,
                kind: .button(action: {
                    draftURL = ""
                    showAddDialog = true
                })
            )
        ]

        if !subscriptions.isEmpty {
            actions.append(
                WindowChromeAction(
                    title: isEditing ? "完成" : "编辑",
                    systemImage: isEditing ? "checkmark" : "slider.horizontal.3",
                    kind: .button(action: { isEditing.toggle() })
                )
            )
        }

        chrome.setActions(actions)
    }
}

private struct SubscribeRow: View {
    let sub: AppSubSummary

    var body: some View {
        HStack(spacing: 12) {
            icon
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(sub.name).font(.body).lineLimit(1)
                Text("\(sub.appCount) 应用")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var icon: some View {
        if let url = URL(string: sub.icon), !sub.icon.isEmpty {
            WebImage(url: url).resizable().scaledToFit()
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
        }
    }
}
