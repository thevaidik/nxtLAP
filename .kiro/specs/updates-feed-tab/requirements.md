# Requirements Document: Updates Feed Tab

## Introduction

The Updates Feed Tab replaces the existing News tab in the NxtLAP motorsports app. The News tab is redundant because news articles are already displayed as Instagram-style stories in the Home view. The new Updates Feed provides a Discord/Telegram-style messaging interface where a bot (@nxt_max) posts automated racing event updates and notifications.

The feature consists of two main components:
1. **iOS Client**: SwiftUI-based feed interface replacing the News tab
2. **Backend Service**: AWS Lambda-based bot message generation and delivery system (Comm Server)

## Glossary

- **Updates_Feed_View**: The SwiftUI view that displays the message feed interface
- **Message_Feed_Service**: iOS service that fetches and manages update messages from the backend
- **Comm_Server**: AWS Lambda-based backend service that generates and delivers automated racing update messages
- **Bot_Message_Generator**: AWS Lambda function within Comm Server that generates automated racing update messages
- **Message_Storage**: DynamoDB table storing bot messages with timestamps and metadata
- **NxtMax_Bot**: The automated bot entity that posts racing updates (displayed as @nxt_max)
- **Update_Message**: A single message posted by the bot containing racing event information
- **Message_Channel**: A logical grouping of messages (e.g., "General" channel for all updates)
- **Tab_Navigation**: The main tab bar navigation system in the iOS app
- **Race_Event**: A racing event from the existing racing calendar API
- **Message_Timestamp**: ISO8601 formatted timestamp indicating when a message was posted
- **Message_Reaction**: An emoji reaction added by a user to express sentiment about a message

## Requirements

### Requirement 1: Replace News Tab with Updates Tab

**User Story:** As a user, I want to see an Updates tab instead of the News tab, so that I can access racing event notifications in a dedicated feed interface.

#### Acceptance Criteria

1. THE Tab_Navigation SHALL display "Updates" instead of "News" in the main tab bar
2. WHEN the Updates tab is selected, THE Tab_Navigation SHALL display the Updates_Feed_View
3. THE Tab_Navigation SHALL use an appropriate SF Symbol icon for the Updates tab (e.g., "bell.fill" or "message.fill")
4. THE Tab_Navigation SHALL maintain the existing tab order (Home, Watch, Updates, Standings, Settings)
5. THE Tab_Navigation SHALL remove all references to NewsView and News tab configuration

### Requirement 2: Display Bot Messages in Feed Interface

**User Story:** As a user, I want to see bot messages in a Discord-style feed, so that I can easily read racing event updates.

#### Acceptance Criteria

1. THE Updates_Feed_View SHALL display messages in a vertically scrollable list
2. FOR EACH Update_Message, THE Updates_Feed_View SHALL display the bot avatar, bot name (@nxt_max), message content, and timestamp
3. FOR EACH Update_Message, THE Updates_Feed_View SHALL display reaction counts below the message content
4. THE Updates_Feed_View SHALL display messages in chronological order with newest messages at the bottom
5. THE Updates_Feed_View SHALL use a dark theme consistent with the existing app design
6. THE Updates_Feed_View SHALL automatically scroll to the newest message when the view appears
7. WHEN no messages exist, THE Updates_Feed_View SHALL display an empty state message
8. THE Updates_Feed_View SHALL display a loading indicator while fetching messages

### Requirement 3: Fetch Messages from Backend

**User Story:** As a user, I want the app to automatically load the latest racing updates, so that I see current information without manual refresh.

#### Acceptance Criteria

1. WHEN the Updates_Feed_View appears, THE Message_Feed_Service SHALL fetch messages from the backend API
2. THE Message_Feed_Service SHALL request messages from the endpoint `/updates/messages`
3. THE Message_Feed_Service SHALL decode the JSON response into Update_Message objects
4. WHEN the API request fails, THE Message_Feed_Service SHALL provide an error message to the view
5. THE Message_Feed_Service SHALL cache messages locally for offline viewing
6. THE Message_Feed_Service SHALL support pull-to-refresh functionality

