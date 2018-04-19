//
//  Person.swift
//  ConcurrencyProgramming
//
//  Created by taehoon lee on 2018. 4. 18..
//  Copyright © 2018년 taehoon lee. All rights reserved.
//

import Foundation

class Person {
    private var firstName: String
    private var lastName: String
    
    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
    
    func changeName(firstName: String, lastName: String) {
        sleep(arc4random_uniform(UInt32(1)))
        self.firstName = firstName
        sleep(arc4random_uniform(UInt32(2)))
        self.lastName = lastName
    }
    
    var name: String {
        return "\(firstName) \(lastName)"
    }
}


class ThreadSafePerson: Person {
    let isolationQueue = DispatchQueue(label: "com.iPhoneDev.isolation", attributes: .concurrent)
    override func changeName(firstName: String, lastName: String) {
        isolationQueue.async(flags: .barrier) {
            super.changeName(firstName: firstName, lastName: lastName)
        }
    }
    
    override var name: String {
        return isolationQueue.sync {
            return super.name
        }
    }
}
