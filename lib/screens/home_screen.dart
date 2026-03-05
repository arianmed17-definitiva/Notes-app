import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secure_notes/models/note.dart';
import 'package:secure_notes/services/crypto_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// we no longer keep a local list; Firestore stream is authoritative

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Notas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNote(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('notes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No tienes notas aún. ¡Agrega una!',
                  style: TextStyle(fontSize: 18)),
            );
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final note = Note.fromMap(data);
              return ListTile(
                title: Text(note.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.reminder != null)
                      Text('Recordatorio: ${note.reminder}',
                          style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 4),
                    Text('Contenido: ${note.decryptedContent}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // delete from firestore
                    _firestore
                        .collection('notes')
                        .doc(docs[index].id)
                        .delete();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  void _addNote(BuildContext context) async{

  final titleController = TextEditingController();
  final contentController = TextEditingController();
  DateTime? reminder;

  await showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text('Nueva Nota'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Contenido'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    initialDate: DateTime.now(),
                  );

                  if (date == null) return;

                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (time == null) return;

                  reminder = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                },
                child: const Text('Agregar recordatorio'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;

              final encrypted = CryptoService().encrypt(contentController.text);
              final note = Note(
                id: DateTime.now().toString(),
                title: titleController.text,
                content: encrypted,
                reminder: reminder,
              );

              await _firestore.collection('notes').add(note.toMap());
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
          ],
        );
      },
    );
    }
  }
