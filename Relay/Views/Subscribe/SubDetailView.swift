//
//  SubDetailView.swift
//  NEBox

import SwiftUI
import UIKit
import SDWebImageSwiftUI

struct SubDetailView: View {
    let subURL: String?

    @EnvironmentObject var boxModel: BoxJsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var items: [AppModel] = []
    @State private var selectedApp: AppModel?
    @State private var isNavigationActive: Bool = false

    /// Derived from boxData on appear / change — only the header fields, no apps array.
    @State private var subName: String = ""
    @State private var subIcon: String = ""

    var body: some View {
        ZStack(alignment: .top) {
            // Same gradient as HomeView
            LinearGradient(
                colors: Color.pageGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Color.clear.frame(height: 56)

                if items.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 48))
                            .foregroundColor(.textSecondary.opacity(0.4))
                        Text("该订阅暂无应用")
                            .foregroundColor(.textSecondary.opacity(0.7))
                        Spacer()
                    }
                } else {
                    CollectionViewWrapper(
                        items: $items,
                        boxModel: boxModel,
                        selectedApp: $selectedApp,
                        isNavigationActive: $isNavigationActive,
                        isEditMode: .constant(false),
                        bottomInset: adaptiveBottomInset(),
                        allowsEdit: false,
                        favAppIds: Set(boxModel.favApps.map { $0.id }),
                        contextMenuProvider: { app in
                            let favIds = boxModel.boxData.usercfgs?.favapps ?? []
                            let isFav = favIds.contains(app.id)
                            let title = isFav ? "取消收藏" : "加入收藏"
                            let image = UIImage(systemName: isFav ? "heart.slash" : "heart.fill")
                            return UIMenu(children: [
                                UIAction(title: title, image: image) { _ in
                                    Task { @MainActor in
                                        let ids = boxModel.boxData.usercfgs?.favapps ?? []
                                        if ids.contains(app.id) {
                                            boxModel.updateData(path: "usercfgs.favapps", data: ids.filter { $0 != app.id })
                                        } else {
                                            boxModel.updateData(path: "usercfgs.favapps", data: ids + [app.id])
                                        }
                                    }
                                },
                            ])
                        }
                    )
                    .ignoresSafeArea(edges: .bottom)
                }
            }

            // Nav bar on top
            VStack {
                navBar
                    .background(Color.gradientTop.ignoresSafeArea())
                Spacer()
            }
        }
        .neboxHiddenNavigationBar()
        .background(Color.gradientBottom.ignoresSafeArea(edges: .bottom))
        .neboxNavigationDestination(isPresented: $isNavigationActive) {
            AppDetailView(app: selectedApp)
        }
        .onAppear { loadSubDetail() }
        .onDisappear {
            Task {
                await boxModel.flushPendingDataUpdates()
            }
        }
        .enableSwipeBack()
    }

    private func loadSubDetail() {
        guard let url = subURL,
              let detail = boxModel.boxData.displayAppSubDetail(for: url) else { return }
        subName = detail.name
        subIcon = detail.icon
        items = detail.apps
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: 0) {
            // Back button + subscription avatar + name
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accent)

                    if !subIcon.isEmpty, let iconURL = URL(string: subIcon) {
                        WebImage(url: iconURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Text(String(subName.prefix(1)))
                                .font(.system(size: 28 * 0.42, weight: .semibold, design: .rounded))
                                .foregroundColor(.textSecondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.bgMuted)
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                    } else if !subName.isEmpty {
                        Text(String(subName.prefix(1)))
                            .font(.system(size: 28 * 0.42, weight: .semibold, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Color.bgMuted, in: Circle())
                    }

                    Text(subName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // App count badge
            Text("\(items.count) 个应用")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textTertiary)
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
    }
}
