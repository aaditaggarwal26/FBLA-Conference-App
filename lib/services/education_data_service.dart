import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to access Urban Institute Education Data Portal API
/// Provides insights, statistics, and educational data
class EducationDataService {
  static const String _baseUrl = 'https://educationdata.urban.org/api/v1';
  
  // Cache for API responses
  final Map<String, dynamic> _cache = {};
  
  /// Get school enrollment statistics by grade
  Future<Map<String, dynamic>?> getSchoolEnrollment({
    required String ncessId,
    int? year,
  }) async {
    final useYear = year ?? 2021;
    final cacheKey = 'enrollment_${ncessId}_$useYear';
    
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }
    
    try {
      // Get enrollment by grade for a specific school
      final url = '$_baseUrl/schools/ccd/enrollment/$useYear/grade-pk/?ncessch=$ncessId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cache[cacheKey] = data;
        return data;
      }
    } catch (e) {
      print('Error fetching enrollment: $e');
    }
    
    return null;
  }
  
  /// Get school demographics and diversity stats
  Future<SchoolDemographics?> getSchoolDemographics({
    required String ncessId,
    int? year,
  }) async {
    final useYear = year ?? 2021;
    final cacheKey = 'demographics_${ncessId}_$useYear';
    
    if (_cache.containsKey(cacheKey)) {
      return SchoolDemographics.fromJson(_cache[cacheKey]);
    }
    
    try {
      final url = '$_baseUrl/schools/ccd/directory/$useYear/?ncessch=$ncessId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final schoolData = data['results'][0];
          _cache[cacheKey] = schoolData;
          return SchoolDemographics.fromJson(schoolData);
        }
      }
    } catch (e) {
      print('Error fetching demographics: $e');
    }
    
    return null;
  }
  
  /// Get college scorecard data for higher education institutions
  Future<CollegeScorecard?> getCollegeData({
    required String unitId,
    int? year,
  }) async {
    final useYear = year ?? 2021;
    final cacheKey = 'college_${unitId}_$useYear';
    
    if (_cache.containsKey(cacheKey)) {
      return CollegeScorecard.fromJson(_cache[cacheKey]);
    }
    
    try {
      final url = '$_baseUrl/college-university/scorecard/$useYear/?unitid=$unitId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final collegeData = data['results'][0];
          _cache[cacheKey] = collegeData;
          return CollegeScorecard.fromJson(collegeData);
        }
      }
    } catch (e) {
      print('Error fetching college data: $e');
    }
    
    return null;
  }
  
  /// Search for colleges and universities
  Future<List<CollegeSearchResult>> searchColleges({
    required String query,
    String? state,
    int limit = 10,
  }) async {
    try {
      final year = 2021;
      var url = '$_baseUrl/college-university/ipeds/directory/$year/?inst_name=$query';
      
      if (state != null && state.isNotEmpty) {
        url += '&fips=${_getStateFips(state)}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        return results
            .take(limit)
            .map((college) => CollegeSearchResult.fromJson(college))
            .toList();
      }
    } catch (e) {
      print('Error searching colleges: $e');
    }
    
    return [];
  }
  
  /// Get school district statistics
  Future<DistrictStats?> getDistrictStats({
    required String leaId,
    int? year,
  }) async {
    final useYear = year ?? 2021;
    final cacheKey = 'district_${leaId}_$useYear';
    
    if (_cache.containsKey(cacheKey)) {
      return DistrictStats.fromJson(_cache[cacheKey]);
    }
    
    try {
      final url = '$_baseUrl/school-districts/ccd/directory/$useYear/?leaid=$leaId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final districtData = data['results'][0];
          _cache[cacheKey] = districtData;
          return DistrictStats.fromJson(districtData);
        }
      }
    } catch (e) {
      print('Error fetching district stats: $e');
    }
    
    return null;
  }
  
  /// Get state education summary
  Future<StateEducationSummary?> getStateSummary({
    required String stateCode,
    int? year,
  }) async {
    final useYear = year ?? 2021;
    final fips = _getStateFips(stateCode);
    if (fips == null) return null;
    
    final cacheKey = 'state_${stateCode}_$useYear';
    
    if (_cache.containsKey(cacheKey)) {
      return StateEducationSummary.fromJson(_cache[cacheKey]);
    }
    
    try {
      final url = '$_baseUrl/schools/ccd/directory/$useYear/?fips=$fips';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final schools = data['results'] as List? ?? [];
        
        final summary = StateEducationSummary(
          state: stateCode,
          year: useYear,
          totalSchools: schools.length,
          publicSchools: schools.where((s) => s['school_type'] == 1).length,
          charterSchools: schools.where((s) => s['charter'] == 1).length,
        );
        
        _cache[cacheKey] = summary.toJson();
        return summary;
      }
    } catch (e) {
      print('Error fetching state summary: $e');
    }
    
    return null;
  }
  
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
  
  void clearCache() {
    _cache.clear();
  }
}

