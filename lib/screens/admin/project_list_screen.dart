import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';
import 'package:komeyl_app/screens/admin/calibration_screen.dart';
import 'package:path_provider/path_provider.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen>
    with TickerProviderStateMixin {
  List<CalibrationProject> _projects = [];
  bool _isLoading = true;
  late AnimationController _fabAnimationController;
  late AnimationController _listAnimationController;
  final _searchController = TextEditingController();
  List<CalibrationProject> _filteredProjects = [];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadProjects();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _listAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/calibration_projects.json');
  }

  Future<void> _loadProjects() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        setState(() {
          _projects = [];
          _filteredProjects = [];
          _isLoading = false;
        });
        return;
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      setState(() {
        _projects =
            jsonList.map((json) => CalibrationProject.fromJson(json)).toList();
        _filteredProjects = _projects;
        _isLoading = false;
      });
      _listAnimationController.forward();
    } catch (e) {
      print('Error loading projects: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProjects() async {
    final file = await _localFile;
    final List<Map<String, dynamic>> jsonList =
        _projects.map((p) => p.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  void _filterProjects(String query) {
    setState(() {
      _filteredProjects = _projects
          .where((project) =>
              project.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _deleteProject(CalibrationProject project) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _DeleteConfirmationDialog(projectTitle: project.title),
    );

    if (result == true) {
      setState(() {
        _projects.remove(project);
        _filteredProjects.remove(project);
      });
      await _saveProjects();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('پروژه "${project.title}" حذف شد'),
            action: SnackBarAction(
              label: 'بازگردانی',
              onPressed: () async {
                setState(() {
                  _projects.add(project);
                  _filterProjects(_searchController.text);
                });
                await _saveProjects();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: CustomScrollView(
          slivers: [
            _buildModernSliverAppBar(),
            if (!_isLoading) ...[
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: _buildSearchBar(),
                ),
              ),
              if (_filteredProjects.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _buildProjectGrid(),
                ),
            ] else
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
        floatingActionButton: _buildModernFAB(),
      ),
    );
  }

  Widget _buildModernSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6C63FF),
                const Color(0xFF8B80F8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.folder_special_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'پروژه‌های کالیبراسیون',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_projects.length} پروژه',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        title: const Text(
          'پروژه‌ها',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
          onPressed: () => _showInfoDialog(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterProjects,
        decoration: InputDecoration(
          hintText: 'جستجو در پروژه‌ها...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _filterProjects('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildProjectGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final project = _filteredProjects[index];
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _listAnimationController,
              curve: Interval(
                index * 0.1,
                1.0,
                curve: Curves.easeOutCubic,
              ),
            )),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _listAnimationController,
                curve: Interval(
                  index * 0.1,
                  1.0,
                  curve: Curves.easeOut,
                ),
              ),
              child: _ProjectCard(
                project: project,
                onTap: () => _navigateToCalibration(project),
                onDelete: () => _deleteProject(project),
              ),
            ),
          );
        },
        childCount: _filteredProjects.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 60,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isEmpty
                ? 'هنوز پروژه‌ای ایجاد نشده'
                : 'پروژه‌ای یافت نشد',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'برای شروع، دکمه + را بزنید'
                : 'عبارت دیگری را جستجو کنید',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAB() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
      child: FloatingActionButton.extended(
        onPressed: _showCreateProjectDialog,
        elevation: 8,
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'پروژه جدید',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _navigateToCalibration(CalibrationProject project) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CalibrationScreen(project: project),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(width: 12),
            const Text('راهنما'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• برای ایجاد پروژه جدید، دکمه + را بزنید'),
            SizedBox(height: 8),
            Text('• برای ویرایش، روی کارت پروژه کلیک کنید'),
            SizedBox(height: 8),
            Text('• برای حذف، دکمه سطل زباله را فشار دهید'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateProjectDialog() async {
    HapticFeedback.mediumImpact();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreateProjectDialog(
        onProjectCreated: (project) async {
          setState(() {
            _projects.add(project);
            _filterProjects(_searchController.text);
          });
          await _saveProjects();
        },
      ),
    );
  }
}

// Project Card Widget
class _ProjectCard extends StatefulWidget {
  final CalibrationProject project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.1 : 0.05),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6C63FF),
                              const Color(0xFF8B80F8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red[400],
                        ),
                        onPressed: widget.onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.project.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.audiotrack_rounded,
                        _getFileName(widget.project.audioPath),
                        Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.text_fields_rounded,
                        widget.project.textParsingMode == 'interleaved'
                            ? 'ترکیبی'
                            : 'مجزا',
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getFileName(String path) {
    final name = path.split('/').last.split('\\').last;
    return name.length > 10 ? '${name.substring(0, 10)}...' : name;
  }
}

// Create Project Dialog
class _CreateProjectDialog extends StatefulWidget {
  final Function(CalibrationProject) onProjectCreated;

  const _CreateProjectDialog({required this.onProjectCreated});

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog>
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
            (_parsingMode == 'interleaved' || _translationTextPath != null);
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF),
                const Color(0xFF8B80F8),
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

// Mode Option Widget
class _ModeOption extends StatelessWidget {
  final String title;
  final String subtitle;
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

// File Selector Widget
class _FileSelector extends StatelessWidget {
  final String title;
  final String hint;
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

// Delete Confirmation Dialog
class _DeleteConfirmationDialog extends StatelessWidget {
  final String projectTitle;

  const _DeleteConfirmationDialog({required this.projectTitle});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(width: 12),
          const Text('حذف پروژه'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'آیا از حذف پروژه "$projectTitle" اطمینان دارید؟',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'این عمل قابل بازگشت است',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_rounded, size: 18),
              SizedBox(width: 8),
              Text('حذف'),
            ],
          ),
        ),
      ],
    );
  }
}
