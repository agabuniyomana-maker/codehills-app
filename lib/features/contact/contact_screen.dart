import 'package:flutter/material.dart';

import '../../data/app_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/portal_widgets.dart';

/// Contact Us page — port of ContactUsPanel.java (saves locally until backend).
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _inquiryController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _inquiryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _inquiryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in your name and inquiry.'),
          backgroundColor: AppColors.darkBrown,
        ),
      );
      return;
    }
    await AppData.instance.addInquiry({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'inquiry': _inquiryController.text.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
    _nameController.clear();
    _emailController.clear();
    _inquiryController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you! Your inquiry has been recorded.'),
        backgroundColor: AppColors.darkBrown,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PortalCard(
      radius: 22,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PortalHeading('Contact Us', size: 24),
                const SizedBox(height: 4),
                const ImigongoBand(height: 14),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'YOUR NAME'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'EMAIL ADDRESS'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _inquiryController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'YOUR INQUIRY',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                PortalButton(label: 'SEND INQUIRY', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
