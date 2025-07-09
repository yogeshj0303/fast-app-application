import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NowPaymentsService {
  static const String _baseUrl = 'https://api.nowpayments.io/v1';
  static const String _apiKey = 'VW82WMY-A1WMPRZ-GZ2QKVC-1C8MPCN';
  static const double _inrToUsdRate = 0.0117; // 1 INR = 0.0117 USD (more accurate rate)
  static const double _minimumUsdAmount = 5.0; // Minimum amount required by NOWPayments

  // Convert INR to USD
  double _convertInrToUsd(double inrAmount) {
    final usdAmount = inrAmount * _inrToUsdRate;
    // Round to 2 decimal places
    return double.parse(usdAmount.toStringAsFixed(2));
  }

  // Check if amount meets minimum requirement
  bool _isAmountValid(double usdAmount) {
    return usdAmount >= _minimumUsdAmount;
  }

  // Create a payment
  Future<Map<String, dynamic>> createPayment({
    required double priceAmount,
    required String priceCurrency,
    required String payCurrency,
    String? orderId,
    String? orderDescription,
    String? ipnCallbackUrl,
    bool isFixedRate = true,
    bool isFeePaidByUser = false,
  }) async {
    try {
      // Convert amount to USD if it's in INR
      double amountInUsd = priceCurrency.toUpperCase() == 'INR' 
          ? _convertInrToUsd(priceAmount)
          : priceAmount;

      print('Original amount: $priceAmount $priceCurrency');
      print('Converted amount: $amountInUsd USD');

      if (!_isAmountValid(amountInUsd)) {
        final minimumInrAmount = (_minimumUsdAmount / _inrToUsdRate).toStringAsFixed(2);
        throw Exception(
          'Amount too low. The minimum payment amount for crypto payments is \$$_minimumUsdAmount USD (\$$minimumInrAmount USD). '
          'Your current amount of \$${amountInUsd.toStringAsFixed(2)} USD (\$${priceAmount.toStringAsFixed(2)} USD) is below the minimum. '
          'Please choose a plan with a higher value or use a different payment method.'
        );
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/payment'),
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'price_amount': amountInUsd,
          'price_currency': 'USD',
          'pay_currency': payCurrency,
          'order_id': orderId,
          'order_description': orderDescription,
          'ipn_callback_url': ipnCallbackUrl,
          'is_fixed_rate': isFixedRate,
          'is_fee_paid_by_user': isFeePaidByUser,
        }),
      );

      print('Payment API Response: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Convert numeric values to ensure proper types
        if (responseData['price_amount'] != null) {
          responseData['price_amount'] = double.parse(responseData['price_amount'].toString());
        }
        if (responseData['pay_amount'] != null) {
          responseData['pay_amount'] = double.parse(responseData['pay_amount'].toString());
        }
        if (responseData['amount_received'] != null) {
          responseData['amount_received'] = double.parse(responseData['amount_received'].toString());
        }
        
        // Store payment details in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('payment_id', responseData['payment_id'].toString());
        await prefs.setString('payment_status', responseData['payment_status']);
        await prefs.setString('pay_address', responseData['pay_address']);
        await prefs.setDouble('price_amount', responseData['price_amount']);
        await prefs.setString('pay_currency', responseData['pay_currency']);
        await prefs.setString('order_id', responseData['order_id']);
        await prefs.setString('created_at', responseData['created_at']);
        await prefs.setString('valid_until', responseData['valid_until']);
        
        return responseData;
      } else {
        throw Exception('Failed to create payment: ${response.body}');
      }
    } catch (e) {
      print('Error in createPayment: $e');
      throw Exception('Error creating payment: $e');
    }
  }

  // Create an invoice
  Future<Map<String, dynamic>> createInvoice({
    required double priceAmount,
    required String priceCurrency,
    String? orderId,
    String? orderDescription,
    String? ipnCallbackUrl,
    String? successUrl,
    String? cancelUrl,
    String? partiallyPaidUrl,
    bool isFixedRate = true,
    bool isFeePaidByUser = false,
  }) async {
    try {
      // Convert amount to USD if it's in INR
      double amountInUsd = priceCurrency.toUpperCase() == 'INR' 
          ? _convertInrToUsd(priceAmount)
          : priceAmount;

      print('Creating invoice with amount: $priceAmount $priceCurrency');
      print('Converted amount: $amountInUsd USD');

      if (!_isAmountValid(amountInUsd)) {
        final minimumInrAmount = (_minimumUsdAmount / _inrToUsdRate).toStringAsFixed(2);
        throw Exception(
          'Amount too low. The minimum payment amount for crypto payments is \$$_minimumUsdAmount USD (\$$minimumInrAmount USD). '
          'Your current amount of \$${amountInUsd.toStringAsFixed(2)} USD (\$${priceAmount.toStringAsFixed(2)} USD) is below the minimum. '
          'Please choose a plan with a higher value or use a different payment method.'
        );
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/invoice'),
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'price_amount': amountInUsd,
          'price_currency': 'USD',
          'order_id': orderId,
          'order_description': orderDescription,
          'ipn_callback_url': ipnCallbackUrl,
          'success_url': successUrl,
          'cancel_url': cancelUrl,
          'partially_paid_url': partiallyPaidUrl,
          'is_fixed_rate': isFixedRate,
          'is_fee_paid_by_user': isFeePaidByUser,
        }),
      );

      print('Invoice API Response Status: ${response.statusCode}');
      print('Invoice API Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);
      
      // Check if the response contains an error message
      if (responseData['error'] != null) {
        throw Exception('API Error: ${responseData['error']}');
      }

      // If we have an invoice_url, consider it a success
      if (responseData['invoice_url'] != null) {
        return responseData;
      }

      // If we don't have an invoice_url but have a valid response, return it
      if (response.statusCode == 201 || response.statusCode == 200) {
        return responseData;
      }

      throw Exception('Failed to create invoice: ${response.body}');
    } catch (e) {
      print('Error in createInvoice: $e');
      throw Exception('Error creating invoice: $e');
    }
  }

  // Get payment status
  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    try {
      print('Checking payment status for ID: $paymentId');
      final response = await http.get(
        Uri.parse('$_baseUrl/payment/$paymentId'),
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
      );

      print('Payment Status API Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Convert numeric values to ensure proper types
        if (responseData['price_amount'] != null) {
          responseData['price_amount'] = double.parse(responseData['price_amount'].toString());
        }
        if (responseData['pay_amount'] != null) {
          responseData['pay_amount'] = double.parse(responseData['pay_amount'].toString());
        }
        if (responseData['actually_paid'] != null) {
          responseData['actually_paid'] = double.parse(responseData['actually_paid'].toString());
        }
        if (responseData['amount_received'] != null) {
          responseData['amount_received'] = double.parse(responseData['amount_received'].toString());
        }
        
        return responseData;
      } else {
        throw Exception('Failed to get payment status: ${response.body}');
      }
    } catch (e) {
      print('Error in getPaymentStatus: $e');
      throw Exception('Error getting payment status: $e');
    }
  }
} 