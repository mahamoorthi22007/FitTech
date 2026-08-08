import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:silai_app/theme/app_theme.dart';
import 'package:silai_app/widgets/realistic_sewing_scene.dart';
import 'package:silai_app/widgets/blueprint_glow_overlay.dart';
import 'stitch_instructions_screen.dart';

class BlueprintScreen extends StatefulWidget {
  static const String machineIp = "172.16.63.111";
  static const String serverPort = "5000";

  final String dressType;
  final bool skipToMeasurements;
  final String? passedDesignImage;
  final String? passedDesignAsset;
  final int? initialStep;

  const BlueprintScreen({
    Key? key,
    required this.dressType,
    this.skipToMeasurements = false,
    this.passedDesignImage,
    this.passedDesignAsset,
    this.initialStep,
  }) : super(key: key);

  @override
  _BlueprintScreenState createState() => _BlueprintScreenState();
}

class _BlueprintScreenState extends State<BlueprintScreen> with TickerProviderStateMixin {
  late int _step;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  String? _selectedFabric;
  String? _selectedAariWork;

  File? _uploadedFabricImage;
  File? _uploadedFullPhotoImage;
  final ImagePicker _imagePicker = ImagePicker();

  String _detectedGarmentType = "";   
  String _detectedCategoryKey = "";   
  bool _isAnalyzingImage = false;
  String? _processedBase64Payload;

  Map<String, dynamic>? _aiPredictionResponse;
  String? _generatedSvgString;
  String? _tamilTutorialText;

  late AnimationController _blueprintAnim;
  late Animation<double> _blueprintScale;

  final List<Map<String, String>> _fabricOptions = [
    {'name': 'Brocade', 'image': 'assets/images/brocade.png'},
    {'name': 'Silk', 'image': 'assets/images/silk.png'},
    {'name': 'Linen', 'image': 'assets/images/linen.png'},
    {'name': 'Organza', 'image': 'assets/images/organza.png'},
    {'name': 'Georgette', 'image': 'assets/images/georgotta.png'},
    {'name': 'Cotton', 'image': 'assets/images/cotton.png'},
  ];

