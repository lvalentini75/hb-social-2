import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class RecordedVoice {
  final Uint8List bytes;
  final String extension;
  final String mime;
  final int durationMs;
  final List<double> waveform;

  const RecordedVoice({required this.bytes, required this.extension, required this.mime, required this.durationMs, required this.waveform});
}

/// Records encoded audio to memory so the same flow works on web and devices.
class ChatVoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  final List<int> _bytes = [];
  final List<double> _waveform = [];
  StreamSubscription<Uint8List>? _audioSubscription;
  Timer? _amplitudeTimer;
  Stopwatch? _stopwatch;
  String _extension = 'm4a';
  String _mime = 'audio/mp4';

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start(ValueChanged<double> onAmplitude) async {
    _bytes.clear(); _waveform.clear();
    final aac = await _recorder.isEncoderSupported(AudioEncoder.aacLc);
    _extension = aac ? 'm4a' : 'webm';
    _mime = aac ? 'audio/mp4' : 'audio/webm';
    final stream = await _recorder.startStream(RecordConfig(encoder: aac ? AudioEncoder.aacLc : AudioEncoder.opus, bitRate: 64000, sampleRate: 44100, numChannels: 1));
    _audioSubscription = stream.listen(_bytes.addAll);
    _stopwatch = Stopwatch()..start();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 120), (_) async {
      final amplitude = await _recorder.getAmplitude();
      final normalized = ((amplitude.current + 60) / 60).clamp(0.0, 1.0);
      _waveform.add(normalized); onAmplitude(normalized);
    });
  }

  Future<RecordedVoice?> stop() async {
    await _recorder.stop();
    await _audioSubscription?.cancel();
    _amplitudeTimer?.cancel();
    final duration = _stopwatch?.elapsedMilliseconds ?? 0;
    _stopwatch?.stop();
    if (_bytes.isEmpty) return null;
    return RecordedVoice(bytes: Uint8List.fromList(_bytes), extension: _extension, mime: _mime, durationMs: duration, waveform: List.unmodifiable(_waveform));
  }

  Future<void> cancel() async { await _recorder.cancel(); await _audioSubscription?.cancel(); _amplitudeTimer?.cancel(); _stopwatch?.stop(); _bytes.clear(); }
  Future<void> dispose() async { await cancel(); await _recorder.dispose(); }
}