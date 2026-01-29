# 🗺️ Steply — Smart Itinerary Builder Based on Human Mobility & Social Media Data

Steply is an intelligent travel companion that creates **personalized itineraries** using **human mobility patterns**, **social media trends**, and **environmental comfort indices**.  
It helps users explore cities more efficiently — recommending the *right place, at the right time*, for every traveler.

---

## 🚀 Overview

Steply analyzes aggregated movement data and city embeddings to understand how people move across urban areas.  
It combines **AI**, **GIS**, and **social data** to recommend locations that match user interests and contextual factors such as weather, crowd density, and accessibility.

---

## 🌍 Key Features

- **AI-Powered Itinerary Generation** – Builds optimized travel routes from user preferences.  
- **City Comfort Index** – Evaluates temperature, shade, and walking comfort.  
- **Crowd-Aware Routing** – Detects over-tourism zones and suggests alternative spots.  
- **Social Trend Layer** – Uses social media activity to identify trending places.  
- **Interactive Map Interface** – Displays routes, POIs, and user trajectories with dynamic updates.  

---

## 🧠 Technology Stack

| Layer | Tools / Frameworks |
|-------|--------------------|
| **Frontend** | Flutter / FlutterFlow |
| **Backend** | Python (FastAPI) |
| **Mapping & Visualization** | Leaflet / ArcGIS / Google Maps API |
| **Data Sources** | BlogWatcher mobility data, SNS APIs, OpenStreetMap |
| **AI Models** | Area2Vec, contextual embeddings, clustering models |
| **Storage** | PostgreSQL + PostGIS |

---

## 🧩 Architecture


User Input → Data Fetcher (Social APIs, Mobility DB)
           → Area Embedding Engine (Area2Vec / CTLE)
           → Context Analyzer (Weather, Crowding)
           → Route Optimizer
           → Interactive Map UI


## 🧭 Use Cases

- Urban tourists planning short stays.
- Researchers analyzing city livability and accessibility.
- Local governments studying visitor flow and congestion.
- Sustainable travel startups integrating behavioral insights.

---

## 💡 Vision

Steply aims to redefine how people explore cities by **making human behavior actionable** through data.  
Our long-term goal is to build **behavior-informed environmental suitability models** to improve tourism, mobility, and sustainability worldwide.

---

## 🧑‍💻 Authors

**Nodira Tillayeva**  
Graduate School of Engineering, Nagoya University  
Ubiquitous Computing Laboratory  

---

## 🪪 License

This project is released under the [MIT License](LICENSE).

---

## 🌐 Links

- Project Demo: *Coming soon*  
- Research Paper: *In progress*  
- Contact: `steply.research@gmail.com`

---

© 2025 Steply Team. All rights reserved.
