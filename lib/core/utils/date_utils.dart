import 'package:intl/intl.dart';

class DateUtilsX {
  static final _time = DateFormat('HH:mm');
  static final _dateTime = DateFormat('yyyy-MM-dd HH:mm');

  static String formatTime(DateTime dt) => _time.format(dt);
  static String formatDateTime(DateTime dt) => _dateTime.format(dt);
}
