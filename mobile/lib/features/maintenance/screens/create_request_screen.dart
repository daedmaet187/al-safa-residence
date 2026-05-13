import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gold_button.dart';
import '../providers/maintenance_provider.dart';

// Keys are backend enum values; values are translation keys
const _categoryMap = {
  'PLUMBING': 'maintenance.categories.plumbing',
  'ELECTRICAL': 'maintenance.categories.electrical',
  'AC_HVAC': 'maintenance.categories.ac_hvac',
  'APPLIANCE': 'maintenance.categories.appliance',
  'CLEANING': 'maintenance.categories.cleaning',
  'PEST_CONTROL': 'maintenance.categories.pest_control',
  'STRUCTURAL': 'maintenance.categories.structural',
  'OTHER': 'maintenance.categories.other',
};
final _categories = _categoryMap.keys.toList();

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = _categories.first;
  final List<String> _photoUrls = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1024);
    if (file == null) return;

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final bytes = await File(file.path).readAsBytes();
      final userId = DateTime.now().millisecondsSinceEpoch;
      final key = 'uploads/${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}_$userId.jpg';

      final presignedResp = await dio.post('/uploads/presigned', data: {
        'key': key,
        'contentType': 'image/jpeg',
        'contentLength': bytes.length,
      });
      final uploadUrl = presignedResp.data['uploadUrl'] as String;

      await Dio().put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': 'image/jpeg',
            'Content-Length': bytes.length,
          },
        ),
      );

      final s3Url = presignedResp.data['url'] as String? ?? uploadUrl.split('?')[0];
      setState(() => _photoUrls.add(s3Url));
    } catch (_) {
      // If upload fails, skip photo silently
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text('maintenance.take_photo'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text('maintenance.choose_gallery'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(maintenanceNotifierProvider.notifier).createRequest(
            title: _titleCtrl.text.trim(),
            category: _category,
            description: _descCtrl.text.trim(),
            photoUrls: _photoUrls,
          );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('maintenance.request_submitted'.tr())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('maintenance.failed'.tr(namedArgs: {'error': e.toString()}))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('maintenance.new_request'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'maintenance.request_title'.tr(),
                  prefixIcon: const Icon(Icons.title_rounded),
                  hintText: 'maintenance.title_hint'.tr(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'maintenance.enter_title'.tr() : null,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'maintenance.category'.tr(),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(_categoryMap[c]?.tr() ?? c),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'maintenance.description'.tr(),
                  hintText: 'maintenance.description_hint'.tr(),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'maintenance.enter_description'.tr() : null,
              ),
              const SizedBox(height: 20),

              // Photo upload
              Text('maintenance.photos_optional'.tr(),
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._photoUrls.map(
                    (url) => Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceRaised
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: url.startsWith('http')
                              ? Image.network(url, width: 80, height: 80, fit: BoxFit.cover)
                              : Image.file(File(url), width: 80, height: 80, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _photoUrls.remove(url)),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_photoUrls.length < 5)
                    GestureDetector(
                      onTap: _showImagePicker,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceRaised
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                          size: 28,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 32),
              GoldButton(
                label: 'maintenance.submit_request'.tr(),
                icon: Icons.send_rounded,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
