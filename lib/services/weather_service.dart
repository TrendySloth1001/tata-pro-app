import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WeatherService {
  static const String apiKey = 'YOUR_API_KEY'; // OpenWeatherMap API key
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherData> getWeather(String city) async {
    try {
      // For development, return dummy data instead of making API call
      return WeatherData(
        temperature: 28.5,
        sunshine: 75.0,
        condition: 'Clear',
      );
    } catch (e) {
      debugPrint('Weather service error: $e');
      // Return default values if API fails
      return WeatherData(
        temperature: 25.0,
        sunshine: 50.0,
        condition: 'Unknown',
      );
    }
  }
}

class WeatherData {
  final double temperature;
  final double sunshine;
  final String condition;

  WeatherData({
    required this.temperature,
    required this.sunshine,
    required this.condition,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['main']['temp'].toDouble(),
      sunshine: json['clouds']['all'].toDouble(),
      condition: json['weather'][0]['main'],
    );
  }
}
