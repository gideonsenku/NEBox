import SwiftUI

struct VersionHistoryView: View {
    @State private var versions: [VersionInfo] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Button("重试") { loadVersions() }
                        .font(.system(size: 14, weight: .medium))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if versions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("暂无版本信息")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(versions) { ver in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Text("v\(ver.version)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(ver.version == currentVersion ? .accentColor : .primary)
                                    if ver.version == currentVersion {
                                        Text("当前版本")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.accentColor)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                                ForEach(ver.notes, id: \.name) { note in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(note.name)
                                            .font(.system(size: 14, weight: .semibold))
                                        ForEach(note.descs, id: \.self) { desc in
                                            HStack(alignment: .top, spacing: 6) {
                                                Text("\u{2022}")
                                                    .font(.system(size: 12))
                                                Text(desc)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.leading, 12)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("BoxJs更新日志")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadVersions() }
    }

    private func loadVersions() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let resp: VersionsResp = try await NetworkProvider.request(.getVersions)
                await MainActor.run {
                    versions = resp.releases ?? []
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "加载失败: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
