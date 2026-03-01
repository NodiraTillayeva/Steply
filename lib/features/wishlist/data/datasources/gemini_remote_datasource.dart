import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:steply/core/constants/app_constants.dart';
import 'package:steply/features/analysis/domain/entities/place_insights.dart';
import 'package:steply/features/wishlist/domain/entities/wishlist_place.dart';

abstract class GeminiRemoteDatasource {
  Future<List<WishlistPlace>> extractPlacesFromUrl(String url);
  Future<List<WishlistPlace>> extractPlacesFromImage(String base64Image);
  Future<PlaceInsights> getPlaceInsights({
    required String placeName,
    String? sourceUrl,
    String? rawContent,
    String? description,
  });
}

class GeminiRemoteDatasourceImpl implements GeminiRemoteDatasource {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.5-flash';
  static const int _maxContentChars = 12000;

  String get _endpoint =>
      '$_baseUrl/models/$_model:generateContent?key=${AppStrings.geminiApiKey}';

  static const _browserHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9,ja;q=0.8',
  };

  static const _mobileHeaders = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 '
            '(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9,ja;q=0.8',
  };

  static const String _systemPrompt = '''
You are a place extraction assistant. Extract SPECIFIC places — individual venues, shops, restaurants, cafes, attractions, or named locations — mentioned or featured in the content.

IMPORTANT RULES:
- Always extract the SPECIFIC venue or establishment, NOT the general city/area. For example, if content is about "Round 1 arcade in Nagoya", extract "Round 1 Nagoya" (the specific branch), NOT "Nagoya" (the city).
- Use the exact street address or branch location coordinates, not city center coordinates.
- If a chain store or franchise is mentioned, include the specific branch/location (e.g. "Round 1 Sakae" not just "Round 1").
- Never return a generic city or region as a place unless the content is specifically about visiting that city as a whole destination.

For each place, provide:
- placeName: the specific name of the venue/establishment (include branch/area name if known)
- latitude: precise latitude coordinate of THIS specific location (not city center)
- longitude: precise longitude coordinate of THIS specific location (not city center)
- description: a brief description of the place (what it is, why it's mentioned)
- eventDate: if there's an event or limited-time thing, the start date in ISO 8601 format (YYYY-MM-DD), otherwise null
- eventEndDate: if there's an event end date, in ISO 8601 format (YYYY-MM-DD), otherwise null
- localTips: an array of short practical tips extracted from the content (e.g. "Cash only", "Famous for matcha parfait", "Long wait on weekends", "Reservation required"). If no tips found, use an empty array.

Respond ONLY with a JSON array. Example:
[
  {
    "placeName": "Komeda Coffee Sakae",
    "latitude": 35.1706,
    "longitude": 136.9082,
    "description": "Popular Nagoya-born coffee chain, famous for morning set with ogura toast",
    "eventDate": null,
    "eventEndDate": null,
    "localTips": ["Try the morning set before 11am", "Shiro-noir is the signature dessert"]
  }
]

If no places are found, respond with an empty array: []
''';

  static const String _insightsPrompt = '''
You are a local travel insights assistant who deeply analyzes social media content (TikTok captions, hashtags, comments, Instagram posts, blog articles) to extract genuine, specific insights about a place.

Your job is NOT to give generic travel advice. Instead:
- Extract SPECIFIC details from the provided source content (captions, comments, hashtags, descriptions)
- If comments mention specific dishes, prices, wait times, or experiences — include those exact details
- If hashtags reveal trends or themes — incorporate them
- If the content shows specific things (arcade games, food items, activities) — mention them by name
- If no source content is available, use your knowledge but be specific to THIS exact location/branch

Respond ONLY with a JSON object:
- localTips: array of SPECIFIC, actionable tips drawn from the source content and real visitor experiences (e.g. "The crane game section on 3F has better odds", "¥500 all-you-can-play deal on weekdays before 6pm", "The purikura machines are on 2F"). Be concrete, not generic.
- bestSeason: when to visit and why, specific to this place (e.g. "Weekday evenings are least crowded" or "Summer break brings student crowds")
- vibe: describe the actual atmosphere based on what the content shows — who goes there, what the energy is like, what makes it unique
- highlights: array of SPECIFIC things people love, pulled from the content (specific menu items, games, photo spots, experiences — not generic "great atmosphere")
- caveat: real warnings from the content or known issues (e.g. "Machines eat coins sometimes", "No re-entry after 10pm", "Gets extremely loud on weekends"). Empty string if nothing notable.

Be detailed and authentic. A good insight reads like advice from a local friend, not a guidebook.
''';

  // ---------------------------------------------------------------------------
  // Gemini API helper
  // ---------------------------------------------------------------------------

  /// Core Gemini API call. Returns the text response.
  Future<String> _callGemini({
    required String systemPrompt,
    required String userText,
    List<String> imageBase64s = const [],
    String? audioBase64,
    String? audioMimeType,
    double temperature = 0.1,
    int maxOutputTokens = 2000,
    bool jsonResponse = true,
  }) async {
    final parts = <Map<String, dynamic>>[
      {'text': userText},
    ];

    for (final img in imageBase64s) {
      parts.add({
        'inlineData': {
          'mimeType': 'image/jpeg',
          'data': img,
        },
      });
    }

    if (audioBase64 != null) {
      parts.add({
        'inlineData': {
          'mimeType': audioMimeType ?? 'audio/mp4',
          'data': audioBase64,
        },
      });
    }

    final generationConfig = <String, dynamic>{
      'temperature': temperature,
      'maxOutputTokens': maxOutputTokens,
    };
    if (jsonResponse) {
      generationConfig['responseMimeType'] = 'application/json';
    }

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': parts,
        },
      ],
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'generationConfig': generationConfig,
    });

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['error']?['message'] ?? 'Unknown API error';
      throw Exception('Gemini API error: $errorMessage');
    }

    final responseBody = jsonDecode(response.body);
    final candidates = responseBody['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini API error: No candidates in response');
    }
    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final responseParts = content?['parts'] as List<dynamic>?;
    if (responseParts == null || responseParts.isEmpty) {
      throw Exception('Gemini API error: No parts in response');
    }
    return responseParts[0]['text'] as String;
  }

  // ---------------------------------------------------------------------------
  // Place extraction from URL
  // ---------------------------------------------------------------------------

  @override
  Future<List<WishlistPlace>> extractPlacesFromUrl(String url) async {
    final lower = url.toLowerCase();
    String extractedContent;
    List<String> videoFrames;
    String? imageUrl;

    if (lower.contains('tiktok.com')) {
      (extractedContent, videoFrames, imageUrl) =
          await _fetchTikTokContent(url);
    } else if (lower.contains('instagram.com')) {
      (extractedContent, videoFrames, imageUrl) =
          await _fetchInstagramContent(url);
    } else if (lower.contains('twitter.com') ||
        lower.contains('x.com') ||
        lower.contains('facebook.com') ||
        lower.contains('threads.net') ||
        lower.contains('youtube.com') ||
        lower.contains('youtu.be')) {
      (extractedContent, videoFrames, imageUrl) =
          await _fetchSocialMediaContent(url);
    } else {
      (extractedContent, videoFrames, imageUrl) =
          await _fetchWebpageContent(url);
    }

    final userPrompt =
        'Extract places from this content (source URL: $url):\n\n$extractedContent';

    // Download OG image and convert to base64
    String? imageBase64;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final imgResponse =
            await http.get(Uri.parse(imageUrl), headers: _mobileHeaders);
        if (imgResponse.statusCode == 200 &&
            imgResponse.bodyBytes.length < 5 * 1024 * 1024) {
          imageBase64 = base64Encode(imgResponse.bodyBytes);
        }
      } catch (_) {}
    }

    final allImages = <String>[];
    if (imageBase64 != null) allImages.add(imageBase64);
    allImages.addAll(videoFrames);

    final content = await _callGemini(
      systemPrompt: _systemPrompt,
      userText: userPrompt,
      imageBase64s: allImages,
    );

    return _parsePlaces(content, url, extractedContent, imageUrl: imageUrl);
  }

  // ---------------------------------------------------------------------------
  // Place extraction from image
  // ---------------------------------------------------------------------------

  @override
  Future<List<WishlistPlace>> extractPlacesFromImage(
      String base64Image) async {
    final content = await _callGemini(
      systemPrompt: _systemPrompt,
      userText:
          'Extract all places, locations, restaurants, or venues visible in this screenshot.',
      imageBase64s: [base64Image],
    );

    return _parsePlaces(content, 'screenshot', null);
  }

  // ---------------------------------------------------------------------------
  // Place insights
  // ---------------------------------------------------------------------------

  @override
  Future<PlaceInsights> getPlaceInsights({
    required String placeName,
    String? sourceUrl,
    String? rawContent,
    String? description,
  }) async {
    String contextContent = '';
    String? imageUrl;

    if (sourceUrl != null &&
        sourceUrl.isNotEmpty &&
        sourceUrl != 'screenshot') {
      try {
        final result = await _fetchInsightsContent(sourceUrl);
        contextContent = result.$1;
        imageUrl = result.$2;
      } catch (_) {
        contextContent = rawContent ?? '';
      }
    } else if (rawContent != null && rawContent.isNotEmpty) {
      contextContent = rawContent;
    }

    final userText = StringBuffer();
    userText.writeln('Place: $placeName');
    if (description != null && description.isNotEmpty) {
      userText.writeln('Description: $description');
    }
    if (sourceUrl != null && sourceUrl.isNotEmpty) {
      userText.writeln('Source URL: $sourceUrl');
    }
    if (contextContent.isNotEmpty) {
      final content = contextContent.length > 6000
          ? contextContent.substring(0, 6000)
          : contextContent;
      userText.writeln(
          '\n--- SOURCE CONTENT (from social media / webpage) ---\n$content');
    }
    userText.writeln(
        '\nAnalyze the above content deeply. Extract specific details, not generic advice.');

    // Download image and convert to base64
    final insightImages = <String>[];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final imgResponse =
            await http.get(Uri.parse(imageUrl), headers: _mobileHeaders);
        if (imgResponse.statusCode == 200 &&
            imgResponse.bodyBytes.length < 5 * 1024 * 1024) {
          insightImages.add(base64Encode(imgResponse.bodyBytes));
        }
      } catch (_) {}
    }

    final content = await _callGemini(
      systemPrompt: _insightsPrompt,
      userText: userText.toString(),
      imageBase64s: insightImages,
      temperature: 0.3,
    );

    final stripped = _stripMarkdownFences(content);
    final json = jsonDecode(stripped) as Map<String, dynamic>;

    return PlaceInsights(
      localTips: (json['localTips'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          const [],
      bestSeason: json['bestSeason'] as String? ?? '',
      vibe: json['vibe'] as String? ?? '',
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((h) => h.toString())
              .toList() ??
          const [],
      caveat: json['caveat'] as String? ?? '',
    );
  }

  // ---------------------------------------------------------------------------
  // JSON parsing helpers
  // ---------------------------------------------------------------------------

  List<WishlistPlace> _parsePlaces(
    String content,
    String source,
    String? extractedContent, {
    String? imageUrl,
  }) {
    final stripped = _stripMarkdownFences(content);
    final List<dynamic> places = jsonDecode(stripped);
    final now = DateTime.now();

    final truncatedContent =
        extractedContent != null && extractedContent.length > 2000
            ? extractedContent.substring(0, 2000)
            : extractedContent;

    return places.map((p) {
      final tips = (p['localTips'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          const [];

      return WishlistPlace(
        id: '${now.millisecondsSinceEpoch}_${p['placeName'].hashCode}',
        name: p['placeName'] as String,
        latitude: (p['latitude'] as num).toDouble(),
        longitude: (p['longitude'] as num).toDouble(),
        description: p['description'] as String,
        eventDate: p['eventDate'] != null
            ? DateTime.tryParse(p['eventDate'] as String)
            : null,
        eventEndDate: p['eventEndDate'] != null
            ? DateTime.tryParse(p['eventEndDate'] as String)
            : null,
        sourceUrl: source,
        addedAt: now,
        localTips: tips,
        rawSourceContent: truncatedContent,
        imageUrl: imageUrl,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Content fetching (unchanged from OpenAI version)
  // ---------------------------------------------------------------------------

  /// Fetch TikTok content via oEmbed API + page HTML parsing
  Future<(String, List<String>, String?)> _fetchTikTokContent(
      String url) async {
    final parts = <String>[];
    var videoFrames = <String>[];
    String? imageUrl;

    // 1. oEmbed API — most reliable for TikTok
    try {
      final oembedUrl =
          'https://www.tiktok.com/oembed?url=${Uri.encodeComponent(url)}';
      final oembedResponse = await http.get(Uri.parse(oembedUrl));
      if (oembedResponse.statusCode == 200) {
        final data = jsonDecode(oembedResponse.body) as Map<String, dynamic>;
        final title = data['title'] as String? ?? '';
        final author = data['author_name'] as String? ?? '';
        final authorId = data['author_unique_id'] as String? ?? '';
        final thumbnail = data['thumbnail_url'] as String?;
        if (thumbnail != null && thumbnail.isNotEmpty) {
          imageUrl = thumbnail;
        }
        if (title.isNotEmpty) {
          parts.add('VIDEO CAPTION: $title');
        }
        if (author.isNotEmpty) {
          parts.add('AUTHOR: $author (@$authorId)');
        }
        final html = data['html'] as String? ?? '';
        if (html.isNotEmpty) {
          final citeMatch = RegExp(r'cite="([^"]+)"').firstMatch(html);
          if (citeMatch != null) {
            parts.add('CANONICAL URL: ${citeMatch.group(1)}');
          }
        }
      }
    } catch (_) {}

    // 2. Try fetching with mobile user-agent
    String? fetchedHtml;
    try {
      final response =
          await http.get(Uri.parse(url), headers: _mobileHeaders);
      if (response.statusCode == 200) {
        fetchedHtml = response.body;
      }
    } catch (_) {}

    // 3. Fallback: try desktop user-agent
    if (fetchedHtml == null) {
      try {
        final response =
            await http.get(Uri.parse(url), headers: _browserHeaders);
        if (response.statusCode == 200) {
          fetchedHtml = response.body;
        }
      } catch (_) {}
    }

    // 4. Parse whatever HTML we got
    if (fetchedHtml != null) {
      final rehydrationData = _extractRehydrationData(fetchedHtml);
      if (rehydrationData != null) {
        parts.add(rehydrationData);
      }

      final nextData = _extractNextData(fetchedHtml);
      if (nextData != null) {
        parts.add(nextData);
      }

      final ogData = _extractOgMetaTags(fetchedHtml);
      if (ogData.isNotEmpty) {
        parts.add('OG METADATA: $ogData');
      }

      final descMatch = RegExp(
              r'<meta\s+name="description"\s+content="([^"]*)"',
              caseSensitive: false)
          .firstMatch(fetchedHtml);
      if (descMatch != null) {
        final desc = _decodeHtmlEntities(descMatch.group(1)!);
        if (desc.isNotEmpty && !parts.any((p) => p.contains(desc))) {
          parts.add('META DESCRIPTION: $desc');
        }
      }
    }

    // 5. Try to process video (transcribe + extract frames)
    if (fetchedHtml != null) {
      final videoUrl = _extractVideoUrl(fetchedHtml);
      if (videoUrl != null) {
        final (transcript, frames) = await _processVideo(videoUrl);
        if (transcript != null) {
          parts.add('VIDEO TRANSCRIPT: $transcript');
        }
        videoFrames = frames;
      }
    }

    if (imageUrl == null && fetchedHtml != null) {
      imageUrl = _extractOgImageUrl(fetchedHtml);
      imageUrl ??= _extractTwitterImageUrl(fetchedHtml);
    }

    if (parts.isEmpty) {
      return (
        'TikTok video URL: $url\n\n'
            'I could not scrape the content from this TikTok video. '
            'However, please analyze the URL structure for any clues '
            '(username, video ID, hashtags in URL) and use your knowledge '
            'to identify any places, restaurants, attractions, or venues '
            'that might be featured. If the URL contains a username, '
            'consider what locations that creator commonly features.',
        videoFrames,
        imageUrl,
      );
    }

    return (
      'SOURCE: TikTok video\nURL: $url\n\n${parts.join('\n\n')}',
      videoFrames,
      imageUrl,
    );
  }

  /// Extract data from TikTok's __NEXT_DATA__ script (newer format)
  String? _extractNextData(String html) {
    try {
      const marker = '__NEXT_DATA__';
      final scriptStart = html.indexOf(marker);
      if (scriptStart == -1) return null;

      final jsonStart = html.indexOf('>', scriptStart);
      if (jsonStart == -1) return null;
      final jsonEnd = html.indexOf('</script>', jsonStart);
      if (jsonEnd == -1) return null;

      final jsonStr = html.substring(jsonStart + 1, jsonEnd).trim();
      if (jsonStr.isEmpty) return null;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final parts = <String>[];

      final props = data['props'] as Map<String, dynamic>?;
      final pageProps = props?['pageProps'] as Map<String, dynamic>?;
      if (pageProps != null) {
        final itemInfo = pageProps['itemInfo'] as Map<String, dynamic>?;
        final itemStruct = itemInfo?['itemStruct'] as Map<String, dynamic>?;
        if (itemStruct != null) {
          final desc = itemStruct['desc'] as String? ?? '';
          if (desc.isNotEmpty) parts.add('VIDEO DESCRIPTION: $desc');

          final location = itemStruct['locationCreated'] as String? ?? '';
          if (location.isNotEmpty) parts.add('LOCATION TAGGED: $location');
        }

        final seoProps = pageProps['seoProps'] as Map<String, dynamic>?;
        final metaParams = seoProps?['metaParams'] as Map<String, dynamic>?;
        if (metaParams != null) {
          final title = metaParams['title'] as String? ?? '';
          if (title.isNotEmpty) parts.add('SEO TITLE: $title');
          final description = metaParams['description'] as String? ?? '';
          if (description.isNotEmpty) {
            parts.add('SEO DESCRIPTION: $description');
          }
        }
      }

      return parts.isEmpty ? null : parts.join('\n');
    } catch (_) {
      return null;
    }
  }

  /// Extract video data from TikTok's __UNIVERSAL_DATA_FOR_REHYDRATION__
  String? _extractRehydrationData(String html) {
    try {
      const marker = '__UNIVERSAL_DATA_FOR_REHYDRATION__';
      final scriptStart = html.indexOf(marker);
      if (scriptStart == -1) return null;

      final jsonStart = html.indexOf('>', scriptStart);
      if (jsonStart == -1) return null;
      final jsonEnd = html.indexOf('</script>', jsonStart);
      if (jsonEnd == -1) return null;

      final jsonStr = html.substring(jsonStart + 1, jsonEnd).trim();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final parts = <String>[];

      final defaultScope =
          data['__DEFAULT_SCOPE__'] as Map<String, dynamic>?;
      if (defaultScope != null) {
        final videoDetail =
            defaultScope['webapp.video-detail'] as Map<String, dynamic>?;
        if (videoDetail != null) {
          final itemInfo =
              videoDetail['itemInfo'] as Map<String, dynamic>?;
          final itemStruct =
              itemInfo?['itemStruct'] as Map<String, dynamic>?;
          if (itemStruct != null) {
            final desc = itemStruct['desc'] as String? ?? '';
            if (desc.isNotEmpty) {
              parts.add('VIDEO DESCRIPTION: $desc');
            }

            final location =
                itemStruct['locationCreated'] as String? ?? '';
            if (location.isNotEmpty) {
              parts.add('LOCATION TAGGED: $location');
            }

            final contents = itemStruct['contents'] as List<dynamic>?;
            if (contents != null) {
              final hashtags = <String>[];
              for (final c in contents) {
                final textExtras =
                    (c as Map<String, dynamic>)['textExtra']
                        as List<dynamic>?;
                if (textExtras != null) {
                  for (final te in textExtras) {
                    final tag = (te as Map<String, dynamic>)['hashtagName']
                        as String?;
                    if (tag != null) hashtags.add('#$tag');
                  }
                }
              }
              if (hashtags.isNotEmpty) {
                parts.add('HASHTAGS: ${hashtags.join(' ')}');
              }
            }

            final stats =
                itemStruct['stats'] as Map<String, dynamic>?;
            if (stats != null) {
              final likes = stats['diggCount'] ?? 0;
              final comments = stats['commentCount'] ?? 0;
              final shares = stats['shareCount'] ?? 0;
              parts.add(
                  'ENGAGEMENT: $likes likes, $comments comments, $shares shares');
            }

            final suggestedWords =
                itemStruct['suggestedWords'] as List<dynamic>?;
            if (suggestedWords != null && suggestedWords.isNotEmpty) {
              parts.add('SUGGESTED TOPICS: ${suggestedWords.join(', ')}');
            }
          }
        }

        final commentDetail =
            defaultScope['webapp.video-detail']?['commentInfo']
                as Map<String, dynamic>?;
        if (commentDetail != null) {
          final commentList =
              commentDetail['comments'] as List<dynamic>?;
          if (commentList != null && commentList.isNotEmpty) {
            final commentTexts = <String>[];
            for (final c in commentList.take(20)) {
              final text = (c as Map<String, dynamic>)['text'] as String?;
              if (text != null && text.isNotEmpty) {
                commentTexts.add(text);
              }
            }
            if (commentTexts.isNotEmpty) {
              parts.add('TOP COMMENTS:\n${commentTexts.join('\n')}');
            }
          }
        }
      }

      return parts.isEmpty ? null : parts.join('\n');
    } catch (_) {
      return null;
    }
  }

  /// Fetch Instagram content with enhanced parsing strategies
  Future<(String, List<String>, String?)> _fetchInstagramContent(
      String url) async {
    final parts = <String>[];
    var videoFrames = <String>[];
    String? imageUrl;

    String? fetchedHtml;
    try {
      final response =
          await http.get(Uri.parse(url), headers: _mobileHeaders);
      if (response.statusCode == 200) {
        fetchedHtml = response.body;
      }
    } catch (_) {}

    if (fetchedHtml == null) {
      try {
        final response =
            await http.get(Uri.parse(url), headers: _browserHeaders);
        if (response.statusCode == 200) {
          fetchedHtml = response.body;
        }
      } catch (_) {}
    }

    if (fetchedHtml != null) {
      final ogData = _extractOgMetaTags(fetchedHtml);
      if (ogData.isNotEmpty) {
        parts.add('PAGE METADATA:\n$ogData');
      }

      final titleMatch =
          RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
              .firstMatch(fetchedHtml);
      if (titleMatch != null) {
        parts.add(
            'PAGE TITLE: ${_decodeHtmlEntities(titleMatch.group(1)!)}');
      }

      final descMatch = RegExp(
              r'<meta\s+name="description"\s+content="([^"]*)"',
              caseSensitive: false)
          .firstMatch(fetchedHtml);
      if (descMatch != null) {
        parts.add(
            'META DESCRIPTION: ${_decodeHtmlEntities(descMatch.group(1)!)}');
      }

      final twitterTitleMatch = RegExp(
              r'<meta\s+(?:name|property)="twitter:title"\s+content="([^"]*)"',
              caseSensitive: false)
          .firstMatch(fetchedHtml);
      if (twitterTitleMatch != null) {
        final t = _decodeHtmlEntities(twitterTitleMatch.group(1)!);
        if (t.isNotEmpty) parts.add('TWITTER TITLE: $t');
      }

      final twitterDescMatch = RegExp(
              r'<meta\s+(?:name|property)="twitter:description"\s+content="([^"]*)"',
              caseSensitive: false)
          .firstMatch(fetchedHtml);
      if (twitterDescMatch != null) {
        final t = _decodeHtmlEntities(twitterDescMatch.group(1)!);
        if (t.isNotEmpty) parts.add('TWITTER DESCRIPTION: $t');
      }

      final jsonLdMatches = RegExp(
        r'<script\s+type="application/ld\+json"[^>]*>(.*?)</script>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(fetchedHtml);

      for (final m in jsonLdMatches) {
        try {
          final jsonStr = m.group(1)!.trim();
          final data = jsonDecode(jsonStr);
          if (data is Map<String, dynamic>) {
            final name = data['name'] as String? ?? '';
            final desc = data['description'] as String? ?? '';
            final author = data['author'] as Map<String, dynamic>?;
            final authorName = author?['name'] as String? ?? '';
            final caption = data['caption'] as String? ?? '';
            final altDesc =
                data['accessibilityCaption'] as String? ?? '';

            if (name.isNotEmpty) parts.add('LD NAME: $name');
            if (desc.isNotEmpty) parts.add('LD DESCRIPTION: $desc');
            if (authorName.isNotEmpty) parts.add('LD AUTHOR: $authorName');
            if (caption.isNotEmpty) parts.add('LD CAPTION: $caption');
            if (altDesc.isNotEmpty) parts.add('LD ALT TEXT: $altDesc');
          }
        } catch (_) {}
      }

      final altMatches = RegExp(
        r'alt="([^"]{20,})"',
        caseSensitive: false,
      ).allMatches(fetchedHtml);

      final altTexts = <String>[];
      for (final m in altMatches) {
        final alt = _decodeHtmlEntities(m.group(1)!);
        if (!alt.contains('profile picture') &&
            !altTexts.any((a) => a == alt)) {
          altTexts.add(alt);
        }
      }
      if (altTexts.isNotEmpty) {
        parts.add('IMAGE ALT TEXT: ${altTexts.take(3).join(' | ')}');
      }

      final videoUrl = _extractVideoUrl(fetchedHtml);
      if (videoUrl != null) {
        final (transcript, frames) = await _processVideo(videoUrl);
        if (transcript != null) {
          parts.add('VIDEO TRANSCRIPT: $transcript');
        }
        videoFrames = frames;
      }

      imageUrl = _extractOgImageUrl(fetchedHtml);
      imageUrl ??= _extractTwitterImageUrl(fetchedHtml);
    }

    if (parts.isEmpty) {
      return (
        'Instagram post URL: $url\n\n'
            'I could not scrape the content from this Instagram post. '
            'However, please analyze the URL structure for any clues '
            '(username, post ID, location tags) and use your knowledge '
            'to identify any places, restaurants, attractions, or venues '
            'that might be featured. If there is an attached image, '
            'analyze it carefully for venue names, signage, food, '
            'landmarks, or other location clues.',
        videoFrames,
        imageUrl,
      );
    }

    return (
      'SOURCE: Instagram post\nURL: $url\n\n${parts.join('\n\n')}',
      videoFrames,
      imageUrl,
    );
  }

  /// Fetch content from other social media via OG meta tags
  Future<(String, List<String>, String?)> _fetchSocialMediaContent(
      String url) async {
    final parts = <String>[];
    String? imageUrl;

    try {
      final response =
          await http.get(Uri.parse(url), headers: _browserHeaders);
      if (response.statusCode == 200) {
        final ogData = _extractOgMetaTags(response.body);
        if (ogData.isNotEmpty) {
          parts.add('PAGE METADATA:\n$ogData');
        }

        imageUrl = _extractOgImageUrl(response.body);
        imageUrl ??= _extractTwitterImageUrl(response.body);

        final titleMatch =
            RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
                .firstMatch(response.body);
        if (titleMatch != null) {
          parts.add(
              'PAGE TITLE: ${_decodeHtmlEntities(titleMatch.group(1)!)}');
        }

        final descMatch = RegExp(
                r'<meta\s+name="description"\s+content="([^"]*)"',
                caseSensitive: false)
            .firstMatch(response.body);
        if (descMatch != null) {
          parts.add(
              'META DESCRIPTION: ${_decodeHtmlEntities(descMatch.group(1)!)}');
        }
      }
    } catch (_) {}

    if (parts.isEmpty) {
      return (
        'Social media URL: $url\n'
            'Could not fetch content directly. '
            'Please extract any places based on your knowledge of this URL, '
            'including any location hints in the URL itself.',
        <String>[],
        imageUrl,
      );
    }

    return (parts.join('\n\n'), <String>[], imageUrl);
  }

  /// Extract Open Graph meta tags from HTML
  String _extractOgMetaTags(String html) {
    final ogTags = <String, String>{};
    final regex = RegExp(
      r'<meta\s+(?:property|name)="(og:[^"]+)"\s+content="([^"]*)"',
      caseSensitive: false,
    );
    final regex2 = RegExp(
      r'<meta\s+content="([^"]*)"\s+(?:property|name)="(og:[^"]+)"',
      caseSensitive: false,
    );

    for (final match in regex.allMatches(html)) {
      ogTags[match.group(1)!] = _decodeHtmlEntities(match.group(2)!);
    }
    for (final match in regex2.allMatches(html)) {
      ogTags[match.group(2)!] = _decodeHtmlEntities(match.group(1)!);
    }

    if (ogTags.isEmpty) return '';

    return ogTags.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  /// Fetch regular webpage HTML
  Future<(String, List<String>, String?)> _fetchWebpageContent(
      String url) async {
    final response =
        await http.get(Uri.parse(url), headers: _browserHeaders);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch URL: ${response.statusCode}');
    }

    final fullBody = response.body;
    String? imageUrl = _extractOgImageUrl(fullBody);
    imageUrl ??= _extractTwitterImageUrl(fullBody);

    String content = fullBody;
    if (content.length > _maxContentChars) {
      content = content.substring(0, _maxContentChars);
    }
    return (content, <String>[], imageUrl);
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&apos;', "'");
  }

  /// Extract video download URL from HTML metadata
  String? _extractVideoUrl(String html) {
    for (final attr in [
      'og:video',
      'og:video:url',
      'og:video:secure_url'
    ]) {
      final regex = RegExp(
        '<meta\\s+(?:property|name)="$attr"\\s+content="([^"]*)"',
        caseSensitive: false,
      );
      final regex2 = RegExp(
        '<meta\\s+content="([^"]*)"\\s+(?:property|name)="$attr"',
        caseSensitive: false,
      );
      final match = regex.firstMatch(html) ?? regex2.firstMatch(html);
      if (match != null) {
        final url = _decodeHtmlEntities(match.group(1)!);
        if (url.isNotEmpty && url.startsWith('http')) return url;
      }
    }

    try {
      const marker = '__UNIVERSAL_DATA_FOR_REHYDRATION__';
      final scriptStart = html.indexOf(marker);
      if (scriptStart != -1) {
        final jsonStart = html.indexOf('>', scriptStart);
        final jsonEnd = html.indexOf('</script>', jsonStart);
        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonStr = html.substring(jsonStart + 1, jsonEnd).trim();
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final itemStruct = data['__DEFAULT_SCOPE__']
              ?['webapp.video-detail']?['itemInfo']?['itemStruct'];
          if (itemStruct != null) {
            final video = itemStruct['video'] as Map<String, dynamic>?;
            final playAddr = video?['playAddr'] as String?;
            if (playAddr != null && playAddr.isNotEmpty) return playAddr;
            final downloadAddr = video?['downloadAddr'] as String?;
            if (downloadAddr != null && downloadAddr.isNotEmpty) {
              return downloadAddr;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  // ---------------------------------------------------------------------------
  // Video processing with Gemini audio transcription
  // ---------------------------------------------------------------------------

  /// Download video, extract key frames, and transcribe audio via Gemini
  Future<(String? transcript, List<String> frameBase64s)> _processVideo(
      String videoUrl) async {
    File? tempFile;
    try {
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      tempFile = File('${dir.path}/steply_video_$ts.mp4');

      final request = await HttpClient().getUrl(Uri.parse(videoUrl));
      request.headers.set('User-Agent', _mobileHeaders['User-Agent']!);
      final response = await request.close();

      if (response.statusCode != 200) return (null, <String>[]);

      final contentLength = response.contentLength;
      if (contentLength > 20 * 1024 * 1024) return (null, <String>[]);

      final sink = tempFile.openWrite();
      await response.pipe(sink);
      await sink.close();

      final fileSize = await tempFile.length();
      if (fileSize > 20 * 1024 * 1024 || fileSize < 1000) {
        return (null, <String>[]);
      }

      // Extract key frames at different timestamps
      final frameBase64s = <String>[];
      for (final ms in [1000, 10000, 25000]) {
        try {
          final Uint8List? frame = await VideoThumbnail.thumbnailData(
            video: tempFile.path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 512,
            quality: 60,
            timeMs: ms,
          );
          if (frame != null && frame.isNotEmpty) {
            frameBase64s.add(base64Encode(frame));
          }
        } catch (_) {}
      }
      print('🎬 [Video] Extracted ${frameBase64s.length} frames');

      // Transcribe audio via Gemini (replaces Whisper)
      String? transcript;
      try {
        final audioBytes = await tempFile.readAsBytes();
        if (audioBytes.length < 20 * 1024 * 1024) {
          final audioBase64 = base64Encode(audioBytes);
          transcript = await _callGemini(
            systemPrompt: 'You are a transcription assistant.',
            userText:
                'Transcribe the audio from this video. Return ONLY the transcription text, nothing else. If there is no speech, return an empty string.',
            audioBase64: audioBase64,
            audioMimeType: 'audio/mp4',
            temperature: 0.0,
            maxOutputTokens: 1000,
            jsonResponse: false,
          );
          if (transcript.trim().isEmpty) {
            transcript = null;
          }
        }
      } catch (e) {
        print('🎙️ [Gemini] Transcription failed: $e');
      }

      return (transcript, frameBase64s);
    } catch (e) {
      print('🎬 [Video] Processing failed: $e');
      return (null, <String>[]);
    } finally {
      try {
        await tempFile?.delete();
      } catch (_) {}
    }
  }

  /// Extract OG image URL from raw HTML content
  String? _extractOgImageUrl(String content) {
    final regex = RegExp(
      r'<meta\s+(?:property|name)="og:image"\s+content="([^"]*)"',
      caseSensitive: false,
    );
    final regex2 = RegExp(
      r'<meta\s+content="([^"]*)"\s+(?:property|name)="og:image"',
      caseSensitive: false,
    );
    final match = regex.firstMatch(content) ?? regex2.firstMatch(content);
    if (match != null) {
      return _decodeHtmlEntities(match.group(1)!);
    }
    return null;
  }

  /// Extract twitter:image URL as fallback
  String? _extractTwitterImageUrl(String content) {
    final regex = RegExp(
      r'<meta\s+(?:property|name)="twitter:image"\s+content="([^"]*)"',
      caseSensitive: false,
    );
    final regex2 = RegExp(
      r'<meta\s+content="([^"]*)"\s+(?:property|name)="twitter:image"',
      caseSensitive: false,
    );
    final match = regex.firstMatch(content) ?? regex2.firstMatch(content);
    if (match != null) {
      return _decodeHtmlEntities(match.group(1)!);
    }
    return null;
  }

  /// Fetch content for insights
  Future<(String, String?)> _fetchInsightsContent(String url) async {
    final lower = url.toLowerCase();
    String? imageUrl;

    String textContent;
    if (lower.contains('tiktok.com')) {
      (textContent, _, imageUrl) = await _fetchTikTokContent(url);
    } else if (lower.contains('instagram.com')) {
      (textContent, _, imageUrl) = await _fetchInstagramContent(url);
    } else if (lower.contains('twitter.com') ||
        lower.contains('x.com') ||
        lower.contains('facebook.com') ||
        lower.contains('threads.net') ||
        lower.contains('youtube.com') ||
        lower.contains('youtu.be')) {
      (textContent, _, imageUrl) = await _fetchSocialMediaContent(url);
    } else {
      (textContent, _, imageUrl) = await _fetchWebpageContent(url);
    }

    return (textContent, imageUrl);
  }

  String _stripMarkdownFences(String content) {
    content = content.trim();
    if (content.startsWith('```json')) {
      content = content.substring(7);
    } else if (content.startsWith('```')) {
      content = content.substring(3);
    }
    if (content.endsWith('```')) {
      content = content.substring(0, content.length - 3);
    }
    return content.trim();
  }
}
