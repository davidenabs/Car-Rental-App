import 'package:car_rental_app/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const BookingScreen({super.key, required this.vehicle});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _selectedColor;

  // Form field controllers
  final _driverLicenseController = TextEditingController();
  final _ninController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedState;

  // Paystack plugin
  // final _paystack = PaystackPlugin();
  final _uuid = Uuid();

  // List of Nigerian states
  final List<String> _nigerianStates = [
    'Abia',
    'Adamawa',
    'Akwa Ibom',
    'Anambra',
    'Bauchi',
    'Bayelsa',
    'Benue',
    'Borno',
    'Cross River',
    'Delta',
    'Ebonyi',
    'Edo',
    'Ekiti',
    'Enugu',
    'Gombe',
    'Imo',
    'Jigawa',
    'Kaduna',
    'Kano',
    'Katsina',
    'Kebbi',
    'Kogi',
    'Kwara',
    'Lagos',
    'Nasarawa',
    'Niger',
    'Ogun',
    'Ondo',
    'Osun',
    'Oyo',
    'Plateau',
    'Rivers',
    'Sokoto',
    'Taraba',
    'Yobe',
    'Zamfara',
    'FCT',
  ];

  int get _totalDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  num get _totalCost {
    return _totalDays * (widget.vehicle['price_per_day'] ?? 0);
  }

  // Paystack amount in kobo
  int get _totalCostInKobo {
    return (_totalCost * 100).toInt();
  }

  @override
  void initState() {
    super.initState();
    _fullNameController.text =
        supabase.auth.currentUser!.userMetadata?['full_name'] ?? '';
    _emailController.text = supabase.auth.currentUser!.email ?? '';
    // Initialize Paystack
    // _paystack.initialize(
    //   publicKey: 'pk_test_XXXXXXXXXXXXXXXXXXXXX',
    // ); // Replace with your Paystack public key
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

  Future<void> _makeBooking(String paymentReference) async {
    try {
      await supabase.from('bookings').insert({
        'user_id': supabase.auth.currentUser!.id,
        'vehicle_id': widget.vehicle['id'],
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'total_cost': _totalCost,
        'status': 'pending',
        'driver_license_number': _driverLicenseController.text,
        'nin': _ninController.text,
        'full_name': _fullNameController.text,
        'address': _addressController.text,
        'state': _selectedState,
        'phone_number': _phoneNumberController.text,
        'email': _emailController.text,
        'color': _selectedColor,
        'payment_reference': paymentReference,
        'payment_status': 'completed',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking and payment completed successfully!')),
      );
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create booking: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initiatePayment() async {
    if (_formKey.currentState!.validate() &&
        _startDate != null &&
        _endDate != null &&
        _selectedColor != null) {
      setState(() => _isLoading = true);

      final String reference = _uuid.v4();
      // final Charge charge = Charge()
      //   ..amount = _totalCostInKobo
      //   ..reference = reference
      //   ..email = _emailController.text
      //   ..currency = 'NGN';

      try {
        final uniqueTransRef = PayWithPayStack().generateUuidV4();

       await PayWithPayStack().now(
          context: context,
          secretKey: "sk_test_b260279d69c07196f87e47abce20c3f7a1f621f1",
          customerEmail: _emailController.text,
          reference: uniqueTransRef,
          currency: "NGN",
          amount: _totalCostInKobo.toDouble(),
          callbackUrl: "https://google.com",
          transactionCompleted: (paymentData) async {
            debugPrint(paymentData.toString());
            await _makeBooking(reference);
          },
          transactionNotCompleted: (reason) {
            debugPrint("==> Transaction failed reason $reason");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment failed: $reason')),
            );
            setState(() => _isLoading = false);
          },
        );

        // final CheckoutResponse response = await _paystack.checkout(
        //   context,
        //   method: CheckoutMethod.card, // Allow card payments
        //   charge: charge,
        // );

        // if (response.status && response.verify) {
        //   await _makeBooking(reference);
        // } else {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(content: Text('Payment failed: ${response.message}')),
        //   );
        //   setState(() => _isLoading = false);
        // }
      } catch (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment error: $error')));
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all required fields, select dates, and choose a color',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _driverLicenseController.dispose();
    _ninController.dispose();
    _fullNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableColors =
        (widget.vehicle['available_colors'] as List<dynamic>?)
            ?.cast<String>() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Book Vehicle'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 0,
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.vehicle['brand']} ${widget.vehicle['model']}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '₦${widget.vehicle['price_per_day'].toStringAsFixed(2)}/day',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Vehicle Color',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Color',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedColor,
                  items: availableColors.map((color) {
                    return DropdownMenuItem(value: color, child: Text(color));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedColor = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a vehicle color' : null,
                ),
                SizedBox(height: 24),
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your full name' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _driverLicenseController,
                  decoration: InputDecoration(
                    labelText: 'Driver License Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty
                      ? 'Please enter your driver license number'
                      : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _ninController,
                  decoration: InputDecoration(
                    labelText: 'NIN',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your NIN' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your address' : null,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedState,
                  items: _nigerianStates.map((state) {
                    return DropdownMenuItem(value: state, child: Text(state));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedState = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a state' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter your phone number';
                    if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value))
                      return 'Invalid phone number';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter your email';
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value))
                      return 'Invalid email';
                    return null;
                  },
                ),
                SizedBox(height: 24),
                Text(
                  'Select Rental Period',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
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
                                    : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_startDate!),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _startDate == null
                                      ? Colors.grey
                                      : null,
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
                                    : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_endDate!),
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
                if (_totalDays > 0) ...[
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [Text('Total Days'), Text('$_totalDays')],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Price per day'),
                              Text(
                                '₦${widget.vehicle['price_per_day'].toStringAsFixed(2)}',
                              ),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _initiatePayment,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Pay and Book'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
