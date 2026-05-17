# Implementation Plan: Updates Feed Tab (Comm Server)

## Overview

Two parallel implementation tracks:

- **Track 1 — Backend (Rust):** A new standalone Rust workspace called "Comm Server" in
  `NxtLAP Folder/Server NxtLAP/Comm Server/`. Follows the same structural pattern as the
  existing News Server. Contains two Lambda functions (`comm-bot` scheduled every 5 min,
  `comm-api` HTTP) and a `shared` crate for models + DynamoDB service.

- **Track 2 — iOS (SwiftUI):** New model, service, view-model, and three views added to
  `NxtLAP/motorsports/`. The existing News tab in `MainTabView` is replaced with the Updates
  tab. `motorsportsApp.swift` is updated to remove the `newsViewModel` environment object if
  `NewsView` is no longer referenced.

Both tracks are independent and can be worked on simultaneously. The iOS track has a placeholder
base URL that must be updated after the backend is deployed.

---

## Tasks

- [x] 1. Create Comm Server workspace skeleton
  - Create the directory `NxtLAP Folder/Server NxtLAP/Comm Server/` with subdirectories:
    `comm-bot/src/`, `comm-api/src/`, `shared/src/`, `scripts/`
  - Write `Cargo.toml` (workspace root) with members `["comm-bot", "comm-api", "shared"]`,
    `resolver = "2"`, and all `[workspace.dependencies]` pinned exactly as specified in
    design §2.2 (aws-config `=1.8.12`, aws-sdk-dynamodb `=1.103.0`, lambda_runtime `0.11`,
    lambda_http `0.11`, reqwest `0.11` rustls-tls, serde, serde_json, chrono, uuid, anyhow,
    tracing, tracing-subscriber, tokio full, `[profile.release]` with `opt-level = "z"`,
    `lto = true`, `codegen-units = 1`, `strip = true`)
  - _Requirements: 4.1, 5.1, 6.1, 7.1_

  - [x] 1.1 Write workspace `Cargo.toml`
    - Exact content from design §2.2
    - _Requirements: 4.1, 5.1_

  - [x] 1.2 Write `shared/Cargo.toml`
    - Exact content from design §2.3 — all deps via `workspace = true`
    - _Requirements: 4.1, 5.1_

  - [x] 1.3 Write `comm-bot/Cargo.toml`
    - Exact content from design §2.3 — `[[bin]] name = "comm-bot"`
    - _Requirements: 4.1, 7.1_

  - [x] 1.4 Write `comm-api/Cargo.toml`
    - Exact content from design §2.3 — `[[bin]] name = "comm-api"`
    - _Requirements: 6.1_

