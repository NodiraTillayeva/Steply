import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class AppConstants {
  AppConstants._();

  // Nagoya map defaults
  static const LatLng nagoyaCenter = LatLng(35.1815, 136.9066);
  static const double defaultZoom = 13.0;
  static const double minZoom = 10.0;
  static const double maxZoom = 18.0;

  // Nagoya region bounds
  static const double minLatitude = 35.1;
  static const double maxLatitude = 35.2;
  static const double minLongitude = 136.8;
  static const double maxLongitude = 136.9;

  // Map tile URLs
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String esriSatelliteTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  // Heatmap settings
  static const double heatmapRadius = 25.0;
  static const double heatmapBlur = 15.0;
  static const double heatmapOpacity = 0.6;

  // Comfort index thresholds
  static const double lowComfortThreshold = 0.3;
  static const double mediumComfortThreshold = 0.6;
  static const double highComfortThreshold = 0.8;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  static const Duration panelAnimation = Duration(milliseconds: 500);
}

// ─── Spacing System (8pt grid) ───

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;
}

// ─── Premium Color System ───

class AppColors {
  AppColors._();

  // Primary — Deep Indigo
  static const Color primary = Color(0xFF3D5AF1);
  static const Color primaryDark = Color(0xFF2A3EB1);
  static const Color primaryLight = Color(0xFFE8EBFF);
  static const Color primarySoft = Color(0xFFF0F2FF);

  // Accent — Warm Teal (AI intelligence)
  static const Color accent = Color(0xFF14B8A6);
  static const Color accentLight = Color(0xFFCCFBF1);
  static const Color accentSoft = Color(0xFFF0FDFA);

  // Coral — Warm emphasis
  static const Color coral = Color(0xFFFF6B6B);
  static const Color coralLight = Color(0xFFFFE0E0);

