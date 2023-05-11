import SwiftUI
import ComposableArchitecture

struct LoadingDots: View {
    
    @State var counter = 0
    @State var isRunningDotOne = 2
    @State var isRunningDotTwo = 2
    @State var isRunningDotThree = 2
    
    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
        
    
    private func bouncingDot(isRunning: Int) -> some View {
        Circle()
            .frame(width: 20, height: 20)
            .foregroundColor(isRunning == 2 ? .blue200 : .blue800)
            .offset(y: isRunning == 0 ? 0 : 40)
            .animation(
                .easeInOut(duration: 1)
                .repeatCount(1, autoreverses: true),
                value: isRunning
            )
    }
    
    var body: some View {
        HStack {
            bouncingDot(isRunning: isRunningDotOne)
            bouncingDot(isRunning: isRunningDotTwo)
            bouncingDot(isRunning: isRunningDotThree)
        }
        .onReceive(timer) { _ in
            if (counter >= 6) {
                counter = 0
            }
            
            if (counter == 0) {
                isRunningDotThree = 2
                isRunningDotOne = 0
            } else if (counter == 1) {
                isRunningDotOne = 1
            } else if (counter == 2) {
                isRunningDotOne =  2
                isRunningDotTwo = 0
            } else if (counter == 3) {
                isRunningDotTwo = 1
            } else if (counter == 4) {
                isRunningDotTwo = 2
                isRunningDotThree = 0
            } else if (counter == 5) {
                isRunningDotThree = 1
            }
            
            counter += 1
        }
    }
}

struct WaitingForIdentView: View {
    
    
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                LoadingDots()
                    .padding(.bottom, 80)
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
