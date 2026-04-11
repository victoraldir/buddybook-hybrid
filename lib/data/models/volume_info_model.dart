// lib/data/models/volume_info_model.dart

import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/volume_info.dart';

part 'volume_info_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ImageLinkModel {
  final String? thumbnail;
  @JsonKey(name: 'smallThumbnail')
  final String? smallThumbnail;

  ImageLinkModel({
    this.thumbnail,
    this.smallThumbnail,
  });

  ImageLink toEntity() {
    return ImageLink(
      thumbnail: thumbnail,
      smallThumbnail: smallThumbnail,
    );
  }

  factory ImageLinkModel.fromEntity(ImageLink imageLink) {
    return ImageLinkModel(
      thumbnail: imageLink.thumbnail,
      smallThumbnail: imageLink.smallThumbnail,
    );
  }

  factory ImageLinkModel.fromJson(Map<String, dynamic> json) =>
      _$ImageLinkModelFromJson(json);

  Map<String, dynamic> toJson() => _$ImageLinkModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VolumeInfoModel {
  @JsonKey(defaultValue: '')
  final String title;
  @JsonKey(defaultValue: [])
  final List<String> authors;
  final String? publisher;
  @JsonKey(name: 'publishedDate')
  final String? publishedDate;
  final String? description;
  @JsonKey(name: 'imageLink')
  final ImageLinkModel? imageLink;
  final String? isbn10;
  final String? isbn13;
  @JsonKey(name: 'pageCount')
  final String? pageCount;
  final String? language;
  @JsonKey(name: 'printType')
  final String? printType;
  @JsonKey(name: 'searchField')
  final String? searchField;

  VolumeInfoModel({
    this.title = '',
    this.authors = const [],
    this.publisher,
    this.publishedDate,
    this.description,
    this.imageLink,
    this.isbn10,
    this.isbn13,
    this.pageCount,
    this.language,
    this.printType,
    this.searchField,
  });

  VolumeInfo toEntity() {
    return VolumeInfo(
      title: title,
      authors: authors,
      publisher: publisher,
      publishedDate: publishedDate,
      description: description,
      imageLink: imageLink?.toEntity(),
      isbn10: isbn10,
      isbn13: isbn13,
      pageCount: pageCount,
      language: language,
      printType: printType,
      searchField: searchField,
    );
  }

  factory VolumeInfoModel.fromEntity(VolumeInfo volumeInfo) {
    return VolumeInfoModel(
      title: volumeInfo.title,
      authors: volumeInfo.authors,
      publisher: volumeInfo.publisher,
      publishedDate: volumeInfo.publishedDate,
      description: volumeInfo.description,
      imageLink: volumeInfo.imageLink != null
          ? ImageLinkModel.fromEntity(volumeInfo.imageLink!)
          : null,
      isbn10: volumeInfo.isbn10,
      isbn13: volumeInfo.isbn13,
      pageCount: volumeInfo.pageCount,
      language: volumeInfo.language,
      printType: volumeInfo.printType,
      searchField: volumeInfo.searchField,
    );
  }

  factory VolumeInfoModel.fromJson(Map<String, dynamic> json) =>
      _$VolumeInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$VolumeInfoModelToJson(this);
}
