# Design Document: Updates Feed Tab (Comm Server)

## Overview

The Updates Feed Tab replaces the existing News tab in the NxtLAP iOS app with a Discord-style
message feed. A scheduled AWS Lambda bot (@nxt_max) auto-generates race lifecycle messages
(about to start, started, finished) by polling the existing racing calendar API. Users can react
to messages with six racing emojis. The backend is a new Rust workspace called "Comm Server"
deployed to AWS Lambda + DynamoDB, following the exact same patterns as the News Server.

---

## 1. System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          AWS Cloud                                   │
│                                                                      │
│  EventBridge (rate 5 min)                                            │
│       │                                                              │
│       ▼                                                              │
│  ┌──────────────┐    GET /races/upcoming    ┌──────────────────────┐ │
│  │  comm-bot    │ ─────────────────────────▶│  Racing Server API   │ │
│  │  (Lambda)    │ ◀─────────────────────────│  brto98doc9...       │ │
│  └──────┬───────┘                           └──────────────────────┘ │
│         │ put_item (conditional)                                      │
│         ▼                                                             │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                  DynamoDB: NxtLAPComm                        │    │
│  │  PK: id (UUID)  |  data (JSON blob)  |  ttl (90 days)       │    │
│  └──────────────────────────┬───────────────────────────────────┘    │
│                             │ scan + update_item                      │
│  ┌──────────────┐           │                                         │
│  │  comm-api    │ ──────────┘                                         │
│  │  (Lambda)    │                                                      │
│  └──────┬───────┘                                                      │
│         │ API Gateway HTTP API                                         │
└─────────┼───────────────────────────────────────────────────────────┘
          │ HTTPS
          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        iOS App (NxtLAP)                              │
│                                                                      │
│  MainTabView  ──▶  UpdatesFeedView                                   │
│                         │                                            │
│                    CommViewModel  ──▶  CommService                   │
│                         │                  │                         │
│                    [CommMessage]       URLSession                     │
│                    UserDefaults                                       │
│                    (deviceId UUID)                                    │
└─────────────────────────────────────────────────────────────────────┘
```

### How it fits alongside existing servers

| Server | URL | Purpose |
|--------|-----|---------|
| Racing Server | `https://brto98doc9.execute-api.us-east-1.amazonaws.com` | Race calendar, standings |
| News Server | `https://meol2c3y91.execute-api.us-east-1.amazonaws.com` | RSS news articles |
| Livestream Server | `https://650wjqhzhc.execute-api.us-east-1.amazonaws.com` | YouTube livestreams |
| **Comm Server** | **New URL after deploy** | Bot messages + reactions |

The Comm Server is a standalone Rust workspace in `Server NxtLAP/Comm Server/`. It does not
share code with the other servers — it follows the same structural pattern but is independently
deployed.

---

## 2. Backend Design (Rust)

### 2.1 Folder Structure

```
Server NxtLAP/
└── Comm Server/
    ├── Cargo.toml          ← workspace root
    ├── Cargo.lock
    ├── comm-bot/           ← scheduled Lambda (EventBridge every 5 min)
    │   ├── Cargo.toml
    │   └── src/
    │       └── main.rs
    ├── comm-api/           ← HTTP Lambda (API Gateway)
    │   ├── Cargo.toml
    │   └── src/
    │       └── main.rs
    ├── shared/             ← shared models + DynamoDB service
    │   ├── Cargo.toml
    │   └── src/
    │       ├── lib.rs
    │       ├── models.rs
    │       └── dynamodb_service.rs
    ├── scripts/
    │   ├── build.sh
    │   └── deploy.sh
    └── README.md
```

### 2.2 Workspace `Cargo.toml`

```toml
[workspace]
members = ["comm-bot", "comm-api", "shared"]
resolver = "2"

[workspace.dependencies]
# AWS SDK — pinned to match existing workspace (rustc 1.88 compatible)
aws-config = { version = "=1.8.12", features = ["behavior-version-latest"] }
aws-sdk-dynamodb = "=1.103.0"

# Lambda
lambda_runtime = "0.11"
lambda_http = "0.11"

# Async runtime
tokio = { version = "1", features = ["full"] }

# HTTP client (rustls — avoids OpenSSL cross-compile issues)
reqwest = { version = "0.11", default-features = false, features = ["json", "rustls-tls"] }

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Date/Time
chrono = { version = "0.4", features = ["serde"] }

# Unique IDs
uuid = { version = "1.0", features = ["v4"] }

# Error handling & logging
anyhow = "1.0"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }

[profile.release]
opt-level = "z"
lto = true
codegen-units = 1
strip = true
```

### 2.3 Member `Cargo.toml` files

**`shared/Cargo.toml`**
```toml
[package]
name = "shared"
version = "0.1.0"
edition = "2021"

[dependencies]
aws-config      = { workspace = true }
aws-sdk-dynamodb = { workspace = true }
reqwest         = { workspace = true }
serde           = { workspace = true }
serde_json      = { workspace = true }
chrono          = { workspace = true }
uuid            = { workspace = true }
anyhow          = { workspace = true }
tracing         = { workspace = true }
tokio           = { workspace = true }
```

**`comm-bot/Cargo.toml`**
```toml
[package]
name = "comm-bot"
version = "0.1.0"
edition = "2021"

[[bin]]
name = "comm-bot"
path = "src/main.rs"

[dependencies]
shared          = { path = "../shared" }
aws-config      = { workspace = true }
aws-sdk-dynamodb = { workspace = true }
lambda_runtime  = { workspace = true }
tokio           = { workspace = true }
serde_json      = { workspace = true }
anyhow          = { workspace = true }
tracing         = { workspace = true }
tracing-subscriber = { workspace = true }
```

**`comm-api/Cargo.toml`**
```toml
[package]
name = "comm-api"
version = "0.1.0"
edition = "2021"

[[bin]]
name = "comm-api"
path = "src/main.rs"

[dependencies]
shared          = { path = "../shared" }
aws-config      = { workspace = true }
aws-sdk-dynamodb = { workspace = true }
lambda_http     = { workspace = true }
tokio           = { workspace = true }
serde           = { workspace = true }
serde_json      = { workspace = true }
anyhow          = { workspace = true }
tracing         = { workspace = true }
tracing-subscriber = { workspace = true }
```

### 2.4 `shared/src/models.rs`

