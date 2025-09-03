import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';
import 'package:racconnect/data/models/accomplishment_model.dart';
import 'package:racconnect/data/models/profile_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:racconnect/logic/cubit/attendance_cubit.dart';
import 'package:printing/printing.dart';

class ExportAccomplishmentsButton extends StatefulWidget {
  final int selectedYear;
  final int selectedMonth;

  const ExportAccomplishmentsButton({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
  });

  @override
  State<ExportAccomplishmentsButton> createState() =>
      _ExportAccomplishmentsButtonState();
}

class _ExportAccomplishmentsButtonState
    extends State<ExportAccomplishmentsButton> {
  bool _isExporting = false;

  Future<void> _exportToPDF() async {
    final authState = context.read<AuthCubit>().state;

    // Check if user is COS employee
    final isCOS =
        authState is AuthenticatedState &&
        authState.user.profile?.employmentStatus == 'COS';

    if (authState is AuthenticatedState) {
      if (isCOS) {
        // Show dialog for COS employees to choose export options
        _showCOSExportOptions(authState);
      } else {
        // For non-COS employees, automatically generate Annex A for the whole month.
        _performExport(authState, 'whole', true, isCOS);
      }
    }
  }

  Future<void> _showCOSExportOptions(AuthenticatedState authState) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Report Type'),
          content: const Text(
            'Choose the type of accomplishment report to generate:',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annex A (WFH)'),
              onPressed: () {
                Navigator.of(context).pop();
                _showPeriodSelection(authState, true);
              },
            ),
            TextButton(
              child: const Text('Accomplishment Report'),
              onPressed: () {
                Navigator.of(context).pop();
                _showPeriodSelection(authState, false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPeriodSelection(
    AuthenticatedState authState,
    bool isAnnexA,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Period'),
          content: const Text('Choose the period for the report:'),
          actions: <Widget>[
            TextButton(
              child: const Text('First Half (1-15)'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport(authState, 'first', isAnnexA, true);
              },
            ),
            TextButton(
              child: const Text('Second Half (16-last day)'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport(authState, 'second', isAnnexA, true);
              },
            ),
            TextButton(
              child: const Text('Whole Month'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport(authState, 'whole', isAnnexA, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performExport(
    AuthenticatedState authState,
    String? period,
    bool isAnnexA,
    bool isCOS,
  ) async {
    if (_isExporting) return;

    // Get user info and context before async gap to avoid BuildContext issues
    final attendanceCubit = context.read<AttendanceCubit>();
    String userName = 'Unknown User';
    String userPosition = '';
    String userOffice = '';

    // Try to get name from profile first
    userName =
        '${authState.user.profile?.firstName ?? ''} ${_getMiddleInitialFromMiddleName(authState.user.profile?.middleName)} ${authState.user.profile?.lastName ?? ''}'
            .trim();
    if (userName.isEmpty) {
      // Fallback to user name from UserModel
      userName = authState.user.name;
    }
    if (userName.isEmpty) {
      // Last resort fallback
      userName = 'Unknown User';
    }

    // Get position and office (using sectionName as office, fallback to sectionCode)
    userPosition = authState.user.profile?.position ?? '';
    userOffice = _getOfficeInfo(authState.user.profile);

    setState(() {
      _isExporting = true;
    });

    try {
      // Show loading indicator
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Exporting accomplishments to PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Get employee number
      final employeeNumber = authState.user.profile?.employeeNumber;
      if (employeeNumber == null || employeeNumber.isEmpty) {
        throw Exception('Employee number not found');
      }

      // Determine date range based on period
      DateTime startDate;
      DateTime endDate;

      if (period == 'first') {
        // First half of the month (1st to 15th)
        startDate = DateTime(widget.selectedYear, widget.selectedMonth, 1);
        endDate = DateTime(widget.selectedYear, widget.selectedMonth, 15);
      } else if (period == 'second') {
        // Second half of the month (16th to end of month)
        startDate = DateTime(widget.selectedYear, widget.selectedMonth, 16);
        endDate = DateTime(
          widget.selectedYear,
          widget.selectedMonth + 1,
          1,
        ).subtract(const Duration(days: 1));
      } else {
        // Whole month (default behavior)
        startDate = DateTime(widget.selectedYear, widget.selectedMonth, 1);
        endDate = DateTime(
          widget.selectedYear,
          widget.selectedMonth + 1,
          1,
        ).subtract(const Duration(days: 1));
      }

      final accomplishmentRepository = AccomplishmentRepository();
      final allAccomplishments = await accomplishmentRepository
          .getEmployeeAccomplishmentsForMonth(
            employeeNumber,
            startDate,
            endDate,
          );

      // Filter accomplishments based on report type
      List<AccomplishmentModel> filteredAccomplishments;

      if (isAnnexA) {
        // Annex A report - only include WFH accomplishments
        final attendanceRepository = attendanceCubit.attendanceRepository;
        final attendanceRecords = await attendanceRepository
            .getEmployeeAttendanceForMonth(employeeNumber, startDate);

        // Filter to only WFH attendance records
        final wfhAttendanceRecords =
            attendanceRecords
                .where((record) => record.type.toLowerCase().contains('wfh'))
                .toList();

        // Create a set of dates that have WFH attendance
        final wfhDates = <DateTime>{};
        for (var record in wfhAttendanceRecords) {
          final date = DateTime(
            record.timestamp.year,
            record.timestamp.month,
            record.timestamp.day,
          );
          wfhDates.add(date);
        }

        // Filter accomplishments to only include those with WFH attendance
        filteredAccomplishments =
            allAccomplishments.where((accomplishment) {
              final accomplishmentDate = DateTime(
                accomplishment.date.year,
                accomplishment.date.month,
                accomplishment.date.day,
              );
              return wfhDates.contains(accomplishmentDate);
            }).toList();
      } else {
        // Simple Accomplishment Report - include all accomplishments
        filteredAccomplishments = allAccomplishments;
      }

      // Generate PDF content
      final pdfFile = await _generatePDF(
        filteredAccomplishments,
        startDate,
        userName,
        userPosition,
        userOffice,
        period: period,
        isAnnexA: isAnnexA,
        isCOS: isCOS,
      );

      if (!mounted) return;

      // Check platform and handle accordingly
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: Share the PDF file
        final params = ShareParams(
          subject:
              'Accomplishments Report - ${DateFormat('MMMM yyyy').format(startDate)}',
          files: [XFile(pdfFile.path)],
        );

        final result = await SharePlus.instance.share(params);

        if (!mounted) return;

        if (result.status == ShareResultStatus.success) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('PDF exported successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('PDF exported successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Desktop: Open the file in the default PDF viewer
        final uri = Uri.file(pdfFile.path);
        if (await launchUrl(uri)) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('PDF saved and opened: ${pdfFile.path}'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('PDF saved to: ${pdfFile.path}'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<File> _generatePDF(
    List<AccomplishmentModel> accomplishments,
    DateTime month,
    String userName,
    String userPosition,
    String userOffice, {
    String? period,
    bool isAnnexA = true,
    bool isCOS = false,
  }) async {
    final pdf = pw.Document();

    // Load header and footer images
    pw.MemoryImage? headerImage;
    pw.MemoryImage? footerImage;

    try {
      final headerData = await rootBundle.load('assets/images/header.png');
      if (headerData.lengthInBytes > 0) {
        headerImage = pw.MemoryImage(headerData.buffer.asUint8List());
      }
    } catch (e) {
      headerImage = null;
    }

    try {
      final footerData = await rootBundle.load('assets/images/footer.png');
      if (footerData.lengthInBytes > 0) {
        footerImage = pw.MemoryImage(footerData.buffer.asUint8List());
      }
    } catch (e) {
      footerImage = null;
    }

    final garamond = await PdfGoogleFonts.cormorantGaramondRegular();
    final garamondBold = await PdfGoogleFonts.cormorantGaramondBold();

    final tableHeaders = [
      'Date',
      'Activity / Deliverables',
      'Accomplishment',
      'Remarks',
    ];

    final tableData =
        accomplishments
            .map(
              (acc) => [
                DateFormat('MMM dd, yyyy').format(acc.date),
                acc.target.replaceAll('\n', ' ').replaceAll('\r', ' '),
                acc.accomplishment.replaceAll('\n', ' ').replaceAll('\r', ' '),
                '',
              ],
            )
            .toList();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginTop: 20,
            marginBottom: 20,
            marginLeft: 20,
            marginRight: 20,
          ),
          theme: pw.ThemeData.withFont(base: garamond, bold: garamondBold),
        ),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              if (headerImage != null)
                pw.Center(
                  child: pw.Image(
                    headerImage,
                    height: 120,
                    width: PdfPageFormat.a4.width * 0.9,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              pw.SizedBox(height: 20),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 5),
              pw.Container(height: 1, color: PdfColors.black),
              pw.SizedBox(height: 10),
              if (footerImage != null)
                pw.Image(
                  footerImage,
                  height: 60,
                  width: PdfPageFormat.a4.width - 40,
                  fit: pw.BoxFit.cover,
                )
              else
                pw.SizedBox(height: 60),
            ],
          );
        },
        build:
            (pw.Context context) => [
              if (isAnnexA) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'ANNEX A',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(width: 20),
                  ],
                ),
                pw.SizedBox(height: 5),
              ] else if (isCOS) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'ACCOMPLISHMENT REPORT',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
              ],
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1.2),
                columnWidths: {
                  0: pw.FractionColumnWidth(0.15),
                  1: pw.FractionColumnWidth(0.35),
                  2: pw.FractionColumnWidth(0.15),
                  3: pw.FractionColumnWidth(0.35),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Container(
                          width: 70,
                          child: pw.Text(
                            'Name:',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Container(
                          width: 180,
                          child: pw.Text(
                            userName,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Container(
                          width: 90,
                          child: pw.Text(
                            'Period Covered:',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Container(
                          width: 160,
                          child: pw.Text(
                            _getPeriodCoveredText(month, period),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Container(
                          width: 70,
                          child: pw.Text(
                            'Position:',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Container(
                          width: 180,
                          child: pw.Text(
                            userPosition,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Container(
                          width: 90,
                          child: pw.Text(
                            'Office:',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Container(
                          width: 160,
                          child: pw.Text(
                            userOffice,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              // Custom table implementation with proper multi-page support and custom column widths
              pw.Table(
                border: pw.TableBorder.all(),
                tableWidth: pw.TableWidth.max,
                columnWidths: {
                  0: pw.FractionColumnWidth(0.15), // Date (10%)
                  1: pw.FractionColumnWidth(0.35), // Deliverables (35%)
                  2: pw.FractionColumnWidth(0.35), // Accomplishment (35%)
                  3: pw.FractionColumnWidth(0.15), // Remarks (20%)
                },
                children: [
                  // Header row with grey background
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          tableHeaders[0],
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          tableHeaders[1],
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          tableHeaders[2],
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          tableHeaders[3],
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...tableData.map(
                    (row) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            row[0],
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            row[1],
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            row[2],
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            row[3],
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        child: pw.Text(
                          'Prepared by: $userName${_getMiddleInitial(userName)}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        child: pw.Text(
                          'Approved by: ${_getUnitHeadName(null)}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  '*** THIS IS A SYSTEM-GENERATED REPORT. NOTHING FOLLOWS. ***',
                  style: pw.TextStyle(color: PdfColors.black, fontSize: 6),
                ),
              ),
            ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'accomplishments_${DateFormat('yyyy-MM').format(month)}.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Helper to get middle initial from middle name (null-safe)
  String _getMiddleInitialFromMiddleName(String? middleName) {
    if (middleName != null && middleName.trim().isNotEmpty) {
      return '${middleName.trim()[0]}.';
    }
    return '';
  }

  /// Get office information with fallbacks
  String _getOfficeInfo(ProfileModel? profile) {
    // Try sectionName first
    if (profile?.sectionName?.isNotEmpty ?? false) {
      return profile!.sectionName!;
    }

    // Fallback to sectionCode
    if (profile?.sectionCode?.isNotEmpty ?? false) {
      return profile!.sectionCode!;
    }

    // Fallback to a generic office name if section exists but no name
    if (profile?.section?.isNotEmpty ?? false) {
      return 'N/A'; // Don't expose raw section IDs
    }

    // If all else fails, return N/A
    return 'N/A';
  }

  String _getPeriodCoveredText(DateTime month, String? period) {
    if (period == null || period == 'whole') {
      return DateFormat('MMMM yyyy').format(month);
    }

    switch (period) {
      case 'first':
        return '${DateFormat('MMMM').format(month)} 1-15, ${DateFormat('y').format(month)}';
      case 'second':
        final lastDay =
            DateTime(
              month.year,
              month.month + 1,
              1,
            ).subtract(const Duration(days: 1)).day;
        return '${DateFormat('MMMM').format(month)} 16-$lastDay, ${DateFormat('y').format(month)}';
      default:
        return DateFormat('MMMM yyyy').format(month);
    }
  }

  String _getMiddleInitial(String fullName) {
    // Extract middle initial from full name
    final parts = fullName.split(' ');
    if (parts.length >= 3) {
      // Assuming format: First Middle Last
      return ' ${parts[1][0]}.'; // Return middle initial with space and period
    }
    return ''; // No middle name found
  }

  String _getUnitHeadName(ProfileModel? profile) {
    // For now, default to John S. Calidguid, RSW, MPA
    // In a future enhancement, this could lookup the actual unit head based on section
    return 'John S. Calidguid, RSW, MPA';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 5, // Position at the bottom
      right: 5,
      child: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _exportToPDF,
        child:
            _isExporting
                ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                )
                : const Icon(Icons.picture_as_pdf, color: Colors.deepPurple),
      ),
    );
  }
}
