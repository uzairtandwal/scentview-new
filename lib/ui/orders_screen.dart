import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

class AddressesScreen extends StatefulWidget {
  static const routeName = '/addresses';
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  int _defaultIndex = 0;

  final List<Map<String, dynamic>> _addresses = [
    {
      'label': 'Home',
      'name': 'John Doe',
      'address': '123, Perfume Lane',
      'city': 'Scent City, 54000',
      'phone': '+92 300 1234567',
    },
  ];

  // ── Label config ───────────────────────────────────────────────────────────
  static const _labelIcons = {
    'Home'   : Iconsax.home_25,
    'Office' : Iconsax.building_35,
    'Other'  : Iconsax.location5,
  };

  static const _labelColors = {
    'Home'   : Color(0xFF1565C0),
    'Office' : Color(0xFFE65100),
    'Other'  : Color(0xFF6A1B9A),
  };

  Color _labelColor(String label) =>
      _labelColors[label] ?? const Color(0xFF1565C0);

  IconData _labelIcon(String label) =>
      _labelIcons[label] ?? Iconsax.location5;

  // ── Actions ────────────────────────────────────────────────────────────────
  void _confirmDelete(int index) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Delete Address?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this address?',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _addresses.removeAt(index);
                if (_defaultIndex >= _addresses.length &&
                    _addresses.isNotEmpty) {
                  _defaultIndex = 0;
                }
              });
              Navigator.pop(context);
              _showSnack('Address removed', isError: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAddressSheet({int? editIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(
        existing: editIndex != null ? _addresses[editIndex] : null,
        labelIcons: _labelIcons,
        labelColors: _labelColors,
        onSave: (addr) {
          setState(() {
            if (editIndex != null) {
              _addresses[editIndex] = addr;
            } else {
              _addresses.add(addr);
            }
          });
          _showSnack(
              editIndex != null ? 'Address updated!' : 'Address added!');
        },
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? theme.colorScheme.error
            : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2,
              color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Shipping Addresses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showAddressSheet(),
        icon: const Icon(Iconsax.add),
        label: const Text(
          'Add Address',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 2,
      ),
      body: _addresses.isEmpty
          ? _EmptyState(onAdd: () => _showAddressSheet())
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _AddressCard(
                addr: _addresses[i],
                isDefault: i == _defaultIndex,
                labelColor: _labelColor(_addresses[i]['label'] as String),
                labelIcon: _labelIcon(_addresses[i]['label'] as String),
                theme: theme,
                onSetDefault: () => setState(() => _defaultIndex = i),
                onEdit: () => _showAddressSheet(editIndex: i),
                onDelete: () => _confirmDelete(i),
              ),
            ),
    );
  }
}

// ─── Address Card ─────────────────────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  final Map<String, dynamic> addr;
  final bool isDefault;
  final Color labelColor;
  final IconData labelIcon;
  final ThemeData theme;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.addr,
    required this.isDefault,
    required this.labelColor,
    required this.labelIcon,
    required this.theme,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDefault
              ? primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.12),
          width: isDefault ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDefault
                ? primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: labelColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(labelIcon, color: labelColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        addr['label'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    addr['name'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${addr['address']}\n${addr['city']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Iconsax.call, size: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4)),
                      const SizedBox(width: 5),
                      Text(
                        addr['phone'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              color: theme.colorScheme.surface,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Iconsax.edit_2, size: 18,
                        color: theme.colorScheme.onSurface),
                    const SizedBox(width: 10),
                    Text('Edit',
                        style:
                            TextStyle(color: theme.colorScheme.onSurface)),
                  ]),
                ),
                if (!isDefault)
                  PopupMenuItem(
                    value: 'default',
                    child: Row(children: [
                      Icon(Iconsax.tick_circle, size: 18, color: primary),
                      const SizedBox(width: 10),
                      Text('Set as Default',
                          style: TextStyle(color: primary)),
                    ]),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Iconsax.trash, size: 18,
                        color: theme.colorScheme.error),
                    const SizedBox(width: 10),
                    Text('Delete',
                        style:
                            TextStyle(color: theme.colorScheme.error)),
                  ]),
                ),
              ],
              onSelected: (val) {
                if (val == 'default') onSetDefault();
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Address Form Sheet ───────────────────────────────────────────────────────
class _AddressFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final Map<String, IconData> labelIcons;
  final Map<String, Color> labelColors;
  final ValueChanged<Map<String, dynamic>> onSave;

  const _AddressFormSheet({
    required this.existing,
    required this.labelIcons,
    required this.labelColors,
    required this.onSave,
  });

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  late String _selectedLabel;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _phoneCtrl;
  final _formKey = GlobalKey<FormState>();

  static const _labels = ['Home', 'Office', 'Other'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _selectedLabel = e?['label'] as String? ?? 'Home';
    _nameCtrl    = TextEditingController(text: e?['name']    as String? ?? '');
    _addressCtrl = TextEditingController(text: e?['address'] as String? ?? '');
    _cityCtrl    = TextEditingController(text: e?['city']    as String? ?? '');
    _phoneCtrl   = TextEditingController(text: e?['phone']   as String? ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave({
      'label'  : _selectedLabel,
      'name'   : _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'city'   : _cityCtrl.text.trim(),
      'phone'  : _phoneCtrl.text.trim(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isEdit  = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isEdit ? 'Edit Address' : 'Add New Address',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 20),

                // Label selector
                Text('LABEL', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  letterSpacing: 1.2, color: primary,
                )),
                const SizedBox(height: 10),
                Row(
                  children: _labels.map((lbl) {
                    final isSelected = _selectedLabel == lbl;
                    final color = widget.labelColors[lbl] ?? primary;
                    final icon  = widget.labelIcons[lbl] ?? Iconsax.location5;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedLabel = lbl),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(
                              right: lbl != _labels.last ? 10 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.08)
                                : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? color.withValues(alpha: 0.5)
                                  : theme.colorScheme.outline
                                      .withValues(alpha: 0.2),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(children: [
                            Icon(icon,
                                color: isSelected
                                    ? color
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.3),
                                size: 22),
                            const SizedBox(height: 5),
                            Text(lbl, style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? color
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                            )),
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                _FormField(ctrl: _nameCtrl, hint: 'Full Name',
                    icon: Iconsax.user, theme: theme,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required' : null),
                const SizedBox(height: 12),
                _FormField(ctrl: _addressCtrl, hint: 'Street Address',
                    icon: Iconsax.location, theme: theme,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Address is required' : null),
                const SizedBox(height: 12),
                _FormField(ctrl: _cityCtrl,
                    hint: 'City, Province & Postal Code',
                    icon: Iconsax.building, theme: theme),
                const SizedBox(height: 12),
                _FormField(ctrl: _phoneCtrl, hint: 'Phone Number',
                    icon: Iconsax.call, theme: theme,
                    type: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d\s\+\-]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Phone is required';
                      if (v.trim().length < 10)
                        return 'Enter a valid phone number';
                      return null;
                    }),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isEdit ? 'Save Changes' : 'Add Address',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
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

// ─── Form Field ───────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final ThemeData theme;
  final TextInputType type;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({
    required this.ctrl,
    required this.hint,
    required this.icon,
    required this.theme,
    this.type = TextInputType.text,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: primary, size: 20),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.location, size: 40, color: primary),
            ),
            const SizedBox(height: 20),
            Text('No addresses saved',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700, letterSpacing: -0.2)),
            const SizedBox(height: 8),
            Text(
              'Add a shipping address\nto get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, height: 1.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Iconsax.add, size: 18),
              label: const Text('Add Address',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
