//
//  NotificationManager.swift
//  motorsports
//
//  Created by Vaidik Dubey on 22/04/26.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var scheduledNotificationIDs: Set<String> = []
    @Published var pendingRequests: [UNNotificationRequest] = []
    private let storageKey = "scheduled_notifications"
    
    init() {
        loadScheduledIDs()
        updateScheduledStatus()
    }
    
    private func loadScheduledIDs() {
        if let saved = UserDefaults.standard.stringArray(forKey: storageKey) {
            scheduledNotificationIDs = Set(saved)
        }
    }
    
    private func saveScheduledIDs() {
        UserDefaults.standard.set(Array(scheduledNotificationIDs), forKey: storageKey)
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleRaceNotification(race: Race) {
        let content = UNMutableNotificationContent()
        content.title = "🏎️ Race Starting Soon!"
        content.body = "\(race.series): \(race.name) is about to start at \(race.location)."
        content.sound = .default
        
        var triggerDate = race.date
        
        // Handle races without exact time
        if !race.hasExactTime {
            // Set to 9:00 AM on the day of the race
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: race.date)
            components.hour = 9
            components.minute = 0
            if let newDate = calendar.date(from: components) {
                triggerDate = newDate
            }
            content.body = "\(race.series): \(race.name) is happening today at \(race.location)!"
        } else {
            // Schedule 15 minutes before if it has an exact time
            triggerDate = race.date.addingTimeInterval(-15 * 60)
            
            // If 15 mins before is in the past, schedule for now or the actual start time
            if triggerDate < Date() {
                triggerDate = race.date
            }
        }
        
        // Only schedule if it's in the future
        guard triggerDate > Date() else {
            print("⚠️ Cannot schedule notification for past date: \(triggerDate)")
            return
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: race.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.scheduledNotificationIDs.insert(race.id)
                    self.saveScheduledIDs()
                }
                print("✅ Scheduled notification for \(race.name) at \(triggerDate)")
            }
        }
    }
    
    func scheduleLivestreamNotification(stream: Livestream) {
        guard let startDate = stream.startDate, startDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📺 Livestream Starting!"
        content.body = "\(stream.channelTitle): \(stream.title) is about to go live."
        content.sound = .default
        
        // Schedule 5 minutes before
        let triggerDate = startDate.addingTimeInterval(-5 * 60)
        let finalTriggerDate = triggerDate > Date() ? triggerDate : startDate
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: finalTriggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: stream.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule livestream notification: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.scheduledNotificationIDs.insert(stream.id)
                    self.saveScheduledIDs()
                }
                print("✅ Scheduled livestream notification for \(stream.title) at \(finalTriggerDate)")
            }
        }
    }
    
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        scheduledNotificationIDs.remove(id)
        saveScheduledIDs()
        print("🗑️ Cancelled notification for \(id)")
    }
    
    func isNotificationScheduled(id: String) -> Bool {
        return scheduledNotificationIDs.contains(id)
    }
    
    func toggleRaceNotification(race: Race) {
        if isNotificationScheduled(id: race.id) {
            cancelNotification(id: race.id)
        } else {
            scheduleRaceNotification(race: race)
        }
    }
    
    func toggleLivestreamNotification(stream: Livestream) {
        if isNotificationScheduled(id: stream.id) {
            cancelNotification(id: stream.id)
        } else {
            scheduleLivestreamNotification(stream: stream)
        }
    }
    
    // MARK: - Status Sync
    func syncRaceNotifications(races: [Race], enabledSeries: Set<String>) {
        // 1. Get all upcoming sessions for enabled series
        let enabledRaces = races.filter { enabledSeries.contains($0.series) }
        
        // 2. Schedule each one (handles future-only and avoids duplicates via identifier)
        for race in enabledRaces {
            scheduleRaceNotification(race: race)
        }
    }
    
    func updateScheduledStatus() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingRequests = requests.sorted { 
                    let d1 = ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? Date.distantFuture
                    let d2 = ($1.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? Date.distantFuture
                    return d1 < d2
                }
                self.scheduledNotificationIDs = Set(requests.map { $0.identifier })
                self.saveScheduledIDs()
            }
        }
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        DispatchQueue.main.async {
            self.scheduledNotificationIDs.removeAll()
            self.pendingRequests.removeAll()
            self.saveScheduledIDs()
        }
    }
    
}
