import 'package:intl/intl.dart';

final DateFormat _stamp = DateFormat('yyyy.MM.dd HH:mm');

String formatTimestamp(DateTime value) => _stamp.format(value.toLocal());
