//
//  ShareDownloadLimitNetwork.swift
//  Nextcloud
//
//  Created by A118830248 on 11/11/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation
import SwiftyJSON
import NCCommunication
import Alamofire

extension NCCommunication {
    func getDownloadLimit(token: String, completion: @escaping (_ downloadLimit: DownloadLimit?, _ errorDescription: String) -> Void)  {
        let baseUrl = NCBrandOptions.shared.loginBaseUrl
        let endPoint = "ocs/v2.php/apps/files_downloadlimit/\(token)/limit"
        let path = baseUrl+endPoint
        do {
            var urlRequest = try URLRequest(url: URL(string: path)!, method: .get)
            urlRequest.addValue("true", forHTTPHeaderField: "OCS-APIRequest")
            urlRequest.addValue("true", forHTTPHeaderField: "Authorization")
            
            let sessionConfiguration = URLSessionConfiguration.default
            let urlSession = URLSession(configuration: sessionConfiguration)
            
            let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
                guard error == nil else {
                    completion(nil, error?.localizedDescription ?? "")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    print("url: \(String(describing: httpResponse.url))\nStatus Code: \(statusCode)")
                    if  httpResponse.statusCode == 200 {
                        do {
                            let json = try JSON(data: data!)
                            let message = json["ocs"]["meta"]["message"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                            
                            let downloadLimit = try JSONDecoder().decode(DownloadLimit.self, from: data!)
                            completion(downloadLimit, message)
                            
                        } catch {
                            completion(nil, error.localizedDescription)
                        }
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
        let baseUrl = NCBrandOptions.shared.loginBaseUrl
        let endPoint = "ocs/v2.php/apps/files_downloadlimit/\(token)/limit"
        let path = baseUrl+endPoint
        do {
            
            let method =  deleteLimit ? HTTPMethod.delete : .put
            var urlRequest = try URLRequest(url: URL(string: path)!, method: method)
            
            urlRequest.addValue("true", forHTTPHeaderField: "OCS-APIRequest")
            
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
}

struct DownloadLimit: Codable {
    var limit: Int?
    var count: Int?
}
