//
//  AppView.swift
//  BoxJs
//
//  Created by Senku on 7/4/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Foundation


struct SubAppView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel

    var item: AppModel
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(item.name)")
                            .font(.system(size: 16))
                        Spacer()
                    }
                    
                    Text(AttributedString("\(item.repo ?? "")"))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(AttributedString("\(item.author)"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if let isFav = item.isFav, isFav == true {
                    Image(systemName: "star.fill")
                        .foregroundColor(.accentColor)
                        .onTapGesture {
                            let updateIds = boxModel.favApps.map { $0.id }.filter { $0 != item.id }
                            boxModel.updateData(path: "usercfgs.favapps", data: updateIds)
                        }
                } else {
                    Image(systemName: "star")
                        .foregroundColor(.gray)
                        .onTapGesture {
                            var updateIds = boxModel.favApps.map { $0.id }
                            updateIds.append(item.id)
                            boxModel.updateData(path: "usercfgs.favapps", data: updateIds)
                        }

                }
            }
        }
        .background(
            BackgroundView(imageUrl: URL(string: boxModel.boxData.bgImgUrl))
        )
    }
}


struct CustomDisclosureGroup: View {
    @State private var isExpanded: Bool = false
    var title: String
    var items: [AppModel]
    var icon: String?
    var sysIcon: String?
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                Divider()
                    .padding(.vertical, 5)
                ScrollView {
                    ForEach(items) { item in
                        SubAppView(item: item)
                    }
                }
                .frame(maxHeight: 300)
            },
            label: {
                HStack {
                    if let icon {
                        WebImage(url: URL(string: icon)) { image in
                            image.resizable()
                        } placeholder: {
                            Rectangle().foregroundColor(.gray)
                        }
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else if let sysIcon {
                        Image(systemName: sysIcon)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .foregroundColor(.red)
                    }
                    
                    Text("\(title)(\(items.count))")
                        .font(Font.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
        )
        .padding()
        .foregroundColor(.black)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct AppView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView() {
                    if !boxModel.favApps.isEmpty {
                        CustomDisclosureGroup(title: "收藏应用", items: boxModel.favApps, sysIcon: "star.circle.fill")
                    }
                    if boxModel.boxData.displayAppSubs.count != 0 {
                        ForEach(boxModel.boxData.displayAppSubs) { group in
                            CustomDisclosureGroup(
                                title: group.name,
                                items: group.apps,
                                icon: group.icon
                            )
                        }
                    }
                    if !boxModel.boxData.displaySysApps.isEmpty {
                        CustomDisclosureGroup(title: "系统应用", items: boxModel.boxData.displaySysApps, sysIcon: "gearshape.circle.fill")
                    }
                }
            }
            .background(
                BackgroundView(imageUrl: URL(string: boxModel.boxData.bgImgUrl))
            )
            .navigationBarTitle("应用列表")
        }
        .onAppear {
            DispatchQueue.main.async {
                boxModel.fetchData()
            }
        }
    }
}

#Preview {
    AppView()
}
