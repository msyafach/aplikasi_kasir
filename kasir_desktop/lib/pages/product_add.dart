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
  final formKey = GlobalKey<FormState>();
  final nameC = TextEditingController();
  final catC = TextEditingController();
  final priceC = TextEditingController(text: '0');
  final stockC = TextEditingController(text: '0');
  final descC = TextEditingController();
  String? imagePath;

  @override
  void dispose() {
    nameC.dispose(); catC.dispose(); priceC.dispose(); stockC.dispose(); descC.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null && res.files.single.path != null) {
      final src = File(res.files.single.path!);
      final imagesDir = await DatabaseService.instance.imagesDir();
      final destPath = p.join(imagesDir, '${DateTime.now().millisecondsSinceEpoch}_${p.basename(src.path)}');
      await src.copy(destPath);
      setState(() => imagePath = destPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => Navigator.pop(context)), title: const Text('Tambah Produk Baru')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: nameC,
                      decoration: const InputDecoration(labelText: 'Nama Produk *', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: catC,
                      decoration: const InputDecoration(labelText: 'Kategori', hintText: 'Contoh: Makanan, Minuman', border: OutlineInputBorder()),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceC, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga (Rp) *', border: OutlineInputBorder()),
                      validator: (v) => (double.tryParse(v ?? '') == null) ? 'Angka tidak valid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: stockC, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stok *', border: OutlineInputBorder()),
                      validator: (v) => (int.tryParse(v ?? '') == null) ? 'Angka tidak valid' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descC, minLines: 3, maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  FilledButton.icon(onPressed: pickImage, icon: const Icon(Icons.image_outlined), label: const Text('Upload Gambar')),
                  const SizedBox(width: 12),
                  if (imagePath != null) ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(imagePath!), width: 96, height: 96, fit: BoxFit.cover),
                  ),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  FilledButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await DatabaseService.instance.addProduct(
                        name: nameC.text.trim(),
                        price: double.parse(priceC.text),
                        stock: int.parse(stockC.text),
                        category: catC.text.trim().isEmpty ? null : catC.text.trim(),
                        description: descC.text.trim().isEmpty ? null : descC.text.trim(),
                        imagePath: imagePath,
                      );
                      if (context.mounted) Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.save_alt), label: const Text('Simpan Produk'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
