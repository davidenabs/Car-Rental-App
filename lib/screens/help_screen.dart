import 'package:car_rental_app/main.dart';
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  final List<Map<String, String>> _faqItems = [
    {
      'question': 'How do I book a car?',
      'answer':
          'Browse available vehicles, select your preferred car, choose rental dates, and confirm your booking. Payment will be processed securely through our platform.',
    },
    {
      'question': 'Can I cancel my booking?',
      'answer':
          'Yes, you can cancel your booking up to 24 hours before the rental start date. Cancellation fees may apply depending on the timing.',
    },
    {
      'question': 'What documents do I need?',
      'answer':
          'You need a valid driver\'s license, national ID or passport, and a credit/debit card for payment and security deposit.',
    },
    {
      'question': 'How do I modify my booking?',
      'answer':
          'You can modify your booking through the app by going to your bookings section. Changes are subject to vehicle availability and may incur additional charges.',
    },
    {
      'question': 'What if I return the car late?',
      'answer':
          'Late returns are subject to additional charges. Please contact us immediately if you need to extend your rental period.',
    },
    {
      'question': 'Is insurance included?',
      'answer':
          'Basic insurance is included with all rentals. Additional coverage options are available for purchase during booking.',
    },
  ];

  HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & FAQ'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _faqItems.length,
        itemBuilder: (context, index) {
          final item = _faqItems[index];
          return Card(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                item['question']!,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    item['answer']!,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