- [x] 2. Implement shared crate (models + DynamoDB service)

  - [x] 2.1 Write `shared/src/models.rs`
    - Define `MessageType` enum with variants `RaceStart`, `RaceStarted`, `RaceFinished`,
      `General`; implement `as_db_str()` and `from_db_str()` helpers
    - Define `ReactionData` struct with `count: u32` and `user_ids: Vec<String>`
    - Define `CommMessage` struct — **critical**: `ttl: i64` field MUST carry
      `#[serde(skip_serializing, skip_deserializing)]` to prevent iOS decoding failures
      (see design §8 / SERVER_BUG_CONTEXT.md §3)
    - Implement `CommMessage::new()` constructor that generates UUID v4, sets `bot_name =
      "@nxt_max"`, and computes `ttl = now + 90 * 24 * 60 * 60`
    - Define `RaceEvent` struct matching the racing calendar API response shape
    - All structs use `#[serde(rename_all = "camelCase")]`
    - Exact code from design §2.4
    - _Requirements: 4.6, 4.7, 5.2, 5.5, 8.1–8.4_

  - [ ]* 2.2 Write property test — TTL exclusion from JSON (Property 6)
    - **Property 6: TTL exclusion from API response**
    - Serialize any `CommMessage` to JSON and assert the resulting string does NOT contain
      the key `"ttl"`
    - **Validates: Requirements 5.5**

  - [ ]* 2.3 Write property test — Reaction count consistency (Property 2)
    - **Property 2: Reaction count consistency**
    - For any sequence of add/remove operations on a `ReactionData`, assert
      `count == user_ids.len()` after every operation
    - **Validates: Requirements 13.7, 13.8, 13.9**

  - [x] 2.4 Write `shared/src/dynamodb_service.rs`
    - Implement `CommDynamoDBService` with methods:
      - `save_message` — `put_item` with `condition_expression("attribute_not_exists(id)")`
        to prevent duplicates; swallows `ConditionalCheckFailedException`
      - `get_messages(limit)` — full table scan, deserialize `data` blob, restore `ttl`
        from dedicated attribute, filter expired items (`ttl > now`), sort ascending by
        `timestamp`, truncate to `limit`
      - `message_exists_for_race(race_id, msg_type)` — scan with filter expression on
        `race_id` and `message_type` attributes
      - `add_reaction(message_id, emoji, user_id)` — read → check duplicate → push user_id
        → update count → write back
      - `remove_reaction(message_id, emoji, user_id)` — read → retain filter → update count
        → remove emoji key if count == 0 → write back
      - Private helpers `get_message_by_id` and `write_message_back`
    - Exact code from design §2.5
    - _Requirements: 5.1–5.6, 7.4, 13.7–13.10_

  - [ ]* 2.5 Write property test — Message deduplication (Property 1)
    - **Property 1: Message deduplication**
    - Calling `save_message` multiple times with the same race ID and message type must
      result in exactly one item stored (idempotent)
    - **Validates: Requirements 7.4**

  - [ ]* 2.6 Write property test — Reaction idempotence add (Property 3)
    - **Property 3: Reaction idempotence (add)**
    - Calling `add_reaction` twice with the same (message_id, emoji, user_id) must produce
      the same result as calling it once — count increments by exactly 1, user_id appears
      exactly once
    - **Validates: Requirements 13.7, 13.8**

  - [ ]* 2.7 Write property test — Reaction round-trip (Property 4)
    - **Property 4: Reaction round-trip (add then remove)**
    - For a message with no existing reactions, adding then removing the same reaction must
      return the reactions map to its original empty state
    - **Validates: Requirements 13.4, 13.5, 13.9**

  - [ ]* 2.8 Write property test — Message sort order (Property 5)
    - **Property 5: Message sort order**
    - For any set of messages returned by `get_messages`, assert they are sorted by
      `timestamp` in ascending order (oldest first)
    - **Validates: Requirements 5.6**

  - [x] 2.9 Write `shared/src/lib.rs`
    - Re-export `CommMessage`, `MessageType`, `RaceEvent`, `ReactionData`,
      `CommDynamoDBService`
    - Exact content from design §2.6
    - _Requirements: 4.1, 5.1_

- [x] 3. Checkpoint — shared crate compiles
  - Run `cargo check -p shared` from the Comm Server workspace root.
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Implement `comm-bot` Lambda

  - [x] 4.1 Write `comm-bot/src/main.rs`
    - Implement `function_handler` that:
      1. Reads `TABLE_NAME` env var (default `"NxtLAPComm"`)
      2. Initializes `CommDynamoDBService`
      3. Calls `fetch_upcoming_races()` → `GET {RACING_API}/races/upcoming`
      4. For each race, computes `minutes_until = (race.date - now).num_minutes()` and
         creates messages for three windows:
         - `RaceStart`: `0 <= minutes_until <= 30`
         - `RaceStarted`: `-5 <= minutes_until < 0`
         - `RaceFinished`: `-5 <= finish_minutes < 0` (finish = start + 120 min)
      5. Calls `message_exists_for_race` before each `save_message` to prevent duplicates
    - Implement `fetch_upcoming_races()` using `reqwest` with `use_rustls_tls()`
    - `RACING_API` constant: `"https://brto98doc9.execute-api.us-east-1.amazonaws.com"`
    - Exact code from design §2.7
    - _Requirements: 4.1–4.7, 7.1–7.6, 8.1–8.5_

  - [ ]* 4.2 Write property test — Message content completeness (Property 8)
    - **Property 8: Message content completeness**
    - For any `RaceEvent`, the generated message content string must contain
      `event_name`, `circuit`, and `series`
    - **Validates: Requirements 8.1, 8.4, 4.5**

