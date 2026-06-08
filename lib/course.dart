class Course {
  final int? id;
  final String name;
  final String classroom;
  final int dayOfWeek;
  final int period;
  final int colorIndex;
  final int weekType; // 0=每周, 1=单周, 2=双周

  Course({
    this.id,
    required this.name,
    required this.classroom,
    required this.dayOfWeek,
    required this.period,
    this.colorIndex = 0,
    this.weekType = 0, // 默认每周
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'classroom': classroom,
      'dayOfWeek': dayOfWeek,
      'period': period,
      'colorIndex': colorIndex,
      'weekType': weekType,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as int?,
      name: map['name'] as String,
      classroom: map['classroom'] as String,
      dayOfWeek: map['dayOfWeek'] as int,
      period: map['period'] as int,
      colorIndex: map['colorIndex'] as int? ?? 0,
      weekType: map['weekType'] as int? ?? 0,
    );
  }

  // 检查课程是否在当前周显�?
  bool shouldShow(int currentWeek) {
    if (weekType == 0) return true; // 每周都显�?
    if (weekType == 1) return currentWeek % 2 == 1; // 单周显示
    if (weekType == 2) return currentWeek % 2 == 0; // 双周显示
    return true;
  }

  // 获取周次类型文字
  String get weekTypeText {
    switch (weekType) {
      case 1:
        return '单周';
      case 2:
        return '双周';
      default:
        return '每周';
    }
  }

  @override
  String toString() {
    return '$name\n$classroom';
  }
}
