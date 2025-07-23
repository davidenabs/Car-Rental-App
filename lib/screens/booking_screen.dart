import 'package:car_rental_app/main.dart';
import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  BookingScreen({required this.vehicle});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  // Form controllers for vehicle details
  final _licenseNumberController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _plateNumberController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int get _totalDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  num get _totalCost {
    return _totalDays * (widget.vehicle['price_per_day'] ?? 0);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _makeBooking() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all vehicle details')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.from('bookings').insert({
        'user_id': supabase.auth.currentUser!.id,
        'vehicle_id': widget.vehicle['id'],
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'total_cost': _totalCost,
        'status': 'pending',
        'license_number': _licenseNumberController.text.trim(),
        'plate_number': _plateNumberController.text.trim(),
        'color': _colorController.text.trim(),
        'year': int.tryParse(_yearController.text.trim()) ?? 0,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking created successfully!')));
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create booking: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Vehicle'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Header Card
              Card(
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.vehicle['brand']} ${widget.vehicle['model']}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '₦${widget.vehicle['price_per_day']}/day',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Vehicle Details Input Section
              Text(
                'Vehicle Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              Card(
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _licenseNumberController,
                        label: 'License Number',
                        hint: 'Enter vehicle license number',
                        icon: Icons.assignment,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'License number is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _plateNumberController,
                        label: 'Plate Number',
                        hint: 'Enter vehicle plate number',
                        icon: Icons.confirmation_number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Plate number is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _colorController,
                              label: 'Color',
                              hint: 'e.g., Black, White',
                              icon: Icons.palette,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Color is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _yearController,
                              label: 'Year',
                              hint: 'e.g., 2022',
                              icon: Icons.calendar_today,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Year is required';
                                }
                                final year = int.tryParse(value.trim());
                                if (year == null ||
                                    year < 1900 ||
                                    year > DateTime.now().year + 1) {
                                  return 'Enter valid year';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              Text(
                'Select Rental Period',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // Date Selection
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start Date'),
                            SizedBox(height: 8),
                            Text(
                              _startDate == null
                                  ? 'Select date'
                                  : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _startDate == null ? Colors.grey : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('End Date'),
                            SizedBox(height: 8),
                            Text(
                              _endDate == null
                                  ? 'Select date'
                                  : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _endDate == null ? Colors.grey : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Cost Summary
              if (_totalDays > 0) ...[
                Card(
                  color: Colors.white,
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Summary',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text('Total Days'), Text('$_totalDays')],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Price per day'),
                            Text('₦${widget.vehicle['price_per_day']}'),
                          ],
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Cost',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₦${_totalCost.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _makeBooking,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Confirm Booking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
