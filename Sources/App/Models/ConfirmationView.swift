//
//  ConfirmationUIView.swift
//

import SwiftUI

struct ConfirmationView: View {
    
    @State var isComing: Bool = false
    @state var currentID: Int = 0
    
    var body: some View {
        
        ZStack{
            
            Button("Confirmation"){
                showAlert.toggle()
            }
            .alert(isPresented: @isComing, content:{
                
                Alert(
                    title: Text("Incoming Shuttle")
                    message: Text("It is reported a shuttle is coming.\nPlease Confirm.")
                    primaryButton: action:{
                        Button(Text("I see the shuttle.")){
                            
                        message:  Confirmation.reportPositive()
                        message: Text("You reported the bus is coming.")
                            
                        }
                        Button(Text("I do not see the shuttle.")){
                        message: Confirmation.reportNegative()
                        message: Text("You reported the bus is missing.")
                        }
                        Button(Text("Show other's report")){
                        message: Confirmation.getReport()
                            
                        }
                    }
                    
                    secondaryButton: .cancel())
            
            
        }
        
                
                
            
            )
        })
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