### Requirement 4: Generate Racing Event Update Messages

**User Story:** As a system administrator, I want the bot to automatically generate racing event updates, so that users receive timely notifications about races.

#### Acceptance Criteria

1. THE Bot_Message_Generator SHALL create Update_Message objects for racing events
2. WHEN a race is scheduled to start within 30 minutes, THE Bot_Message_Generator SHALL create a "Race is about to start" message
3. WHEN a race has started, THE Bot_Message_Generator SHALL create a "Race has started" message
4. WHEN a race has finished, THE Bot_Message_Generator SHALL create a "Race has finished" message
5. FOR EACH Update_Message, THE Bot_Message_Generator SHALL include the race name, series, and circuit information
6. THE Bot_Message_Generator SHALL assign the bot identity (@nxt_max) to all generated messages
7. THE Bot_Message_Generator SHALL generate unique message IDs for each Update_Message

### Requirement 5: Store and Retrieve Messages

**User Story:** As a system, I want to persist bot messages in a database, so that users can view message history.

#### Acceptance Criteria

1. THE Message_Storage SHALL store Update_Message objects in DynamoDB
2. FOR EACH Update_Message, THE Message_Storage SHALL store message ID, bot name, content, timestamp, reactions, and metadata
3. THE Message_Storage SHALL support querying messages by timestamp range
4. THE Message_Storage SHALL support retrieving the most recent N messages
5. THE Message_Storage SHALL use a TTL attribute to automatically delete messages older than 90 days
6. WHEN queried, THE Message_Storage SHALL return messages sorted by timestamp in ascending order

### Requirement 6: Provide Backend API Endpoint

**User Story:** As an iOS developer, I want a REST API endpoint to fetch messages, so that the app can display updates to users.

#### Acceptance Criteria

1. THE Backend_API SHALL expose a GET endpoint at `/updates/messages`
2. WHEN requested, THE Backend_API SHALL return an array of Update_Message objects in JSON format
3. THE Backend_API SHALL support an optional `limit` query parameter to control the number of messages returned (default: 50)
4. THE Backend_API SHALL support an optional `since` query parameter to fetch messages after a specific timestamp
5. WHEN an error occurs, THE Backend_API SHALL return an appropriate HTTP status code and error message
6. THE Backend_API SHALL include CORS headers to allow requests from the iOS app

### Requirement 7: Schedule Message Generation

**User Story:** As a system administrator, I want messages to be generated automatically based on race schedules, so that users receive timely updates without manual intervention.

#### Acceptance Criteria

1. THE Bot_Message_Generator SHALL run on a scheduled basis (every 5 minutes)
2. WHEN executed, THE Bot_Message_Generator SHALL query the racing calendar API for upcoming races
3. FOR EACH Race_Event within the next 60 minutes, THE Bot_Message_Generator SHALL check if a pre-race message has been sent
4. THE Bot_Message_Generator SHALL not create duplicate messages for the same race event and message type
5. THE Bot_Message_Generator SHALL use EventBridge or CloudWatch Events for scheduling
6. WHEN a race transitions from "upcoming" to "in progress" to "finished", THE Bot_Message_Generator SHALL create corresponding messages

### Requirement 8: Format Messages with Racing Context

**User Story:** As a user, I want update messages to include relevant racing information, so that I understand which race the update refers to.

#### Acceptance Criteria

1. FOR EACH Update_Message about a race start, THE Bot_Message_Generator SHALL include the race name, series, and circuit
2. THE Bot_Message_Generator SHALL format messages in a conversational tone (e.g., "🏁 The Chinese Grand Prix is about to start at Shanghai International Circuit!")
3. THE Bot_Message_Generator SHALL include appropriate emoji icons for different message types (🏁 for race start, 🏆 for race finish)
4. THE Bot_Message_Generator SHALL include the race series name (e.g., "Formula 1", "MotoGP")
5. WHEN multiple races are happening simultaneously, THE Bot_Message_Generator SHALL create separate messages for each race

