import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import 'package:flutter/services.dart';

class InvoiceGenerator {
  // ===== STORE INFO — update these =====
  static const String storeName = "NATURAL FRUITS AND VEGETABLES";
  static const String storeAddress =
      "In front of MM college, Madam Mahal Station Road,\nWright Town, Jabalpur";
  static const String storePhone = "9109493750";
  static const String storeEmail = "naturalfruitveg25@gmail.com";
  static const String storeState = "23-Madhya Pradesh";
  // =====================================

  /// Call this to download invoice PDF
  static Future<void> downloadInvoice(
      BuildContext context, Order order) async {
    final pdf = await _buildPdf(order);
    await Printing.sharePdf(
      bytes: pdf,
      filename:
          'invoice_${order.id.substring(order.id.length - 6)}.pdf',
    );
  }

  static Future<Uint8List> _buildPdf(Order order) async {
    final doc = pw.Document();

    // Fonts
    final fontBold = pw.Font.timesBold();
    final fontNormal = pw.Font.times();
    final fontHelvetica = pw.Font.helvetica();
    final fontHelveticaBold = pw.Font.helveticaBold();

    // Colors
    const headerBg = PdfColor.fromInt(0xFF2E7D32); // dark green
    const lightGreen = PdfColor.fromInt(0xFFE8F5E9);
    const tableHeader = PdfColor.fromInt(0xFF1B5E20);
    const borderColor = PdfColor.fromInt(0xFFBDBDBD);
    const black = PdfColors.black;
    const white = PdfColors.white;

    final orderNumber =
        order.id.substring(order.id.length - 6).toUpperCase();
    final orderDate =
        DateFormat('dd-MM-yyyy').format(order.createdAt);
    final orderTime =
        DateFormat('hh:mm a').format(order.createdAt);
    final logoBytes = await rootBundle.load('assets/best_logo.png');
final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());   

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ========== HEADER ==========
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Store info
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          storeName,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 14,
                            color: black,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          storeAddress,
                          style: pw.TextStyle(
                              font: fontNormal, fontSize: 9),
                        ),
                        pw.Text(
                          "Phone no.: $storePhone",
                          style: pw.TextStyle(
                              font: fontNormal, fontSize: 9),
                        ),
                        pw.Text(
                          "Email: $storeEmail",
                          style: pw.TextStyle(
                              font: fontNormal, fontSize: 9),
                        ),
                        pw.Text(
                          "State: $storeState",
                          style: pw.TextStyle(
                              font: fontNormal, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  // Logo circle
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      color: lightGreen,
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(
                          color: headerBg, width: 2),
                    ),
                    child: pw.ClipOval(
  child: pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Image(
      logoImage,
      fit: pw.BoxFit.contain,
    ),
  ),
  ),
),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(color: borderColor),
              pw.SizedBox(height: 8),

              // ========== TITLE ==========
              pw.Center(
                child: pw.Text(
                  "Sale Order",
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 16,
                    color: headerBg,
                  ),
                ),
              ),

              pw.SizedBox(height: 12),

              // ========== ORDER FROM + DETAILS ==========
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: Order From
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                            color: borderColor, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Order From",
                            style: pw.TextStyle(
                                font: fontBold, fontSize: 10),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            order.customerName,
                            style: pw.TextStyle(
                                font: fontBold, fontSize: 10),
                          ),
                          pw.Text(
                            order.paymentMethod.toUpperCase(),
                            style: pw.TextStyle(
                                font: fontNormal, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 12),

                  // Right: Order Details
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                            color: borderColor, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            "Order Details",
                            style: pw.TextStyle(
                                font: fontBold, fontSize: 10),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            "Order No.: $orderNumber",
                            style: pw.TextStyle(
                                font: fontNormal, fontSize: 9),
                          ),
                          pw.Text(
                            "Date: $orderDate",
                            style: pw.TextStyle(
                                font: fontNormal, fontSize: 9),
                          ),
                          pw.Text(
                            "Time: $orderTime",
                            style: pw.TextStyle(
                                font: fontNormal, fontSize: 9),
                          ),
                          pw.Text(
                            "Due Date: $orderDate",
                            style: pw.TextStyle(
                                font: fontHelveticaBold,
                                fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // ========== ITEMS TABLE ==========
              pw.Table(
                border: pw.TableBorder.all(
                    color: borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FixedColumnWidth(55),
                  3: const pw.FixedColumnWidth(40),
                  4: const pw.FixedColumnWidth(65),
                  5: const pw.FixedColumnWidth(65),
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration:
                        pw.BoxDecoration(color: tableHeader),
                    children: [
                      _tableCell("#", fontHelveticaBold,
                          color: white, center: true),
                      _tableCell(
                          "Item Name", fontHelveticaBold,
                          color: white),
                      _tableCell("Quantity", fontHelveticaBold,
                          color: white, center: true),
                      _tableCell("Unit", fontHelveticaBold,
                          color: white, center: true),
                      _tableCell(
                          "Price/ Unit", fontHelveticaBold,
                          color: white, center: true),
                      _tableCell("Amount", fontHelveticaBold,
                          color: white, center: true),
                    ],
                  ),

                  // Item rows
                  ...order.items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final amount = item.price * item.quantity;
                    final isEven = i % 2 == 0;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven
                            ? PdfColors.white
                            : lightGreen,
                      ),
                      children: [
                        _tableCell(
                            '${i + 1}', fontHelvetica,
                            center: true, fontSize: 9),
                        _tableCell(item.name, fontHelvetica,
                            fontSize: 9),
                        _tableCell(
                            item.quantity.toString(),
                            fontHelvetica,
                            center: true,
                            fontSize: 9),
                        _tableCell("Kg", fontHelvetica,
                            center: true, fontSize: 9),
                        _tableCell(
                            "Rs. ${item.price.toStringAsFixed(2)}",
                            fontHelvetica,
                            center: true,
                            fontSize: 9),
                        _tableCell(
                            "Rs. ${amount.toStringAsFixed(2)}",
                            fontHelvetica,
                            center: true,
                            fontSize: 9),
                      ],
                    );
                  }).toList(),

                  // Total row
                  pw.TableRow(
                    decoration:
                        pw.BoxDecoration(color: lightGreen),
                    children: [
                      _tableCell("", fontHelveticaBold),
                      _tableCell("Total", fontHelveticaBold,
                          fontSize: 10),
                      _tableCell(
                          order.items.length.toString(),
                          fontHelveticaBold,
                          center: true,
                          fontSize: 10),
                      _tableCell("", fontHelveticaBold),
                      _tableCell("", fontHelveticaBold),
                      _tableCell(
                          "Rs. ${order.itemsTotal.toStringAsFixed(2)}",
                          fontHelveticaBold,
                          center: true,
                          fontSize: 10),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // ========== BOTTOM SECTION ==========
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: Amount in words + Terms
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "Order Amount In Words",
                          style: pw.TextStyle(
                              font: fontBold, fontSize: 9),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _amountInWords(order.grandTotal),
                          style: pw.TextStyle(
                              font: fontNormal, fontSize: 9),
                        ),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          "Terms And Conditions",
                          style: pw.TextStyle(
                              font: fontBold, fontSize: 9),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "Thank you for doing business with us.",
                          style: pw.TextStyle(
                              font: fontNormal, fontSize: 9),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(width: 12),

                  // Right: Summary table
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(
                          color: borderColor, width: 0.5),
                      children: [
                        _summaryRow(
                            "Sub Total",
                            "Rs. ${order.itemsTotal.toStringAsFixed(2)}",
                            fontNormal),
                        _summaryRowHighlight(
                            "Total",
                            "Rs. ${order.grandTotal.toStringAsFixed(2)}",
                            fontBold,
                            headerBg),
                        if (order.deliveryCharge > 0)
                          _summaryRow(
                              "Delivery Charge",
                              "Rs. ${order.deliveryCharge.toStringAsFixed(2)}",
                              fontNormal),
                        if (order.handlingCharge > 0)
                          _summaryRow(
                              "Handling Charge",
                              "Rs. ${order.handlingCharge.toStringAsFixed(2)}",
                              fontNormal),
                        _summaryRow(
                            "Advance", "Rs. 0.00", fontNormal),
                        _summaryRow(
                            "Balance",
                            "Rs. ${order.grandTotal.toStringAsFixed(2)}",
                            fontNormal),
                        _summaryRow(
                            "Payment Mode",
                            order.paymentMethod.toUpperCase(),
                            fontNormal),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // ========== FOOTER ==========
              pw.Divider(color: borderColor),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "For: $storeName",
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 9),
                  ),
                  pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.center,
                    children: [
                      pw.SizedBox(height: 20),
                      pw.Text(
                        "Authorized Signatory",
                        style: pw.TextStyle(
                            font: fontBold, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  "Status: ${order.orderStatus.toUpperCase()} | Payment: ${order.paymentStatus.toUpperCase()}",
                  style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 8,
                      color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ===== HELPERS =====

  static pw.Widget _tableCell(
    String text,
    pw.Font font, {
    PdfColor color = PdfColors.black,
    bool center = false,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign:
            center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
            font: font, fontSize: fontSize, color: color),
      ),
    );
  }

  static pw.TableRow _summaryRow(
      String label, String value, pw.Font font) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(
              horizontal: 6, vertical: 4),
          child: pw.Text(label,
              style: pw.TextStyle(font: font, fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(
              horizontal: 6, vertical: 4),
          child: pw.Text(value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: font, fontSize: 9)),
        ),
      ],
    );
  }

  static pw.TableRow _summaryRowHighlight(String label,
      String value, pw.Font font, PdfColor bg) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(
              horizontal: 6, vertical: 4),
          child: pw.Text(label,
              style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: PdfColors.white)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(
              horizontal: 6, vertical: 4),
          child: pw.Text(value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: PdfColors.white)),
        ),
      ],
    );
  }

  static String _amountInWords(double amount) {
    final int rupees = amount.toInt();
    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen'
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety'
    ];

    String convert(int n) {
      if (n == 0) return '';
      if (n < 20) return ones[n];
      if (n < 100)
        return tens[n ~/ 10] +
            (n % 10 != 0 ? ' ${ones[n % 10]}' : '');
      if (n < 1000)
        return '${ones[n ~/ 100]} Hundred${n % 100 != 0 ? ' ${convert(n % 100)}' : ''}';
      if (n < 100000)
        return '${convert(n ~/ 1000)} Thousand${n % 1000 != 0 ? ' ${convert(n % 1000)}' : ''}';
      if (n < 10000000)
        return '${convert(n ~/ 100000)} Lakh${n % 100000 != 0 ? ' ${convert(n % 100000)}' : ''}';
      return '${convert(n ~/ 10000000)} Crore${n % 10000000 != 0 ? ' ${convert(n % 10000000)}' : ''}';
    }

    final words = convert(rupees);
    return '$words Rupees Only';
  }
}