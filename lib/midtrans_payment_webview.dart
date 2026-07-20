import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

/// Fungsi: Halaman khusus berbentuk WebView untuk memproses pembayaran menggunakan Midtrans Snap.
/// Cara Kerja: Menerima parameter `snapUrl` (tautan pembayaran), `orderId` (ID pesanan), dan
/// fungsi opsional `onPaymentSuccess`. Halaman ini menampilkan situs web pembayaran di dalam aplikasi,
/// sekaligus memantau perubahan status transaksi secara *realtime* di Firestore serta mendeteksi
/// navigasi tautan sukses/gagal di dalam webview tersebut.
class MidtransPaymentWebView extends StatefulWidget {
  final String snapUrl;
  final String orderId;
  final VoidCallback? onPaymentSuccess;

  const MidtransPaymentWebView({
    required this.snapUrl,
    required this.orderId,
    this.onPaymentSuccess,
    super.key,
  });

  @override
  State<MidtransPaymentWebView> createState() => _MidtransPaymentWebViewState();
}

class _MidtransPaymentWebViewState extends State<MidtransPaymentWebView> {
  late WebViewController controller;
  late StreamSubscription<DocumentSnapshot> orderSub;

  @override
  void initState() {
    super.initState();

    /// Fungsi: Mendengarkan (listening) perubahan data pesanan di Firestore secara realtime.
    /// Cara Kerja: Berlangganan (subscribe) ke aliran data (*stream*) dari dokumen pesanan berdasarkan `orderId`.
    /// Jika status dokumen berubah menjadi `'completed'`, aplikasi secara otomatis menutup halaman
    /// webview (`Navigator.pop`) dengan mengirimkan status `'success'`.
    orderSub = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((doc) {
          final status = doc['status'];
          if (status == 'completed') {
            if (mounted) {
              Navigator.pop(context, {'status': 'success'});
            }
          }
        });

    /// Fungsi: Menginisialisasi pengendali WebView (WebViewController).
    /// Cara Kerja: Mengaktifkan fitur JavaScript, mengatur delegasi navigasi untuk mendeteksi
    /// perpindahan halaman URL di webview, dan memuat URL pembayaran (`widget.snapUrl`).
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            debugPrint("PAGE FINISHED: $url");
            if (url.contains("payment-finish")) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pop(context, {'status': 'success'});
                }
              });
            }
          },

          /// Fungsi: Mengintersepsi atau memeriksa setiap ada request perpindahan halaman URL di webview.
          /// Cara Kerja:Memeriksa tautan URL tujuan:
          /// 1. Jika sukses (`/payment-finish`), program memperbarui database Firestore (`orders`)
          ///    mengubah `payment_status` jadi 'success', `status` pesanan menjadi 'pickup_validation',
          ///    memicu *callback* sukses, lalu mencegah web melanjutkan navigasinya (`NavigationDecision.prevent`).
          /// 2. Jika gagal (`/payment-error`), halaman ditutup dengan status `'error'`.
          /// 3. Jika batal (`/payment-unfinish`), halaman ditutup dengan status `'cancel'`.
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint("NAV: $url");

            if (url.startsWith(
                  "https://api-midtrans-teal.vercel.app/api/payment-finish",
                ) ||
                url.startsWith(
                  "http://api-midtrans-teal.vercel.app/api/payment-finish",
                )) {
              FirebaseFirestore.instance
                  .collection('orders')
                  .doc(widget.orderId)
                  .update({
                    'payment_status': 'success',
                    'status': 'pickup_validation',
                    'payment_time': Timestamp.now(),
                  });

              widget.onPaymentSuccess?.call();
              return NavigationDecision.prevent;
            }

            if (url.startsWith(
                  "https://api-midtrans-teal.vercel.app/api/payment-error",
                ) ||
                url.startsWith(
                  "http://api-midtrans-teal.vercel.app/api/payment-error",
                )) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pop(context, {'status': 'error'});
                }
              });
              return NavigationDecision.prevent;
            }

            if (url.startsWith(
                  "https://api-midtrans-teal.vercel.app/api/payment-unfinish",
                ) ||
                url.startsWith(
                  "http://api-midtrans-teal.vercel.app/api/payment-unfinish",
                )) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pop(context, {'status': 'cancel'});
                }
              });
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.snapUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran")),
      body: WebViewWidget(controller: controller),
    );
  }

  @override
  void dispose() {
    /// Fungsi: Membersihkan memori dan menghentikan langganan data.
    /// Cara Kerja: Membatalkan `orderSub` (StreamSubscription) saat widget dihancurkan
    /// agar tidak terjadi kebocoran memori (*memory leak*).
    orderSub.cancel();
    super.dispose();
  }
}
