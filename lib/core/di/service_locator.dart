// lib/core/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data sources
import '../../data/datasources/firebase_auth_remote_data_source.dart';
import '../../data/datasources/firebase_database_remote_data_source.dart';
import '../../data/datasources/book_remote_data_source.dart';
import '../../data/datasources/folder_remote_data_source.dart';
import '../../data/datasources/lend_remote_data_source.dart';

// Repositories
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../domain/repositories/book_repository.dart';
import '../../data/repositories/folder_repository_impl.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../data/repositories/lend_repository_impl.dart';
import '../../domain/repositories/lend_repository.dart';

// Search
import '../../data/datasources/google_books_api_data_source.dart';
import '../../data/datasources/open_library_api_data_source.dart';
import '../../data/repositories/book_search_repository_impl.dart';
import '../../domain/repositories/book_search_repository.dart';

// BLoCs
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/book_bloc.dart';
import '../../presentation/blocs/book_search_bloc.dart';
import '../../presentation/blocs/folder_bloc.dart';
import '../../presentation/blocs/lend_bloc.dart';

// Services
import '../services/chat_persistence_service.dart';
import '../services/logging_service.dart';
import '../services/subscription_service.dart';
import '../services/remote_config_service.dart';
import '../services/secret_provider.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Firebase instances
  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);

  // Enable offline persistence — must be set before any database operations.
  // This caches data locally so the app works offline and starts faster.
  final firebaseDatabase = FirebaseDatabase.instance;
  firebaseDatabase.setPersistenceEnabled(true);
  firebaseDatabase.setPersistenceCacheSizeBytes(100 * 1024 * 1024); // 100 MB
  getIt.registerSingleton<FirebaseDatabase>(firebaseDatabase);
  getIt.registerSingleton<FirebaseStorage>(
    FirebaseStorage.instanceFor(
      bucket: 'gs://buddybookflutter-ccac6.firebasestorage.app',
    ),
  );

  // Initialize Remote Config service
  final remoteConfig = FirebaseRemoteConfig.instance;
  getIt.registerSingleton<FirebaseRemoteConfig>(remoteConfig);

  final remoteConfigService = RemoteConfigService(remoteConfig: remoteConfig);
  getIt.registerSingleton<RemoteConfigService>(remoteConfigService);
  await remoteConfigService.initialize();

  // Register SecretProvider which uses RemoteConfigService
  getIt.registerSingleton<SecretProvider>(
    SecretProvider(remoteConfigService: remoteConfigService),
  );

  // Initialize Google Sign-In
  // serverClientId (Web client ID) is required on Android for v7+
  final GoogleSignIn signIn = GoogleSignIn.instance;

  // Use SecretProvider to get the server client ID
  final secretProvider = getIt<SecretProvider>();
  await signIn.initialize(
    serverClientId: secretProvider.serverClientId.isNotEmpty ? secretProvider.serverClientId : null,
  );
  getIt.registerSingleton<GoogleSignIn>(signIn);

  // HTTP Client with retry interceptor for rate limiting
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 429) {
          final retryCount = error.requestOptions.extra['retryCount'] ?? 0;
          if (retryCount < 3) {
            await Future.delayed(Duration(seconds: retryCount + 1));
            error.requestOptions.extra['retryCount'] = retryCount + 1;
            try {
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ),
  );

  getIt.registerSingleton<Dio>(dio);

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Register data sources
  _registerDataSources();

  // Register services
  _registerServices();

  // Register repositories
  _registerRepositories();
}

