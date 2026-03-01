# Steply — Smart Itinerary Builder Based on Human Mobility & Social Media Data

Steply is an intelligent travel companion that creates **personalized itineraries** using **human mobility patterns**, **social media trends**, and **environmental comfort indices**.
It helps users explore cities more efficiently — recommending the *right place, at the right time*, for every traveler.

---

## Overview

Steply analyzes 528,000+ aggregated movement records and city embeddings to understand how people move across urban areas.
It combines **AI**, **GIS**, and **social data** to recommend locations that match user interests and contextual factors such as weather, crowd density, and accessibility.

---

## Key Features

### Explore (Home Tab)
- **Interactive Heatmap** — Visualizes crowd density across Nagoya using pre-computed mobility data (528K+ records).
- **Points of Interest** — Browse categorized POIs (attractions, restaurants, shopping, transport) with real-time comfort scores.
- **City Comfort Index** — Evaluates crowd intensity at any location based on nearby heatmap data.

### My Trip (Itinerary Tab)
- **AI-Powered Scheduling** — Organizes your stops into an optimized itinerary using crowd heatmap data.
- **Time-Aware Planning** — Only suggests visit times that haven't passed yet (accounts for current time of day).
- **Multi-Day Support** — Spreads stops across all trip days for multi-day trips.
- **Crowd-Optimized** — Uses a greedy constraint-satisfaction algorithm to assign each stop to its least-crowded available time slot.

### Discover (Analysis Tab)
- **Temporal Analysis** — Hourly and daily crowd distribution charts revealing city movement patterns.
- **Popular Areas** — 50 identified hotspots ranked by visit frequency with peak day/hour info.
- **Weather Integration** — Real-time weather data combined with crowd patterns for smart recommendations.
- **AI Recommendations** — Best exploration times, quiet areas, weather-optimal hours, and peak crowd warnings.

### Saved (Wishlist Tab)
- **URL Extraction** — Paste any URL (TikTok, Instagram, blogs, etc.) and AI extracts place names, coordinates, descriptions, and event dates.
- **Screenshot Analysis** — Take a screenshot of a social media post and AI identifies the places mentioned.
- **Video Transcription** — For video content, AI transcribes audio to extract location mentions.
- **Add to Trip** — One-tap to add saved places to your current trip or start a new one.
- **Map View** — Toggle between list and map view of all saved places.

### Share Extension
- Share links directly from any app (Safari, TikTok, Instagram) to Steply for instant place extraction.

---

## Technology Stack

| Layer | Tools / Frameworks |
|-------|--------------------|
| **Frontend** | Flutter (Dart) with BLoC state management |
| **Navigation** | GoRouter with StatefulShellRoute (4-tab layout) |
| **AI / Vision** | Google Gemini 2.5 Flash (vision, audio transcription, structured JSON output) |
| **Mapping** | Flutter Map + OpenStreetMap tiles |
| **Weather** | Open-Meteo API (hourly forecasts + current conditions) |
| **Data** | Pre-computed mobility analytics from 528K+ movement records |
| **DI** | GetIt + Injectable |
| **Storage** | SharedPreferences (saved itineraries), in-memory (wishlist) |

---

## Architecture

```
lib/
├── core/
│   ├── constants/       # App-wide constants, colors, strings
│   ├── design_system/   # Reusable UI components (bottom nav, etc.)
│   ├── di/              # Dependency injection setup
│   ├── router/          # GoRouter configuration
│   ├── services/        # Sharing intent service
│   └── theme/           # Light/dark theme definitions
├── features/
│   ├── analysis/        # Discover tab + Itinerary tab
│   │   ├── data/        # Datasources (mobility JSON, weather API)
│   │   ├── domain/      # Entities, repositories, use cases
│   │   └── presentation/# BLoCs (ComfortBloc, ItineraryBloc) + pages
│   ├── map_view/        # Home tab (map, heatmap, POIs)
│   │   ├── data/        # Location repository, heatmap datasource
│   │   ├── domain/      # POI entities, use cases
│   │   └── presentation/# MapBloc + MapPage
│   ├── shared/          # Shell page with bottom navigation
│   └── wishlist/        # Saved tab
│       ├── data/        # Gemini API datasource, HTML scrapers
│       ├── domain/      # WishlistPlace entity, use cases
│       └── presentation/# WishlistBloc + pages + analysis sheet
└── main.dart            # App entry point with MultiBlocProvider
```

---

## Getting Started

### Prerequisites
- Flutter SDK (3.x+)
- Xcode (for iOS deployment)
- A Google Gemini API key

### Setup
```bash
# Clone the repository
git clone https://github.com/NodiraTillayeva/Steply.git
cd Steply

# Install dependencies
flutter pub get

# Create .env file with your API key
echo "GEMINI_API_KEY=your_key_here" > .env

# Run on device
flutter run --dart-define-from-file=.env
```

---

## Use Cases

- Urban tourists planning short stays in Nagoya.
- Researchers analyzing city livability and accessibility.
- Local governments studying visitor flow and congestion.
- Travelers discovering places from social media content.

---

## Vision

Steply aims to redefine how people explore cities by **making human behavior actionable** through data.
Our long-term goal is to build **behavior-informed environmental suitability models** to improve tourism, mobility, and sustainability worldwide.

---

## Authors

**Nodira Tillayeva**
Graduate School of Engineering, Nagoya University
Ubiquitous Computing Laboratory

---

## License

This project is released under the [MIT License](LICENSE).

---

© 2025 Steply Team. All rights reserved.