### Requirement 9: Display Message Metadata

**User Story:** As a user, I want to see when each message was posted, so that I can understand the timeline of racing events.

#### Acceptance Criteria

1. FOR EACH Update_Message, THE Updates_Feed_View SHALL display a relative timestamp (e.g., "2 hours ago", "just now")
2. THE Updates_Feed_View SHALL format timestamps using RelativeDateTimeFormatter
3. WHEN a message is less than 1 minute old, THE Updates_Feed_View SHALL display "just now"
4. WHEN a message is more than 24 hours old, THE Updates_Feed_View SHALL display the absolute date and time
5. THE Updates_Feed_View SHALL update relative timestamps when the view is refreshed

### Requirement 10: Handle Empty and Error States

**User Story:** As a user, I want clear feedback when there are no messages or when something goes wrong, so that I understand the app's status.

#### Acceptance Criteria

1. WHEN no messages are available, THE Updates_Feed_View SHALL display "No updates yet. Check back soon for racing news!"
2. WHEN the API request fails, THE Updates_Feed_View SHALL display an error message with a retry button
3. WHEN retrying after an error, THE Updates_Feed_View SHALL show a loading indicator
4. THE Updates_Feed_View SHALL use the app's Racing Red color for error icons
5. WHEN the device is offline, THE Updates_Feed_View SHALL display cached messages if available

### Requirement 11: Integrate with Existing Notification System

**User Story:** As a user, I want to receive push notifications for important racing updates, so that I don't miss race starts even when the app is closed.

#### Acceptance Criteria

1. WHEN a "race is about to start" message is generated, THE Bot_Message_Generator SHALL trigger a push notification
2. THE Bot_Message_Generator SHALL use the existing NotificationManager infrastructure
3. THE Push_Notification SHALL include the race name and series in the notification body
4. WHEN a user taps the notification, THE App SHALL open to the Updates_Feed_View
5. THE Bot_Message_Generator SHALL respect user notification preferences from the Settings view

### Requirement 12: Support Future Extensibility

**User Story:** As a product manager, I want the message system to support future interactive features, so that we can add replies and other engagement features later.

#### Acceptance Criteria

1. THE Update_Message data model SHALL include an optional field for reply count
2. THE Message_Storage schema SHALL support storing reply data
3. THE Updates_Feed_View layout SHALL reserve space for future reply UI elements
4. THE Backend_API response format SHALL be versioned to support future schema changes

### Requirement 13: Add Reactions to Messages

**User Story:** As a user, I want to react to bot messages with emojis, so that I can express my excitement about races.

#### Acceptance Criteria

1. WHEN a user taps a message, THE Updates_Feed_View SHALL display reaction options
2. THE Updates_Feed_View SHALL provide common racing emojis for reactions (🏁, 🏆, 🔥, ❤️, 👍, 😮)
3. FOR EACH Update_Message, THE Updates_Feed_View SHALL display reaction counts below the message content
4. THE Updates_Feed_View SHALL allow users to add a reaction by tapping an emoji
5. THE Updates_Feed_View SHALL allow users to remove their own reaction by tapping it again
6. THE Message_Feed_Service SHALL send reaction updates to the backend API endpoint POST /updates/messages/{messageId}/reactions
7. THE Message_Storage SHALL store reactions with user IDs to prevent duplicate reactions from the same user
8. WHEN a user adds a reaction, THE Backend_API SHALL increment the reaction count for that emoji
9. WHEN a user removes a reaction, THE Backend_API SHALL decrement the reaction count for that emoji
10. THE Backend_API SHALL return the updated message with current reaction counts after each reaction operation

## Data Models

