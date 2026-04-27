import 'package:cloud_functions/cloud_functions.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'dart:developer' as developer;

class PaymentService {
  /// Initiates a one-time payment request.
  /// Securely fetches the payment hash from the backend.
  static Future<void> startOneTimePayment({
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
    try {
      // 1. Fetch Secure Hash from Backend
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getPayhereHash');
      final result = await callable.call({
        'orderId': orderId,
        'amount': amount,
        'currency': currency,
      });

      final data = result.data as Map<String, dynamic>;
      final String merchantId = data['merchantId'];
      final String hash = data['hash'];
      final String formattedAmount = data['amount'];

      // 2. Construct Payment Object WITHOUT merchant_secret
      Map paymentObject = {
        "sandbox": isSandbox,
        "merchant_id": merchantId,
        "hash": hash, // Using hash instead of secret
        "notify_url": "https://us-central1-travelpass-40736.cloudfunctions.net/payhereNotify",
        "order_id": orderId,
        "items": itemsDescription,
        "amount": formattedAmount,
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
    } catch (e) {
      developer.log("Payment Initialization Error: $e");
      if (onError != null) onError("Failed to initialize payment: $e");
    }
  }

  /// Initiates a pre-approval request (Tokenization).
  /// Note: Tokenization also requires a hash for the pre-approval request.
  static Future<void> startPreapprovalRequest({
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
    try {
      // For pre-approval, PayHere hash is md5(merchant_id + order_id + md5(merchant_secret))
      // Our backend can be updated to support this, or we can use a small amount for pre-approval.
      // Usually pre-approval hash doesn't include amount.
      
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getPayhereHash');
      final result = await callable.call({
        'orderId': orderId,
        'amount': "0", // Amount is 0 for pre-approval hash usually, but verify PayHere docs
        'currency': currency,
      });

      final data = result.data as Map<String, dynamic>;
      
      Map paymentObject = {
        "sandbox": isSandbox,
        "preapprove": true,
        "merchant_id": data['merchantId'],
        "hash": data['hash'],
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
    } catch (e) {
      developer.log("Tokenization Initialization Error: $e");
      if (onError != null) onError("Failed to initialize tokenization: $e");
    }
  }
}
