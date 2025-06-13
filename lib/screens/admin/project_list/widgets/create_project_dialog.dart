import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';

class CreateProjectDialog extends StatefulWidget {
  final Function(CalibrationProject) onProjectCreated;

  const CreateProjectDialog({super.key, required this.onProjectCreated});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  String? _audioPath;
  String? _mainTextPath;
  String? _translationTextPath;
  String _parsingMode = 'interleaved';
  late AnimationController _animationController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _titleController.text.isNotEmpty;
      case 1:
        return _audioPath != null;
      case 2:
        return _mainTextPath != null &&
            (_parsingMode == 'separate' ||
                _translationTextPath != null ||
                _parsingMode == 'interleaved');
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStepIndicator(),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
              const SizedBox(height: 32),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Widget builder methods remain here as they are tightly coupled to this dialog's state)
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6C63FF),
                Color(0xFF8B80F8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'ایجاد پروژه جدید',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return Expanded(
          child: Row(
            children: [
              if (index > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? const Color(0xFF6C63FF)
                        : Colors.grey[300],
                  ),
                ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive || isCompleted
                      ? const Color(0xFF6C63FF)
                      : Colors.grey[300],
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (index < 2)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? const Color(0xFF6C63FF)
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildAudioStep();
      case 2:
        return _buildTextStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNameStep() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نام پروژه را وارد کنید',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'مثال: دعای کمیل - قرائت استاد فلانی',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6C63FF),
                width: 2,
              ),
            ),
            prefixIcon: const Icon(Icons.edit_rounded),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildAudioStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'فایل صوتی را انتخاب کنید',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _selectAudioFile,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _audioPath != null
                  ? const Color(0xFF6C63FF).withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _audioPath != null
                    ? const Color(0xFF6C63FF)
                    : Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _audioPath != null
                      ? Icons.check_circle_rounded
                      : Icons.cloud_upload_rounded,
                  size: 48,
                  color: _audioPath != null
                      ? const Color(0xFF6C63FF)
                      : Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  _audioPath != null
                      ? _getFileName(_audioPath!)
                      : 'برای انتخاب کلیک کنید',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _audioPath != null
                        ? const Color(0xFF6C63FF)
                        : Colors.grey[600],
                  ),
                ),
                if (_audioPath != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'برای تغییر دوباره کلیک کنید',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextStep() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نحوه ورود متن را انتخاب کنید',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildParsingModeSelector(),
        const SizedBox(height: 24),
        if (_parsingMode == 'interleaved')
          _buildInterleavedFileSelector()
        else
          _buildSeparateFileSelectors(),
      ],
    );
  }

  Widget _buildParsingModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _ModeOption(
            title: 'ترکیبی',
            subtitle: 'عربی و ترجمه در یک فایل',
            icon: Icons.merge_type_rounded,
            isSelected: _parsingMode == 'interleaved',
            onTap: () => setState(() => _parsingMode = 'interleaved'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeOption(
            title: 'مجزا',
            subtitle: 'دو فایل جداگانه',
            icon: Icons.call_split_rounded,
            isSelected: _parsingMode == 'separate',
            onTap: () => setState(() => _parsingMode = 'separate'),
          ),
        ),
      ],
    );
  }

  Widget _buildInterleavedFileSelector() {
    return _FileSelector(
      title: 'فایل متن ترکیبی',
      hint: 'فایل حاوی عربی و ترجمه',
      path: _mainTextPath,
      onTap: _selectMainTextFile,
      icon: Icons.description_rounded,
      color: Colors.blue,
    );
  }

  Widget _buildSeparateFileSelectors() {
    return Column(
      children: [
        _FileSelector(
          title: 'فایل متن عربی',
          hint: 'فقط متن عربی',
          path: _mainTextPath,
          onTap: _selectMainTextFile,
          icon: Icons.text_fields_rounded,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _FileSelector(
          title: 'فایل ترجمه (اختیاری)',
          hint: 'متن ترجمه فارسی',
          path: _translationTextPath,
          onTap: _selectTranslationTextFile,
          icon: Icons.translate_rounded,
          color: Colors.orange,
          isOptional: true,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: _currentStep > 0
              ? () => setState(() => _currentStep--)
              : () => Navigator.pop(context),
          child: Text(_currentStep > 0 ? 'قبلی' : 'انصراف'),
        ),
        Row(
          children: [
            if (_currentStep < 2)
              ElevatedButton(
                onPressed:
                    _canProceed ? () => setState(() => _currentStep++) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  children: [
                    Text('بعدی'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: _canProceed ? _createProject : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('ایجاد پروژه'),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        _audioPath = result.files.single.path;
      });
    }
  }

  Future<void> _selectMainTextFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result != null) {
      setState(() {
        _mainTextPath = result.files.single.path;
      });
    }
  }

  Future<void> _selectTranslationTextFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result != null) {
      setState(() {
        _translationTextPath = result.files.single.path;
      });
    }
  }

  void _createProject() {
    final newProject = CalibrationProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      audioPath: _audioPath!,
      textParsingMode: _parsingMode,
      mainTextPath: _mainTextPath!,
      translationTextPath: _translationTextPath,
    );

    widget.onProjectCreated(newProject);
    Navigator.pop(context);

    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('پروژه "${newProject.title}" با موفقیت ایجاد شد'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getFileName(String path) {
    return path.split('/').last.split('\\').last;
  }
}

class _ModeOption extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C63FF).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FileSelector extends StatelessWidget {
  final String title, hint;
  final String? path;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final bool isOptional;

  const _FileSelector({
    required this.title,
    required this.hint,
    required this.path,
    required this.onTap,
    required this.icon,
    required this.color,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: path != null ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: path != null ? color : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: path != null ? color : Colors.grey[400],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isOptional) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'اختیاری',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    path != null ? _getFileName(path!) : hint,
                    style: TextStyle(
                      fontSize: 12,
                      color: path != null ? color : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              path != null
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: path != null ? color : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  String _getFileName(String path) {
    return path.split('/').last.split('\\').last;
  }
}
