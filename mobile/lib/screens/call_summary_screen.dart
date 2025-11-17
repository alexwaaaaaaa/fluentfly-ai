import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../utils/logger.dart';
import '../providers/progress_provider.dart';
import '../providers/lesson_state_provider.dart';

/// Model for call summary data
class CallSummaryData {
  final int sessionId;
  final Duration duration;
  final int totalSpeakingTime;
  final int wordsPerMinute;
  final int pauseCount;
  final double averagePauseLength;
  final int fluencyScore;
  final int turnCount;
  final List<ConversationTurnData> conversationTurns;

  CallSummaryData({
    required this.sessionId,
    required this.duration,
    required this.totalSpeakingTime,
    required this.wordsPerMinute,
    required this.pauseCount,
    required this.averagePauseLength,
    required this.fluencyScore,
    required this.turnCount,
    required this.conversationTurns,
  });
}

class ConversationTurnData {
  final String speaker;
  final String text;
  final DateTime timestamp;

  ConversationTurnData({
    required this.speaker,
    required this.text,
    required this.timestamp,
  });
}

/// Call summary screen showing statistics and transcript
class CallSummaryScreen extends ConsumerStatefulWidget {
  final CallSummaryData summaryData;
  final int lessonId;
  final String topic;
  final bool markAsComplete;

  const CallSummaryScreen({
    super.key,
    required this.summaryData,
    required this.lessonId,
    required this.topic,
    this.markAsComplete = true,
  });

  @override
  ConsumerState<CallSummaryScreen> createState() => _CallSummaryScreenState();
}

class _CallSummaryScreenState extends ConsumerState<CallSummaryScreen> {
  final AppLogger _logger = AppLogger();
  bool _hasAwardedXp = false;

  @override
  void initState() {
    super.initState();
    // Award XP and mark as complete when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _awardXpAndMarkComplete();
    });
  }

  Future<void> _awardXpAndMarkComplete() async {
    if (_hasAwardedXp) return;
    _hasAwardedXp = true;

    try {
      // Calculate XP based on call duration (1 XP per 10 seconds, max 50 XP)
      final durationSeconds = widget.summaryData.duration.inSeconds;
      final xpAmount = (durationSeconds / 10).round().clamp(5, 50);

      _logger.info('Awarding $xpAmount XP for ${durationSeconds}s video call');

      // Award XP
      await ref
          .read(progressProvider.notifier)
          .awardXp(xpAmount, 'Video call practice - ${widget.topic}');

      // Mark speaking stage as complete if requested
      if (widget.markAsComplete) {
        final fluencyScore = widget.summaryData.fluencyScore;
        ref
            .read(lessonStateProvider(widget.lessonId).notifier)
            .completeStage(fluencyScore);

        _logger.info(
          'Marked speaking stage as complete with score: $fluencyScore',
        );
      }
    } catch (e) {
      _logger.error('Failed to award XP or mark complete', error: e);
      // Don't show error to user, just log it
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Summary'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildStatisticsSection(),
            _buildFluencyScoreSection(),
            _buildTranscriptSection(),
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Text(
            'Great Practice Session!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.topic,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _formatDuration(widget.summaryData.duration),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Total Duration',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer,
                  label: 'Speaking Time',
                  value: '${widget.summaryData.totalSpeakingTime}s',
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.speed,
                  label: 'Words/Min',
                  value: '${widget.summaryData.wordsPerMinute}',
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pause_circle,
                  label: 'Pauses',
                  value: '${widget.summaryData.pauseCount}',
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.chat_bubble,
                  label: 'Turns',
                  value: '${widget.summaryData.turnCount}',
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFluencyScoreSection() {
    final score = widget.summaryData.fluencyScore;
    final color = _getFluencyColor(score);
    final feedback = _getFluencyFeedback(score);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              'Fluency Score',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'out of 100',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              feedback,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getDetailedFeedback(score),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversation Transcript',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.textTertiary),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.summaryData.conversationTurns.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final turn = widget.summaryData.conversationTurns[index];
                return _buildTranscriptItem(turn);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptItem(ConversationTurnData turn) {
    final isUser = turn.speaker == 'user';
    final color = isUser ? AppTheme.accentColor : AppTheme.primaryColor;
    final icon = isUser ? Icons.person : Icons.smart_toy;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isUser ? 'You' : 'AI Tutor',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(turn.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(turn.text, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handlePracticeAgain,
              icon: const Icon(Icons.refresh),
              label: const Text('Practice Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleBackToLesson,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Lesson'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes min ${seconds}s';
    }
    return '${seconds}s';
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Color _getFluencyColor(int score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.primaryColor;
    if (score >= 40) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getFluencyFeedback(int score) {
    if (score >= 80) return 'Excellent!';
    if (score >= 60) return 'Good Job!';
    if (score >= 40) return 'Keep Practicing!';
    return 'Need More Practice';
  }

  String _getDetailedFeedback(int score) {
    if (score >= 80) {
      return 'Your fluency is excellent! You speak naturally with good pace and minimal pauses.';
    } else if (score >= 60) {
      return 'You\'re doing well! Try to reduce pauses and maintain a steady speaking pace.';
    } else if (score >= 40) {
      return 'You\'re making progress! Focus on speaking more continuously and building confidence.';
    } else {
      return 'Keep practicing! Try to speak more and don\'t worry about making mistakes.';
    }
  }

  void _handlePracticeAgain() {
    _logger.info('User wants to practice again');
    // Navigate to video call screen again
    Navigator.of(context).pushReplacementNamed(
      '/video-call',
      arguments: {'lessonId': widget.lessonId, 'topic': widget.topic},
    );
  }

  void _handleBackToLesson() {
    _logger.info('User returning to lesson');
    // Pop back to the lesson flow screen
    // Since we used pushReplacement from video call, we need to pop twice
    // to get back to the lesson flow
    Navigator.of(context).popUntil((route) {
      // Pop until we find the lesson flow screen or reach the main screen
      return route.settings.name == '/lesson-flow' ||
          route.settings.name == '/main' ||
          route.isFirst;
    });
  }
}
