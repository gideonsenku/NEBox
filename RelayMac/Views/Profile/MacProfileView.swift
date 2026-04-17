//
//  MacProfileView.swift
//  RelayMac
//

import SDWebImageSwiftUI
import SwiftUI

struct MacProfileView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var apiManager: ApiManager
    @EnvironmentObject var toastManager: ToastManager

    @State private var nameDraft: String = ""
    @State private var showEditAvatar: Bool = false
    @State private var localAvatarRefreshToken: Int = 0

    var body: some View {
        Form {
            avatarSection
            identitySection
            statsSection
        }
        .formStyle(.grouped)
        .navigationTitle("个人资料")
        .onAppear {
            nameDraft = boxModel.boxData.usercfgs?.name ?? ""
        }
        .onChange(of: boxModel.boxData.usercfgs?.name) { _, newValue in
            nameDraft = newValue ?? ""
        }
    }

    // MARK: - Sections

    private var avatarSection: some View {
        Section("头像") {
            HStack(spacing: 16) {
                avatarImage
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    .id(localAvatarRefreshToken)

                VStack(alignment: .leading, spacing: 6) {
                    Text(boxModel.boxData.usercfgs?.name ?? "未设置昵称")
                        .font(.title3).bold()
                    Text(apiManager.apiUrl ?? "未配置服务器")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                Spacer()
                Button("编辑头像…") { showEditAvatar = true }
                    .popover(isPresented: $showEditAvatar, arrowEdge: .bottom) {
                        EditAvatarPopover(onLocalChanged: {
                            localAvatarRefreshToken &+= 1
                        })
                        .environmentObject(boxModel)
                        .environmentObject(toastManager)
                    }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let localImage = AvatarStorage.load() {
            Image(platformImage: localImage)
                .resizable()
                .scaledToFill()
        } else if let iconURL = boxModel.boxData.usercfgs?.icon, !iconURL.isEmpty,
                  let url = URL(string: iconURL) {
            WebImage(url: url).resizable().scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "person.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 32, weight: .medium))
            }
        }
    }

    private var identitySection: some View {
        Section("基础") {
            LabeledContent("昵称") {
                TextField("输入昵称", text: $nameDraft, onCommit: saveName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
            }
            Button("保存昵称", action: saveName)
                .disabled(nameDraft == (boxModel.boxData.usercfgs?.name ?? ""))
        }
    }

    private var statsSection: some View {
        Section("统计") {
            HStack(spacing: 14) {
                StatsCard(
                    title: "应用",
                    value: boxModel.boxData.apps.count,
                    systemImage: "app"
                )
                StatsCard(
                    title: "订阅",
                    value: boxModel.boxData.usercfgs?.appsubs.count ?? 0,
                    systemImage: "rectangle.stack"
                )
                StatsCard(
                    title: "会话",
                    value: boxModel.boxData.sessions.count,
                    systemImage: "clock"
                )
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Actions

    private func saveName() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              trimmed != (boxModel.boxData.usercfgs?.name ?? "") else { return }
        Task { @MainActor in
            let result = await boxModel.updateDataAsync(path: "usercfgs.name", data: trimmed)
            switch result {
            case .success:
                toastManager.showToast(message: "昵称已保存")
            case .failure(let err):
                toastManager.showToast(message: "保存失败：\(err.localizedDescription)")
            }
        }
    }
}
