import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

class SchoolSearchResult {
  final String name;
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? ncessId;
  final String? phone;
  final String? website;

  SchoolSearchResult({
    required this.name,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
    this.ncessId,
    this.phone,
    this.website,
  });

  String get fullAddress {
    final parts = [address];
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (zipCode != null) parts.add(zipCode!);
    return parts.join(', ');
  }

  factory SchoolSearchResult.fromUrbanApi(Map<String, dynamic> json) {
    // Urban Institute Education Data API format
    return SchoolSearchResult(
      name: json['school_name'] ?? json['name'] ?? '',
      address: json['street_mailing'] ?? json['street_location'] ?? json['address'] ?? '',
      city: json['city_mailing'] ?? json['city_location'] ?? json['city'],
      state: json['state_mailing'] ?? json['state_location'] ?? json['state'],
      zipCode: json['zip_mailing'] ?? json['zip_location'] ?? json['zip'],
      ncessId: json['ncessch']?.toString(),
      phone: json['phone'],
      website: json['website'],
    );
  }
}

class SchoolSearchService {
  static const String _baseUrl = 'https://educationdata.urban.org/api/v1';
  // Cache for recent searches to improve performance
  final Map<String, List<SchoolSearchResult>> _searchCache = {};
  final Map<int, List<SchoolSearchResult>> _stateCache = {};

  /// Search schools using Urban Institute Education Data API with fuzzy matching
  Future<List<SchoolSearchResult>> searchSchools(String query, {String? stateFilter}) async {
    if (query.trim().isEmpty) return [];

    final queryLower = query.toLowerCase().trim();
    
    // Check cache first
    final cacheKey = '${stateFilter ?? 'all'}_$queryLower';
    if (_searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey]!;
    }