// Data models

class SchoolDemographics {
  final String schoolName;
  final String? city;
  final String? state;
  final int? totalStudents;
  final String? schoolType;
  final String? schoolLevel;
  final bool? isCharter;
  final bool? isMagnet;
  final String? phone;
  final String? website;
  
  SchoolDemographics({
    required this.schoolName,
    this.city,
    this.state,
    this.totalStudents,
    this.schoolType,
    this.schoolLevel,
    this.isCharter,
    this.isMagnet,
    this.phone,
    this.website,
  });
  
  factory SchoolDemographics.fromJson(Map<String, dynamic> json) {
    return SchoolDemographics(
      schoolName: json['school_name'] ?? '',
      city: json['city_location'],
      state: json['state_location'],
      totalStudents: json['enrollment'],
      schoolType: _getSchoolType(json['school_type']),
      schoolLevel: _getSchoolLevel(json['school_level']),
      isCharter: json['charter'] == 1,
      isMagnet: json['magnet'] == 1,
      phone: json['phone'],
      website: json['website'],
    );
  }
  
  static String? _getSchoolType(dynamic type) {
    if (type == null) return null;
    switch (type) {
      case 1: return 'Regular school';
      case 2: return 'Special education';
      case 3: return 'Vocational';
      case 4: return 'Alternative';
      default: return 'Other';
    }
  }
  
  static String? _getSchoolLevel(dynamic level) {
    if (level == null) return null;
    switch (level) {
      case 1: return 'Elementary';
      case 2: return 'Middle';
      case 3: return 'High';
      case 4: return 'Other';
      default: return 'Ungraded';
    }
  }
}

class CollegeScorecard {
  final String institutionName;
  final String? city;
  final String? state;
  final double? admissionRate;
  final double? completionRate;
  final int? medianDebt;
  final int? medianEarnings;
  final int? averageCost;
  final String? website;
  
  CollegeScorecard({
    required this.institutionName,
    this.city,
    this.state,
    this.admissionRate,
    this.completionRate,
    this.medianDebt,
    this.medianEarnings,
    this.averageCost,
    this.website,
  });
  
  factory CollegeScorecard.fromJson(Map<String, dynamic> json) {
    return CollegeScorecard(
      institutionName: json['institution_name'] ?? '',
      city: json['city'],
      state: json['state'],
      admissionRate: json['adm_rate']?.toDouble(),
      completionRate: json['completion_rate']?.toDouble(),
      medianDebt: json['median_debt'],
      medianEarnings: json['median_earnings'],
      averageCost: json['avg_net_price'],
      website: json['website'],
    );
  }
}

class CollegeSearchResult {
  final String name;
  final String? city;
  final String? state;
  final String? institutionType;
  final String unitId;
  
  CollegeSearchResult({
    required this.name,
    this.city,
    this.state,
    this.institutionType,
    required this.unitId,
  });
  
  factory CollegeSearchResult.fromJson(Map<String, dynamic> json) {
    return CollegeSearchResult(
      name: json['inst_name'] ?? '',
      city: json['city'],
      state: json['state'],
      institutionType: _getInstitutionType(json['inst_control']),
      unitId: json['unitid'].toString(),
    );
  }
  
  static String? _getInstitutionType(dynamic control) {
    if (control == null) return null;
    switch (control) {
      case 1: return 'Public';
      case 2: return 'Private nonprofit';
      case 3: return 'Private for-profit';
      default: return 'Other';
    }
  }
  
  String get fullLocation {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    return parts.join(', ');
  }
}

class DistrictStats {
  final String districtName;
  final String? city;
  final String? state;
  final int? totalSchools;
  final int? totalStudents;
  final String? phone;
  final String? website;
  
  DistrictStats({
    required this.districtName,
    this.city,
    this.state,
    this.totalSchools,
    this.totalStudents,
    this.phone,
    this.website,
  });
  
  factory DistrictStats.fromJson(Map<String, dynamic> json) {
    return DistrictStats(
      districtName: json['lea_name'] ?? '',
      city: json['city_location'],
      state: json['state_location'],
      totalSchools: json['number_of_schools'],
      totalStudents: json['enrollment'],
      phone: json['phone'],
      website: json['website'],
    );
  }
}

class StateEducationSummary {
  final String state;
  final int year;
  final int totalSchools;
  final int publicSchools;
  final int charterSchools;
  
  StateEducationSummary({
    required this.state,
    required this.year,
    required this.totalSchools,
    required this.publicSchools,
    required this.charterSchools,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'year': year,
      'totalSchools': totalSchools,
      'publicSchools': publicSchools,
      'charterSchools': charterSchools,
    };
  }
  
  factory StateEducationSummary.fromJson(Map<String, dynamic> json) {
    return StateEducationSummary(
      state: json['state'],
      year: json['year'],
      totalSchools: json['totalSchools'],
      publicSchools: json['publicSchools'],
      charterSchools: json['charterSchools'],
    );
  }
}
