import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/language_service.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../widgets/theme_toggle_button.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final List<_ChatMessage> _messages;
  String _selectedLanguage = LanguageService.currentLanguage.value;
  bool _isSending = false;
  int _recommendationIndex = 0;

  static const List<String> _languages = [
    'English',
    'Hindi',
    'Bengali',
    'Tamil',
    'Telugu',
    'Marathi',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Urdu',
    'Odia',
    'Assamese',
    'Spanish',
    'French',
    'Arabic',
  ];

  @override
  void initState() {
    super.initState();
    _messages = [
      _ChatMessage(text: _introFor(_selectedLanguage), isUser: false),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();

    final reply = await _getSecureReply(text);

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<String> _getSecureReply(String message) async {
    if (!SupabaseConfig.isConfigured ||
        Supabase.instance.client.auth.currentUser == null) {
      return _localGuidanceFor(message, _selectedLanguage);
    }

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'parent-chat',
        body: {'message': message, 'language': _selectedLanguage},
      );
      final data = response.data;
      if (data is Map && data['reply'] is String) {
        final reply = data['reply'] as String;
        if (_isPlaceholderBackendReply(reply)) {
          return _localGuidanceFor(message, _selectedLanguage);
        }
        return reply;
      }
    } catch (_) {
      return _localGuidanceFor(message, _selectedLanguage);
    }

    return _localGuidanceFor(message, _selectedLanguage);
  }

  bool _isPlaceholderBackendReply(String reply) {
    final lower = reply.toLowerCase();
    return lower.contains('backend') ||
        lower.contains('not deployed') ||
        lower.contains('these replies are only general guidance') ||
        lower.trim().isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI Parent Chat'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.12) : AppTheme.primary.withOpacity(0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        isExpanded: true,
                        dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                        icon: const Icon(LucideIcons.chevronDown),
                        items: _languages
                            .map(
                              (language) => DropdownMenuItem(
                                value: language,
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.languages,
                                      size: 18,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      language,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (language) {
                          if (language == null) return;
                          setState(() {
                            _selectedLanguage = language;
                            _messages.add(
                              _ChatMessage(
                                text: _introFor(language),
                                isUser: false,
                              ),
                            );
                          });
                          _scrollToBottom();
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _ChatBubble(message: _messages[index]),
                  ),
                ),
                if (_isSending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Thinking...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    12 + MediaQuery.viewInsetsOf(context).bottom * 0.05,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 3,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Ask about activities or recommendations...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white60 : AppTheme.textSecondary,
                            ),
                            filled: true,
                            fillColor: isDark ? AppTheme.cardDark : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: isDark
                                  ? BorderSide(color: Colors.white.withOpacity(0.12))
                                  : BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: isDark
                                  ? BorderSide(color: Colors.white.withOpacity(0.12))
                                  : BorderSide(color: Colors.black.withOpacity(0.06)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 56,
                        width: 56,
                        child: IconButton.filled(
                          onPressed: _sendMessage,
                          icon: const Icon(LucideIcons.send),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _introFor(String language) {
    switch (language) {
      case 'Hindi':
        return 'Namaste, aap activities, reminders aur screening results ke baare me pooch sakte hain. Main diagnosis nahi karta; medical concern ho toh qualified doctor se consult karein.';
      case 'Spanish':
        return 'Hola, puedo ayudarle con actividades, recordatorios y resultados de evaluacion. No puedo diagnosticar; consulte a un profesional medico para dudas de salud.';
      case 'French':
        return 'Bonjour, je peux aider avec les activites, rappels et resultats. Je ne diagnostique pas; consultez un professionnel de sante pour les questions medicales.';
      default:
        return 'Hi, I can help you understand activities, reminders, and screening results. I cannot diagnose; for medical concerns, please consult a qualified professional.';
    }
  }

  String _localGuidanceFor(String message, String language) {
    final lower = message.toLowerCase();
    final isGreeting =
        lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        lower.contains('namaste') ||
        lower.contains('hii');
    final asksActivity =
        lower.contains('activity') ||
        lower.contains('activities') ||
        lower.contains('recommend') ||
        lower.contains('more') ||
        lower.contains('suggest') ||
        lower.contains('game');

    if (language == 'Hindi') {
      if (isGreeting) {
        return 'Namaste! Aap mujhse activity ideas, screening result, reminder, ya parent guidance ke baare me pooch sakte hain. Main diagnosis nahi karta, par simple aur safe guidance de sakta hoon.';
      }
      if (asksActivity) {
        return _nextRecommendationHindi();
      }
      if (lower.contains('reminder') || lower.contains('streak')) {
        return 'Reminder ko parent ke routine ke hisaab se set karein. Streak tab badhega jab aap activity complete, questionnaire save, ya photo result save karenge.';
      }
      if (lower.contains('photo') ||
          lower.contains('result') ||
          lower.contains('assessment') ||
          lower.contains('score')) {
        return 'Photo ya questionnaire result ko sirf screening support ki tarah dekhein. Agar concern repeat ho raha hai ya child ko difficulty hai, pediatrician ya specialist se consult karein.';
      }
      return 'Main aapko activities, reminders aur screening results samjhane me help kar sakta hoon. Medical diagnosis ke liye qualified doctor se consult karna best hai.';
    }

    if (isGreeting) {
      return 'Hi! You can ask me for activity ideas, result explanations, reminder help, or whether a recommendation is suitable. I can guide you, but I cannot diagnose.';
    }
    if (asksActivity) {
      return _nextRecommendationEnglish();
    }
    if (lower.contains('reminder') || lower.contains('streak')) {
      return 'Set reminders for realistic days and times. Your streak updates when an activity is marked complete or an assessment result is saved.';
    }
    if (lower.contains('result') || lower.contains('assessment')) {
      return 'Use saved results to track patterns over time. Screening results are not a diagnosis, so share concerns with a qualified doctor or clinician.';
    }

    switch (language) {
      case 'Spanish':
        return 'Puedo ayudar con actividades, recordatorios y resultados. Para informacion medica precisa, consulte a un doctor.';
      case 'French':
        return 'Je peux aider avec les activites, rappels et resultats. Pour un avis medical precis, consultez un medecin.';
      default:
        return 'I can help with activities, reminders, and screening results. For accurate medical advice, please visit a qualified doctor.';
    }
  }

  String _nextRecommendationEnglish() {
    final recommendations = [
      'Try Color Sorting for 6-8 minutes: place red, blue, and yellow objects in separate bowls. Give one instruction at a time and praise every correct match.',
      'Try Follow the Sound: sit across the room, play a soft clap or bell from the left/right side, and ask the child to point toward the sound. Keep it playful and short.',
      'Try Emotion Cards: show one face card, name the emotion, and ask “happy or sad?” Use only 2 emotions first, then slowly add more.',
      'Try Texture Touch: offer soft cloth, sponge, and smooth toy one by one. Let the child touch voluntarily and stop immediately if they look uncomfortable.',
      'Try Joint Attention Play: point to a toy, say “look,” wait 3 seconds, then celebrate if the child looks or reaches. Repeat only 5-6 times.',
    ];
    final reply =
        recommendations[_recommendationIndex % recommendations.length];
    _recommendationIndex++;
    return '$reply\n\nThese are practice ideas, not medical treatment. For accurate guidance, consult a qualified doctor or therapist.';
  }

  String _nextRecommendationHindi() {
    final recommendations = [
      'Color Sorting try karein: red, blue aur yellow objects ko alag bowls me dalwayen. Ek time par sirf ek instruction dein aur correct match par praise karein.',
      'Follow the Sound try karein: left/right side se halki clap ya bell sound bajayen aur child se direction point karne ko bolen. 5-6 minutes enough hai.',
      'Emotion Cards try karein: happy aur sad face cards se start karein. Pehle emotion ka naam bolen, phir child ko choose karne dein.',
      'Texture Touch try karein: soft cloth, sponge aur smooth toy ek-ek karke offer karein. Child uncomfortable lage toh turant stop karein.',
      'Joint Attention Play try karein: toy ki taraf point karke “dekho” bolen, 3 seconds wait karein, aur child response kare toh praise karein.',
    ];
    final reply =
        recommendations[_recommendationIndex % recommendations.length];
    _recommendationIndex++;
    return '$reply\n\nYeh sirf practice ideas hain, medical treatment nahi. Accurate guidance ke liye qualified doctor ya therapist se consult karein.';
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser 
              ? AppTheme.primary 
              : (isDark ? AppTheme.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: message.isUser
                ? Colors.transparent
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.transparent),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.24 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser 
                ? Colors.white 
                : (isDark ? Colors.white : AppTheme.textPrimary),
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}
