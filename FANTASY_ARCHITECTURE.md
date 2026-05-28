# NxtLAP Fantasy System Architecture & Game Mechanics

This document outlines the architecture, database schema, and core game mechanics for the multi-series fantasy motorsports system built into NxtLAP. The design draws inspiration from modern social sports applications (like the "Real" app) to create a high-engagement, yield-based virtual economy.

## 1. Core Game Mechanics: The "Real App" Model

### The Economy (Nxt & Social Karma)
*   **Nxt (Primary Currency):** The virtual currency used to purchase Driver Cards, Team Cards, and Card Packs. Nxt is earned passively by holding cards of drivers who perform well in real life, or by ranking high on global leaderboards.
*   **Karma/Rep (Social Currency):** Earned by actively engaging with the app—commenting on the live race feed, voting in pre-race polls, and reacting to live events. High Karma can be converted into Nxt bonuses or exclusive Card Packs.

### Driver & Team Cards
*   **The "Draft" as an Investment:** Instead of picking a new draft roster every week from scratch, users "invest" their Nxt into Driver Cards (e.g., a Max Verstappen card). If you own a driver's card, every time that driver races and scores points in real life, your card generates **Nxt** directly into your wallet.
*   **Multipliers & Real Ratings:** Each driver has a base rating. Outstanding performances (e.g., Fastest Lap, winning from a lower grid position) yield bonus Nxt.
*   **Card Upgrades (Tiers):** Users can collect "Moment Cards" (e.g., "Alonso's Turn 1 Overtake") to upgrade their Driver Cards (Common -> Rare -> Iconic). Higher tiers provide a permanent multiplier to the Nxt that the card generates.

## 2. Backend Architecture

A microservices-oriented approach is utilized to handle high-frequency live data across multiple series (F1, IMSA, etc.) and process real-time asset yields.

### Services
1.  **User & Wallet Service:** Strictly transactional service that manages Nxt balances, Karma scores, and processes microtransactions.
2.  **Live Data Ingestion Service:** Connects to third-party APIs (Sportradar, F1 Timing, IMSA timing). It normalizes incoming data and ensures low-latency event streaming to trigger live in-app notifications.
3.  **Yield Engine:** A stateless rules engine that listens to live race events. When an event happens (e.g., Driver X completes an overtake), the engine finds all users who own Driver X's card and dispatches Nxt to their wallets instantly based on the series' `yield_rules.json`.
4.  **Asset / Inventory Manager:** Tracks user ownership of Driver and Moment Cards, the tier of those cards, and handles the logic for upgrading cards.

## 3. Database Schema (Hybrid Approach)

A hybrid database approach is used to balance strict ledger consistency with flexible game rules.

### Relational (PostgreSQL) - Ledgers & Inventory
Used for strict ACID compliance on currency and ownership.
*   `users`: (id, username, nxt_balance, karma_balance)
*   `transactions`: (id, user_id, amount, currency_type, type [e.g., card_purchase, race_yield], timestamp)
*   `user_inventory`: (id, user_id, asset_id, asset_type [driver_card, moment_card], tier_level)

### Document (MongoDB / Firebase) - Assets & Rules
Used for highly variable, series-specific data.
*   `assets`: Driver and Team metadata across F1, IMSA, etc. Includes dynamic pricing values.
*   `yield_rules`: JSON configurations defining how real-world actions translate to Nxt for different series.
    *   *Example (F1):* `{"event": "fastest_lap", "yield": 50}`
    *   *Example (IMSA):* `{"event": "class_win", "yield": 100}`
*   `live_events`: A stream of race events used to trigger social polls and Nxt payouts.

## 4. UI/UX Flow

1.  **The Card Market:** A sleek store interface where users spend Nxt to buy specific Driver Cards or open randomized Packs.
2.  **My Garage (Inventory):** A visual showcase of the user's collected cards, displaying their tiers and the total Nxt they have generated over the season.
3.  **Live Race Hub:** A real-time chat and play-by-play screen where users earn Karma for reacting to events and see live Nxt drops as their owned drivers perform on track.
4.  **Upgrade Forge:** An interface where users combine Moment Cards to level up their Driver Cards with satisfying micro-animations.
