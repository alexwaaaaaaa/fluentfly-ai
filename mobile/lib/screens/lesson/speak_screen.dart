import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../models/chat_message.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/mic_button.dart';
import '../../providers/ai_provider.dart';
import '../../providers/audio_provider.dart';

class SpeakScreen extends ConsumerStatefulWidget {
  final int lessonId;
  final String? topic;
  final VoidCallback onComplete;

  const SpeakScreen({
    super.key,
    required this.lessonId,
    this.topic,
    required this.onComplete,
  });

  @override
  ConsumerState<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends ConsumerState<SpeakScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _currentRecordingPath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Initialize session with a welcome message
    _initializeSession();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    // Generate a session ID
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    ref.read(chatSessionIdProvider.notifier).state = sessionId;

    // Add welcome message
    final welcomeMessage = ChatMessage(
      text:
          'Hello! Let\'s practice speaking English together. Press the microphone to start!',
      isUser: false,
      timestamp: DateTime.now(),
    );

    ref.read(chatMessagesProvider.notifier).state = [welcomeMessage];
  }

  Future<void> _toggleRecording() async {
    final isRecording = ref.read(isRecordingProvider);
    final audioService = ref.read(audioServiceProvider);

    if (isRecording) {
      // Stop recording and process
      ref.read(isRecordingProvider.notifier).state = false;

      try {
        final recordingPath = await audioService.stopRecording();
        if (recordingPath != null) {
          _currentRecordingPath = recordingPath;
          await _processUserSpeech(File(recordingPath));
        }
      } catch (e) {
        _showError('Failed to stop recording: $e');
      }
    } else {
      // Start recording
      try {
        await audioService.startRecording();
        ref.read(isRecordingProvider.notifier).state = true;
      } catch (e) {
        _showError('Failed to start recording: $e');
      }
    }
  }

  Future<void> _processUserSpeech(File audioFile) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final sessionId = ref.read(chatSessionIdProvider);

      // Process audio through STT and get AI response
      final response = await aiService.processChatTurnWithAudio(
        audioFile: audioFile,
        sessionId: sessionId,
      );

      // Add user message (transcribed text)
      final messages = ref.read(chatMessagesProvider);
      final userMessage = ChatMessage(
        text: 'User spoke', // We don't have the transcription directly
        isUser: true,
        timestamp: DateTime.now(),
        audioUrl: _currentRecordingPath,
      );

      // Add AI response
      final aiMessage = ChatMessage(
        text: response.reply,
        isUser: false,
        timestamp: DateTime.now(),
        audioUrl: response.ttsUrl,
      );

      ref.read(chatMessagesProvider.notifier).state = [
        ...messages,
        userMessage,
        aiMessage,
      ];

      // Update AI emotion
      ref.read(aiEmotionProvider.notifier).state = response.emotion;

      // Play AI response audio
      await _playAiResponse(response.ttsUrl);

      // Show hint if available
      if (response.hint != null && response.hint!.isNotEmpty) {
        _showHint(response.hint!);
      }

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to process speech: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _playAiResponse(String audioUrl) async {
    try {
      final audioService = ref.read(audioServiceProvider);

      // Set AI speaking state
      ref.read(aiSpeakingProvider.notifier).state = true;

      // Play the audio
      await audioService.playAudio(audioUrl);

      // Reset AI speaking state
      ref.read(aiSpeakingProvider.notifier).state = false;
    } catch (e) {
      ref.read(aiSpeakingProvider.notifier).state = false;
      _showError('Failed to play audio: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showHint(String hint) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lightbulb, color: Color(0xFF39FF14)),
            const SizedBox(width: 8),
            Expanded(child: Text(hint)),
          ],
        ),
        backgroundColor: const Color(0xFF1A1F26),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _startVideoCall() {
    Navigator.pushNamed(
      context,
      '/video-call',
      arguments: {
        'lessonId': widget.lessonId,
        'topic': widget.topic ?? 'Speaking Practice',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isRecording = ref.watch(isRecordingProvider);
    final aiSpeaking = ref.watch(aiSpeakingProvider);
    final aiEmotion = ref.watch(aiEmotionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Speaking Practice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: widget.onComplete,
            tooltip: 'Complete',
          ),
        ],
      ),
      body: Column(
        children: [
          // Avatar section
          Padding(
            padding: const EdgeInsets.all(24),
            child: AvatarWidget(isAnimating: aiSpeaking, emotion: aiEmotion),
          ),

          // Video Call Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _buildVideoCallButton(),
          ),

          // Chat messages
          Expanded(child: _buildChatMessages(messages)),

          // Recording indicator
          if (isRecording)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildRecordingIndicator(),
            ),

          // Processing indicator
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildProcessingIndicator(),
            ),

          // Microphone button
          Padding(
            padding: const EdgeInsets.all(24),
            child: MicButton(
              isRecording: isRecording,
              onPressed: _isProcessing ? null : _toggleRecording,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF00BFFF).withOpacity(0.2)
              : Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: message.isUser
                ? const Color(0xFF00BFFF).withOpacity(0.3)
                : Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: Colors.grey[200], fontSize: 15, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 40,
            child: Lottie.asset(
              'assets/lottie/audio_wave_mic.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Listening...',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFFF).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00BFFF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF00BFFF),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Processing...',
            style: TextStyle(
              color: Color(0xFF00BFFF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCallButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFFF), Color(0xFF0080FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFFF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _startVideoCall,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Start Video Call with AI Tutor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Practice speaking face-to-face',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