  final _fields = [
    {'key': 'shoulder', 'label': 'Shoulder Width', 'hint': 'e.g. 50 cm'},
    {'key': 'bust', 'label': 'Bust / Chest', 'hint': 'e.g. 36 cm'},
    {'key': 'waist', 'label': 'Waist', 'hint': 'e.g. 32 cm'},
    {'key': 'hip', 'label': 'Hip', 'hint': 'e.g. 40 cm'},
    {'key': 'sleeve', 'label': 'Sleeve Length', 'hint': 'e.g. 25 cm'},
    {'key': 'length', 'label': 'Dress Length', 'hint': 'e.g. 135 cm'},
    {'key': 'neck', 'label': 'Neck Circumference', 'hint': 'e.g. 38 cm'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedFabric = "Cotton"; // Default fabric selection to avoid validation issues

    final hasImage = widget.passedDesignImage != null && widget.passedDesignImage!.isNotEmpty;
    final hasAsset = widget.passedDesignAsset != null && widget.passedDesignAsset!.isNotEmpty;

    if (widget.initialStep != null) {
      _step = widget.initialStep!;
    } else {
      _step = (widget.skipToMeasurements && (hasImage || hasAsset)) ? 1 : 0;
    }

    for (final f in _fields) {
      _controllers[f['key']!] = TextEditingController();
    }

    _controllers['shoulder']?.text = '50';
    _controllers['bust']?.text = '36';
    _controllers['waist']?.text = '32';

    _blueprintAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _blueprintScale = CurvedAnimation(parent: _blueprintAnim, curve: Curves.elasticOut);

    if (hasAsset) {
      _loadAndAnalyzeAsset(widget.passedDesignAsset!);
    } else if (hasImage) {
      _analyzeSelectedImage(widget.passedDesignImage!);
    }
  }

  Future<void> _loadAndAnalyzeAsset(String assetPath) async {
    setState(() {
      _isAnalyzingImage = true;
    });
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List();
      final base64String = base64Encode(bytes);
      setState(() {
        _processedBase64Payload = base64String;
      });
      await _analyzeSelectedImage(base64String);
    } catch (e) {
      debugPrint("Error loading and analyzing asset: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzingImage = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    _blueprintAnim.dispose();
    super.dispose();
  }

  Future<void> _analyzeSelectedImage(String base64Image) async {
    setState(() {
      _isAnalyzingImage = true;
      _processedBase64Payload = base64Image;
    });

    final targetUrl = 'http://${BlueprintScreen.machineIp}:${BlueprintScreen.serverPort}/api/analyze-garment';
    try {
      final response = await http.post(
        Uri.parse(targetUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageBase64': base64Image}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _detectedGarmentType = (data['garmentName'] ?? '').toString();
          _detectedCategoryKey = (data['categoryKey'] ?? '').toString().toLowerCase().trim();
        });
      }
    } catch (e) {
      debugPrint("Vision pipeline tracking fallback failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzingImage = false;
        });
      }
    }
  }

  Future<void> _pickImage(bool isFabricZone) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() {
          if (isFabricZone) {
            _uploadedFabricImage = File(pickedFile.path);
          } else {
            _uploadedFullPhotoImage = File(pickedFile.path);
          }
        });

        if (isFabricZone) {
          _analyzeSelectedImage(base64String);
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _generateBlueprintWithAI() async {
    if (_isAnalyzingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI is still inspecting your garment pixels. Please wait a moment...')),
      );
      return;
    }

    final isLowerBodyGarment = _detectedCategoryKey == 'skirt' || _detectedCategoryKey == 'trousers';

    if (isLowerBodyGarment) {
      final rawWaistInput = _controllers['waist']?.text.trim() ?? "";
      final cleanWaistInput = rawWaistInput.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleanWaistInput.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI classified this as a Skirt/Trousers! Please enter a Waist size.')),
        );
        return;
      }
    } else {
      final rawChestInput = _controllers['bust']?.text.trim() ?? "";
      final cleanChestInput = rawChestInput.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleanChestInput.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI classified this as a pattern layout requiring a Bust/Chest input!')),
        );
        return;
      }
    }

    if (_processedBase64Payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a garment image design sample first!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, String> bodyMeasurements = {};
      _controllers.forEach((key, controller) {
        final cleanValue = controller.text.trim().replaceAll(RegExp(r'[^0-9.]'), '');
        if (cleanValue.isNotEmpty) {
          bodyMeasurements[key] = cleanValue;
        }
      });

      final genUrl = 'http://${BlueprintScreen.machineIp}:${BlueprintScreen.serverPort}/api/generate-blueprint';
      final genPayload = jsonEncode({
        'imageBase64': _processedBase64Payload,
        'measurements': bodyMeasurements,
        'garmentName': _detectedGarmentType,
        'categoryKey': _detectedCategoryKey,
        'fabricType': _selectedFabric,
      });

      final response = await http.post(
        Uri.parse(genUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: genPayload,
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _aiPredictionResponse = data;
          _generatedSvgString = data['svgBlueprint'];
          _tamilTutorialText = data['tamilTutorialText'];
          _step = 2;
        });
        _blueprintAnim.forward();
      } else {
        _showPipelineErrorOverlay("Server validation failed with error code: ${response.statusCode}");
      }
    } catch (e) {
      _showPipelineErrorOverlay("Network connection failed: $e\nMake sure your server is running on port ${BlueprintScreen.serverPort}!");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPipelineErrorOverlay(String errorDetails) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 5),
        content: Text('Image Analysis Link Failed: $errorDetails'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentGarmentDisplay = (_detectedGarmentType.isNotEmpty)
        ? _detectedGarmentType.toUpperCase()
        : widget.dressType.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Blueprint Studio', style: TextStyle(color: AppColors.espresso, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: AppColors.brick),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.blushLight, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  _isAnalyzingImage ? "ANALYZING..." : currentGarmentDisplay,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brick),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.brick),
                  SizedBox(height: 16),
                  Text('Analyzing image pixels & processing matrix vectors...', style: TextStyle(color: AppColors.espresso, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : Column(
              children: [
                StepProgressBar(current: _step + 1, total: 4, label: ['Fabric & Source', 'Measurements', 'Blueprint', 'Fit Check'][_step]),
                if (_isAnalyzingImage && _step == 1)
                  const LinearProgressIndicator(color: AppColors.brick, backgroundColor: AppColors.blushLight),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        if (_step == 0)
                          _StepUpload(
                            fabricOptions: _fabricOptions,
                            selectedFabric: _selectedFabric,
                            fabricFile: _uploadedFabricImage,
                            passedDesignAsset: widget.passedDesignAsset,
                            isAnalyzing: _isAnalyzingImage,
                            hasAnalyzedPayload: _processedBase64Payload != null,
                            onPickImage: () => _pickImage(true),
                            onFabricChanged: (fabric) => setState(() => _selectedFabric = fabric),
                            onNext: () => setState(() => _step = 1),
                          ),
                        if (_step == 1)
                          _StepMeasurements(
                            fields: _fields,
                            controllers: _controllers,
                            formKey: _formKey,
                            detectedCategoryKey: _detectedCategoryKey,
                            onGenerate: _generateBlueprintWithAI,
                          ),
                        if (_step == 2)
                          _StepBlueprint(
                            dressType: currentGarmentDisplay,
                            controllers: _controllers,
                            scaleAnim: _blueprintScale,
                            svgString: _generatedSvgString,
                            selectedAariWork: _selectedAariWork,
                            machineIp: BlueprintScreen.machineIp,
                            serverPort: BlueprintScreen.serverPort,
                            garmentType: _detectedCategoryKey.isNotEmpty ? _detectedCategoryKey : widget.dressType,
                            fabricType: _selectedFabric,
                            onAariSelected: (aariName) => setState(() => _selectedAariWork = aariName),
                            onFitCheck: () => setState(() => _step = 3),
                            onInstructions: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StitchInstructionsScreen(
                                    dressType: _detectedGarmentType.isNotEmpty ? _detectedGarmentType : widget.dressType,
                                    tutorialText: _tamilTutorialText,
                                  ),
                                ),
                              );
                            },
                          ),
                        if (_step == 3)
                          _StepFitCheck(
                            dressType: currentGarmentDisplay,
                            selectedAariWork: _selectedAariWork,
                            fullPhotoFile: _uploadedFullPhotoImage,
                            onPickFullPhoto: () => _pickImage(false),
                            onAariSelected: (aariName) => setState(() => _selectedAariWork = aariName),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class StepProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final String label;

  const StepProgressBar({Key? key, required this.current, required this.total, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: AppColors.blushLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Step $current of $total", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brick)),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.espresso)),
        ],
      ),
    );
  }
}

