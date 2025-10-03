//
//  ApiTest.swift
//  motorsports
//
//  Created by Vaidik Dubey on 18/09/25.
//

//import Foundation
//
//func testAPIConnection() async -> Bool{
//    
//    do {
//        print (" Testing api with data")
//        let url = URL(string: "\(RacingAPIService.baseURL)/eventsseason.php?id=4370&s=2025")
//        
//        let (data, response) = try await URLSession.shared.data(from : url)
//        
//        if let httpResponse = response as? HTTPURLResponse {
//            print("HTTP status code: \(httpResponse.statusCode)")
//            
//            if httpResponse.statusCode == 200 {
//                print("Api test data size : \(data.count) bytes")
//                
//                //parsing and counting upcoming events
//                
//                do {
//                    let apiResponse = try JSONDecoder().decode(SportsDBResponse.self, from : data)
//                    let eventCount = apiResponse.events?.count ?? 0
//                    print(" found \(eventCount) f1 2025 events")
//                    
//                    let today = Date()
//                    let upcomingCount = apiresponse.events?.filter {
//                        event in
//                        guard let datestring = event.dateEvent,
//                              let date = parseEventDate(dateString) else { return false}
//                        return date >= today
//                    }.count ?? 0
//                }
//                
//            }
//        }
//    }
//}
//    
//    private func parseEventdate ( dateString: String) -> Date? {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        let date = formatter.date(from: dateString)
//        if date == nil {
//            print("failed to parse data")
//        }
//        return date
//    }
//
// class FontManager
