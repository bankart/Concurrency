//
//  AsyncOperation.swift
//  ConcurrencyProgramming
//
//  Created by taehoon lee on 2018. 4. 18..
//  Copyright © 2018년 taehoon lee. All rights reserved.
//

import UIKit

class AsyncOperation: Operation {
    // TODO: 1) State enumeration
    enum State: String {
        case ready, executing, finished
        
        // for KVO
        fileprivate var keyPath: String {
            return "is" + rawValue.capitalized
        }
    }
    
    
    // TODO: 2) state property
    var state = State.ready {
        willSet {
            print("AsyncOperation.state.willSet: \(newValue.keyPath), \(state.keyPath)")
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            print("AsyncOperation.state.didSet: \(oldValue.keyPath), \(state.keyPath)")
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
    
    
}

// TODO: 3) Operation overrides
extension AsyncOperation {
    override var isReady: Bool {
        print("\(#function)")
        return super.isReady && state == .ready
    }
    
    override var isExecuting: Bool {
        print("\(#function)")
        return state == .executing
    }
    
    override var isFinished: Bool {
        print("\(#function)")
        return state == .finished
    }
    
    override var isAsynchronous: Bool {
        print("\(#function)")
        return true
    }
    
    override func start() {
        print("\(#function)")
        guard !isCancelled else {
            state = .finished
            return
        }
        main()
        state = .executing
    }
    
    override func cancel() {
        print("\(#function)")
        super.cancel()
        state = .finished
    }
    
}




class SlowAddOperation: AsyncOperation {
    let lhs: Int
    let rhs: Int
    var result: Int?
    init(lhs: Int, rhs: Int) {
        self.lhs = lhs
        self.rhs = rhs
        super.init()
    }
    
    override func main() {
        sleep(1)
        self.result = self.lhs + self.rhs
        print("SlowAddOperation result: \(self.result!)")
        self.state = .finished
    }
}


fileprivate class URLSessionDataTaskMock: URLSessionDataTask {
    var url: URL?
    var data: Data?
    var responseMock: URLResponse?
    var errorMock: Error?
    var completionHandler: (Data?, URLResponse?, Error?) -> Void
    
    init(url: URL?, data: Data?, responseMock: URLResponse?, errorMock: Error?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        print("URLSessionDataTaskMock.init()")
        self.url = url
        self.data = data
        self.responseMock = responseMock
        self.errorMock = errorMock
        self.completionHandler = completionHandler
    }
    override func resume() {
        print("URLSessionDataTaskMock.resume()")
        completionHandler(data, responseMock, errorMock)
//        super.resume()
    }
}

fileprivate class URLSessionMock: URLSession {
    var data: Data?
    var error: Error?
    var response: URLResponse?
    init(data: Data?, response: URLResponse?, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskMock {
        print("URLSessionMock.dataTask()")
        return URLSessionDataTaskMock(url: url, data: data, responseMock: response, errorMock: error, completionHandler: completionHandler)
    }
}

fileprivate func downloadImage(named name: String, completion: @escaping (UIImage?) -> Void) {
    print("\(#function)")
    let data = UIImageJPEGRepresentation(UIImage(named: name)!, 1.0)
    var urlComponents = URLComponents(string: "https://images.org/")
    urlComponents?.path.append(name)
    let url = urlComponents?.url
    let urlResponse = HTTPURLResponse(url: url!, statusCode: 200, httpVersion: nil, headerFields: nil)
    let session = URLSessionMock(data: data, response: urlResponse, error: nil)
    session.dataTask(with: url!) { (data, response, error) in
        if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
            DispatchQueue.global().async {
                completion(UIImage(data: data))
            }
        }
    }.resume()
}

class ImageLoadOperation: AsyncOperation {
    let imageName: String
    let completion: (UIImage?) -> Void
    var outputImage: UIImage?
    
    init(imageName: String, completion: @escaping (UIImage?) -> Void) {
        self.imageName = imageName
        self.completion = completion
        super.init()
    }
    
    override func main() {
        downloadImage(named: imageName) { image in
            self.outputImage = image
            self.state = .finished
            self.completion(self.outputImage)
        }
    }
}