### Update_Message (iOS Client)
```swift
struct UpdateMessage: Identifiable, Codable {
    let id: String
    let botName: String // "@nxt_max"
    let content: String
    let timestamp: String // ISO8601
    let messageType: MessageType // .raceStart, .raceFinished, .general
    let raceId: String?
    let reactions: [String: Int] // emoji -> count
    let replyCount: Int? // Future
}

enum MessageType: String, Codable {
    case raceStart
    case raceFinished
    case general
}
```

### Message Item (DynamoDB)
```json
{
  "messageId": "uuid",
  "botName": "@nxt_max",
  "content": "🏁 The Chinese Grand Prix is about to start!",
  "timestamp": "2026-03-22T14:30:00Z",
  "messageType": "raceStart",
  "raceId": "2225616",
  "ttl": 1770022430,
  "reactions": {
    "🏁": {
      "count": 5,
      "userIds": ["user1", "user2", "user3", "user4", "user5"]
    },
    "🔥": {
      "count": 3,
      "userIds": ["user1", "user6", "user7"]
    }
  },
  "replyCount": 0
}
```

## API Specification

### GET /updates/messages

**Query Parameters:**
- `limit` (optional, default: 50): Maximum number of messages to return
- `since` (optional): ISO8601 timestamp to fetch messages after

**Response (200 OK):**
```json
[
  {
    "id": "msg-123",
    "botName": "@nxt_max",
    "content": "🏁 The Chinese Grand Prix is about to start at Shanghai International Circuit!",
    "timestamp": "2026-03-22T14:30:00Z",
    "messageType": "raceStart",
    "raceId": "2225616",
    "reactions": {
      "🏁": 5,
      "🔥": 3
    },
    "replyCount": 0
  }
]
```

**Error Response (500):**
```json
{
  "error": "Failed to fetch messages",
  "message": "Internal server error"
}
```

### POST /updates/messages/{messageId}/reactions

**Path Parameters:**
- `messageId` (required): The ID of the message to react to

**Request Body:**
```json
{
  "emoji": "🏁",
  "action": "add"
}
```

**Fields:**
- `emoji` (required): The emoji to add or remove (must be one of: 🏁, 🏆, 🔥, ❤️, 👍, 😮)
- `action` (required): Either "add" or "remove"

**Response (200 OK):**
```json
{
  "id": "msg-123",
  "botName": "@nxt_max",
  "content": "🏁 The Chinese Grand Prix is about to start at Shanghai International Circuit!",
  "timestamp": "2026-03-22T14:30:00Z",
  "messageType": "raceStart",
  "raceId": "2225616",
  "reactions": {
    "🏁": 6,
    "🔥": 3
  },
  "replyCount": 0
}
```

**Error Response (400):**
```json
{
  "error": "Invalid request",
  "message": "Emoji must be one of: 🏁, 🏆, 🔥, ❤️, 👍, 😮"
}
```

**Error Response (404):**
```json
{
  "error": "Message not found",
  "message": "Message with ID msg-123 does not exist"
}
```

## Technical Notes

### Backend Architecture
- **Lambda Function**: `comm-bot-generator` (scheduled via EventBridge)
- **Lambda Function**: `comm-api-handler` (API Gateway integration)
- **DynamoDB Table**: `nxtlap-updates-messages`
- **EventBridge Rule**: Trigger every 5 minutes
- **Message TTL**: 90 days (automatically deleted after 3 months)

### Folder Structure
- **Backend Code**: `comm-server/` directory containing Lambda functions and infrastructure code

### iOS Architecture
- **New View**: `UpdatesFeedView.swift`
- **New Service**: `UpdatesService.swift`
- **New Model**: `UpdateMessage.swift`
- **New ViewModel**: `UpdatesViewModel.swift`
- **Modified**: `MainTabView.swift` (replace News tab)

### Dependencies
- Existing racing calendar API (`/races/upcoming`)
- Existing NotificationManager for push notifications
- AWS SDK for Lambda and DynamoDB operations
