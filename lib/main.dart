import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notes Lab 7',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const NotesHomePage(),
    );
  }
}

class Note {
  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  final int id;
  String title;
  String description;
  DateTime date;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  static const String notesKey = 'saved_notes';

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final List<Note> notes = <Note>[];

  int nextId = 1;
  int? editingNoteId;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadNotes() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? savedNotes = preferences.getString(notesKey);

    if (savedNotes == null) {
      return;
    }

    final List<dynamic> decodedNotes = jsonDecode(savedNotes) as List<dynamic>;
    notes
      ..clear()
      ..addAll(
        decodedNotes.map(
          (dynamic item) => Note.fromJson(item as Map<String, dynamic>),
        ),
      );

    if (notes.isNotEmpty) {
      nextId = notes
              .map((Note note) => note.id)
              .reduce((int a, int b) => a > b ? a : b) +
          1;
    }

    setState(() {});
  }

  Future<void> saveNotes() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String encodedNotes = jsonEncode(
      notes.map((Note note) => note.toJson()).toList(),
    );
    await preferences.setString(notesKey, encodedNotes);
  }

  Future<void> addOrUpdateNote() async {
    final String title = titleController.text.trim();
    final String description = descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and description.')),
      );
      return;
    }

    setState(() {
      if (editingNoteId == null) {
        notes.add(
          Note(
            id: nextId,
            title: title,
            description: description,
            date: DateTime.now(),
          ),
        );
        nextId++;
      } else {
        final Note note = notes.firstWhere(
          (Note item) => item.id == editingNoteId,
        );
        note.title = title;
        note.description = description;
      }

      clearInputFields();
    });

    await saveNotes();
  }

  void startEditing(Note note) {
    setState(() {
      editingNoteId = note.id;
      titleController.text = note.title;
      descriptionController.text = note.description;
    });
  }

  Future<void> deleteNote(Note note) async {
    setState(() {
      notes.removeWhere((Note item) => item.id == note.id);
      if (editingNoteId == note.id) {
        clearInputFields();
      }
    });

    await saveNotes();
  }

  void clearInputFields() {
    titleController.clear();
    descriptionController.clear();
    editingNoteId = null;
  }

  String formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = editingNoteId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Lab 7'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: addOrUpdateNote,
                    icon: Icon(isEditing ? Icons.save : Icons.add),
                    label: Text(isEditing ? 'UPDATE NOTE' : 'ADD NOTE'),
                  ),
                ),
                if (isEditing) ...<Widget>[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(clearInputFields);
                    },
                    child: const Text('CANCEL'),
                  ),
                ],
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: notes.isEmpty
                  ? const Center(child: Text('No notes yet.'))
                  : ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Note note = notes[index];
                        return Card(
                          child: ListTile(
                            title: Text('ID: ${note.id} - ${note.title}'),
                            subtitle: Text(
                              'Description: ${note.description}\nDate: ${formatDate(note.date)}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  tooltip: 'Edit note',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => startEditing(note),
                                ),
                                IconButton(
                                  tooltip: 'Delete note',
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => deleteNote(note),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
