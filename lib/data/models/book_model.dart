// lib/data/models/book_model.dart

import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/book.dart';
import 'volume_info_model.dart';
import 'lend_model.dart';

part 'book_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BookModel {
  final String id;
  @JsonKey(name: 'idProvider')
  final String? idProvider;
  @JsonKey(name: 'typeProvider')
  final String? typeProvider;
  final String? kind;
  final String? annotation;
  @JsonKey(name: 'volumeInfo')
  final VolumeInfoModel volumeInfo;
  final LendModel? lend;
  @JsonKey(name: 'custom')
  final bool isCustom;
  final String? folderId;

  BookModel({
    required this.id,
    this.idProvider,
    this.typeProvider,
    this.kind,
    this.annotation,
    required this.volumeInfo,
    this.lend,
    this.isCustom = false,
    this.folderId,
  });

  /// Convert to domain entity
  Book toEntity() {
    return Book(
      id: id,
      idProvider: idProvider,
      typeProvider: typeProvider,
      kind: kind,
      annotation: annotation,
      volumeInfo: volumeInfo.toEntity(),
      lend: lend?.toEntity(),
      isCustom: isCustom,
      folderId: folderId,
    );
  }

  /// Create from domain entity
  factory BookModel.fromEntity(Book book) {
    return BookModel(
      id: book.id,
      idProvider: book.idProvider,
      typeProvider: book.typeProvider,
      kind: book.kind,
      annotation: book.annotation,
      volumeInfo: VolumeInfoModel.fromEntity(book.volumeInfo),
      lend: book.lend != null ? LendModel.fromEntity(book.lend!) : null,
      isCustom: book.isCustom,
      folderId: book.folderId,
    );
  }

  factory BookModel.fromJson(Map<String, dynamic> json) =>
      _$BookModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookModelToJson(this);

  BookModel copyWith({
    String? id,
    String? idProvider,
    String? typeProvider,
    String? kind,
    String? annotation,
    VolumeInfoModel? volumeInfo,
    LendModel? lend,
    bool? isCustom,
    String? folderId,
  }) {
    return BookModel(
      id: id ?? this.id,
      idProvider: idProvider ?? this.idProvider,
      typeProvider: typeProvider ?? this.typeProvider,
      kind: kind ?? this.kind,
      annotation: annotation ?? this.annotation,
      volumeInfo: volumeInfo ?? this.volumeInfo,
      lend: lend ?? this.lend,
      isCustom: isCustom ?? this.isCustom,
      folderId: folderId ?? this.folderId,
    );
  }
}
