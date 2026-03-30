import SwiftUI
import SDWebImageSwiftUI

// MARK: - Model

private struct GitHubContributor: Decodable, Identifiable {
    let id: Int
    let login: String
    let avatarUrl: String
    let htmlUrl: String

    enum CodingKeys: String, CodingKey {
        case id, login
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
    }
}

// MARK: - View

struct AcknowledgementsView: View {
    @State private var collaborators: [GitHubContributor] = []
    @State private var contributors: [GitHubContributor] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private static let collaboratorIDs: Set<Int> = [
        29748519, 39037656, 9592236, 1210282, 65508083, 23498579
    ]

    private static let excludedIDs: Set<Int> = [49699333]

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
                    Button("重试") { loadContributors() }
                        .font(.system(size: 14, weight: .medium))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !collaborators.isEmpty {
                            ContributorSection(title: "核心开发者", contributors: collaborators)
                        }
                        if !contributors.isEmpty {
                            ContributorSection(title: "贡献者", contributors: contributors)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("致谢")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard collaborators.isEmpty && contributors.isEmpty else { return }
            loadContributors()
        }
    }

    private func loadContributors() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let url = URL(string: "https://api.github.com/repos/chavyleung/scripts/contributors")!
                let (data, response) = try await URLSession.shared.data(from: url)
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                let all = try JSONDecoder().decode([GitHubContributor].self, from: data)
                    .filter { !Self.excludedIDs.contains($0.id) }
                let fetchedCollaborators = all.filter { Self.collaboratorIDs.contains($0.id) }
                let fetchedContributors = all.filter { !Self.collaboratorIDs.contains($0.id) }
                await MainActor.run {
                    collaborators = fetchedCollaborators
                    contributors = fetchedContributors
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

// MARK: - Contributor Section

private struct ContributorSection: View {
    let title: String
    let contributors: [GitHubContributor]

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: 16)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(contributors) { contributor in
                    if let url = URL(string: contributor.htmlUrl) {
                        Link(destination: url) {
                            ContributorAvatar(contributor: contributor)
                        }
                    } else {
                        ContributorAvatar(contributor: contributor)
                    }
                }
            }
        }
    }
}

// MARK: - Contributor Avatar

private struct ContributorAvatar: View {
    let contributor: GitHubContributor

    var body: some View {
        VStack(spacing: 6) {
            WebImage(url: URL(string: contributor.avatarUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())

            Text(contributor.login)
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
                .lineLimit(1)
        }
    }
}
