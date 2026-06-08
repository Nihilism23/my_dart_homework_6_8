import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final String city;
  final String weatherText;
  final String weatherCode;
  final int tempNow;
  final int humidity;
  final String windDir;
  final String windScale;
  final int pressure;
  final String visibility;
  final String updateTime;

  WeatherData({
    required this.city,
    required this.weatherText,
    required this.weatherCode,
    required this.tempNow,
    required this.humidity,
    required this.windDir,
    required this.windScale,
    required this.pressure,
    required this.visibility,
    required this.updateTime,
  });
}

class DailyForecast {
  final String date;
  final String dayText;
  final String nightText;
  final int tempMax;
  final int tempMin;
  final String dayIcon;
  final String nightIcon;

  DailyForecast({
    required this.date,
    required this.dayText,
    required this.nightText,
    required this.tempMax,
    required this.tempMin,
    required this.dayIcon,
    required this.nightIcon,
  });
}

class WeatherService {
  static const String _apiKey = 'dd549d14f548670d0853c92ec6f81ccd';

  WeatherService();

  static const Map<int, String> weatherCodeMap = {
    200: 'Thunderstorm with light rain',
    201: 'Thunderstorm with rain',
    202: 'Thunderstorm with heavy rain',
    210: 'Light thunderstorm',
    211: 'Thunderstorm',
    212: 'Heavy thunderstorm',
    221: 'Ragged thunderstorm',
    230: 'Thunderstorm with light drizzle',
    231: 'Thunderstorm with drizzle',
    232: 'Thunderstorm with heavy drizzle',
    300: 'Light intensity drizzle',
    301: 'Drizzle',
    302: 'Heavy intensity drizzle',
    310: 'Light intensity drizzle rain',
    311: 'Drizzle rain',
    312: 'Heavy intensity drizzle rain',
    313: 'Shower rain and drizzle',
    314: 'Heavy shower rain and drizzle',
    321: 'Shower drizzle',
    500: 'Light rain',
    501: 'Moderate rain',
    502: 'Heavy intensity rain',
    503: 'Very heavy rain',
    504: 'Extreme rain',
    511: 'Freezing rain',
    520: 'Light intensity shower rain',
    521: 'Shower rain',
    522: 'Heavy intensity shower rain',
    531: 'Ragged shower rain',
    600: 'Light snow',
    601: 'Snow',
    602: 'Heavy snow',
    611: 'Sleet',
    612: 'Light shower sleet',
    613: 'Shower sleet',
    615: 'Light rain and snow',
    616: 'Rain and snow',
    620: 'Light shower snow',
    621: 'Shower snow',
    622: 'Heavy shower snow',
    701: 'Mist',
    711: 'Smoke',
    721: 'Haze',
    731: 'Sand/dust whirls',
    741: 'Fog',
    751: 'Sand',
    761: 'Dust',
    762: 'Volcanic ash',
    771: 'Squalls',
    781: 'Tornado',
    800: 'Clear sky',
    801: 'Few clouds',
    802: 'Scattered clouds',
    803: 'Broken clouds',
    804: 'Overcast clouds',
  };

  String _getWeatherText(int code) {
    return weatherCodeMap[code] ?? 'Unknown';
  }

  String _mapCodeToIcon(int code) {
    if (code == 800) return '100';
    if (code <= 804) return '101';
    if (code <= 781) return '501';
    if (code <= 622) return '400';
    if (code <= 531) return '300';
    if (code <= 321) return '305';
    if (code <= 232) return '302';
    return '999';
  }

