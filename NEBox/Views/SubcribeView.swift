//
//  SubcribeView.swift
//  BoxJs
//
//  Created by Senku on 7/4/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct SubcribeView: View {
    @StateObject var boxModel = BoxJsViewModel()
    @State private var refreshingIndex: Int? = nil
    @State private var isShowingSheet = false
    @State private var subUrl = ""
    
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    let enumeratedSubs = Array(boxModel.boxData.displayAppSubs.enumerated())
                    ForEach(enumeratedSubs, id: \.element.id) { index, subApp in
                        VStack {
                            SubScribeCardView(item: subApp, isLoading: refreshingIndex == index)
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
            }
            .background(
                BackgroundView(imageUrl: URL(string: boxModel.boxData.bgImgUrl))
            )
            .toolbar {
                ToolbarItem {
                    Button {
                        showTextFieldAlert(title: "添加订阅", message: nil, placeholder: "输入订阅地址", confirmButtonTitle: "确定", cancelButtonTitle: "取消") { inputText in
                            Task {
                                await boxModel.addAppSub(url: inputText)
                            }
                        }
                    } label: {
                        Label("Add Account", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("应用订阅")
        }
    }
    
}

#Preview {
    SubcribeView()
}
