import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:backdrop/backdrop.dart';
import 'dart:io';
import '../models/project.dart';
import '../screens/pdf_viewer_screen.dart'; // Import the PDF Viewer screen

class InvoiceTab extends StatefulWidget {
  final Project project;

  const InvoiceTab({required this.project, super.key});

  @override
  InvoiceTabState createState() => InvoiceTabState();
}

class InvoiceTabState extends State<InvoiceTab> {
  List<File> _invoices = [];
  late Box<String> invoiceBox;
  late Box<Map> projectDetailsBox;

  final _formKey = GlobalKey<FormState>();
  String _fromAddress = '';
  String _billTo = '';
  String _shipTo = '';
  String _clientName = ''; // Client's name field
  String _freelancerName = ''; // Freelancer's name for signature
  final List<Map<String, dynamic>> _tasks = []; // Task list
  double _subtotal = 0.0;
  double _tax = 0.0;
  double _total = 0.0;
  int _editingTaskIndex = -1; // Track the index of the task being edited

  // Task form controllers
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController();
  final _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeInvoices();
    _loadSavedInvoiceDetails();
  }

  Future<void> _initializeInvoices() async {
    final appDir = await getApplicationDocumentsDirectory();
    final invoiceDir = Directory('${appDir.path}/invoices');
    if (!await invoiceDir.exists()) {
      await invoiceDir.create();
    }

    // Load existing invoices (file paths) from Hive
    invoiceBox = await Hive.openBox<String>('invoices_${widget.project.name}');
    if (mounted) {
      setState(() {
        _invoices = invoiceBox.values.map((filePath) => File(filePath)).toList();
      });
    }
  }

  Future<void> _loadSavedInvoiceDetails() async {
    projectDetailsBox = await Hive.openBox<Map>('project_details');
    final savedDetails = projectDetailsBox.get(widget.project.name);
    if (savedDetails != null && mounted) {
      setState(() {
        _fromAddress = savedDetails['fromAddress'] ?? '';
        _billTo = savedDetails['billTo'] ?? '';
        _shipTo = savedDetails['shipTo'] ?? '';
        _clientName = savedDetails['clientName'] ?? ''; // Load client name
        _freelancerName = savedDetails['freelancerName'] ?? '';
      });
    }
  }

  Future<void> _saveInvoiceDetails() async {
    final details = {
      'fromAddress': _fromAddress,
      'billTo': _billTo,
      'shipTo': _shipTo,
      'clientName': _clientName, // Save client name
      'freelancerName': _freelancerName,
    };
    await projectDetailsBox.put(widget.project.name, details);
  }

  // Generate and save a new invoice PDF
  Future<void> _generateInvoice() async {
    await _saveInvoiceDetails(); // Save common invoice details before generating

    final pdf = pw.Document();

    // Calculate the subtotal, tax, and total
    _subtotal = _tasks.fold(0.0, (sum, task) => sum + (task['hours'] * task['rate']));
    _tax = _subtotal * 0.0625; // 6.25% sales tax
    _total = _subtotal + _tax;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(16.0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Invoice header with From Address and Invoice number
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FROM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(_fromAddress),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Invoice #: US-001'),
                        pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Client information
                pw.Text('BILL TO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(_billTo),
                pw.SizedBox(height: 10),
                pw.Text('SHIP TO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(_shipTo),
                pw.SizedBox(height: 20),

                // Client Name and Tasks Table
                pw.Text('CLIENT NAME: $_clientName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headers: ['Task Description', 'Hours Worked', 'Rate (per hour)', 'Amount'],
                  data: _tasks.map((task) {
                    final taskAmount = task['hours'] * task['rate'];
                    return [
                      task['description'],
                      task['hours'].toString(),
                      '\$${task['rate'].toStringAsFixed(2)}',
                      '\$${taskAmount.toStringAsFixed(2)}',
                    ];
                  }).toList(),
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellPadding: const pw.EdgeInsets.all(8.0),
                ),
                pw.SizedBox(height: 20),

                // Summary with subtotal, tax, and total
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: \$${_subtotal.toStringAsFixed(2)}'),
                      pw.Text('Sales Tax (6.25%): \$${_tax.toStringAsFixed(2)}'),
                      pw.Text(
                        'Total: \$${_total.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Freelancer's signature
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Freelancer: $_freelancerName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );

    final appDir = await getApplicationDocumentsDirectory();
    final invoiceDir = Directory('${appDir.path}/invoices');
    final file = File('${invoiceDir.path}/invoice_${widget.project.name}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await invoiceBox.add(file.path);

    if (mounted) {
      setState(() {
        _invoices.add(file);
      });

      // Navigate to the PDF viewer screen to display the generated invoice
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PDFViewerScreen(filePath: file.path)),
      );
    }
  }

  // Add or update a task in the invoice
  void _addOrUpdateTask() {
    if (_hoursController.text.isNotEmpty && _rateController.text.isNotEmpty) {
      if (_editingTaskIndex == -1) {
        _addTask();
      } else {
        _updateTask(_editingTaskIndex);
      }
    }
  }

  // Add a new task
  void _addTask() {
    setState(() {
      _tasks.add({
        'description': _descriptionController.text,
        'hours': double.parse(_hoursController.text),
        'rate': double.parse(_rateController.text),
      });
      _clearTaskForm();
    });
  }

  // Edit an existing task
  void _editTask(int index) {
    setState(() {
      _editingTaskIndex = index;
      _descriptionController.text = _tasks[index]['description'];
      _hoursController.text = _tasks[index]['hours'].toString();
      _rateController.text = _tasks[index]['rate'].toString();
    });
  }

  // Update an existing task
  void _updateTask(int index) {
    setState(() {
      _tasks[index] = {
        'description': _descriptionController.text,
        'hours': double.parse(_hoursController.text),
        'rate': double.parse(_rateController.text),
      };
      _editingTaskIndex = -1;
      _clearTaskForm();
    });
  }

  // Delete a task
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  // Clear the task form
  void _clearTaskForm() {
    _descriptionController.clear();
    _hoursController.clear();
    _rateController.clear();
    _editingTaskIndex = -1;
  }

  Future<void> _deleteInvoice(int index) async {
    final file = _invoices[index];
    await file.delete();
    await invoiceBox.deleteAt(index);
    if (mounted) {
      setState(() {
        _invoices.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropScaffold(
      appBar: BackdropAppBar(
        title: const Text("Invoice Generator",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
        backgroundColor: const Color(0xFF6750A4),
        leading: const BackdropToggleButton(
          color: Colors.white, // Menu and Close icons color set to black
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the leading icon color to black
        ),
      ),
      resizeToAvoidBottomInset: true, // Allow screen resizing when keyboard appears
      backLayer: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Invoice Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: _fromAddress,
                      decoration: const InputDecoration(
                        labelText: 'From Address',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onSaved: (value) => _fromAddress = value!,
                      validator: (value) => value!.isEmpty ? 'Please enter the sender\'s address' : null,
                    ),
                    TextFormField(
                      initialValue: _billTo,
                      decoration: const InputDecoration(
                        labelText: 'Bill To',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onSaved: (value) => _billTo = value!,
                      validator: (value) => value!.isEmpty ? 'Please enter the bill to address' : null,
                    ),
                    TextFormField(
                      initialValue: _shipTo,
                      decoration: const InputDecoration(
                        labelText: 'Ship To',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onSaved: (value) => _shipTo = value!,
                      validator: (value) => value!.isEmpty ? 'Please enter the ship to address' : null,
                    ),
                    TextFormField(
                      initialValue: _clientName,
                      decoration: const InputDecoration(
                        labelText: 'Client Name',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onSaved: (value) => _clientName = value!,
                      validator: (value) => value!.isEmpty ? 'Please enter the client name' : null,
                    ),
                    TextFormField(
                      initialValue: _freelancerName,
                      decoration: const InputDecoration(
                        labelText: 'Freelancer Name (Signature)',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onSaved: (value) => _freelancerName = value!,
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add or Edit Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Task Description',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _hoursController,
                      decoration: const InputDecoration(
                        labelText: 'Hours Worked',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      decoration: const InputDecoration(
                        labelText: 'Rate (per hour)',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: _editingTaskIndex == -1
                        ? const Icon(Icons.add, color: Colors.white)
                        : const Icon(Icons.save, color: Colors.green),
                    onPressed: _addOrUpdateTask,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _tasks.isNotEmpty
                  ? Column(
                children: List.generate(
                  _tasks.length,
                      (index) {
                    return ListTile(
                      title: Text(
                        _tasks[index]['description'],
                        style: const TextStyle(color: Colors.white), // White text for title
                      ),
                      subtitle: Text(
                        'Hours: ${_tasks[index]['hours']} - Rate: \$${_tasks[index]['rate']}',
                        style: const TextStyle(color: Colors.white70), // White70 text for subtitle
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () => _editTask(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => _deleteTask(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )

                  : const Text(
                'No tasks added yet.',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _generateInvoice();
                  }
                },
                child: const Text('Generate Invoice'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      frontLayer: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _invoices.isEmpty
            ? const Center(child: Text('No invoices generated yet.'))
            : ListView.builder(
          itemCount: _invoices.length,
          itemBuilder: (context, index) {
            final invoice = _invoices[index];
            return ListTile(
              title: Text(invoice.uri.pathSegments.last),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () => _deleteInvoice(index),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PDFViewerScreen(filePath: invoice.path)),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