```rust
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// The type of automated message the bot generates.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub enum MessageType {
    /// Sent ~30 min before race start
    RaceStart,
    /// Sent when race is detected as started
    RaceStarted,
    /// Sent when race is detected as finished
    RaceFinished,
    /// General announcement (future use)
    General,
}

impl MessageType {
    /// Returns the snake_case string stored in DynamoDB's `message_type` attribute.
    pub fn as_db_str(&self) -> &'static str {
        match self {
            MessageType::RaceStart    => "race_start",
            MessageType::RaceStarted  => "race_started",
            MessageType::RaceFinished => "race_finished",
            MessageType::General      => "general",
        }
    }

    pub fn from_db_str(s: &str) -> Option<Self> {
        match s {
            "race_start"    => Some(MessageType::RaceStart),
            "race_started"  => Some(MessageType::RaceStarted),
            "race_finished" => Some(MessageType::RaceFinished),
            "general"       => Some(MessageType::General),
            _               => None,
        }
    }
}

/// Per-emoji reaction data stored in DynamoDB.
/// `user_ids` prevents duplicate reactions from the same device.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct ReactionData {
    pub count: u32,
    pub user_ids: Vec<String>,
}

/// A single bot message stored in DynamoDB and served via the API.
///
/// IMPORTANT: `ttl` uses `skip_serializing` + `skip_deserializing` so it is
/// never included in the JSON API response. The iOS app will fail to decode
/// if `ttl` appears in the response (known bug — see SERVER_BUG_CONTEXT.md).
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CommMessage {
    /// UUID v4 — primary key in DynamoDB
    pub id: String,
    /// Always "@nxt_max"
    pub bot_name: String,
    /// Human-readable message text, e.g. "🏁 The Chinese GP is about to start!"
    pub content: String,
    /// ISO 8601 creation timestamp
    pub timestamp: DateTime<Utc>,
    /// Message category for filtering / icon selection
    pub message_type: MessageType,
    /// Race ID from the racing calendar API (used for dedup checks)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub race_id: Option<String>,
    /// emoji → ReactionData. The API response includes this full map so the
    /// iOS client can show counts and know if the current user has reacted.
    #[serde(default)]
    pub reactions: HashMap<String, ReactionData>,
    /// Reserved for future reply threading (always 0 for now)
    pub reply_count: u32,
    /// DynamoDB TTL — Unix timestamp 90 days from creation.
    /// MUST be excluded from JSON to avoid iOS decoding failures.
    #[serde(skip_serializing, skip_deserializing)]
    pub ttl: i64,
}

impl CommMessage {
    pub fn new(
        content: String,
        message_type: MessageType,
        race_id: Option<String>,
    ) -> Self {
        let now = Utc::now();
        let ttl = now.timestamp() + 90 * 24 * 60 * 60; // 90 days
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            bot_name: "@nxt_max".to_string(),
            content,
            timestamp: now,
            message_type,
            race_id,
            reactions: HashMap::new(),
            reply_count: 0,
            ttl,
        }
    }
}

/// A race event returned by the racing calendar API.
#[derive(Debug, Deserialize)]
pub struct RaceEvent {
    pub id: String,
    pub series: String,
    pub event_name: String,
    pub circuit: String,
    pub date: DateTime<Utc>,
    pub country: String,
    pub season: String,
    pub round: u32,
}
```

### 2.5 `shared/src/dynamodb_service.rs`

