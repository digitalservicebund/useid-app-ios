import SwiftUI
import ComposableArchitecture

struct WaitingForIdentView: View {
    
    var body: some View {
        NavigationView {
            VStack {
                Text(" o  o  o  o")
                    .bodyLBold(color: .blue800)
                    .padding(.bottom, 10)
                Text("Auf Identifikation warten")
                    .bodyLBold(color: .blue800)
            }
        }
    }
}

struct WaitingForIdentView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingForIdentView()
    }
}