void _registerDataSources() {
  // Auth data sources
  getIt.registerSingleton<FirebaseAuthRemoteDataSource>(
    FirebaseAuthRemoteDataSourceImpl(
      firebaseAuth: getIt<FirebaseAuth>(),
      googleSignIn: getIt<GoogleSignIn>(),
    ),
  );

  getIt.registerSingleton<FirebaseDatabaseRemoteDataSource>(
    FirebaseDatabaseRemoteDataSourceImpl(
      firebaseDatabase: getIt<FirebaseDatabase>(),
    ),
  );

  // Book data sources
  getIt.registerSingleton<BookRemoteDataSource>(
    BookRemoteDataSourceImpl(
      firebaseDatabase: getIt<FirebaseDatabase>(),
      firebaseStorage: getIt<FirebaseStorage>(),
    ),
  );

  // Folder data sources
  getIt.registerSingleton<FolderRemoteDataSource>(
    FolderRemoteDataSourceImpl(
      firebaseDatabase: getIt<FirebaseDatabase>(),
    ),
  );

  // Lend data sources
  getIt.registerSingleton<LendRemoteDataSource>(
    LendRemoteDataSourceImpl(
      firebaseDatabase: getIt<FirebaseDatabase>(),
    ),
  );

  // Book search data sources
  getIt.registerSingleton<GoogleBooksApiDataSource>(
    GoogleBooksApiDataSourceImpl(
      dio: getIt<Dio>(),
      apiKey: getIt<SecretProvider>().googleBooksApiKey,
    ),
  );

  getIt.registerSingleton<OpenLibraryApiDataSource>(
    OpenLibraryApiDataSourceImpl(
      dio: getIt<Dio>(),
    ),
  );
}

void _registerRepositories() {
  // Auth repository
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      authRemoteDataSource: getIt<FirebaseAuthRemoteDataSource>(),
      databaseRemoteDataSource: getIt<FirebaseDatabaseRemoteDataSource>(),
    ),
  );

  // Book repository
  getIt.registerSingleton<BookRepository>(
    BookRepositoryImpl(
      remoteDataSource: getIt<BookRemoteDataSource>(),
      logger: getIt<LoggingService>(),
    ),
  );

  // Folder repository
  getIt.registerSingleton<FolderRepository>(
    FolderRepositoryImpl(
      remoteDataSource: getIt<FolderRemoteDataSource>(),
    ),
  );

  // Lend repository
  getIt.registerSingleton<LendRepository>(
    LendRepositoryImpl(
      remoteDataSource: getIt<LendRemoteDataSource>(),
    ),
  );

  // Book search repository
  getIt.registerSingleton<BookSearchRepository>(
    BookSearchRepositoryImpl(
      googleBooksDataSource: getIt<GoogleBooksApiDataSource>(),
      openLibraryDataSource: getIt<OpenLibraryApiDataSource>(),
    ),
  );
}

void _registerServices() {
  // Logging service
  getIt.registerSingleton<LoggingService>(LoggingService());

  // Chat persistence service
  getIt.registerSingleton<ChatPersistenceService>(
    ChatPersistenceService(getIt<FirebaseDatabase>()),
  );

  // Subscription service (lazy — initialized after login)
  getIt.registerLazySingleton<SubscriptionService>(
    () => SubscriptionService(
      databaseDataSource: getIt<FirebaseDatabaseRemoteDataSource>(),
    ),
  );

  // BLoCs - use registerFactory so each consumer gets a fresh instance
  // (singletons cause stale state across pages and sign-out/sign-in)
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      authRepository: getIt<AuthRepository>(),
      subscriptionService: getIt<SubscriptionService>(),
    ),
  );

  getIt.registerFactory<BookBloc>(
    () => BookBloc(
      repository: getIt<BookRepository>(),
      subscriptionService: getIt<SubscriptionService>(),
    ),
  );

  getIt.registerFactory<FolderBloc>(
    () => FolderBloc(
      repository: getIt<FolderRepository>(),
      subscriptionService: getIt<SubscriptionService>(),
    ),
  );

  getIt.registerFactory<LendBloc>(
    () => LendBloc(repository: getIt<LendRepository>()),
  );

  getIt.registerFactory<BookSearchBloc>(
    () => BookSearchBloc(searchRepository: getIt<BookSearchRepository>()),
  );
}