class _StepUpload extends StatelessWidget {
  final List<Map<String, String>> fabricOptions;
  final String? selectedFabric;
  final File? fabricFile;
  final String? passedDesignAsset;
  final bool isAnalyzing;
  final bool hasAnalyzedPayload;
  final VoidCallback onPickImage;
  final ValueChanged<String?> onFabricChanged;
  final VoidCallback onNext;

  const _StepUpload({
    required this.fabricOptions,
    required this.selectedFabric,
    required this.fabricFile,
    this.passedDesignAsset,
    required this.isAnalyzing,
    required this.hasAnalyzedPayload,
    required this.onPickImage,
    required this.onFabricChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("1. Select Fabric Material", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.espresso)),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fabricOptions.length,
                itemBuilder: (context, index) {
                  final fabric = fabricOptions[index];
                  final isSelected = selectedFabric == fabric['name'];

                  return GestureDetector(
                    onTap: () => onFabricChanged(fabric['name']),
                    child: Container(
                      width: 85,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.brick : Colors.grey.shade300,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              child: Image.asset(
                                fabric['image']!,
                                width: double.infinity,
                                errorBuilder: (context, e, s) => const Icon(Icons.tune, color: Colors.grey),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              fabric['name']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.brick : AppColors.espresso,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14.0),
              child: Divider(),
            ),
            const Text("2. Upload Pattern Design Blueprint Source", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.espresso)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onPickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.brick.withOpacity(0.4), width: 2, style: BorderStyle.solid),
                ),
                child: fabricFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.file(fabricFile!))
                    : passedDesignAsset != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.asset(passedDesignAsset!, fit: BoxFit.cover))
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 44, color: AppColors.brick),
                              SizedBox(height: 8),
                              Text("Click to upload fabric image pattern", style: TextStyle(color: AppColors.espresso, fontSize: 13)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 20),
            if ((fabricFile != null || passedDesignAsset != null) && isAnalyzing) ...[
              const Row(
                children: [
                  Spacer(),
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brick)),
                  SizedBox(width: 10),
                  Text("Analyzing your garment photo…", style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Spacer(),
                ],
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brick,
                minimumSize: const Size(double.infinity, 45),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              onPressed: ((fabricFile != null || passedDesignAsset != null) && selectedFabric != null && hasAnalyzedPayload && !isAnalyzing) ? onNext : null,
              child: Text(
                (fabricFile == null && passedDesignAsset == null)
                    ? "Upload a photo to continue"
                    : (isAnalyzing ? "Waiting for analysis…" : "Continue to Measurements"),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepMeasurements extends StatelessWidget {
  final List<Map<String, String>> fields;
  final Map<String, TextEditingController> controllers;
  final GlobalKey<FormState> formKey;
  final String detectedCategoryKey;
  final VoidCallback onGenerate;

  const _StepMeasurements({
    required this.fields,
    required this.controllers,
    required this.formKey,
    required this.detectedCategoryKey,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isLowerBody = detectedCategoryKey == 'skirt' || detectedCategoryKey == 'trousers';

    return Form(
      key: formKey,
      child: Card(
        color: Colors.white,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLowerBody ? "Lower-Body Metric Overrides Active" : "Standard Upper-Body Metrics Active",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.brick),
              ),
              const SizedBox(height: 12),
              ...fields.map((field) {
                final key = field['key']!;

                if (isLowerBody && (key == 'bust' || key == 'shoulder' || key == 'neck' || key == 'sleeve')) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    controller: controllers[key],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: field['label'],
                      hintText: field['hint'],
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brick, minimumSize: const Size(double.infinity, 45)),
                onPressed: onGenerate,
                child: const Text("Run Computational AI Generation", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBlueprint extends StatefulWidget {
  final String dressType;
  final Map<String, TextEditingController> controllers;
  final Animation<double> scaleAnim;
  final String? svgString;
  final String? selectedAariWork;
  final String machineIp;
  final String serverPort;
  final String garmentType;
  final String? fabricType;
  final ValueChanged<String?> onAariSelected;
  final VoidCallback onFitCheck;
  final VoidCallback onInstructions;

  const _StepBlueprint({
    Key? key,
    required this.dressType,
    required this.controllers,
    required this.scaleAnim,
    required this.svgString,
    required this.selectedAariWork,
    required this.machineIp,
    required this.serverPort,
    required this.garmentType,
    required this.fabricType,
    required this.onAariSelected,
    required this.onFitCheck,
    required this.onInstructions,
  }) : super(key: key);

  @override
  State<_StepBlueprint> createState() => _StepBlueprintState();
}

enum _TeacherLessonStatus { idle, requesting, processing, completed, failed, noCredits }

class _StepBlueprintState extends State<_StepBlueprint> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLessonShowing = false;

  String _selectedLanguageCode = 'ta';
  final Map<String, String> _languageLabels = {
    'ta': 'Tamil',
    'en': 'English',
    'hi': 'Hindi',
    'te': 'Telugu',
    'kn': 'Kannada',
  };

  _TeacherLessonStatus _teacherStatus = _TeacherLessonStatus.idle;
  String? _teacherErrorMessage;
  String? _activeLessonId;
  Timer? _pollTimer;

  List<Map<String, dynamic>> _lessonSteps = [];
  String? _lessonAudioBase64;
  int _currentStepIndex = -1;
  final List<Timer> _stepTimers = [];

  Map<String, dynamic> _segments = {};
  Offset _canvasOffset = const Offset(15, 45); 
  Size _canvasSize = const Size(300, 300); 

  String get _baseUrl => 'http://${widget.machineIp}:${widget.serverPort}';

  @override
  void dispose() {
    _pollTimer?.cancel();
    for (final t in _stepTimers) {
      t.cancel();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  Map<String, String> _collectMeasurements() {
    final Map<String, String> measurements = {};
    widget.controllers.forEach((key, controller) {
      final clean = controller.text.trim();
      if (clean.isNotEmpty) measurements[key] = clean;
    });
    return measurements;
  }

  Future<void> _generateTeacherLesson() async {
    _pollTimer?.cancel();
    for (final t in _stepTimers) {
      t.cancel();
    }
    _stepTimers.clear();

    setState(() {
      _teacherStatus = _TeacherLessonStatus.requesting;
      _teacherErrorMessage = null;
      _isLessonShowing = true;
      _lessonSteps = [];
      _lessonAudioBase64 = null;
      _currentStepIndex = -1;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/generate-video-lesson'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'garmentType': widget.garmentType,
          'garmentName': widget.dressType,
          'measurements': _collectMeasurements(),
          'fabricType': widget.fabricType,
          'languageCode': _selectedLanguageCode,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        setState(() {
          _teacherStatus = _TeacherLessonStatus.failed;
          _teacherErrorMessage = 'Server returned error code ${response.statusCode}.';
        });
        return;
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true || data['videoId'] == null) {
        setState(() {
          _teacherStatus = _TeacherLessonStatus.failed;
          _teacherErrorMessage = data['error']?.toString() ?? 'Could not start lesson generation.';
        });
        return;
      }

      _activeLessonId = data['videoId'];
      setState(() => _teacherStatus = _TeacherLessonStatus.processing);
      _startPolling();
    } catch (e) {
      setState(() {
        _teacherStatus = _TeacherLessonStatus.failed;
        _teacherErrorMessage = 'Network error: $e';
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activeLessonId == null) {
        timer.cancel();
        return;
      }
      try {
        final response = await http
            .get(Uri.parse('$_baseUrl/api/video-lesson-status/$_activeLessonId'))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) return; 

        final data = jsonDecode(response.body);
        final status = data['status'];

        if (status == 'completed') {
          timer.cancel();
          
          final steps = (data['steps'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ?? <Map<String, dynamic>>[];
              
          final audioB64 = data['audioBase64'] as String?;
          // segments is a Map<String, List<Map<String,num>>> — each value is a
          // list of {x,y} points, NOT a String. The previous Map<String,String>
          // cast here would throw a type error the moment real data arrived.
          final segmentsRaw = data['segments'] != null
              ? Map<String, dynamic>.from(data['segments'] as Map)
              : <String, dynamic>{};

          final offsetRaw = data['canvasOffset'] ?? data['canvas_offset'];

          setState(() {
            _lessonSteps = steps; 
            _lessonAudioBase64 = audioB64;
            _segments = segmentsRaw;
            
            if (data['canvasSize'] != null) {
              final cSize = data['canvasSize'] as Map<String, dynamic>;
              _canvasSize = Size(
                (cSize['width'] as num?)?.toDouble() ?? 300.0,
                (cSize['height'] as num?)?.toDouble() ?? 300.0,
              );
            } else {
              _canvasSize = const Size(300, 300);
            }

            if (offsetRaw != null) {
              _canvasOffset = Offset(
                (offsetRaw['x'] as num?)?.toDouble() ?? 15,
                (offsetRaw['y'] as num?)?.toDouble() ?? 45,
              );
            }
            _teacherStatus = _TeacherLessonStatus.completed;
          });

          if (audioB64 != null && audioB64.isNotEmpty) {
            await _playLessonAudio(audioB64);
          }
          _scheduleStepHighlights(steps);
        } else if (status == 'failed') {
          timer.cancel();
          final errCode = data['error']?['code']?.toString() ?? '';
          final isCreditIssue = errCode.contains('PAYMENT') || errCode.contains('CREDIT');
          setState(() {
            _teacherStatus = isCreditIssue ? _TeacherLessonStatus.noCredits : _TeacherLessonStatus.failed;
            _teacherErrorMessage = isCreditIssue
                ? 'TTS credits are exhausted right now. Please try again later.'
                : (data['error']?['message']?.toString() ?? data['error']?.toString() ?? 'Lesson generation failed.');
          });
        }
      } catch (e) {
        debugPrint("Teacher lesson poll error (will retry): $e");
      }
    });
  }

  Future<void> _playLessonAudio(String base64Audio) async {
    try {
      final bytes = base64Decode(base64Audio);
      await _audioPlayer.play(BytesSource(bytes));
    } catch (e) {
      debugPrint("Audio playback failed: $e");
      setState(() {
        _teacherStatus = _TeacherLessonStatus.failed;
        _teacherErrorMessage = 'Audio playback failed: $e';
      });
    }
  }

  void _scheduleStepHighlights(List<Map<String, dynamic>> steps) {
    for (final t in _stepTimers) {
      t.cancel();
    }
    _stepTimers.clear();
    setState(() => _currentStepIndex = steps.isEmpty ? -1 : 0);

    for (var i = 0; i < steps.length; i++) {
      final startSec = (steps[i]['startSec'] as num?)?.toDouble() ?? 0.0;
      final timer = Timer(Duration(milliseconds: (startSec * 1000).round()), () {
        if (mounted) setState(() => _currentStepIndex = i);
      });
      _stepTimers.add(timer);
    }
  }

  void _closeTeacherLesson() {
    _pollTimer?.cancel();
    for (final t in _stepTimers) {
      t.cancel();
    }
    _audioPlayer.stop();
    setState(() {
      _isLessonShowing = false;
      _currentStepIndex = -1;
    });
  }

  Widget _buildTeacherPanel() {
    switch (_teacherStatus) {
      case _TeacherLessonStatus.requesting:
        return _statusBox(
          icon: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brick)),
          text: "Preparing your lesson script…",
        );
      case _TeacherLessonStatus.processing:
        return _statusBox(
          icon: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brick)),
          text: "AI teacher is preparing narration… this takes a few seconds.",
        );
      case _TeacherLessonStatus.noCredits:
        return _statusBox(
          icon: const Icon(Icons.error_outline, color: Colors.orange, size: 20),
          text: _teacherErrorMessage ?? "TTS credits are exhausted right now. Please try again later.",
          color: Colors.orange.shade50,
          textColor: Colors.orange.shade900,
        );
      case _TeacherLessonStatus.failed:
        return _statusBox(
          icon: const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          text: _teacherErrorMessage ?? "Something went wrong generating the lesson.",
          color: Colors.red.shade50,
          textColor: Colors.red.shade900,
        );
      case _TeacherLessonStatus.completed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedStage(),
            const SizedBox(height: 14),
            _buildStepList(),
          ],
        );
      case _TeacherLessonStatus.idle:
        return const SizedBox.shrink();
    }
  }

 Widget _buildAnimatedStage() {
  print("DEBUG - Server Segments Data: $_segments");
    final currentStep = (_currentStepIndex >= 0 && _currentStepIndex < _lessonSteps.length) ? _lessonSteps[_currentStepIndex] : null;

    final segmentName = (currentStep?['segment'] ?? '').toString();
    final action = (currentStep?['action'] ?? 'cut').toString(); 
    final highlightForGlow = action == 'cut' ? 'outline' : action; 

    List<dynamic>? rawSegment = _segments[segmentName] as List<dynamic>?;

    if (rawSegment == null && segmentName.isNotEmpty) {
      final cleanName = segmentName.toLowerCase().trim();
      
      if (cleanName.contains('neck') || cleanName.contains('shoulder')) {
        rawSegment = (_segments['neckline'] ?? _segments['shoulder'] ?? _segments['front_outline'] ?? _segments['back_outline']) as List<dynamic>?;
      } else if (cleanName.contains('armhole') || cleanName.contains('sleeve')) {
        rawSegment = (_segments['armhole_curve'] ?? _segments['sleeve_seam'] ?? _segments['front_sleeve'] ?? _segments['back_sleeve']) as List<dynamic>?;
      } else if (cleanName.contains('waist') || cleanName.contains('bodice') || cleanName.contains('side')) {
        rawSegment = (_segments['front_waist_dart'] ?? _segments['waistline_join'] ?? _segments['underbust_line'] ?? _segments['side_seam'] ?? _segments['bodice_seam'] ?? _segments['hip_curve']) as List<dynamic>?;
      } else if (cleanName.contains('hem') || cleanName.contains('bottom')) {
        rawSegment = (_segments['skirt_hem_curve'] ?? _segments['hemline_curve'] ?? _segments['hemline']) as List<dynamic>?;
      } else if (cleanName.contains('crotch') || cleanName.contains('leg')) {
        rawSegment = (_segments['crotch_seam'] ?? _segments['inner_leg_seam']) as List<dynamic>?;
      }
      
      if (rawSegment == null) {
        final matchingKey = _segments.keys.firstWhere(
          (k) => k.toLowerCase().contains(cleanName) || cleanName.contains(k.toLowerCase()),
          orElse: () => '',
        );
        if (matchingKey.isNotEmpty) {
          rawSegment = _segments[matchingKey] as List<dynamic>?;
        }
      }
    }

    if ((rawSegment == null || rawSegment.isEmpty) && _segments.isNotEmpty) {
      rawSegment = _segments.values.first as List<dynamic>?;
    }

    // 🌟 1. மாப்பிங் பாயிண்ட்ஸ்களை எடுக்கிறோம்
    List<Offset> pathPoints = (rawSegment ?? [])
        .map((p) => Offset(
              ((p['x'] as num?)?.toDouble() ?? 0) + _canvasOffset.dx,
              ((p['y'] as num?)?.toDouble() ?? 0) + _canvasOffset.dy,
            ))
        .toList();

    // 🚨 2. சர்வர்ல இருந்து டேட்டாவே வரலைனாலும் அனிமேஷன் நிக்காமல் ஓட டம்மி பாத் செட் பண்றோம்!
    if (pathPoints.isEmpty) {
      pathPoints = [
        Offset(20 + _canvasOffset.dx, 40 + _canvasOffset.dy),
        Offset(120 + _canvasOffset.dx, 40 + _canvasOffset.dy),
        Offset(140 + _canvasOffset.dx, 120 + _canvasOffset.dy),
        Offset(40 + _canvasOffset.dx, 140 + _canvasOffset.dy),
      ];
    }

    final hasSvg = widget.svgString != null && widget.svgString!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: hasSvg
                ? BlueprintGlowOverlay(
                    svgString: widget.svgString!,
                    currentHighlight: highlightForGlow,
                    height: 180,
                  )
                : const SizedBox(
                    height: 180,
                    child: Center(child: Text("No blueprint to animate.", style: TextStyle(color: AppColors.textMuted))),
                  ),
          ),
          Container(width: 1, height: 160, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 8)),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // இப்போ கண்டிப்பா pathPoints காலியா இருக்காது, சோ மெஷின் தையல் போடும்!
                RealisticSewingScene(
                  key: UniqueKey(), 
                  pathPoints: pathPoints,
                  action: action,
                  canvasSize: _canvasSize == Size.zero ? const Size(300, 300) : _canvasSize, 
                  width: 200,
                  height: 170,
                ),
                const SizedBox(height: 6),
                Text(
                  _actionLabel(action, segmentName.isNotEmpty ? segmentName : "Processing Line"),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brick),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  String _actionLabel(String action, String segmentName) {
    final readable = segmentName.replaceAll('_', ' ');
    switch (action) {
      case 'pin':
        return 'Pinning: $readable';
      case 'stitch':
        return 'Stitching: $readable';
      case 'cut':
      default:
        return 'Cutting: $readable';
    }
  }

  Widget _buildStepList() {
    if (_lessonSteps.isEmpty) {
      return const Center(child: Text("No lesson steps were returned.", style: TextStyle(color: AppColors.textMuted)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.graphic_eq, color: AppColors.brick, size: 18),
            SizedBox(width: 8),
            Text("AI Teacher Narration", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brick)),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(_lessonSteps.length, (i) {
          final step = _lessonSteps[i];
          final isActive = i == _currentStepIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.brick.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isActive ? AppColors.brick : Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isActive ? Icons.play_circle_fill : Icons.circle_outlined,
                  size: 18,
                  color: isActive ? AppColors.brick : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (step['title'] ?? '').toString(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isActive ? AppColors.brick : Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (step['narration'] ?? '').toString(),
                        style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _statusBox({required Widget icon, required String text, Color? color, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? AppColors.blushLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, color: textColor ?? AppColors.espresso, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget.scaleAnim,
      child: Column(
        children: [
          Card(
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CAD Blueprint Matrix Profile: ${widget.dressType}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E1A11)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFFFFFDF9), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(8),
                    child: widget.svgString != null && widget.svgString!.isNotEmpty
                        ? SvgPicture.string(widget.svgString!, placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()))
                        : const Center(child: Text("Missing valid vector dataset context mappings.")),
                  ),
                  if (_isLessonShowing) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider()),
                    _buildTeacherPanel(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_teacherStatus == _TeacherLessonStatus.idle ||
              _teacherStatus == _TeacherLessonStatus.failed ||
              _teacherStatus == _TeacherLessonStatus.noCredits) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguageCode,
                  isExpanded: true,
                  icon: const Icon(Icons.language, color: AppColors.brick),
                  items: _languageLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text("AI Teacher Language: ${e.value}"))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLanguageCode = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  icon: Icon(
                    _isLessonShowing
                        ? Icons.close
                        : (_teacherStatus == _TeacherLessonStatus.failed || _teacherStatus == _TeacherLessonStatus.noCredits)
                            ? Icons.refresh
                            : Icons.smart_display_outlined,
                    color: Colors.redAccent,
                  ),
                  label: Text(
                    _isLessonShowing
                        ? "Close"
                        : (_teacherStatus == _TeacherLessonStatus.failed || _teacherStatus == _TeacherLessonStatus.noCredits)
                            ? "Try Again"
                            : "AI Teacher Lesson",
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    if (_isLessonShowing &&
                        _teacherStatus != _TeacherLessonStatus.failed &&
                        _teacherStatus != _TeacherLessonStatus.noCredits) {
                      _closeTeacherLesson();
                    } else {
                      _generateTeacherLesson();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: widget.onFitCheck,
                  icon: const Icon(Icons.layers_outlined, color: Colors.white),
                  label: const Text("AR Fit Layer", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepFitCheck extends StatefulWidget {
  final String dressType;
  final String? selectedAariWork;
  final File? fullPhotoFile;
  final VoidCallback onPickFullPhoto;
  final ValueChanged<String?> onAariSelected;

  const _StepFitCheck({
    Key? key,
    required this.dressType,
    required this.selectedAariWork,
    required this.fullPhotoFile,
    required this.onPickFullPhoto,
    required this.onAariSelected,
  }) : super(key: key);

  @override
  State<_StepFitCheck> createState() => _StepFitCheckState();
}

class _StepFitCheckState extends State<_StepFitCheck> {
  File? personImage;
  File? dressImage;
  bool showResult = false;
  bool _isGenerating = false;
  String? _resultImageUrl; // FIX: server's actual result was never stored before
  String? _errorMessage;
  String _clothType = 'upper'; // NEW: CatVTON needs this — upper | lower | overall
  final ImagePicker picker = ImagePicker();

  // FIX: reuse the same machineIp/serverPort as the rest of the screen,
  // instead of a second hardcoded IP that can silently drift out of sync.
  static const String _baseUrl = 'http://${BlueprintScreen.machineIp}:${BlueprintScreen.serverPort}';

  Future<void> pickImage(bool isPerson) async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        if (isPerson) {
          personImage = File(file.path);
        } else {
          dressImage = File(file.path);
        }
        // Clear any stale result when a new photo is chosen.
        showResult = false;
        _resultImageUrl = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> generateFit() async {
    if (personImage == null || dressImage == null) {
      setState(() => _errorMessage = "Please upload both your photo and the dress photo first.");
      return;
    }

    setState(() {
      showResult = false;
      _errorMessage = null;
    });

    try {
      final personBytes = await personImage!.readAsBytes();
      final dressBytes = await dressImage!.readAsBytes();

      final personBase64 = base64Encode(personBytes);
      final dressBase64 = base64Encode(dressBytes);

      // NOTE: this now calls your self-hosted CatVTON Colab session
      // (see CatVTON_FreeColab.ipynb) instead of a rate-limited public
      // Space — no daily quota, but the Colab notebook must be running.
      // A cold Colab session can still take 20-40s for the first request
      // while the model warms up, so the generous timeout below stays.
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ar-fit-layer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userPhotoBase64': personBase64,
          'garmentPatternBase64': dressBase64,
          'clothType': _clothType,
        }),
      ).timeout(const Duration(seconds: 75));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true && data['resultImageUrl'] != null) {
        // FIX: previously the response body was never read at all, so
        // there was nothing to show even on success.
        setState(() {
          _resultImageUrl = data['resultImageUrl'];
          showResult = true;
        });
      } else {
        setState(() {
          _errorMessage = data['error']?.toString() ?? 'Try-on generation failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('TimeoutException')
            ? 'Your Colab session is taking longer than usual — check it\'s still running.'
            : 'AR Fit generation failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "AR Virtual Try-On",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Free unlimited try-on via your own Colab GPU session.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),

            // NEW: cloth type selector — CatVTON needs this to know where
            // to apply the garment (upper body, lower body, or full outfit).
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _ClothTypeChip(label: 'Upper', value: 'upper', selected: _clothType, onTap: (v) => setState(() => _clothType = v)),
                _ClothTypeChip(label: 'Lower', value: 'lower', selected: _clothType, onTap: (v) => setState(() => _clothType = v)),
                _ClothTypeChip(label: 'Overall', value: 'overall', selected: _clothType, onTap: (v) => setState(() => _clothType = v)),
              ],
            ),

            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => pickImage(true),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.grey),
                ),
                child: personImage == null ? const Center(child: Text("Upload Person Image")) : Image.file(personImage!),
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => pickImage(false),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.grey),
                ),
                child: dressImage == null ? const Center(child: Text("Upload Dress Image")) : Image.file(dressImage!),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isGenerating ? Colors.grey : AppColors.brick,
              ),
              onPressed: _isGenerating
                  ? null
                  : () async {
                      setState(() => _isGenerating = true);
                      await generateFit();
                      setState(() => _isGenerating = false);
                    },
              child: _isGenerating
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text("Generating\u2026", style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text("Generate", style: TextStyle(color: Colors.white)),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 12.5, color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // FIX: this used to always show a hardcoded local asset
            // (assets/images/result.jpeg) regardless of what the server
            // returned. Now it shows the REAL generated try-on image.
            if (showResult && _resultImageUrl != null)
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
                child: Image.network(
                  _resultImageUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: AppColors.brick));
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text("Result image could not be loaded.", style: TextStyle(color: AppColors.textMuted)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClothTypeChip extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  const _ClothTypeChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brick : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}