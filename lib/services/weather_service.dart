import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Free OpenMeteo API - No API key required!
  static const String _baseUrl = 'https://api.open-meteo.com/v1';
  
  // Geocoding API for location search
  static const String _geocodingUrl = 'https://geocoding-api.open-meteo.com/v1';

  /// Get current weather and 7-day forecast for a location
  Future<WeatherData?> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?'
        'latitude=$latitude&'
        'longitude=$longitude&'
        'current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m&'
        'hourly=temperature_2m,precipitation_probability,weather_code&'
        'daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max&'
        'temperature_unit=fahrenheit&'
        'wind_speed_unit=mph&'
        'precipitation_unit=inch&'
        'timezone=auto&'
        'forecast_days=7'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  /// Search for a location by name
  Future<List<LocationResult>> searchLocation(String query) async {
    if (query.length < 2) return [];
    
    try {
      final url = Uri.parse(
        '$_geocodingUrl/search?'
        'name=${Uri.encodeComponent(query)}&'
        'count=5&'
        'language=en&'
        'format=json'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          return (data['results'] as List)
              .map((json) => LocationResult.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching location: $e');
      return [];
    }
  }

  /// Get weather for a specific event location
  Future<WeatherData?> getEventWeather(String locationName) async {
    final locations = await searchLocation(locationName);
    if (locations.isEmpty) return null;
    
    final location = locations.first;
    return getWeather(
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }
}

class WeatherData {
  final CurrentWeather current;
  final List<DailyForecast> daily;
  final List<HourlyForecast> hourly;
  final String timezone;

  WeatherData({
    required this.current,
    required this.daily,
    required this.hourly,
    required this.timezone,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final currentData = json['current'];
    final dailyData = json['daily'];
    final hourlyData = json['hourly'];

    return WeatherData(
      timezone: json['timezone'] ?? 'America/New_York',
      current: CurrentWeather(
        temperature: currentData['temperature_2m']?.toDouble() ?? 0.0,
        apparentTemperature: currentData['apparent_temperature']?.toDouble() ?? 0.0,
        humidity: currentData['relative_humidity_2m']?.toInt() ?? 0,
        precipitation: currentData['precipitation']?.toDouble() ?? 0.0,
        weatherCode: currentData['weather_code'] ?? 0,
        windSpeed: currentData['wind_speed_10m']?.toDouble() ?? 0.0,
      ),
      daily: List.generate(
        (dailyData['time'] as List).length,
        (index) => DailyForecast(
          date: DateTime.parse(dailyData['time'][index]),
          weatherCode: dailyData['weather_code'][index],
          maxTemp: dailyData['temperature_2m_max'][index]?.toDouble() ?? 0.0,
          minTemp: dailyData['temperature_2m_min'][index]?.toDouble() ?? 0.0,
          precipitationProbability: dailyData['precipitation_probability_max'][index]?.toInt() ?? 0,
          maxWindSpeed: dailyData['wind_speed_10m_max'][index]?.toDouble() ?? 0.0,
        ),
      ),
      hourly: List.generate(
        (hourlyData['time'] as List).length.clamp(0, 24),
        (index) => HourlyForecast(
          time: DateTime.parse(hourlyData['time'][index]),
          temperature: hourlyData['temperature_2m'][index]?.toDouble() ?? 0.0,
          precipitationProbability: hourlyData['precipitation_probability'][index]?.toInt() ?? 0,
          weatherCode: hourlyData['weather_code'][index],
        ),
      ),
    );
  }
}

class CurrentWeather {
  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final double precipitation;
  final int weatherCode;
  final double windSpeed;

  CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed,
  });

  String get condition => _getWeatherCondition(weatherCode);
  String get emoji => _getWeatherEmoji(weatherCode);
}

class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;
  final int precipitationProbability;
  final double maxWindSpeed;

  DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitationProbability,
    required this.maxWindSpeed,
  });

  String get condition => _getWeatherCondition(weatherCode);
  String get emoji => _getWeatherEmoji(weatherCode);
  String get dayName {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final int weatherCode;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  String get condition => _getWeatherCondition(weatherCode);
  String get emoji => _getWeatherEmoji(weatherCode);
  String get hour {
    final hour = time.hour;
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

class LocationResult {
  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  final String? admin1; // State/Province
  final String? admin2; // County

  LocationResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.admin1,
    this.admin2,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      name: json['name'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      country: json['country'],
      admin1: json['admin1'],
      admin2: json['admin2'],
    );
  }

  String get displayName {
    final parts = [name];
    if (admin1 != null) parts.add(admin1!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }
}

// Weather code mapping based on WMO codes
String _getWeatherCondition(int code) {
  if (code == 0) return 'Clear sky';
  if (code <= 3) return 'Partly cloudy';
  if (code <= 48) return 'Foggy';
  if (code <= 67) return 'Rainy';
  if (code <= 77) return 'Snowy';
  if (code <= 82) return 'Showers';
  if (code <= 86) return 'Snow showers';
  if (code <= 99) return 'Thunderstorm';
  return 'Unknown';
}

String _getWeatherEmoji(int code) {
  if (code == 0) return '☀️';
  if (code <= 3) return '⛅';
  if (code <= 48) return '🌫️';
  if (code <= 67) return '🌧️';
  if (code <= 77) return '❄️';
  if (code <= 82) return '🌦️';
  if (code <= 86) return '🌨️';
  if (code <= 99) return '⛈️';
  return '🌡️';
}
