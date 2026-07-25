import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gemmea/core/core.dart';
import 'package:gemmea/presentation/bloc/bloc.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  String _activeSpeakingText = "";

  @override
  void initState() {
    super.initState();
    VoiceService.instance.onTtsComplete = () {
      if (mounted) {
        setState(() => _activeSpeakingText = "");
      }
    };
    context.read<ChatCubit>().loadChatHistory();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleMic() async {
    if (_isListening) {
      await VoiceService.instance.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await VoiceService.instance.startListening(
        onResult: (recognizedText) {
          setState(() {
            _messageController.text = recognizedText;
          });
        },
        onDone: () {
          setState(() => _isListening = false);
        },
      );
    }
  }

  void _speakMessage(String text) async {
    if (_activeSpeakingText == text) {
      await VoiceService.instance.stopSpeaking();
      if (mounted) {
        setState(() => _activeSpeakingText = "");
      }
    } else {
      if (mounted) {
        setState(() => _activeSpeakingText = text);
      }
      await VoiceService.instance.speak(text);
    }
  }

  void _submitMessage() {
    final text = _messageController.text;
    if (text.trim().isNotEmpty) {
      context.read<ChatCubit>().sendMessage(text);
      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  Future<void> _showClearConfirmationDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.r20),
          ),
          backgroundColor: AppColors.cardCleanWhite,
          title: const Row(
            children: [
              HugeIcon(
                icon: AppIcons.alert,
                color: Colors.redAccent,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                "Supprimer la discussion ?",
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.textCharcoal,
                ),
              ),
            ],
          ),
          content: const Text(
            "Êtes-vous sûr de vouloir effacer tout l'historique de cette conversation ? Cette action est irréversible.",
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: AppSize.p16, vertical: AppSize.p12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "Annuler",
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSize.r12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSize.p16, vertical: AppSize.p8),
              ),
              child: const Text(
                "Supprimer",
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      context.read<ChatCubit>().clearConversation();
      context.read<HomeCubit>().loadDashboard(); // Refresh calendar too
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Assistant Gemmea",
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            color: AppColors.primaryForestGreen,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showClearConfirmationDialog,
            icon: const HugeIcon(icon: AppIcons.delete, color: AppColors.primaryForestGreen, size: AppSize.iconMd),
            tooltip: "Effacer les discussions",
          ),
        ],
      ),
      body: BlocConsumer<ChatCubit, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded) {
            Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
            
            // If the local function call updated the calendar, reload the dashboard elements in background
            if (state.systemNotification != null) {
              context.read<HomeCubit>().loadDashboard();
            }
          }
        },
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForestGreen),
              ),
            );
          } else if (state is ChatError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSize.p24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(icon: AppIcons.alert, color: AppColors.errorRed, size: AppSize.iconXl),
                    const SizedBox(height: AppSize.p16),
                    Text("Error: ${state.error}", textAlign: TextAlign.center),
                    const SizedBox(height: AppSize.p16),
                    ElevatedButton(
                      onPressed: () => context.read<ChatCubit>().loadChatHistory(),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is ChatLoaded) {
            return Column(
              children: [
                // Top banner for structural function calling update alerts
                if (state.systemNotification != null)
                  Container(
                    width: double.infinity,
                    color: AppColors.primaryForestGreen.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(horizontal: AppSize.p16, vertical: 10.0),
                    child: Row(
                      children: [
                        const HugeIcon(
                          icon: AppIcons.home,
                          color: AppColors.primaryForestGreen,
                          size: 20.0,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.systemNotification!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryForestGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Chat Messages viewport
                Expanded(
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    behavior: HitTestBehavior.translucent,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSize.p16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        final isLast = index == state.messages.length - 1;
                        final isLastAndStreaming = isLast && state.isStreaming;
                        return _buildMessageBubble(message, isLastAndStreaming);
                      },
                    ),
                  ),
                ),

                // Text Input area
                _buildMessageInput(state.isStreaming),
              ],
            );
          }
          return Container();
        },
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isLastAndStreaming) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSize.p12),
        padding: const EdgeInsets.symmetric(horizontal: AppSize.p16, vertical: AppSize.p12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryForestGreen : AppColors.cardCleanWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSize.r16),
            topRight: const Radius.circular(AppSize.r16),
            bottomLeft: Radius.circular(isUser ? AppSize.r16 : 4.0),
            bottomRight: Radius.circular(isUser ? 4.0 : AppSize.r16),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: isUser
            ? MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.0,
                    height: 1.4,
                    fontFamily: 'Fredoka',
                  ),
                  strong: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Fredoka',
                  ),
                  em: const TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                  listBullet: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              )
            : (message.text.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: ThreeDotBounce(color: AppColors.primaryForestGreen),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSize.p8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryForestGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppSize.r12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HugeIcon(icon: AppIcons.check, size: 12.0, color: AppColors.primaryForestGreen),
                                SizedBox(width: 4),
                                Text(
                                  "Ancré FAO RAG",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryForestGreen,
                                    fontFamily: 'Fredoka',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _activeSpeakingText == message.text
                              ? GestureDetector(
                                  onTap: () => _speakMessage(message.text),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSize.p8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.redAccent, width: 1.2),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        HugeIcon(icon: AppIcons.stop, size: 14.0, color: Colors.redAccent),
                                        SizedBox(width: 4),
                                        Text(
                                          "STOP",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.redAccent,
                                            fontFamily: 'Fredoka',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () => _speakMessage(message.text),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSize.p8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryForestGreen.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        HugeIcon(icon: AppIcons.play, size: 16.0, color: AppColors.primaryForestGreen),
                                        SizedBox(width: 4),
                                        Text(
                                          "Écouter",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryForestGreen,
                                            fontFamily: 'Fredoka',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            color: AppColors.textCharcoal,
                            fontSize: 15.0,
                            height: 1.4,
                            fontFamily: 'Fredoka',
                          ),
                          strong: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textCharcoal,
                            fontFamily: 'Fredoka',
                          ),
                          em: const TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                          listBullet: const TextStyle(
                            color: AppColors.primaryForestGreen,
                          ),
                        ),
                      ),
                      if (isLastAndStreaming) ...[
                        const SizedBox(height: 8.0),
                        const ThreeDotBounce(color: AppColors.primaryForestGreen, size: 5.0),
                      ],
                    ],
                  )),
      ),
    );
  }

  Widget _buildMessageInput(bool isStreaming) {
    return Container(
      color: AppColors.cardCleanWhite,
      padding: const EdgeInsets.all(AppSize.p12),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _toggleMic,
              style: IconButton.styleFrom(
                backgroundColor: _isListening ? Colors.redAccent : AppColors.primaryForestGreen.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(10.0),
              ),
              icon: HugeIcon(
                icon: AppIcons.mic,
                color: _isListening ? Colors.white : AppColors.primaryForestGreen,
                size: 22.0,
              ),
              tooltip: _isListening ? "Écoute en cours..." : "Dictée vocale",
            ),
            const SizedBox(width: AppSize.p8),
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
                textCapitalization: TextLinesSpacing.hasUnderlyingSpacing ? TextCapitalization.sentences : TextCapitalization.none,
                decoration: InputDecoration(
                  hintText: "Posez des questions sur le manioc, le neem, etc...",
                  hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: AppColors.primaryForestGreen.withValues(alpha: 0.12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: AppColors.primaryForestGreen.withValues(alpha: 0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(color: AppColors.primaryForestGreen),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSize.p16, vertical: 10.0),
                ),
                onSubmitted: (_) => _submitMessage(),
              ),
            ),
            const SizedBox(width: AppSize.p8),
            IconButton(
              onPressed: isStreaming ? null : _submitMessage,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryForestGreen,
                disabledBackgroundColor: AppColors.textGrey.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(AppSize.p12),
              ),
              icon: const HugeIcon(
                icon: AppIcons.send,
                color: Colors.white,
                size: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TextLinesSpacing {
  static const bool hasUnderlyingSpacing = true;
}

class ThreeDotBounce extends StatefulWidget {
  final Color color;
  final double size;

  const ThreeDotBounce({
    super.key,
    this.color = AppColors.primaryForestGreen,
    this.size = 6.0,
  });

  @override
  State<ThreeDotBounce> createState() => _ThreeDotBounceState();
}

class _ThreeDotBounceState extends State<ThreeDotBounce> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: -8.0).animate(
        CurvedAnimation(
          parent: _controllers[index],
          curve: Curves.easeInOut,
        ),
      );
    });

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