```rust
use anyhow::{Context, Result};
use aws_sdk_dynamodb::{
    types::AttributeValue,
    Client,
};
use chrono::Utc;
use std::collections::HashMap;
use crate::models::{CommMessage, MessageType, ReactionData};

pub struct CommDynamoDBService {
    client: Client,
    table_name: String,
}

impl CommDynamoDBService {
    pub fn new(client: Client, table_name: String) -> Self {
        Self { client, table_name }
    }

    /// Persist a new message. Uses `attribute_not_exists(id)` to skip duplicates
    /// — if the bot runs twice for the same race+type, the second write is a no-op.
    pub async fn save_message(&self, msg: &CommMessage) -> Result<()> {
        let json_str = serde_json::to_string(msg)?;

        let mut builder = self.client
            .put_item()
            .table_name(&self.table_name)
            .item("id",           AttributeValue::S(msg.id.clone()))
            .item("data",         AttributeValue::S(json_str))
            .item("timestamp",    AttributeValue::S(msg.timestamp.to_rfc3339()))
            .item("message_type", AttributeValue::S(msg.message_type.as_db_str().to_string()))
            .item("ttl",          AttributeValue::N(msg.ttl.to_string()))
            .condition_expression("attribute_not_exists(id)");

        if let Some(race_id) = &msg.race_id {
            builder = builder.item("race_id", AttributeValue::S(race_id.clone()));
        }

        match builder.send().await {
            Ok(_) => Ok(()),
            Err(e) => {
                let svc = e.into_service_error();
                if svc.is_conditional_check_failed_exception() {
                    tracing::debug!("Message already exists, skipping: {}", msg.id);
                    Ok(())
                } else {
                    Err(anyhow::anyhow!("DynamoDB put_item failed: {:?}", svc))
                }
            }
        }
    }

    /// Scan the table, filter expired items, sort ascending by timestamp, truncate.
    pub async fn get_messages(&self, limit: usize) -> Result<Vec<CommMessage>> {
        let result = self.client
            .scan()
            .table_name(&self.table_name)
            .send()
            .await
            .context("Failed to scan NxtLAPComm table")?;

        let items = result.items.unwrap_or_default();
        tracing::info!("Scanned {} raw items", items.len());

        let now = Utc::now().timestamp();
        let mut messages: Vec<CommMessage> = Vec::new();

        for item in items {
            if let Some(AttributeValue::S(json_str)) = item.get("data") {
                match serde_json::from_str::<CommMessage>(json_str) {
                    Ok(mut msg) => {
                        // Restore TTL from dedicated attribute (excluded from JSON blob)
                        if let Some(AttributeValue::N(ttl_str)) = item.get("ttl") {
                            if let Ok(ttl) = ttl_str.parse::<i64>() {
                                msg.ttl = ttl;
                            }
                        }
                        if msg.ttl > now {
                            messages.push(msg);
                        }
                    }
                    Err(e) => tracing::warn!("Failed to parse message: {}", e),
                }
            }
        }

        // Chronological order — oldest first (feed scrolls to bottom)
        messages.sort_by(|a, b| a.timestamp.cmp(&b.timestamp));
        messages.truncate(limit);
        Ok(messages)
    }

    /// Check whether a message already exists for a given race + message type.
    /// Used by comm-bot to prevent duplicate messages.
    pub async fn message_exists_for_race(
        &self,
        race_id: &str,
        msg_type: &MessageType,
    ) -> Result<bool> {
        let result = self.client
            .scan()
            .table_name(&self.table_name)
            .filter_expression("race_id = :rid AND message_type = :mtype")
            .expression_attribute_values(":rid",   AttributeValue::S(race_id.to_string()))
            .expression_attribute_values(":mtype", AttributeValue::S(msg_type.as_db_str().to_string()))
            .send()
            .await
            .context("Failed to scan for existing race message")?;

        Ok(result.count > 0)
    }

    /// Atomically add a reaction emoji from a user.
    /// Returns the updated CommMessage. No-ops if user already reacted with this emoji.
    pub async fn add_reaction(
        &self,
        message_id: &str,
        emoji: &str,
        user_id: &str,
    ) -> Result<CommMessage> {
        // Read current message
        let mut msg = self.get_message_by_id(message_id).await?;

        let reaction = msg.reactions.entry(emoji.to_string()).or_default();
        if reaction.user_ids.contains(&user_id.to_string()) {
            // Already reacted — idempotent
            return Ok(msg);
        }
        reaction.user_ids.push(user_id.to_string());
        reaction.count = reaction.user_ids.len() as u32;

        self.write_message_back(&msg).await?;
        Ok(msg)
    }

    /// Atomically remove a reaction emoji from a user.
    /// Returns the updated CommMessage. No-ops if user hasn't reacted.
    pub async fn remove_reaction(
        &self,
        message_id: &str,
        emoji: &str,
        user_id: &str,
    ) -> Result<CommMessage> {
        let mut msg = self.get_message_by_id(message_id).await?;

        if let Some(reaction) = msg.reactions.get_mut(emoji) {
            reaction.user_ids.retain(|uid| uid != user_id);
            reaction.count = reaction.user_ids.len() as u32;
            if reaction.count == 0 {
                msg.reactions.remove(emoji);
            }
        }

        self.write_message_back(&msg).await?;
        Ok(msg)
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    async fn get_message_by_id(&self, message_id: &str) -> Result<CommMessage> {
        let result = self.client
            .get_item()
            .table_name(&self.table_name)
            .key("id", AttributeValue::S(message_id.to_string()))
            .send()
            .await
            .context("DynamoDB get_item failed")?;

        let item = result.item.ok_or_else(|| {
            anyhow::anyhow!("Message not found: {}", message_id)
        })?;

        if let Some(AttributeValue::S(json_str)) = item.get("data") {
            let mut msg: CommMessage = serde_json::from_str(json_str)?;
            if let Some(AttributeValue::N(ttl_str)) = item.get("ttl") {
                if let Ok(ttl) = ttl_str.parse::<i64>() {
                    msg.ttl = ttl;
                }
            }
            Ok(msg)
        } else {
            Err(anyhow::anyhow!("Message data attribute missing for id: {}", message_id))
        }
    }

    async fn write_message_back(&self, msg: &CommMessage) -> Result<()> {
        let json_str = serde_json::to_string(msg)?;
        self.client
            .update_item()
            .table_name(&self.table_name)
            .key("id", AttributeValue::S(msg.id.clone()))
            .update_expression("SET #d = :data")
            .expression_attribute_names("#d", "data")
            .expression_attribute_values(":data", AttributeValue::S(json_str))
            .send()
            .await
            .context("DynamoDB update_item failed")?;
        Ok(())
    }
}
```

### 2.6 `shared/src/lib.rs`

```rust
pub mod models;
pub mod dynamodb_service;

pub use models::{CommMessage, MessageType, RaceEvent, ReactionData};
pub use dynamodb_service::CommDynamoDBService;
```

### 2.7 `comm-bot/src/main.rs`

```rust
use anyhow::Result;
use aws_config::BehaviorVersion;
use aws_sdk_dynamodb::Client as DynamoDBClient;
use chrono::Utc;
use lambda_runtime::{run, service_fn, Error, LambdaEvent};
use serde_json::Value;
use shared::{CommDynamoDBService, CommMessage, MessageType, RaceEvent};
use tracing::info;

const RACING_API: &str =
    "https://brto98doc9.execute-api.us-east-1.amazonaws.com";

async fn function_handler(_event: LambdaEvent<Value>) -> Result<Value, Error> {
    info!("comm-bot started");

    let table_name = std::env::var("TABLE_NAME")
        .unwrap_or_else(|_| "NxtLAPComm".to_string());

    let config = aws_config::load_defaults(BehaviorVersion::latest()).await;
    let db = CommDynamoDBService::new(DynamoDBClient::new(&config), table_name);

    // Fetch upcoming races from the racing calendar API
    let races = fetch_upcoming_races().await?;
    info!("Fetched {} upcoming races", races.len());

    let now = Utc::now();
    let mut created = 0usize;

    for race in &races {
        let minutes_until = (race.date - now).num_minutes();

        // ── "About to start" — within 30 min, not yet started ──────────────
        if minutes_until >= 0 && minutes_until <= 30 {
            if !db.message_exists_for_race(&race.id, &MessageType::RaceStart).await? {
                let content = format!(
                    "🏁 The {} is about to start at {}! ({})",
                    race.event_name, race.circuit, race.series
                );
                let msg = CommMessage::new(content, MessageType::RaceStart, Some(race.id.clone()));
                db.save_message(&msg).await?;
                info!("Created RaceStart message for race {}", race.id);
                created += 1;
            }
        }

        // ── "Race started" — within 0–5 min past start time ────────────────
        // The bot runs every 5 min; a race is "started" if it began 0–5 min ago.
        if minutes_until < 0 && minutes_until >= -5 {
            if !db.message_exists_for_race(&race.id, &MessageType::RaceStarted).await? {
                let content = format!(
                    "🚦 The {} has started at {}! ({})",
                    race.event_name, race.circuit, race.series
                );
                let msg = CommMessage::new(content, MessageType::RaceStarted, Some(race.id.clone()));
                db.save_message(&msg).await?;
                info!("Created RaceStarted message for race {}", race.id);
                created += 1;
            }
        }

        // ── "Race finished" — approximate finish (start + ~2h) ─────────────
        // Most races are 1.5–2h. We use 120 min as a conservative estimate.
        let finish_minutes = minutes_until + 120;
        if finish_minutes < 0 && finish_minutes >= -5 {
            if !db.message_exists_for_race(&race.id, &MessageType::RaceFinished).await? {
                let content = format!(
                    "🏆 The {} has finished! Great racing at {}. ({})",
                    race.event_name, race.circuit, race.series
                );
                let msg = CommMessage::new(content, MessageType::RaceFinished, Some(race.id.clone()));
                db.save_message(&msg).await?;
                info!("Created RaceFinished message for race {}", race.id);
                created += 1;
            }
        }
    }

    info!("comm-bot done. Created {} messages.", created);
    Ok(serde_json::json!({ "statusCode": 200, "created": created }))
}

async fn fetch_upcoming_races() -> Result<Vec<RaceEvent>> {
    let url = format!("{}/races/upcoming", RACING_API);
    let races = reqwest::Client::builder()
        .use_rustls_tls()
        .build()?
        .get(&url)
        .send()
        .await?
        .json::<Vec<RaceEvent>>()
        .await?;
    Ok(races)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .with_target(false)
        .without_time()
        .init();

    run(service_fn(function_handler)).await
}
```

