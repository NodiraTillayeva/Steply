import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:steply/core/constants/app_constants.dart';
import 'package:steply/features/analysis/domain/entities/place_insights.dart';
import 'package:steply/features/wishlist/domain/entities/wishlist_place.dart';

abstract class OpenAiRemoteDatasource {
  Future<List<WishlistPlace>> extractPlacesFromUrl(String url);
  Future<List<WishlistPlace>> extractPlacesFromImage(String base64Image);
  Future<PlaceInsights> getPlaceInsights({
    required String placeName,
    String? sourceUrl,
    String? rawContent,
    String? description,
  });
}

class OpenAiRemoteDatasourceImpl implements OpenAiRemoteDatasource {
  static const String _endpoint =
      'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o';
  static const int _maxContentChars = 12000;

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

  @override
  Future<List<WishlistPlace>> extractPlacesFromUrl(String url) async {
    final lower = url.toLowerCase();
    String extractedContent;
    String? imageUrl;

    if (lower.contains('tiktok.com')) {
      extractedContent = await _fetchTikTokContent(url);
    } else if (lower.contains('instagram.com') ||
        lower.contains('twitter.com') ||
        lower.contains('x.com') ||
        lower.contains('facebook.com') ||
        lower.contains('threads.net') ||
        lower.contains('youtube.com') ||
        lower.contains('youtu.be')) {
      extractedContent = await _fetchSocialMediaContent(url);
    } else {
      extractedContent = await _fetchWebpageContent(url);
    }

    // Try to get a preview image from the source page
    try {
      final response =
          await http.get(Uri.parse(url), headers: _browserHeaders);
      if (response.statusCode == 200) {
        imageUrl = _extractOgImageUrl(response.body);
      }
    } catch (_) {}

    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      {
        'role': 'user',
        'content':
            'Extract places from this content (source URL: $url):\n\n$extractedContent',
      },
    ];

