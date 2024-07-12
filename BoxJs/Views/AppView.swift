//
//  AppView.swift
//  BoxJs
//
//  Created by Senku on 7/4/24.
//

import SwiftUI

struct AppView: View {
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("每日目标")) {
                    Text("Row 1")
                    Text("Row 2")
                    Text("Row 3")
                }
                Section(header: Text("Section 2")) {
                    Text("Row 1")
                    Text("Row 2")
                    Text("Row 3")
                }
            }
            .navigationBarTitle("AppView")
        }
    }
}

#Preview {
    AppView()
}
