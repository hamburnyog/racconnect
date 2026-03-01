import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:racconnect/data/models/forum_attendee.dart';
import 'package:racconnect/logic/cubit/forum_cubit.dart';
import 'package:racconnect/utility/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForumEmailSender {
  final BuildContext context;
  final List<ForumAttendee> attendees;

  ForumEmailSender({required this.context, required this.attendees});

  final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);
  final ValueNotifier<String> statusNotifier = ValueNotifier('Preparing...');
  late BuildContext dialogContext;

  static String _formatOrdinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  static String _formatFullOrdinalDate(DateTime date) {
    final dayOrdinal = _formatOrdinal(date.day);
    final monthYear = DateFormat('MMMM yyyy').format(date);
    return '$dayOrdinal of $monthYear';
  }

  Future<String> _getTemplate() async {
    try {
      return await rootBundle.loadString('assets/certificate/email_template.html');
    } catch (e) {
      debugPrint('Error loading email template from assets: $e');
    }

    // Default template fallback if asset fails to load
    return '''<p>Dear {{name}},</p>
<p>Isang mapagarugang araw!</p>
<p>Attached is your Forum Certificate. We are truly grateful for your participation—this marks a meaningful first step in your adoption/foster care journey, and we commend you for taking it.</p>
<p><b>Please note that this certificate is system-generated.</b> If you notice any concerns or require clarification, feel free to reach out and we will be happy to assist you.</p>
<p>Thank you once again, and we wish you all the best as you move forward in this important and inspiring path.</p>
<p>Kind regards,</p>
<p><b>RACCO IV-A Calabarzon</b></p>''';
  }

  String _processTemplate(String template, ForumAttendee attendee) {
    final forumDateStr = DateFormat(
      'MMMM d, yyyy',
    ).format(attendee.forumDate ?? DateTime.now());

    return template
        .replaceAll('{{name}}', attendee.name)
        .replaceAll('{{forum_date}}', forumDateStr)
        .replaceAll('{{address}}', attendee.address)
        .replaceAll('{{type}}', attendee.type);
  }

  static Future<Uint8List> generateCertificatePdf({
    required ForumAttendee attendee,
    required Uint8List svgBytes,
    required pw.Font font,
    required pw.Font fontBold,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    final forumDateStr = DateFormat(
      'MMMM d, yyyy',
    ).format(attendee.forumDate ?? DateTime.now());
    final certDateStr =
        attendee.emailSentDate != null
            ? _formatFullOrdinalDate(attendee.emailSentDate!)
            : '(For sending)';

    final pageFormat = PdfPageFormat.a4.landscape.copyWith(
      marginTop: 0,
      marginBottom: 0,
      marginLeft: 0,
      marginRight: 0,
    );

    double x(double mm) => (mm / 210) * pageFormat.width;
    double y(double mm) => (mm / 297) * pageFormat.height;

    // Calibration values (matching CertificatePreviewSheet defaults)
    const double nameTop = 123.0;
    const double nameLeft = 46.0;
    const double nameWidth = 150.0;
    const double nameFontSize = 24.0;

    const double addrTop = 145.0;
    const double addrLeft = 46.0;
    const double addrWidth = 150.0;
    const double addrFontSize = 10.0;

    const double forumDateTop = 166.0;
    const double forumDateLeft = 50.0;
    const double forumDateWidth = 40.0;
    const double forumDateFontSize = 12.0;

    const double certDateTop = 224.0;
    const double certDateLeft = 72.0;
    const double certDateWidth = 56.0;
    const double certDateFontSize = 12.0;

    const double qrTop = 262.0;
    const double qrLeft = 193.0;
    const double qrSize = 9.0;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.SvgImage(svg: String.fromCharCodes(svgBytes)),
              ),
              pw.Positioned(
                top: y(nameTop),
                left: x(nameLeft),
                child: pw.Container(
                  width: x(nameWidth),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    attendee.name.toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: nameFontSize,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),
              pw.Positioned(
                top: y(addrTop),
                left: x(addrLeft),
                child: pw.Container(
                  width: x(addrWidth),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    attendee.address,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: addrFontSize,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),
              pw.Positioned(
                top: y(forumDateTop),
                left: x(forumDateLeft),
                child: pw.Container(
                  width: x(forumDateWidth),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1.0),
                    ),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    forumDateStr,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: forumDateFontSize,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),
              pw.Positioned(
                top: y(certDateTop),
                left: x(certDateLeft),
                child: pw.Container(
                  width: x(certDateWidth),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1.0),
                    ),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    certDateStr,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: certDateFontSize,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),
              pw.Positioned(
                top: y(qrTop),
                left: x(qrLeft),
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: attendee.id,
                  width: x(qrSize),
                  height: x(qrSize),
                  drawText: false,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> sendEmails() async {
    if (attendees.isEmpty) return;

    _showProgressDialog();

    int total = attendees.length;
    int success = 0;
    int failed = 0;

    try {
      final font = await PdfGoogleFonts.libreBaskervilleRegular();
      final fontBold = await PdfGoogleFonts.libreBaskervilleBold();

      final smtpServerInstance = gmail(smtpUsername, smtpPassword);

      final rawTemplate = await _getTemplate();

      // Load used email images from assets
      final Map<String, Uint8List> emailImages = {};
      final List<String> imageNames = [
        'image1.png', 
        'image2.png', 
        'image3.png', 
        'image4.jpg', 
        'image5.png', 
        'image6.png', 
        'image7.png', 
        'image8.png', 
        'image9.png',
      ];

      for (final name in imageNames) {
        try {
          final data = await rootBundle.load('assets/certificate/email_images/$name');
          emailImages[name] = data.buffer.asUint8List();
        } catch (e) {
          debugPrint('Error loading image $name: $e');
        }
      }

      for (int i = 0; i < attendees.length; i++) {
        final attendee = attendees[i];
        statusNotifier.value = 'Sending to ${attendee.name}...';
        progressNotifier.value = i / total;

        try {
          // 1. Choose template based on type (Case-insensitive check)
          final bool isFosterCare =
              attendee.type.toLowerCase().contains('foster care');

          final String svgPath = isFosterCare
              ? 'assets/certificate/TEMPLATE CERT DRAFT.svg'
              : 'assets/certificate/PREADOPTION CERT DRAFT.svg';

          final svgData = await rootBundle.load(svgPath);
          final svgBytes = svgData.buffer.asUint8List();

          // Determine if this is the first time sending
          final bool isFirstTime = attendee.emailSentDate == null;
          // Use original date if available, otherwise use 'now'
          final DateTime sentDateToUse =
              attendee.emailSentDate ?? DateTime.now();

          // Create a version of attendee with the correct date for the PDF
          final attendeeForCert = ForumAttendee(
            id: attendee.id,
            name: attendee.name,
            address: attendee.address,
            email: attendee.email,
            type: attendee.type,
            forumDate: attendee.forumDate,
            emailSentDate: sentDateToUse,
          );

          final bytes = await generateCertificatePdf(
            attendee: attendeeForCert,
            svgBytes: svgBytes,
            font: font,
            fontBold: fontBold,
          );

          final forumDateStr = DateFormat(
            'MMMM d, yyyy',
          ).format(attendee.forumDate ?? DateTime.now());

          final htmlBody = _processTemplate(rawTemplate, attendee);

          final message =
              Message()
                ..from = Address(smtpFromEmail, smtpFromName)
                ..recipients.addAll(attendee.emails)
                ..subject =
                    'Forum Certificate ($forumDateStr): ${attendee.name}'
                ..html = htmlBody
                ..attachments.add(
                  StreamAttachment(
                    Stream.value(bytes),
                    'application/pdf',
                    fileName:
                        'Certificate_${attendee.name.replaceAll(' ', '_')}.pdf',
                  ),
                );

          // Add CID image attachments
          emailImages.forEach((name, data) {
            final cid = name.split('.').first.replaceAll(' ', '_'); // e.g. "racco_sig"
            final mimeType = name.endsWith('.jpg') ? 'image/jpeg' : 'image/png';
            message.attachments.add(
              StreamAttachment(
                Stream.value(data),
                mimeType,
                fileName: name,
              )
              ..location = Location.inline
              ..cid = cid,
            );
          });

          await send(message, smtpServerInstance);

          // ONLY update the database if this is the first successful send
          if (isFirstTime && context.mounted) {
            await context.read<ForumCubit>().updateAttendee(
              attendee.id,
              ForumAttendee(
                id: attendee.id,
                name: attendee.name,
                address: attendee.address,
                email: attendee.email,
                type: attendee.type,
                forumDate: attendee.forumDate,
                emailSentDate: sentDateToUse,
              ),
              silent: true,
            );
          }
          success++;
        } catch (e) {
          failed++;
        }
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e', false);
    }

    progressNotifier.value = 1.0;
    statusNotifier.value = 'Finished: $success sent, $failed failed.';

    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted) {
      try {
        Navigator.of(dialogContext).pop();
      } catch (_) {}
    }

    _showSnackBar('Sent $success certificates successfully!', true);
  }

  void _showProgressDialog() {
    if (!context.mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Sending Emails',
      pageBuilder: (BuildContext dialogCtx, _, __) {
        dialogContext = dialogCtx;
        return AlertDialog(
          // title: const Text('Sending Certificates'),
          content: SizedBox(
            height: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: statusNotifier,
                  builder:
                      (_, value, __) =>
                          Text(value, style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<double>(
                  valueListenable: progressNotifier,
                  builder:
                      (_, value, __) => LinearProgressIndicator(value: value),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<double>(
                  valueListenable: progressNotifier,
                  builder: (_, value, __) => Text('${(value * 100).toInt()}%'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }
}
