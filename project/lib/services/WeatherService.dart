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
}
