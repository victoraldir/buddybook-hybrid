// lib/domain/entities/volume_info.dart

import 'package:equatable/equatable.dart';

class ImageLink extends Equatable {
  final String? thumbnail;
  final String? smallThumbnail;

  const ImageLink({
    this.thumbnail,
    this.smallThumbnail,
  });

  @override
  List<Object?> get props => [thumbnail, smallThumbnail];
}

class VolumeInfo extends Equatable {
  final String title;
  final List<String> authors;
  final String? publisher;
  final String? publishedDate;
  final String? description;
  final ImageLink? imageLink;
  final String? isbn10;
  final String? isbn13;
  final String? pageCount;
  final String? language;
  final String? printType;
  final String? searchField; // Indexed field for search

  const VolumeInfo({
    required this.title,
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

  /// Get primary cover image URL
  String? get coverImageUrl {
    return imageLink?.thumbnail ?? imageLink?.smallThumbnail;
  }

  /// Get authors as comma-separated string
  String get authorsString => authors.join(', ');

  @override
  List<Object?> get props => [
        title,
        authors,
        publisher,
        publishedDate,
        description,
        imageLink,
        isbn10,
        isbn13,
        pageCount,
        language,
        printType,
        searchField,
      ];
}
