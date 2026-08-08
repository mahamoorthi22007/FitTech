// lib/controllers/tutorial_manager.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/tutorial_step.dart';

class TutorialManager extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<TutorialStep> _steps = [];
  int _currentIndex = 0;

  List<TutorialStep> get steps => _steps;
  TutorialStep get currentStep => _steps[_currentIndex];
  bool get isLastStep => _currentIndex == _steps.length - 1;
  bool get hasSteps => _steps.isNotEmpty;

  void loadSteps(List<dynamic> jsonList) {
    _steps = jsonList.map((json) => TutorialStep.fromJson(json)).toList();
    _currentIndex = 0;
    notifyListeners();
    _playAudioForCurrentStep(); // Auto-play the first step
  }

  Future<void> nextStep() async {
    if (_currentIndex < _steps.length - 1) {
      _currentIndex++;
      await _playAudioForCurrentStep(); // Auto-play when moving to next step
      notifyListeners();
    }
  }

  Future<void> _playAudioForCurrentStep() async {
    // Stop current audio before playing new one
    await _audioPlayer.stop();
    
    // Assuming audioUrl comes from the backend in your JSON
    final String? url = currentStep.audioUrl; 
    if (url != null && url.isNotEmpty) {
      await _audioPlayer.play(UrlSource(url));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}