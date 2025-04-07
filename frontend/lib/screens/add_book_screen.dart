import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../providers/book_provider.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  AddBookScreenState createState() => AddBookScreenState();
}

class AddBookScreenState extends State<AddBookScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  File? coverImage;
  File? pdfFile;
  String? coverImageName;
  String? pdfFileName;
  String? selectedCategory;

  List<Map<String, String>> categories = [
    {'id': '1', 'name': 'Fiction'},
    {'id': '2', 'name': 'Non-Fiction'},
    {'id': '3', 'name': 'Science'},
    {'id': '4', 'name': 'Technology'},
    {'id': '5', 'name': 'History'},
    {'id': '6', 'name': 'Biography'},
  ];

  Future<void> pickCoverImage() async {
    final status = await Permission.storage.request();
    if (!mounted) return;
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Storage permission is required to pick images')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    await showModalBottomSheet<XFile>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (!mounted) return;
                  if (image != null) {
                    setState(() {
                      coverImage = File(image.path);
                      coverImageName = image.name;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (!mounted) return;
                  if (image != null) {
                    setState(() {
                      coverImage = File(image.path);
                      coverImageName = image.name;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> pickPdfFile() async {
    final status = await Permission.storage.request();
    if (!mounted) return;
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Storage permission is required to pick PDF files')),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (!mounted) return;

      if (result != null) {
        setState(() {
          pdfFile = File(result.files.single.path!);
          pdfFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking PDF file: $e')),
      );
    }
  }

  void handleAddBook() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      setState(() => isLoading = true);

      try {
        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        final categoryId = int.parse(selectedCategory!);

        await bookProvider.addBook(
          title: titleController.text,
          author: authorController.text,
          categoryId: categoryId,
          description: descriptionController.text.isEmpty
              ? null
              : descriptionController.text,
          coverImage: coverImage,
          pdfFile: pdfFile,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book added successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Book'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter the title'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter the author'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'],
                    child: Text(category['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: pickCoverImage,
                icon: const Icon(Icons.image),
                label: Text(coverImageName ?? 'Pick Cover Image'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: pickPdfFile,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(pdfFileName ?? 'Pick PDF File'),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleAddBook,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
