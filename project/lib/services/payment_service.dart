import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'dart:developer' as developer;

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
    Map paymentObject = {
      "sandbox": isSandbox,
      "merchant_id": "1211149", // Replace with your Merchant ID
      "merchant_secret": "xyz", // Replace with your Merchant Secret (Hash value)
      "notify_url": "http://sample.com/notify", // Replace with your Notify URL
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
      "merchant_id": "1211149",
      "merchant_secret": "xyz",
      "notify_url": "http://sample.com/notify",
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
