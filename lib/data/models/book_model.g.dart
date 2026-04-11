// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookModel _$BookModelFromJson(Map<String, dynamic> json) => BookModel(
      id: json['id'] as String,
      idProvider: json['idProvider'] as String?,
      typeProvider: json['typeProvider'] as String?,
      kind: json['kind'] as String?,
      annotation: json['annotation'] as String?,
      volumeInfo:
          VolumeInfoModel.fromJson(json['volumeInfo'] as Map<String, dynamic>),
      lend: json['lend'] == null
          ? null
          : LendModel.fromJson(json['lend'] as Map<String, dynamic>),
      isCustom: json['custom'] as bool? ?? false,
      folderId: json['folderId'] as String?,
    );

Map<String, dynamic> _$BookModelToJson(BookModel instance) => <String, dynamic>{
      'id': instance.id,
      'idProvider': instance.idProvider,
      'typeProvider': instance.typeProvider,
      'kind': instance.kind,
      'annotation': instance.annotation,
      'volumeInfo': instance.volumeInfo.toJson(),
      'lend': instance.lend?.toJson(),
      'custom': instance.isCustom,
      'folderId': instance.folderId,
    };
