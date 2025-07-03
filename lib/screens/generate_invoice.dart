import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'invoice.dart';

class GenerateInvoiceScreen extends StatefulWidget {
  const GenerateInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<GenerateInvoiceScreen> createState() => _GenerateInvoiceScreenState();
}

class _GenerateInvoiceScreenState extends State<GenerateInvoiceScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Controllers
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _productController = TextEditingController();
  
  // Variables
  String _queryId = '';
  String _warrantyStatus = 'Before';
  List<Map<String, dynamic>> _selectedProducts = [];
  bool _showProductSuggestions = false;
  bool _isGenerating = false;
  
  // Sample product database
  final Map<String, double> _products = {
    'Apple iPhone 15': 999.99,
    'Apple MacBook Pro': 2499.99,
    'Apple AirPods Pro': 249.99,
    'Android Samsung Galaxy': 899.99,
    'Bluetooth Speaker': 99.99,
    'Wireless Headphones': 199.99,
    'Laptop Stand': 49.99,
    'USB-C Cable': 19.99,
    'Power Bank': 79.99,
    'Screen Protector': 15.99,
  };
  
  List<String> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _generateQueryId();
    _productController.addListener(_onProductTextChanged);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _companyNameController.dispose();
    _productController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _generateQueryId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    final input = 'INV-$timestamp-$random';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    _queryId = 'QID-${digest.toString().substring(0, 12).toUpperCase()}';
  }

  void _onProductTextChanged() {
    final query = _productController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _showProductSuggestions = false;
        _filteredProducts = [];
      });
      return;
    }

    setState(() {
      _filteredProducts = _products.keys
          .where((product) => product.toLowerCase().contains(query))
          .toList();
      _showProductSuggestions = _filteredProducts.isNotEmpty;
    });
  }

  void _addProduct(String productName) {
    final price = _products[productName]!;
    
    // Check if product already exists
    final existingIndex = _selectedProducts.indexWhere(
      (product) => product['name'] == productName
    );
    
    if (existingIndex != -1) {
      // Increase quantity if product already exists
      setState(() {
        _selectedProducts[existingIndex]['quantity']++;
      });
    } else {
      // Add new product
      setState(() {
        _selectedProducts.add({
          'name': productName,
          'price': price,
          'quantity': 1,
        });
      });
    }
    
    _productController.clear();
    setState(() {
      _showProductSuggestions = false;
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
  }

  void _updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _removeProduct(index);
    } else {
      setState(() {
        _selectedProducts[index]['quantity'] = quantity;
      });
    }
  }

  double _calculateSubtotal() {
    return _selectedProducts.fold(0.0, (sum, product) => 
      sum + (product['price'] * product['quantity'])
    );
  }

  Future<void> _generateInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProducts.isEmpty) {
      _showCustomSnackBar('Please add at least one product', Colors.orange);
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final invoiceData = InvoiceData(
        queryId: _queryId,
        customerName: _customerNameController.text.trim(),
        customerAddress: _customerAddressController.text.trim(),
        companyName: _companyNameController.text.trim(),
        products: _selectedProducts,
        warrantyStatus: _warrantyStatus,
        generatedDate: DateTime.now(),
      );

      // Generate PDF
      final invoiceGenerator = InvoiceGenerator();
      await invoiceGenerator.generatePDF(invoiceData);

      // Save to MongoDB
      await _saveInvoiceToDatabase(invoiceData);

      _showCustomSnackBar('Invoice generated and saved successfully!', Colors.green);

      // Clear form after successful generation
      _clearForm();
    } catch (e) {
      _showCustomSnackBar('Error generating invoice: $e', Colors.red);
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _saveInvoiceToDatabase(InvoiceData invoiceData) async {
    const String apiUrl = 'http://localhost:3000/api/invoices';
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'queryId': invoiceData.queryId,
          'customerName': invoiceData.customerName,
          'customerAddress': invoiceData.customerAddress,
          'companyName': invoiceData.companyName,
          'products': invoiceData.products,
          'warrantyStatus': invoiceData.warrantyStatus,
          'generatedDate': invoiceData.generatedDate.toIso8601String(),
          'subtotal': _calculateSubtotal(),
          'taxAmount': _calculateSubtotal() * 0.10,
          'total': _calculateSubtotal() * 1.10,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to save invoice: ${response.body}');
      }
    } catch (e) {
      print('Error saving to database: $e');
      throw Exception('Failed to save invoice to database');
    }
  }

  void _clearForm() {
    _customerNameController.clear();
    _customerAddressController.clear();
    _companyNameController.clear();
    _productController.clear();
    _selectedProducts.clear();
    _generateQueryId();
    setState(() {
      _warrantyStatus = 'Before';
      _showProductSuggestions = false;
    });
  }

  void _showCustomSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : 
              color == Colors.red ? Icons.error : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1e3c72),
              Color(0xFF2a5298),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  // Custom App Bar
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text(
                        'Generate Invoice',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      centerTitle: true,
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Query ID Card
                            _buildGlassCard(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.tag,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Query ID',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _queryId,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Customer Details Card
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Customer Details',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  _buildCustomTextField(
                                    controller: _customerNameController,
                                    label: 'Customer Name *',
                                    icon: Icons.person,
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Please enter customer name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  _buildCustomTextField(
                                    controller: _customerAddressController,
                                    label: 'Customer Address *',
                                    icon: Icons.location_on,
                                    maxLines: 3,
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Please enter customer address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  _buildCustomTextField(
                                    controller: _companyNameController,
                                    label: 'Company Name *',
                                    icon: Icons.business,
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Please enter company name';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Products Card
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Products',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Product Search
                                  Column(
                                    children: [
                                      _buildCustomTextField(
                                        controller: _productController,
                                        label: 'Search Products',
                                        icon: Icons.search,
                                        hint: 'Start typing to search products...',
                                      ),
                                      
                                      if (_showProductSuggestions) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          constraints: const BoxConstraints(maxHeight: 200),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.2),
                                            ),
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: _filteredProducts.length,
                                            itemBuilder: (context, index) {
                                              final product = _filteredProducts[index];
                                              final price = _products[product]!;
                                              return ListTile(
                                                title: Text(
                                                  product,
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                                subtitle: Text(
                                                  '\$${price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.7),
                                                  ),
                                                ),
                                                trailing: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.add_circle,
                                                      color: Colors.green,
                                                    ),
                                                    onPressed: () => _addProduct(product),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  // Selected Products
                                  if (_selectedProducts.isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    Text(
                                      'Selected Products',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      constraints: const BoxConstraints(maxHeight: 300),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: _selectedProducts.length,
                                        itemBuilder: (context, index) {
                                          final product = _selectedProducts[index];
                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                product['name'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '\$${product['price'].toStringAsFixed(2)} each',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.7),
                                                ),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.remove_circle,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () => _updateQuantity(
                                                      index,
                                                      product['quantity'] - 1,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '${product['quantity']}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.add_circle,
                                                      color: Colors.green,
                                                    ),
                                                    onPressed: () => _updateQuantity(
                                                      index,
                                                      product['quantity'] + 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Total Summary
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.2),
                                            Colors.white.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Subtotal:',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                '\$${_calculateSubtotal().toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Tax (10%):',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                '\$${(_calculateSubtotal() * 0.10).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                            child: Divider(color: Colors.white38),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Total:',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '\$${(_calculateSubtotal() * 1.10).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Warranty Status Card
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_user_outlined,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Warranty Status',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _warrantyStatus == 'Before'
                                                ? Colors.white.withOpacity(0.2)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                            ),
                                          ),
                                          child: RadioListTile<String>(
                                            title: const Text(
                                              'Before Warranty',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                            value: 'Before',
                                            groupValue: _warrantyStatus,
                                            onChanged: (value) {
                                              setState(() {
                                                _warrantyStatus = value!;
                                              });
                                            },
                                            activeColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _warrantyStatus == 'After'
                                                ? Colors.white.withOpacity(0.2)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                            ),
                                          ),
                                          child: RadioListTile<String>(
                                            title: const Text(
                                              'After Warranty',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                            value: 'After',
                                            groupValue: _warrantyStatus,
                                            onChanged: (value) {
                                              setState(() {
                                                _warrantyStatus = value!;
                                              });
                                            },
                                            activeColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Action Buttons
                            Column(
                              children: [
                                // Generate Invoice Button
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.white, Colors.white70],
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _isGenerating ? null : _generateInvoice,
                                    icon: _isGenerating 
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Color(0xFF1e3c72),
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.picture_as_pdf),
                                    label: Text(
                                      _isGenerating ? 'Generating...' : 'Generate Invoice',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: const Color(0xFF1e3c72),
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Clear Form Button
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: OutlinedButton.icon(
                                    onPressed: _clearForm,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Clear Form'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}