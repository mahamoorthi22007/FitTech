class TutorialStep {
  final int stepId;
  final String instructionTamil;
  final String animationType;
  final Map<String, dynamic> coordinates;

  TutorialStep({required this.stepId, required this.instructionTamil, required this.animationType, required this.coordinates});

  factory TutorialStep.fromJson(Map<String, dynamic> json) {
    return TutorialStep(
      stepId: json['step_id'],
      instructionTamil: json['instruction_tamil'],
      animationType: json['animation_type'],
      coordinates: json['coordinates'],
    );
  }
}