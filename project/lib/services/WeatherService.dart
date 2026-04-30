import 'package:cloud_functions/cloud_functions.dart';

class WeatherService {
  final FirebaseFunctions _functions;

  WeatherService({FirebaseFunctions? functions}) 
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Fetches weather recommendation from the secure backend proxy.
  Future<Map<String, String>> getWeatherRecommendation(double lat, double lng) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getWeatherData');
      final result = await callable.call({
        'lat': lat,
        'lon': lng,
        'mode': 'weather',
      });

      final data = result.data as Map<String, dynamic>;
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

      // 🌡️ Hot condition
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

  /// Fetches destination forecast from the secure backend proxy.
  Future<Map<String, String>> getDestinationForecast(double lat, double lng) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getWeatherData');
      final result = await callable.call({
        'lat': lat,
        'lon': lng,
        'mode': 'forecast',
      });

      final data = result.data as Map<String, dynamic>;
      final List forecasts = data['list'];
      
      bool willRain = false;
      double maxTemp = -100.0;

      // Check the next 5 forecast slots
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
