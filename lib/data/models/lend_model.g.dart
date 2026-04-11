// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lend_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LendModel _$LendModelFromJson(Map<String, dynamic> json) => LendModel(
      receiverName: json['receiverName'] as String,
      receiverEmail: json['receiverEmail'] as String? ?? '',
      lendDate: _lendDateFromJson(json['lendDate']),
    );

Map<String, dynamic> _$LendModelToJson(LendModel instance) => <String, dynamic>{
      'receiverName': instance.receiverName,
      'receiverEmail': instance.receiverEmail,
      'lendDate': _lendDateToJson(instance.lendDate),
    };