### 2.8 `comm-api/src/main.rs`

```rust
use anyhow::Result;
use aws_config::BehaviorVersion;
use aws_sdk_dynamodb::Client as DynamoDBClient;
use lambda_http::{run, service_fn, Body, Error, Request, Response};
use serde::Deserialize;
use shared::CommDynamoDBService;
use tracing::info;

// ── Request body for POST /updates/messages/{id}/reactions ──────────────────

#[derive(Deserialize)]
struct ReactionRequest {
    emoji: String,
    action: String, // "add" | "remove"
    #[serde(rename = "userId")]
    user_id: String,
}

// ── Allowed reaction emojis ──────────────────────────────────────────────────

const ALLOWED_EMOJIS: &[&str] = &["🏁", "🏆", "🔥", "❤️", "👍", "😮"];

// ── Handler ──────────────────────────────────────────────────────────────────

async fn function_handler(event: Request) -> Result<Response<Body>, Error> {
    let path = event.uri().path().to_string();
    let method = event.method().as_str().to_string();
    info!("{} {}", method, path);

    let table_name = std::env::var("TABLE_NAME")
        .unwrap_or_else(|_| "NxtLAPComm".to_string());

    let config = aws_config::load_defaults(BehaviorVersion::latest()).await;
    let db = CommDynamoDBService::new(DynamoDBClient::new(&config), table_name);

    let response = match (method.as_str(), path.as_str()) {

        // ── Health check ─────────────────────────────────────────────────────
        ("GET", "/health") => json_ok(serde_json::json!({"status": "ok", "service": "NxtLAP Comm"})),

        // ── GET /updates/messages ─────────────────────────────────────────────
        ("GET", "/updates/messages") => {
            let limit = parse_limit(event.uri().query(), 50, 100);
            let messages = db.get_messages(limit).await?;
            info!("Returning {} messages", messages.len());

            // Strip user_ids from reactions before sending to iOS client.
            // The client only needs counts, not who reacted.
            let public: Vec<_> = messages.iter().map(|m| {
                let mut m2 = m.clone();
                for reaction in m2.reactions.values_mut() {
                    reaction.user_ids.clear();
                }
                m2
            }).collect();

            json_ok(serde_json::to_value(&public)?)
        }

        // ── POST /updates/messages/{id}/reactions ─────────────────────────────
        ("POST", p) if p.starts_with("/updates/messages/") && p.ends_with("/reactions") => {
            // Extract message ID from path: /updates/messages/{id}/reactions
            let parts: Vec<&str> = p.split('/').collect();
            // ["", "updates", "messages", "{id}", "reactions"]
            if parts.len() != 5 {
                return Ok(json_error(400, "Invalid path"));
            }
            let message_id = parts[3];

            let body_bytes = event.body().as_ref();
            let req: ReactionRequest = match serde_json::from_slice(body_bytes) {
                Ok(r) => r,
                Err(_) => return Ok(json_error(400, "Invalid request body")),
            };

            if !ALLOWED_EMOJIS.contains(&req.emoji.as_str()) {
                return Ok(json_error(400, "Emoji must be one of: 🏁, 🏆, 🔥, ❤️, 👍, 😮"));
            }

            let updated = match req.action.as_str() {
                "add"    => db.add_reaction(message_id, &req.emoji, &req.user_id).await,
                "remove" => db.remove_reaction(message_id, &req.emoji, &req.user_id).await,
                _        => return Ok(json_error(400, "action must be 'add' or 'remove'")),
            };

            match updated {
                Ok(mut msg) => {
                    // Strip user_ids before returning
                    for reaction in msg.reactions.values_mut() {
                        reaction.user_ids.clear();
                    }
                    json_ok(serde_json::to_value(&msg)?)
                }
                Err(e) if e.to_string().contains("not found") => {
                    json_error(404, &format!("Message not found: {}", message_id))
                }
                Err(e) => {
                    tracing::error!("Reaction error: {}", e);
                    json_error(500, "Internal server error")
                }
            }
        }

        _ => json_error(404, "Not found"),
    };

    Ok(response)
}

// ── Helpers ──────────────────────────────────────────────────────────────────

fn json_ok(body: serde_json::Value) -> Response<Body> {
    Response::builder()
        .status(200)
        .header("Content-Type", "application/json")
        .header("Access-Control-Allow-Origin", "*")
        .body(body.to_string().into())
        .unwrap()
}

fn json_error(status: u16, message: &str) -> Response<Body> {
    Response::builder()
        .status(status)
        .header("Content-Type", "application/json")
        .header("Access-Control-Allow-Origin", "*")
        .body(serde_json::json!({"error": message}).to_string().into())
        .unwrap()
}

fn parse_limit(query: Option<&str>, default: usize, max: usize) -> usize {
    let Some(q) = query else { return default };
    for pair in q.split('&') {
        let mut parts = pair.splitn(2, '=');
        if parts.next() == Some("limit") {
            if let Some(val) = parts.next() {
                if let Ok(n) = val.parse::<usize>() {
                    return n.min(max);
                }
            }
        }
    }
    default
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .with_target(false)
        .without_time()
        .init();

    run(service_fn(function_handler)).await
}
```

