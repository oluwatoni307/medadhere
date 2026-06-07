// ============================================
// FILE: add_edit_medication_screen.dart
// LAYER: screen
// DOMAIN: medications
// RESPONSIBLE FOR: 3-step add/edit medication flow — owns all form state, private step methods for UI
// RECEIVES: Optional medication for edit mode, onSaved and onCancelled callbacks
// RETURNS: Widget
// CONNECTS TO: medication_provider.dart
// MUST NEVER: Call services or repositories directly, use go_router, use context.pop()
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/medication.dart';
import '../../../shared/models/category.dart';
import '../state/medication_provider.dart';
import '../../../core/constants/app_constant.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_animations.dart';

class AddEditMedicationScreen extends ConsumerStatefulWidget {
  const AddEditMedicationScreen({
    super.key,
    this.medication,
    required this.onSaved,
    required this.onCancelled,
  });

  final Medication? medication;
  final VoidCallback onSaved;
  final VoidCallback onCancelled;

  @override
  ConsumerState<AddEditMedicationScreen> createState() =>
      _AddEditMedicationScreenState();
}

class _AddEditMedicationScreenState
    extends ConsumerState<AddEditMedicationScreen> {
  // --- step ---
  late int _step;

  // --- form controllers ---
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _purposeController;
  late final TextEditingController _newCategoryController;

  // --- form values ---
  String? _selectedCategoryId;
  late String _frequency;
  final List<String> _times = [];

  // --- category creation ---
  bool _addingCategory = false;
  String _newCategoryColor = '#1A6B58';

  // --- validation ---
  bool _showTimeValidation = false;

  // --- mode ---
  bool get _isEdit => widget.medication != null;

  // --- frequency display ↔ data mapping (Option C) ---
  static const _asNeededDisplay = 'Only when needed';
  static const _asNeededValue = 'As needed';

  static const _frequencyOptions = [
    'Once a day',
    'Twice a day',
    'Three times a day',
    _asNeededDisplay,
  ];

  static const _presetColors = [
    '#1A6B58',
    '#8A5800',
    '#B3261E',
    '#2B6B38',
    '#5B4FCF',
    '#1565C0',
  ];

  String _toDisplayFrequency(String value) {
    if (value == _asNeededValue) return _asNeededDisplay;
    if (value == 'Once daily') return 'Once a day'; // model default guard
    return value;
  }

  String _toDataFrequency(String display) =>
      display == _asNeededDisplay ? _asNeededValue : display;

  int get _timeSlotCount =>
      const {
        'Once a day': 1,
        'Twice a day': 2,
        'Three times a day': 3,
      }[_frequency] ??
      0;

  bool get _canSave =>
      _nameController.text.isNotEmpty &&
      _dosageController.text.isNotEmpty &&
      (_frequency == _asNeededDisplay || _times.isNotEmpty);

  // --- lifecycle ---

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      final m = widget.medication!;
      _nameController = TextEditingController(text: m.name);
      _dosageController = TextEditingController(text: m.dosage);
      _purposeController = TextEditingController(text: m.purpose ?? '');
      _selectedCategoryId = m.categoryId;
      _frequency = _toDisplayFrequency(m.frequency);
      _times.addAll(m.times);
    } else {
      _nameController = TextEditingController();
      _dosageController = TextEditingController();
      _purposeController = TextEditingController();
      _frequency = 'Once a day';
    }

    _newCategoryController = TextEditingController();
    _step = 1;

    Future.microtask(() {
      if (ref.read(medicationProvider).categories.isEmpty) {
        ref.read(medicationProvider.notifier).loadMedications();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _purposeController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  // --- navigation ---

  void _handleBack() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      _showCancelDialog();
    }
  }

  void _handleNext() {
    if (_step == 3) {
      if (_frequency != _asNeededDisplay && _times.isEmpty) {
        setState(() => _showTimeValidation = true);
        return;
      }
      _save();
    } else {
      setState(() {
        _showTimeValidation = false;
        _step++;
      });
    }
  }

  Future<void> _showCancelDialog() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => const _CancelDialog(),
    );
    if ((leave ?? false) && mounted) widget.onCancelled();
  }

  // --- save ---

  Future<void> _save() async {
    if (!_canSave) return;
    final notifier = ref.read(medicationProvider.notifier);
    final med = Medication(
      id: _isEdit
          ? widget.medication!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      purpose: _purposeController.text.trim().isEmpty
          ? null
          : _purposeController.text.trim(),
      categoryId: _selectedCategoryId,
      frequency: _toDataFrequency(_frequency),
      times: _frequency == _asNeededDisplay
          ? const []
          : List.unmodifiable(_times.take(_timeSlotCount).toList()),
      userId: AppConstants.placeholderUserId,
      createdAt: _isEdit ? widget.medication!.createdAt : DateTime.now(),
    );
    if (_isEdit) {
      await notifier.updateMedication(med);
    } else {
      await notifier.addMedication(med);
    }
    if (mounted) widget.onSaved();
  }

  // --- category actions ---

  Future<void> _submitNewCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) {
      setState(() => _addingCategory = false);
      return;
    }
    final category = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: _newCategoryColor,
      userId: AppConstants.placeholderUserId,
    );
    await ref.read(medicationProvider.notifier).addCategory(category);
    if (!mounted) return;
    _newCategoryController.clear();
    setState(() {
      _addingCategory = false;
      _newCategoryColor = '#1A6B58';
    });
  }

  void _cancelNewCategory() {
    _newCategoryController.clear();
    setState(() {
      _addingCategory = false;
      _newCategoryColor = '#1A6B58';
    });
  }

  // --- time ---

  void _onTimePicked(int slotIndex, String time) {
    setState(() {
      if (slotIndex < _times.length) {
        _times[slotIndex] = time;
      } else {
        _times.add(time);
      }
      _showTimeValidation = false;
    });
  }

  Future<void> _showTimePicker(int slotIndex) async {
    int h = 8, m = 0, p = 0;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.colorCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.radiusXL),
        ),
      ),
      builder: (_) => StatefulBuilder(
        builder: (_, setSt) {
          final typography = Theme.of(context).extension<AppTypography>()!;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.space20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'What time works for you?',
                  style: typography.textHeading2.copyWith(
                    color: AppColors.colorTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWheel(
                      List.generate(12, (i) => i + 1),
                      (v) => setSt(() => h = v),
                      disableAnimations: disableAnimations,
                    ),
                    Text(
                      ' : ',
                      style: typography.textHeading1.copyWith(
                        color: AppColors.colorTextPrimary,
                      ),
                    ),
                    _buildWheel(
                      [0, 15, 30, 45],
                      (v) => setSt(() => m = v),
                      labels: ['00', '15', '30', '45'],
                      disableAnimations: disableAnimations,
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    _buildWheel(
                      [0, 1],
                      (v) => setSt(() => p = v),
                      labels: ['AM', 'PM'],
                      disableAnimations: disableAnimations,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space24),
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.buttonHeightPrimary,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.colorPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.button,
                      ),
                    ),
                    onPressed: () {
                      final time =
                          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} ${['AM', 'PM'][p]}';
                      Navigator.pop(context);
                      _onTimePicked(slotIndex, time);
                    },
                    child: Text(
                      'SET TIME',
                      style: typography.textLabel.copyWith(
                        color: AppColors.colorOnPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWheel(
    List<int> items,
    ValueChanged<int> onChanged, {
    List<String>? labels,
    required bool disableAnimations,
  }) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return SizedBox(
      height: 120,
      width: 50,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        physics: disableAnimations
            ? const NeverScrollableScrollPhysics()
            : const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (i) => onChanged(items[i]),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: items.length,
          builder: (_, i) => Center(
            child: Text(
              labels != null ? labels[i] : '${items[i]}',
              style: typography.textBody.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- build ---

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicationProvider);
    final typography = Theme.of(context).extension<AppTypography>()!;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.colorSurface,
      appBar: AppBar(
        backgroundColor: AppColors.colorCard,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: _handleBack,
          child: SizedBox(
            width: AppSpacing.touchTargetMin,
            height: AppSpacing.touchTargetMin,
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.colorTextPrimary,
              size: 24,
            ),
          ),
        ),
        title: Text(
          _isEdit ? 'Edit medication' : 'Add medication',
          style: typography.textHeading1.copyWith(
            color: AppColors.colorTextPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _showCancelDialog,
            child: Text(
              'Cancel',
              style: typography.textBody.copyWith(
                color: AppColors.colorPrimary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.viewportMarginHorizontal,
            vertical: AppSpacing.space20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- progress bar ---
              Text(
                'Step $_step of 3',
                style: typography.textCaption.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              ClipRRect(
                borderRadius: AppRadius.badge,
                child: LinearProgressIndicator(
                  value: _step / 3,
                  minHeight: 4.0, // TOKEN GAP: no token at this scale
                  backgroundColor: AppColors.colorSurfaceMuted,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.colorPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),

              // --- step content ---
              Expanded(
                child: AnimatedSwitcher(
                  duration: disableAnimations
                      ? AppMotion.durationInstant
                      : AppMotion.durationFast,
                  switchInCurve: AppMotion.curveStandard,
                  switchOutCurve: AppMotion.curveStandard,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_step),
                    child: _step == 1
                        ? _buildStep1()
                        : _step == 2
                        ? _buildStep2(state.categories)
                        : _buildStep3(),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space16),

              // --- primary action button ---
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeightPrimary,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: (_step == 3 && !_canSave)
                        ? AppColors.colorDisabled
                        : AppColors.colorPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
                    ),
                  ),
                  onPressed: (_step == 3 && !_canSave) || state.isLoading
                      ? null
                      : _handleNext,
                  child: state.isLoading
                      ? LoadingPulseAnimation(
                          isLoading: true,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.colorOnPrimary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Text(
                          _step < 3
                              ? 'NEXT'
                              : _isEdit
                              ? 'SAVE CHANGES'
                              : 'ADD MEDICATION',
                          style: typography.textLabel.copyWith(
                            color: AppColors.colorOnPrimary,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- step 1: name, dosage, purpose ---

  Widget _buildStep1() {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            // name
            Text(
              'What medication is this?',
              style: typography.textBody.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            _buildTextField(
              controller: _nameController,
              hint: 'e.g. Metformin',
              action: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.space24),

            // dosage
            Text(
              'How much do you take?',
              style: typography.textBody.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            _buildTextField(
              controller: _dosageController,
              hint: 'e.g. 500mg',
              action: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.space24),

            // purpose
            Row(
              children: [
                Text(
                  'What do you take it for?',
                  style: typography.textBody.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space8),
                Text(
                  'Optional',
                  style: typography.textCaption.copyWith(
                    color: AppColors.colorTextTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space8),
            _buildTextField(
              controller: _purposeController,
              hint: 'e.g. For blood pressure',
              action: TextInputAction.done,
            ),
          ]),
        ),
      ],
    );
  }

  // --- step 2: category, frequency ---

  Widget _buildStep2(List<Category> categories) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            // category label
            Text(
              'Category',
              style: typography.textBody.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Categories help you group similar medications together.',
              style: typography.textCaption.copyWith(
                color: AppColors.colorTextTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),

            // category chips
            Wrap(
              spacing: AppSpacing.space8,
              runSpacing: AppSpacing.space8,
              children: [
                ...categories.map((c) {
                  final selected = _selectedCategoryId == c.id;
                  return FilterChip(
                    key: ValueKey(c.id),
                    label: Text(
                      c.name,
                      style: typography.textBodySmall.copyWith(
                        color: selected
                            ? AppColors.colorStateConsistent
                            : AppColors.colorTextSecondary,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedCategoryId = c.id),
                    backgroundColor: AppColors.colorSurfaceMuted,
                    selectedColor: AppColors.colorStateConsistentSurface,
                    side: BorderSide(
                      color: selected
                          ? AppColors.colorStateConsistent
                          : AppColors.colorBorder,
                      width: selected ? 1.5 : 0.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.chip),
                    showCheckmark: false,
                  );
                }),
                if (!_addingCategory)
                  ActionChip(
                    key: const ValueKey('new-category-chip'),
                    avatar: const Icon(
                      Icons.add,
                      size: 16,
                      color: AppColors.colorTextSecondary,
                    ),
                    label: Text(
                      'New category',
                      style: typography.textBodySmall.copyWith(
                        color: AppColors.colorTextSecondary,
                      ),
                    ),
                    backgroundColor: AppColors.colorSurfaceMuted,
                    side: const BorderSide(
                      color: AppColors.colorBorder,
                      width: 0.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.chip),
                    onPressed: () => setState(() => _addingCategory = true),
                  ),
              ],
            ),

            // Fix 1: inline category input wrapped in container for visual anchoring
            if (_addingCategory) ...[
              const SizedBox(height: AppSpacing.space8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.space12),
                decoration: BoxDecoration(
                  color: AppColors.colorSurfaceMuted,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.colorBorder, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newCategoryController,
                            autofocus: true,
                            style: typography.textBody.copyWith(
                              color: AppColors.colorTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Category name',
                              hintStyle: typography.textBody.copyWith(
                                color: AppColors.colorTextTertiary,
                              ),
                              filled: true,
                              fillColor: AppColors.colorCard,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space12,
                                vertical: AppSpacing.space8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.pill,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppRadius.pill,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppRadius.pill,
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _submitNewCategory(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        SizedBox(
                          width: AppSpacing.touchTargetMin,
                          height: AppSpacing.touchTargetMin,
                          child: GestureDetector(
                            onTap: _submitNewCategory,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: AppColors.colorPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: AppColors.colorOnPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space4),
                        SizedBox(
                          width: AppSpacing.touchTargetMin,
                          height: AppSpacing.touchTargetMin,
                          child: GestureDetector(
                            onTap: _cancelNewCategory,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.colorSurfaceMuted,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: AppColors.colorTextSecondary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    // color picker row
                    Row(
                      children: _presetColors.map((hex) {
                        final color = Color(
                          int.parse('0xFF${hex.substring(1)}'),
                        );
                        final selected = _newCategoryColor == hex;
                        return GestureDetector(
                          onTap: () => setState(() => _newCategoryColor = hex),
                          child: SizedBox(
                            width: AppSpacing.touchTargetMin,
                            height: AppSpacing.touchTargetMin,
                            child: Center(
                              child: Container(
                                key: ValueKey(hex),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(
                                          color: AppColors.colorTextPrimary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Fix 2: divider between category and frequency for scroll discoverability
            const SizedBox(height: AppSpacing.space32),
            Divider(color: AppColors.colorBorder, thickness: 0.5, height: 0),
            const SizedBox(height: AppSpacing.space24),

            // frequency label
            Text(
              'How often?',
              style: typography.textBody.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),

            // Fix 3: frequency items inlined into sliver delegate — no nested ListView
            ...List.generate(_frequencyOptions.length, (i) {
              final option = _frequencyOptions[i];
              final selected = _frequency == option;
              return Padding(
                key: ValueKey(option),
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.doseOptionVerticalGap,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _frequency = option),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: AppSpacing.doseOptionMinHeight,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: AppSpacing.space12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.colorStateConsistentSurface
                          : AppColors.colorSurfaceMuted,
                      borderRadius: AppRadius.chip,
                      border: Border.all(
                        color: selected
                            ? AppColors.colorStateConsistent
                            : AppColors.colorBorder,
                        width: selected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Text(
                      option,
                      style: typography.textBody.copyWith(
                        color: AppColors.colorTextPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ]),
        ),
      ],
    );
  }

  // --- step 3: time slots ---

  Widget _buildStep3() {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final isAsNeeded = _frequency == _asNeededDisplay;

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            // Fix 4: as-needed state has icon for visual weight
            if (isAsNeeded)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space32),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 48,
                      color: AppColors.colorTextTertiary,
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    Text(
                      'You can take this medication whenever you need it.',
                      textAlign: TextAlign.center,
                      style: typography.textBody.copyWith(
                        color: AppColors.colorTextSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'What time do you take it?',
                style: typography.textBody.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),

              if (_showTimeValidation) ...[
                Text(
                  'Choose a time to keep going.',
                  style: typography.textCaption.copyWith(
                    color: AppColors.colorStateRisk,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
              ],

              // time slots inlined — no nested ListView
              ...List.generate(_timeSlotCount, (i) {
                final hasTime = i < _times.length;
                return Padding(
                  key: ValueKey('time-slot-$i'),
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.doseOptionVerticalGap,
                  ),
                  child: GestureDetector(
                    onTap: () => _showTimePicker(i),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: AppSpacing.doseOptionMinHeight,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                        vertical: AppSpacing.space12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.colorSurfaceMuted,
                        borderRadius: AppRadius.cardLarge,
                        border: Border.all(
                          color: AppColors.colorBorder,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            hasTime ? _times[i] : 'Tap to set a time',
                            style: typography.textBody.copyWith(
                              color: hasTime
                                  ? AppColors.colorTextPrimary
                                  : AppColors.colorTextTertiary,
                            ),
                          ),
                          const Icon(
                            Icons.access_time,
                            size: 24,
                            color: AppColors.colorTextTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ]),
        ),
      ],
    );
  }

  // --- shared field builder ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required TextInputAction action,
  }) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return TextField(
      controller: controller,
      textInputAction: action,
      style: typography.textBody.copyWith(color: AppColors.colorTextPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: typography.textBody.copyWith(
          color: AppColors.colorTextTertiary,
        ),
        filled: true,
        fillColor: AppColors.colorSurfaceMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.card,
          borderSide: const BorderSide(
            color: AppColors.colorBorder,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.card,
          borderSide: BorderSide(color: AppColors.colorPrimary, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space16,
        ),
      ),
    );
  }
}

// --- cancel dialog ---

class _CancelDialog extends StatelessWidget {
  const _CancelDialog();

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return AlertDialog(
      backgroundColor: AppColors.colorCard,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      title: Text(
        'Leave this for now?',
        style: typography.textHeading2.copyWith(
          color: AppColors.colorTextPrimary,
        ),
      ),
      content: Text(
        'You can come back and finish this whenever you\'re ready.',
        style: typography.textBody.copyWith(
          color: AppColors.colorTextSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Leave',
            style: typography.textBody.copyWith(
              color: AppColors.colorStateRisk,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.colorPrimary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          ),
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'KEEP GOING',
            style: typography.textLabel.copyWith(
              color: AppColors.colorOnPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
