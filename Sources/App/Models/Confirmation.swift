//
//  Confirmation.swift
//

import Foundation


class Confirmation: Identifiable{
    
    
    private var id: Int
    private var busId: Int
    private var location: Int
    private var userID: Int
    
    init(){
        id = 0
        busID = 0
        location = 0
        userID = 0
    }
    
    init(idV: Int, busIDV: Int, locationV: Int, userIDV: Int){
        id = idV
        busID = busIDV
        location = locationV
        userID = userIDV
        
        if (!ConfirmationBase.search(id)){
            ConfirmationBase.addUser(id, busID, location)
        }
    }
    
    public func reportPositive(){
        ConfirmationBase.addPositive(id)
    }
    
    public func reportNegative(){
        ConfirmationBase.addNegative(id)
    }
    
    public func getReport() -> Double{
        return ConfirmationBase.getRatio(id)
    }
    
}
