import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

class WeatherWidget extends StatefulWidget {
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final bool showForecast;

  const WeatherWidget({
    super.key,
    this.locationName,
    this.latitude,
    this.longitude,
    this.showForecast = false,
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final _weatherService = WeatherService();
  WeatherData? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      WeatherData? weather;

      if (widget.latitude != null && widget.longitude != null) {
        weather = await _weatherService.getWeather(
          latitude: widget.latitude!,
          longitude: widget.longitude!,
        );
      } else if (widget.locationName != null) {
        weather = await _weatherService.getEventWeather(widget.locationName!);
      }

      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoading = false;
          if (weather == null) {
            _error = 'Unable to load weather data';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading weather';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Text(
                'Loading weather...',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _weather == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.grey[400]),
              const SizedBox(width: 12),
              Text(
                _error ?? 'No weather data available',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCurrentWeather(isDark),
        if (widget.showForecast) ...[
          const SizedBox(height: 16),
          _buildHourlyForecast(isDark),
          const SizedBox(height: 16),
          _buildDailyForecast(isDark),
        ],
      ],
    );
  }

  Widget _buildCurrentWeather(bool isDark) {
    final current = _weather!.current;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Current Weather',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  current.emoji,
                  style: const TextStyle(fontSize: 60),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${current.temperature.round()}°F',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        current.condition,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherStat(
                    icon: Icons.thermostat,
                    label: 'Feels like',
                    value: '${current.apparentTemperature.round()}°F',
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildWeatherStat(
                    icon: Icons.water_drop,
                    label: 'Humidity',
                    value: '${current.humidity}%',
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildWeatherStat(
                    icon: Icons.air,
                    label: 'Wind',
                    value: '${current.windSpeed.round()} mph',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherStat({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Hourly Forecast',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _weather!.hourly.length,
                itemBuilder: (context, index) {
                  final hour = _weather!.hourly[index];
                  return Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hour.hour,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(hour.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          '${hour.temperature.round()}°',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyForecast(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '7-Day Forecast',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_weather!.daily.length, (index) {
              final day = _weather!.daily[index];
              final isToday = index == 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        isToday ? 'Today' : day.dayName,
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(day.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        day.condition,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                    if (day.precipitationProbability > 20) ...[
                      Icon(Icons.water_drop, size: 14, color: Colors.blue[300]),
                      const SizedBox(width: 4),
                      Text(
                        '${day.precipitationProbability}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[300],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      '${day.maxTemp.round()}°',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / ${day.minTemp.round()}°',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Compact weather badge for event cards
class WeatherBadge extends StatefulWidget {
  final String locationName;

  const WeatherBadge({
    super.key,
    required this.locationName,
  });

  @override
  State<WeatherBadge> createState() => _WeatherBadgeState();
}

class _WeatherBadgeState extends State<WeatherBadge> {
  final _weatherService = WeatherService();
  CurrentWeather? _current;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final weather = await _weatherService.getEventWeather(widget.locationName);
    if (mounted && weather != null) {
      setState(() {
        _current = weather.current;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_current == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_current!.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '${_current!.temperature.round()}°F',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
