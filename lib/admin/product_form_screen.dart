import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scentview/models/product_model.dart';
import 'package:scentview/services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/category.dart' as app_category;

class ProductFormScreen extends StatefulWidget {
  static const String routeName = '/admin/add-edit-product';
  final Product? product;
  final VoidCallback? onSave;
  const ProductFormScreen({this.product, this.onSave, Key? key}) : super(key: key);
  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  Future<List<app_category.Category>>? _categoriesFuture;

  late TextEditingController _nameController, _brandController, _descriptionController, _notesTopController, _notesMiddleController, _notesBaseController, _priceController, _quantityController, _price100mlController, _quantity100mlController, _customerProductNameController, _imageUrlController;
  
  String? _selectedCategoryName, _selectedScentFamily, _selectedSize;
  XFile? _pickedImage;
  List<XFile> _images50ml = [], _images100ml = [], _additionalImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false, _isFeatured = false, _isSlider = false;
  final List<String> _scentFamilies = ['Oriental', 'Fresh', 'Floral', 'Woody'], _sizes = ['50ml', '100ml', 'Both'];
  List<ProductVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _categoriesFuture = _apiService.fetchCategories();
  }

  void _initializeControllers() {
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _notesTopController = TextEditingController(text: p?.notesTop ?? '');
    _notesMiddleController = TextEditingController(text: p?.notesMiddle ?? '');
    _notesBaseController = TextEditingController(text: p?.notesBase ?? '');
    _priceController = TextEditingController(text: p?.price.toString() ?? '');
    _quantityController = TextEditingController(text: p?.quantity.toString() ?? '100');
    _price100mlController = TextEditingController(text: p?.price100ml?.toString() ?? '');
    _quantity100mlController = TextEditingController(text: p?.quantity100ml.toString() ?? '0');
    _customerProductNameController = TextEditingController(text: p?.customerProductName ?? '');
    _imageUrlController = TextEditingController();
    _selectedCategoryName = p?.category;
    _isFeatured = p?.isFeatured ?? false;
    _isSlider = p?.isSlider ?? false;
    if (p?.scentFamily != null && _scentFamilies.contains(p!.scentFamily)) _selectedScentFamily = p.scentFamily;
    if (p?.size != null && _sizes.contains(p!.size)) _selectedSize = p.size;
    if (p != null && p.variants.isNotEmpty) _variants = List.from(p.variants);
  }

  Future<void> _pickMulti(List<XFile> target) async {
    final List<XFile>? picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked != null) setState(() { target.addAll(picked); if (target.length > 4) target.removeRange(4, target.length); });
  }

  void _addVariant() { setState(() { _variants.add(ProductVariant(size: '', price: 0)); }); }
  void _removeVariant(int index) { setState(() { _variants.removeAt(index); }); }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      String variantsJson = jsonEncode(_variants.map((v) => v.toJson()).toList());
      if (widget.product == null) {
        await _apiService.addProduct(name: _nameController.text, description: _descriptionController.text, price: _priceController.text, category: _selectedCategoryName!, isFeatured: _isFeatured, isSlider: _isSlider, scentFamily: _selectedScentFamily, brand: _brandController.text, size: _selectedSize, quantity: _quantityController.text, notesTop: _notesTopController.text, notesMiddle: _notesMiddleController.text, notesBase: _notesBaseController.text, imageFile: _pickedImage, token: ApiService.authToken, customerProductName: _customerProductNameController.text, externalImageUrl: _imageUrlController.text, price100ml: _price100mlController.text, quantity100ml: _quantity100mlController.text, images50ml: _images50ml, images100ml: _images100ml, additionalImages: _additionalImages, variants: variantsJson);
      } else {
        await _apiService.updateProduct(id: widget.product!.id.toString(), name: _nameController.text, description: _descriptionController.text, price: _priceController.text, category: _selectedCategoryName!, isFeatured: _isFeatured, isSlider: _isSlider, scentFamily: _selectedScentFamily ?? '', brand: _brandController.text, size: _selectedSize ?? '', quantity: _quantityController.text, notesTop: _notesTopController.text, notesMiddle: _notesMiddleController.text, notesBase: _notesBaseController.text, imageFile: _pickedImage, token: ApiService.authToken, customerProductName: _customerProductNameController.text, externalImageUrl: _imageUrlController.text, price100ml: _price100mlController.text, quantity100ml: _quantity100mlController.text, images50ml: _images50ml, images100ml: _images100ml, additionalImages: _additionalImages, variants: variantsJson);
      }
      if (widget.onSave != null) widget.onSave!();
      Navigator.pop(context);
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)); }
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Product' : 'Add Product')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── IMAGE PORTIONS ──
          _buildVariantPortion("50ML IMAGES (PORTION 1)", _images50ml, widget.product?.images50ml, () {
            setState(() {
              _images50ml.clear();
              widget.product?.images50ml.clear();
            });
          }),
          const SizedBox(height: 20),
          _buildVariantPortion("100ML IMAGES (PORTION 2)", _images100ml, widget.product?.images100ml, () {
            setState(() {
              _images100ml.clear();
              widget.product?.images100ml.clear();
            });
          }),
          const SizedBox(height: 20),
          
          // ── GENERAL INFO ──
          _buildSectionTitle("BASIC INFORMATION"),
          _buildTextField(_nameController, "Product Name *", validator: (v) => v!.isEmpty ? "Name required" : null),
          _buildTextField(_brandController, "Brand *", validator: (v) => v!.isEmpty ? "Brand required" : null),
          _buildDropdown("Scent Family", _selectedScentFamily, _scentFamilies, (v) => setState(() => _selectedScentFamily = v)),
          _buildDropdown("Size Category", _selectedSize, _sizes, (v) => setState(() => _selectedSize = v)),
          _buildCategoryDropdown(),
          
          SwitchListTile(title: const Text("Featured Product"), value: _isFeatured, onChanged: (v) => setState(() => _isFeatured = v)),
          SwitchListTile(title: const Text("Show in Slider"), value: _isSlider, onChanged: (v) => setState(() => _isSlider = v)),
          
          const SizedBox(height: 20),
          _buildSectionTitle("PRICING & STOCK"),
          Row(children: [
            Expanded(child: _buildTextField(_priceController, "50ml Price *", kb: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_quantityController, "50ml Stock", kb: TextInputType.number)),
          ]),
          Row(children: [
            Expanded(child: _buildTextField(_price100mlController, "100ml Price", kb: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_quantity100mlController, "100ml Stock", kb: TextInputType.number)),
          ]),

          const SizedBox(height: 20),
          _buildVariantsSection(),

          const SizedBox(height: 20),
          _buildSectionTitle("DESCRIPTION & NOTES"),
          _buildTextField(_descriptionController, "Description *", max: 3),
          _buildTextField(_notesTopController, "Top Notes"),
          _buildTextField(_notesMiddleController, "Middle Notes"),
          _buildTextField(_notesBaseController, "Base Notes"),
          _buildTextField(_customerProductNameController, "Customer Product Name (Optional)"),
          _buildTextField(_imageUrlController, "External Image URL (Optional)"),

          const SizedBox(height: 30),
          ElevatedButton(onPressed: _submitForm, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(isEdit ? "UPDATE PRODUCT" : "CREATE PRODUCT")),
          const SizedBox(height: 50),
        ])),
      ),
    );
  }

  Widget _previewImgBox(XFile xFile, VoidCallback onRemove) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8),
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey[100],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb 
              ? Image.network(xFile.path, fit: BoxFit.cover) 
              : Image.file(File(xFile.path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantPortion(String title, List<XFile> current, List<String>? existing, VoidCallback onClearAll) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
          if (current.isNotEmpty || (existing != null && existing.isNotEmpty))
            TextButton(onPressed: onClearAll, child: const Text("Clear All", style: TextStyle(fontSize: 11, color: Colors.red))),
        ],
      ),
      const SizedBox(height: 8),
      GestureDetector(onTap: () => _pickMulti(current), child: Container(height: 80, width: double.infinity, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)), child: const Icon(Icons.add_a_photo, color: Colors.blue))),
      if (current.isNotEmpty || (existing != null && existing.isNotEmpty)) Padding(padding: const EdgeInsets.only(top: 10), child: SizedBox(height: 80, child: ListView(scrollDirection: Axis.horizontal, children: [
        ...current.asMap().entries.map((entry) => _previewImgBox(entry.value, () {
          setState(() => current.removeAt(entry.key));
        })),
        if (existing != null) ...existing.asMap().entries.map((entry) => _networkImgBox(entry.value, () {
          setState(() => existing.removeAt(entry.key));
        })),
      ])))
    ]);
  }

  Widget _networkImgBox(String url, VoidCallback onRemove) {
    if (url.isEmpty || url == "null") return const SizedBox.shrink();
    String? fullUrl = ApiService.toAbsoluteUrl(url);
    if (fullUrl == null || fullUrl.isEmpty) return const SizedBox.shrink();

    if (kDebugMode) debugPrint("DEBUG: Loading image for admin: $fullUrl");

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8), 
          width: 70, height: 70, 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), 
            border: Border.all(color: Colors.grey.shade300), 
            color: Colors.grey[100], // Background for visibility
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              fullUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 20, height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                if (kDebugMode) debugPrint("❌ ERROR loading image: $fullUrl - $error");
                return const Center(
                  child: Icon(Icons.broken_image, color: Colors.red, size: 24),
                );
              },
            ),
          ),
        ),
        Positioned(
          right: 0, top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionTitle(String t) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)));
  
  Widget _buildTextField(TextEditingController c, String l, {TextInputType kb = TextInputType.text, int max = 1, String? Function(String?)? validator}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: c, keyboardType: kb, maxLines: max, validator: validator, decoration: InputDecoration(labelText: l, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50)));

  Widget _buildDropdown(String l, String? v, List<String> items, ValueChanged<String?> onChanged) => Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<String>(value: v, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged, decoration: InputDecoration(labelText: l, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50)));

  Widget _buildCategoryDropdown() => FutureBuilder<List<app_category.Category>>(future: _categoriesFuture, builder: (context, snap) {
    if (!snap.hasData) return const LinearProgressIndicator();
    String? safeValue = snap.data!.any((c) => c.name == _selectedCategoryName) ? _selectedCategoryName : null;
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<String>(value: safeValue, items: snap.data!.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(), onChanged: (v) => setState(() => _selectedCategoryName = v), decoration: InputDecoration(labelText: "Category *", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey.shade50)));
  });

  Widget _buildVariantsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("ADDITIONAL VARIANTS", style: TextStyle(fontWeight: FontWeight.bold)),
        TextButton.icon(onPressed: _addVariant, icon: const Icon(Icons.add), label: const Text("Add Size"))
      ]),
      ..._variants.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        Expanded(child: TextFormField(initialValue: entry.value.size, decoration: const InputDecoration(labelText: "Size"), onChanged: (v) => _variants[entry.key] = ProductVariant(size: v, price: entry.value.price))),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(initialValue: entry.value.price.toString(), decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number, onChanged: (v) => _variants[entry.key] = ProductVariant(size: entry.value.size, price: double.tryParse(v) ?? 0))),
        IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _removeVariant(entry.key))
      ])))
    ]);
  }
}
