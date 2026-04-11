// lib/domain/entities/book.dart

import 'package:equatable/equatable.dart';
import 'lend.dart';
import 'volume_info.dart';

class Book extends Equatable {
  final String id;
  final String? idProvider;
  final String? typeProvider; // 'GOOGLE', 'GOODREADS', or null for custom
  final String? kind;
  final String? annotation;
  final VolumeInfo volumeInfo;
  final Lend? lend;
  final bool isCustom;
  final String? folderId; // Which folder this book belongs to

  const Book({
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

  /// Check if book is currently lent
  bool get isLent => lend != null;

  /// Copy with method for immutability
  Book copyWith({
    String? id,
    String? idProvider,
    String? typeProvider,
    String? kind,
    String? annotation,
    VolumeInfo? volumeInfo,
    Lend? lend,
    bool? isCustom,
    String? folderId,
  }) {
    return Book(
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

  @override
  List<Object?> get props => [
        id,
        idProvider,
        typeProvider,
        kind,
        annotation,
        volumeInfo,
        lend,
        isCustom,
        folderId,
      ];
}
