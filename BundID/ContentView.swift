//
//  ContentView.swift
//  BundID
//
//  Created by Fabio Tacke on 20.04.22.
//

import SwiftUI
import Combine
import OpenEcard

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewViewModel()
    
    var body: some View {
        Button {
            viewModel.identify()
        } label: {
            Text("Identify")
        }
        Button {
            viewModel.changePIN()
        } label: {
            Text("Change PIN")
        }
    }
}

class ContentViewViewModel: ObservableObject {
    let nfcManager = IDInteractionManager()
    @Published var testValue = ""
    
    var cancellable: AnyCancellable? = nil
    
    func identify() {
        let tokenURL = "http://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Ftest.governikus-eid.de%2FAutent-DemoApplication%2FRequestServlet%3Fprovider%3Ddemo_epa_20%26redirect%3Dtrue"
        
        cancellable = nfcManager.identify(tokenURL: tokenURL).sink { completion in
            switch completion {
            case .finished: print("Publisher finished.")
            case .failure(let error): print("Publisher failed with error: \(error)")
            }
        } receiveValue: { value in
            switch value {
            case .requestCardInsertion(let messageCallback):
                print("Request card insertion.")
                messageCallback("Request card insertion.")
            case .cardInteractionComplete: print("Card interaction complete.")
            case .cardRecognized: print("Card recognized.")
            case .cardRemoved: print("Card removed.")
            case .requestCAN(let canCallback): print("CAN callback not implemented.")
            case .requestPIN(let attempts, let pinCallback):
                print("Entering PIN with \(attempts ?? 3) remaining attempts.")
                pinCallback("123456")
            case .requestPINAndCAN(let pinCANCallback): print("PIN CAN callback not implemented.")
            case .requestPUK(let pukCallback): print("PUK callback not implemented.")
            case .processCompletedSuccessfully: print("Process completed successfully.")
            
            case .authenticationStarted: print("Authentication started.")
            case .requestAuthenticationRequestConfirmation(let request, let confirmationCallback):
                print("Confirm request.")
                confirmationCallback([:])
            case .authenticationSuccessful: print("Authentication successful.")
                
            default: print("Received unexpected event.")
            }
        }
    }
    
    func changePIN() {
        cancellable = nfcManager.changePIN().sink { completion in
            switch completion {
            case .finished: print("Publisher finished.")
            case .failure(let error): print("Publisher failed with error: \(error)")
            }
        } receiveValue: { value in
            switch value {
            case .requestCardInsertion(let messageCallback):
                print("Request card insertion.")
                messageCallback("Request card insertion.")
            case .cardInteractionComplete: print("Card interaction complete.")
            case .cardRecognized: print("Card recognized.")
            case .cardRemoved: print("Card removed.")
            case .requestCAN(let canCallback): print("CAN callback not implemented.")
            case .requestPIN(let attempts, let pinCallback): print("PIN callback not implemented.")
            case .requestPINAndCAN(let pinCANCallback): print("PIN CAN callback not implemented.")
            case .requestPUK(let pukCallback): print("PUK callback not implemented.")
            case .processCompletedSuccessfully: print("Process completed successfully.")
            case .pinManagementStarted: print("PIN Management started.")
            case .requestChangedPIN(let attempts, let pinCallback):
                print("Providing changed PIN with \(attempts ?? 3) attempts.")
                pinCallback("123456", "000000")
            case .requestCANAndChangedPIN(let pinCallback): print("Providing CAN and changed PIN not implemented.")
            default: print("Received unexpected event.")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