    try {
      // Get the most recent year of data available (2021 is latest for CCD)
      final year = 2021;
      
      // Build API URL - get all schools from a state or all states
      String apiUrl = '$_baseUrl/schools/ccd/directory/$year/';
      
      // Add state filter if provided
      if (stateFilter != null && stateFilter.isNotEmpty) {
        apiUrl += '?fips=${_getStateFips(stateFilter)}';
      }
      
      print('Fetching schools from: $apiUrl');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        print('Received ${results.length} schools from API');
        
        // Convert API results to SchoolSearchResult objects
        final allSchools = results
            .map((school) => SchoolSearchResult.fromUrbanApi(school))
            .where((school) => school.name.isNotEmpty && school.address.isNotEmpty)
            .toList();

        // Apply fuzzy matching
        final matchedSchools = _fuzzyMatchSchools(allSchools, query);
        
        // Cache the results
        _searchCache[cacheKey] = matchedSchools;
        
        return matchedSchools;
      } else {
        print('API error: ${response.statusCode}');
        return _fallbackSearch(query);
      }
    } catch (e) {
      print('Error searching schools: $e');
      return _fallbackSearch(query);
    }
  }

  /// Fuzzy match schools by name and location
  List<SchoolSearchResult> _fuzzyMatchSchools(
    List<SchoolSearchResult> schools,
    String query,
  ) {
    final queryLower = query.toLowerCase();
    
    // Score each school based on fuzzy matching
    final scoredSchools = schools.map((school) {
      final nameLower = school.name.toLowerCase();
      final cityLower = school.city?.toLowerCase() ?? '';
      final stateLower = school.state?.toLowerCase() ?? '';
      
      // Use token_sort_ratio for better matching with word order differences
      final nameScore = tokenSortRatio(queryLower, nameLower);
      final cityScore = tokenSortRatio(queryLower, cityLower);
      final stateScore = partialRatio(queryLower, stateLower);
      
      // Boost exact matches at start of name
      int exactBonus = 0;
      if (nameLower.startsWith(queryLower)) {
        exactBonus = 20;
      } else if (nameLower.contains(queryLower)) {
        exactBonus = 10;
      }
      
      // Combined score: prioritize name match, then city/state
      final combinedScore = (nameScore * 0.7 + 
                            cityScore * 0.2 + 
                            stateScore * 0.1 +
                            exactBonus).round();
      
      return MapEntry(school, combinedScore);
    }).toList();

    // Sort by score descending
    scoredSchools.sort((a, b) => b.value.compareTo(a.value));
    
    // Filter out poor matches (score < 60) and return top results
    final goodMatches = scoredSchools
        .where((entry) => entry.value >= 60)
        .map((entry) => entry.key)
        .take(10) // Show top 10 matches
        .toList();
    
    print('Fuzzy matching: ${goodMatches.length} results with score >= 60');
    
    return goodMatches;
  }

  /// Get FIPS code for state abbreviation
  int? _getStateFips(String state) {
    final stateFips = {
      'AL': 1, 'AK': 2, 'AZ': 4, 'AR': 5, 'CA': 6, 'CO': 8, 'CT': 9, 'DE': 10,
      'DC': 11, 'FL': 12, 'GA': 13, 'HI': 15, 'ID': 16, 'IL': 17, 'IN': 18,
      'IA': 19, 'KS': 20, 'KY': 21, 'LA': 22, 'ME': 23, 'MD': 24, 'MA': 25,
      'MI': 26, 'MN': 27, 'MS': 28, 'MO': 29, 'MT': 30, 'NE': 31, 'NV': 32,
      'NH': 33, 'NJ': 34, 'NM': 35, 'NY': 36, 'NC': 37, 'ND': 38, 'OH': 39,
      'OK': 40, 'OR': 41, 'PA': 42, 'RI': 44, 'SC': 45, 'SD': 46, 'TN': 47,
      'TX': 48, 'UT': 49, 'VT': 50, 'VA': 51, 'WA': 53, 'WV': 54, 'WI': 55,
      'WY': 56,
    };
    return stateFips[state.toUpperCase()];
  }

  /// Fallback local search if API fails
  List<SchoolSearchResult> _fallbackSearch(String query) {
    print('Using fallback search for: $query');
    
    final fallbackSchools = [
      {
        'name': 'Washington High School',
        'address': '123 Main St',
        'city': 'Washington',
        'state': 'DC',
        'zip': '20001'
      },
      {
        'name': 'Lincoln High School',
        'address': '456 Oak Ave',
        'city': 'Lincoln',
        'state': 'NE',
        'zip': '68501'
      },
      {
        'name': 'Roosevelt High School',
        'address': '789 Pine Rd',
        'city': 'Seattle',
        'state': 'WA',
        'zip': '98101'
      },
      {
        'name': 'Jefferson High School',
        'address': '321 Elm St',
        'city': 'Portland',
        'state': 'OR',
        'zip': '97201'
      },
      {
        'name': 'Madison High School',
        'address': '654 Maple Dr',
        'city': 'Madison',
        'state': 'WI',
        'zip': '53701'
      },
      {
        'name': 'Kennedy High School',
        'address': '987 Cedar Ln',
        'city': 'Los Angeles',
        'state': 'CA',
        'zip': '90001'
      },
      {
        'name': 'Franklin High School',
        'address': '147 Birch Blvd',
        'city': 'Philadelphia',
        'state': 'PA',
        'zip': '19019'
      },
      {
        'name': 'Hamilton High School',
        'address': '258 Spruce Way',
        'city': 'New York',
        'state': 'NY',
        'zip': '10001'
      },
    ];

    final results = fallbackSchools
        .map((school) => SchoolSearchResult(
              name: school['name']!,
              address: school['address']!,
              city: school['city'],
              state: school['state'],
              zipCode: school['zip'],
            ))
        .toList();

    return _fuzzyMatchSchools(results, query);
  }

  /// Search schools by state
  Future<List<SchoolSearchResult>> searchByState(String stateCode) async {
    final fips = _getStateFips(stateCode);
    if (fips == null) return [];

    // Check state cache
    if (_stateCache.containsKey(fips)) {
      return _stateCache[fips]!;
    }

    try {
      final year = 2021;
      final apiUrl = '$_baseUrl/schools/ccd/directory/$year/?fips=$fips';
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        final schools = results
            .map((school) => SchoolSearchResult.fromUrbanApi(school))
            .where((school) => school.name.isNotEmpty)
            .take(100) // Limit state results
            .toList();

        _stateCache[fips] = schools;
        return schools;
      }
    } catch (e) {
      print('Error fetching state schools: $e');
    }

    return [];
  }

  /// Clear cache
  void clearCache() {
    _searchCache.clear();
    _stateCache.clear();
  }
}
