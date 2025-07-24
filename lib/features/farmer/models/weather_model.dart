class Weather {
  final double temperature;
  final String condition;
  // final String location;
  final double latitude;
  final double longitude;

  Weather({
    this.temperature = 0,
    this.condition = '',
    // this.location = '',
    this.latitude = 0,
    this.longitude = 0,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'] ?? '',
      // location: json['name'] ?? '',
      latitude: json['coord']['lat'] ?? 0,
      longitude: json['coord']['lon'] ?? 0,
    );
  }

  factory Weather.empty() => Weather();

  Map<String, dynamic> toJson() => {
    'main': {'temp': temperature},
    'weather': [
      {'main': condition},
    ],
    // 'name': location,
  };
}
