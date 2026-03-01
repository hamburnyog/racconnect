import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:racconnect/data/models/forum_attendee.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/forum_cubit.dart';
import 'package:racconnect/utility/forum_email_sender.dart';
import 'package:url_launcher/url_launcher.dart';

class CertificatePreviewSheet extends StatefulWidget {
  final ForumAttendee attendee;
  final bool showSuccess;
  final bool isAuthorized;

  const CertificatePreviewSheet({
    super.key,
    required this.attendee,
    this.showSuccess = false,
    this.isAuthorized = false,
  });

  @override
  State<CertificatePreviewSheet> createState() =>
      _CertificatePreviewSheetState();
}

class _CertificatePreviewSheetState extends State<CertificatePreviewSheet> {
  Uint8List? _svgBytes;
  pw.Font? _font;
  pw.Font? _fontBold;
  bool _isLoading = true;
  bool _showCalibration = false;

  // Calibration State
  double nameTop = 128.0;
  double nameLeft = 46.0;
  double nameWidth = 150.0;
  double nameFontSize = 24.0;

  double addrTop = 145.0;
  double addrLeft = 46.0;
  double addrWidth = 150.0;
  double addrFontSize = 10.0;

  double forumDateTop = 166.0;
  double forumDateLeft = 50.0;
  double forumDateWidth = 40.0;
  double forumDateFontSize = 12.0;

  double certDateTop = 224.0;
  double certDateLeft = 72.0;
  double certDateWidth = 56.0;
  double certDateFontSize = 12.0;

  // QR Calibration State
  double qrTop = 262.0;
  double qrLeft = 193.0;
  double qrSize = 9.0;

