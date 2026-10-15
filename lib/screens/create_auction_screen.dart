import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/auction_provider.dart';
import '../theme/app_theme.dart';

class CreateAuctionScreen extends StatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  State<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends State<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startingPriceController = TextEditingController(text: '100');
  final _minIncrementController = TextEditingController(text: '10');

  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 4));

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String? _selectedSampleImage;
  bool _isSubmitting = false;

  final List<Map<String, String>> _sampleImages = [
    {
      'label': 'Rolex Watch',
      'url': 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800',
    },
    {
      'label': 'MacBook Pro',
      'url': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800',
    },
    {
      'label': 'DSLR Camera',
      'url': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
    },
    {
      'label': 'Classic Car',
      'url': 'https://images.unsplash.com/photo-1584345604476-8ec5e12e42dd?w=800',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startingPriceController.dispose();
    _minIncrementController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageName = picked.name;
          _selectedSampleImage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final current = isStart ? _startTime : _endTime;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(minutes: 5)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (time == null || !mounted) return;

    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (isStart) {
        _startTime = combined;
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 2));
        }
      } else {
        _endTime = combined;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endTime.isBefore(_startTime) || _endTime.isAtSameMomentAs(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    if (_endTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be in the future')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<AuctionProvider>();
    final result = await provider.createAuction(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startingPrice: num.parse(_startingPriceController.text.trim()),
      minIncrement: num.parse(_minIncrementController.text.trim()),
      startTime: _startTime,
      endTime: _endTime,
      imageBytes: _pickedImageBytes,
      imageFileName: _pickedImageName,
      imageUrlFallback: _selectedSampleImage ?? _sampleImages[0]['url'],
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auction created successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to create auction'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Auction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Box
              const Text(
                'Auction Image',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: _pickedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(_pickedImageBytes!, fit: BoxFit.cover),
                        )
                      : _selectedSampleImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(_selectedSampleImage!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 44, color: Colors.grey.shade500),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap to upload image from device',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Supports PNG, JPG, WEBP (Max 10MB)',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 8),

              // Or choose sample image preset
              const Text(
                'Or choose preset photo:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _sampleImages.map((s) {
                    final isChosen = _selectedSampleImage == s['url'] && _pickedImageBytes == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s['label']!),
                        selected: isChosen,
                        onSelected: (_) {
                          setState(() {
                            _selectedSampleImage = s['url'];
                            _pickedImageBytes = null;
                            _pickedImageName = null;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Auction Title',
                  hintText: 'e.g. 1978 Rolex Submariner Date',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe condition, features, provenance, etc.',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              // Starting Price & Min Increment Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Starting Price (\$)',
                        prefixText: '\$ ',
                      ),
                      validator: (val) {
                        final n = num.tryParse(val ?? '');
                        if (n == null || n < 0) return 'Invalid price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _minIncrementController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Min Increment (\$)',
                        prefixText: '\$ ',
                      ),
                      validator: (val) {
                        final n = num.tryParse(val ?? '');
                        if (n == null || n < 1) return 'Must be >= \$1';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Schedule Section
              const Text(
                'Auction Schedule',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),

              // Start Time
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start Time', style: TextStyle(fontSize: 13, color: Colors.grey)),
                subtitle: Text(
                  dateFormat.format(_startTime),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                trailing: TextButton.icon(
                  onPressed: () => _pickDateTime(true),
                  icon: const Icon(Icons.edit_calendar, size: 18),
                  label: const Text('Change'),
                ),
              ),
              const Divider(height: 1),

              // End Time
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('End Time', style: TextStyle(fontSize: 13, color: Colors.grey)),
                subtitle: Text(
                  dateFormat.format(_endTime),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                trailing: TextButton.icon(
                  onPressed: () => _pickDateTime(false),
                  icon: const Icon(Icons.edit_calendar, size: 18),
                  label: const Text('Change'),
                ),
              ),
              const SizedBox(height: 10),

              // Quick Duration Presets for convenience
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('+15 mins'),
                    onPressed: () {
                      setState(() {
                        _endTime = _startTime.add(const Duration(minutes: 15));
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('+2 hours'),
                    onPressed: () {
                      setState(() {
                        _endTime = _startTime.add(const Duration(hours: 2));
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('+24 hours'),
                    onPressed: () {
                      setState(() {
                        _endTime = _startTime.add(const Duration(days: 1));
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Publish Auction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