### 2.9 `scripts/build.sh`

```bash
#!/bin/bash
set -e

echo "🦀 Building NxtLAP Comm Server (Rust)..."
echo ""

# Check for cargo-lambda
if ! command -v cargo-lambda &> /dev/null; then
    echo "❌ cargo-lambda not found."
    echo "   Install: brew install cargo-lambda"
    exit 1
fi

# IMPORTANT: Use aarch64-unknown-linux-gnu-gcc, NOT Zig.
# Zig 0.15.2 has a regression that breaks crypto libs (ring, aws-lc-rs).
# See SERVER_BUG_CONTEXT.md §4.
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-unknown-linux-gnu-gcc

echo "📦 Building comm-bot..."
cargo lambda build --release --arm64 -p comm-bot --compiler cargo

echo "📦 Building comm-api..."
cargo lambda build --release --arm64 -p comm-api --compiler cargo

echo ""
echo "✅ Build complete!"
echo ""
echo "Binary sizes:"
ls -lh target/lambda/comm-bot/bootstrap | awk '{print $9, $5}'
ls -lh target/lambda/comm-api/bootstrap | awk '{print $9, $5}'
echo ""
echo "Ready to deploy! Run ./scripts/deploy.sh"
```

### 2.10 `scripts/deploy.sh`

```bash
#!/bin/bash
set -e

echo "🚀 Deploying NxtLAP Comm Server to AWS..."
echo ""

REGION="${AWS_REGION:-us-east-1}"
TABLE_NAME="NxtLAPComm"
echo "📍 Region: $REGION"
echo "📋 Table:  $TABLE_NAME"
echo ""

# Build first
./scripts/build.sh

echo ""
echo "☁️  Deploying to AWS..."
echo ""

# Deploy comm-bot (scheduled Lambda — longer timeout for API calls)
echo "1️⃣  Deploying comm-bot..."
cargo lambda deploy \
  --binary-name comm-bot \
  --region "$REGION" \
  --env-var TABLE_NAME=$TABLE_NAME \
  --timeout 120 \
  --memory 256

echo ""

# Deploy comm-api (HTTP Lambda — short timeout)
echo "2️⃣  Deploying comm-api..."
cargo lambda deploy \
  --binary-name comm-api \
  --region "$REGION" \
  --env-var TABLE_NAME=$TABLE_NAME \
  --timeout 30 \
  --memory 256

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Create API Gateway HTTP API in AWS Console → connect to comm-api Lambda"
echo "  2. Create EventBridge rule: rate(5 minutes) → comm-bot Lambda"
echo "  3. Update iOS CommService.swift with the new API Gateway URL"
echo ""
echo "🧪 Manual bot trigger:"
echo "  aws lambda invoke --function-name comm-bot --payload '{}' /tmp/comm-out.json && cat /tmp/comm-out.json"
echo ""
echo "🧪 Test the API:"
echo "  curl <API_GATEWAY_URL>/updates/messages | python3 -m json.tool"
```

---

## 3. DynamoDB Schema

**Table name:** `NxtLAPComm`
**Billing mode:** `PAY_PER_REQUEST` (on-demand — avoids ProvisionedThroughputExceededException at free tier)
**TTL attribute:** `ttl` (N type, Unix timestamp)

| Attribute | DynamoDB Type | Description |
|-----------|--------------|-------------|
| `id` | S (PK) | UUID v4 — primary key |
| `data` | S | Full JSON blob of CommMessage (reactions include user_ids) |
| `timestamp` | S | ISO 8601 — used for sorting in Rust after scan |
| `message_type` | S | `"race_start"`, `"race_started"`, `"race_finished"`, `"general"` |
| `race_id` | S | Race ID from racing calendar API — used for dedup filter |
| `ttl` | N | Unix timestamp 90 days from creation — DynamoDB auto-deletes |

### Example item in DynamoDB

```json
{
  "id":           { "S": "a1b2c3d4-e5f6-7890-abcd-ef1234567890" },
  "data":         { "S": "{\"id\":\"a1b2c3d4...\",\"botName\":\"@nxt_max\",\"content\":\"🏁 The Chinese Grand Prix is about to start at Shanghai International Circuit! (formula1)\",\"timestamp\":\"2026-03-22T14:00:00Z\",\"messageType\":\"raceStart\",\"raceId\":\"2225616\",\"reactions\":{\"🏁\":{\"count\":3,\"userIds\":[\"uuid-1\",\"uuid-2\",\"uuid-3\"]}},\"replyCount\":0}" },
  "timestamp":    { "S": "2026-03-22T14:00:00Z" },
  "message_type": { "S": "race_start" },
  "race_id":      { "S": "2225616" },
  "ttl":          { "N": "1753228800" }
}
```

### Key design decisions

- **Full JSON blob in `data`**: Reactions (including `user_ids`) are stored inside the blob. This avoids complex DynamoDB map attribute updates and keeps the read path simple (scan → deserialize).
- **`user_ids` stripped before API response**: The `comm-api` handler clears `user_ids` from each `ReactionData` before serializing the response. The iOS client only needs counts.
- **Scan + filter in Rust**: At free-tier scale (< a few hundred messages at any time, TTL auto-expires old ones), a full table scan is fast and avoids the cost of a GSI.
- **`PAY_PER_REQUEST`**: The News Server uses provisioned 5 WCU/5 RCU which causes throttling during bulk writes. Comm Server uses on-demand to avoid this.

---

## 4. iOS Design (SwiftUI)

### 4.1 New and Modified Files

**New files:**
- `motorsports/Models/CommMessage.swift`
- `motorsports/Services/CommService.swift`
- `motorsports/ViewModels/CommViewModel.swift`
- `motorsports/Views/UpdatesFeedView.swift`
- `motorsports/Views/MessageBubbleView.swift`
- `motorsports/Views/ReactionBarView.swift`

**Modified files:**
- `motorsports/Views/MainTabView.swift` — replace `.news` tab with `.updates`

---

### 4.2 `CommMessage.swift`