  // Emerald — low crowd / success / optimal
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFFD1FAE5);

  // Amber — warm / sunny / moderate
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFEF3C7);

  // Backgrounds — Warm, not flat
  static const Color bgLight = Color(0xFFF8F9FE);
  static const Color bgDark = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceElevated = Color(0xFFFCFCFF);

  // Glass effects
  static const Color glassWhite = Color(0xCCFFFFFF); // 80% white
  static const Color glassWhiteSubtle = Color(0x99FFFFFF); // 60% white
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassDark = Color(0x331A2035);

  // Text hierarchy
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Comfort index
  static const Color lowComfort = Color(0xFFEF4444);
  static const Color mediumComfort = Color(0xFFF59E0B);
  static const Color highComfort = Color(0xFF10B981);

  // Heatmap gradient (softer, less harsh)
  static const List<Color> heatmapGradient = [
    Color(0x00FFFFFF),
    Color(0x3014B8A6),
    Color(0x50F59E0B),
    Color(0x70FF6B6B),
    Color(0x90EF4444),
  ];

  // POI categories
  static const Color poiAttraction = Color(0xFF8B5CF6);
  static const Color poiRestaurant = Color(0xFFF97316);
  static const Color poiShopping = Color(0xFF06B6D4);
  static const Color poiTransport = Color(0xFF64748B);

  // Wishlist / Saved
  static const Color wishlistMarker = Color(0xFFEC4899);
  static const Color saved = Color(0xFFEC4899);

  // OpenAI
  static const Color openAi = Color(0xFF10A37F);

  // Weather colors
  static const Color weatherSunny = Color(0xFFF59E0B);
  static const Color weatherCloudy = Color(0xFF94A3B8);
  static const Color weatherRainy = Color(0xFF3B82F6);
  static const Color weatherSnowy = Color(0xFFE2E8F0);
  static const Color weatherStormy = Color(0xFF6366F1);
  static const Color weatherFoggy = Color(0xFFCBD5E1);

  // Recommendations
  static const Color recBestTime = Color(0xFF10B981);
  static const Color recQuietArea = Color(0xFF3B82F6);
  static const Color recWeatherOptimal = Color(0xFFF59E0B);
  static const Color recAvoidCrowd = Color(0xFFEF4444);

  // Insights
  static const Color insightVibe = Color(0xFF8B5CF6);
  static const Color insightTip = Color(0xFF14B8A6);
  static const Color insightHighlight = Color(0xFFF97316);
  static const Color insightCaveat = Color(0xFFEF4444);
  static const Color seasonalBest = Color(0xFF10B981);
  static const Color seasonalWorst = Color(0xFFCBD5E1);
  static const Color statusQuiet = Color(0xFF10B981);
  static const Color statusModerate = Color(0xFFF59E0B);
  static const Color statusBusy = Color(0xFFEF4444);

  // Neutral
  static const Color surface = Color(0xFFF8F9FE);
  static const Color background = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFDC2626);

  // ─── Premium Gradients ───

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3D5AF1), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coralGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFF8F9FE), Color(0xFFF0F2FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient warmBgGradient = LinearGradient(
    colors: [Color(0xFFF8F9FE), Color(0xFFFFF7ED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ─── Box Shadows (Depth levels) ───

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> softGlow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.15),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'STEPLY';
  static const String appTagline = 'Your AI Travel Companion';

  // Navigation
  static const String navMap = 'Explore';
  static const String navItinerary = 'Journey';
  static const String navAnalysis = 'Insights';
  static const String navWishlist = 'Wishlist';
  static const String navExplore = 'Explore';
  static const String navInsights = 'Insights';
  static const String navProfile = 'Profile';

  // Map
  static const String mapTitle = 'Nagoya Explorer';
  static const String mapLoading = 'Loading map...';
  static const String mapError = 'Failed to load map';
  static const String mapSearch = 'Search places in Nagoya...';

  // Itinerary
  static const String itineraryTitle = 'Your Journey';
  static const String itineraryEmpty = 'Your journey starts here.';
  static const String itineraryEmptySub =
      'Add your first place and we\'ll optimize it for you.';
  static const String itineraryAdd = 'Add Stop';
  static const String itineraryCreate = 'Name Your Journey';
  static const String planATrip = 'Plan a Trip';
  static const String yourTrip = 'Your trip';
  static const String stops = 'stops';
  static const String addStop = 'Add Stop';
  static const String whenAreYouGoing = 'When are you going?';
  static const String today = 'Today';
  static const String thisWeekend = 'This Weekend';
  static const String thisMonth = 'This Month';
  static const String chooseADate = 'Choose a date';
  static const String organizeWithAi = 'Organize with AI';
  static const String organizing = 'Crafting your perfect itinerary...';

  // Comfort
  static const String comfortTitle = 'Crowd Pulse';
  static const String comfortLow = 'Crowded';
  static const String comfortMedium = 'Moderate';
  static const String comfortHigh = 'Comfortable';

  // Insights
  static const String insightsTitle = 'City Intelligence';
  static const String crowdIntelligence = 'Crowd Intelligence';
  static const String temporalPatterns = 'Temporal Patterns';
  static const String weatherCorrelation = 'Weather & Movement';
  static const String hourlyFlow = 'Hourly Flow';
  static const String weeklyRhythm = 'Weekly Rhythm';
  static const String activityHeatmap = 'Activity Heatmap';
  static const String smartRecommendations = 'Smart Recommendations';
  static const String analysisWeatherUnavailable = 'Weather data unavailable';

  // AI Personality
  static const String aiInsight = 'AI Insight';
  static const String crowdPulse = 'Crowd Pulse';
  static const String movementIntelligence = 'Movement Intelligence';
  static const String smartTiming = 'Smart Timing';

  // OpenAI
  static const String openAiApiKey =
      '';

  // Place Analysis Sheet
  static const String analysisRightNow = 'Right Now';
  static const String analysisBestTimes = 'Best Times to Visit';
  static const String analysisSeasonalGuide = 'Seasonal Weather Guide';
  static const String analysisLocalTips = 'Local Tips & Insights';
  static const String statusQuiet = 'Quiet';
  static const String statusModerate = 'Moderate';
  static const String statusBusy = 'Busy';
  static const String getAiInsights = 'Get AI Insights';
  static const String bestMonths = 'Best Months';
  static const String nextQuietWeekend = 'Next Quiet Weekend';

  // Profile
  static const String profileTitle = 'Profile';
  static const String savedPlaces = 'Saved Places';
  static const String preferences = 'Preferences';
  static const String settings = 'Settings';

  // General
  static const String loading = 'Loading...';
  static const String error = 'An error occurred';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String delete = 'Delete';
}