- [x] 5. Implement `comm-api` Lambda

  - [x] 5.1 Write `comm-api/src/main.rs`
    - Implement `function_handler` routing on `(method, path)`:
      - `GET /health` → `{"status": "ok", "service": "NxtLAP Comm"}`
      - `GET /updates/messages` → scan, strip `user_ids` from all `ReactionData` before
        serializing, return JSON array
      - `POST /updates/messages/{id}/reactions` → parse `ReactionRequest` (emoji, action,
        userId), validate emoji against `ALLOWED_EMOJIS`, dispatch to `add_reaction` or
        `remove_reaction`, strip `user_ids` from response
    - `ALLOWED_EMOJIS`: `["🏁", "🏆", "🔥", "❤️", "👍", "😮"]`
    - All responses include `Access-Control-Allow-Origin: *` header
    - Implement `parse_limit(query, default, max)` helper
    - Exact code from design §2.8
    - _Requirements: 6.1–6.6, 13.6–13.10_

  - [ ]* 5.2 Write property test — Allowed emoji enforcement (Property 9)
    - **Property 9: Allowed emoji enforcement**
    - For any emoji string not in the allowed set, the handler must return HTTP 400 and
      leave the message unchanged
    - **Validates: Requirements 13.2**

  - [ ]* 5.3 Write property test — user_ids exclusion from API response (Property 7)
    - **Property 7: user_ids exclusion from API response**
    - For any `CommMessage` returned by `GET /updates/messages` or `POST .../reactions`,
      the serialized JSON must not contain a `"userIds"` field in any reaction value
    - **Validates: Requirements 13.7**

- [x] 6. Write build and deploy scripts

  - [x] 6.1 Write `scripts/build.sh`
    - Set `CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-unknown-linux-gnu-gcc`
      before invoking `cargo lambda build` — this is the Zig 0.15.2 linker workaround
      (see SERVER_BUG_CONTEXT.md §4)
    - Build both binaries with `--release --arm64 --compiler cargo`:
      ```
      cargo lambda build --release --arm64 -p comm-bot --compiler cargo
      cargo lambda build --release --arm64 -p comm-api --compiler cargo
      ```
    - Check for `cargo-lambda` and exit with helpful message if missing
    - Print binary sizes after build
    - Exact content from design §2.9
    - _Requirements: 4.1, 6.1_

  - [x] 6.2 Write `scripts/deploy.sh`
    - Call `./scripts/build.sh` first
    - Deploy `comm-bot` with `--timeout 120 --memory 256 --env-var TABLE_NAME=NxtLAPComm`
    - Deploy `comm-api` with `--timeout 30 --memory 256 --env-var TABLE_NAME=NxtLAPComm`
    - Print post-deploy instructions: create API Gateway HTTP API, create EventBridge rule
      `rate(5 minutes)`, update iOS `CommService.swift` base URL
    - Exact content from design §2.10
    - _Requirements: 7.5_

- [x] 7. Write `README.md` for Comm Server
  - Document folder structure, prerequisites (`cargo-lambda`, `aarch64-unknown-linux-gnu-gcc`,
    Rust target `aarch64-unknown-linux-gnu`), build command, deploy command
  - Include the DynamoDB table creation commands from design §6 (step 3)
  - Include the EventBridge rule creation commands from design §6 (step 8)
  - Reference `SERVER_BUG_CONTEXT.md` for known issues (TTL, Zig linker, duplicates)
  - _Requirements: 4.1, 6.1, 7.5_

- [x] 8. Checkpoint — backend compiles and passes tests
  - Run `cargo check` and `cargo test` from the Comm Server workspace root.
  - Ensure all tests pass, ask the user if questions arise.

---

