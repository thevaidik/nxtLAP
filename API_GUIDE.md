# 🏎️ NxtLAP Racing Server API

This API provides a unified racing calendar for major motorsport series (F1, MotoGP, IndyCar, etc.). It aggregates data from TheSportsDB and caches it in DynamoDB for high performance.

## 🚀 Base URL
```
https://brto98doc9.execute-api.us-east-1.amazonaws.com
```

## 📡 Endpoints

### 1. Health Check
Check if the server is running.
- **GET** `/health`
- **Response:**
  ```json
  { "status": "ok" }
  ```

### 2. Get All Races
Retrieve all cached racing events for the current season (2026).
- **GET** `/races`
- **Response:** Array of Event objects (mixed series).

### 3. Get Races by Series
Filter events by a specific racing series.
- **GET** `/races/{series_slug}`
- **Supported Slugs:**
  - `formula1`
  - `motogp`
  - `indycar`
  - `wrc` (World Rally Championship)
  - `imsa`
  - `supergt`
  - `britishgt`
  - `btcc` (British Touring Car)
  - `v8supercars`

- **Example:**
  `GET /races/formula1`

### 4. Get Upcoming Races
Retrieve the next 15 scheduled races across all series, sorted by date.
- **GET** `/races/upcoming`

## 📦 Data Model

### Event Object
```json
{
  "id": "2225616",
  "series": "formula1",
  "event_name": "Chinese Grand Prix Sprint",
  "circuit": "Shanghai International Circuit",
  "date": "2025-03-22T00:00:00Z",
  "country": "China",
  "season": "2025",
  "round": 2,
  "description": "The Chinese Grand Prix Sprint...",
  "ttl": 1770022430
}
```

## 🛠️ Maintenance

### Manual Data Refresh
The server refreshes automatically, but you can force an update via AWS CLI:
```bash
aws lambda invoke --function-name data-fetcher response.json
```

### Deployment
To deploy updates to the Rust code:
```bash
./scripts/deploy-rust.sh 3
```
*(Where `3` is the API Key)*
