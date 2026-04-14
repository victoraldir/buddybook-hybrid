// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BuddyBook';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInSubtitle => 'Sign in to your BuddyBook account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInButton => 'Sign In';

  @override
  String get signUpLink => 'Don\'t have an account? Sign Up';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get homeTitle => 'My Library';

  @override
  String get searchPlaceholder => 'Search by title, author, or ISBN...';

  @override
  String get noBooksFound => 'No books found in your library.';

  @override
  String get addBookTooltip => 'Add a new book';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get logoutButton => 'Log Out';
}
