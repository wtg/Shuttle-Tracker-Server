//
//  Credit.swift
//  

import Foundation


class Credit{
    
    private data: [:]
    
    
    init(){
        data = [:]
    }
    
    public func addUser(id: int){
        data[id] = 5
    }
    
    public func search(id: int) -> Bool{
        if (data[id] == nil){
            return false
        }
        else{
            return true
        }
    }
    
    public func updateCredit(idV: int, creditV: int){
        data[idV] = creditV
    }
    
    public func getCredit(id: int) -> Int{
        return data[id]
    }
}
