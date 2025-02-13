import 'dart:io';
import 'sql_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _items = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  File? _image;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  void _refreshItems() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _items = data;
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showForm(int? id) async {
    if (id != null) {
      final existingItem = _items.firstWhere((element) => element['id'] == id);
      _titleController.text = existingItem['title'];
      _descriptionController.text = existingItem['description'];
      _noteController.text = existingItem['note'];
      _image =
          existingItem['image'] != null ? File(existingItem['image']) : null;
    }

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
              const SizedBox(height: 10),
              _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          Image.file(_image!, height: 120, fit: BoxFit.cover),
                    )
                  : const Text("No Image Selected"),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text("Pick Image"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (id == null) {
                    await SQLHelper.createItem(
                        _titleController.text,
                        _descriptionController.text,
                        _noteController.text,
                        _image?.path);
                  } else {
                    await SQLHelper.updateItem(
                        id,
                        _titleController.text,
                        _descriptionController.text,
                        _noteController.text,
                        _image?.path);
                  }
                  _titleController.clear();
                  _descriptionController.clear();
                  _noteController.clear();
                  _image = null;

                  if (!mounted) return;
                  Navigator.of(context).pop();
                  _refreshItems();
                },
                child: Text(id == null ? 'Add Item' : 'Update Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    _refreshItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('SQL Lite')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.all(8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  title: Text(
                    _items[index]['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_items[index]['description']),
                      Text(
                        _items[index]['note'],
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      if (_items[index]['image'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_items[index]['image']),
                              height: 120, fit: BoxFit.cover),
                        )
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _showForm(_items[index]['id'])),
                      IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteItem(_items[index]['id'])),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
