//
//  SubcribeView.swift
//  BoxJs
//
//  Created by Senku on 7/4/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct SubcribeView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @State private var refreshingIndex: Int? = nil

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView(urlString: boxModel.boxData.bgImgUrl)
                List {
                    let enumeratedSubs = Array(boxModel.boxData.displayAppSubs.enumerated())
                    ForEach(enumeratedSubs, id: \.element.id) { index, subApp in
                        VStack {
                            SubScribeCardView(item: subApp, isLoading: refreshingIndex == index)
                                .contextMenu {
                                    // Sort
                                    if index > 0 {
                                        Button {
                                            moveSub(from: index, by: -1)
                                        } label: {
                                            Label("上移", systemImage: "arrow.up")
                                        }
                                    }
                                    if index < enumeratedSubs.count - 1 {
                                        Button {
                                            moveSub(from: index, by: 1)
                                        } label: {
                                            Label("下移", systemImage: "arrow.down")
                                        }
                                    }

                                    Divider()

                                    // Actions
                                    Button {
                                        Task {
                                            refreshingIndex = index
                                            await boxModel.reloadAppSub(url: subApp.url ?? "")
                                            refreshingIndex = nil
                                        }
                                    } label: {
                                        Label("刷新", systemImage: "arrow.triangle.2.circlepath")
                                    }

                                    Button {
                                        openInSafari(for: subApp.repo)
                                    } label: {
                                        Label("仓库", systemImage: "safari")
                                    }

                                    Button {
                                        copyToClipboard(text: subApp.url ?? "")
                                        toastManager.showToast(message: "已复制链接")
                                    } label: {
                                        Label("复制", systemImage: "doc.on.doc")
                                    }

                                    Button {
                                        let shareUrl = "http://boxjs.com/#/sub/add/\(subApp.url?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                                        copyToClipboard(text: shareUrl)
                                        toastManager.showToast(message: "已复制分享链接")
                                    } label: {
                                        Label("分享", systemImage: "square.and.arrow.up")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        Task {
                                            await boxModel.deleteAppSub(url: subApp.url ?? "")
                                        }
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        Task {
                                            await boxModel.deleteAppSub(url: subApp.url ?? "")
                                        }
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }.tint(.red)

                                    Button {
                                        Task {
                                            refreshingIndex = index
                                            await boxModel.reloadAppSub(url: subApp.url ?? "")
                                            refreshingIndex = nil
                                        }
                                    } label: {
                                        Label("刷新", systemImage: "arrow.triangle.2.circlepath")
                                    }.tint(.green)

                                    Button {
                                        openInSafari(for: subApp.repo)
                                    } label: {
                                        Label("打开", systemImage: "safari")
                                    }.tint(.blue)
                                }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .padding(.horizontal, -4)
                    }
                }
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .refreshable {
                    await boxModel.reloadAppSub(url: "")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await boxModel.reloadAppSub(url: "")
                                toastManager.showToast(message: "已刷新全部订阅")
                            }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }

                        Button {
                            showTextFieldAlert(title: "添加订阅", message: nil, placeholder: "输入订阅地址", confirmButtonTitle: "确定", cancelButtonTitle: "取消") { inputText in
                                Task {
                                    await boxModel.addAppSub(url: inputText)
                                }
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .navigationTitle("应用订阅")
        }
    }

    private func moveSub(from index: Int, by offset: Int) {
        let subs = boxModel.boxData.appsubs
        var urls = subs.map { $0.url }
        let toIndex = index + offset
        guard toIndex >= 0 && toIndex < urls.count else { return }
        urls.swapAt(index, toIndex)
        // Rebuild appsubs array with new order
        let reordered = urls.compactMap { url in subs.first { $0.url == url } }
        let reorderedData = reordered.map { ["url": $0.url, "enable": $0.enable, "id": $0.id ?? ""] as [String : Any] }
        boxModel.updateData(path: "usercfgs.appsubs", data: reorderedData)
    }
}

#Preview {
    SubcribeView()
}