- [x] 9. Create iOS data model

  - [x] 9.1 Write `NxtLAP/motorsports/Models/CommMessage.swift`
    - Define `CommMessage: Identifiable, Codable, Equatable` with fields:
      `id`, `botName`, `content`, `timestamp` (String ISO 8601), `messageType`,
      `raceId: String?`, `reactions: [String: Int]` (server strips userIds),
      `replyCount: Int?`
    - Define nested `MessageType: String, Codable` enum with cases `raceStart`,
      `raceStarted`, `raceFinished`, `general`
    - Implement `formattedTimestamp: String` computed property using
      `ISO8601DateFormatter` (try with `.withFractionalSeconds` first, then without),
      `RelativeDateTimeFormatter` for < 24 h, `DateFormatter` for older messages,
      returning `"just now"` for < 60 s
    - Exact code from design §4.2
    - _Requirements: 2.2, 2.3, 9.1–9.5_

  - [ ]* 9.2 Write unit tests for `CommMessage.formattedTimestamp`
    - Test "just now" for timestamps < 60 s ago
    - Test relative format for timestamps 1 h ago
    - Test absolute date format for timestamps > 24 h ago
    - _Requirements: 9.1–9.4_

- [x] 10. Create iOS network service

  - [x] 10.1 Write `NxtLAP/motorsports/Services/CommService.swift`
    - `baseURL` placeholder: `"https://REPLACE_WITH_COMM_API_URL"` (updated after deploy)
    - `cacheKey = "cached_comm_messages"` in `UserDefaults`
    - `fetchMessages(limit: Int = 50)` — `GET /updates/messages?limit=\(limit)`, decode
      `[CommMessage]`, cache raw `Data` to `UserDefaults`; on network error fall back to
      cached data if available, otherwise rethrow
    - `addReaction(to:emoji:userId:)` and `removeReaction(from:emoji:userId:)` — delegate
      to private `sendReaction(messageId:emoji:action:userId:)` which POSTs to
      `/updates/messages/{id}/reactions` with JSON body `{emoji, action, userId}`
    - Exact code from design §4.3
    - _Requirements: 3.1–3.6, 13.6_

  - [ ]* 10.2 Write property test — Offline cache round-trip (Property 10)
    - **Property 10: Offline cache round-trip**
    - For any array of `CommMessage` objects, encoding to `Data` and decoding back must
      produce an equivalent array
    - **Validates: Requirements 3.5, 10.5**

- [x] 11. Create iOS view-model

  - [x] 11.1 Write `NxtLAP/motorsports/ViewModels/CommViewModel.swift`
    - `@MainActor class CommViewModel: ObservableObject`
    - `@Published var messages: [CommMessage] = []`
    - `@Published var isLoading = false`
    - `@Published var errorMessage: String?`
    - `deviceId: String` computed property — reads from `UserDefaults["deviceId"]`,
      generates and stores `UUID().uuidString` on first access
    - `fetchMessages()` — sets `isLoading`, calls `CommService.fetchMessages()`, updates
      `messages` or `errorMessage`
    - `addReaction(to:emoji:)` — calls service, calls `updateMessage(_:)`, triggers
      `HapticManager.shared.trigger(.light)`; silently logs on failure
    - `removeReaction(from:emoji:)` — same pattern as add
    - Private `updateMessage(_:)` — finds index by id and replaces in-place
    - Exact code from design §4.4
    - _Requirements: 2.1, 2.4, 2.6, 2.8, 3.1, 3.4, 3.6, 13.4, 13.5_

- [x] 12. Create iOS views

  - [x] 12.1 Write `NxtLAP/motorsports/Views/UpdatesFeedView.swift`
    - `@StateObject private var viewModel = CommViewModel()`
    - `NavigationView` with `Color.black` background, `.navigationTitle("Updates")`,
      `.navigationBarTitleDisplayMode(.inline)`, `.toolbarColorScheme(.dark)`
    - State-driven body: loading spinner (while `isLoading && messages.isEmpty`), error
      view with retry button (while `errorMessage != nil && messages.isEmpty`), empty state
      view, or feed view
    - Feed: `ScrollViewReader` → `ScrollView` → `LazyVStack` of `MessageBubbleView`;
      `.refreshable` triggers `fetchMessages()`; `.onAppear` scrolls to `last.id`
    - Empty state: `"No updates yet.\nCheck back soon for racing news!"`
    - Error state: `racingRed` triangle icon, error text, "Retry" button
    - `.task { await viewModel.fetchMessages() }` on the outer view
    - Exact code from design §4.5
    - _Requirements: 2.1–2.8, 3.6, 10.1–10.5_

  - [x] 12.2 Write `NxtLAP/motorsports/Views/MessageBubbleView.swift`
    - `HStack(alignment: .top)` with bot avatar (36 pt red circle + antenna SF Symbol) and
      a `VStack` containing: header row (`@nxt_max` in `racingRed` bold + relative
      timestamp in secondary), message content text, and `ReactionBarView` (shown only
      when `reactions` is non-empty)
    - Padding: `.horizontal 16`, `.vertical 10`
    - Exact code from design §4.6
    - _Requirements: 2.2, 2.3, 9.1_

  - [x] 12.3 Write `NxtLAP/motorsports/Views/ReactionBarView.swift`
    - Pill buttons for existing reactions (emoji + count); tapping an existing pill calls
      `viewModel.removeReaction`
    - "+" button that toggles `showPicker` with haptic feedback
    - `.sheet` presenting `EmojiPickerSheet` at `.height(120)` detent
    - `EmojiPickerSheet`: `HStack` of 6 emoji buttons from `allowedEmojis`; tapping calls
      `viewModel.addReaction` and dismisses sheet
    - `allowedEmojis = ["🏁", "🏆", "🔥", "❤️", "👍", "😮"]`
    - Exact code from design §4.7
    - _Requirements: 13.1–13.5_

