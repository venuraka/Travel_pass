import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import '../config/AppConfig.dart';

class PaymentService {
  /// Initiates a one-time payment request.
  /// 
  /// [amount] - The amount to be charged (e.g., "50.00").
  /// [orderId] - Unique identifier for the transaction.
  /// [itemsDescription] - Description of the items being purchased.
  /// [firstName], [lastName], [email], [phone], [address], [city] - Customer details.
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
  }) {
    // Debug: Log the retrieved merchant ID and secret
    developer.log("PaymentService DEBUG: merchant_id='${AppConfig.payhereMerchantId}'");
    developer.log("PaymentService DEBUG: merchant_secret='${AppConfig.payhereMerchantSecret}'");
    
    // Validate merchant credentials
    if (AppConfig.payhereMerchantId.isEmpty || AppConfig.payhereMerchantSecret.isEmpty) {
      final errorMsg = "PayHere credentials not configured. Merchant ID: '${AppConfig.payhereMerchantId}', Secret: '${AppConfig.payhereMerchantSecret}'";
      developer.log("PAYHERE CONFIG ERROR: $errorMsg");
      if (onError != null) onError(errorMsg);
      return;
    }
    
    Map paymentObject = {
      "sandbox": isSandbox,
      "merchant_id": AppConfig.payhereMerchantId,
      "merchant_secret": AppConfig.payhereMerchantSecret,
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
      "custom_1": "",
      "custom_2": ""
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
  }) {
    Map paymentObject = {
      "sandbox": isSandbox,
      "preapprove": true,
      "merchant_id": AppConfig.payhereMerchantId,
      "merchant_secret": AppConfig.payhereMerchantSecret,
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
