import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migration contains v4 and v5 schema steps', () {
    final file = File('lib/data/local_database.dart');
    final source = file.readAsStringSync();

    expect(source.contains('ALTER TABLE events ADD COLUMN duration_minutes INTEGER'), isTrue);
    expect(source.contains('CREATE TABLE IF NOT EXISTS focus_sessions'), isTrue);
    expect(source.contains('CREATE TABLE IF NOT EXISTS daily_stats'), isTrue);
  });
}