```swift
// motorsports/Models/CommMessage.swift

import Foundation

/// Matches the Rust CommMessage struct (camelCase, reactions stripped of userIds by server).
struct CommMessage: Identifiable, Codable, Equatable {
    let id: String
    let botName: String          // "@nxt_max"
    let content: String
    let timestamp: String        // ISO 8601 string
    let messageType: MessageType
    let raceId: String?
    let reactions: [String: Int] // emoji → count (server strips userIds)
    let replyCount: Int?         // Reserved for future use

    enum MessageType: String, Codable {
        case raceStart    = "raceStart"
        case raceStarted  = "raceStarted"
        case raceFinished = "raceFinished"
        case general      = "general"
    }

    /// Relative or absolute timestamp string for display.
    var formattedTimestamp: String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Try with fractional seconds first, then without
        let date = isoFormatter.date(from: timestamp)
            ?? ISO8601DateFormatter().date(from: timestamp)

        guard let date else { return timestamp }

        let diff = Date().timeIntervalSince(date)
        if diff < 60 {
            return "just now"
        } else if diff < 86400 {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: date, relativeTo: Date())
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}
```

---

### 4.3 `CommService.swift`

```swift
// motorsports/Services/CommService.swift

import Foundation

class CommService {
    // Replace with actual API Gateway URL after deployment
    private let baseURL = "https://REPLACE_WITH_COMM_API_URL"
    private let session = URLSession.shared
    private let cacheKey = "cached_comm_messages"

    func fetchMessages(limit: Int = 50) async throws -> [CommMessage] {
        guard let url = URL(string: "\(baseURL)/updates/messages?limit=\(limit)") else {
            throw URLError(.badURL)
        }

        do {
            let (data, response) = try await session.data(from: url)

            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw APIError.httpError(http.statusCode)
            }

            let decoder = JSONDecoder()
            let messages = try decoder.decode([CommMessage].self, from: data)

            // Cache for offline use
            UserDefaults.standard.set(data, forKey: cacheKey)
            return messages

        } catch {
            // Offline fallback: return cached messages if available
            if let cached = UserDefaults.standard.data(forKey: cacheKey),
               let messages = try? JSONDecoder().decode([CommMessage].self, from: cached) {
                return messages
            }
            throw error
        }
    }

    func addReaction(to messageId: String, emoji: String, userId: String) async throws -> CommMessage {
        return try await sendReaction(messageId: messageId, emoji: emoji, action: "add", userId: userId)
    }

    func removeReaction(from messageId: String, emoji: String, userId: String) async throws -> CommMessage {
        return try await sendReaction(messageId: messageId, emoji: emoji, action: "remove", userId: userId)
    }

    private func sendReaction(
        messageId: String,
        emoji: String,
        action: String,
        userId: String
    ) async throws -> CommMessage {
        guard let url = URL(string: "\(baseURL)/updates/messages/\(messageId)/reactions") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "emoji": emoji,
            "action": action,
            "userId": userId
        ])

        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw APIError.httpError(http.statusCode)
        }

        return try JSONDecoder().decode(CommMessage.self, from: data)
    }
}
```

---

### 4.4 `CommViewModel.swift`

```swift
// motorsports/ViewModels/CommViewModel.swift

import SwiftUI

@MainActor
class CommViewModel: ObservableObject {
    @Published var messages: [CommMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = CommService()

    /// Persistent device ID used as userId for reactions.
    /// Generated once on first launch and stored in UserDefaults.
    var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: "deviceId") {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "deviceId")
        return newId
    }

    func fetchMessages() async {
        isLoading = true
        errorMessage = nil
        do {
            messages = try await service.fetchMessages()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addReaction(to messageId: String, emoji: String) async {
        do {
            let updated = try await service.addReaction(to: messageId, emoji: emoji, userId: deviceId)
            updateMessage(updated)
            HapticManager.shared.trigger(.light)
        } catch {
            // Silently fail — reaction is non-critical
            print("❌ addReaction failed: \(error)")
        }
    }

    func removeReaction(from messageId: String, emoji: String) async {
        do {
            let updated = try await service.removeReaction(from: messageId, emoji: emoji, userId: deviceId)
            updateMessage(updated)
            HapticManager.shared.trigger(.light)
        } catch {
            print("❌ removeReaction failed: \(error)")
        }
    }

    private func updateMessage(_ updated: CommMessage) {
        if let idx = messages.firstIndex(where: { $0.id == updated.id }) {
            messages[idx] = updated
        }
    }
}
```

---

### 4.5 `UpdatesFeedView.swift`

```swift
// motorsports/Views/UpdatesFeedView.swift

import SwiftUI

struct UpdatesFeedView: View {
    @StateObject private var viewModel = CommViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.isLoading && viewModel.messages.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.messages.isEmpty {
                    errorView(error)
                } else if viewModel.messages.isEmpty {
                    emptyView
                } else {
                    feedView
                }
            }
            .navigationTitle("Updates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            await viewModel.fetchMessages()
        }
    }

    // ── Sub-views ────────────────────────────────────────────────────────────

    private var feedView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(message: message, viewModel: viewModel)
                            .id(message.id)
                    }
                }
                .padding(.vertical, 8)
            }
            .refreshable {
                await viewModel.fetchMessages()
            }
            .onAppear {
                // Scroll to newest message (bottom)
                if let last = viewModel.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .racingRed))
                .scaleEffect(1.5)
            Text("Loading updates...")
                .foregroundColor(.secondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.racingRed)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Button {
                Task { await viewModel.fetchMessages() }
            } label: {
                Text("Retry")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.racingRed)
                    .cornerRadius(8)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No updates yet.\nCheck back soon for racing news!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
}
```

---

### 4.6 `MessageBubbleView.swift`

```swift
// motorsports/Views/MessageBubbleView.swift

import SwiftUI

struct MessageBubbleView: View {
    let message: CommMessage
    @ObservedObject var viewModel: CommViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Bot avatar
            ZStack {
                Circle()
                    .fill(Color.racingRed)
                    .frame(width: 36, height: 36)
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Header row: bot name + timestamp
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("@nxt_max")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.racingRed)
                    Text(message.formattedTimestamp)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // Message content
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)

                // Reaction bar
                if !message.reactions.isEmpty {
                    ReactionBarView(message: message, viewModel: viewModel)
                        .padding(.top, 4)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
```

---

### 4.7 `ReactionBarView.swift`

