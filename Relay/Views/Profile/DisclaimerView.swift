import SwiftUI

struct DisclaimerView: View {
    private let sections: [(icon: String, title: String, content: String)] = [
        (
            "info.circle",
            "项目性质",
            "Relay 是一款开源的 BoxJS 客户端工具，仅用于管理和配置 BoxJS 脚本。本应用不提供、不托管、不分发任何脚本内容，也不对任何第三方脚本的功能或行为负责。"
        ),
        (
            "hand.raised",
            "使用责任",
            "用户应自行判断所使用脚本的合法性与安全性，因使用本应用或相关脚本所造成的任何直接或间接后果，均由用户自行承担。"
        ),
        (
            "network",
            "网络访问",
            "本应用需要连接用户自行部署的 BoxJS 服务地址（本地 HTTP），不会收集、上传或共享任何用户数据。所有数据仅在用户设备与本地服务之间传输。"
        ),
        (
            "doc.text",
            "知识产权",
            "BoxJS 及其相关脚本的版权归原作者所有。Relay 作为客户端工具，尊重并不侵犯任何第三方的知识产权。如有侵权请联系我们处理。"
        ),
        (
            "arrow.triangle.2.circlepath",
            "条款变更",
            "本免责声明可能随版本更新而修改，继续使用即表示您同意最新版本的条款内容。"
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    disclaimerSection(icon: section.icon, title: section.title, content: section.content)
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: Color.pageGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("免责声明")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func disclaimerSection(icon: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.accent)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }

            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
