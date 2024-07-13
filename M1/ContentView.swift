//
//  ContentView.swift
//  M1
//
//  Created by Nagayama Kazuki on 2024/06/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject var chatViewModel = ChatViewModel()
    var body: some View {
        if chatViewModel.isEnd {
            ResultView(chatViewModel: chatViewModel)
        } else if chatViewModel.inGame {
            GameView(chatViewModel: chatViewModel)
        } else {
            MenuView(matchManager: chatViewModel)
        }
    }
}

#Preview {
    ContentView()
}
