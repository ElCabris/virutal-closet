import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

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
  File? _imageFile;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
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
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            imageFile: _imageFile,
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
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border,
            width: _imageFile == null ? 1 : 0,
          ),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_imageFile!, fit: BoxFit.cover),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => setState(() => _imageFile = null),
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
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.textDisabled, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Add photo',
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
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                context.pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _brandCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Brand'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                ),
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
