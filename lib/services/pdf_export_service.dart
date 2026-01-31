// =============================================================================
// YemenChat - PDF Export Service
// =============================================================================
// Service for generating and exporting chat conversations to PDF format.
// =============================================================================

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

/// Service for exporting chat conversations to PDF
class PDFExportService {
  /// Generate PDF from chat messages
  ///
  /// [messages] - List of messages to export
  /// [currentUser] - Current user info
  /// [otherUser] - Other user info
  /// [chatName] - Name of the chat (optional, defaults to other user's name)
  /// [startDate] - Optional start date filter
  /// [endDate] - Optional end date filter
  ///
  /// Returns the file path of the generated PDF
  Future<String> generateChatPDF({
    required List<MessageModel> messages,
    required UserModel currentUser,
    required UserModel otherUser,
    String? chatName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Filter messages by date range if provided
    var filteredMessages = messages;
    if (startDate != null || endDate != null) {
      filteredMessages =
          messages.where((msg) {
            if (startDate != null && msg.time.isBefore(startDate)) return false;
            if (endDate != null && msg.time.isAfter(endDate)) return false;
            return true;
          }).toList();
    }

    // Sort messages by date (oldest first for PDF)
    filteredMessages.sort((a, b) => a.time.compareTo(b.time));

    // Create PDF document
    final pdf = pw.Document();

    // Format dates for header
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final exportDate = DateFormat(
      'dd MMMM yyyy - HH:mm',
    ).format(DateTime.now());

    // Add page(s) to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (context) => [
              // Header
              _buildHeader(
                chatName ?? otherUser.fullName,
                exportDate,
                filteredMessages.length,
                startDate != null ? dateFormat.format(startDate) : null,
                endDate != null ? dateFormat.format(endDate) : null,
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Messages
              ...filteredMessages.map((message) {
                final isSentByMe = message.senderId == currentUser.id;
                final sender = isSentByMe ? currentUser : otherUser;

                return _buildMessage(
                  sender.fullName,
                  message.text,
                  timeFormat.format(message.time),
                  dateFormat.format(message.time),
                  isSentByMe,
                );
              }).toList(),
            ],
        footer:
            (context) => _buildFooter(context.pageNumber, context.pagesCount),
      ),
    );

    // Save PDF to file
    final output = await _getOutputFile(otherUser.fullName);
    final file = File(output);
    await file.writeAsBytes(await pdf.save());

    return output;
  }

  /// Build PDF header
  pw.Widget _buildHeader(
    String chatName,
    String exportDate,
    int messageCount,
    String? startDate,
    String? endDate,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Chat Conversation Export',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Chat with: $chatName',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Exported on: $exportDate',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        if (startDate != null || endDate != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Date range: ${startDate ?? 'Start'} - ${endDate ?? 'End'}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
        pw.SizedBox(height: 4),
        pw.Text(
          'Total messages: $messageCount',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
      ],
    );
  }

  /// Build a single message in PDF
  pw.Widget _buildMessage(
    String senderName,
    String messageText,
    String time,
    String date,
    bool isSentByMe,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: isSentByMe ? PdfColors.green50 : PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: isSentByMe ? PdfColors.green200 : PdfColors.grey300,
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Sender and time
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                senderName,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: isSentByMe ? PdfColors.green900 : PdfColors.grey900,
                ),
              ),
              pw.Text(
                '$date $time',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          // Message text
          pw.Text(messageText, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  /// Build PDF footer
  pw.Widget _buildFooter(int pageNumber, int totalPages) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        'Page $pageNumber of $totalPages',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  /// Get output file path
  Future<String> _getOutputFile(String chatName) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final sanitizedName = chatName.replaceAll(RegExp(r'[^\w\s-]'), '');
    return '${directory.path}/Chat_${sanitizedName}_$timestamp.pdf';
  }
}
