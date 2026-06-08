import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'course.dart';
import 'database_helper.dart';
import 'csv_importer.dart';
import 'weather_service.dart';
import 'dart:async';

void main() async {
  if (kIsWeb) {
    try {
      await _initWebDatabase();
    } catch (e) {
      // ignore
    }
  }
  runApp(const MyApp());
}

Future<void> _initWebDatabase() async {
  // Web平台的数据库初始化
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 主题设置
  bool _isDarkMode = false;
  bool _followSystemTheme = false;
  Color _themeColor = Colors.blue;
  double _fontSize = 14;
  String _fontFamily = '默认字体';

  // 更新主题设置
  void updateTheme({
    bool? isDarkMode,
    bool? followSystemTheme,
    Color? themeColor,
    double? fontSize,
    String? fontFamily,
  }) {
    setState(() {
      if (isDarkMode != null) _isDarkMode = isDarkMode;
      if (followSystemTheme != null) _followSystemTheme = followSystemTheme;
      if (themeColor != null) _themeColor = themeColor;
      if (fontSize != null) _fontSize = fontSize;
      if (fontFamily != null) _fontFamily = fontFamily;
    });
  }

  // 获取当前主题设置
  bool get isDarkMode => _isDarkMode;
  bool get followSystemTheme => _followSystemTheme;
  Color get themeColor => _themeColor;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;

  @override
  Widget build(BuildContext context) {
    // 构建字体族
    String? fontFamilyValue = _fontFamily == '默认字体' ? null : _fontFamily;
    
    return MaterialApp(
      title: '校园课程表',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _themeColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: fontFamilyValue,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: _fontSize),
          bodyLarge: TextStyle(fontSize: _fontSize + 2),
          titleMedium: TextStyle(fontSize: _fontSize + 2),
          titleLarge: TextStyle(fontSize: _fontSize + 4),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _themeColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: fontFamilyValue,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: _fontSize),
          bodyLarge: TextStyle(fontSize: _fontSize + 2),
          titleMedium: TextStyle(fontSize: _fontSize + 2),
          titleLarge: TextStyle(fontSize: _fontSize + 4),
        ),
      ),
      themeMode: _followSystemTheme 
          ? ThemeMode.system 
          : (_isDarkMode ? ThemeMode.dark : ThemeMode.light),
      home: CourseSchedulePage(
        appTheme: this,
      ),
    );
  }
}

class CourseSchedulePage extends StatefulWidget {
  final _MyAppState? appTheme;
  
  const CourseSchedulePage({super.key, this.appTheme});

  @override
  State<CourseSchedulePage> createState() => _CourseSchedulePageState();
}

