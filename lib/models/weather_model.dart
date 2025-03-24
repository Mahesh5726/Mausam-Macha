class Weather {
  final double temperature;
  final String description;
  final double humidity;
  final double windSpeed;
  final String icon;
  final String cityName;

  Weather({
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
    required this.cityName,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      humidity: (json['main']['humidity'] as num).toDouble(),
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      icon: json['weather'][0]['icon'],
      cityName: json['name'] ?? 'Unknown Location',
    );
  }
}