  Future<Map<String, dynamic>?> getCityLocation(String cityName) async {
    try {
      print('=== Getting city location ===');
      print('City: $cityName');

      final url = Uri.https(
        'api.openweathermap.org',
        '/geo/1.0/direct',
        {
          'q': cityName,
          'limit': '1',
          'appid': _apiKey,
        },
      );
      print('Location URL: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Location request timed out');
          return http.Response('{"cod": 408, "message": "Request Timeout"}', 408);
        },
      );
      print('Location status: ${response.statusCode}');
      print('Location body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final location = data[0];
          print('Found city: ${location['name']}, coords: ${location['lat']}, ${location['lon']}');
          return {
            'lat': location['lat'],
            'lon': location['lon'],
            'name': cityName,
          };
        } else {
          print('City not found');
        }
      } else {
        print('Location request failed: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Location exception: $e');
      print('Stack: $stackTrace');
    }
    return null;
  }

  Future<WeatherData?> getCurrentWeather(String cityName) async {
    try {
      print('=== Getting current weather ===');
      print('City: $cityName');

      final location = await getCityLocation(cityName);
      if (location == null) {
        print('Unable to get location');
        return null;
      }

      final url = Uri.https(
        'api.openweathermap.org',
        '/data/2.5/weather',
        {
          'lat': location['lat'].toString(),
          'lon': location['lon'].toString(),
          'units': 'metric',
          'appid': _apiKey,
        },
      );
      print('Weather URL: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Weather request timed out');
          return http.Response('{"cod": 408, "message": "Request Timeout"}', 408);
        },
      );
      print('Weather status: ${response.statusCode}');
      print('Weather body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['weather'] != null && data['weather'].isNotEmpty) {
          final weather = data['weather'][0];
          final main = data['main'];
          final wind = data['wind'];
          final weatherCode = weather['id'] as int;
          final windSpeed = (wind['speed'] as num?)?.toDouble() ?? 0;
          final windDeg = (wind['deg'] as num?)?.toDouble() ?? 0;
          final visibility = (data['visibility'] as num?)?.toDouble() ?? 10000;

          print('Parsed data: $data');

          final weatherData = WeatherData(
            city: location['name'] ?? cityName,
            weatherText: _getWeatherText(weatherCode),
            weatherCode: _mapCodeToIcon(weatherCode),
            tempNow: (main['temp'] as num?)?.round() ?? 0,
            humidity: (main['humidity'] as num?)?.round() ?? 0,
            windDir: _mapWindDeg(windDeg),
            windScale: _mapWindSpeed(windSpeed),
            pressure: (main['pressure'] as num?)?.round() ?? 1013,
            visibility: (visibility / 1000).toStringAsFixed(1),
            updateTime: DateTime.now().toIso8601String(),
          );
          print('=== Weather success ===');
          return weatherData;
        }
      } else {
        print('Weather HTTP failed: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Weather exception: $e');
      print('Stack: $stackTrace');
    }
    print('=== Weather ended, return null ===');
    return null;
  }

  Future<List<DailyForecast>> getDailyForecast(String cityName) async {
    try {
      print('=== Getting 3-day forecast ===');
      print('City: $cityName');

      final location = await getCityLocation(cityName);
      if (location == null) {
        print('Unable to get location');
        return [];
      }

      final url = Uri.https(
        'api.openweathermap.org',
        '/data/2.5/forecast',
        {
          'lat': location['lat'].toString(),
          'lon': location['lon'].toString(),
          'units': 'metric',
          'appid': _apiKey,
        },
      );
      print('Forecast URL: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Forecast request timed out');
          return http.Response('{"cod": 408, "message": "Request Timeout"}', 408);
        },
      );
      print('Forecast status: ${response.statusCode}');
      print('Forecast body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['list'] != null) {
          final list = data['list'] as List;
          
          final Map<String, List<dynamic>> dailyData = {};
          for (var item in list) {
            final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
            final dateKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            if (!dailyData.containsKey(dateKey)) {
              dailyData[dateKey] = [];
            }
            dailyData[dateKey]!.add(item);
          }

          final forecast = <DailyForecast>[];
          int count = 0;
          for (var entry in dailyData.entries) {
            if (count >= 3) break;
            final items = entry.value;
            items.sort((a, b) => (a['main']['temp'] as num).compareTo(b['main']['temp'] as num));
            
            final minItem = items.first;
            final maxItem = items.last;
            final midItem = items[items.length ~/ 2];
            
            final weather = midItem['weather'][0];
            final weatherCode = weather['id'] as int;

            forecast.add(DailyForecast(
              date: entry.key,
              dayText: _getWeatherText(weatherCode),
              nightText: _getWeatherText(weatherCode),
              tempMax: (maxItem['main']['temp'] as num?)?.round() ?? 0,
              tempMin: (minItem['main']['temp'] as num?)?.round() ?? 0,
              dayIcon: _mapCodeToIcon(weatherCode),
              nightIcon: _mapCodeToIcon(weatherCode),
            ));
            count++;
          }

          print('=== Forecast success, ${forecast.length} days ===');
          return forecast;
        }
      } else {
        print('Forecast HTTP failed: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Forecast exception: $e');
      print('Stack: $stackTrace');
    }
    print('=== Forecast ended, return empty ===');
    return [];
  }

  Future<WeatherData?> get(String cityName) async {
    return await getCurrentWeather(cityName);
  }

  Future<List<DailyForecast>> days() async {
    return [];
  }

  String _mapWindDeg(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'N';
    if (deg >= 22.5 && deg < 67.5) return 'NE';
    if (deg >= 67.5 && deg < 112.5) return 'E';
    if (deg >= 112.5 && deg < 157.5) return 'SE';
    if (deg >= 157.5 && deg < 202.5) return 'S';
    if (deg >= 202.5 && deg < 247.5) return 'SW';
    if (deg >= 247.5 && deg < 292.5) return 'W';
    if (deg >= 292.5 && deg < 337.5) return 'NW';
    return '--';
  }

  String _mapWindSpeed(double speed) {
    if (speed < 0.3) return '0';
    if (speed < 1.6) return '1';
    if (speed < 3.4) return '2';
    if (speed < 5.5) return '3';
    if (speed < 8.0) return '4';
    if (speed < 10.8) return '5';
    if (speed < 13.9) return '6';
    if (speed < 17.2) return '7';
    if (speed < 20.8) return '8';
    return '9+';
  }
}

