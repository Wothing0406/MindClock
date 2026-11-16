import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/domain/services/answer_normalizer.dart';

void main() {
  group('AnswerNormalizer Dart Client Test (T040)', () {
    test('Số thập phân: 0,5 == 0.5, 3,14 == 3.14', () {
      expect(isAnswerAccepted('0,5', <String>['0.5']), isTrue);
      expect(isAnswerAccepted('3,14', <String>['3.14']), isTrue);
      expect(isAnswerAccepted('2.50', <String>['2.5']), isTrue);
      expect(isAnswerAccepted('0.5', <String>['0,5']), isTrue);
    });

    test('Phân số: 3/4 == 0.75, \\frac{1}{2} == 0,5', () {
      expect(isAnswerAccepted('3/4', <String>['0.75']), isTrue);
      expect(isAnswerAccepted('0.75', <String>['3/4']), isTrue);
      expect(isAnswerAccepted(r'\frac{1}{2}', <String>['0.5']), isTrue);
      expect(isAnswerAccepted('1/2', <String>['0,5']), isTrue);
    });

    test('Biến số và phương trình: x = 8, x=8', () {
      expect(isAnswerAccepted('x = 8', <String>['8']), isTrue);
      expect(isAnswerAccepted('8', <String>['x = 8']), isTrue);
      expect(isAnswerAccepted('x=8', <String>['8']), isTrue);
      expect(isAnswerAccepted("y'(2) = 9", <String>['9']), isTrue);
    });

    test('Đơn vị đo lường: 2A, 2 A, 10 m/s', () {
      expect(isAnswerAccepted('2A', <String>['2A']), isTrue);
      expect(isAnswerAccepted('2 A', <String>['2A']), isTrue);
      expect(isAnswerAccepted('2 a', <String>['2A']), isTrue);
      expect(isAnswerAccepted('I = 2A', <String>['2A']), isTrue);
      expect(isAnswerAccepted('2', <String>['2A']), isTrue);
      expect(isAnswerAccepted('10 m/s', <String>['10m/s']), isTrue);

      // Sai đơn vị
      expect(isAnswerAccepted('2V', <String>['2A']), isFalse);
      expect(isAnswerAccepted('10 km/h', <String>['10 m/s']), isFalse);
    });

    test('Văn bản trắc nghiệm chữ / ngoại ngữ', () {
      expect(isAnswerAccepted('ẩn dụ', <String>['ẩn dụ', 'an du']), isTrue);
      expect(isAnswerAccepted('has lived', <String>['has lived']), isTrue);
      expect(isAnswerAccepted('Aa', <String>['100% Aa', 'Aa']), isTrue);
      expect(isAnswerAccepted('sai hoan toan', <String>['ẩn dụ']), isFalse);
    });
  });
}
