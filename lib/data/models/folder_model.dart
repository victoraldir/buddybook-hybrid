// lib/data/models/folder_model.dart

import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/book.dart';
import 'book_model.dart';

part 'folder_model.g.dart';

@JsonSerializable(explicitToJson: true)
class FolderModel {
  final String id;
  final String description;
  @JsonKey(name: 'custom', defaultValue: false)
  final bool isCustom;
  final Map<String, BookModel>? books;

  FolderModel({
    required this.id,
    required this.description,
    required this.isCustom,
    this.books,
  });

  /// Convert to domain entity
  Folder toEntity() {
    final bookEntities = <String, Book>{};
    if (books != null) {
      books!.forEach((key, value) {
        bookEntities[key] = value.toEntity();
      });
    }

    return Folder(
      id: id,
      description: description,
      isCustom: isCustom,
      books: bookEntities,
    );
  }

  /// Create from domain entity
  factory FolderModel.fromEntity(Folder folder) {
    final bookModels = <String, BookModel>{};
    folder.books.forEach((key, value) {
      bookModels[key] = BookModel.fromEntity(value);
    });

    return FolderModel(
      id: folder.id,
      description: folder.description,
      isCustom: folder.isCustom,
      books: bookModels,
    );
  }

  factory FolderModel.fromJson(Map<String, dynamic> json) =>
      _$FolderModelFromJson(json);

  Map<String, dynamic> toJson() => _$FolderModelToJson(this);

  FolderModel copyWith({
    String? id,
    String? description,
    bool? isCustom,
    Map<String, BookModel>? books,
  }) {
    return FolderModel(
      id: id ?? this.id,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      books: books ?? this.books,
    );
  }
}
