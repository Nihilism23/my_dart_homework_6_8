import 'package:csv/csv.dart';
import 'course.dart';

class CsvImporter {
  /// 从CSV文本解析课程
  static List<Course> parseFromText(String csvText) {
    print('=== CSV解析调试 ===');
    print('输入文本: $csvText');
    print('文本长度: ${csvText.length}');
    
    // 统一换行符为 \n，然后手动分行解析
    final normalizedText = csvText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalizedText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    print('分行后的行数: ${lines.length}');
    for (int i = 0; i < lines.length; i++) {
      print('行 $i: ${lines[i]}');
    }
    
    // 逐行解析CSV
    final rows = <List<dynamic>>[];
    for (final line in lines) {
      final row = const CsvToListConverter().convert(line).first;
      rows.add(row);
    }
    
    print('解析后的行数: ${rows.length}');
    for (int i = 0; i < rows.length; i++) {
      print('行 $i: ${rows[i]}');
    }
    
    return _parseRows(rows);
  }

  /// 解析行数据
  static List<Course> _parseRows(List<List<dynamic>> rows) {
    List<Course> courses = [];

    if (rows.isEmpty) {
      print('行列表为空');
      return courses;
    }

    print('总行数: ${rows.length}');

    // 跳过第一行（表头），从第二行开始解析
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      print('处理行 $i: $row');
      
      if (row.isEmpty) {
        print('行 $i 为空，跳过');
        continue;
      }
      
      // 确保至少有5列
      if (row.length < 5) {
        print('行 $i 列数不足: ${row.length}，跳过');
        continue;
      }
      
      final name = row[0].toString().trim();
      final classroom = row[1].toString().trim();
      final dayStr = row[2].toString().trim();
      final periodStr = row[3].toString().trim();
      final colorStr = row[4].toString().trim();
      
      print('解析: 名称=$name, 教室=$classroom, 星期=$dayStr, 节次=$periodStr, 颜色=$colorStr');
      
      if (name.isEmpty) {
        print('行 $i 名称为空，跳过');
        continue;
      }

      // 解析星期
      int dayOfWeek = _parseDayOfWeek(dayStr);
      
      // 解析节次
      int period = int.tryParse(periodStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      
      // 解析颜色
      int colorIndex = int.tryParse(colorStr) ?? 0;

      // 解析周次类型（第6列，可选）
      int weekType = 0;
      if (row.length >= 6) {
        final weekTypeStr = row[5].toString().trim().toLowerCase();
        if (weekTypeStr.contains('单') || weekTypeStr == '1') {
          weekType = 1;
        } else if (weekTypeStr.contains('双') || weekTypeStr == '2') {
          weekType = 2;
        }
      }

      print('解析结果: 名称=$name, 星期=$dayOfWeek, 节次=$period, 周次类型=$weekType');

      courses.add(Course(
        name: name,
        classroom: classroom.isEmpty ? '待定' : classroom,
        dayOfWeek: dayOfWeek,
        period: period,
        colorIndex: colorIndex,
        weekType: weekType,
      ));
    }

    print('总共解析到 ${courses.length} 门课程');
    return courses;
  }

  /// 解析星期
  static int _parseDayOfWeek(String str) {
    str = str.toLowerCase();

    if (str.contains('一') || str.contains('1')) return 1;
    if (str.contains('二') || str.contains('2')) return 2;
    if (str.contains('三') || str.contains('3')) return 3;
    if (str.contains('四') || str.contains('4')) return 4;
    if (str.contains('五') || str.contains('5')) return 5;
    if (str.contains('六') || str.contains('6')) return 6;
    if (str.contains('日') || str.contains('天') || str.contains('7')) return 7;

    final num = int.tryParse(str.replaceAll(RegExp(r'[^0-9]'), ''));
    if (num != null && num >= 1 && num <= 7) return num;

    return 1;
  }

  /// 获取模板内容
  static String getTemplate() {
    return '课程名称,教室,星期,节次,颜色,周次类型\n数学,教室A,1,1,0,每周\n英语,教室B,2,2,1,单周\n物理,实验室,3,3,2,双周';
  }
}
