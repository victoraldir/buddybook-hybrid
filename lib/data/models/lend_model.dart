// lib/data/models/lend_model.dart

import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/lend.dart';

part 'lend_model.g.dart';

/// Custom converter for lendDate that handles both:
/// - Java Date object: { time: 1234567890, year: 118, month: 5, ... }
/// - Plain int (milliseconds timestamp)
int _lendDateFromJson(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is Map) {
    // Java Date object serialization - extract the 'time' field
    final time = value['time'];
    if (time is int) return time;
    if (time is num) return time.toInt();
  }
  return 0;
}

/// Write lendDate as a Java Date-compatible object for compatibility
dynamic _lendDateToJson(int value) {
  final dt = DateTime.fromMillisecondsSinceEpoch(value);
  return {
    'time': value,
    'year': dt.year - 1900,
    'month': dt.month - 1,
    'date': dt.day,
    'day': dt.weekday % 7,
    'hours': dt.hour,
    'minutes': dt.minute,
    'seconds': dt.second,
    'timezoneOffset': dt.timeZoneOffset.inMinutes,
  };
}

@JsonSerializable(explicitToJson: true)
class LendModel {
  @JsonKey(name: 'receiverName')
  final String receiverName;
  @JsonKey(name: 'receiverEmail', defaultValue: '')
  final String receiverEmail;
  @JsonKey(
    name: 'lendDate',
    fromJson: _lendDateFromJson,
    toJson: _lendDateToJson,
  )
  final int lendDate; // Stored internally as milliseconds timestamp

  LendModel({
    required this.receiverName,
    this.receiverEmail = '',
    required this.lendDate,
  });

  /// Convert to domain entity
  Lend toEntity() {
    return Lend(
      receiverName: receiverName,
      receiverEmail: receiverEmail,
      lendDate: DateTime.fromMillisecondsSinceEpoch(lendDate),
    );
  }

  /// Create from domain entity
  factory LendModel.fromEntity(Lend lend) {
    return LendModel(
      receiverName: lend.receiverName,
      receiverEmail: lend.receiverEmail,
      lendDate: lend.lendDate.millisecondsSinceEpoch,
    );
  }

  factory LendModel.fromJson(Map<String, dynamic> json) =>
      _$LendModelFromJson(json);

  Map<String, dynamic> toJson() => _$LendModelToJson(this);

  LendModel copyWith({
    String? receiverName,
    String? receiverEmail,
    int? lendDate,
  }) {
    return LendModel(
      receiverName: receiverName ?? this.receiverName,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      lendDate: lendDate ?? this.lendDate,
    );
  }
}
