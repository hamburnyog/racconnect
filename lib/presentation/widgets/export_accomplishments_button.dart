import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';
import 'package:racconnect/data/models/accomplishment_model.dart';
import 'package:racconnect/data/models/suspension_model.dart';
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
  final Map<DateTime, String> holidayMap;
  final Map<DateTime, SuspensionModel> suspensionMap;
  final Map<DateTime, String> leaveMap;
  final Map<DateTime, String> travelMap;

  const ExportAccomplishmentsButton({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.holidayMap,
    required this.suspensionMap,
    required this.leaveMap,
    required this.travelMap,
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

    final isCOS =
        authState is AuthenticatedState &&
        authState.user.profile?.employmentStatus == 'COS';

    if (authState is AuthenticatedState) {
      if (isCOS) {
        _showCOSExportOptions(authState);
      } else {
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

    final attendanceCubit = context.read<AttendanceCubit>();
    String userName = 'Unknown User';
    String userPosition = '';
    String userOffice = '';

    userName =
        '${authState.user.profile?.firstName ?? ''} ${_getMiddleInitialFromMiddleName(authState.user.profile?.middleName)} ${authState.user.profile?.lastName ?? ''}'
            .trim();
    if (userName.isEmpty) {
      userName = authState.user.name;
    }
    if (userName.isEmpty) {
      userName = 'Unknown User';
    }

    userPosition = authState.user.profile?.position ?? '';
    userOffice = _getOfficeInfo(authState.user.profile);

    setState(() {
      _isExporting = true;
    });

    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Exporting accomplishments to PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

      final employeeNumber = authState.user.profile?.employeeNumber;
      if (employeeNumber == null || employeeNumber.isEmpty) {
        throw Exception('Employee number not found');
      }

      DateTime startDate;
      DateTime endDate;

      if (period == 'first') {
        startDate = DateTime(widget.selectedYear, widget.selectedMonth, 1);
        endDate = DateTime(widget.selectedYear, widget.selectedMonth, 15);
      } else if (period == 'second') {
        startDate = DateTime(widget.selectedYear, widget.selectedMonth, 16);
        endDate = DateTime(
          widget.selectedYear,
          widget.selectedMonth + 1,
          1,
        ).subtract(const Duration(days: 1));
      } else {
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

      List<AccomplishmentModel> filteredAccomplishments;

      if (isAnnexA) {
        final attendanceRepository = attendanceCubit.attendanceRepository;
        final attendanceRecords = await attendanceRepository
            .getEmployeeAttendanceForMonth(employeeNumber, startDate);

        final wfhAttendanceRecords =
            attendanceRecords
                .where((record) => record.type.toLowerCase().contains('wfh'))
                .toList();

        final wfhDates = <DateTime>{};
        for (var record in wfhAttendanceRecords) {
          final date = DateTime(
            record.timestamp.year,
            record.timestamp.month,
            record.timestamp.day,
          );
          wfhDates.add(date);
        }

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
        filteredAccomplishments = allAccomplishments;
      }

      final pdfFile = await _generatePDF(
        filteredAccomplishments,
        startDate,
        userName,
        userPosition,
        userOffice,
        period: period,
        isAnnexA: isAnnexA,
        isCOS: isCOS,
        holidayMap: widget.holidayMap,
        suspensionMap: widget.suspensionMap,
        leaveMap: widget.leaveMap,
        travelMap: widget.travelMap,
      );

      if (!mounted) return;

      if (Platform.isAndroid || Platform.isIOS) {
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
    required Map<DateTime, String> holidayMap,
    required Map<DateTime, SuspensionModel> suspensionMap,
    required Map<DateTime, String> leaveMap,
    required Map<DateTime, String> travelMap,
  }) async {
    final pdf = pw.Document();

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

    final tableHeaders =
        isAnnexA
            ? ['Date', 'Activity / Deliverables', 'Accomplishment', 'Remarks']
            : ['Date', 'Accomplishment', 'Remarks'];

    final List<List<dynamic>> tableData;
    if (isAnnexA) {
      tableData =
          accomplishments.map((acc) {
            return [
              DateFormat('MMM dd, yyyy').format(acc.date),
              acc.target.replaceAll('\n', ' ').replaceAll('\r', ' '),
              acc.accomplishment.replaceAll('\n', ' ').replaceAll('\r', ' '),
              '',
            ];
          }).toList();
    } else {
      tableData = <List<dynamic>>[];
      final daysInPeriod = getDaysInPeriod(month.year, month.month, period);

      for (var day in daysInPeriod) {
        final accomplishmentsForDay =
            accomplishments
                .where((acc) => DateUtils.isSameDay(acc.date, day))
                .toList();

        final holidayName = holidayMap[day];
        final suspension = suspensionMap[day];
        final leaveName = leaveMap[day];
        final travelName = travelMap[day];

        String nonWorkingDayText = '';
        if (holidayName != null) {
          nonWorkingDayText = holidayName;
        } else if (suspension != null) {
          nonWorkingDayText = suspension.name;
        } else if (leaveName != null) {
          nonWorkingDayText = leaveName;
        } else if (travelName != null) {
          nonWorkingDayText = 'On Travel Order: $travelName';
        } else if (day.weekday == DateTime.saturday ||
            day.weekday == DateTime.sunday) {
          nonWorkingDayText = 'Weekend';
        }

        final accomplishmentText = accomplishmentsForDay
            .map((e) => e.accomplishment)
            .join('\n');

        final richText = pw.RichText(
          text: pw.TextSpan(
            children: [
              if (nonWorkingDayText.isNotEmpty)
                pw.TextSpan(
                  text: '${nonWorkingDayText.toUpperCase()}\n',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              pw.TextSpan(text: accomplishmentText),
            ],
          ),
        );

        tableData.add([DateFormat('MMM dd, yyyy').format(day), richText, '']);
      }
    }

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
              pw.Table(
                border: pw.TableBorder.all(),
                tableWidth: pw.TableWidth.max,
                columnWidths:
                    isAnnexA
                        ? {
                          0: pw.FractionColumnWidth(0.15),
                          1: pw.FractionColumnWidth(0.35),
                          2: pw.FractionColumnWidth(0.35),
                          3: pw.FractionColumnWidth(0.15),
                        }
                        : {
                          0: pw.FractionColumnWidth(0.15),
                          1: pw.FractionColumnWidth(0.50),
                          2: pw.FractionColumnWidth(0.35),
                        },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children:
                        isAnnexA
                            ? [
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
                            ]
                            : [
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
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                  ),
                  ...tableData.map(
                    (row) => pw.TableRow(
                      children:
                          isAnnexA
                              ? (row as List<String>)
                                  .asMap()
                                  .map(
                                    (index, cell) => MapEntry(
                                      index,
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(4),
                                        child: pw.Text(
                                          cell,
                                          textAlign:
                                              index == 0 || index == 3
                                                  ? pw.TextAlign.center
                                                  : pw.TextAlign.left,
                                          style: const pw.TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .values
                                  .toList()
                              : [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    row[0] as String,
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    (row[1] as pw.RichText).text.toPlainText(),
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    row[2] as String,
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
                          'Prepared by: $userName',
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
                          'Approved by: ${_getUnitHeadName(userOffice)}',
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
                  style: pw.TextStyle(color: PdfColors.grey, fontSize: 6),
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

  String _getMiddleInitialFromMiddleName(String? middleName) {
    if (middleName != null && middleName.trim().isNotEmpty) {
      return '${middleName.trim()[0]}.';
    }
    return '';
  }

  String _getOfficeInfo(ProfileModel? profile) {
    if (profile?.sectionName?.isNotEmpty ?? false) {
      return profile!.sectionName!;
    }

    if (profile?.sectionCode?.isNotEmpty ?? false) {
      return profile!.sectionCode!;
    }

    if (profile?.section?.isNotEmpty ?? false) {
      return 'N/A';
    }

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

  String _getUnitHeadName(userOffice) {
    String supervisor =
        userOffice == 'Office of the RACC Officer'
            ? 'Hon. Rowena M. Macalintal, ASEC'
            : 'John S. Calidguid, RSW, MPA';
    return supervisor;
  }

  List<DateTime> getDaysInPeriod(int year, int month, String? period) {
    DateTime startDate;
    DateTime endDate;

    if (period == 'first') {
      startDate = DateTime(year, month, 1);
      endDate = DateTime(year, month, 15);
    } else if (period == 'second') {
      startDate = DateTime(year, month, 16);
      endDate = DateTime(year, month + 1, 0);
    } else {
      startDate = DateTime(year, month, 1);
      endDate = DateTime(year, month + 1, 0);
    }

    final days = <DateTime>[];
    for (var i = 0; i <= endDate.difference(startDate).inDays; i++) {
      days.add(startDate.add(Duration(days: i)));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 5,
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
