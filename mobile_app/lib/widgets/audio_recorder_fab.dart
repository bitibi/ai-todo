import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';

class AudioRecorderFAB extends StatefulWidget {
  const AudioRecorderFAB({super.key});

  @override
  State<AudioRecorderFAB> createState() => _AudioRecorderFABState();
}

class _AudioRecorderFABState extends State<AudioRecorderFAB> {
  void _openVoiceOverlay() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppTheme.bg,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const VoiceOverlay();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: FloatingActionButton(
        onPressed: _openVoiceOverlay,
        backgroundColor: AppTheme.accent,
        shape: const CircleBorder(),
        elevation: 0,
        child: const Icon(Icons.mic, color: Colors.white),
      ),
    );
  }
}

class VoiceOverlay extends StatefulWidget {
  const VoiceOverlay({super.key});

  @override
  State<VoiceOverlay> createState() => _VoiceOverlayState();
}

enum VoiceState { listening, thinking, saved }

class _VoiceOverlayState extends State<VoiceOverlay> with SingleTickerProviderStateMixin {
  VoiceState _state = VoiceState.listening;
  late final AudioRecorder _audioRecorder;
  String _transcript = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _startRecording();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 64000,
          ), 
          path: filePath
        );
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required')));
        }
      }
    } catch (e) {
      print('Recording start error: $e');
    }
  }

  Future<void> _stopRecordingAndProcess() async {
    setState(() {
      _state = VoiceState.thinking;
    });
    
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final text = await ApiService().transcribe(path);
        if (text != null && mounted) {
          setState(() {
            _transcript = text;
            _state = VoiceState.saved;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
          return;
        }
      }
    } catch (e) {
      print('Recording stop error: $e');
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to transcribe')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () {
                  _audioRecorder.stop();
                  Navigator.pop(context);
                },
              ),
            ),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_state == VoiceState.listening) ...[
                      const Icon(Icons.circle, color: AppTheme.accent, size: 8),
                      const SizedBox(width: 8),
                      const Text('LISTENING', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
                    ] else if (_state == VoiceState.thinking) ...[
                      const Icon(Icons.circle_outlined, color: Colors.white54, size: 8),
                      const SizedBox(width: 8),
                      const Text('THINKING', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
                    ] else if (_state == VoiceState.saved) ...[
                      const Icon(Icons.check, color: Colors.white54, size: 12),
                      const SizedBox(width: 4),
                      const Text('DONE', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                if (_state == VoiceState.listening)
                  const Text("Tap the orb when you're done", style: TextStyle(color: Colors.white38))
                else if (_state == VoiceState.thinking)
                  const Text("Working on it...", style: TextStyle(color: Colors.white38))
                else if (_state == VoiceState.saved)
                  const Text("Saved", style: TextStyle(color: Colors.white)),

                const SizedBox(height: 60),

                if (_state == VoiceState.thinking || _state == VoiceState.saved)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      '"$_transcript"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),

                const Spacer(),

                if (_state == VoiceState.listening)
                  GestureDetector(
                    onTap: _stopRecordingAndProcess,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 80 + (_pulseController.value * 20),
                          height: 80 + (_pulseController.value * 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accent.withOpacity(0.2 + (_pulseController.value * 0.8)),
                          ),
                          child: const Icon(Icons.mic, color: Colors.white, size: 32),
                        );
                      },
                    ),
                  )
                else if (_state == VoiceState.thinking)
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  )
                else if (_state == VoiceState.saved)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent),
                    child: const Icon(Icons.mic, color: Colors.white, size: 32),
                  ),

                const SizedBox(height: 24),
                
                if (_state == VoiceState.listening)
                  const Text('TAP TO STOP', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2))
                else if (_state == VoiceState.saved)
                  const Text('AUTO-CLOSING', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2))
                else
                  const SizedBox(height: 12),

                const SizedBox(height: 60),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
