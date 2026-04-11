// lib/core/constants/firebase_constants.dart

class FirebaseConstants {
  // Database references
  static const String usersPath = 'users';
  static const String usersCollection = 'users';
  static const String foldersPath = 'folders';
  static const String booksPath = 'books';
  static const String defaultFolderId = 'myBooksFolder';
  static const String defaultFolderName = 'My books';

  // User fields
  static const String userIdField = 'uid';
  static const String uidField = 'uid';
  static const String emailField = 'email';
  static const String usernameField = 'username';
  static const String photoUrlField = 'photoUrl';
  static const String lastActivityField = 'lastActivity';
  static const String tierField = 'tier';
  static const String foldersField = 'folders';

  // Folder fields
  static const String idField = 'id';
  static const String folderIdField = 'id';
  static const String descriptionField = 'description';
  static const String isCustomField = 'custom';
  static const String folderBooksField = 'books';

  // Book fields
  static const String bookIdField = 'id';
  static const String idProviderField = 'idProvider';
  static const String typeProviderField = 'typeProvider';
  static const String kindField = 'kind';
  static const String annotationField = 'annotation';
  static const String volumeInfoField = 'volumeInfo';
  static const String lendField = 'lend';
  static const String isCustomBookField = 'custom';

  // VolumeInfo fields
  static const String titleField = 'title';
  static const String authorsField = 'authors';
  static const String publisherField = 'publisher';
  static const String publishedDateField = 'publishedDate';
  static const String descriptionField2 = 'description';
  static const String imageLinkField = 'imageLink';
  static const String isbn10Field = 'isbn10';
  static const String isbn13Field = 'isbn13';
  static const String pageCountField = 'pageCount';
  static const String languageField = 'language';
  static const String printTypeField = 'printType';
  static const String searchFieldField = 'searchField';

  // ImageLink fields
  static const String thumbnailField = 'thumbnail';
  static const String smallThumbnailField = 'smallThumbnail';

  // Lend fields
  static const String receiverNameField = 'receiverName';
  static const String receiverEmailField = 'receiverEmail';
  static const String lendDateField = 'lendDate';

  // Storage paths
  static const String userAvatarsPath = 'users/{uid}/avatars';
  static const String bookCoversPath = 'books/{bookId}/cover';

  // Remote Config keys
  static const String maxBooksKey = 'MAX_BOOKS_FREE';
  static const String maxFoldersKey = 'MAX_FOLDERS_FREE';
  static const String maxBooksPaidKey = 'MAX_BOOKS_PAID';
  static const String maxFoldersPaidKey = 'MAX_FOLDERS_PAID';
  static const String featureBarcodeScannerKey = 'FEATURE_BARCODE_SCANNER';
  static const String featureExportKey = 'FEATURE_EXPORT';
  static const String featureLendingKey = 'FEATURE_LENDING';

  // Default values
  static const int defaultMaxBooks = 25;
  static const int defaultMaxFolders = 5;
  static const int defaultMaxBooksPaid = 999999;
  static const int defaultMaxFoldersPaid = 999999;
  static const int defaultMaxChatMessagesPerSessionFree = 5;
  static const int defaultMaxChatSessionsFree = 3;
  static const bool defaultFeatureBarcode = true;
  static const bool defaultFeatureExport = true;
  static const bool defaultFeatureLending = true;

  // Tier types
  static const String freeTier = 'free';
  static const String paidTier = 'paid';

  // In-App Purchase
  static const String monthlySubscriptionId = 'buddybook_premium_monthly';

  // Chat fields
  static const String chatSessionsField = 'chatSessions';
  static const String chatMessagesField = 'messages';
  static const String chatRoleField = 'role';
  static const String chatContentField = 'content';
  static const String chatTimestampField = 'timestamp';
  static const String chatTitleField = 'title';
  static const String chatCreatedAtField = 'createdAt';

  // AI Chat - Gemini API key loaded from environment
  // Set via: flutter build --dart-define=GEMINI_API_KEY=your_key
}
