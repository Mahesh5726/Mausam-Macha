import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';

class WeatherService {
  static String _apiKey =
      const String.fromEnvironment('OPENWEATHER_API_KEY');
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String _forecastUrl =
      'https://api.openweathermap.org/data/2.5/forecast';

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Weather> getWeather() async {
    try {
      final position = await getCurrentLocation();
      final response = await http.get(Uri.parse(
          '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric'));

      if (response.statusCode == 200) {
        return Weather.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error getting weather: $e');
    }
  }

  Future<Weather> getWeatherByCity(String cityName) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl?q=$cityName&appid=$_apiKey&units=metric'));

      if (response.statusCode == 200) {
        return Weather.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('City not found');
      }
    } catch (e) {
      throw Exception('Error getting weather: $e');
    }
  }

  Future<List<String>> getCitySuggestions(String query) async {
    if (query.length < 2) return [];

    try {
      // Using OpenWeatherMap's Geocoding API instead of GeoDB
      final response = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=100&appid=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> cities = jsonDecode(response.body);
        return cities.map((city) {
          String name = city['name'];
          String country = city['country'];
          String state = city['state'] ?? '';
          return state.isNotEmpty
              ? '$name, $state, $country'
              : '$name, $country';
        }).toList();
      } else {
        print('Error fetching suggestions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception in getCitySuggestions: $e');
      return [];
    }
  }

  Future<List<Weather>> getForecast(String cityName) async {
    try {
      final response = await http.get(
        Uri.parse('$_forecastUrl?q=$cityName&appid=$_apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['list'];

        Map<String, Weather> dailyForecasts = {};

        for (var item in list) {
          final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dateString = '${date.year}-${date.month}-${date.day}';

          if (!dailyForecasts.containsKey(dateString)) {
            dailyForecasts[dateString] = Weather.fromJson(item);
          }
        }

        return dailyForecasts.values.take(7).toList();
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      throw Exception('Error getting forecast: $e');
    }
  }

  Future<List<Weather>> getForecastByCoordinates(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_forecastUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['list'];

        Map<String, Weather> dailyForecasts = {};

        for (var item in list) {
          final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dateString = '${date.year}-${date.month}-${date.day}';

          if (!dailyForecasts.containsKey(dateString)) {
            dailyForecasts[dateString] = Weather.fromJson(item);
          }
        }

        return dailyForecasts.values.take(7).toList();
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      throw Exception('Error getting forecast: $e');
    }
  }
}
