import '../cache/local_cache.dart';

class PendingSessionRegistration {
  const PendingSessionRegistration({
    required this.appointmentId,
    required this.idempotencyKey,
    required this.createdAt,
  });

  factory PendingSessionRegistration.fromJson(Map<String, dynamic> json) {
    return PendingSessionRegistration(
      appointmentId: json['appointment_id'] as int,
      idempotencyKey: json['idempotency_key'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int appointmentId;
  final String idempotencyKey;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'appointment_id': appointmentId,
    'idempotency_key': idempotencyKey,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

class SessionOutbox {
  const SessionOutbox(this.cache);

  static const cacheKey = 'outbox:session-registrations';
  final LocalCache cache;

  Future<List<PendingSessionRegistration>> readAll() async {
    final data = await cache.read(cacheKey);
    return (data?['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PendingSessionRegistration.fromJson)
        .toList(growable: false);
  }

  Future<void> enqueue(PendingSessionRegistration pending) async {
    final items = await readAll();
    if (items.any((item) => item.idempotencyKey == pending.idempotencyKey)) {
      return;
    }
    await _write([...items, pending]);
  }

  Future<void> remove(String idempotencyKey) async {
    final items = await readAll();
    await _write(
      items
          .where((item) => item.idempotencyKey != idempotencyKey)
          .toList(growable: false),
    );
  }

  Future<void> _write(List<PendingSessionRegistration> items) {
    return cache.write(cacheKey, {
      'items': items.map((item) => item.toJson()).toList(growable: false),
    });
  }
}
