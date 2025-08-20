import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../services/db.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameC = TextEditingController();
  final _catC = TextEditingController();
  final _priceC = TextEditingController(text: '0');
  final _stockC = TextEditingController(text: '0');
  final _descC = TextEditingController();

  String? _pickedPath; // path file sumber (sementara)
  String? _savedPath;  // path file setelah di-copy ke folder app

  @override
  void dispose() {
    _nameC.dispose();
    _catC.dispose();
    _priceC.dispose();
    _stockC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    if (res == null || res.files.isEmpty) return;

    final file = res.files.single;
    if (file.path == null) return;

    setState(() {
      _pickedPath = file.path!;
    });
  }

  Future<void> _save() async {
    final name = _nameC.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nama produk wajib diisi')));
      return;
    }

    final price = num.tryParse(_priceC.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final stock = int.tryParse(_stockC.text.replaceAll('.', '')) ?? 0;

    String? finalImagePath;
    if (_pickedPath != null && _pickedPath!.isNotEmpty) {
      final folder = await DatabaseService.instance.imagesDir();
      final ext = p.extension(_pickedPath!).toLowerCase(); // .jpg/.png
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}$ext';
      final dest = p.join(folder, fileName);

      try {
        await File(_pickedPath!).copy(dest);
        finalImagePath = dest;
        setState(() {
          _savedPath = dest;
        });
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal salin gambar: $e')));
        return;
      }
    }

    final id = await DatabaseService.instance.addProduct(
      name,
      _catC.text.trim().isEmpty ? null : _catC.text.trim(),
      price,
      stock,
      finalImagePath,
      _descC.text.trim().isEmpty ? null : _descC.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Produk tersimpan (ID: $id)')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Produk'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Form Produk',
                    style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    children: [
                      TextField(
                        controller: _nameC,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _catC,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _priceC,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga (Rp)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _stockC,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stok',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descC,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Pilih Gambar'),
                          ),
                          const SizedBox(width: 12),
                          if (_pickedPath != null)
                            Expanded(
                              child: Text(
                                p.basename(_pickedPath!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_pickedPath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_pickedPath!),
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (_savedPath != null) ...[
                        const SizedBox(height: 8),
                        Text('Disalin ke: $_savedPath',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ],
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
