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
import 'package:racconnect/presentation/widgets/forum_attendee_form.dart';
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
  bool _isUpdating = false;
  bool _showCalibration = false;
  late String _selectedName;

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
    _selectedName = widget.attendee.name;
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

  void _resetToDefault() {
    setState(() {
      nameTop = 128.0;
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

  Future<Uint8List> _generatePdfWithAttendee(PdfPageFormat format, ForumAttendee attendee) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: _font, bold: _fontBold),
    );

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
                    _selectedName.toUpperCase(),
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
                    attendee.address,
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
                  child: attendee.emailSentDate == null
                      ? pw.Text(
                          '(For sending)',
                          style: pw.TextStyle(
                            font: _fontBold,
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
                                  font: _fontBold,
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
                                      font: _fontBold,
                                      fontSize: certDateFontSize * 0.6,
                                      color: PdfColors.black,
                                    ),
                                  ),
                                ),
                              ),
                              pw.TextSpan(
                                text: ' of $monthYear',
                                style: pw.TextStyle(
                                  font: _fontBold,
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
                    data: attendee.id,
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

  Future<void> _savePdfWithAttendee(ForumAttendee attendee) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: _font, bold: _fontBold),
      );

      // Add main attendee page
      ForumEmailSender.addCertificatePage(
        pdf: pdf,
        attendee: attendee,
        svgBytes: _svgBytes!,
        font: _font!,
        fontBold: _fontBold!,
        nameTop: nameTop,
        nameLeft: nameLeft,
        nameWidth: nameWidth,
        nameFontSize: nameFontSize,
        addrTop: addrTop,
        addrLeft: addrLeft,
        addrWidth: addrWidth,
        addrFontSize: addrFontSize,
        forumDateTop: forumDateTop,
        forumDateLeft: forumDateLeft,
        forumDateWidth: forumDateWidth,
        forumDateFontSize: forumDateFontSize,
        certDateTop: certDateTop,
        certDateLeft: certDateLeft,
        certDateWidth: certDateWidth,
        certDateFontSize: certDateFontSize,
        qrTop: qrTop,
        qrLeft: qrLeft,
        qrSize: qrSize,
      );

      // Add spouse page if exists
      if (attendee.spouseName != null && attendee.spouseName!.isNotEmpty) {
        ForumEmailSender.addCertificatePage(
          pdf: pdf,
          attendee: attendee.copyWith(name: attendee.spouseName!),
          svgBytes: _svgBytes!,
          font: _font!,
          fontBold: _fontBold!,
          nameTop: nameTop,
          nameLeft: nameLeft,
          nameWidth: nameWidth,
          nameFontSize: nameFontSize,
          addrTop: addrTop,
          addrLeft: addrLeft,
          addrWidth: addrWidth,
          addrFontSize: addrFontSize,
          forumDateTop: forumDateTop,
          forumDateLeft: forumDateLeft,
          forumDateWidth: forumDateWidth,
          forumDateFontSize: forumDateFontSize,
          certDateTop: certDateTop,
          certDateLeft: certDateLeft,
          certDateWidth: certDateWidth,
          certDateFontSize: certDateFontSize,
          qrTop: qrTop,
          qrLeft: qrLeft,
          qrSize: qrSize,
        );
      }

      final bytes = await pdf.save();
      final fileName =
          'Certificate_${attendee.name.replaceAll(' ', '_')}.pdf';

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

  Future<void> _sendEmailWithAttendee(ForumAttendee attendee) async {
    if (attendee.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email address provided for this recipient.'),
        ),
      );
      return;
    }

    final sender = ForumEmailSender(
      context: context,
      attendees: [attendee],
      nameTop: nameTop,
      nameLeft: nameLeft,
      nameWidth: nameWidth,
      nameFontSize: nameFontSize,
      addrTop: addrTop,
      addrLeft: addrLeft,
      addrWidth: addrWidth,
      addrFontSize: addrFontSize,
      forumDateTop: forumDateTop,
      forumDateLeft: forumDateLeft,
      forumDateWidth: forumDateWidth,
      forumDateFontSize: forumDateFontSize,
      certDateTop: certDateTop,
      certDateLeft: certDateLeft,
      certDateWidth: certDateWidth,
      certDateFontSize: certDateFontSize,
      qrTop: qrTop,
      qrLeft: qrLeft,
      qrSize: qrSize,
    );

    await sender.sendEmails();
  }

  Future<void> _markAsSentWithAttendee(ForumAttendee attendee) async {
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
      final updatedAttendee = attendee.copyWith(
        emailSentDate: DateTime.now(),
      );

      await context.read<ForumCubit>().updateAttendee(
            attendee.id,
            updatedAttendee,
          );
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
      return const Scaffold(body: SizedBox.shrink());
    }

    final width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 900;

    return BlocConsumer<ForumCubit, ForumState>(
      listener: (context, state) {
        if (state is ForumLoading) {
          setState(() => _isUpdating = true);
        } else if (state is ForumUpdateSuccess ||
            state is ForumUpdateSilentSuccess ||
            state is ForumLoaded ||
            state is ForumError) {
          setState(() => _isUpdating = false);
        }
      },
      builder: (context, state) {
        ForumAttendee attendee = widget.attendee;
        if (state is ForumLoaded) {
          try {
            attendee = state.allAttendees
                .firstWhere((a) => a.id == widget.attendee.id);
          } catch (_) {}
        }

        return Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.transparent,
              body: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    AppBar(
                      title: Text('Certificate: $_selectedName'),
                      automaticallyImplyLeading: false,
                      actions: [
                        if (attendee.spouseName != null &&
                            attendee.spouseName!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.swap_horiz),
                            tooltip:
                                'Switch to ${_selectedName == attendee.name ? 'Spouse' : 'Main'} Certificate',
                            onPressed: () {
                              setState(() {
                                _selectedName = (_selectedName == attendee.name)
                                    ? attendee.spouseName!
                                    : attendee.name;
                              });
                            },
                          ),
                        if (_showCalibration)
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _resetToDefault,
                            tooltip: 'Reset to Default Values',
                          ),
                        if (widget.isAuthorized) ...[
                          if (!_showCalibration)
                            IconButton(
                              icon: const Icon(Icons.edit_note),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  scrollControlDisabledMaxHeightRatio: 0.75,
                                  showDragHandle: true,
                                  useSafeArea: true,
                                  builder: (BuildContext builder) {
                                    return ForumAttendeeForm(
                                      forumAttendee: attendee,
                                    );
                                  },
                                );
                              },
                              tooltip: 'Edit Attendee',
                            ),
                        ],
                        if (!_showCalibration) ...[
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, authState) {
                              String role = '';
                              if (authState is AuthenticatedState) {
                                role = authState.user.role ?? '';
                              }
                              if (role == 'Developer') {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.mark_email_read),
                                      onPressed: () =>
                                          _markAsSentWithAttendee(attendee),
                                      tooltip: 'Mark as Sent',
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          if (widget.isAuthorized)
                            IconButton(
                              icon: const Icon(Icons.forward_to_inbox),
                              onPressed: () => _sendEmailWithAttendee(attendee),
                              tooltip: 'Send to Email',
                            ),
                          IconButton(
                            icon: const Icon(Icons.save_alt),
                            onPressed: () => _savePdfWithAttendee(attendee),
                            tooltip: 'Save as PDF',
                          ),
                        ],
                        if (widget.isAuthorized)
                          IconButton(
                            icon: Icon(
                              _showCalibration
                                  ? Icons.playlist_remove
                                  : Icons.tune,
                            ),
                            onPressed: () => setState(
                                () => _showCalibration = !_showCalibration),
                            tooltip: _showCalibration
                                ? 'Finish Calibration'
                                : 'Toggle Calibration',
                          ),
                        if (!_showCalibration)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                      ],
                    ),
                    Expanded(
                      child: isLargeScreen
                          ? Row(
                              children: [
                                Expanded(
                                  flex: _showCalibration ? 80 : 100,
                                  child: PdfPreview(
                                    padding: EdgeInsets.zero,
                                    key: ValueKey(
                                      '$_showCalibration-$_selectedName-${attendee.emailSentDate}-$nameTop-$nameLeft-$nameWidth-$nameFontSize-$addrTop-$addrLeft-$addrWidth-$addrFontSize-$forumDateTop-$forumDateLeft-$forumDateWidth-$forumDateFontSize-$certDateTop-$certDateLeft-$certDateWidth-$certDateFontSize-$qrTop-$qrLeft-$qrSize',
                                    ),
                                    build: (format) => _generatePdfWithAttendee(
                                        format, attendee),
                                    initialPageFormat:
                                        PdfPageFormat.a4.landscape,
                                    canChangePageFormat: false,
                                    canChangeOrientation: false,
                                    canDebug: false,
                                    allowPrinting: false,
                                    allowSharing: false,
                                    actions: [],
                                  ),
                                ),
                                if (_showCalibration)
                                  _buildCalibrationPanel(true),
                              ],
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: PdfPreview(
                                    padding: EdgeInsets.zero,
                                    key: ValueKey(
                                      '$_showCalibration-$_selectedName-${attendee.emailSentDate}-$nameTop-$nameLeft-$nameWidth-$nameFontSize-$addrTop-$addrLeft-$addrWidth-$addrFontSize-$forumDateTop-$forumDateLeft-$forumDateWidth-$forumDateFontSize-$certDateTop-$certDateLeft-$certDateWidth-$certDateFontSize-$qrTop-$qrLeft-$qrSize',
                                    ),
                                    build: (format) => _generatePdfWithAttendee(
                                        format, attendee),
                                    initialPageFormat:
                                        PdfPageFormat.a4.landscape,
                                    canChangePageFormat: false,
                                    canChangeOrientation: false,
                                    canDebug: false,
                                    allowPrinting: false,
                                    allowSharing: false,
                                    actions: [],
                                  ),
                                ),
                                if (_showCalibration)
                                  _buildCalibrationPanel(false),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isUpdating)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(50),
                ),
              ),
          ],
        );
      },
    );
  }
}
