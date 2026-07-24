import 'package:flutter_test/flutter_test.dart';
import 'package:ezitech_learning_platform/core/offline/outbox_item.dart';

void main() {
  group('OutboxItem backoff', () {
    test('defaults nextRetryAt to createdAt when not specified', () {
      final now = DateTime.now();
      final item = OutboxItem(
        id: '1',
        payloadType: 'test',
        payloadJson: const {},
        createdAt: now,
      );
      expect(item.nextRetryAt, now);
    });

    test('accepts an explicit nextRetryAt for scheduled retries', () {
      final createdAt = DateTime.now();
      final retryAt = createdAt.add(const Duration(minutes: 5));
      final item = OutboxItem(
        id: '1',
        payloadType: 'test',
        payloadJson: const {},
        createdAt: createdAt,
        nextRetryAt: retryAt,
      );
      expect(item.nextRetryAt, retryAt);
    });
  });
}
