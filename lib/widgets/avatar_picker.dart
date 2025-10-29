import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AvatarPicker extends StatefulWidget {
  const AvatarPicker({super.key, this.initialUrl, required this.onPicked});

  final String? initialUrl;
  final void Function(Uint8List data, String fileExt) onPicked;

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  Uint8List? _bytes;
  String? _fileExt;

  Future<void> _pick() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        setState(() {
          _bytes = file.bytes;
          _fileExt = file.extension ?? 'png';
        });
        widget.onPicked(_bytes!, _fileExt!);
      }
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _bytes = bytes;
        _fileExt = picked.path.split('.').last.toLowerCase();
      });
      widget.onPicked(bytes, _fileExt!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = 36.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: radius,
              backgroundImage: _bytes != null
                  ? MemoryImage(_bytes!)
                  : (widget.initialUrl != null ? NetworkImage(widget.initialUrl!) as ImageProvider : null),
              child: _bytes == null && widget.initialUrl == null ? const Icon(Icons.person, size: 32) : null,
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(onPressed: _pick, icon: const Icon(Icons.upload), label: const Text('Chọn ảnh')),
          ],
        ),
        if (_fileExt != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Đã chọn: $_fileExt')),
      ],
    );
  }
}