```swift
// motorsports/Views/ReactionBarView.swift

import SwiftUI

private let allowedEmojis = ["🏁", "🏆", "🔥", "❤️", "👍", "😮"]

struct ReactionBarView: View {
    let message: CommMessage
    @ObservedObject var viewModel: CommViewModel
    @State private var showPicker = false

    var body: some View {
        HStack(spacing: 6) {
            // Existing reactions as pill buttons
            ForEach(message.reactions.sorted(by: { $0.key < $1.key }), id: \.key) { emoji, count in
                Button {
                    Task {
                        // Tap existing reaction to remove it (toggle)
                        await viewModel.removeReaction(from: message.id, emoji: emoji)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(emoji)
                            .font(.system(size: 14))
                        Text("\(count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
            }

            // "+" button to open emoji picker
            Button {
                showPicker.toggle()
                HapticManager.shared.selection()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 24)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showPicker) {
            EmojiPickerSheet(message: message, viewModel: viewModel, isPresented: $showPicker)
                .presentationDetents([.height(120)])
        }
    }
}

private struct EmojiPickerSheet: View {
    let message: CommMessage
    @ObservedObject var viewModel: CommViewModel
    @Binding var isPresented: Bool

    var body: some View {
        HStack(spacing: 16) {
            ForEach(allowedEmojis, id: \.self) { emoji in
                Button {
                    Task {
                        await viewModel.addReaction(to: message.id, emoji: emoji)
                        isPresented = false
                    }
                } label: {
                    Text(emoji)
                        .font(.system(size: 28))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}
```

---

### 4.8 `MainTabView.swift` changes

Replace the `.news` tab with `.updates`. The diff is:

```swift
// REMOVE:
enum Tab {
    case home, watch, news, standings, settings
}

// ADD:
enum Tab {
    case home, watch, updates, standings, settings
}

// REMOVE:
NewsView()
    .tabItem {
        Label("News", systemImage: "newspaper.fill")
    }
    .tag(Tab.news)

// ADD:
UpdatesFeedView()
    .tabItem {
        Label("Updates", systemImage: "bell.fill")
    }
    .tag(Tab.updates)
```

The `NewsViewModel` environment object injection in `motorsportsApp.swift` should also be removed
(or kept if `NewsView` is still used elsewhere — check before deleting).

---

## 5. User Identity for Reactions

Reactions are tied to a device-level UUID, not an authenticated user account. This keeps the
feature simple (no auth required) while still preventing duplicate reactions from the same device.

**Flow:**
1. On first app launch, `CommViewModel.deviceId` generates a `UUID().uuidString` and stores it
   in `UserDefaults` under the key `"deviceId"`.
2. Every reaction API call includes `"userId": deviceId` in the request body.
3. The Rust `add_reaction` handler checks `reaction.user_ids.contains(&user_id)` before adding.
4. The `user_ids` array is stored in the `data` JSON blob in DynamoDB but **stripped from the
   API response** — the iOS client only receives counts.

**Limitation:** Uninstalling the app generates a new device ID, so a user could react again after
reinstalling. This is acceptable for a free-tier, no-auth feature.

---

## 6. Deployment Steps

### Prerequisites
- `cargo-lambda` installed: `brew install cargo-lambda`
- `aarch64-unknown-linux-gnu-gcc` installed: `brew install FiloSottile/musl-cross/musl-cross` or via `brew install aarch64-unknown-linux-gnu`
- AWS CLI configured with appropriate IAM permissions
- Rust toolchain with `aarch64-unknown-linux-gnu` target: `rustup target add aarch64-unknown-linux-gnu`

### Step-by-step

**1. Create the Comm Server folder**
```bash
mkdir -p "Server NxtLAP/Comm Server"
cd "Server NxtLAP/Comm Server"
```

**2. Write all Rust files** (as specified in §2 above)

**3. Create the DynamoDB table**
```bash
aws dynamodb create-table \
  --table-name NxtLAPComm \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# Enable TTL
aws dynamodb update-time-to-live \
  --table-name NxtLAPComm \
  --time-to-live-specification Enabled=true,AttributeName=ttl \
  --region us-east-1
```

**4. Build**
```bash
cd "Server NxtLAP/Comm Server"
./scripts/build.sh
```

**5. Deploy Lambda functions**
```bash
./scripts/deploy.sh
```

**6. Create API Gateway HTTP API**
- AWS Console → API Gateway → Create API → HTTP API
- Add integration: Lambda → `comm-api`
- Add route: `ANY /{proxy+}` → `comm-api`
- Deploy to stage `$default`
- Copy the Invoke URL (e.g., `https://abc123.execute-api.us-east-1.amazonaws.com`)

**7. Update iOS `CommService.swift`**
```swift
private let baseURL = "https://abc123.execute-api.us-east-1.amazonaws.com"
```

**8. Create EventBridge rule for comm-bot**
```bash
# Create the rule
aws events put-rule \
  --name "NxtLAPCommBotSchedule" \
  --schedule-expression "rate(5 minutes)" \
  --state ENABLED \
  --region us-east-1

# Get the comm-bot Lambda ARN
LAMBDA_ARN=$(aws lambda get-function \
  --function-name comm-bot \
  --region us-east-1 \
  --query 'Configuration.FunctionArn' \
  --output text)

# Add Lambda as target
aws events put-targets \
  --rule NxtLAPCommBotSchedule \
  --targets "Id=CommBotTarget,Arn=$LAMBDA_ARN" \
  --region us-east-1

# Grant EventBridge permission to invoke the Lambda
aws lambda add-permission \
  --function-name comm-bot \
  --statement-id EventBridgeInvoke \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn $(aws events describe-rule --name NxtLAPCommBotSchedule --region us-east-1 --query 'Arn' --output text) \
  --region us-east-1
```

**9. Verify**
```bash
# Trigger bot manually
aws lambda invoke \
  --function-name comm-bot \
  --payload '{}' \
  /tmp/comm-out.json \
  --region us-east-1
cat /tmp/comm-out.json

# Test API
curl https://abc123.execute-api.us-east-1.amazonaws.com/updates/messages | python3 -m json.tool
```

---

## 7. Free Tier Analysis

### Monthly usage estimates

