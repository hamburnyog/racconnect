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
  final double? nameTop;
  final double? nameLeft;
  final double? nameWidth;
  final double? nameFontSize;
  final double? addrTop;
  final double? addrLeft;
  final double? addrWidth;
  final double? addrFontSize;
  final double? forumDateTop;
  final double? forumDateLeft;
  final double? forumDateWidth;
  final double? forumDateFontSize;
  final double? certDateTop;
  final double? certDateLeft;
  final double? certDateWidth;
  final double? certDateFontSize;
  final double? qrTop;
  final double? qrLeft;
  final double? qrSize;

  ForumEmailSender({
    required this.context,
    required this.attendees,
    this.nameTop,
    this.nameLeft,
    this.nameWidth,
    this.nameFontSize,
    this.addrTop,
    this.addrLeft,
    this.addrWidth,
    this.addrFontSize,
    this.forumDateTop,
    this.forumDateLeft,
    this.forumDateWidth,
    this.forumDateFontSize,
    this.certDateTop,
    this.certDateLeft,
    this.certDateWidth,
    this.certDateFontSize,
    this.qrTop,
    this.qrLeft,
    this.qrSize,
  });

  final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);
  final ValueNotifier<String> statusNotifier = ValueNotifier('Preparing...');
  late BuildContext dialogContext;

  static void addCertificatePage({
    required pw.Document pdf,
    required ForumAttendee attendee,
    required Uint8List svgBytes,
    required pw.Font font,
    required pw.Font fontBold,
    double nameTop = 128.0,
    double nameLeft = 46.0,
    double nameWidth = 150.0,
    double nameFontSize = 24.0,
    double addrTop = 145.0,
    double addrLeft = 46.0,
    double addrWidth = 150.0,
    double addrFontSize = 10.0,
    double forumDateTop = 166.0,
    double forumDateLeft = 50.0,
    double forumDateWidth = 40.0,
    double forumDateFontSize = 12.0,
    double certDateTop = 224.0,
    double certDateLeft = 72.0,
    double certDateWidth = 56.0,
    double certDateFontSize = 12.0,
    double qrTop = 262.0,
    double qrLeft = 193.0,
    double qrSize = 9.0,
  }) {
    final forumDateStr = DateFormat(
      'MMMM d, yyyy',
    ).format(attendee.forumDate ?? DateTime.now());

    final sentDate = attendee.emailSentDate ?? DateTime.now();
    final day = sentDate.day;
    final monthYear = DateFormat('MMMM yyyy').format(sentDate);

    String suffix = 'th';
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }

    final pageFormat = PdfPageFormat.a4.landscape.copyWith(
      marginTop: 0,
      marginBottom: 0,
      marginLeft: 0,
      marginRight: 0,
    );

    double x(double mm) => (mm / 210) * pageFormat.width;
    double y(double mm) => (mm / 297) * pageFormat.height;

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
                  child: attendee.emailSentDate == null
                      ? pw.Text(
                          '(For sending)',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: certDateFontSize,
                            color: PdfColors.black,
                          ),
                        )
                      : pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: '$day',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: certDateFontSize,
                                  color: PdfColors.black,
                                ),
                              ),
                              pw.WidgetSpan(
                                baseline: 0.5,
                                child: pw.Transform.translate(
                                  offset: const PdfPoint(0, 4),
                                  child: pw.Text(
                                    suffix,
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: certDateFontSize * 0.6,
                                      color: PdfColors.black,
                                    ),
                                  ),
                                ),
                              ),
                              pw.TextSpan(
                                text: ' of $monthYear',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: certDateFontSize,
                                  color: PdfColors.black,
                                ),
                              ),
                            ],
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

    addCertificatePage(
      pdf: pdf,
      attendee: attendee,
      svgBytes: svgBytes,
      font: font,
      fontBold: fontBold,
    );

    return pdf.save();
  }

  Future<void> sendEmails() async {
    if (attendees.isEmpty) return;

    if (smtpUsername.isEmpty || smtpPassword.isEmpty) {
      _showSnackBar(
        'SMTP Error: Username or Password not configured. Please check your environment settings.',
        false,
      );
      return;
    }

    _showProgressDialog();

    int total = attendees.length;
    int success = 0;
    int failed = 0;

    try {
      final font = await PdfGoogleFonts.libreBaskervilleRegular();
      final fontBold = await PdfGoogleFonts.libreBaskervilleBold();

      final smtpServerInstance = SmtpServer(
        smtpServer,
        port: smtpPort,
        username: smtpUsername,
        password: smtpPassword,
      );

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

          // Determine the date to use for the PDF
          // If first time sending, use 'now'. If already sent, use the existing date.
          final DateTime sentDateToUse = attendee.emailSentDate ?? DateTime.now();

          // Create a version of attendee with the correct date for the PDF
          final attendeeForCert = attendee.copyWith(emailSentDate: sentDateToUse);

          final forumDateStr = DateFormat(
            'MMMM d, yyyy',
          ).format(attendee.forumDate ?? DateTime.now());

          final htmlBody = _processTemplate(rawTemplate, attendee);
          
          final fromEmail = smtpFromEmail.isNotEmpty 
              ? smtpFromEmail 
              : (smtpUsername.contains('@') ? smtpUsername : '');

          if (fromEmail.isEmpty) {
            failed++;
            statusNotifier.value = 'Invalid "From" email configuration';
            debugPrint('Error: smtpFromEmail and smtpUsername are not valid email addresses.');
            continue;
          }

          final recipients = attendee.emails;

          if (recipients.isEmpty) {
            failed++;
            statusNotifier.value = 'No valid email for ${attendee.name}';
            continue;
          }

          final message =
              Message()
                ..from = Address(fromEmail, smtpFromName)
                ..recipients.addAll(recipients)
                ..subject =
                    'Forum Certificate ($forumDateStr): ${attendee.name}'
                ..html = htmlBody;

          // 1. Add Main Certificate Attachment
          final mainPdf = pw.Document(
            theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          );

          addCertificatePage(
            pdf: mainPdf,
            attendee: attendeeForCert,
            svgBytes: svgBytes,
            font: font,
            fontBold: fontBold,
            nameTop: nameTop ?? 128.0,
            nameLeft: nameLeft ?? 46.0,
            nameWidth: nameWidth ?? 150.0,
            nameFontSize: nameFontSize ?? 24.0,
            addrTop: addrTop ?? 145.0,
            addrLeft: addrLeft ?? 46.0,
            addrWidth: addrWidth ?? 150.0,
            addrFontSize: addrFontSize ?? 10.0,
            forumDateTop: forumDateTop ?? 166.0,
            forumDateLeft: forumDateLeft ?? 50.0,
            forumDateWidth: forumDateWidth ?? 40.0,
            forumDateFontSize: forumDateFontSize ?? 12.0,
            certDateTop: certDateTop ?? 224.0,
            certDateLeft: certDateLeft ?? 72.0,
            certDateWidth: certDateWidth ?? 56.0,
            certDateFontSize: certDateFontSize ?? 12.0,
            qrTop: qrTop ?? 262.0,
            qrLeft: qrLeft ?? 193.0,
            qrSize: qrSize ?? 9.0,
          );

          final mainBytes = await mainPdf.save();
          message.attachments.add(
            StreamAttachment(
              Stream.value(mainBytes),
              'application/pdf',
              fileName:
                  'Certificate_${attendee.name.replaceAll(' ', '_')}.pdf',
            ),
          );

          // 2. Add Spouse Certificate Attachment if available
          if (attendee.spouseName != null && attendee.spouseName!.isNotEmpty) {
            final spousePdf = pw.Document(
              theme: pw.ThemeData.withFont(base: font, bold: fontBold),
            );
            final spouseAttendeeForCert = attendeeForCert.copyWith(
              name: attendee.spouseName!,
            );
            addCertificatePage(
              pdf: spousePdf,
              attendee: spouseAttendeeForCert,
              svgBytes: svgBytes,
              font: font,
              fontBold: fontBold,
              nameTop: nameTop ?? 128.0,
              nameLeft: nameLeft ?? 46.0,
              nameWidth: nameWidth ?? 150.0,
              nameFontSize: nameFontSize ?? 24.0,
              addrTop: addrTop ?? 145.0,
              addrLeft: addrLeft ?? 46.0,
              addrWidth: addrWidth ?? 150.0,
              addrFontSize: addrFontSize ?? 10.0,
              forumDateTop: forumDateTop ?? 166.0,
              forumDateLeft: forumDateLeft ?? 50.0,
              forumDateWidth: forumDateWidth ?? 40.0,
              forumDateFontSize: forumDateFontSize ?? 12.0,
              certDateTop: certDateTop ?? 224.0,
              certDateLeft: certDateLeft ?? 72.0,
              certDateWidth: certDateWidth ?? 56.0,
              certDateFontSize: certDateFontSize ?? 12.0,
              qrTop: qrTop ?? 262.0,
              qrLeft: qrLeft ?? 193.0,
              qrSize: qrSize ?? 9.0,
            );
            final spouseBytes = await spousePdf.save();
            message.attachments.add(
              StreamAttachment(
                Stream.value(spouseBytes),
                'application/pdf',
                fileName:
                    'Certificate_${attendee.spouseName!.replaceAll(' ', '_')}.pdf',
              ),
            );
          }

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
          if (attendee.emailSentDate == null && context.mounted) {
            await context.read<ForumCubit>().updateAttendee(
              attendee.id,
              attendee.copyWith(emailSentDate: sentDateToUse),
              silent: true,
            );
          }
          success++;
        } catch (e) {
          failed++;
          statusNotifier.value = 'Failed for ${attendee.name}: $e';
          debugPrint('Error sending email to ${attendee.name}: $e');
          // Wait a bit so user can see the error
          await Future.delayed(const Duration(seconds: 3));
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
