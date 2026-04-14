import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:buddybook_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:buddybook_flutter/presentation/blocs/auth/auth_state.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/chat_persistence_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../domain/entities/book.dart';
import '../../../presentation/widgets/subscription/upgrade_dialog.dart';

class ChatPage extends StatefulWidget {
  final Book book;
  final String folderId;

  const ChatPage({super.key, required this.book, required this.folderId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final FirebaseProvider _provider;
  bool _isLoading = true;
  bool _isBlocked = false;
  bool _messageLimitReached = false;

  final _subscriptionService = getIt<SubscriptionService>();
  final _persistenceService = getIt<ChatPersistenceService>();

  String get _bookId => widget.book.id;
  String get _userId {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.uid;
    return '';
  }

  String get _sessionCountKey => 'chat_session_count';
  String get _messageCountKey => 'chat_message_count_$_bookId';

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure context is available for reading AuthBloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  Future<void> _initializeProvider() async {
    if (!_subscriptionService.isPremium) {
      final canStart = await _checkSessionLimit();
      if (!canStart) {
        if (mounted) setState(() => _isBlocked = true);
        return;
      }
    }

    final history = await _persistenceService.loadHistory(_userId, _bookId);
    _provider = FirebaseProvider(
      model: FirebaseAI.vertexAI().generativeModel(
        model: 'gemini-2.5-flash-lite',
        systemInstruction: Content.system(_buildSystemPrompt()),
      ),
      history: history,
    );
    _provider.addListener(_onHistoryChanged);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<bool> _checkSessionLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionCount = prefs.getInt(_sessionCountKey) ?? 0;
    final maxSessions = _subscriptionService.maxChatSessions;

    if (sessionCount >= maxSessions) {
      return false;
    }

    await prefs.setInt(_sessionCountKey, sessionCount + 1);
    return true;
  }

  void _onHistoryChanged() {
    _persistenceService.saveHistory(_userId, _bookId, _provider.history);
    _trackMessageUsage();
  }

  Future<void> _trackMessageUsage() async {
    if (_subscriptionService.isPremium) return;

    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_messageCountKey) ?? 0;
    final newCount = count + 1;
    await prefs.setInt(_messageCountKey, newCount);

    if (newCount >= _subscriptionService.maxChatMessagesPerSession &&
        !_messageLimitReached) {
      _messageLimitReached = true;
      if (mounted) {
        final result = await showUpgradeDialog(
          context,
          currentCount: newCount,
          maxBooks: _subscriptionService.maxChatMessagesPerSession,
        );
        if (result != true && mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onHistoryChanged);
    super.dispose();
  }

  String _buildSystemPrompt() {
    final title = widget.book.volumeInfo.title;
    final authors = widget.book.volumeInfo.authors.join(', ');
    final description =
        widget.book.volumeInfo.description ?? 'No description available';
    final publisher = widget.book.volumeInfo.publisher ?? 'Unknown Publisher';
    final publishedDate = widget.book.volumeInfo.publishedDate ?? 'Unknown';
    final pageCount = widget.book.volumeInfo.pageCount?.toString() ?? 'Unknown';

    return '''
You are a literary discussion partner, not a generic AI assistant. You help users discuss and understand books in a natural, conversational way.

The user is currently discussing the book:

**Title:** $title
**Author:** $authors
**Publisher:** $publisher
**Published Date:** $publishedDate
**Page Count:** $pageCount

**Description:**
$description

**CRITICAL INSTRUCTIONS - Read carefully:**

1. **DO NOT use generic phrases** like "That's a great question!" or "I'm happy to help!" or "What an interesting topic!" These sound artificial and should be avoided entirely.

2. **Be direct and natural** - Respond conversationally as if you're discussing books with a friend. Start your response directly with the answer or relevant insight.

3. **Don't over-praise** - Avoid excessive compliments about the user's questions. Just answer thoughtfully.

4. **Be specific and concise** - Focus on providing actual insights about the book rather than filler phrases.

5. **Admit uncertainty** - If you don't know something, say so directly without apologetic fluff.

**Discussion topics:**
- The book's plot, themes, and characters
- The author's style and other works  
- The book's context and background
- Recommendations for similar books

**Response style:**
- Natural, conversational tone
- Direct and to the point
- No generic AI pleasantries
- Focus on substantive content about the book
''';
  }

  LlmChatViewStyle _buildChatStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    if (!isDark) return LlmChatViewStyle.defaultStyle();

    // Dark theme optimized colors
    final surfaceColor = colors.surface;
    final textColor = colors.onSurface;
    final secondaryTextColor = colors.onSurface.withValues(alpha: 0.7);
    final bubbleBg = const Color(0xFF2D2D2D);
    final userBubbleBg = const Color(0xFF00796B);

    return LlmChatViewStyle(
      backgroundColor: surfaceColor,
      menuColor: const Color(0xFF424242),
      progressIndicatorColor: textColor,
      chatInputStyle: ChatInputStyle(
        backgroundColor: bubbleBg,
        textStyle: TextStyle(color: textColor, fontSize: 14),
        hintStyle: TextStyle(
          color: secondaryTextColor,
          fontSize: 14,
        ),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      userMessageStyle: UserMessageStyle(
        textStyle: const TextStyle(color: Colors.white),
        decoration: BoxDecoration(
          color: userBubbleBg,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      llmMessageStyle: LlmMessageStyle(
        iconColor: textColor,
        iconDecoration: BoxDecoration(
          color: bubbleBg,
          shape: BoxShape.circle,
        ),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.zero,
            bottomLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        markdownStyle: MarkdownStyleSheet(
          p: TextStyle(color: textColor, fontSize: 14),
          h1: TextStyle(color: textColor, fontSize: 24),
          h2: TextStyle(color: textColor, fontSize: 20),
          h3: TextStyle(color: textColor, fontSize: 18),
          h4: TextStyle(color: textColor, fontSize: 16),
          h5: TextStyle(color: textColor, fontSize: 14),
          h6: TextStyle(color: textColor, fontSize: 12),
          code: TextStyle(color: textColor, backgroundColor: bubbleBg),
          codeblockDecoration: BoxDecoration(
            color: bubbleBg,
            borderRadius: BorderRadius.circular(8),
          ),
          blockquoteDecoration: BoxDecoration(
            color: bubbleBg,
            borderRadius: BorderRadius.circular(4),
          ),
          listBullet: TextStyle(color: textColor),
        ),
      ),
      suggestionStyle: SuggestionStyle(
        textStyle: TextStyle(color: textColor),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      fileAttachmentStyle: FileAttachmentStyle(
        decoration: ShapeDecoration(
          color: bubbleBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        filenameStyle: TextStyle(color: textColor),
        filetypeStyle: TextStyle(color: secondaryTextColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isBlocked) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chat about "${widget.book.volumeInfo.title}"'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: colors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chat Limit Reached',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ve used all ${_subscriptionService.maxChatSessions} free chat sessions. '
                  'Upgrade to Premium for unlimited chats.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => showUpgradeDialog(
                    context,
                    currentCount: _subscriptionService.maxChatSessions,
                    maxBooks: _subscriptionService.maxChatSessions,
                  ),
                  icon: const Icon(Icons.star),
                  label: const Text('Upgrade to Premium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat about "${widget.book.volumeInfo.title}"'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear chat history',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Chat History'),
                  content: const Text(
                    'This will delete all messages in this conversation. This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _persistenceService.clearHistory(_userId, _bookId);
                        _provider.history = [];
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: LlmChatView(
        provider: _provider,
        welcomeMessage:
            'Hi! I\'m your BuddyBook AI. Ask me anything about "${widget.book.volumeInfo.title}" by ${widget.book.volumeInfo.authorsString}.',
        style: _buildChatStyle(context),
        enableAttachments: false,
        enableVoiceNotes: false,
      ),
    );
  }
}
