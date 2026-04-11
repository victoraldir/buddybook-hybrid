// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FolderModel _$FolderModelFromJson(Map<String, dynamic> json) => FolderModel(
      id: json['id'] as String,
      description: json['description'] as String,
      isCustom: json['custom'] as bool? ?? false,
      books: (json['books'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, BookModel.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$FolderModelToJson(FolderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'custom': instance.isCustom,
      'books': instance.books?.map((k, e) => MapEntry(k, e.toJson())),
    };
