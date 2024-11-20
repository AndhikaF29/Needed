import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/premium_app.dart';
import '../constants/app_colors.dart';
import '../screens/upload_payment_proof_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

final supabase = Supabase.instance.client;

class PaymentScreen extends StatefulWidget {
  final PremiumApp app;

  const PaymentScreen({super.key, required this.app});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? selectedPaymentMethod;
  bool isLoading = false;
  late PremiumApp currentApp;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'name': 'DANA',
      'icon': 'assets/icons/dana.png',
      'number': '08596316077',
      'account_name': 'Andhika Fajar Prayoga'
    },
    {
      'name': 'OVO',
      'icon': 'assets/icons/ovo.png',
      'number': '08596316077',
      'account_name': 'Andhika Fajar Prayoga'
    },
    {
      'name': 'GoPay',
      'icon': 'assets/icons/gopay.png',
      'number': '08596316077',
      'account_name': 'Andhika Fajar Prayoga'
    },
    {
      'name': 'Bank Transfer',
      'icon': 'assets/icons/bank.png',
      'number': '7773036910',
      'bank': 'BCA',
      'account_name': 'Andhika Fajar Prayoga'
    },
  ];

  @override
  void initState() {
    super.initState();
    currentApp = widget.app;
    _loadCurrentAppData();
  }

  Future<void> _loadCurrentAppData() async {
    try {
      final response = await supabase
          .from('premium_apps')
          .select()
          .eq('id', widget.app.id)
          .single();
      
      if (response != null && mounted) {
        setState(() {
          currentApp = PremiumApp.fromJson(response);
        });
      }
    } catch (e) {
      print('Error loading app data: $e');
    }
  }

  // Fungsi untuk memproses pembayaran
  Future<void> processPayment() async {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih metode pembayaran')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Silakan login terlebih dahulu');

      final transactionData = _prepareTransactionData(user.id);
      
      // Ubah cara mengambil response
      final response = await supabase
          .from('transactions')
          .insert(transactionData)
          .select()
          .maybeSingle();

      if (!mounted) return;
      
      if (response == null) {
        throw Exception('Gagal membuat transaksi');
      }

      await _handleSuccessfulTransaction(response);
      
    } catch (e) {
      print('Payment Error: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses pembayaran: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Pindahkan persiapan data transaksi ke fungsi terpisah
  Map<String, dynamic> _prepareTransactionData(String userId) {
    return {
      'user_id': userId,
      'premium_app_id': currentApp.id,
      'payment_method': selectedPaymentMethod,
      'amount': currentApp.discountPrice,
      'status': 'pending',
      'transaction_date': DateTime.now().toIso8601String(),
    };
  }

  // Pindahkan handling sukses ke fungsi terpisah
  Future<void> _handleSuccessfulTransaction(Map<String, dynamic> transactionResponse) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildSuccessDialog(transactionResponse),
    );
  }

  Widget _buildSuccessDialog(Map<String, dynamic> transactionResponse) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: const Text('Pembayaran Berhasil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Silakan lakukan pembayaran sesuai metode yang dipilih:'),
            const SizedBox(height: 12),
            Text('Metode: $selectedPaymentMethod'),
            _buildPaymentDetails(),
            const SizedBox(height: 12),
            const Text('Silakan upload bukti pembayaran untuk verifikasi.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Kembali ke Beranda'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UploadPaymentProofScreen(
                  transactionId: transactionResponse['id'],
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Upload Bukti Pembayaran'),
          ),
        ],
      ),
    );
  }

  // Helper method untuk payment details
  Widget _buildPaymentDetails() {
    if (selectedPaymentMethod == null) return const SizedBox.shrink();
    
    final method = paymentMethods.firstWhere(
      (method) => method['name'] == selectedPaymentMethod,
      orElse: () => {},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nomor Tujuan: ${method['number'] ?? '-'}'),
        Text('Atas Nama: ${method['account_name'] ?? '-'}'),
        if (selectedPaymentMethod == 'Bank Transfer')
          Text('Bank: ${method['bank'] ?? '-'}'),
        Text(
          'Total: Rp ${NumberFormat.decimalPattern('id_ID').format(currentApp.discountPrice + 1000)}',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.decimalPattern('id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detail Produk
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (currentApp.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        currentApp.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentApp.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${formatCurrency.format(currentApp.discountPrice)}/bln',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Metode Pembayaran
            const Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // List Metode Pembayaran
            ...paymentMethods.map((method) => RadioListTile(
                  value: method['name'],
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value as String;
                    });
                  },
                  title: Row(
                    children: [
                      // Icon(Icons.payment), // Ganti dengan image icon sesuai payment method
                      const SizedBox(width: 12),
                      Text(method['name']),
                    ],
                  ),
                )),

            const SizedBox(height: 24),

            // Rincian Pembayaran
            const Text(
              'Rincian Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Harga Langganan'),
                Text('Rp ${formatCurrency.format(currentApp.discountPrice)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Biaya Layanan'),
                Text('Rp ${formatCurrency.format(1000)}'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp ${formatCurrency.format(currentApp.discountPrice + 1000)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading || selectedPaymentMethod == null
              ? null
              : processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
                  'Bayar Sekarang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
