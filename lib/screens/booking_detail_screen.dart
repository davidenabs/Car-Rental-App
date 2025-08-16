import 'package:car_rental_app/main.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> vehicle;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.vehicle,
  });

  @override
  _BookingDetailScreenState createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _isLoading = false;

  Future<void> _cancelBooking() async {
    if (widget.booking['status'].toString().toLowerCase() != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only pending bookings can be cancelled')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', widget.booking['id']);

      setState(() {
        widget.booking['status'] = 'cancelled';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking cancelled successfully')));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel booking: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime.parse(widget.booking['start_date']);
    final endDate = DateTime.parse(widget.booking['end_date']);
    final createdAt = DateTime.parse(widget.booking['created_at']);
    final galleryImages =
        (widget.vehicle['gallery_images'] as List<dynamic>?)?.cast<String>() ??
        [];
    final availableColors =
        (widget.vehicle['available_colors'] as List<dynamic>?)
            ?.cast<String>() ??
        [];
    final selectedColor = widget.booking['color'] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle['brand']} ${widget.vehicle['model']}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Image Carousel
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
                              return Icon(
                                Icons.directions_car,
                                size: 80,
                                color: Colors.grey[400],
                              );
                            },
                          );
                        }).toList(),
                      )
                    : Image.network(
                        widget.vehicle['image_url'] ?? '',
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.directions_car,
                            size: 80,
                            color: Colors.grey[400],
                          );
                        },
                      ),
              ),
              SizedBox(height: 24),
              // Vehicle Details
              Text(
                'Vehicle Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildDetailRow(context, 'Brand', widget.vehicle['brand']),
              _buildDetailRow(context, 'Model', widget.vehicle['model']),
              _buildDetailRow(context, 'Type', widget.vehicle['type']),
              _buildDetailRow(
                context,
                'Plate Number',
                widget.vehicle['plate_number'],
              ),
              _buildDetailRow(context, 'Selected Colour', selectedColor),

              // if (availableColors.isNotEmpty) ...[
              //   Text(
              //     'Available Colors',
              //     style: Theme.of(context).textTheme.titleMedium?.copyWith(
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              //   SizedBox(height: 8),
              //   Wrap(
              //     spacing: 8,
              //     children: availableColors.map((color) {
              //       if (selectedColor == color)
              //       return Chip(
              //         label: Text(color),
              //         backgroundColor: Colors.grey[100],
              //         labelStyle: TextStyle(color: Colors.black87),
              //       );
              //     }).toList(),
              //     else
              //     return '';
              //   ),
              // ],
              SizedBox(height: 24),
              // Booking Details
              Text(
                'Booking Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildDetailRow(context, 'Booking ID', widget.booking['id']),
              _buildDetailRow(
                context,
                'Status',
                widget.booking['status'].toString().toUpperCase(),
                valueColor: _getStatusColor(widget.booking['status']),
              ),
              _buildDetailRow(
                context,
                'Start Date',
                DateFormat('dd/MM/yyyy').format(startDate),
              ),
              _buildDetailRow(
                context,
                'End Date',
                DateFormat('dd/MM/yyyy').format(endDate),
              ),
              _buildDetailRow(
                context,
                'Total Cost',
                '₦${widget.booking['total_cost'].toStringAsFixed(2)}',
                valueColor: Theme.of(context).primaryColor,
              ),
              _buildDetailRow(
                context,
                'Booked On',
                DateFormat('dd/MM/yyyy').format(createdAt),
              ),
              SizedBox(height: 24),
              // Customer Information
              Text(
                'Customer Information',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildDetailRow(
                context,
                'Full Name',
                widget.booking['full_name'],
              ),
              _buildDetailRow(
                context,
                'Driver License',
                widget.booking['driver_license_number'],
              ),
              _buildDetailRow(context, 'NIN', widget.booking['nin']),
              _buildDetailRow(context, 'Address', widget.booking['address']),
              _buildDetailRow(context, 'State', widget.booking['state']),
              _buildDetailRow(
                context,
                'Phone Number',
                widget.booking['phone_number'],
              ),
              _buildDetailRow(context, 'Email', widget.booking['email']),
              SizedBox(height: 24),
              // Cancel Booking Button
              if (widget.booking['status'].toString().toLowerCase() ==
                  'pending')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _cancelBooking,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Cancel Booking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
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
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
