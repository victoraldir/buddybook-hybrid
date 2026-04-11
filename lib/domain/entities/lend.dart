// lib/domain/entities/lend.dart

import 'package:equatable/equatable.dart';

class Lend extends Equatable {
  final String receiverName;
  final String receiverEmail;
  final DateTime lendDate;

  const Lend({
    required this.receiverName,
    required this.receiverEmail,
    required this.lendDate,
  });

  @override
  List<Object> get props => [receiverName, receiverEmail, lendDate];
}
