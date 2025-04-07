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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.02),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Add New Book',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.03),
                  _buildTextField(
                    controller: titleController,
                    label: 'Book Title',
                    icon: Icons.book_outlined,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter the title'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: authorController,
                    label: 'Author Name',
                    icon: Icons.person_outline,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter the author'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: Icon(Icons.category_outlined,
                            color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
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
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: descriptionController,
                    label: 'Description (Optional)',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _buildFilePickerButton(
                    onPressed: pickCoverImage,
                    icon: Icons.image_outlined,
                    label: 'Cover Image',
                    fileName: coverImageName,
                  ),
                  const SizedBox(height: 16),
                  _buildFilePickerButton(
                    onPressed: pickPdfFile,
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF File',
                    fileName: pdfFileName,
                  ),
                  SizedBox(height: size.height * 0.04),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleAddBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Add Book',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines ?? 1,
        style: const TextStyle(fontSize: 16),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilePickerButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    String? fileName,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (fileName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          fileName,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
