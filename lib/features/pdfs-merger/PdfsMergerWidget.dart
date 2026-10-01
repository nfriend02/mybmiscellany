import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/history/saveResult.dart';
import '../../core/registry/featureModule.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import '../../shared/widgets/FeatureFrame.dart';
import '../../shared/widgets/InputBox.dart';
import '../../shared/widgets/Panels.dart';
import 'pdfsMergerService.dart';

class PdfsMergerWidget extends StatefulWidget {
  const PdfsMergerWidget({super.key, required this.module});

  final FeatureModule module;

  @override
  State<PdfsMergerWidget> createState() => _PdfsMergerWidgetState();
}

class _PdfsMergerWidgetState extends State<PdfsMergerWidget> {
  final _note = TextEditingController();
  List<PickedUpload> _files = [];
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _merge() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final merged = await mergePdfs(_files.map((file) => file.bytes).toList());
      final saved = await FilePicker.saveFile(
        fileName: 'merged.pdf',
        bytes: merged,
        mimeType: 'application/pdf',
      );
      if (!mounted) return;
      await saveResult(
        context,
        featureType: widget.module.featureType,
        title: 'PDF ${_files.length}개 병합',
        preview:
            '${_files.map((file) => file.name).join(' + ')} → ${(merged.length / 1024).toStringAsFixed(1)}KB',
        input: {
          'files': _files.map((file) => file.name).toList(),
          'note': _note.text.trim(),
        },
        output: {'bytes': merged.length, 'saved': saved != null},
      );
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'PDF를 합치지 못했습니다. 암호화되지 않은 파일인지 확인해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureFrame(
      module: widget.module,
      children: [
        InputBox(
          label: 'PDF 파일',
          hint: '병합 순서를 메모해 둘 수 있습니다.',
          controller: _note,
          maxLines: 2,
          enableFile: true,
          allowMultiple: true,
          allowedExtensions: const ['pdf'],
          files: _files,
          onFiles: (files) => setState(() => _files = files),
        ),
        const SizedBox(height: 8),
        const NoteText('아래 목록 순서가 합쳐지는 순서입니다. 결과 PDF는 저장 위치로 내려받습니다.'),
        const SizedBox(height: 10),
        for (var index = 0; index < _files.length; index++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Text(
                  '${index + 1}',
                  style: orbitron(14, color: AppColors.blue),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(_files[index].name, style: bodyText())),
                IconButton(
                  tooltip: '위로',
                  onPressed: index == 0
                      ? null
                      : () => setState(() {
                          final item = _files.removeAt(index);
                          _files.insert(index - 1, item);
                        }),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                IconButton(
                  tooltip: '아래로',
                  onPressed: index == _files.length - 1
                      ? null
                      : () => setState(() {
                          final item = _files.removeAt(index);
                          _files.insert(index + 1, item);
                        }),
                  icon: const Icon(Icons.arrow_downward_rounded),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy || _files.length < 2 ? null : _merge,
          child: Text(_busy ? '합치는 중' : '하나로 병합'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: bodyText(color: AppColors.neonOrange)),
        ],
      ],
    );
  }
}
