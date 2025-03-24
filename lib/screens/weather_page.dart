import 'package:flutter/material.dart';
import 'dart:async';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import 'package:fuzzy/fuzzy.dart';
import '../widgets/glass_container.dart';
import '../widgets/skeleton_loader.dart';

class WeatherPage extends StatefulWidget {
  final String title;
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const WeatherPage({
    super.key,
    required this.title,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  // Add these variables at the top of the class
  Weather? _weather;
  List<Weather>? _forecast;
  List<String> _suggestions = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _showSuggestions = false;

  // Add this method to get day names
  String _getDayName(DateTime date) {
    if (date.day == DateTime.now().day) return 'Today';
    if (date.day == DateTime.now().add(const Duration(days: 1)).day) {
      return 'Tomorrow';
    }

    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[date.weekday - 1];
  }

  // Add the weather color method
  Color _getWeatherColor(String weatherCondition) {
    weatherCondition = weatherCondition.toLowerCase();

    if (weatherCondition.contains('clear')) {
      return const Color(0xFF00E5FF); // Bright cyan
    } else if (weatherCondition.contains('rain')) {
      return const Color(0xFF536DFE); // Bright indigo
    } else if (weatherCondition.contains('cloud')) {
      return const Color(0xFF7C4DFF); // Deep purple
    } else if (weatherCondition.contains('thunder')) {
      return const Color(0xFFAA00FF); // Purple
    } else if (weatherCondition.contains('snow')) {
      return const Color(0xFF18FFFF); // Light cyan
    } else if (weatherCondition.contains('mist') ||
        weatherCondition.contains('fog')) {
      return const Color(0xFF64FFDA); // Teal
    } else {
      return const Color(0xFF00E5FF); // Default cyan
    }
  }

  // Add the weather gradient method
  LinearGradient _getWeatherGradient(String weatherCondition, bool isDarkMode) {
    weatherCondition = weatherCondition.toLowerCase();

    if (isDarkMode) {
      if (weatherCondition.contains('clear')) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D1B2A), // Darker space blue
            Color(0xFF1B263B), // Dark navy
          ],
        );
      } else if (weatherCondition.contains('rain')) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E), // Dark blue
            Color(0xFF16213E), // Navy
            Color(0xFF0F172A), // Deep blue
          ],
        );
      } else if (weatherCondition.contains('cloud')) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF0F172A),
          ],
        );
      } else if (weatherCondition.contains('thunder')) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF311B92),
          ],
        );
      } else if (weatherCondition.contains('snow')) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF0D47A1),
          ],
        );
      } else if (weatherCondition.contains('mist') ||
          weatherCondition.contains('fog')) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF0F172A),
          ],
        );
      }
    }

    // Light mode gradients (existing code)
    if (weatherCondition.contains('clear')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1A237E),
          Color(0xFF673AB7),
        ],
        stops: [0.2, 0.8],
      );
    } else if (weatherCondition.contains('rain')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0D47A1),
          Color(0xFF311B92),
          Color(0xFF4A148C),
        ],
      );
    }

    // Default gradient for both modes
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDarkMode
          ? const [Color(0xFF1A1A2E), Color(0xFF0F172A)]
          : const [Color(0xFF64B5F6), Color(0xFF1976D2)],
    );
  }

  // Add initialization
  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  // Add the weather service
  final WeatherService _weatherService = WeatherService();

  // Add loading method
  Future<void> _loadWeather([String? cityName]) async {
    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      if (cityName != null) {
        final weather = await _weatherService.getWeatherByCity(cityName);
        final forecast = await _weatherService.getForecast(cityName);
        setState(() {
          _weather = weather;
          _forecast = forecast;
          _error = null;
        });
      } else {
        final weather = await _weatherService.getWeather();
        final position = await _weatherService.getCurrentLocation();
        final forecast = await _weatherService.getForecastByCoordinates(
          position.latitude,
          position.longitude,
        );
        setState(() {
          _weather = weather;
          _forecast = forecast;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showErrorSnackBar(_error!);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Add error handling variables and methods
  String? _error;
  bool _isSearching = false;

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error.replaceAll('Exception: ', ''),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Update the fuzzy search method
  List<String> _getFuzzySuggestions(List<String> allCities, String query) {
    if (query.isEmpty) return [];

    final fuse = Fuzzy(
      allCities,
      options: FuzzyOptions(
        threshold: 0.4,
        keys: [
          WeightedKey(
            name: 'name',
            getter: (item) => item as String,
            weight: 1,
          ),
        ],
      ),
    );

    final results = fuse.search(query);
    return results.map((result) => result.item.toString()).take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final weatherCondition = _weather?.description ?? 'clear';
    final mainColor = _getWeatherColor(weatherCondition);
    final gradient = _getWeatherGradient(weatherCondition, widget.isDarkMode);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: GlassContainer(
                isDark: widget.isDarkMode,
                borderRadius: BorderRadius.circular(22.5),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: TextStyle(
                shadows: [
                  Shadow(
                    color: Colors.blue.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: GlassContainer(
          isDark: widget.isDarkMode,
          blur: 20,
          borderRadius: BorderRadius.zero,
          child: Container(),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
        child: Stack(
          children: [
            // Add subtle animated particles or grid background here
            Column(
              children: [
                SizedBox(
                    height:
                        MediaQuery.of(context).padding.top + kToolbarHeight),
                _buildSearchBar(),
                Expanded(
                  child: _isSearching
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        )
                      : _weather == null
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            )
                          : _buildWeatherInfo(),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: mainColor.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: GlassContainer(
          isDark: widget.isDarkMode,
          borderRadius: BorderRadius.circular(30),
          child: FloatingActionButton(
            onPressed: () => _loadWeather(),
            backgroundColor: Colors.transparent,
            child:
                Icon(Icons.my_location, color: Colors.white.withOpacity(0.9)),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo() {
    if (_isSearching || _weather == null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildCurrentWeatherSkeleton(),
            _buildHourlyForecastSkeleton(),
            const Divider(
              color: Colors.white24,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            _buildForecastSkeleton(),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCurrentWeather(),
          if (_forecast != null) ...[
            _buildHourlyForecast(),
            const Divider(
              color: Colors.white24,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            _buildForecast(),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    final isDark = widget.isDarkMode;
    final glowColor = isDark ? Colors.cyanAccent : Colors.blue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassContainer(
        isDark: isDark,
        blur: isDark ? 20 : 15,
        opacity: isDark ? 0.1 : 0.2,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: glowColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // AI Assistant Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyanAccent.withOpacity(0.5),
                      Colors.blueAccent.withOpacity(0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.android,
                  color: Colors.white.withOpacity(0.9),
                  size: 24,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _weather!.cityName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Last Update: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.cyanAccent.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_weather!.temperature.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withOpacity(0.9),
                      shadows: [
                        Shadow(
                          color: Colors.cyanAccent.withOpacity(0.8),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '°C',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.cyanAccent.withOpacity(0.9),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _weather!.description.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.cyanAccent,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWeatherDetail(
                    Icons.water_drop,
                    'HUMIDITY',
                    '${_weather!.humidity}%',
                  ),
                  _buildWeatherDetail(
                    Icons.air,
                    'WIND',
                    '${_weather!.windSpeed} m/s',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyForecast() {
    final isDark = widget.isDarkMode;
    final glowColor = isDark ? Colors.cyanAccent : Colors.blue;

    return Container(
      height: MediaQuery.of(context).size.height * 0.18,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _forecast!.length * 3,
        itemBuilder: (context, index) {
          final hour = DateTime.now().hour + index;
          final weather = _forecast![index ~/ 3];
          return Container(
            width: MediaQuery.of(context).size.width * 0.2,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: 8,
            ),
            child: GlassContainer(
              isDark: isDark,
              blur: isDark ? 15 : 10,
              opacity: isDark ? 0.1 : 0.2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: glowColor.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      '${hour % 24}:00',
                      style: TextStyle(
                        color: Colors.cyanAccent.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Image.network(
                        'https://openweathermap.org/img/w/${weather.icon}.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Text(
                      '${weather.temperature.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.cyanAccent,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForecast() {
    final isDark = widget.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _forecast!.length,
            itemBuilder: (context, index) {
              final weather = _forecast![index];
              final date = DateTime.now().add(Duration(days: index));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: GlassContainer(
                  isDark: isDark,
                  blur: isDark ? 15 : 10,
                  opacity: isDark ? 0.1 : 0.2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            _getDayName(date),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.blue.withOpacity(0.5),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.network(
                            'https://openweathermap.org/img/w/${weather.icon}.png',
                            scale: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${weather.temperature.toStringAsFixed(0)}°',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: Colors.blue.withOpacity(0.5),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.cyanAccent.withOpacity(0.9),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.cyanAccent,
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Update the _buildSearchBar method
  Widget _buildSearchBar() {
    final isDark = widget.isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.2),
                      ]
                    : [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.2),
                      ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search city...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon:
                    Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: Colors.white.withOpacity(0.7)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _suggestions = [];
                            _showSuggestions = false;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onChanged: (value) {
                if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                _debounceTimer =
                    Timer(const Duration(milliseconds: 500), () async {
                  if (value.length >= 2) {
                    final suggestions =
                        await _weatherService.getCitySuggestions(value);
                    if (mounted) {
                      setState(() {
                        _suggestions = _getFuzzySuggestions(suggestions, value);
                        _showSuggestions = _suggestions.isNotEmpty;
                      });
                    }
                  } else {
                    setState(() {
                      _suggestions = [];
                      _showSuggestions = false;
                    });
                  }
                });
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _loadWeather(value);
                  setState(() {
                    _showSuggestions = false;
                  });
                }
              },
            ),
          ),
          if (_showSuggestions)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    final parts = suggestion.split(',');

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _searchController.text = suggestion;
                          _loadWeather(parts[0].trim());
                          setState(() {
                            _showSuggestions = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: isDark ? Colors.white54 : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      parts[0].trim(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (parts.length > 1)
                                      Text(
                                        parts.sublist(1).join(',').trim(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Add this to dispose method
  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Add skeleton loader widgets
  Widget _buildCurrentWeatherSkeleton() {
    return GlassContainer(
      blur: 15,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SkeletonLoader(width: 200, height: 32),
            const SizedBox(height: 8),
            SkeletonLoader(width: 120, height: 16),
            const SizedBox(height: 20),
            SkeletonLoader(width: 150, height: 80),
            const SizedBox(height: 10),
            SkeletonLoader(width: 180, height: 24),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SkeletonLoader(width: 100, height: 40),
                SizedBox(width: 40),
                SkeletonLoader(width: 100, height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecastSkeleton() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.15,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.18,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: 8,
            ),
            child: GlassContainer(
              blur: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    SkeletonLoader(width: 40, height: 16),
                    SkeletonLoader(width: 40, height: 40),
                    SkeletonLoader(width: 30, height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForecastSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: List.generate(
          7,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: GlassContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 2,
                      child: SkeletonLoader(width: 100, height: 20),
                    ),
                    SizedBox(width: 16),
                    SkeletonLoader(width: 40, height: 40),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: SkeletonLoader(width: 40, height: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
