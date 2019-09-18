//
//  FlickerClient.swift
//  VirtualTourist
//
//  Created by Julio Cesar Whatley on 9/13/19.
//  Copyright © 2019 Capi. All rights reserved.
//

import Foundation

class FlickerClient {
    
    static let apiKey = "b0b9aad156f2e2f5b3b07a1dd2cf7551"
    static let apiSecret = "1e428b7a707b814e"
    
    class func getRandomPageNum(totalPicsAvailable: Int, maxNumPicsDisplayed: Int) -> Int {
        let flickrLimit = 4000
        // number of pages of results is based on the total number of pics available, or the flickr limit,
        // whichever amount is smaller, divided by the maximum number of pics allowed to be displayed in the album
        let numPages = min(totalPicsAvailable, flickrLimit) / maxNumPicsDisplayed
        let randomPageNum = Int.random(in: 0...numPages)
        print("totalPicsAvailable is \(totalPicsAvailable)")
        print("numPages is \(numPages)")
        print("randomPageNum is \(randomPageNum)")
        return randomPageNum
    }
    
    class func getFlickerUrl(latitude: Double, longitude: Double, totalNumPicsAvailable: Int = 0, updatedNumPicsToDisplay: Int = 12, maxNumPicsDisplayed: Int = 12) -> URL {
        
        let radius = 20
        let perPage = updatedNumPicsToDisplay
        let pageNum = totalNumPicsAvailable > 0 ?
            getRandomPageNum(totalPicsAvailable: totalNumPicsAvailable, maxNumPicsDisplayed: maxNumPicsDisplayed) : 1
        
        let searchURLString = "https://www.flickr.com/services/rest/?method=flickr.photos.search" +
            "&api_key=\(FlickerClient.apiKey)" +
            "&lat=\(latitude)" +
            "&lon=\(longitude)" +
            "&radius=\(radius)" +
            "&per_page=\(perPage)" +
            "&page=\(pageNum)" +
        "&format=json&nojsoncallback=1&extras=url_m"
        print(searchURLString)
        
         return URL(string: searchURLString)!
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                //                print(decoder)
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                //                print(error)
                //                do {
                //                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data) as Error
                //                    DispatchQueue.main.async {
                //                        completion(nil, errorResponse)
                //                    }
                //                } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                //                }
            }
        }
        task.resume()
        
        return task
    }
    
    class func getPhotos(latitude: Double, longitude: Double, totalNumPicsAvailable: Int = 0, completion: @escaping ([Photo], Error?) -> Void) -> Void {
        let url = getFlickerUrl(latitude: latitude, longitude: longitude, totalNumPicsAvailable: totalNumPicsAvailable)
        let _ = taskForGETRequest(url: url, responseType: PictureReponse.self) { response, error in
            if let response = response {
                completion(response.photos.photo, nil)
            } else {
                completion([], error)
            }
        }
    }
    
    class func downloadImage(img: String, completion: @escaping (Data?, Error?) -> Void) {
        let url =  URL(string: img)
        
        guard let imageURL = url else {
            DispatchQueue.main.async {
                completion(nil, nil)
            }
            return
        }
        
        let request = URLRequest(url: imageURL)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(data, nil)
            }
        }
        task.resume()
    }
}
