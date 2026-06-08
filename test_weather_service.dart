import 'package:course_schedule/weather_service.dart';

void main() async {
  print('=== Testing WeatherService ===\n');

  final service = WeatherService();
  const cityName = 'À¥Ã÷';

  print('1. Testing getCurrentWeather...');
  try {
    final weather = await service.getCurrentWeather(cityName);
    if (weather != null) {
      print('? Weather: ${weather.weatherText}');
      print('? Temp: ${weather.tempNow}¡ãC');
      print('? Humidity: ${weather.humidity}%');
    } else {
      print('? Weather is null');
    }
  } catch (e, stack) {
    print('? Error: $e');
    print('Stack: $stack');
  }

  print('\n2. Testing getDailyForecast...');
  try {
    final forecast = await service.getDailyForecast(cityName);
    print('? Forecast count: ${forecast.length}');
    for (var i = 0; i < forecast.length; i++) {
      print('  $i: ${forecast[i].date}, ${forecast[i].tempMin}¡ãC ~ ${forecast[i].tempMax}¡ãC');
    }
  } catch (e, stack) {
    print('? Error: $e');
    print('Stack: $stack');
  }

  print('\n=== Test complete ===');
}
