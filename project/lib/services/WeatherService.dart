import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/AppConfig.dart';

class WeatherService {
  final String _apiKey = AppConfig.openWeatherApiKey;

  Future<Map<String, String>> getWeatherRecommendation(double lat, double lng) async {
    if (_apiKey.isEmpty || _apiKey == "PLACEHOLDER_OPENWEATHER_KEY") {
      return {
        'title': 'Stay Prepared!',
        'body': 'Check the weather before you head out today.',
        'type': 'default'
      };
    }

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&appid=$_apiKey&units=metric'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final mainCondition = data['weather'][0]['main'].toString().toLowerCase();
        final temp = (data['main']['temp'] as num).toDouble();

        // 🌧️ Rainy conditions
        if (mainCondition.contains('rain') || 
            mainCondition.contains('drizzle') || 
            mainCondition.contains('thunderstorm')) {
          return {
            'title': 'Bring an Umbrella! ☔',
            'body': "It's a rainy day. Don't forget to take your umbrella with you.",
            'type': 'rain'
          };
        }

        // 🌡️ Hot condition (Industrial standard threshold: 30°C)
        if (temp >= 30.0) {
          return {
            'title': 'Stay Hydrated! 🍶',
            'body': "It's very hot today (${temp.toStringAsFixed(0)}°C). Remember to bring a water bottle.",
            'type': 'hot'
          };
        }

        // ☀️ Sunny condition
        if (mainCondition.contains('clear')) {
          return {
            'title': 'It\'s Sunny! ☀️',
            'body': "It's a beautiful sunny day. A water bottle might be a good idea.",
            'type': 'sunny'
          };
        }
      }
      
      return {
        'title': 'Have a safe trip!',
        'body': 'The journey has started. See you soon!',
        'type': 'default'
      };
    } catch (e) {
      return {
        'title': 'Journey Started',
        'body': 'Your bus is on the way!',
        'type': 'error'
      };
    }
  }

  Future<Map<String, String>> getDestinationForecast(double lat, double lng) async {
    if (_apiKey.isEmpty || _apiKey == "PLACEHOLDER_OPENWEATHER_KEY") {
      return {
        'title': 'Journey Update',
        'body': 'Stay safe on your trip!',
        'type': 'default'
      };
    }

    try {
      // Using the 5-day / 3-hour forecast API
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lng&appid=$_apiKey&units=metric'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List forecasts = data['list'];
        
        bool willRain = false;
        double maxTemp = -100.0;

        // Check the next 5 forecast slots (roughly the next 15 hours)
        for (var i = 0; i < 5 && i < forecasts.length; i++) {
          final forecast = forecasts[i];
          final condition = forecast['weather'][0]['main'].toString().toLowerCase();
          final temp = (forecast['main']['temp'] as num).toDouble();
          
          if (temp > maxTemp) maxTemp = temp;
          if (condition.contains('rain') || condition.contains('drizzle')) {
            willRain = true;
          }
        }

        if (willRain) {
          return {
            'title': 'Rain Alert at Destination! ☔',
            'body': "Rain is expected at your destination today. Don't forget your umbrella!",
            'type': 'rain'
          };
        }

        if (maxTemp >= 30.0) {
          return {
            'title': 'Hot Day Ahead! 🍶',
            'body': "It will be hot at your destination (${maxTemp.toStringAsFixed(0)}°C). Bring plenty of water.",
            'type': 'hot'
          };
        }
      }
      return {
        'title': 'Journey Started',
        'body': 'Weather looks clear at your destination.',
        'type': 'sunny'
      };
    } catch (e) {
      return {
        'title': 'Journey Started',
        'body': 'Safe travels!',
        'type': 'default'
      };
    }
  }
}
