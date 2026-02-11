import Foundation

class NetworkManager {
    
    let serverURL: String
    
    init(serverURL: String) {
        self.serverURL = serverURL
    }
    
    func sendData(_ payload: [String: Any], completion: @escaping (Bool) -> Void) {
        // Build URL with query parameters
        guard var components = URLComponents(string: "\(serverURL)/location") else {
            print("❌ Invalid server URL: \(serverURL)")
            completion(false)
            return
        }
        
        var queryItems: [URLQueryItem] = []
        
        if let latitude = payload["latitude"] as? Double {
            queryItems.append(URLQueryItem(name: "latitude", value: String(latitude)))
        }
        
        if let longitude = payload["longitude"] as? Double {
            queryItems.append(URLQueryItem(name: "longitude", value: String(longitude)))
        }
        
        if let timestamp = payload["timestamp"] as? String {
            queryItems.append(URLQueryItem(name: "timestamp", value: timestamp))
        }
        
        if let device = payload["device"] as? String {
            queryItems.append(URLQueryItem(name: "device", value: device))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            print("❌ Invalid URL")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        // If health data exists, send as JSON in POST instead
        if let health = payload["health"] as? [String: Any] {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            var bodyDict: [String: Any] = [
                "latitude": payload["latitude"] ?? 0,
                "longitude": payload["longitude"] ?? 0,
                "timestamp": payload["timestamp"] ?? "",
                "device": payload["device"] ?? "iPhone",
                "health": health
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
            } catch {
                print("❌ Failed to serialize JSON: \(error)")
                completion(false)
                return
            }
        }
        
        // Send request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Data sent successfully (HTTP \(httpResponse.statusCode))")
                    completion(true)
                } else {
                    print("❌ Server error: HTTP \(httpResponse.statusCode)")
                    completion(false)
                }
            }
        }.resume()
    }
}
