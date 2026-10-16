import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/trippay/trippay_pin_page.dart';

/// Supported payment methods for bookings and other flows.
enum PaymentMethod { trippay, creditCard, cash }

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.trippay:
        return 'TripPay';
      case PaymentMethod.creditCard:
        return 'Thẻ tín dụng';
      case PaymentMethod.cash:
        return 'Tiền mặt';
    }
  }
}

/// Utility helpers used by the various booking pages to ask for and process
/// a payment.
class PaymentHelper {
  /// Ask the user which method they want to use. Returns `null` if the
  /// dialog was cancelled.
  static Future<PaymentMethod?> chooseMethod(BuildContext context) {
    return showDialog<PaymentMethod?>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Chọn phương thức thanh toán'),
          children: PaymentMethod.values.map((m) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m),
              child: Text(
                m == PaymentMethod.trippay
                    ? '${m.displayName} (ưu tiên hàng đầu)'
                    : m.displayName,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Execute the payment flow for the selected method. Returns `true` if the
  /// operation succeeded (or was deferred for cash), or `false` if the user
  /// cancelled / payment failed.
  static Future<bool> processPayment(
    BuildContext context,
    PaymentMethod method,
    double amount,
  ) async {
    switch (method) {
      case PaymentMethod.trippay:
        // Open PIN entry and wait for result.  When the PIN page is
        // constructed with `redirectToHome: false` it simply pops with a bool
        // instead of navigating to the wallet screen.
        final paid =
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const TripPayPinPage(redirectToHome: false),
              ),
            ) ??
            false;
        if (paid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Thanh toán ${amount.toStringAsFixed(0)} đ bằng TripPay thành công',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanh toán bằng TripPay thất bại')),
          );
        }
        return paid;
      case PaymentMethod.creditCard:
        // For now we just show a placeholder dialog. Integration with a real
        // gateway would happen here.
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Thanh toán bằng thẻ tín dụng'),
              content: Text(
                'Xác nhận thanh toán ${amount.toStringAsFixed(0)} đ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
        if (confirm == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Thanh toán bằng thẻ tín dụng thành công (giả lập)',
              ),
            ),
          );
          return true;
        }
        return false;
      case PaymentMethod.cash:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn sẽ thanh toán bằng tiền mặt khi nhận dịch vụ'),
          ),
        );
        return true;
    }
  }
}
