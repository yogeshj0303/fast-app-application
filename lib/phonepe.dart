// import 'dart:convert';
// import 'package:crypto/crypto.dart';
// import 'package:flutter/material.dart';
// import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

// class PhonepePayment extends StatefulWidget {
//   const PhonepePayment({super.key});

//   @override
//   State<PhonepePayment> createState() => _PhonepePaymentState();
// }

// class _PhonepePaymentState extends State<PhonepePayment> {
//   String environmentValue = "SANDBOX";
//   String appId = "";
//   String merchantId = "PGTESTPAYUAT";
//   bool enableLogging = true;

//   String saltKey = "099eb0cd-02cf-4e2a-8aca-3e6c6aff0399";
//   String saltIndex = "1";
//   Object? result;

//   String body = "";
//   String callback = "";
//   String checksum = "";
//   String packageName = "";
//   String apiEndPoint = "/pg/v1/pay";
//   String uatHostUrl = "https://api-preprod.phonepe.com/apis/hermes";

//   @override
//   void initState() {
//     initPayment();
//     body = getChecksum().toString();
//     super.initState();
//   }

//   void initPayment() {
//     PhonePePaymentSdk.init(environmentValue, appId, merchantId, enableLogging)
//         .then((val) => {
//               setState(() {
//                 result = 'PhonePe SDK Initialized - $val';
//               })
//             })
//         .catchError((error) {
//       handleError(error);
//       return <dynamic>{};
//     });
//   }

//   void handleError(error) {
//     result = error;
//   }

//   void startTranscation() {
//     PhonePePaymentSdk.startTransaction(body, callback, checksum, packageName)
//         .then((response) => {
//               setState(() {
//                 if (response != null) {
//                   String status = response['status'].toString();
//                   String error = response['error'].toString();
//                   if (status == 'SUCCESS') {
//                     result = "Flow Completed - Status: Success!";
//                   } else {
//                     result =
//                         "Flow Completed - Status: $status and Error: $error";
//                   }
//                 } else {
//                   result = "Flow Incomplete";
//                 }
//               })
//             })
//         .catchError((error) {
//       handleError(error);
//       return <dynamic>{};
//     });
//   }

//   getChecksum() {
//     final reqData = {
//       "merchantId": merchantId,
//       "merchantTransactionId": "t_52554",
//       "merchantUserId": "MUID123",
//       "amount": 10000,
//       "callbackUrl": callback,
//       "mobileNumber": "9999999999",
//       "paymentInstrument": {"type": "PAY_PAGE"}
//     };

//     String base64body = base64.encode(utf8.encode(json.encode(reqData)));

//     checksum =
//         '${sha256.convert(utf8.encode(base64body + apiEndPoint + saltKey)).toString()}###$saltIndex';

//     return base64body;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("PhonePe"),
//       ),
//       body: Column(
//         children: [
//           Container(
//             child: ElevatedButton(
//                 onPressed: () {
//                   startTranscation();
//                 },
//                 child: const Text("PAY NOW")),
//           ),
//           Text("$result")
//         ],
//       ),
//     );
//   }
// }
