//
//  ViewController.swift
//  ConcurrencyProgramming
//
//  Created by taehoon lee on 2018. 4. 18..
//  Copyright © 2018년 taehoon lee. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private var viewLaunchTime: TimeInterval?
    override func viewDidLoad() {
        super.viewDidLoad()
        viewLaunchTime = Date().timeIntervalSince1970
        print("\(#function)")
//        animation0()
        
//        threadUnsafe()
        
//        operationDemo0()
//        operationDemo1()
        operationDemo2()
    }
    
    private func canvas() -> UIView {
        let container = UIView(frame: CGRect(x: 10, y: 50, width: view.frame.width - 20, height: view.frame.height - 20))
        container.backgroundColor = .black
        
        let box = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        box.backgroundColor = .red
        container.addSubview(box)
        
        let label = UILabel(frame: CGRect(x: 15, y: 100, width: 360, height: 40))
        label.font = label.font.withSize(50)
        label.text = "All done!"
        label.textAlignment = .center
        label.isHidden = true
        
        container.addSubview(label)
        return container
    }
    
    private func animation0() {
        let canvas = self.canvas()
        view.addSubview(canvas)
        let box = canvas.subviews.first!
        let label = canvas.subviews.last!
        
        UIView.animate(withDuration: 1, animations: {
            box.center = CGPoint(x: 300, y: 300)
        }) { _ in
            UIView.animate(withDuration: 3, animations: {
                box.transform = CGAffineTransform(rotationAngle: .pi/4)
            }, completion: nil)
        }
        
        UIView.animate(withDuration: 5, animations: {
            canvas.backgroundColor = .blue
        }, completion: { _ in
            label.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
                canvas.removeFromSuperview()
                self?.animation1()
            })
        })
    }
    
    private func animation1() {
        let canvas = self.canvas()
        view.addSubview(canvas)
        let box = canvas.subviews.first!
        let label = canvas.subviews.last!
        
        let animationGroup = DispatchGroup()
        
        UIView.animate(withDuration: 1, animations: {
            box.center = CGPoint(x: 300, y: 300)
        }, group: animationGroup, completion: { _ in
            UIView.animate(withDuration: 3, animations: {
                box.transform = CGAffineTransform(rotationAngle: .pi/4)
            }, group: animationGroup, completion: nil)
        })
        
        UIView.animate(withDuration: 5, animations: {
            canvas.backgroundColor = .blue
        }, group: animationGroup, completion: nil)
        
        animationGroup.notify(queue: DispatchQueue.main) {
            label.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                canvas.removeFromSuperview()
            })
        }
    }
    
    
    private func threadUnsafe() {
        print("\n\(#function)")
        let workerQueue = DispatchQueue(label: "com.iPhoneDev.worker", attributes: .concurrent)
        let nameChangeGroup = DispatchGroup()
        let nameChangingPerson = Person(firstName: "Alison", lastName: "Anderson")
        let nameList = [("charlie", "Cheesecake"), ("Delia", "Dingle"), ("Eva", "Evershed"), ("Freddi", "Frost"), ("Gina", "Gregory")]
        
        for (idx, name) in nameList.enumerated() {
            workerQueue.async(group: nameChangeGroup) {
                usleep(UInt32(10000 * idx))
                nameChangingPerson.changeName(firstName: name.0, lastName: name.1)
                print("\(#function) current name: \(nameChangingPerson.name)")
            }
        }
        
        nameChangeGroup.notify(queue: DispatchQueue.global()) {
            print("\(#function) final name: \(nameChangingPerson.name)")
            self.threadSafe()
        }
    }
    
    private func threadSafe() {
        print("\n\(#function)")
        let workerQueue = DispatchQueue(label: "com.iPhoneDev.worker", attributes: .concurrent)
        let nameChangeGroup = DispatchGroup()
        let nameChangingPerson = ThreadSafePerson(firstName: "Alison", lastName: "Anderson")
        let nameList = [("charlie", "Cheesecake"), ("Delia", "Dingle"), ("Eva", "Evershed"), ("Freddi", "Frost"), ("Gina", "Gregory")]
        
        for (idx, name) in nameList.enumerated() {
            workerQueue.async(group: nameChangeGroup) {
                usleep(UInt32(10000 * idx))
                nameChangingPerson.changeName(firstName: name.0, lastName: name.1)
                print("\(#function) current name: \(nameChangingPerson.name)")
            }
        }
        
        nameChangeGroup.notify(queue: DispatchQueue.global()) {
            print("\(#function) final name: \(nameChangingPerson.name)")
        }
    }
    
    private func operationDemo0() {
        func slowAdd(_ input: (Int, Int)) -> Int {
            sleep(1)
            return input.0 + input.1
        }
        let result = slowAdd((42, 24))
        print("slowAdd result: \(result)")
        
        let slowAddQueue = OperationQueue()
        func asyncSlowAdd(lhs: Int, rhs: Int, completion: @escaping (Int) -> Void) {
            slowAddQueue.addOperation {
                completion( slowAdd((lhs, rhs)) )
            }
        }
        asyncSlowAdd(lhs: 42, rhs: 24) { (result) in
            print("asyncSlowAdd result: \(result)")
        }
    }
    
    private func operationDemo1() {
        let slowAddOp = SlowAddOperation(lhs: 42, rhs: 24)
        OperationQueue().addOperations([slowAddOp], waitUntilFinished: true)
    }
    
    private func operationDemo2() {
        let imageLoad = ImageLoadOperation(imageName: "bear_first") { [weak self] image in
            print("image load complete")
            guard let strongSelf = self else { return }
            strongSelf.view.addSubview(UIImageView(image: image))
            let finishTime = Date().timeIntervalSince1970
            print("\(finishTime) - \(strongSelf.viewLaunchTime!) = \(finishTime - strongSelf.viewLaunchTime!)")
        }
        OperationQueue().addOperations([imageLoad], waitUntilFinished: true)
    }
}

extension UIView {
    static func animate(withDuration duration: TimeInterval, animations: @escaping () -> Void, group: DispatchGroup, completion: ((Bool) -> Void)?) {
        group.enter()
        animate(withDuration: duration, animations: animations) { success in
            completion?(success)
            group.leave()
        }
    }
}

