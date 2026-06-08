import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'dd549d14f548670d0853c92ec6f81ccd';
  const cityName = 'À¥Ã÷';

  print('=== Testing API for $cityName ===\n');

  try {
    print('1. Testing geocoding API...');
    final geoUrl = Uri.https(
      'api.openweathermap.org',
      '/geo/1.0/direct',
      {
        'q': cityName,
        'limit': '1',
        'appid': apiKey,
      },
    );
    print('URL: $geoUrl');
    
    final geoResponse = await http.get(geoUrl).timeout(const Duration(seconds: 10));
    print('Status: ${geoResponse.statusCode}');
    print('Body: ${geoResponse.body}\n');
    
    if (geoResponse.statusCode == 200) {
      final List<dynamic> data = json.decode(geoResponse.body);
      if (data.isNotEmpty) {
        final location = data[0];
        final lat = location['lat'];
        final lon = location['lon'];
        print('Found: ${location['name']}, lat=$lat, lon=$lon\n');
        
        print('2. Testing current weather API...');
        final weatherUrl = Uri.https(
          'api.openweathermap.org',
          '/data/2.5/weather',
          {
            'lat': lat.toString(),
            'lon': lon.toString(),
            'units': 'metric',
            'appid': apiKey,
          },
        );
        print('URL: $weatherUrl');
        
        final weatherResponse = await http.get(weatherUrl).timeout(const Duration(seconds: 10));
        print('Status: ${weatherResponse.statusCode}');
        print('Body: ${weatherResponse.body}\n');
        
        if (weatherResponse.statusCode == 200) {
          final weatherData = json.decode(weatherResponse.body);
          print('Temperature: ${weatherData['main']['temp']}¡ãC');
          print('Weather: ${weatherData['weather'][0]['main']}');
          print('\n=== API test successful! ===');
        }
      } else {
        print('City not found in geocoding response');
      }
    }
  } catch (e, stack) {
    print('Error: $e');
    print('Stack: $stack');
  }
}
