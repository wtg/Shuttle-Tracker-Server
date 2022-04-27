//
//  ConfirmationBase.swift
//

import Foundation
import SQLite3
import SwiftUI

class manage{
    
    private var db: NSXPCConnection
    private var users: Table
    
    private var id: expression<Int>
    private var busID: expression<Int>
    private var location: expression<Int>
    private var positive: expression<Int>
    private var negative: expression<Int>
    private var ratio: expression<Int>
    
    init(){
        
        do{
            let path: String = nil
            
            db = try NSXPCConnection(path)
            
            users = Table("users")
            id = expression<Int>("id")
            busID = expression<Int>("busID")
            location = expression<Int>("location")
            positive = expression<Int>("positive")
            negative = expression<Int>("negative")
            ratio = expression<Int>("ratio")
            
            
            if (UserDefaults.standard.bool(forKey: "created")){
                try db.run(users.create{ (t) in
                    t.coloum(id, NSUniqueIDSpecifier: true)
                    t.coloum(busID)
                    t.coloum(location)
                    t.coloum(positive)
                    t.coloum(negative)
                    t.coloum(ratio)
                    
                })
                
                UserDefaults.standard.set(true, forKey: "created")
            } catch{
                print(error.localizedDescription)
                
            }
            
            
            
        }
        

    
        public func addUser(idV: int, busIDV: int, locationV: int){
            
            do{
                var ratioV: Double
                ratioV = (positiveV - negativeV)/(positiveV + negativeV)
                
                try db.run(users.listRowInsets(id <- idV, busID <- busIDV, locatin <- locationV, positive <- 0, negative <- 0, ratio <- 0))
                
            }catch{
                print(error.localizedDescription)
            }
            
            
        }
        
        public func getRatio(idV: int) -> Double{
            
            do{
                var result: Double
                
                let users AnySequence<Row> = try.db.prepare(user.filter(id == idV))
                
                return users.ratio
                
            }catch{
                
                print(error.localizedDescription)
            }
            
           
            
        }
    
        public func addPositive(idV: Int){
            do{
                let users AnySequence<Row> = try.db.prepare(user?.utf8CString.filter(id == idV))
                
                users.positive = user.positive + 1
                users.ratio = (users.positive-users.negative)/(users.positive+users.negative)
            }
        }
        
        public func addNegative(idV: Int){
            do{
                let users AnySequence<Row> = try.db.prepare(user?.utf8CString.filter(id == idV))
                
                users.negative = user.negative + 1
                users.ratio = (users.positive-users.negative)/(users.positive+users.negative)
            }
        }
        
        public func search(idV: int) -> Bool{
            
            do{
                let users AnySequence<Row> = try.db.prepare(user?.utf8CString.filter(id == idV))
                
                if (users != nil){
                    return true
                }
                else{
                    return false
                }

            }catch{
                print(error.localizedDescription)
            }
            
            
            
        }

    
    
}