    return _callOpenAi(messages, url, extractedContent, imageUrl: imageUrl);
  }

  /// Fetch TikTok content via oEmbed API + page HTML parsing
  Future<String> _fetchTikTokContent(String url) async {
    final parts = <String>[];

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
        if (title.isNotEmpty) {
          parts.add('VIDEO CAPTION: $title');
        }
        if (author.isNotEmpty) {
          parts.add('AUTHOR: $author (@$authorId)');
        }
        // oEmbed sometimes includes HTML with extra text
        final html = data['html'] as String? ?? '';
        if (html.isNotEmpty) {
          // Extract cite URL which may differ from input
          final citeMatch = RegExp(r'cite="([^"]+)"').firstMatch(html);
          if (citeMatch != null) {
            parts.add('CANONICAL URL: ${citeMatch.group(1)}');
          }
        }
      }
    } catch (_) {}

    // 2. Try fetching with mobile user-agent (TikTok serves lighter HTML)
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
      // Try __UNIVERSAL_DATA_FOR_REHYDRATION__
      final rehydrationData = _extractRehydrationData(fetchedHtml);
      if (rehydrationData != null) {
        parts.add(rehydrationData);
      }

      // Try __NEXT_DATA__ (newer TikTok format)
      final nextData = _extractNextData(fetchedHtml);
      if (nextData != null) {
        parts.add(nextData);
      }

      // OG meta tags
      final ogData = _extractOgMetaTags(fetchedHtml);
      if (ogData.isNotEmpty) {
        parts.add('OG METADATA: $ogData');
      }

      // Extract any meta description
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

    if (parts.isEmpty) {
      // Even with no extracted content, give OpenAI the URL and
      // ask it to use its training knowledge
      return 'TikTok video URL: $url\n\n'
          'I could not scrape the content from this TikTok video. '
          'However, please analyze the URL structure for any clues '
          '(username, video ID, hashtags in URL) and use your knowledge '
          'to identify any places, restaurants, attractions, or venues '
          'that might be featured. If the URL contains a username, '
          'consider what locations that creator commonly features.';
    }

    return 'SOURCE: TikTok video\nURL: $url\n\n${parts.join('\n\n')}';
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

      // Navigate through props -> pageProps -> itemInfo
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

        // Also check for SEO data
        final seoProps = pageProps['seoProps'] as Map<String, dynamic>?;
        final metaParams = seoProps?['metaParams'] as Map<String, dynamic>?;
        if (metaParams != null) {
          final title = metaParams['title'] as String? ?? '';
          if (title.isNotEmpty) parts.add('SEO TITLE: $title');
          final description = metaParams['description'] as String? ?? '';
          if (description.isNotEmpty) parts.add('SEO DESCRIPTION: $description');
        }
      }

      return parts.isEmpty ? null : parts.join('\n');
    } catch (_) {
      return null;
    }
  }

  /// Extract video data from TikTok's __UNIVERSAL_DATA_FOR_REHYDRATION__ script
  String? _extractRehydrationData(String html) {
    try {
      // Find the JSON blob in the script tag
      const marker = '__UNIVERSAL_DATA_FOR_REHYDRATION__';
      final scriptStart = html.indexOf(marker);
      if (scriptStart == -1) return null;

      // Find the JSON content after the marker
      final jsonStart = html.indexOf('>', scriptStart);
      if (jsonStart == -1) return null;
      final jsonEnd = html.indexOf('</script>', jsonStart);
      if (jsonEnd == -1) return null;

      final jsonStr = html.substring(jsonStart + 1, jsonEnd).trim();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final parts = <String>[];

      // Navigate to video detail data
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

            // Location data
            final location =
                itemStruct['locationCreated'] as String? ?? '';
            if (location.isNotEmpty) {
              parts.add('LOCATION TAGGED: $location');
            }

            // Hashtags from contents
            final contents = itemStruct['contents'] as List<dynamic>?;
            if (contents != null) {
              final hashtags = <String>[];
              for (final c in contents) {
                final textExtras =
                    (c as Map<String, dynamic>)['textExtra'] as List<dynamic>?;
                if (textExtras != null) {
                  for (final te in textExtras) {
                    final tag =
                        (te as Map<String, dynamic>)['hashtagName'] as String?;
                    if (tag != null) hashtags.add('#$tag');
                  }
                }
              }
              if (hashtags.isNotEmpty) {
                parts.add('HASHTAGS: ${hashtags.join(' ')}');
              }
            }

            // Engagement stats
            final stats =
                itemStruct['stats'] as Map<String, dynamic>?;
            if (stats != null) {
              final likes = stats['diggCount'] ?? 0;
              final comments = stats['commentCount'] ?? 0;
              final shares = stats['shareCount'] ?? 0;
              parts.add('ENGAGEMENT: $likes likes, $comments comments, $shares shares');
            }

            // Suggested words / auto-captions if available
            final suggestedWords =
                itemStruct['suggestedWords'] as List<dynamic>?;
            if (suggestedWords != null && suggestedWords.isNotEmpty) {
              parts.add('SUGGESTED TOPICS: ${suggestedWords.join(', ')}');
            }
          }
        }

        // Try to extract comments from comment data
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

  /// Fetch content from other social media via OG meta tags
  Future<String> _fetchSocialMediaContent(String url) async {
    final parts = <String>[];

    try {
      final response =
          await http.get(Uri.parse(url), headers: _browserHeaders);
      if (response.statusCode == 200) {
        final ogData = _extractOgMetaTags(response.body);
        if (ogData.isNotEmpty) {
          parts.add('PAGE METADATA:\n$ogData');
        }

        // Try to extract any useful text from meta tags and title
        final titleMatch =
            RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
                .firstMatch(response.body);
        if (titleMatch != null) {
          parts.add('PAGE TITLE: ${_decodeHtmlEntities(titleMatch.group(1)!)}');
        }

        // Extract meta description
        final descMatch = RegExp(
                r'<meta\s+name="description"\s+content="([^"]*)"',
                caseSensitive: false)
            .firstMatch(response.body);
        if (descMatch != null) {
          parts.add(
              'META DESCRIPTION: ${_decodeHtmlEntities(descMatch.group(1)!)}');
        }
      }
    } catch (_) {
      // Fetch failed
    }

    if (parts.isEmpty) {
      return 'Social media URL: $url\n'
          'Could not fetch content directly. '
          'Please extract any places based on your knowledge of this URL, '
          'including any location hints in the URL itself.';
    }

    return parts.join('\n\n');
  }

  /// Extract Open Graph meta tags from HTML
  String _extractOgMetaTags(String html) {
    final ogTags = <String, String>{};
    final regex = RegExp(
      r'<meta\s+(?:property|name)="(og:[^"]+)"\s+content="([^"]*)"',
      caseSensitive: false,
    );
    // Also match reversed attribute order
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
  Future<String> _fetchWebpageContent(String url) async {
    final response =
        await http.get(Uri.parse(url), headers: _browserHeaders);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch URL: ${response.statusCode}');
    }

    String content = response.body;
    if (content.length > _maxContentChars) {
      content = content.substring(0, _maxContentChars);
    }
    return content;
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

  @override
  Future<List<WishlistPlace>> extractPlacesFromImage(
      String base64Image) async {
    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      {
        'role': 'user',
        'content': [
          {
            'type': 'text',
            'text':
                'Extract all places, locations, restaurants, or venues visible in this screenshot.',
          },
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:image/jpeg;base64,$base64Image',
            },
          },
        ],
      },
    ];

    return _callOpenAi(messages, 'screenshot', null);
  }

  Future<List<WishlistPlace>> _callOpenAi(
      List<Map<String, dynamic>> messages,
      String source,
      String? extractedContent,
      {String? imageUrl}) async {
    final body = jsonEncode({
      'model': _model,
      'temperature': 0.1,
      'max_tokens': 2000,
      'messages': messages,
    });

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppStrings.openAiApiKey}',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['error']?['message'] ?? 'Unknown API error';
      throw Exception('OpenAI API error: $errorMessage');
    }

    final responseBody = jsonDecode(response.body);
    String content =
        responseBody['choices'][0]['message']['content'] as String;

    content = _stripMarkdownFences(content);

    final List<dynamic> places = jsonDecode(content);
    final now = DateTime.now();

    // Truncate raw content for storage (max 2000 chars)
    final truncatedContent = extractedContent != null && extractedContent.length > 2000
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

  /// Fetch content for insights — returns (textContent, imageUrl?)
  Future<(String, String?)> _fetchInsightsContent(String url) async {
    final lower = url.toLowerCase();
    String? imageUrl;

    // Always try to get the page HTML for the OG image
    try {
      final response = await http.get(Uri.parse(url), headers: _browserHeaders);
      if (response.statusCode == 200) {
        imageUrl = _extractOgImageUrl(response.body);
      }
    } catch (_) {}

    String textContent;
    if (lower.contains('tiktok.com')) {
      textContent = await _fetchTikTokContent(url);
    } else if (lower.contains('instagram.com') ||
        lower.contains('twitter.com') ||
        lower.contains('x.com') ||
        lower.contains('facebook.com') ||
        lower.contains('threads.net') ||
        lower.contains('youtube.com') ||
        lower.contains('youtu.be')) {
      textContent = await _fetchSocialMediaContent(url);
    } else {
      textContent = await _fetchWebpageContent(url);
    }

    return (textContent, imageUrl);
  }

  @override
  Future<PlaceInsights> getPlaceInsights({
    required String placeName,
    String? sourceUrl,
    String? rawContent,
    String? description,
  }) async {
    String contextContent = '';
    String? imageUrl;

    // Always re-fetch fresh content for insights (richer than truncated rawContent)
    if (sourceUrl != null && sourceUrl.isNotEmpty && sourceUrl != 'screenshot') {
      try {
        final result = await _fetchInsightsContent(sourceUrl);
        contextContent = result.$1;
        imageUrl = result.$2;
      } catch (_) {
        // Fall back to stored raw content
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
      // Send full content for insights (not truncated)
      final content = contextContent.length > 6000
          ? contextContent.substring(0, 6000)
          : contextContent;
      userText.writeln('\n--- SOURCE CONTENT (from social media / webpage) ---\n$content');
    }
    userText.writeln('\nAnalyze the above content deeply. Extract specific details, not generic advice.');

    // Build messages — use vision if we have a thumbnail image
    final List<Map<String, dynamic>> messages;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      messages = [
        {'role': 'system', 'content': _insightsPrompt},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userText.toString()},
            {
              'type': 'image_url',
              'image_url': {'url': imageUrl, 'detail': 'low'},
            },
          ],
        },
      ];
    } else {
      messages = [
        {'role': 'system', 'content': _insightsPrompt},
        {'role': 'user', 'content': userText.toString()},
      ];
    }

    final body = jsonEncode({
      'model': _model,
      'temperature': 0.3,
      'max_tokens': 2000,
      'messages': messages,
    });

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppStrings.openAiApiKey}',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['error']?['message'] ?? 'Unknown API error';
      throw Exception('OpenAI API error: $errorMessage');
    }

    final responseBody = jsonDecode(response.body);
    String content =
        responseBody['choices'][0]['message']['content'] as String;

    content = _stripMarkdownFences(content);

    final json = jsonDecode(content) as Map<String, dynamic>;

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
