import 'dart:io';
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
  final _scrollController = ScrollController();

  Future<List<app_category.Category>>? _categoriesFuture;

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesTopController;
  late TextEditingController _notesMiddleController;
  late TextEditingController _notesBaseController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  
  // Naya Fields
  late TextEditingController _customerProductNameController;
  late TextEditingController _imageUrlController;
  
  String? _selectedCategoryName;
  String? _selectedScentFamily;
  String? _selectedSize;
  
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isFeatured = false;

  final List<String> _scentFamilies = ['Oriental', 'Fresh', 'Floral', 'Woody'];
  final List<String> _sizes = ['50ml', '100ml'];

  // ================ RESPONSIVE UTILITIES ================
  bool get _isMobile => MediaQuery.of(context).size.width < 600;
  
  double get _screenPadding => _isMobile ? 16 : 24;
  double get _fieldSpacing => _isMobile ? 12 : 16;
  double get _sectionSpacing => _isMobile ? 20 : 28;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _categoriesFuture = _apiService.fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _notesTopController.dispose();
    _notesMiddleController.dispose();
    _notesBaseController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _customerProductNameController.dispose();
    _imageUrlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    final product = widget.product;
    
    _nameController = TextEditingController(text: product?.name ?? '');
    _brandController = TextEditingController(text: product?.brand ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _notesTopController = TextEditingController(text: product?.notesTop ?? '');
    _notesMiddleController = TextEditingController(text: product?.notesMiddle ?? '');
    _notesBaseController = TextEditingController(text: product?.notesBase ?? '');
    _priceController = TextEditingController(text: product?.price.toString() ?? '');
    _quantityController = TextEditingController(text: product?.quantity.toString() ?? '100');
    
    _customerProductNameController = TextEditingController(); // Optional, usually empty for new
    _imageUrlController = TextEditingController();     // Optional URL field
    
    _selectedCategoryName = product?.category;
    _isFeatured = product?.isFeatured ?? false;
    
    // Set dropdown values if they match options
    if (product?.scentFamily != null && _scentFamilies.contains(product!.scentFamily)) {
      _selectedScentFamily = product.scentFamily;
    }
    
    if (product?.size != null && _sizes.contains(product!.size)) {
      _selectedSize = product.size;
    } else if (product?.size != null && product!.size!.isNotEmpty) {
       // If existing size is not in 50ml/100ml, we might need to handle it, 
       // but user specifically asked for these two options.
    }
  }

  void _reloadCategories() {
    setState(() {
      _categoriesFuture = _apiService.fetchCategories();
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryName == null) {
      _showErrorSnackbar('Please select a category');
      return;
    }

    // Required image check (either picked, or existing, or URL provided)
    if (widget.product == null && _pickedImage == null && _imageUrlController.text.isEmpty) {
      _showErrorSnackbar('Please upload an image or enter an image URL');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String token = ApiService.authToken ?? "YOUR_TEST_TOKEN";

      // Note: customer_name and direct_image_url might need backend support,
      // for now we pass them in the request.
      
      if (widget.product == null) {
        await _apiService.addProduct(
          name: _nameController.text,
          description: _descriptionController.text,
          price: _priceController.text,
          category: _selectedCategoryName!,
          isFeatured: _isFeatured,
          scentFamily: _selectedScentFamily ?? '',
          brand: _brandController.text,
          size: _selectedSize ?? '',
          quantity: _quantityController.text,
          notesTop: _notesTopController.text,
          notesMiddle: _notesMiddleController.text,
          notesBase: _notesBaseController.text,
          imageFile: _pickedImage,
          token: token,
          customerProductName: _customerProductNameController.text,
          externalImageUrl: _imageUrlController.text,
        );
      } else {
        await _apiService.updateProduct(
          id: widget.product!.id.toString(),
          name: _nameController.text,
          description: _descriptionController.text,
          price: _priceController.text,
          category: _selectedCategoryName!,
          isFeatured: _isFeatured,
          scentFamily: _selectedScentFamily ?? '',
          brand: _brandController.text,
          size: _selectedSize ?? '',
          quantity: _quantityController.text,
          notesTop: _notesTopController.text,
          notesMiddle: _notesMiddleController.text,
          notesBase: _notesBaseController.text,
          imageFile: _pickedImage,
          token: token,
          customerProductName: _customerProductNameController.text,
          externalImageUrl: _imageUrlController.text,
        );
      }

      if (widget.onSave != null) widget.onSave!();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.product != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(_screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================ IMAGES SECTION ================
                    _buildSectionTitle('Product Image'),
                    SizedBox(height: _fieldSpacing),
                    _buildImagePicker(isEdit),
                    SizedBox(height: _fieldSpacing),
                    _buildTextField(
                      controller: _imageUrlController,
                      label: 'Enter Image URL (Optional)',
                      hintText: 'https://example.com/image.jpg',
                    ),

                    SizedBox(height: _sectionSpacing),

                    // ================ CORE FIELDS ================
                    _buildSectionTitle('General Information'),
                    SizedBox(height: _fieldSpacing),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Product Name *',
                      validator: (v) => v!.isEmpty ? 'Name required' : null,
                    ),
                    SizedBox(height: _fieldSpacing),
                    _buildTextField(
                      controller: _brandController,
                      label: 'Brand *',
                      validator: (v) => v!.isEmpty ? 'Brand required' : null,
                    ),
                    SizedBox(height: _fieldSpacing),
                    _buildDropdown(
                      label: 'Scent Family *',
                      value: _selectedScentFamily,
                      items: _scentFamilies,
                      onChanged: (v) => setState(() => _selectedScentFamily = v),
                    ),
                    SizedBox(height: _fieldSpacing),
                    _buildDropdown(
                      label: 'Size *',
                      value: _selectedSize,
                      items: _sizes,
                      onChanged: (v) => setState(() => _selectedSize = v),
                    ),
                    SizedBox(height: _fieldSpacing),
                    _buildCategoryDropdown(),

                    SizedBox(height: _sectionSpacing),

                    // ================ FEATURED TOGGLE ================
                    SwitchListTile(
                      title: const Text('Featured Product', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Show on Home Page if ON, else only in Shop'),
                      value: _isFeatured,
                      onChanged: (v) => setState(() => _isFeatured = v),
                      activeColor: theme.primaryColor,
                    ),

                    SizedBox(height: _sectionSpacing),

                    // ================ ADDITIONAL INFO ================
                    _buildSectionTitle('Details & Notes'),
                    SizedBox(height: _fieldSpacing),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description *',
                      maxLines: 3,
                      validator: (v) => v!.isEmpty ? 'Description required' : null,
                    ),
                    SizedBox(height: _fieldSpacing),
                    _buildTextField(controller: _notesTopController, label: 'Top Notes'),
                    SizedBox(height: _fieldSpacing),
                    _buildTextField(controller: _notesMiddleController, label: 'Middle Notes'),
                    SizedBox(height: _fieldSpacing),
                    _buildTextField(controller: _notesBaseController, label: 'Base Notes'),
                    
                    SizedBox(height: _fieldSpacing),
                    _buildTextField(
                      controller: _customerProductNameController,
                      label: 'Customer Product Name (Optional)',
                    ),

                    SizedBox(height: _sectionSpacing),

                    // ================ PRICING & STOCK ================
                    _buildSectionTitle('Inventory'),
                    SizedBox(height: _fieldSpacing),
                    _buildTextField(
                      controller: _priceController,
                      label: 'Price *',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Price required' : null,
                    ),
                    SizedBox(height: _fieldSpacing),
                    _buildTextField(
                      controller: _quantityController,
                      label: 'Quantity',
                      keyboardType: TextInputType.number,
                    ),

                    SizedBox(height: _sectionSpacing * 2),
                    
                    _buildSubmitButton(isEdit),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selection required' : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<app_category.Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final categories = snapshot.data!;
        return DropdownButtonFormField<String>(
          value: _selectedCategoryName,
          decoration: InputDecoration(
            labelText: 'Category *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
          onChanged: (v) => setState(() => _selectedCategoryName = v),
          validator: (v) => v == null ? 'Category required' : null,
        );
      },
    );
  }

  Widget _buildImagePicker(bool isEdit) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _pickedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb ? Image.network(_pickedImage!.path, fit: BoxFit.cover) : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
              )
            : (isEdit && widget.product!.imageUrl.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(ApiService.toAbsoluteUrl(widget.product!.imageUrl)!, fit: BoxFit.cover),
                  )
                : const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to upload image', style: TextStyle(color: Colors.grey)),
                    ],
                  )),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { Navigator.pop(context); _pickImage(); }),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () { Navigator.pop(context); _takePhoto(); }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isEdit) {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(isEdit ? 'Update Product' : 'Create Product', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
