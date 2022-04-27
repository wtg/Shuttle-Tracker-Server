//
//  passenger.swift
//

import Foundation


class Passenger{
    
    private id: Int
    private credit: Int
    
    
    init(){
        id = 0
        credit = 5
    }
    
    init(idV: int, creditV: int){
        id = idV
        credit = creditV
    }
    
    public func lowerCredit(){
        if (credit != 1){
            credit = credit - 1
        }
        Credit.updateCredit(id, credit)
    }
    
    public func increaseCredit(){
        if (credit != 5){
            credit = credit + 1
        }
        Credit.updateCredit(id, credit)
    }
    
    
    
}
