//
//  SettingView.swift
//  BoxJs
//
//  Created by Senku on 7/5/24.
//

import SwiftUI

struct SettingView: View {
    @State var showAni = false
    @State var isPlaying = false
    var body: some View {
        VStack {
            Button(action: {
                withAnimation(.smooth) {
                    showAni.toggle()
                }
            }) {
                Image(systemName: "wind")
                    .imageScale(.large)
                    .rotationEffect(.degrees(showAni ? 90: 0))
                    .scaleEffect(5)
                    .padding()
        }
        
        
        Divider().padding()
        
        Button {
            withAnimation {
                isPlaying.toggle()
            }
        } label: {
            if isPlaying {
                Image(systemName: "play.fill")
                    .imageScale(.large)
                    .padding()
            } else {
                Image(systemName: "pause.fill")
                    .imageScale(.large)
                    .padding()
            }
        }
        }
    }
}

#Preview {
    SettingView()
}
