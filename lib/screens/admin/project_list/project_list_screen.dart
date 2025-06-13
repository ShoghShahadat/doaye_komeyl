import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';
import 'package:komeyl_app/screens/admin/calibration/calibration_screen.dart';
import 'package:path_provider/path_provider.dart';

import 'widgets/create_project_dialog.dart';
import 'widgets/delete_confirmation_dialog.dart';
import 'widgets/project_card.dart';

part 'project_list_ui.dart';

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
    setState(() => _isLoading = true);
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
      _listAnimationController.forward(from: 0);
    } catch (e) {
      debugPrint('Error loading projects: $e');
      setState(() => _isLoading = false);
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
          DeleteConfirmationDialog(projectTitle: project.title),
    );

    if (result == true) {
      final index = _projects.indexOf(project);
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
                  _projects.insert(index, project);
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

  void _navigateToCalibration(CalibrationProject project) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => CalibrationScreen(project: project),
          ),
        )
        .then((_) => _loadProjects()); // Refresh list when returning
  }

  Future<void> _showCreateProjectDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateProjectDialog(
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
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
}
