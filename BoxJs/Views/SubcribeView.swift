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
                if let url = URL(string: boxModel.boxData.bgImgUrl) {
                    BackgroundView(imageUrl: url)
                        .edgesIgnoringSafeArea(.all)
                }
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
                        
                    }
                }
                .background(Color.clear)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("应用订阅")
        }
        .onAppear {
            DispatchQueue.main.async {
                boxModel.fetchData()
            }
        }
    }
    
}

struct SubcribeCard: View {
    var body: some View {
        Text("Hello, World!").likeButtonStyle()
    }
}

struct LikeBtnModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

extension Text {
    func likeButtonStyle() -> some View {
        modifier(LikeBtnModifier())
    }
}

#Preview {
    SubcribeView()
}
