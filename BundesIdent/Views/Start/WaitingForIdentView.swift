import SwiftUI
import ComposableArchitecture

struct WaitingForIdentView: View {
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.blue900))
                    .scaleEffect(3)
                    .frame(maxWidth: .infinity)
                    .padding(50)
                Text("Starten Sie Ihre Identifizierung im Browser.")
                    .headingL(color: .black)
                    .multilineTextAlignment(.center)
                Spacer()
                Text("Anschließend werden Sie zurück in die App geleitet und durch den Online-Ausweis Prozess geführt.")
                    .bodyMRegular(color: .neutral900)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 80)
            }
        }
    }
}

struct WaitingForIdentView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingForIdentView()
    }
}