  @override
  void initState() {
    super.initState();
    _loadAssets();
    if (widget.showSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Valid Certificate Found!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  Future<void> _loadAssets() async {
    try {
      final bool isFosterCare =
          widget.attendee.type.toLowerCase().contains('foster care');

      final String svgPath = isFosterCare
          ? 'assets/certificate/TEMPLATE CERT DRAFT.svg'
          : 'assets/certificate/PREADOPTION CERT DRAFT.svg';

      final svgData = await rootBundle.load(svgPath);
      final svgBytes = svgData.buffer.asUint8List();
      final font = await PdfGoogleFonts.libreBaskervilleRegular();
      final fontBold = await PdfGoogleFonts.libreBaskervilleBold();

      if (mounted) {
        setState(() {
          _svgBytes = svgBytes;
          _font = font;
          _fontBold = fontBold;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatOrdinal(int day) {
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

  String _formatFullOrdinalDate(DateTime date) {
    final dayOrdinal = _formatOrdinal(date.day);
    final monthYear = DateFormat('MMMM yyyy').format(date);
    return '$dayOrdinal of $monthYear';
  }

  void _resetToDefault() {
    setState(() {
      nameTop = 123.0;
      nameLeft = 46.0;
      nameWidth = 150.0;
      nameFontSize = 24.0;
      addrTop = 145.0;
      addrLeft = 46.0;
      addrWidth = 150.0;
      addrFontSize = 10.0;
      forumDateTop = 166.0;
      forumDateLeft = 50.0;
      forumDateWidth = 40.0;
      forumDateFontSize = 12.0;
      certDateTop = 224.0;
      certDateLeft = 72.0;
      certDateWidth = 56.0;
      certDateFontSize = 12.0;
      qrTop = 262.0;
      qrLeft = 193.0;
      qrSize = 9.0;
    });
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: _font, bold: _fontBold),
    );

    final forumDateStr = DateFormat(
      'MMMM d, yyyy',
    ).format(widget.attendee.forumDate ?? DateTime.now());
    final certDateStr =
        widget.attendee.emailSentDate != null
            ? _formatFullOrdinalDate(widget.attendee.emailSentDate!)
            : '(For sending)';

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
              if (_svgBytes != null)
                pw.Positioned.fill(
                  child: pw.SvgImage(svg: String.fromCharCodes(_svgBytes!)),
                ),

              pw.Positioned(
                top: y(nameTop),
                left: x(nameLeft),
                child: pw.Container(
                  width: x(nameWidth),
                  decoration:
                      _showCalibration
                          ? pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.red300,
                              width: 0.5,
                            ),
                          )
                          : null,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    widget.attendee.name.toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: _fontBold,
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
                  decoration:
                      _showCalibration
                          ? pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.blue300,
                              width: 0.5,
                            ),
                          )
                          : null,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    widget.attendee.address,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: _fontBold,
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
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: const pw.BorderSide(
                        color: PdfColors.black,
                        width: 1.0,
                      ),
                      left:
                          _showCalibration
                              ? const pw.BorderSide(
                                color: PdfColors.green300,
                                width: 0.5,
                              )
                              : pw.BorderSide.none,
                      right:
                          _showCalibration
                              ? const pw.BorderSide(
                                color: PdfColors.green300,
                                width: 0.5,
                              )
                              : pw.BorderSide.none,
                      top:
                          _showCalibration
                              ? const pw.BorderSide(
                                color: PdfColors.green300,
                                width: 0.5,
                              )
                              : pw.BorderSide.none,
                    ),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    forumDateStr,
                    style: pw.TextStyle(
                      font: _font,
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
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: const pw.BorderSide(
                        color: PdfColors.black,
                        width: 1.0,
                      ),
                      left:
                          _showCalibration
                              ? const pw.BorderSide(
                                color: PdfColors.orange300,
                                width: 0.5,
                              )
                              : pw.BorderSide.none,
                      right:
                          _showCalibration
                              ? const pw.BorderSide(
                                color: PdfColors.orange300,
                                width: 0.5,
                              )
                              : pw.BorderSide.none,
                      top:
                          _showCalibration
                              ? const pw.BorderSide(
                                color: PdfColors.orange300,
                                width: 0.5,
                              )
                              : pw.BorderSide.none,
                    ),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    certDateStr,
                    style: pw.TextStyle(
                      font: _fontBold,
                      fontSize: certDateFontSize,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),

              pw.Positioned(
                top: y(qrTop),
                left: x(qrLeft),
                child: pw.Container(
                  padding: _showCalibration ? const pw.EdgeInsets.all(1) : null,
                  decoration:
                      _showCalibration
                          ? pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.purple300,
                              width: 0.5,
                            ),
                          )
                          : null,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: widget.attendee.id,
                    width: x(qrSize),
                    height: x(qrSize),
                    drawText: false,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _savePdf() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _generatePdf(PdfPageFormat.a4.landscape);
      final fileName =
          'Certificate_${widget.attendee.name.replaceAll(' ', '_')}.pdf';

      if (kIsWeb) {
        // Handle web if needed
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Use FilePicker for a better desktop "Save As" experience
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Certificate PDF',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (outputFile != null) {
          // Add .pdf extension if it's missing (some platforms might not add it automatically)
          if (!outputFile.toLowerCase().endsWith('.pdf')) {
            outputFile = '$outputFile.pdf';
          }

          final file = File(outputFile);
          await file.writeAsBytes(bytes);

          messenger.showSnackBar(
            SnackBar(
              content: Text('Saved successfully!'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () async {
                  final uri = Uri.file(file.path);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ),
          );
        }
      } else {
        // Use share sheet for mobile (Android/iOS)
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to save PDF: $e')));
    }
  }

  Future<void> _sendEmail() async {
    if (widget.attendee.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email address provided for this recipient.'),
        ),
      );
      return;
    }

    final sender = ForumEmailSender(
      context: context,
      attendees: [widget.attendee],
    );

    await sender.sendEmails();
  }

  Future<void> _markAsSent() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Sent?'),
        content: const Text(
          'This will mark the certificate as "Sent" using today\'s date. No email will actually be sent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark as Sent'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final updatedAttendee = ForumAttendee(
        id: widget.attendee.id,
        name: widget.attendee.name,
        address: widget.attendee.address,
        email: widget.attendee.email,
        type: widget.attendee.type,
        forumDate: widget.attendee.forumDate,
        emailSentDate: DateTime.now(),
      );

      await context.read<ForumCubit>().updateAttendee(
            widget.attendee.id,
            updatedAttendee,
          );

      if (mounted) {
        Navigator.pop(context); // Close the preview sheet
      }
    }
  }

  Widget _buildControlRow(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  onChanged: (v) => setState(() => onChanged(v)),
                ),
              ),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: TextEditingController(
                    text: value.toStringAsFixed(1),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 11),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (v) {
                    final newVal = double.tryParse(v);
                    if (newVal != null) setState(() => onChanged(newVal));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationPanel(bool isHorizontal) {
    return Container(
      width: isHorizontal ? 300 : double.infinity,
      height: isHorizontal ? double.infinity : 250,
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'CALIBRATION',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Divider(),
            _buildControlRow('Name Top', nameTop, 0, 300, (v) => nameTop = v),
            _buildControlRow(
              'Name Left',
              nameLeft,
              0,
              300,
              (v) => nameLeft = v,
            ),
            _buildControlRow(
              'Name Width',
              nameWidth,
              10,
              300,
              (v) => nameWidth = v,
            ),
            _buildControlRow(
              'Name Size',
              nameFontSize,
              5,
              80,
              (v) => nameFontSize = v,
            ),
            const Divider(),
            _buildControlRow('Addr Top', addrTop, 0, 300, (v) => addrTop = v),
            _buildControlRow(
              'Addr Left',
              addrLeft,
              0,
              300,
              (v) => addrLeft = v,
            ),
            _buildControlRow(
              'Addr Width',
              addrWidth,
              10,
              300,
              (v) => addrWidth = v,
            ),
            _buildControlRow(
              'Addr Size',
              addrFontSize,
              5,
              40,
              (v) => addrFontSize = v,
            ),
            const Divider(),
            _buildControlRow(
              'Forum Top',
              forumDateTop,
              0,
              300,
              (v) => forumDateTop = v,
            ),
            _buildControlRow(
              'Forum Left',
              forumDateLeft,
              0,
              300,
              (v) => forumDateLeft = v,
            ),
            _buildControlRow(
              'Forum Width',
              forumDateWidth,
              10,
              300,
              (v) => forumDateWidth = v,
            ),
            _buildControlRow(
              'Forum Size',
              forumDateFontSize,
              5,
              50,
              (v) => forumDateFontSize = v,
            ),
            const Divider(),
            _buildControlRow(
              'Cert Top',
              certDateTop,
              0,
              300,
              (v) => certDateTop = v,
            ),
            _buildControlRow(
              'Cert Left',
              certDateLeft,
              0,
              300,
              (v) => certDateLeft = v,
            ),
            _buildControlRow(
              'Cert Width',
              certDateWidth,
              10,
              300,
              (v) => certDateWidth = v,
            ),
            _buildControlRow(
              'Cert Size',
              certDateFontSize,
              5,
              50,
              (v) => certDateFontSize = v,
            ),
            const Divider(),
            const Text(
              'QR CODE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            _buildControlRow('QR Top', qrTop, 0, 300, (v) => qrTop = v),
            _buildControlRow('QR Left', qrLeft, 0, 300, (v) => qrLeft = v),
            _buildControlRow('QR Size', qrSize, 5, 100, (v) => qrSize = v),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            AppBar(
              title: Text('Certificate: ${widget.attendee.name}'),
              automaticallyImplyLeading: false,
              actions: [
                if (_showCalibration)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _resetToDefault,
                    tooltip: 'Reset to Default Values',
                  ),
                if (widget.isAuthorized)
                  IconButton(
                    icon: Icon(
                      _showCalibration ? Icons.visibility_off : Icons.tune,
                    ),
                    onPressed: () =>
                        setState(() => _showCalibration = !_showCalibration),
                    tooltip: 'Toggle Calibration',
                  ),
                if (!_showCalibration) ...[
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      String role = '';
                      if (authState is AuthenticatedState) {
                        role = authState.user.role ?? '';
                      }
                      if (role == 'Developer') {
                        return IconButton(
                          icon: const Icon(Icons.mark_email_read),
                          onPressed: _markAsSent,
                          tooltip: 'Mark as Sent',
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  if (widget.isAuthorized)
                    IconButton(
                      icon: const Icon(Icons.forward_to_inbox),
                      onPressed: _sendEmail,
                      tooltip: 'Send to Email',
                    ),
                  IconButton(
                    icon: const Icon(Icons.save_alt),
                    onPressed: _savePdf,
                    tooltip: 'Save as PDF',
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child:
                  isLargeScreen
                      ? Row(
                        children: [
                          Expanded(
                            flex: _showCalibration ? 80 : 100,
                            child: PdfPreview(
                              padding: EdgeInsets.zero,
                              key: ValueKey(
                                '$_showCalibration-$nameTop-$nameLeft-$nameWidth-$nameFontSize-$addrTop-$addrLeft-$addrWidth-$addrFontSize-$forumDateTop-$forumDateLeft-$forumDateWidth-$forumDateFontSize-$certDateTop-$certDateLeft-$certDateWidth-$certDateFontSize-$qrTop-$qrLeft-$qrSize',
                              ),
                              build: _generatePdf,
                              initialPageFormat: PdfPageFormat.a4.landscape,
                              canChangePageFormat: false,
                              canChangeOrientation: false,
                              canDebug: false,
                              allowPrinting: false,
                              allowSharing: false,
                              actions: [],
                            ),
                          ),
                          if (_showCalibration) _buildCalibrationPanel(true),
                        ],
                      )
                      : Column(
                        children: [
                          Expanded(
                            child: PdfPreview(
                              padding: EdgeInsets.zero,
                              key: ValueKey(
                                '$_showCalibration-$nameTop-$nameLeft-$nameWidth-$nameFontSize-$addrTop-$addrLeft-$addrWidth-$addrFontSize-$forumDateTop-$forumDateLeft-$forumDateWidth-$forumDateFontSize-$certDateTop-$certDateLeft-$certDateWidth-$certDateFontSize-$qrTop-$qrLeft-$qrSize',
                              ),
                              build: _generatePdf,
                              initialPageFormat: PdfPageFormat.a4.landscape,
                              canChangePageFormat: false,
                              canChangeOrientation: false,
                              canDebug: false,
                              allowPrinting: false,
                              allowSharing: false,
                              actions: [],
                            ),
                          ),
                          if (_showCalibration) _buildCalibrationPanel(false),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
