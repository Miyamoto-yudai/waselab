import 'package:flutter_test/flutter_test.dart';

/// Googleカレンダー連携のテストコード
/// 実機でテストする前にこのテストを実行して確認
void main() {
  group('Google Calendar URL Tests', () {
    test('Google Calendar URL format is correct', () {
      final title = '【わせラボ】テスト実験';
      final details = 'これはテストです';
      final location = '早稲田大学';
      final startTime = DateTime(2024, 1, 15, 14, 0); // 2024年1月15日 14:00
      final endTime = DateTime(2024, 1, 15, 15, 0);   // 2024年1月15日 15:00
      
      // UTC時間に変換
      final startUtc = startTime.toUtc();
      final endUtc = endTime.toUtc();
      
      // フォーマット
      final dates = '${startUtc.year}'
          '${startUtc.month.toString().padLeft(2, '0')}'
          '${startUtc.day.toString().padLeft(2, '0')}'
          'T'
          '${startUtc.hour.toString().padLeft(2, '0')}'
          '${startUtc.minute.toString().padLeft(2, '0')}'
          '${startUtc.second.toString().padLeft(2, '0')}'
          'Z/'
          '${endUtc.year}'
          '${endUtc.month.toString().padLeft(2, '0')}'
          '${endUtc.day.toString().padLeft(2, '0')}'
          'T'
          '${endUtc.hour.toString().padLeft(2, '0')}'
          '${endUtc.minute.toString().padLeft(2, '0')}'
          '${endUtc.second.toString().padLeft(2, '0')}'
          'Z';
      
      final expectedUrl = 'https://calendar.google.com/calendar/render'
          '?action=TEMPLATE'
          '&text=${Uri.encodeComponent(title)}'
          '&details=${Uri.encodeComponent(details)}'
          '&dates=$dates'
          '&location=${Uri.encodeComponent(location)}';
      
      print('Generated URL: $expectedUrl');
      
      // URLが正しい形式であることを確認
      expect(expectedUrl.contains('https://calendar.google.com'), true);
      expect(expectedUrl.contains('action=TEMPLATE'), true);
      expect(expectedUrl.contains('text='), true);
      expect(expectedUrl.contains('details='), true);
      expect(expectedUrl.contains('dates='), true);
      expect(expectedUrl.contains('location='), true);
      
      // URLが解析可能であることを確認
      final uri = Uri.parse(expectedUrl);
      expect(uri.scheme, 'https');
      expect(uri.host, 'calendar.google.com');
      expect(uri.path, '/calendar/render');
    });
    
    test('URL encoding is correct', () {
      final title = 'テスト & 実験';
      final encoded = Uri.encodeComponent(title);
      expect(encoded, contains('%'));
      expect(encoded, isNot(contains('&'))); // &は%26にエンコードされる
      expect(encoded, isNot(contains(' '))); // スペースは%20にエンコードされる
    });
    
    test('DateTime formatting for Google Calendar', () {
      final dateTime = DateTime(2024, 1, 1, 9, 30, 0); // 日本時間 9:30
      final utc = dateTime.toUtc();
      
      final formatted = '${utc.year}'
          '${utc.month.toString().padLeft(2, '0')}'
          '${utc.day.toString().padLeft(2, '0')}'
          'T'
          '${utc.hour.toString().padLeft(2, '0')}'
          '${utc.minute.toString().padLeft(2, '0')}'
          '${utc.second.toString().padLeft(2, '0')}'
          'Z';
      
      // 長さが正しいことを確認（YYYYMMDDTHHMMSSZ = 16文字）
      expect(formatted.length, 16);
      expect(formatted.endsWith('Z'), true);
      expect(formatted.contains('T'), true);
    });
  });
}