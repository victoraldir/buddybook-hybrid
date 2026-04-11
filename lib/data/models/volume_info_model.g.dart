// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageLinkModel _$ImageLinkModelFromJson(Map<String, dynamic> json) =>
    ImageLinkModel(
      thumbnail: json['thumbnail'] as String?,
      smallThumbnail: json['smallThumbnail'] as String?,
    );

Map<String, dynamic> _$ImageLinkModelToJson(ImageLinkModel instance) =>
    <String, dynamic>{
      'thumbnail': instance.thumbnail,
      'smallThumbnail': instance.smallThumbnail,
    };

VolumeInfoModel _$VolumeInfoModelFromJson(Map<String, dynamic> json) =>
    VolumeInfoModel(
      title: json['title'] as String? ?? '',
      authors: (json['authors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      publisher: json['publisher'] as String?,
      publishedDate: json['publishedDate'] as String?,
      description: json['description'] as String?,
      imageLink: json['imageLink'] == null
          ? null
          : ImageLinkModel.fromJson(json['imageLink'] as Map<String, dynamic>),
      isbn10: json['isbn10'] as String?,
      isbn13: json['isbn13'] as String?,
      pageCount: json['pageCount'] as String?,
      language: json['language'] as String?,
      printType: json['printType'] as String?,
      searchField: json['searchField'] as String?,
    );

Map<String, dynamic> _$VolumeInfoModelToJson(VolumeInfoModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'authors': instance.authors,
      'publisher': instance.publisher,
      'publishedDate': instance.publishedDate,
      'description': instance.description,
      'imageLink': instance.imageLink?.toJson(),
      'isbn10': instance.isbn10,
      'isbn13': instance.isbn13,
      'pageCount': instance.pageCount,
      'language': instance.language,
      'printType': instance.printType,
      'searchField': instance.searchField,
    };
