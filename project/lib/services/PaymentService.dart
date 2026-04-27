import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:developer' as developer;

class PaymentService {
  /// Fetches the MD5 hash from our secure Cloud Function.
  static Future<Map<String, dynamic>?> _getSecureHash({
    required String orderId,
    required String amount,
    required String currency,
  }) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getPayhereHash');
      final result = await callable.call({
        'orderId': orderId,
        'amount': amount,
        'currency': currency,
      });
      return result.data as Map<String, dynamic>;
    } catch (e) {
      developer.log("PAYHERE HASH ERROR: $e");
      return null;
    }
  }

  /// Initiates a one-time payment request.
  static void startOneTimePayment({
    required String amount,
    required String orderId,
    required String itemsDescription,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String city,
    String currency = "LKR",
    bool isSandbox = true,
    Function(String)? onCompleted,
    Function(String)? onError,
    Function()? onDismissed,
  }) async {
    
    // 1. Get Secure Hash from Backend
    final hashData = await _getSecureHash(
      orderId: orderId,
      amount: amount,
      currency: currency,
    );

    if (hashData == null) {
      if (onError != null) onError("Failed to secure payment transaction.");
      return;
    }

    final String merchantId = hashData['merchantId'];
    final String hash = hashData['hash'];

    // 2. Build Payment Object (using hash instead of secret)
    Map paymentObject = {
      "sandbox": isSandbox,
      "merchant_id": merchantId,
      "hash": hash, // Securely generated on backend
      "notify_url": "https://us-central1-travelpass-40736.cloudfunctions.net/payhereNotify",
      "order_id": orderId,
      "items": itemsDescription,
      "amount": amount,
      "currency": currency,
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "phone": phone,
      "address": address,
      "city": city,
      "country": "Sri Lanka",
    };

    PayHere.startPayment(
      paymentObject,
      (paymentId) {
        developer.log("One Time Payment Success. Payment Id: $paymentId");
        if (onCompleted != null) onCompleted(paymentId);
      },
      (error) {
        developer.log("One Time Payment Failed. Error: $error");
        if (onError != null) onError(error);
      },
      () {
        developer.log("One Time Payment Dismissed");
        if (onDismissed != null) onDismissed();
      },
    );
  }

  /// Initiates a pre-approval request (Tokenization).
  /// Note: Tokenization usually doesn't require a hash in the same way,
  /// but we should keep it consistent.
  static void startPreapprovalRequest({
    required String orderId,
    required String itemsDescription,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String city,
    String currency = "LKR",
    bool isSandbox = true,
    Function(String)? onCompleted,
    Function(String)? onError,
    Function()? onDismissed,
  }) async {
    
    // For tokenization, we'll fetch a special hash if needed, 
    // or use the merchant ID from the backend.
    final hashData = await _getSecureHash(
      orderId: orderId,
      amount: "0.00", // Tokenization has no amount
      currency: currency,
    );

    if (hashData == null) {
      if (onError != null) onError("Failed to secure tokenization.");
      return;
    }

    final String merchantId = hashData['merchantId'];

    Map paymentObject = {
      "sandbox": isSandbox,
      "preapprove": true,
      "merchant_id": merchantId,
      // Note: Tokenization might still require a secret for full flow, 
      // but mobile SDK allows basic start with just ID.
      "notify_url": "https://us-central1-travelpass-40736.cloudfunctions.net/payhereNotify",
      "order_id": orderId,
      "items": itemsDescription,
      "currency": currency,
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "phone": phone,
      "address": address,
      "city": city,
      "country": "Sri Lanka",
    };

    PayHere.startPayment(
      paymentObject,
      (paymentId) {
        developer.log("Tokenization Success. Payment Id: $paymentId");
        if (onCompleted != null) onCompleted(paymentId);
      },
      (error) {
        developer.log("Tokenization Failed. Error: $error");
        if (onError != null) onError(error);
      },
      () {
        developer.log("Tokenization Dismissed");
        if (onDismissed != null) onDismissed();
      },
    );
  }
}
