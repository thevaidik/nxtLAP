//
//  WidgetsAndNotificationsView.swift
//  motorsports
//
//  Created by Vaidik Dubey on 22/04/26.
//

import SwiftUI
import UserNotifications

struct WidgetsAndNotificationsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var dataService: RacingDataService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            // MARK: - Widgets Section
            Section(header: Text("Dynamic Widgets").font(.caption).fontWeight(.bold)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 15) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.nxtlapRacingRed)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Home Screen Widgets")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text("Track upcoming races for your Starred series directly from your Home Screen.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    Text("Tip: To add a widget, long-press your Home Screen, tap '+', and search for 'NxtLAP'.")
                        .font(.caption2)
                        .italic()
                        .foregroundColor(.gray)
                        .padding(.bottom, 4)
                }
                .listRowBackground(Color(white: 0.12))
            }

            // MARK: - Livestream Reminders
            let livestreamRequests = notificationManager.pendingRequests.filter { $0.content.title.contains("📺") }
            if !livestreamRequests.isEmpty {
                Section(header: Text("Livestream Reminders").font(.caption).fontWeight(.bold)) {
                    ForEach(livestreamRequests, id: \.identifier) { request in
                        NotificationRequestRow(request: request)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    notificationManager.cancelNotification(id: request.identifier)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }

            // MARK: - Race Alerts (Grouped)
            let enabledSeries = Array(dataService.notificationsEnabledSeries).sorted()
            if !enabledSeries.isEmpty {
                Section(header: Text("Series Race Alerts").font(.caption).fontWeight(.bold)) {
                    ForEach(enabledSeries, id: \.self) { seriesShortName in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(seriesShortName) Alerts")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("Automatic reminders for all sessions")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "bell.fill")
                                .foregroundColor(.nxtlapRacingRed)
                                .font(.caption)
                                .padding(6)
                                .background(Color.nxtlapRacingRed.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                withAnimation {
                                    dataService.toggleNotificationsForSeries(seriesShortName)
                                }
                            } label: {
                                Label("Disable", systemImage: "bell.slash")
                            }
                        }
                    }
                }
            }

            // MARK: - Empty State
            if livestreamRequests.isEmpty && enabledSeries.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.top, 20)
                        
                        Text("No Alerts Active")
                            .font(.headline)
                        
                        Text("Star a series or set a reminder on a livestream to see them here.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    Button(role: .destructive) {
                        notificationManager.removeAllNotifications()
                        // Also disable all series notifications? 
                        // User might want to keep the series enabled but clear the pending ones.
                        // But for "Automatic" ones they will just come back.
                        // For now let's just clear manual ones.
                    } label: {
                        HStack {
                            Spacer()
                            Text("Remove All Manual Reminders")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Widgets & Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear {
            notificationManager.updateScheduledStatus()
        }
    }
}

struct NotificationRequestRow: View {
    let request: UNNotificationRequest
    
    var triggerDate: Date? {
        if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
            return calendarTrigger.nextTriggerDate()
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(request.content.title.replacingOccurrences(of: "📺 ", with: ""))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(request.content.body)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            if let date = triggerDate {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Starts at ")
                        .font(.caption2)
                    Text(date, style: .time)
                        .font(.caption2)
                        .fontWeight(.semibold)
                    Text("•")
                    Text(date, style: .date)
                        .font(.caption2)
                }
                .foregroundColor(.nxtlapRacingRed.opacity(0.8))
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}
