import 'course.dart';

class SimpleStorage {
  static final SimpleStorage instance = SimpleStorage._init();
  List<Course> _courses = [];

  SimpleStorage._init();

  Future<List<Course>> getAllCourses() async {
    return _courses;
  }

  Future<int> insertCourse(Course course) async {
    final newId = _courses.length + 1;
    final newCourse = Course(
      id: newId,
      name: course.name,
      classroom: course.classroom,
      dayOfWeek: course.dayOfWeek,
      period: course.period,
      colorIndex: course.colorIndex,
      weekType: course.weekType,
    );
    _courses.add(newCourse);
    return newId;
  }

  Future<int> deleteCourse(int id) async {
    _courses.removeWhere((c) => c.id == id);
    return 1;
  }

  Future<int> updateCourse(Course course) async {
    final index = _courses.indexWhere((c) => c.id == course.id);
    if (index != -1) {
      _courses[index] = course;
      return 1;
    }
    return 0;
  }
}