class _CourseSchedulePageState extends State<CourseSchedulePage> {
  List<Course> courses = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final List<String> weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  
  // 每节课的时间
  final List<String> periodTimes = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];
  
  // 当前周次（假设1-20周）
  int currentWeek = 1;
  final int maxWeeks = 20;
  final int maxPeriods = 8;
  
  // 月份和学期
  int currentMonth = DateTime.now().month;
  String currentSemester = '2025秋季';
  final List<String> semesters = ['2025春季', '2025秋季', '2026春季', '2026秋季'];
  
  // 底部导航当前选中索引
  int _currentBottomIndex = 0;
  
  // 备忘录列表
  final List<Map<String, dynamic>> _memos = [];
  
  // 个人中心设置
  String _userName = '未设置昵称';
  String _studentId = '未设置学号';
  String? _avatarPath;
  
  // 天气设置
  String _currentCity = '昆明';
  final List<String> _presetCities = ['北京', '天津', '石家庄', '太原', '呼和浩特', '沈阳', '长春', '哈尔滨', '上海', '南京', '杭州', '合肥', '福州', '南昌', '济南', '郑州', '武汉', '长沙', '广州', '南宁', '海口', '重庆', '成都', '贵阳', '昆明', '拉萨', '西安', '兰州', '西宁', '银川', '乌鲁木齐'];
  Map<String, dynamic>? _weatherData;
  String _weatherApiKey = '';
  WeatherData? _realWeatherData;
  List<DailyForecast> _forecastData = [];
  bool _isLoadingWeather = false;
  String? _weatherError;
  final List<String> _fontFamilies = ['默认字体', '宋体', '黑体', '楷体'];
  final List<Color> _presetColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];
  
  // 获取主题设置（从 App 级别）
  bool get _isDarkMode => widget.appTheme?.isDarkMode ?? false;
  bool get _followSystemTheme => widget.appTheme?.followSystemTheme ?? false;
  Color get _themeColor => widget.appTheme?.themeColor ?? Colors.blue;
  double get _fontSize => widget.appTheme?.fontSize ?? 14;
  String get _fontFamily => widget.appTheme?.fontFamily ?? '默认字体';

  // 滚动控制器
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  // 课程颜色列表
  final List<Color?> courseColors = [
    Colors.green[100], // 0 - 绿色
    Colors.blue[100], // 1 - 蓝色
    Colors.orange[100], // 2 - 橙色
    Colors.purple[100], // 3 - 紫色
    Colors.pink[100], // 4 - 粉色
    Colors.yellow[100], // 5 - 黄色
    Colors.cyan[100], // 6 - 青色
    Colors.red[100], // 7 - 红色
  ];

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _fetchWeather();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final loadedCourses = await _dbHelper.getAllCourses();
    setState(() {
      courses = loadedCourses;
    });
  }

  // 显示今天的课程
  void _showTodayCourses() {
    final now = DateTime.now();
    final currentDay = now.weekday; // 1=周一, 2=周二...
    
    // 获取今天的课程（根据当前周次过滤单双周）
    final todayCourses = courses.where((c) => c.dayOfWeek == currentDay && c.shouldShow(currentWeek)).toList();
    // 按节次排序
    todayCourses.sort((a, b) => a.period.compareTo(b.period));
    
    // 星期文字
    String dayText;
    if (currentDay >= 1 && currentDay <= 7) {
      dayText = weekDays[currentDay - 1];
    } else {
      dayText = '未知';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('今天 ($dayText) 的课程'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: todayCourses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '今天无课程',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '好好休息吧！',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: todayCourses.length,
                  itemBuilder: (context, index) {
                    final course = todayCourses[index];
                    return Card(
                      color: courseColors[course.colorIndex % courseColors.length],
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text('${course.period}'),
                        ),
                        title: Text(
                          course.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${course.classroom} · ${periodTimes[course.period - 1]}'),
                            if (course.weekType != 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: course.weekType == 1 ? Colors.orange[100] : Colors.purple[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  course.weekTypeText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: course.weekType == 1 ? Colors.orange[800] : Colors.purple[800],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditCourseDialog(course);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 月份选择器
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: currentMonth,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  onChanged: (int? newValue) {
                    setState(() {
                      currentMonth = newValue!;
                    });
                  },
                  items: List.generate(12, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text('${index + 1}月'),
                    );
                  }),
                ),
              ),
              // 学期选择器
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentSemester,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 12),
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                  onChanged: (String? newValue) {
                    setState(() {
                      currentSemester = newValue!;
                    });
                  },
                  items: semesters.map((semester) {
                    return DropdownMenuItem<String>(
                      value: semester,
                      child: Text(semester, style: const TextStyle(fontSize: 10)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 100,
        title: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: currentWeek,
            icon: const Icon(Icons.arrow_drop_down),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            onChanged: (int? newValue) {
              setState(() {
                currentWeek = newValue!;
              });
              // 这里可以添加切换周次后的逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('切换到第 $currentWeek 周')),
              );
            },
            items: List.generate(maxWeeks, (index) {
              return DropdownMenuItem<int>(
                value: index + 1,
                child: Text('第 ${index + 1} 周'),
              );
            }),
          ),
        ),
        centerTitle: true,
        actions: [
          // 今天按钮
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: '今天',
            onPressed: _showTodayCourses,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'import') {
                _showImportDialog();
              } else if (value == 'template') {
                _showTemplateDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file),
                    SizedBox(width: 8),
                    Text('导入CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('查看模板'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _currentBottomIndex == 0
          ? _buildSchedulePage()
          : _currentBottomIndex == 1
              ? _buildMemoPage()
              : _currentBottomIndex == 2
                  ? _buildWeatherPage()
                  : _buildProfilePage(),
      floatingActionButton: _currentBottomIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddCourseDialog,
              tooltip: '添加课程',
              child: const Icon(Icons.add),
            )
          : _currentBottomIndex == 2
              ? FloatingActionButton(
                  onPressed: _showCityPicker,
                  tooltip: '切换城市',
                  child: const Icon(Icons.location_city),
                )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomIndex,
        onTap: (index) {
          setState(() {
            _currentBottomIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // 超过3个按钮时必须设置
        selectedItemColor: _themeColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '课程表',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt),
            label: '备忘录',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny),
            label: '天气',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  // 构建课程表页面
  Widget _buildSchedulePage() {
    return SingleChildScrollView(
      controller: _horizontalController,
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        controller: _verticalController,
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // 表头
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      color: Colors.grey[200],
                    ),
                    child: const Center(child: Text('节次')),
                  ),
                  ...weekDays.map(
                    (day) => Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        color: Colors.blue[100],
                      ),
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // 课程表格
              ...List.generate(maxPeriods, (periodIndex) {
                int period = periodIndex + 1;
                return Row(
                  children: [
                    Container(
                      width: 50,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        color: Colors.grey[200],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '第$period节',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              periodTimes[period - 1],
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ...List.generate(7, (dayIndex) {
                      int day = dayIndex + 1;
                      final courseList = courses.where(
                        (c) => c.dayOfWeek == day && c.period == period && c.shouldShow(currentWeek),
                      ).toList();
                      final course =
                          courseList.isNotEmpty ? courseList.first : null;

                      return GestureDetector(
                        onTap: course != null
                            ? () => _showEditCourseDialog(course!)
                            : null,
                        onLongPress: course != null
                            ? () => _deleteCourse(course!)
                            : null,
                        child: Container(
                          width: 100,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            color: course != null
                                ? courseColors[
                                    course.colorIndex % courseColors.length]
                                : Colors.white,
                          ),
                          child: course != null
                              ? Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        course.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        course.classroom,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      // 显示单双周标识
                                      if (course.weekType != 0)
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: course.weekType == 1 ? Colors.orange[100] : Colors.purple[100],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            course.weekTypeText,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: course.weekType == 1 ? Colors.orange[800] : Colors.purple[800],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 构建备忘录页面
  Widget _buildMemoPage() {
    return Scaffold(
      body: _memos.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '暂无备忘录',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '点击右下角 + 号添加',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _memos.length,
              itemBuilder: (context, index) {
                final memo = _memos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.note, color: Colors.blue),
                    title: Text(
                      memo['title'] ?? '无标题',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      memo['content'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          memo['date'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _memos.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    onTap: () => _showMemoDetail(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemoDialog,
        tooltip: '添加备忘录',
        child: const Icon(Icons.add),
      ),
    );
  }

  // 显示添加备忘录对话框
  void _showAddMemoDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加备忘录'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '请输入标题',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '内容',
                  hintText: '请输入内容',
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty || contentController.text.isNotEmpty) {
                setState(() {
                  _memos.add({
                    'title': titleController.text.isEmpty ? '无标题' : titleController.text,
                    'content': contentController.text,
                    'date': '${DateTime.now().month}/${DateTime.now().day}',
                  });
                });
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 显示备忘录详情
  void _showMemoDetail(int index) {
    final memo = _memos[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(memo['title'] ?? '无标题'),
        content: SingleChildScrollView(
          child: Text(memo['content'] ?? ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 构建天气页面
  Widget _buildWeatherPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前城市卡片
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: const Text('当前城市'),
              subtitle: Text(_currentCity),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: _isLoadingWeather
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: _isLoadingWeather ? null : _fetchWeather,
                    tooltip: '刷新天气',
                  ),
                  TextButton(
                    onPressed: _showCityPicker,
                    child: const Text('切换'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 天气主卡片
          _buildWeatherMainCard(),
          const SizedBox(height: 16),
          // 天气详情
          _buildWeatherDetailsCard(),
          const SizedBox(height: 16),
          // 未来天气预报
          _buildForecastCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // 拉取真实天气
  Future<void> _fetchWeather() async {
    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
    });
    try {
      final service = WeatherService();
      final weather = await service.getCurrentWeather(_currentCity);
      final forecast = await service.getDailyForecast(_currentCity);
      setState(() {
        _realWeatherData = weather;
        _forecastData = forecast;
        _isLoadingWeather = false;
        if (weather == null) {
          _weatherError = '获取天气失败，请检查城市名称';
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingWeather = false;
        _weatherError = '网络错误: $e';
      });
    }
  }

  // 天气主卡片
  Widget _buildWeatherMainCard() {
    String weatherType = 'sunny';
    if (_realWeatherData != null) {
      weatherType = WeatherIconHelper.getWeatherType(_realWeatherData!.weatherCode);
    }

    final gradientColors = {
      'sunny': [Colors.blue[400]!, Colors.blue[700]!],
      'cloudy': [Colors.blueGrey[300]!, Colors.blueGrey[600]!],
      'rainy': [Colors.indigo[300]!, Colors.indigo[700]!],
      'snowy': [Colors.lightBlue[200]!, Colors.lightBlue[500]!],
      'foggy': [Colors.grey[400]!, Colors.grey[700]!],
    };
    final colors = gradientColors[weatherType] ?? [Colors.blue[400]!, Colors.blue[700]!];

    final weatherIcons = {
      'sunny': Icons.wb_sunny,
      'cloudy': Icons.wb_cloudy,
      'rainy': Icons.water_drop,
      'snowy': Icons.ac_unit,
      'foggy': Icons.cloud,
    };
    final icon = weatherIcons[weatherType] ?? Icons.wb_sunny;

    final tempText = _realWeatherData != null ? '${_realWeatherData!.tempNow}°C' : '25°C';
    final weatherText = _realWeatherData?.weatherText ?? '晴天';
    final needUmbrella = _realWeatherData != null
        && WeatherIconHelper.needUmbrella(_realWeatherData!.weatherCode);

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (_weatherError != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_weatherError!, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            Icon(icon, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(weatherText, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(tempText, style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$_currentCity · 今天', style: const TextStyle(fontSize: 16, color: Colors.white70)),
            if (needUmbrella) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.umbrella, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('今天有雨，记得带伞！', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
            if (_realWeatherData != null && _realWeatherData!.updateTime.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '更新时间：${_realWeatherData!.updateTime}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 天气详情卡片
  Widget _buildWeatherDetailsCard() {
    final humidity = _realWeatherData != null ? '${_realWeatherData!.humidity}%' : '65%';
    final wind = _realWeatherData != null
        ? '${_realWeatherData!.windDir} ${_realWeatherData!.windScale}级'
        : '3级';
    final pressure = _realWeatherData != null ? '${_realWeatherData!.pressure}hPa' : '1013hPa';
    final visibility = _realWeatherData != null ? '${_realWeatherData!.visibility}km' : '10km';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('天气详情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetailItem(Icons.water_drop, '湿度', humidity),
                _buildWeatherDetailItem(Icons.air, '风速', wind),
                _buildWeatherDetailItem(Icons.compress, '气压', pressure),
                _buildWeatherDetailItem(Icons.visibility, '能见度', visibility),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 天气详情项
  Widget _buildWeatherDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // 未来天气预报
  Widget _buildForecastCard() {
    final bool hasReal = _forecastData.isNotEmpty;
    final weatherIcons = {
      'sunny': Icons.wb_sunny,
      'cloudy': Icons.wb_cloudy,
      'rainy': Icons.water_drop,
      'snowy': Icons.ac_unit,
      'foggy': Icons.cloud,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('未来预报', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (hasReal)
              ..._forecastData.asMap().entries.map((entry) {
                final i = entry.key;
                final f = entry.value;
                final wType = WeatherIconHelper.getWeatherType(f.dayIcon);
                return ListTile(
                  leading: Icon(weatherIcons[wType] ?? Icons.wb_sunny, color: Colors.blue),
                  title: Text(WeatherIconHelper.formatDateLabel(f.date, i)),
                  subtitle: Text(f.dayText),
                  trailing: Text('${f.tempMin}°/${f.tempMax}°', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList()
            else ...[
              ListTile(leading: const Icon(Icons.wb_cloudy, color: Colors.blue), title: const Text('明天'), subtitle: const Text('多云'), trailing: const Text('22°/28°', style: TextStyle(fontWeight: FontWeight.bold))),
              ListTile(leading: const Icon(Icons.water_drop, color: Colors.blue), title: const Text('后天'), subtitle: const Text('小雨'), trailing: const Text('20°/25°', style: TextStyle(fontWeight: FontWeight.bold))),
              ListTile(leading: const Icon(Icons.wb_sunny, color: Colors.blue), title: const Text('周四'), subtitle: const Text('晴'), trailing: const Text('23°/29°', style: TextStyle(fontWeight: FontWeight.bold))),
              ListTile(leading: const Icon(Icons.wb_sunny, color: Colors.blue), title: const Text('周五'), subtitle: const Text('晴'), trailing: const Text('24°/30°', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ],
        ),
      ),
    );
  }

  // 显示城市选择器
  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('选择城市', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCustomCityInput();
                    },
                    child: const Text('自定义'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _presetCities.length,
                itemBuilder: (context, index) {
                  final city = _presetCities[index];
                  return ListTile(
                    title: Text(city),
                    trailing: _currentCity == city ? Icon(Icons.check, color: _themeColor) : null,
                    onTap: () {
                      setState(() {
                        _currentCity = city;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已切换到 $city')),
                      );
                      _fetchWeather();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 显示自定义城市输入
  void _showCustomCityInput() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入城市名称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入城市名',
            prefixIcon: Icon(Icons.location_city),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _currentCity = controller.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已切换到 ${_currentCity}')),
                );
                _fetchWeather();
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 构建个人中心页面
  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // 头像
          GestureDetector(
            onTap: _showAvatarOptions,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: _themeColor.withOpacity(0.2),
              backgroundImage: null,
              child: Icon(Icons.person, size: 50, color: _themeColor),
            ),
          ),
          const SizedBox(height: 16),
          // 昵称
          GestureDetector(
            onTap: _editUserInfo,
            child: Column(
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _themeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '学号: $_studentId',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  '点击编辑个人信息',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 设置列表
          Card(
            child: Column(
              children: [
                // 跟随系统主题
                ListTile(
                  leading: const Icon(Icons.brightness_auto),
                  title: const Text('跟随系统主题'),
                  trailing: Switch(
                    value: _followSystemTheme,
                    onChanged: (value) {
                      widget.appTheme?.updateTheme(followSystemTheme: value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(value ? '已开启跟随系统主题' : '已关闭跟随系统主题')),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                // 深色模式
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('深色模式'),
                  enabled: !_followSystemTheme,
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: _followSystemTheme
                        ? null
                        : (value) {
                            widget.appTheme?.updateTheme(isDarkMode: value);
                          },
                  ),
                ),
                const Divider(height: 1),
                // 主题颜色
                ListTile(
                  leading: Icon(Icons.color_lens, color: _themeColor),
                  title: const Text('主题颜色'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _themeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: _showThemeColorPicker,
                ),
                const Divider(height: 1),
                // 字体大小
                ListTile(
                  leading: const Icon(Icons.format_size),
                  title: const Text('字体大小'),
                  trailing: Text('${_fontSize.toInt()}'),
                  onTap: _showFontSizePicker,
                ),
                const Divider(height: 1),
                // 字体选择
                ListTile(
                  leading: const Icon(Icons.font_download),
                  title: const Text('字体选择'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_fontFamily),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: _showFontFamilyPicker,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('课程提醒'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('提醒设置开发中...')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 关于与帮助
          Card(
            child: Column(
              children: [
                // 版本信息
                ListTile(
                  leading: const Icon(Icons.new_releases, color: Colors.blue),
                  title: const Text('版本信息'),
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('v1.0.0', style: TextStyle(color: Colors.grey)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: _showVersionInfo,
                ),
                const Divider(height: 1),
                // 使用教程
                ListTile(
                  leading: const Icon(Icons.school, color: Colors.green),
                  title: const Text('使用教程'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showTutorial,
                ),
                const Divider(height: 1),
                // 反馈建议
                ListTile(
                  leading: const Icon(Icons.feedback, color: Colors.orange),
                  title: const Text('反馈建议'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showFeedback,
                ),
                const Divider(height: 1),
                // 检查更新
                ListTile(
                  leading: const Icon(Icons.system_update, color: Colors.purple),
                  title: const Text('检查更新'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _checkForUpdates,
                ),
                const Divider(height: 1),
                // 关于
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('关于'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: '校园课程表',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2025 校园课程表',
                    );
                  },
                ),
              ],
            ),
          ),
          // 添加底部间距，避免被导航栏遮挡
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // 显示版本信息
  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.new_releases, color: Colors.blue),
            SizedBox(width: 8),
            Text('版本信息'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('校园课程表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('当前版本: v1.0.0', style: TextStyle(fontSize: 14)),
            SizedBox(height: 4),
            Text('构建日期: 2025年3月', style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 16),
            Text('版本说明:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('• 初始版本发布', style: TextStyle(fontSize: 13)),
            Text('• 支持课程表管理', style: TextStyle(fontSize: 13)),
            Text('• 支持备忘录功能', style: TextStyle(fontSize: 13)),
            Text('• 支持个性化设置', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 显示使用教程
  void _showTutorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.green),
            SizedBox(width: 8),
            Text('使用教程'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTutorialItem('1', '添加课程', '点击课程表右下角的 + 按钮，填写课程名称、教室、星期和节次即可添加课程。'),
                const SizedBox(height: 12),
                _buildTutorialItem('2', '编辑/删除课程', '点击已添加的课程可以编辑，长按课程可以删除。'),
                const SizedBox(height: 12),
                _buildTutorialItem('3', '查看今天课程', '点击右上角的「今天」按钮，可以快速查看今天的所有课程。'),
                const SizedBox(height: 12),
                _buildTutorialItem('4', '切换周次', '点击顶部中间的周次选择器，可以切换查看不同周的课程安排。'),
                const SizedBox(height: 12),
                _buildTutorialItem('5', '使用备忘录', '点击底部导航的「备忘录」，可以添加和管理待办事项。'),
                const SizedBox(height: 12),
                _buildTutorialItem('6', '个性化设置', '在「我的」页面可以修改头像、昵称、主题颜色、深色模式等。'),
                const SizedBox(height: 12),
                _buildTutorialItem('7', '导入课程', '点击右上角的菜单，选择「导入CSV」可以批量导入课程。'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  // 构建教程条目
  Widget _buildTutorialItem(String number, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(content, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  // 显示反馈建议
  void _showFeedback() {
    final feedbackController = TextEditingController();
    final contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.feedback, color: Colors.orange),
            SizedBox(width: 8),
            Text('反馈建议'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('您的建议对我们很重要！', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  labelText: '问题或建议',
                  hintText: '请描述您遇到的问题或建议...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: '联系方式（可选）',
                  hintText: '邮箱或QQ，方便我们回复您',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (feedbackController.text.isNotEmpty) {
                // 这里可以添加提交反馈的逻辑
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('感谢您的反馈！我们会认真考虑您的建议。')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入反馈内容')),
                );
              }
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }

  // 检查更新
  void _checkForUpdates() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.purple),
            SizedBox(width: 8),
            Text('检查更新'),
          ],
        ),
        content: const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('正在检查更新...'),
          ],
        ),
      ),
    );

    // 模拟检查更新
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('已是最新版本'),
            ],
          ),
          content: const Text('当前 v1.0.0 已是最新版本，无需更新。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    });
  }

  // 显示头像选项
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickAvatarFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('拍照功能暂不支持')),
                );
              },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除头像', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _avatarPath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // 从相册选择头像
  Future<void> _pickAvatarFromGallery() async {
    // 桌面端使用文件选择器
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _avatarPath = result.files.single.path;
      });
    }
  }

  // 编辑用户信息
  void _editUserInfo() {
    final nameController = TextEditingController(text: _userName == '未设置昵称' ? '' : _userName);
    final idController = TextEditingController(text: _studentId == '未设置学号' ? '' : _studentId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑个人信息'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '昵称',
                  hintText: '请输入昵称',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: '学号',
                  hintText: '请输入学号',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (nameController.text.isNotEmpty) {
                  _userName = nameController.text;
                }
                if (idController.text.isNotEmpty) {
                  _studentId = idController.text;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 显示主题颜色选择器
  void _showThemeColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择主题颜色',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // 预设颜色
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presetColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      widget.appTheme?.updateTheme(themeColor: color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _themeColor == color
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: _themeColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // 自定义颜色按钮
              ListTile(
                leading: const Icon(Icons.colorize),
                title: const Text('自定义颜色'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showCustomColorPicker();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示自定义颜色选择器
  void _showCustomColorPicker() {
    // 简化的自定义颜色选择
    final colors = [
      Colors.red[100], Colors.red[300], Colors.red[500], Colors.red[700], Colors.red[900],
      Colors.orange[100], Colors.orange[300], Colors.orange[500], Colors.orange[700], Colors.orange[900],
      Colors.yellow[100], Colors.yellow[300], Colors.yellow[500], Colors.yellow[700], Colors.yellow[900],
      Colors.green[100], Colors.green[300], Colors.green[500], Colors.green[700], Colors.green[900],
      Colors.blue[100], Colors.blue[300], Colors.blue[500], Colors.blue[700], Colors.blue[900],
      Colors.purple[100], Colors.purple[300], Colors.purple[500], Colors.purple[700], Colors.purple[900],
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  widget.appTheme?.updateTheme(themeColor: colors[index]);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  // 显示字体大小选择器
  void _showFontSizePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '字体大小',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Slider(
                        value: _fontSize,
                        min: 12,
                        max: 24,
                        divisions: 12,
                        label: _fontSize.toInt().toString(),
                        onChanged: (value) {
                          setState(() {
                            widget.appTheme?.updateTheme(fontSize: value);
                          });
                        },
                      ),
                      Text(
                        '预览文字 ${_fontSize.toInt()}',
                        style: TextStyle(fontSize: _fontSize),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示字体选择器
  void _showFontFamilyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _fontFamilies.map((font) {
            return ListTile(
              title: Text(font),
              trailing: _fontFamily == font ? const Icon(Icons.check) : null,
              onTap: () {
                widget.appTheme?.updateTheme(fontFamily: font);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // 显示导入对话框
  void _showImportDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入CSV'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              const Text(
                '请粘贴CSV格式的课程数据：',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: '课程名称,教室,星期,节次,颜色\n数学,教室A,1,1,0',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                _importFromText(text);
              }
              Navigator.pop(context);
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  // 从文本导入
  Future<void> _importFromText(String text) async {
    try {
      final importedCourses = CsvImporter.parseFromText(text);

      if (importedCourses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未找到课程信息，请检查格式')),
        );
        return;
      }

      // 显示预览
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('找到 ${importedCourses.length} 门课程'),
          content: SizedBox(
            width: double.maxFinite,
            height: 200,
            child: ListView.builder(
              itemCount: importedCourses.length,
              itemBuilder: (context, index) {
                final c = importedCourses[index];
                return ListTile(
                  dense: true,
                  title: Text(c.name),
                  subtitle:
                      Text('周${c.dayOfWeek} 第${c.period}节 ${c.classroom}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                for (var course in importedCourses) {
                  await _dbHelper.insertCourse(course);
                }
                await _loadCourses();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('成功导入 ${importedCourses.length} 门课程')),
                );
              },
              child: const Text('确认导入'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  // 显示模板
  void _showTemplateDialog() {
    final template = CsvImporter.getTemplate();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV格式说明'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '请按以下格式准备数据：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: SelectableText(template),
              ),
              const SizedBox(height: 16),
              const Text('说明：'),
              const Text('• 星期：1=周一, 2=周二, ..., 7=周日'),
              const Text('• 节次：1-12，对应第几节课'),
              const Text('• 颜色：0-7，对应不同颜色'),
              const Text('• 周次类型：每周/单周/双周'),
              const SizedBox(height: 8),
              const Text(
                '提示：可以用Excel编辑后复制粘贴',
                style: TextStyle(color: Colors.blue),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showAddCourseDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController classroomController = TextEditingController();
    int selectedDay = 1;
    int selectedPeriod = 1;
    int selectedColor = 0;
    int selectedWeekType = 0; // 0=每周, 1=单周, 2=双周

    // 周次类型选项
    final List<Map<String, dynamic>> weekTypes = [
      {'value': 0, 'label': '每周', 'icon': Icons.calendar_today},
      {'value': 1, 'label': '单周', 'icon': Icons.looks_one},
      {'value': 2, 'label': '双周', 'icon': Icons.looks_two},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加课程'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '课程名称'),
                    ),
                    TextField(
                      controller: classroomController,
                      decoration: const InputDecoration(labelText: '教室'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('星期：'),
                        DropdownButton<int>(
                          value: selectedDay,
                          items: List.generate(7, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text(weekDays[index]),
                            );
                          }),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedDay = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('节次：'),
                        DropdownButton<int>(
                          value: selectedPeriod,
                          items: List.generate(8, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text('第${index + 1}节'),
                            );
                          }),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedPeriod = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('颜色：'),
                        DropdownButton<int>(
                          value: selectedColor,
                          items: List.generate(courseColors.length, (index) {
                            return DropdownMenuItem(
                              value: index,
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    color: courseColors[index],
                                    margin: const EdgeInsets.only(right: 8),
                                  ),
                                  Text('颜色${index + 1}'),
                                ],
                              ),
                            );
                          }),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedColor = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('周次类型：', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    // 周次类型选择
                    Row(
                      children: weekTypes.map((type) {
                        final isSelected = selectedWeekType == type['value'];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedWeekType = type['value'];
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? _themeColor.withOpacity(0.2) : Colors.grey[200],
                                  border: Border.all(
                                    color: isSelected ? _themeColor : Colors.grey,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      type['icon'],
                                      color: isSelected ? _themeColor : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      type['label'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected ? _themeColor : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      try {
                        final newCourse = Course(
                          name: nameController.text,
                          classroom: classroomController.text.isEmpty
                              ? '待定'
                              : classroomController.text,
                          dayOfWeek: selectedDay,
                          period: selectedPeriod,
                          colorIndex: selectedColor,
                          weekType: selectedWeekType,
                        );
                        await _dbHelper.insertCourse(newCourse);
                        await _loadCourses();
                        Navigator.pop(context);
                      } catch (e) {
                        print('添加课程出错: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('添加失败: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCourse(Course course) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除 "${course.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (course.id != null) {
                await _dbHelper.deleteCourse(course.id!);
                await _loadCourses();
              }
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(Course course) {
    final TextEditingController nameController =
        TextEditingController(text: course.name);
    final TextEditingController classroomController =
        TextEditingController(text: course.classroom);
    int selectedDay = course.dayOfWeek;
    int selectedPeriod = course.period;
    int selectedColor = course.colorIndex;
    int selectedWeekType = course.weekType;

    // 周次类型选项
    final List<Map<String, dynamic>> weekTypes = [
      {'value': 0, 'label': '每周', 'icon': Icons.calendar_today},
      {'value': 1, 'label': '单周', 'icon': Icons.looks_one},
      {'value': 2, 'label': '双周', 'icon': Icons.looks_two},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('编辑课程'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '课程名称'),
                    ),
                    TextField(
                      controller: classroomController,
                      decoration: const InputDecoration(labelText: '教室'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('星期：'),
                        DropdownButton<int>(
                          value: selectedDay,
                          items: List.generate(7, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text(weekDays[index]),
                            );
                          }),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedDay = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('节次：'),
                        DropdownButton<int>(
                          value: selectedPeriod,
                          items: List.generate(8, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text('第${index + 1}节'),
                            );
                          }),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedPeriod = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('颜色：'),
                        DropdownButton<int>(
                          value: selectedColor,
                          items: List.generate(courseColors.length, (index) {
                            return DropdownMenuItem(
                              value: index,
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    color: courseColors[index],
                                    margin: const EdgeInsets.only(right: 8),
                                  ),
                                  Text('颜色${index + 1}'),
                                ],
                              ),
                            );
                          }),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedColor = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('周次类型：', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    // 周次类型选择
                    Row(
                      children: weekTypes.map((type) {
                        final isSelected = selectedWeekType == type['value'];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedWeekType = type['value'];
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? _themeColor.withOpacity(0.2) : Colors.grey[200],
                                  border: Border.all(
                                    color: isSelected ? _themeColor : Colors.grey,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      type['icon'],
                                      color: isSelected ? _themeColor : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      type['label'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected ? _themeColor : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      try {
                        // 删除旧课程
                        if (course.id != null) {
                          await _dbHelper.deleteCourse(course.id!);
                        }
                        // 插入新课程
                        final updatedCourse = Course(
                          name: nameController.text,
                          classroom: classroomController.text.isEmpty
                              ? '待定'
                              : classroomController.text,
                          dayOfWeek: selectedDay,
                          period: selectedPeriod,
                          colorIndex: selectedColor,
                          weekType: selectedWeekType,
                        );
                        await _dbHelper.insertCourse(updatedCourse);
                        await _loadCourses();
                        Navigator.pop(context);
                      } catch (e) {
                        print('编辑课程出错: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('编辑失败: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
