import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_utils.dart';

class AddGarmentScreen extends ConsumerStatefulWidget {
  const AddGarmentScreen({super.key});

  @override
  ConsumerState<AddGarmentScreen> createState() => _AddGarmentScreenState();
}

class _AddGarmentScreenState extends ConsumerState<AddGarmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _category = AppConstants.garmentCategories.first;
  String? _color;
  String? _season;
  String? _occasion;
  String _currency = AppConstants.defaultCurrency;
  final List<File> _imageFiles = [];
  bool _saving = false;
  bool _removeBackground = true;
  bool _processingImages = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    // If a save is in flight, the repository is (or is about to be)
    // reading these same files to upload them — deleting them here would
    // race with that read. In that case leave cleanup to _save(): the
    // repository deletes local files itself once the upload is durably
    // confirmed, and never deletes them on failure. Only clean up here for
    // the "user picked photos and left without saving" case, where nothing
    // else is going to touch these files again.
    if (!_saving) {
      unawaited(_deleteImageFilesQuietly(_imageFiles));
    }
    super.dispose();
  }

  static Future<void> _deleteImageFilesQuietly(List<File> files) async {
    for (final file in files) {
      await deleteFileQuietly(file);
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    final picker = ImagePicker();
    List<File> picked;
    if (source == ImageSource.gallery) {
      final files = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      picked = files.map((p) => File(p.path)).toList();
    } else {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      picked = file != null ? [File(file.path)] : [];
    }
    if (picked.isEmpty || !mounted) return;

    final bgService = ref.read(backgroundRemovalServiceProvider);
    if (_removeBackground && bgService.isSupported) {
      setState(() => _processingImages = true);
      final original = picked;
      picked = await bgService.removeBackgroundBatch(picked);
      if (!mounted) return;
      setState(() => _processingImages = false);

      // removeBackground() falls back to returning the same File (same
      // path) whenever it can't produce a cutout, so an unchanged path
      // means that photo's background wasn't actually removed. Surfacing
      // this beats failing silently — the toggle is on by default, so a
      // user who never opens the console would otherwise have no way to
      // tell it isn't working.
      final skipped = <int>[
        for (var i = 0; i < picked.length; i++)
          if (picked[i].path == original[i].path) i,
      ].length;
      if (skipped > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Couldn't remove background for $skipped of "
              '${picked.length} photo(s)',
            ),
          ),
        );
      }
    }

    setState(() => _imageFiles.addAll(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(garmentRepositoryProvider).createGarment(
            name: _nameCtrl.text.trim(),
            category: _category,
            brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
            color: _color,
            season: _season,
            occasion: _occasion,
            price: double.tryParse(_priceCtrl.text),
            currency: _currency,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            imageFiles: _imageFiles,
          );
      ref.invalidate(garmentsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Garment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildImagePicker().animate().fadeIn(),
            if (ref.read(backgroundRemovalServiceProvider).isSupported) ...[
              const SizedBox(height: 12),
              _buildBackgroundRemovalToggle().animate().fadeIn(delay: 50.ms),
            ],
            const SizedBox(height: 28),
            _buildBasicInfo().animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),
            _buildCategorySection().animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 20),
            _buildColorSection().animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 20),
            _buildSeasonSection().animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 20),
            _buildOccasionSection().animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 20),
            _buildNotesSection().animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Stack(
      children: [
        _buildImagePickerContent(),
        if (_processingImages)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text('Removing background...'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePickerContent() {
    if (_imageFiles.isEmpty) {
      return GestureDetector(
        onTap: _showImageSourceSheet,
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_photo_alternate_outlined,
                  color: AppColors.textDisabled, size: 40),
              const SizedBox(height: 12),
              Text(
                'Add photos',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to upload from camera or gallery',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _imageFiles.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == _imageFiles.length) {
            return GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Center(
                  child: Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.textDisabled, size: 32),
                ),
              ),
            );
          }
          return Container(
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_imageFiles[index], fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        final removed = _imageFiles[index];
                        setState(() => _imageFiles.removeAt(index));
                        unawaited(deleteFileQuietly(removed));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                context.pop();
                _pickImages(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                context.pop();
                _pickImages(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundRemovalToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Remove background'),
        subtitle: const Text('Applies on-device to new photos'),
        value: _removeBackground,
        onChanged: (val) => setState(() => _removeBackground = val),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Name *'),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Enter garment name' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _brandCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Brand'),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: AppConstants.currencies
                    .map((code) => DropdownMenuItem(
                          value: code,
                          child: Text(code),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _currency = val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return _buildChipGroup(
      label: 'Category *',
      items: AppConstants.garmentCategories,
      selected: [_category],
      onSelected: (val) => setState(() => _category = val),
      single: true,
    );
  }

  Widget _buildColorSection() {
    return _buildChipGroup(
      label: 'Color',
      items: AppConstants.garmentColors,
      selected: _color != null ? [_color!] : [],
      onSelected: (val) =>
          setState(() => _color = _color == val ? null : val),
      single: true,
    );
  }

  Widget _buildSeasonSection() {
    return _buildChipGroup(
      label: 'Season',
      items: AppConstants.seasons,
      selected: _season != null ? [_season!] : [],
      onSelected: (val) =>
          setState(() => _season = _season == val ? null : val),
      single: true,
    );
  }

  Widget _buildOccasionSection() {
    return _buildChipGroup(
      label: 'Occasion',
      items: AppConstants.occasions,
      selected: _occasion != null ? [_occasion!] : [],
      onSelected: (val) =>
          setState(() => _occasion = _occasion == val ? null : val),
      single: true,
    );
  }

  Widget _buildNotesSection() {
    return TextFormField(
      controller: _notesCtrl,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Notes',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildChipGroup({
    required String label,
    required List<String> items,
    required List<String> selected,
    required ValueChanged<String> onSelected,
    bool single = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selected.contains(item);
            return GestureDetector(
              onTap: () => onSelected(item),
              child: AnimatedContainer(
                duration: 150.ms,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.background
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