- [x] 13. Wire iOS tab navigation

  - [x] 13.1 Modify `NxtLAP/motorsports/Views/MainTabView.swift`
    - Change `Tab` enum: replace `case news` with `case updates`
    - Replace `NewsView()` tab item with `UpdatesFeedView()` using
      `Label("Updates", systemImage: "bell.fill")` and `.tag(Tab.updates)`
    - Remove any remaining references to `Tab.news`
    - _Requirements: 1.1–1.5_

  - [x] 13.2 Modify `NxtLAP/motorsports/motorsportsApp.swift`
    - Check whether `NewsView` is still used anywhere in the app (search for `NewsView`
      and `newsViewModel` references)
    - If `NewsView` is no longer referenced: remove `@StateObject private var newsViewModel
      = NewsViewModel()` and remove `.environmentObject(newsViewModel)` from the
      `WindowGroup` body
    - If `NewsView` is still used elsewhere: leave `newsViewModel` in place
    - _Requirements: 1.5_

- [x] 14. Final checkpoint — iOS builds
  - Open the project in Xcode and confirm it builds without errors.
  - Verify the Updates tab appears in the tab bar and `UpdatesFeedView` loads.
  - Ensure all tests pass, ask the user if questions arise.
  - **FIXED**: `CommMessage.reactions` type mismatch — iOS expected `[String: Int]` but server sends `[String: ReactionData]`. Added `ReactionData` struct to iOS model and `reactionCounts` convenience property.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Track 1 (tasks 1–8) and Track 2 (tasks 9–14) are fully independent and can run in parallel
- **Critical bug**: `ttl` on `CommMessage` MUST use `#[serde(skip_serializing, skip_deserializing)]` — omitting this will cause iOS JSON decoding failures
- **Critical build note**: `build.sh` MUST set `CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-unknown-linux-gnu-gcc` and pass `--compiler cargo` — the default Zig linker (0.15.2) breaks crypto libs
- **DynamoDB table**: `NxtLAPComm`, billing mode `PAY_PER_REQUEST` (avoids throttling unlike the provisioned News Server table)
- **iOS base URL**: `CommService.swift` ships with placeholder `"https://REPLACE_WITH_COMM_API_URL"` — update after running `deploy.sh`
- **Device identity**: `UserDefaults["deviceId"]` stores a UUID for reaction deduplication; `user_ids` are stored in DynamoDB but stripped from all API responses
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at natural boundaries

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4", "9.1"] },
    { "id": 1, "tasks": ["2.1", "2.9"] },
    { "id": 2, "tasks": ["2.2", "2.3", "2.4"] },
    { "id": 3, "tasks": ["2.5", "2.6", "2.7", "2.8", "4.1", "10.1"] },
    { "id": 4, "tasks": ["4.2", "5.1", "9.2", "10.2", "11.1"] },
    { "id": 5, "tasks": ["5.2", "5.3", "6.1", "12.1", "12.2", "12.3"] },
    { "id": 6, "tasks": ["6.2", "13.1", "13.2"] }
  ]
}
```