| Service | Free Tier Limit | Estimated Usage | Notes |
|---------|----------------|-----------------|-------|
| **Lambda invocations** | 1M req/month | ~8,640 (comm-bot) + ~3,000 (comm-api) ≈ **12K** | Bot: 12/hr × 24 × 30 = 8,640. API: ~100 users × 30 opens/month |
| **Lambda compute** | 400,000 GB-s/month | ~2,160 GB-s | 256 MB × 120s × 8,640 invocations / 1024 |
| **DynamoDB reads** | 25 RCU provisioned / 2.5M on-demand | ~90K reads | 100 users × 30 fetches × 30 days |
| **DynamoDB writes** | 25 WCU provisioned / 1M on-demand | ~300 writes | ~3 messages/race × ~100 races/year ÷ 12 |
| **API Gateway** | 1M HTTP API calls/month | ~3,000 | Well within limit |
| **EventBridge** | 14M events/month | ~8,640 | One event per bot invocation |

**Conclusion:** All usage is well within AWS Free Tier limits. The most expensive operation is
Lambda compute for comm-bot (120s timeout), but even at maximum race season density (3 races/week)
the monthly compute stays under 5% of the free tier allowance.

### Cost if free tier expires

At standard pricing:
- Lambda: ~$0.002/month
- DynamoDB on-demand: ~$0.001/month
- API Gateway: ~$0.003/month
- **Total: < $0.01/month**

---

## 8. Known Bugs and Mitigations

These are carried forward from `SERVER_BUG_CONTEXT.md` and applied to the Comm Server:

| Bug | Mitigation |
|-----|-----------|
| **TTL in JSON response breaks iOS decoding** | `#[serde(skip_serializing, skip_deserializing)]` on `ttl: i64` in `CommMessage` |
| **Zig 0.15.2 linker regression** | `build.sh` uses `CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-unknown-linux-gnu-gcc` with `--compiler cargo` |
| **Duplicate bot messages** | `condition_expression("attribute_not_exists(id)")` on `put_item` + `message_exists_for_race()` check before creating |
| **DynamoDB throttling** | Table uses `PAY_PER_REQUEST` (on-demand) instead of provisioned capacity |
| **user_ids leaking to client** | `comm-api` clears `user_ids` from all `ReactionData` before serializing the response |

---

## 9. Sequence Diagrams

### Bot message generation flow

```
EventBridge (rate 5 min)
        │
        ▼
   comm-bot Lambda
        │
        ├─── GET /races/upcoming ──▶ Racing Server API
        │◀── [RaceEvent list] ───────
        │
        │  for each race:
        │    check minutes_until_start
        │    if within window AND no existing message:
        │      ├─── scan NxtLAPComm (filter race_id + message_type) ──▶ DynamoDB
        │      │◀── [exists: bool] ──────────────────────────────────────
        │      │
        │      └─── put_item (condition: attribute_not_exists(id)) ──▶ DynamoDB
        │
        └─── return { created: N }
```

### iOS fetch flow

```
UpdatesFeedView.onAppear / .refreshable
        │
        ▼
  CommViewModel.fetchMessages()
        │
        ▼
  CommService.fetchMessages()
        │
        ├─── GET /updates/messages?limit=50 ──▶ comm-api Lambda
        │                                              │
        │                                    scan NxtLAPComm ──▶ DynamoDB
        │                                    sort asc by timestamp
        │                                    strip user_ids from reactions
        │◀── [CommMessage array] ──────────────────────
        │
        ├─── cache to UserDefaults
        │
        └─── update @Published messages
                │
                ▼
        UpdatesFeedView re-renders
        ScrollViewReader scrolls to bottom
```

### Reaction flow

```
User taps emoji in ReactionBarView
        │
        ▼
  CommViewModel.addReaction(messageId, emoji)
        │
        ▼
  CommService.sendReaction(POST /updates/messages/{id}/reactions)
        │
        ├─── POST body: { emoji, action: "add", userId: deviceId }
        │
        ▼
  comm-api Lambda
        │
        ├─── get_item(id) ──▶ DynamoDB
        │◀── CommMessage ────
        │
        │  check user_ids.contains(userId)
        │  if not: push userId, increment count
        │
        ├─── update_item(data = updated JSON) ──▶ DynamoDB
        │
        └─── return updated CommMessage (user_ids stripped)
                │
                ▼
  CommViewModel.updateMessage(updated)
  HapticManager.shared.trigger(.light)
```

---

## 10. Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a
system — essentially, a formal statement about what the system should do. Properties serve as the
bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Message deduplication

*For any* race ID and message type, calling `save_message` multiple times with the same race ID
and message type should result in exactly one message stored in DynamoDB.

**Validates: Requirements 7.4**

### Property 2: Reaction count consistency

*For any* message and any sequence of add/remove reaction operations, the `count` field in
`ReactionData` must always equal the length of the `user_ids` array.

**Validates: Requirements 13.7, 13.8, 13.9**

### Property 3: Reaction idempotence (add)

*For any* message, emoji, and user ID, calling `add_reaction` twice with the same arguments
should produce the same result as calling it once — the count increments by exactly 1 and the
user ID appears exactly once in `user_ids`.

**Validates: Requirements 13.7, 13.8**

### Property 4: Reaction round-trip (add then remove)

*For any* message with no existing reactions, adding a reaction and then removing it should
return the message to its original state (empty reactions map).

**Validates: Requirements 13.4, 13.5, 13.9**

### Property 5: Message sort order

*For any* set of messages stored in DynamoDB, `get_messages` must return them sorted by
`timestamp` in ascending order (oldest first).

**Validates: Requirements 5.6**

### Property 6: TTL exclusion from API response

*For any* `CommMessage` serialized to JSON, the resulting JSON string must not contain a `"ttl"`
key.

**Validates: Requirements 5.5** (and guards against the known iOS decoding bug)

### Property 7: user_ids exclusion from API response

*For any* `CommMessage` returned by `GET /updates/messages` or `POST .../reactions`, the
`reactions` map values must not contain a `"userIds"` field (counts only).

**Validates: Requirements 13.7** (privacy — device IDs must not be exposed)

### Property 8: Message content completeness

*For any* race event that triggers a bot message, the generated message content must contain
the event name, circuit name, and series name.

**Validates: Requirements 8.1, 8.4, 4.5**

### Property 9: Allowed emoji enforcement

*For any* reaction request with an emoji not in `["🏁", "🏆", "🔥", "❤️", "👍", "😮"]`, the
API must return a 400 error and leave the message unchanged.

**Validates: Requirements 13.2**

### Property 10: Offline cache round-trip

*For any* successful fetch of messages, storing the response in `UserDefaults` and then
decoding it must produce an equivalent array of `CommMessage` objects.

**Validates: Requirements 3.5, 10.5**
