import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class RestTimerSoundService {
  RestTimerSoundService();

  final AudioPlayer _player = AudioPlayer(playerId: 'rest_timer_ding');
  final AssetSource _soundAsset = AssetSource('audio/rest_ding.wav');
  bool _isPrepared = false;

  Future<void> preload() async {
	if (_isPrepared) {
	  return;
	}

	await _player.setReleaseMode(ReleaseMode.stop);
	await _player.setVolume(1.0);
	await _player.setSource(_soundAsset);
	_isPrepared = true;
  }

  Future<void> playOnce() async {
	try {
	  if (!_isPrepared) {
		await preload();
	  }
	  await _player.stop();
	  await _player.resume();
	} catch (_) {
	  // Fallback for devices where media asset playback is blocked.
	  unawaited(SystemSound.play(SystemSoundType.alert));
	}
  }

  Future<void> dispose() async {
	await _player.dispose();
  }
}