class WeatherIconHelper {
  static const Map<String, String> weatherTextMap = {
    '100': 'Sunny',
    '101': 'Cloudy',
    '102': 'Partly Cloudy',
    '103': 'Mostly Sunny',
    '104': 'Overcast',
    '150': 'Clear Night',
    '300': 'Shower',
    '301': 'Heavy Shower',
    '302': 'Thunderstorm',
    '303': 'Severe Thunderstorm',
    '304': 'Thunderstorm with Hail',
    '305': 'Light Rain',
    '306': 'Moderate Rain',
    '307': 'Heavy Rain',
    '308': 'Extreme Rain',
    '309': 'Drizzle',
    '310': 'Storm',
    '311': 'Heavy Storm',
    '312': 'Severe Storm',
    '313': 'Freezing Rain',
    '314': 'Light to Moderate Rain',
    '315': 'Moderate to Heavy Rain',
    '316': 'Heavy to Storm',
    '317': 'Storm to Heavy Storm',
    '318': 'Heavy to Severe Storm',
    '399': 'Rain',
    '400': 'Light Snow',
    '401': 'Moderate Snow',
    '402': 'Heavy Snow',
    '403': 'Blizzard',
    '404': 'Sleet',
    '405': 'Rain and Snow',
    '406': 'Shower Snow',
    '407': 'Snow Shower',
    '499': 'Snow',
    '500': 'Mist',
    '501': 'Fog',
    '502': 'Haze',
    '503': 'Sand',
    '504': 'Dust',
    '507': 'Sandstorm',
    '508': 'Severe Sandstorm',
    '509': 'Dense Fog',
    '510': 'Thick Fog',
    '511': 'Moderate Haze',
    '512': 'Heavy Haze',
    '513': 'Severe Haze',
    '514': 'Heavy Fog',
    '515': 'Extreme Fog',
    '900': 'Hot',
    '901': 'Cold',
    '999': 'Unknown',
  };

  static bool needUmbrella(String code) {
    final codeInt = int.tryParse(code) ?? 0;
    return codeInt >= 300 && codeInt < 500;
  }

  static String getWeatherType(String code) {
    final codeInt = int.tryParse(code) ?? 100;
    if (codeInt == 100 || codeInt == 150) return 'sunny';
    if (codeInt < 200) return 'cloudy';
    if (codeInt >= 300 && codeInt < 400) return 'rainy';
    if (codeInt >= 400 && codeInt < 500) return 'snowy';
    if (codeInt >= 500) return 'foggy';
    return 'sunny';
  }

  static String formatDateLabel(String dateStr, int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    if (index == 2) return 'Day after';
    try {
      final date = DateTime.parse(dateStr);
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } catch (_) {
      return dateStr;
    }
  }
}
