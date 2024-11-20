import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';

class UploadPaymentProofScreen extends StatefulWidget {
  final String transactionId;

  const UploadPaymentProofScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<UploadPaymentProofScreen> createState() =>
      _UploadPaymentProofScreenState();
}

class _UploadPaymentProofScreenState extends State<UploadPaymentProofScreen> {
  final supabase = Supabase.instance.client;

  File? _image;
  bool isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _uploadProof() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih bukti pembayaran terlebih dahulu')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Periksa token otentikasi
      final session = supabase.auth.currentSession;
      if (session == null) {
        // Jika session null, arahkan ke halaman login
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Lanjutkan dengan upload
      final fileName =
          '${widget.transactionId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('Uploading image...');
      await supabase.storage.from('payment_proofs').upload(fileName, _image!);
      print('Image uploaded successfully');

      final imageUrl =
          supabase.storage.from('payment_proofs').getPublicUrl(fileName);
      print('Image URL: $imageUrl');

      print('Updating transaction...');
      await supabase.from('transactions').update({
        'payment_proof': imageUrl,
        'status': 'waiting_confirmation'
      }).eq('id', widget.transactionId);
      print('Transaction updated successfully');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Bukti pembayaran berhasil periksa di menu transaksi')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      print('Error during upload: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Bukti Pembayaran'),
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _image == null
                  ? Center(
                      child: TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload),
                        label: const Text('Pilih Bukti Pembayaran'),
                      ),
                    )
                  : Image.file(_image!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _uploadProof,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Upload Bukti Pembayaran',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
