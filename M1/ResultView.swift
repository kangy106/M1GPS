//
//  ResultView.swift
//  M1
//
//  Created by Nagayama Kazuki on 2024/07/05.
//

import SwiftUI

struct ResultView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    var body: some View {
        VStack {
            Spacer()
            if (chatViewModel.my_point > chatViewModel.opponent_point) {
                Image("youWin")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 70)
                    .padding(.vertical)
            }
            else if (chatViewModel.my_point == chatViewModel.opponent_point) {
                Image("draw")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 70)
                    .padding(.vertical)
            } else {
                Image("youLose")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 70)
                    .padding(.vertical)
            }
            
            Text("自分のスコア: \(chatViewModel.my_point)")
                .font(.largeTitle)
                .bold()
                .foregroundColor(Color("primaryYellow"))
                .padding()
            Text("相手のスコア: \(chatViewModel.opponent_point)")
                .font(.largeTitle)
                .bold()
                .foregroundColor(Color("primaryYellow"))
            
            Spacer()
            
            Button {
                chatViewModel.endSession()
            } label: {
                Text("Menu")
                    .foregroundColor(Color("menuBtn"))
                    .brightness(-0.4)
                    .font(.largeTitle)
                    .bold()
            }
            .padding()
            .padding(.horizontal, 50)
            .background(
                Capsule(style: .circular)
                    .fill(Color("menuBtn"))
            )
            
            Spacer()
        }
        .background(
            Image("gameOverBg")
                .resizable()
                .scaledToFill()
                .scaleEffect(1.1)
        )
        .ignoresSafeArea()
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        ResultView(chatViewModel: ChatViewModel())
    }
}
