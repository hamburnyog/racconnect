import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:racconnect/data/models/forum_attendee.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

class CertificatePreviewPage extends StatefulWidget {
  final ForumAttendee attendee;

  const CertificatePreviewPage({super.key, required this.attendee});

  @override
  State<CertificatePreviewPage> createState() => _CertificatePreviewPageState();
}

class _CertificatePreviewPageState extends State<CertificatePreviewPage> {
  Uint8List? _svgBytes;
  pw.Font? _font;
  pw.Font? _fontBold;
  bool _isLoading = true;
  bool _showCalibration = false;

  // Calibration State with provided final default values
  double nameTop = 123.0;
  double nameLeft = 46.0;
  double nameWidth = 150.0;
  double nameFontSize = 32.0;
  
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

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final svgData = await rootBundle.load('assets/certificate/TEMPLATE CERT DRAFT.svg');
      final svgBytes = svgData.buffer.asUint8List();
      
      // Using Libre Baskerville as a high-quality alternative to Bookman Old Style
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatOrdinal(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
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

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    
    final forumDate = widget.attendee.forumDate ?? DateTime.now();
    final certDate = widget.attendee.certificateDate ?? DateTime.now();

    final forumDateStr = DateFormat('MMMM d, yyyy').format(forumDate);
    final certDateStr = _formatFullOrdinalDate(certDate);

    final pageFormat = PdfPageFormat.a4.landscape.copyWith(
      marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0,
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
                pw.Positioned.fill(child: pw.SvgImage(svg: String.fromCharCodes(_svgBytes!))),
              
              // Name Container
              pw.Positioned(
                top: y(nameTop),
                left: x(nameLeft),
                child: pw.Container(
                  width: x(nameWidth),
                  decoration: _showCalibration ? pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red300, width: 0.5),
                  ) : null,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    widget.attendee.name.toUpperCase(),
                    style: pw.TextStyle(font: _fontBold, fontSize: nameFontSize, color: PdfColors.black),
                  ),
                ),
              ),
              
              // Address Container
              pw.Positioned(
                top: y(addrTop),
                left: x(addrLeft),
                child: pw.Container(
                  width: x(addrWidth),
                  decoration: _showCalibration ? pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue300, width: 0.5),
                  ) : null,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    widget.attendee.address,
                    style: pw.TextStyle(font: _fontBold, fontSize: addrFontSize, color: PdfColors.black),
                  ),
                ),
              ),
              
              // Forum Date Container - Permanent Black Bottom Border
              pw.Positioned(
                top: y(forumDateTop),
                left: x(forumDateLeft),
                child: pw.Container(
                  width: x(forumDateWidth),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: const pw.BorderSide(color: PdfColors.black, width: 1.0),
                      left: _showCalibration ? const pw.BorderSide(color: PdfColors.green300, width: 0.5) : pw.BorderSide.none,
                      right: _showCalibration ? const pw.BorderSide(color: PdfColors.green300, width: 0.5) : pw.BorderSide.none,
                      top: _showCalibration ? const pw.BorderSide(color: PdfColors.green300, width: 0.5) : pw.BorderSide.none,
                    ),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    forumDateStr,
                    style: pw.TextStyle(font: _font, fontSize: forumDateFontSize, color: PdfColors.black),
                  ),
                ),
              ),
              
              // Cert Date Container - Permanent Black Bottom Border - Bold Text
              pw.Positioned(
                top: y(certDateTop),
                left: x(certDateLeft),
                child: pw.Container(
                  width: x(certDateWidth),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: const pw.BorderSide(color: PdfColors.black, width: 1.0),
                      left: _showCalibration ? const pw.BorderSide(color: PdfColors.orange300, width: 0.5) : pw.BorderSide.none,
                      right: _showCalibration ? const pw.BorderSide(color: PdfColors.orange300, width: 0.5) : pw.BorderSide.none,
                      top: _showCalibration ? const pw.BorderSide(color: PdfColors.orange300, width: 0.5) : pw.BorderSide.none,
                    ),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    certDateStr,
                    style: pw.TextStyle(font: _fontBold, fontSize: certDateFontSize, color: PdfColors.black),
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
      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final fileName = 'Certificate_${widget.attendee.name.replaceAll(' ', '_')}.pdf';
      final file = File(p.join(dir.path, fileName));
      await file.writeAsBytes(bytes);
      
      messenger.showSnackBar(
        SnackBar(
          content: Text('Saved to: ${file.path}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              final uri = Uri.file(file.path);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Widget _buildControlRow(String label, double value, double min, double max, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                width: 60,
                child: TextField(
                  controller: TextEditingController(text: value.toStringAsFixed(1)),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate Preview'),
        actions: [
          IconButton(
            icon: Icon(_showCalibration ? Icons.visibility_off : Icons.tune),
            onPressed: () => setState(() => _showCalibration = !_showCalibration),
            tooltip: 'Toggle Calibration',
          ),
          if (_showCalibration)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                debugPrint('--- CALIBRATION ---');
                debugPrint('name: top:$nameTop, left:$nameLeft, width:$nameWidth, size:$nameFontSize');
                debugPrint('addr: top:$addrTop, left:$addrLeft, width:$addrWidth, size:$addrFontSize');
                debugPrint('forum: top:$forumDateTop, left:$forumDateLeft, width:$forumDateWidth, size:$forumDateFontSize');
                debugPrint('cert: top:$certDateTop, left:$certDateLeft, width:$certDateWidth, size:$certDateFontSize');
              },
              tooltip: 'Log to Console',
            ),
          IconButton(icon: const Icon(Icons.save), onPressed: _savePdf, tooltip: 'Save to Downloads'),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: PdfPreview(
              key: ValueKey('$_showCalibration-$nameTop-$nameLeft-$nameWidth-$nameFontSize-$addrTop-$addrLeft-$addrWidth-$addrFontSize-$forumDateTop-$forumDateLeft-$forumDateWidth-$forumDateFontSize-$certDateTop-$certDateLeft-$certDateWidth-$certDateFontSize'),
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
          if (_showCalibration)
            Container(
              width: 320,
              color: Colors.grey.shade100,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('CALIBRATION CONTROLS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    _buildControlRow('Name Top', nameTop, 0, 300, (v) => nameTop = v),
                    _buildControlRow('Name Left', nameLeft, 0, 300, (v) => nameLeft = v),
                    _buildControlRow('Name Width', nameWidth, 10, 300, (v) => nameWidth = v),
                    _buildControlRow('Name Size', nameFontSize, 5, 80, (v) => nameFontSize = v),
                    const Divider(),
                    _buildControlRow('Addr Top', addrTop, 0, 300, (v) => addrTop = v),
                    _buildControlRow('Addr Left', addrLeft, 0, 300, (v) => addrLeft = v),
                    _buildControlRow('Addr Width', addrWidth, 10, 300, (v) => addrWidth = v),
                    _buildControlRow('Addr Size', addrFontSize, 5, 40, (v) => addrFontSize = v),
                    const Divider(),
                    _buildControlRow('Forum Top', forumDateTop, 0, 300, (v) => forumDateTop = v),
                    _buildControlRow('Forum Left', forumDateLeft, 0, 300, (v) => forumDateLeft = v),
                    _buildControlRow('Forum Width', forumDateWidth, 10, 300, (v) => forumDateWidth = v),
                    _buildControlRow('Forum Size', forumDateFontSize, 5, 50, (v) => forumDateFontSize = v),
                    const Divider(),
                    _buildControlRow('Cert Top', certDateTop, 0, 300, (v) => certDateTop = v),
                    _buildControlRow('Cert Left', certDateLeft, 0, 300, (v) => certDateLeft = v),
                    _buildControlRow('Cert Width', certDateWidth, 10, 300, (v) => certDateWidth = v),
                    _buildControlRow('Cert Size', certDateFontSize, 5, 50, (v) => certDateFontSize = v),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _savePdf,
                      icon: const Icon(Icons.save),
                      label: const Text('Save PDF Now'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
