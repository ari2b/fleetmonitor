import 'package:flutter/material.dart';

class StatusTheme {
  final Color color;
  final Color bgColor;
  final String label;

  StatusTheme(this.color, this.bgColor, this.label);
}

final Map<String, StatusTheme> statusThemes = {
  'idle': StatusTheme(Colors.blueGrey[600]!, Colors.blueGrey[100]!, 'Istirahat'),
  'loading': StatusTheme(Colors.purple[600]!, Colors.purple[100]!, 'Loading'),
  'berangkat': StatusTheme(Colors.blue[600]!, Colors.blue[100]!, 'Berangkat'),
  'perjalanan': StatusTheme(Colors.teal[600]!, Colors.teal[100]!, 'Dalam Perjalanan'),
  'sampai': StatusTheme(Colors.orange[600]!, Colors.orange[100]!, 'Sampai Tujuan'),
};