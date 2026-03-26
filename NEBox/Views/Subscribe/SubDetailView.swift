//
//  SubDetailView.swift
//  NEBox
//

import SwiftUI
import SDWebImageSwiftUI

struct SubDetailView: View {
    let sub: AppSubCache?

    @EnvironmentObject var boxModel: BoxJsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var items: [AppModel]

    init(sub: AppSubCache?) {
        self.sub = sub
        _items = State(initialValue: sub?.apps ?? [])
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Same gradient as HomeView
            LinearGradient(
                colors: [Color(hex: "#EEF0FA"), Color(hex: "#F0EDF8"), Color(hex: "#F5F0F8")],
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
                            .foregroundColor(Color(hex: "#5A6177").opacity(0.4))
                        Text("该订阅暂无应用")
                            .foregroundColor(Color(hex: "#5A6177").opacity(0.7))
                        Spacer()
                    }
                } else {
                    CollectionViewWrapper(
                        items: $items,
                        boxModel: boxModel,
                        selectedApp: .constant(nil),
                        isNavigationActive: .constant(false),
                        isEditMode: .constant(false),
                        bottomInset: adaptiveBottomInset(),
                        allowsEdit: false,
                        tapOverride: { app in
                            Task { @MainActor in
                                let favIds = boxModel.boxData.usercfgs?.favapps ?? []
                                if favIds.contains(app.id) {
                                    boxModel.updateData(path: "usercfgs.favapps", data: favIds.filter { $0 != app.id })
                                } else {
                                    boxModel.updateData(path: "usercfgs.favapps", data: favIds + [app.id])
                                }
                            }
                        },
                        favAppIds: Set(boxModel.favApps.map { $0.id })
                    )
                    .ignoresSafeArea(edges: .bottom)
                }
            }

            // Nav bar on top
            VStack {
                navBar
                    .background(Color(hex: "#EEF0FA").ignoresSafeArea())
                Spacer()
            }

        }
        .toolbar(.hidden, for: .navigationBar)
        .background(Color(hex: "#F5F0F8").ignoresSafeArea(edges: .bottom))
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
                        .foregroundColor(Color(hex: "#002FA7"))

                    if let iconURL = sub.flatMap({ URL(string: $0.icon) }), !sub!.icon.isEmpty {
                        WebImage(url: iconURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color(hex: "#ECEEF4")
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                    }

                    Text(sub?.name ?? "")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#1A1918"))
                        .lineLimit(1)
                }
            }

            Spacer()

            // App count badge
            Text("\(items.count) 个应用")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#9098AD"))
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
    }
}
