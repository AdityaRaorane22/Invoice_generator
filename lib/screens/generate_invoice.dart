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
  List<Map<String, dynamic>> _selectedProducts = [];
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice generated and saved successfully!'),
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

  Future<void> _saveInvoiceToDatabase(InvoiceData invoiceData) async {
    const String apiUrl = 'http://localhost:3000/api/invoices'; // Replace with your backend URL
    
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
                                labelText: 'Add Products *',
                                prefixIcon: Icon(Icons.inventory),
                                border: OutlineInputBorder(),
                                hintText: 'Start typing to search and add products...',
                              ),
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
                                      trailing: IconButton(
                                        icon: const Icon(Icons.add_circle, color: Colors.green),
                                        onPressed: () => _addProduct(product),
                                      ),
                                      dense: true,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Selected Products List
                        if (_selectedProducts.isNotEmpty) ...[
                          Text(
                            'Selected Products',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _selectedProducts.length,
                              itemBuilder: (context, index) {
                                final product = _selectedProducts[index];
                                return ListTile(
                                  title: Text(product['name']),
                                  subtitle: Text('\$${product['price'].toStringAsFixed(2)} each'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, color: Colors.red),
                                        onPressed: () => _updateQuantity(index, product['quantity'] - 1),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${product['quantity']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, color: Colors.green),
                                        onPressed: () => _updateQuantity(index, product['quantity'] + 1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeProduct(index),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Total Summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                                    Text('\$${_calculateSubtotal().toStringAsFixed(2)}', 
                                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tax (10%):', style: TextStyle(fontSize: 16)),
                                    Text('\$${(_calculateSubtotal() * 0.10).toStringAsFixed(2)}', 
                                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text('\$${(_calculateSubtotal() * 1.10).toStringAsFixed(2)}', 
                                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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