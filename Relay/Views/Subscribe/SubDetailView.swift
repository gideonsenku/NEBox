//
//  SubDetailView.swift
//  NEBox
//

import SwiftUI
import UIKit
import SDWebImageSwiftUI

struct SubDetailView: View {
    let sub: AppSubCache?

    @EnvironmentObject var boxModel: BoxJsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var items: [AppModel]
    @State private var selectedApp: AppModel?
    @State private var isNavigationActive: Bool = false

    init(sub: AppSubCache?) {
        self.sub = sub
        _items = State(initialValue: sub?.apps ?? [])
    }

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
                            let image = UIImage(systemName: isFav ? "star.slash" : "star.fill")
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
        .onDisappear {
            Task {
                await boxModel.flushPendingDataUpdates()
            }
        }
        .enableSwipeBack()
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

                    if let iconURL = sub.flatMap({ URL(string: $0.icon) }), !sub!.icon.isEmpty {
                        WebImage(url: iconURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.bgMuted
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                    }

                    Text(sub?.name ?? "")
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
