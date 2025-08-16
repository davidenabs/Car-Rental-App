import 'package:car_rental_app/main.dart';
import 'package:car_rental_app/screens/booking_screen.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final List<String> galleryImages = (vehicle['gallery_images'] as List<dynamic>?)?.cast<String>() ?? [];
    final List<String> availableColors = (vehicle['available_colors'] as List<dynamic>?)?.cast<String>() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${vehicle['brand']} ${vehicle['model']}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel for gallery images
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey[200],
              child: galleryImages.isNotEmpty
                  ? CarouselSlider(
                      options: CarouselOptions(
                        height: 250,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        aspectRatio: 16 / 9,
                        viewportFraction: 1.0,
                      ),
                      items: galleryImages.map((url) {
                        return Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.directions_car, size: 80, color: Colors.grey[400]);
                          },
                        );
                      }).toList(),
                    )
                  : Image.network(
                      vehicle['image_url'] ?? '',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.directions_car, size: 80, color: Colors.grey[400]);
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle['brand']} ${vehicle['model']}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    vehicle['type'] ?? 'Car',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  // Plate Number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Plate Number',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        vehicle['plate_number'] ?? 'N/A',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Price per day
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price per day',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '₦${vehicle['price_per_day'].toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Availability
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Availability',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: vehicle['available'] == true ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          vehicle['available'] == true ? 'Available' : 'Not Available',
                          style: TextStyle(
                            color: vehicle['available'] == true ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Available Colors
                  if (availableColors.isNotEmpty) ...[
                    Text(
                      'Available Colors',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: availableColors.map((color) {
                        return Chip(
                          label: Text(color),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(color: Colors.black87),
                          padding: EdgeInsets.symmetric(horizontal: 8),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24),
                  ],
                  // Description
                  if (vehicle['description'] != null) ...[
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(vehicle['description']),
                    SizedBox(height: 24),
                  ],
                  // Created At
                  Text(
                    'Added on',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    DateFormat('MMMM d, yyyy').format(DateTime.parse(vehicle['created_at'])),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 24),
                  // Book Now Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: vehicle['available'] == true
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingScreen(vehicle: vehicle),
                                ),
                              );
                            }
                          : null,
                      child: Text('Book Now'),
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
          ],
        ),
      ),
    );
  }
}