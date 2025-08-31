class Weather {
  final String location;
  final double latitude;
  final double longitude;
  // maps weatherMain
  final String condition;
  // maps weatherDescription
  final String description;
  // maps weatherIcon
  final String iconUrl;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final bool isDaytime;
  final DateTime? observationTime;

  Weather({
    this.location = '',
    this.latitude = 0,
    this.longitude = 0,
    this.condition = '',
    this.description = '',
    this.iconUrl = '',
    this.temperature = 0,
    this.feelsLike = 0,
    this.humidity = 0,
    this.windSpeed = 0,
    this.isDaytime = true,
    this.observationTime,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      location: json['location'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      condition: json['weatherMain'] ?? '',
      description: json['weatherDescription'] ?? '',
      iconUrl: json['weatherIcon'] ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      feelsLike: (json['feelsLike'] as num?)?.toDouble() ?? 0,
      humidity: json['humidity'] ?? 0,
      windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 0,
      isDaytime: json['isDaytime'] ?? true,
      observationTime:
          json['observationTime'] != null
              ? DateTime.tryParse(json['observationTime'])
              : null,
    );
  }

  // convert to json
  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'weatherMain': condition,
      'weatherDescription': description,
      'weatherIcon': iconUrl,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'isDaytime': isDaytime,
      'observationTime': observationTime?.toIso8601String(),
    };
  }

  factory Weather.empty() => Weather();

  factory Weather.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return Weather(
      location: data['location'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      condition: data['weatherMain'] ?? '',
      description: data['weatherDescription'] ?? '',
      iconUrl: data['weatherIcon'] ?? '',
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0,
      feelsLike: (data['feelsLike'] as num?)?.toDouble() ?? 0,
      humidity: data['humidity'] ?? 0,
      windSpeed: (data['windSpeed'] as num?)?.toDouble() ?? 0,
      isDaytime: data['isDaytime'] ?? true,
      observationTime:
          data['observationTime'] != null
              ? DateTime.tryParse(data['observationTime'])
              : null,
    );
  }
}
