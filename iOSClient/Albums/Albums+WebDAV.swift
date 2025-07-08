//
//  Albums+WebDAV.swift
//  Nextcloud
//
//  Created by A200118228 on 07/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import NextcloudKit
import Alamofire
import SwiftyJSON
import SwiftyXMLParser

public struct Album {
    let name: String
    let lastPhotoId: String?
    let itemCount: Int?
    let location: String?
    let dateRange: String?
    let collaborators: String?
}

public extension NextcloudKit {
    
    func fetchAllAlbums(
        for account: String,
        options: NKRequestOptions = NKRequestOptions(),
        taskHandler: @escaping (_ task: URLSessionTask) -> Void = { _ in },
        completion: @escaping (Result<[Album], Error>) -> Void
    ) {
        
        let session = NCSession.shared.getSession(account: account)
        
        //options.contentType = "application/xml"
        
        let urlPath = session.urlBase + "/remote.php/dav/photos/" + session.user + "/albums/"
        
        guard let nkSession = nkCommonInstance.getSession(account: account),
              let url = urlPath.encodedToUrl,
              let headers = nkCommonInstance.getStandardHeaders(account: account, options: options) else {
            return options.queue.async { completion(.failure(NKError.urlError)) }
        }
        
        let method = HTTPMethod(rawValue: "PROPFIND")
        
        let propfindXML = """
        <?xml version="1.0"?>
        <d:propfind xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns" xmlns:nc="http://nextcloud.org/ns" xmlns:ocs="http://open-collaboration-services.org/ns">
            <d:prop>
                <nc:last-photo />
                <nc:nbItems />
                <nc:location />
                <nc:dateRange />
                <nc:collaborators />
            </d:prop>
        </d:propfind>
        """
        
        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            urlRequest.httpBody = propfindXML.data(using: .utf8)
            urlRequest.timeoutInterval = options.timeout
        } catch {
            return options.queue.async { completion(.failure(NKError(error: error))) }
        }
        
        nkSession.sessionData.request(
            urlRequest,
            //interceptor: NKInterceptor(nkCommonInstance: nkCommonInstance)
        )
        .validate(statusCode: 200..<300)
        .onURLSessionTaskCreation { task in
            task.taskDescription = options.taskDescription
            taskHandler(task)
        }
        .response(queue: self.nkCommonInstance.backgroundQueue) { response in
            
            if self.nkCommonInstance.levelLog > 0 {
                debugPrint(response)
            }
            
            let statusCode = response.response?.statusCode
            
            // Explicit 404 check
            if statusCode == 404 {
                let error = NKError.success
                return options.queue.async {
                    completion(.success([]))
                }
            }
            
            switch response.result {
                
            case .failure(let error):
                let error = NKError(error: error, afResponse: response, responseData: response.data)
                options.queue.async { completion(.failure(error)) }
                
            case .success:
                
                guard let data = response.data else {
                    return options.queue.async {
                        completion(.failure(NKError.invalidData))
                    }
                }
                
                let albums = self.parseAlbumsXML(data: data)
                options.queue.async {
                    completion(.success(albums))
                }
            }
        }
    }
    
    private func parseAlbumsXML(data: Data) -> [Album] {
        
        let xml = XML.parse(data)
        var albums: [Album] = []
        
        let elements = xml["d:multistatus", "d:response"]
        
        for element in elements {
            
            let href = element["d:href"].element?.text ?? ""
            
            let prop = element["d:propstat"]["d:prop"]
            
            let lastPhoto = prop["nc:last-photo"].element?.text
            let nbItems = prop["nc:nbItems"].element?.text.flatMap { Int($0) }
            let location = prop["nc:location"].element?.text
            let dateRange = prop["nc:dateRange"].element?.text
            let collaborators = prop["nc:collaborators"].element?.text
            
            // Optionally skip entries with 404 status
            let status = element["d:propstat"]["d:status"].element?.text ?? ""
            if status.contains("200") {
                let album = Album(
                    name: href,
                    lastPhotoId: nil,
                    itemCount: nil,
                    location: nil,
                    dateRange: nil,
                    collaborators: nil
                )
                albums.append(album)
            }
        }
        
        return albums
        
        //        return [
        //            Album(
        //                name: "Sample Album",
        //                lastPhotoId: nil,
        //                itemCount: nil,
        //                location: nil,
        //                dateRange: nil,
        //                collaborators: nil
        //            )
        //        ]
    }
    
    func createNewAlbum(
        for account: String,
        albumName: String,
        options: NKRequestOptions = NKRequestOptions(),
        taskHandler: @escaping (_ task: URLSessionTask) -> Void = { _ in },
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        
        let session = NCSession.shared.getSession(account: account)
        
        //options.contentType = "application/xml"
        
        let urlPath = session.urlBase + "/remote.php/dav/photos/" + session.user + "/albums/\(albumName)/"
        
        guard let nkSession = nkCommonInstance.getSession(account: account),
              let url = urlPath.encodedToUrl,
              let headers = nkCommonInstance.getStandardHeaders(account: account, options: options) else {
            return options.queue.async { completion(.failure(NKError.urlError)) }
        }
        
        let method = HTTPMethod(rawValue: "MKCOL")
        
        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            urlRequest.timeoutInterval = options.timeout
        } catch {
            return options.queue.async { completion(.failure(NKError(error: error))) }
        }
        
        nkSession.sessionData.request(
            urlRequest,
            //interceptor: NKInterceptor(nkCommonInstance: nkCommonInstance)
        )
        //        .validate(statusCode: 200..<300)
        .onURLSessionTaskCreation { task in
            task.taskDescription = options.taskDescription
            taskHandler(task)
        }
        .response(queue: self.nkCommonInstance.backgroundQueue) { response in
            
            if self.nkCommonInstance.levelLog > 0 {
                debugPrint(response)
            }
            
            let statusCode = response.response?.statusCode
            
            // Explicit 405 check
            if statusCode == 405 {
                let error = NKError(errorCode: 405, errorDescription: "Album already exists!", responseData: nil)
                return options.queue.async {
                    completion(.failure(error))
                }
            }
            
            switch response.result {
                
            case .failure(let error):
                let error = NKError(error: error, afResponse: response, responseData: response.data)
                options.queue.async { completion(.failure(error)) }
                
            case .success:
                
                guard let data = response.data else {
                    return options.queue.async {
                        completion(.failure(NKError.invalidData))
                    }
                }
                
                let albums = self.parseAlbumsXML(data: data)
                options.queue.async {
                    completion(.success(true))
                }
            }
        }
    }
}
