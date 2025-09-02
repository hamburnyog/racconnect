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
        // Regular export for non-COS employees
        _performExport(authState, null, true);
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
                _performExport(authState, 'first', isAnnexA);
              },
            ),
            TextButton(
              child: const Text('Second Half (16-last day)'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport(authState, 'second', isAnnexA);
              },
            ),
            TextButton(
              child: const Text('Whole Month'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport(authState, 'whole', isAnnexA);
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
  ) async {
    if (_isExporting) return;

    // Get user info and context before async gap to avoid BuildContext issues
    final attendanceCubit = context.read<AttendanceCubit>();
    String userName = 'Unknown User';
    String userPosition = '';
    String userOffice = '';

    // Try to get name from profile first
    userName =
        '${authState.user.profile?.firstName ?? ''} ${authState.user.profile?.lastName ?? ''}'
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
      // Show loading indicator only on mobile
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (_isMobile) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Exporting accomplishments to PDF...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

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

        if (_isMobile) {
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
        }
      } else {
        // Desktop: Open the file in the default PDF viewer
        final uri = Uri.file(pdfFile.path);
        if (await launchUrl(uri)) {
          if (_isMobile) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('PDF saved and opened: ${pdfFile.path}'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
          }
        } else {
          if (_isMobile) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('PDF saved to: ${pdfFile.path}'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;

      if (_isMobile) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
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
  }) async {
    final pdf = pw.Document();

    // Load logo images
    pw.MemoryImage? bpLogoImage;
    pw.MemoryImage? naccLogoImage;

    try {
      final bpLogoData = await rootBundle.load('assets/images/logo_bp.png');
      bpLogoImage = pw.MemoryImage(bpLogoData.buffer.asUint8List());
    } catch (e) {
      // Handle case where logo might not be available
      bpLogoImage = null;
    }

    try {
      final naccLogoData = await rootBundle.load('assets/images/logo_nacc.png');
      naccLogoImage = pw.MemoryImage(naccLogoData.buffer.asUint8List());
    } catch (e) {
      // Handle case where logo might not be available
      naccLogoImage = null;
    }

    // Create the PDF with header and proper formatting
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, // Ensure A4 paper size
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Header with logos
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // BP Logo
                  if (bpLogoImage != null)
                    pw.Image(bpLogoImage, height: 50, width: 50)
                  else
                    pw.SizedBox(width: 50, height: 50),

                  // Center text
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'NATIONAL AUTHORITY FOR CHILD CARE',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'REGIONAL ALTERNATIVE CHILD CARE OFFICE IV-A CALABARZON',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // NACC Logo
                  if (naccLogoImage != null)
                    pw.Image(naccLogoImage, height: 50, width: 50)
                  else
                    pw.SizedBox(width: 50, height: 50),
                ],
              ),

              pw.SizedBox(height: 20),

              // Title
              ..._buildTitleSection(isAnnexA, period),

              pw.SizedBox(height: 20),

              // User info in condensed 4x4 table format
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide.none,
                  verticalInside: pw.BorderSide.none,
                  top: pw.BorderSide.none,
                  bottom: pw.BorderSide.none,
                  left: pw.BorderSide.none,
                  right: pw.BorderSide.none,
                ),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        width: 70,
                        child: pw.Text(
                          'Name',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 180,
                        child: pw.Text(
                          ': $userName',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 90,
                        child: pw.Text(
                          'Period Covered',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 160,
                        child: pw.Text(
                          ': ${_getPeriodCoveredText(month, period)}',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        width: 70,
                        child: pw.Text(
                          'Position',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 180,
                        child: pw.Text(
                          ': $userPosition',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 90,
                        child: pw.Text(
                          'Office',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 160,
                        child: pw.Text(
                          ': $userOffice',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Condensed accomplishments table with specified column widths
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FixedColumnWidth(60), // Date column - narrow
                  1: pw.FlexColumnWidth(2), // Activity/Deliverables - wide
                  2: pw.FlexColumnWidth(
                    2,
                  ), // Accomplishment - wide (equal to deliverables)
                  3: pw.FixedColumnWidth(60), // Remarks column - narrow
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Date',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Activity / Deliverables',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Accomplishment',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Remarks',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  for (var accomplishment in accomplishments)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            DateFormat(
                              'MMM dd, yyyy',
                            ).format(accomplishment.date),
                            style: pw.TextStyle(
                              font: pw.Font.helvetica(),
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            accomplishment.target,
                            style: pw.TextStyle(
                              font: pw.Font.helvetica(),
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            accomplishment.accomplishment,
                            style: pw.TextStyle(
                              font: pw.Font.helvetica(),
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '', // Blank remarks column
                            style: pw.TextStyle(
                              font: pw.Font.helvetica(),
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Signature sections
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Prepared by:',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 30),
                        pw.Text(
                          '___________________________',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          '(Signature over Printed Name)',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Approved by:', // Changed from "Noted by" to "Approved by"
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 30),
                        pw.Text(
                          '___________________________',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          'Immediate Supervisor',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF to a file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'accomplishments_${DateFormat('yyyy-MM').format(month)}.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file;
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

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  List<pw.Widget> _buildTitleSection(bool isAnnexA, String? period) {
    if (isAnnexA) {
      String titleText = 'WORK FROM HOME ACCOMPLISHMENT REPORT';

      return [
        pw.Text(
          'ANNEX A',
          style: pw.TextStyle(
            font: pw.Font.helvetica(),
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            decoration: pw.TextDecoration.underline,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          titleText,
          style: pw.TextStyle(
            font: pw.Font.helvetica(),
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ];
    } else {
      String titleText = 'ACCOMPLISHMENT REPORT';
      if (period != null && period != 'whole') {
        titleText += ' (${_getPeriodLabel(period)})';
      }

      return [
        pw.Text(
          titleText,
          style: pw.TextStyle(
            font: pw.Font.helvetica(),
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            decoration: pw.TextDecoration.underline,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ];
    }
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'first':
        return 'First Half';
      case 'second':
        return 'Second Half';
      default:
        return '';
    }
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
