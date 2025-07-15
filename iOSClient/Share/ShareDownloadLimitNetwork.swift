//
//  ShareDownloadLimitNetwork.swift
//  Nextcloud
//
//  Created by A118830248 on 11/11/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation
import SwiftyJSON
import NextcloudKit
import Alamofire

class NMCCommunication: NSObject, XMLParserDelegate {
    
    public static let shared: NMCCommunication = {
        let instance = NMCCommunication()
        return instance
    }()
    
    var message = ""
    var foundCharacters = "";
    var downloadLimit = DownloadLimit()
    private lazy var appDelegate = UIApplication.shared.delegate as? AppDelegate
    var controller: NCMainTabBarController!
    var session: NCSession.Session {
        NCSession.shared.getSession(controller: controller)
    }
    
    func getDownloadLimit(token: String, completion: @escaping (_ downloadLimit: DownloadLimit?, _ errorDescription: String) -> Void)  {
        let baseUrl = session.urlBase       // NCBrandOptions.shared.loginBaseUrl
    
    func getDownloadLimit(token: String, completion: @escaping (_ downloadLimit: DownloadLimit?, _ errorDescription: String) -> Void)  {
        let baseUrl = appDelegate?.urlBase ?? ""       // NCBrandOptions.shared.loginBaseUrl
        let endPoint = "/ocs/v2.php/apps/files_downloadlimit/\(token)/limit"
        let path = baseUrl+endPoint
        do {
            var urlRequest = try URLRequest(url: URL(string: path)!, method: .get)
            urlRequest.addValue("true", forHTTPHeaderField: "OCS-APIREQUEST")
            
            let sessionConfiguration = URLSessionConfiguration.default
            let urlSession = URLSession(configuration: sessionConfiguration)
            
            let task = urlSession.dataTask(with: urlRequest) { [self] (data, response, error) in
                guard error == nil else {
                    completion(nil, error?.localizedDescription ?? "")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    print("url: \(String(describing: httpResponse.url))\nStatus Code: \(statusCode)")
                    if  httpResponse.statusCode == 200 {
                        let parser = XMLParser(data: data!)
                        parser.delegate = self
                        parser.parse()
                        completion(self.downloadLimit, self.message)
                    }  else {
                        completion(nil, "Invalid Response code: \(statusCode)")
                    }
                } else {
                    completion(nil, error?.localizedDescription ?? "Invalid Response")
                }
            }
            task.resume()
        } catch {
            completion(nil, error.localizedDescription)
        }
    }

    func setDownloadLimit(deleteLimit: Bool, limit: String, token: String, completion: @escaping (_ success: Bool, _ errorDescription: String) -> Void)  {
        let baseUrl = session.urlBase         //NCBrandOptions.shared.loginBaseUrl
        let baseUrl = appDelegate?.urlBase ?? ""         //NCBrandOptions.shared.loginBaseUrl
        let endPoint = "/ocs/v2.php/apps/files_downloadlimit/\(token)/limit"
        let path = baseUrl+endPoint
        do {
            
            let method =  deleteLimit ? HTTPMethod.delete : .put
            var urlRequest = try URLRequest(url: URL(string: path)!, method: method)
            
            urlRequest.addValue("true", forHTTPHeaderField: "OCS-APIREQUEST")
            urlRequest.addValue(authorizationToken(), forHTTPHeaderField: "Authorization")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let parameters = ["token": token, "limit": limit]
            
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(parameters)
            urlRequest.httpBody = jsonData
                         
            let sessionConfiguration = URLSessionConfiguration.default
            let urlSession = URLSession(configuration: sessionConfiguration)
            
            let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
                guard error == nil else {
                    completion(false, error?.localizedDescription ?? "")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    print("url: \(String(describing: httpResponse.url))\nStatus Code: \(statusCode)")
                    if  httpResponse.statusCode == 200 {
                        completion(true, error?.localizedDescription ?? "")
                    }  else {
                        completion(false, "Invalid Response code: \(statusCode)")
                    }
                } else {
                    completion(false, error?.localizedDescription ?? "Invalid Response")
                }
            }
            task.resume()
        } catch {
            completion(false, error.localizedDescription)
        }
    }
    
    public func authorizationToken() -> String {
        let accountDetails = NCManageDatabase.shared.getAllTableAccount().first
        let accountDetails = NCManageDatabase.shared.getAllAccount().first
        let password = NCKeychain().getPassword(account: accountDetails?.account ?? "") 
        let username = accountDetails?.user ?? ""
        let credential = Data("\(username):\(password)".utf8).base64EncodedString()
        return ("Basic \(credential)")
    }

    
    // MARK:- XML Parser Delegate
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
    }
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.foundCharacters += string;
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "limit" {
            let limit =  self.foundCharacters.replacingOccurrences(of: "\n", with: "")
            self.downloadLimit.limit = Int(limit.trimmingCharacters(in: .whitespaces))
        }
        if elementName == "count" {
            let count =  self.foundCharacters.replacingOccurrences(of: "\n", with: "")
            self.downloadLimit.count = Int(count.trimmingCharacters(in: .whitespaces))
        }
        if elementName == "message"{
            self.message = self.foundCharacters
        }
        self.foundCharacters = ""
    }
}

struct DownloadLimit: Codable {
    var limit: Int?
    var count: Int?
}
