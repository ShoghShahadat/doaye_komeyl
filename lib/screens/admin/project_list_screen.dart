import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';
import 'package:komeyl_app/screens/admin/calibration_screen.dart';
import 'package:path_provider/path_provider.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<CalibrationProject> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
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
        });
        return;
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      setState(() {
        _projects =
            jsonList.map((json) => CalibrationProject.fromJson(json)).toList();
      });
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  Future<void> _saveProjects() async {
    final file = await _localFile;
    final List<Map<String, dynamic>> jsonList =
        _projects.map((p) => p.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  Future<void> _showCreateProjectDialog() async {
    final titleController = TextEditingController();
    String? audioPath;
    String? textPath;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ساخت پروژه جدید'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'نام پروژه'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.audiotrack),
                label: const Text('انتخاب فایل صوتی'),
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(type: FileType.audio);
                  if (result != null) {
                    audioPath = result.files.single.path;
                  }
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.text_fields),
                label: const Text('انتخاب فایل متنی (.txt)'),
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['txt'],
                  );
                  if (result != null) {
                    textPath = result.files.single.path;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('لغو')),
            TextButton(
              child: const Text('ساختن'),
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    audioPath != null &&
                    textPath != null) {
                  final newProject = CalibrationProject(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    audioPath: audioPath!,
                    textPath: textPath!,
                  );
                  setState(() {
                    _projects.add(newProject);
                  });
                  _saveProjects();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پروژه‌های کالیبراسیون'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _projects.isEmpty
          ? const Center(
              child:
                  Text('هیچ پروژه‌ای وجود ندارد. برای ساخت، دکمه + را بزنید.'))
          : ListView.builder(
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final project = _projects[index];
                return ListTile(
                  title: Text(project.title),
                  leading: const Icon(Icons.edit_document),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            CalibrationScreen(project: project),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProjectDialog,
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
