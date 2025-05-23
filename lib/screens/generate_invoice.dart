import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'invoice.dart';

class GenerateInvoiceScreen extends StatefulWidget {
  const GenerateInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<GenerateInvoiceScreen> createState() => _GenerateInvoiceScreenState();
}

class _GenerateInvoiceScreenState extends State<GenerateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _productController = TextEditingController();
  
  // Variables
  String _queryId = '';
  String _warrantyStatus = 'Before';
  Map<String, double> _selectedProduct = {};
  bool _showProductSuggestions = false;
  
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
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _companyNameController.dispose();
    _productController.dispose();
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

  void _selectProduct(String productName) {
    _productController.text = productName;
    _selectedProduct = {productName: _products[productName]!};
    setState(() {
      _showProductSuggestions = false;
    });
  }

  Future<void> _generateInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProduct.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid product')),
      );
      return;
    }

    try {
      final invoiceData = InvoiceData(
        queryId: _queryId,
        customerName: _customerNameController.text.trim(),
        customerAddress: _customerAddressController.text.trim(),
        companyName: _companyNameController.text.trim(),
        productName: _selectedProduct.keys.first,
        productPrice: _selectedProduct.values.first,
        warrantyStatus: _warrantyStatus,
        generatedDate: DateTime.now(),
      );

      final invoiceGenerator = InvoiceGenerator();
      await invoiceGenerator.generatePDF(invoiceData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice generated and downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form after successful generation
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _customerNameController.clear();
    _customerAddressController.clear();
    _companyNameController.clear();
    _productController.clear();
    _selectedProduct.clear();
    _generateQueryId();
    setState(() {
      _warrantyStatus = 'Before';
      _showProductSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Invoice'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice Details',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Query ID (Auto-generated, read-only)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.tag, color: Colors.blueAccent),
                              const SizedBox(width: 8),
                              Text(
                                'Query ID: $_queryId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Customer Name
                        TextFormField(
                          controller: _customerNameController,
                          decoration: const InputDecoration(
                            labelText: 'Customer Name *',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Please enter customer name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Customer Address
                        TextFormField(
                          controller: _customerAddressController,
                          decoration: const InputDecoration(
                            labelText: 'Customer Address *',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Please enter customer address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Company Name
                        TextFormField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Company Name *',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Please enter company name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Product Name with Auto-complete
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _productController,
                              decoration: const InputDecoration(
                                labelText: 'Product Name *',
                                prefixIcon: Icon(Icons.inventory),
                                border: OutlineInputBorder(),
                                hintText: 'Start typing to search products...',
                              ),
                              validator: (value) {
                                if (_selectedProduct.isEmpty) {
                                  return 'Please select a valid product';
                                }
                                return null;
                              },
                            ),
                            if (_showProductSuggestions) ...[
                              const SizedBox(height: 4),
                              Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = _filteredProducts[index];
                                    final price = _products[product]!;
                                    return ListTile(
                                      title: Text(product),
                                      subtitle: Text('\$${price.toStringAsFixed(2)}'),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () => _selectProduct(product),
                                      dense: true,
                                    );
                                  },
                                ),
                              ),
                            ],
                            if (_selectedProduct.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Selected: ${_selectedProduct.keys.first} - \$${_selectedProduct.values.first.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Warranty Status
                        Text(
                          'Warranty Status',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Before Warranty'),
                                value: 'Before',
                                groupValue: _warrantyStatus,
                                onChanged: (value) {
                                  setState(() {
                                    _warrantyStatus = value!;
                                  });
                                },
                                activeColor: Colors.blueAccent,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('After Warranty'),
                                value: 'After',
                                groupValue: _warrantyStatus,
                                onChanged: (value) {
                                  setState(() {
                                    _warrantyStatus = value!;
                                  });
                                },
                                activeColor: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Generate Invoice Button
                ElevatedButton.icon(
                  onPressed: _generateInvoice,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Clear Form Button
                OutlinedButton.icon(
                  onPressed: _clearForm,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Form'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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