import SwiftUI

struct MenuView: View {
    @ObservedObject var matchManager: ChatViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            Image("logo3")
                .resizable()
                .scaledToFit()
                .padding(20)
            Image("subLogo")
                .resizable()
                .scaledToFit()
            
            Spacer()
            
            Button {
                matchManager.startSession()
            } label: {
                Text("PLAY")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 100)
            .background(
                Capsule(style: .circular)
            )
            .disabled(matchManager.isConnected || matchManager.isConnecting)
            if matchManager.isConnecting {
                Text("Connecting...")
                    .padding()
            } else {
                Text("　")
                    .padding()
            }
            if matchManager.isConnected {
                Text("Connected!!!")
                    .padding()
            }
            
            Spacer()
        }
        .background(
            Image("menuBg")
                .resizable()
                .scaledToFill()
                .scaleEffect(1.1)
        )
        .ignoresSafeArea()
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView(matchManager: ChatViewModel())
    }
}
