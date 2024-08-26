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
            .navigationTitle("应用订阅")
        }
        .onAppear {
            DispatchQueue.main.async {
                boxModel.fetchData()
            }
        }
    }
    
}

#Preview {
    SubcribeView()
}
