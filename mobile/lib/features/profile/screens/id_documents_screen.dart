import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';

class _Document {
  final String id;
  final String name;
  final String type;
  final String? url;
  const _Document({required this.id, required this.name, required this.type, this.url});
}

final _documentsProvider = FutureProvider.autoDispose<List<_Document>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/documents');
  final list = response.data as List<dynamic>;
  return list
      .map((e) => _Document(
            id: e['id'] as String,
            name: e['name'] as String,
            type: e['type'] as String,
            url: e['url'] as String?,
          ))
      .toList();
});

class IdDocumentsScreen extends ConsumerStatefulWidget {
  const IdDocumentsScreen({super.key});

  @override
  ConsumerState<IdDocumentsScreen> createState() => _IdDocumentsScreenState();
}

class _IdDocumentsScreenState extends ConsumerState<IdDocumentsScreen> {
  bool _isUploading = false;

  Future<void> _uploadDocument(String docType, String docName) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final dio = ref.read(dioProvider);
      final bytes = await File(file.path).readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final key = 'uploads/${DateTime.now().millisecondsSinceEpoch}-$docType.$ext';

      final presignedResp = await dio.post('/uploads/presigned', data: {
        'key': key,
        'contentType': contentType,
        'contentLength': bytes.length,
      });
      final uploadUrl = presignedResp.data['uploadUrl'] as String;

      await Dio().put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {'Content-Type': contentType, 'Content-Length': bytes.length},
        ),
      );

      await dio.post('/documents', data: {
        'name': docName,
        'type': docType,
        's3Key': key,
        'contentType': contentType,
      });

      ref.invalidate(_documentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.document_uploaded'.tr())),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.document_upload_failed'.tr()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile.delete_document'.tr()),
        content: Text('profile.delete_document_confirm'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(dioProvider).delete('/documents/$docId');
      ref.invalidate(_documentsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.document_delete_failed'.tr()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(_documentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('profile.id_documents'.tr())),
      body: Stack(
        children: [
          docsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('common.error'.tr())),
            data: (docs) => _buildBody(context, docs, isDark),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<_Document> docs, bool isDark) {
    const slots = [
      {'type': 'id-front', 'label': 'profile.id_front'},
      {'type': 'id-back', 'label': 'profile.id_back'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('profile.id_documents_hint'.tr(), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          ...slots.map((slot) {
            final existing = docs.where((d) => d.type == slot['type']).toList();
            final doc = existing.isNotEmpty ? existing.first : null;
            return _DocumentSlot(
              label: slot['label']!.tr(),
              docType: slot['type']!,
              document: doc,
              isDark: isDark,
              onUpload: () => _uploadDocument(slot['type']!, slot['label']!.tr()),
              onDelete: doc != null ? () => _deleteDocument(doc.id) : null,
              onView: doc?.url != null ? () => _viewDocument(context, doc!.url!) : null,
            );
          }),
          if (docs.any((d) => d.type != 'id-front' && d.type != 'id-back')) ...[
            const SizedBox(height: 24),
            Text('profile.other_documents'.tr(), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            ...docs.where((d) => d.type != 'id-front' && d.type != 'id-back').map(
              (doc) => _OtherDocTile(doc: doc, isDark: isDark, onDelete: () => _deleteDocument(doc.id)),
            ),
          ],
        ],
      ),
    );
  }

  void _viewDocument(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenImageScreen(url: url),
      ),
    );
  }
}

class _DocumentSlot extends StatelessWidget {
  const _DocumentSlot({
    required this.label,
    required this.docType,
    required this.isDark,
    required this.onUpload,
    this.document,
    this.onDelete,
    this.onView,
  });

  final String label;
  final String docType;
  final _Document? document;
  final bool isDark;
  final VoidCallback onUpload;
  final VoidCallback? onDelete;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          if (document?.url != null)
            GestureDetector(
              onTap: onView,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  document!.url!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: isDark ? AppColors.darkSurfaceRaised : AppColors.background,
                    child: const Icon(Icons.broken_image_outlined, size: 48),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceRaised : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insert_drive_file_outlined,
                        size: 36, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text('profile.not_uploaded'.tr(),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_rounded, size: 16),
                  label: Text(document != null ? 'profile.replace'.tr() : 'profile.upload'.tr()),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  tooltip: 'common.delete'.tr(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OtherDocTile extends StatelessWidget {
  const _OtherDocTile({required this.doc, required this.isDark, required this.onDelete});
  final _Document doc;
  final bool isDark;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined),
      title: Text(doc.name, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(doc.type, style: Theme.of(context).textTheme.bodySmall),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
    );
  }
}

class _FullscreenImageScreen extends StatelessWidget {
  const _FullscreenImageScreen({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
