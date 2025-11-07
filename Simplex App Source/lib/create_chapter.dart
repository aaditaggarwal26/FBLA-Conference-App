import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class CreateChapterPage extends StatefulWidget {
  const CreateChapterPage({super.key});

  @override
  _CreateChapterPageState createState() => _CreateChapterPageState();
}

class _CreateChapterPageState extends State<CreateChapterPage> {
  final _formKey = GlobalKey<FormState>();
  String _chapterName = '';
  bool _parentApproval = false;
  String _joinCode = '';
  final Map<String, bool> _selectedWidgets = {
    'calendar': false,
    'tasks': false,
    'rubric': false,
    'opportunities': false,
    'packets': false,
    'quickLinks': false,
    'eventRegistration': false,
  };

  @override
  void initState() {
    super.initState();
    _generateJoinCode();
  }

  void _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    String code = '';
    for (var i = 0; i < 6; i++) {
      code += chars[rnd.nextInt(chars.length)];
    }
    setState(() {
      _joinCode = code;
    });
  }

  Future<void> _createChapter() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        DocumentReference chapter =
            await FirebaseFirestore.instance.collection('chapters').add({
          'name': _chapterName,
          'parentApproval': _parentApproval,
          'joinCode': _joinCode,
          'widgets': _selectedWidgets,
          'users': []
        });

        chapter.collection("events").add({});
        chapter.collection("tasks").add({});
        chapter.collection("packets").add({});

        await FirebaseFirestore.instance
            .collection('codes')
            .doc('codes')
            .update({'codes.' + _joinCode: chapter.id});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chapter created successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating chapter: $e')),
        );
      }
    }
  }

  Widget _buildWidgetCheckbox(String title, String key) {
    return CheckboxListTile(
      title: Text(title),
      value: _selectedWidgets[key],
      onChanged: (bool? value) {
        setState(() {
          _selectedWidgets[key] = value!;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Chapter')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Chapter Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a chapter name';
                }
                return null;
              },
              onSaved: (value) => _chapterName = value!,
            ),
            SwitchListTile(
              title: const Text('Parent Approval'),
              value: _parentApproval,
              onChanged: (value) => setState(() => _parentApproval = value),
            ),
            ListTile(
              title: const Text('Join Code'),
              subtitle: Text(_joinCode),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _generateJoinCode,
              ),
            ),
            const Divider(),
            const Text('Optional Widgets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildWidgetCheckbox('Calendar', 'calendar'),
            _buildWidgetCheckbox('Tasks', 'tasks'),
            _buildWidgetCheckbox('Rubric', 'rubric'),
            _buildWidgetCheckbox('Opportunities', 'opportunities'),
            _buildWidgetCheckbox('Packets', 'packets'),
            _buildWidgetCheckbox('Quick Links', 'quickLinks'),
            _buildWidgetCheckbox('Event Registration', 'eventRegistration'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createChapter,
              child: const Text('Create Chapter'),
            ),
          ],
        ),
      ),
    );
  }
}
