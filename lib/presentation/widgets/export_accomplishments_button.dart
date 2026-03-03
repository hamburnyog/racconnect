import 'dart:io';
import 'dart:math';
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
import 'package:racconnect/data/models/signatory_model.dart';
import 'package:racconnect/logic/cubit/signatory_cubit.dart';

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
    if (authState is! AuthenticatedState) return;

    final profile = authState.user.profile;
    if (profile == null) return;

    final userRole = authState.user.role ?? '';
    final selectedSignatory = await _showSignatorySelectionDialog(
      profile,
      userRole,
    );

    if (selectedSignatory == null) return;
    if (!mounted) return;

    final signatory = selectedSignatory;
    final isCOS = profile.employmentStatus == 'COS';

    if (isCOS) {
      _showCOSExportOptions(authState, signatory, userRole);
    } else {
      _showPermanentAccomplishmentOptions(authState, signatory, userRole);
    }
  }

  Future<SignatoryModel?> _showSignatorySelectionDialog(
    profile,
    String userRole,
  ) async {
    final signatoryCubit = context.read<SignatoryCubit>();
    if (profile.section != null) {
      signatoryCubit.getSignatoriesBySection(profile.section!);
    } else {
      signatoryCubit.getSignatories();
    }

    return showDialog<SignatoryModel>(
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<SignatoryCubit, SignatoryState>(
          builder: (context, state) {
            return AlertDialog(
              contentPadding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose Signatory',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    if (state is SignatoryLoading)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (state is SignatoryLoadSuccess)
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: state.signatories.length,
                            separatorBuilder:
                                (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final signatory = state.signatories[index];

                              String displayName = signatory.name;
                              String displayDesignation = signatory.designation;

                              // Use userRole from argument
                              bool useSupervisor = false;
                              if (profile.sectionCode == 'OIC') {
                                useSupervisor = userRole == 'OIC';
                              } else {
                                useSupervisor = userRole == 'Unit Head';
                              }

                              if (useSupervisor &&
                                  signatory.supervisor != null) {
                                displayName = signatory.supervisor!;
                                displayDesignation =
                                    signatory.supervisorDesignation ?? '';
                              }

                              return ListTile(
                                dense: true,
                                title: Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  displayDesignation,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onTap:
                                    () => Navigator.of(context).pop(signatory),
                              );
                            },
                          ),
                        ),
                      )
                    else if (state is SignatoryError)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'No signatories found.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.not_interested, size: 20),
                      title: const Text('Leave Blank', style: TextStyle(fontSize: 14)),
                      onTap: () {
                        Navigator.of(context).pop(
                          SignatoryModel(name: '', designation: ''),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCOSExportOptions(
    AuthenticatedState authState,
    SignatoryModel selectedSignatory,
    String userRole,
  ) async {
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
                _showPeriodSelection(
                  authState,
                  true,
                  selectedSignatory,
                  userRole,
                );
              },
            ),
            TextButton(
              child: const Text('Accomplishment Report'),
              onPressed: () {
                Navigator.of(context).pop();
                _showPeriodSelection(
                  authState,
                  false,
                  selectedSignatory,
                  userRole,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPermanentAccomplishmentOptions(
    AuthenticatedState authState,
    SignatoryModel selectedSignatory,
    String userRole,
  ) async {
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
                _performExport(
                  authState,
                  'whole',
                  true,
                  false,
                  selectedSignatory,
                  userRole,
                );
              },
            ),
            TextButton(
              child: const Text('Accomplishment Report'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport(
                  authState,
                  'whole',
                  false,
                  false,
                  selectedSignatory,
                  userRole,
                );
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
    SignatoryModel selectedSignatory,
    String userRole,
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
                _performExport(
                  authState,
                  'first',
                  isAnnexA,
                  true,
                  selectedSignatory,
                  userRole,
                );
              },
            ),
            TextButton(
              child: const Text('Second Half (16-last day)'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport(
                  authState,
                  'second',
                  isAnnexA,
                  true,
                  selectedSignatory,
                  userRole,
                );
              },
            ),
            TextButton(
              child: const Text('Whole Month'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport(
                  authState,
                  'whole',
                  isAnnexA,
                  true,
                  selectedSignatory,
                  userRole,
                );
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
    SignatoryModel signatory,
    String userRole,
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

        // Get all attendance records grouped by date to check for biometric vs WFH
        final recordsByDate = <DateTime, List<dynamic>>{};
        for (var record in attendanceRecords) {
          final date = DateTime(
            record.timestamp.year,
            record.timestamp.month,
            record.timestamp.day,
          );
          recordsByDate.putIfAbsent(date, () => []).add(record);
        }

        // Only consider as WFH if the day has WFH logs and no biometric logs
        final wfhAttendanceRecords = <dynamic>[];
        for (var entry in recordsByDate.entries) {
          final dateRecords = entry.value;
          final hasBiometrics = dateRecords.any(
            (r) => r.type.toLowerCase() == 'biometrics',
          );
          final hasWFH = dateRecords.any(
            (r) => r.type.toLowerCase().contains('wfh'),
          );

          if (hasWFH && !hasBiometrics) {
            // Add all WFH records for this date
            wfhAttendanceRecords.addAll(
              dateRecords.where((r) => r.type.toLowerCase().contains('wfh')),
            );
          }
        }

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
        authState.user.profile,
        signatory: signatory,
        userRole: userRole,
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
        ShareResult result;
        if (Platform.isIOS) {
          // On iOS, we need to provide the sharePositionOrigin for the share sheet
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            result = await SharePlus.instance.share(
              ShareParams(
                subject:
                    'Accomplishments Report - ${DateFormat('MMMM yyyy').format(startDate)}',
                files: [XFile(pdfFile.path)],
                sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
              ),
            );
          } else {
            // Fallback if we can't get the context size
            result = await SharePlus.instance.share(
              ShareParams(
                subject:
                    'Accomplishments Report - ${DateFormat('MMMM yyyy').format(startDate)}',
                files: [XFile(pdfFile.path)],
              ),
            );
          }
        } else {
          // For Android, no special positioning needed
          result = await SharePlus.instance.share(
            ShareParams(
              subject:
                  'Accomplishments Report - ${DateFormat('MMMM yyyy').format(startDate)}',
              files: [XFile(pdfFile.path)],
            ),
          );
        }

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
    String userOffice,
    ProfileModel? profile, {
    String? period,
    bool isAnnexA = true,
    bool isCOS = false,
    required Map<DateTime, String> holidayMap,
    required Map<DateTime, SuspensionModel> suspensionMap,
    required Map<DateTime, String> leaveMap,
    required Map<DateTime, String> travelMap,
    required SignatoryModel signatory,
    required String userRole,
  }) async {
    final pdf = pw.Document();

    String supervisor = '';
    String supervisorDesignation = '';

    if (signatory.name.isNotEmpty) {
      bool useSupervisor = false;
      if (profile?.sectionCode == 'OIC') {
        useSupervisor = userRole == 'OIC';
      } else {
        useSupervisor = userRole == 'Unit Head';
      }

      if (useSupervisor && signatory.supervisor != null) {
        supervisor = signatory.supervisor!.toUpperCase();
        supervisorDesignation = signatory.supervisorDesignation ?? '';
      } else {
        supervisor = signatory.name.toUpperCase();
        supervisorDesignation = signatory.designation;
      }
    }

    pw.MemoryImage? headerImage;
    pw.MemoryImage? footerImage;

    try {
      final headerData = await rootBundle.load('assets/images/header.png');
      headerImage = pw.MemoryImage(headerData.buffer.asUint8List());
    } catch (e) {
      headerImage = null;
    }

    try {
      final footerData = await rootBundle.load('assets/images/footer.png');
      footerImage = pw.MemoryImage(footerData.buffer.asUint8List());
    } catch (e) {
      footerImage = null;
    }

    final garamond = await PdfGoogleFonts.eBGaramondRegular();
    final garamondBold = await PdfGoogleFonts.eBGaramondBold();

    final tableHeaders =
        isAnnexA
            ? ['Date', 'Activity / Deliverables', 'Accomplishment', 'Remarks']
            : ['Date', 'Accomplishment'];

    final List<List<dynamic>> tableData = <List<dynamic>>[];
    if (isAnnexA) {
      for (var acc in accomplishments) {
        final sanitizedTarget = _sanitizeText(acc.target);
        final sanitizedAccomplishment = _sanitizeText(acc.accomplishment);

        final targetChunks = _splitTextIntoChunks(sanitizedTarget, maxLines: 15, maxChars: 1200);
        final accomplishmentChunks = _splitTextIntoChunks(
          sanitizedAccomplishment,
          maxLines: 15,
          maxChars: 1200,
        );

        final totalChunks = max(targetChunks.length, accomplishmentChunks.length);

        for (int i = 0; i < totalChunks; i++) {
          final target = i < targetChunks.length ? targetChunks[i] : '';
          final accomplishment =
              i < accomplishmentChunks.length ? accomplishmentChunks[i] : '';
          final dateStr =
              (i == 0) ? DateFormat('MMM dd, yyyy').format(acc.date) : '';

          tableData.add([
            dateStr,
            _createFormattedRichText(target),
            _createFormattedRichText(accomplishment),
            '', // Remarks
          ]);
        }
      }
    } else {
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
          if (suspension.isHalfday) {
            String formattedTime = DateFormat(
              'h:mm a',
            ).format(suspension.datetime);
            if (suspension.name.contains('Morning')) {
              nonWorkingDayText = 'Morning Suspension ($formattedTime)';
            } else if (suspension.name.contains('Afternoon')) {
              nonWorkingDayText = 'Afternoon Suspension ($formattedTime)';
            } else {
              nonWorkingDayText = '${suspension.name} ($formattedTime)';
            }
          } else {
            nonWorkingDayText = suspension.name;
          }
        } else if (leaveName != null) {
          nonWorkingDayText = leaveName;
        } else if (travelName != null) {
          nonWorkingDayText = 'Special Order No. $travelName';
        } else if (day.weekday == DateTime.saturday) {
          nonWorkingDayText = 'Saturday';
        } else if (day.weekday == DateTime.sunday) {
          nonWorkingDayText = 'Sunday';
        }

        final dateStr = DateFormat('MMM dd, yyyy').format(day);
        bool dateShown = false;

        if (nonWorkingDayText.isNotEmpty) {
          String mainText = nonWorkingDayText;
          String timeText = '';

          if (nonWorkingDayText.contains('(')) {
            int parenthesisIndex = nonWorkingDayText.indexOf('(');
            mainText = nonWorkingDayText.substring(0, parenthesisIndex);
            timeText = nonWorkingDayText.substring(parenthesisIndex);
          }

          final List<pw.TextSpan> spans = [
            pw.TextSpan(
              text: mainText,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ];
          if (timeText.isNotEmpty) {
            spans.add(
              pw.TextSpan(
                text: timeText,
                style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
              ),
            );
          }

          tableData.add([
            dateStr,
            pw.RichText(text: pw.TextSpan(children: spans)),
          ]);
          dateShown = true;
        }

        for (var acc in accomplishmentsForDay) {
          final sanitized = _sanitizeText(acc.accomplishment);
          final chunks = _splitTextIntoChunks(sanitized, maxLines: 25, maxChars: 2000);

          for (var chunk in chunks) {
            tableData.add([
              !dateShown ? dateStr : '',
              _createFormattedRichText(chunk),
            ]);
            dateShown = true;
          }
        }

        if (!dateShown) {
          tableData.add([dateStr, pw.Text('')]);
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        maxPages: 1000,
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 20,
          marginBottom: 20,
          marginLeft: 20,
          marginRight: 20,
        ),
        theme: pw.ThemeData.withFont(base: garamond, bold: garamondBold),
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
                'Page ${context.pageNumber}',
                style: const pw.TextStyle(fontSize: 8),
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
        build: (pw.Context context) {
          final List<pw.Widget> result = [];

          // Report Title
          result.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  isAnnexA
                      ? 'WFH ACCOMPLISHMENT REPORT (ANNEX A)'
                      : 'ACCOMPLISHMENT REPORT',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
          result.add(pw.SizedBox(height: 10));

          // Profile Table
          result.add(
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1.2),
              columnWidths: {
                0: pw.FractionColumnWidth(0.12),
                1: pw.FractionColumnWidth(0.38),
                2: pw.FractionColumnWidth(0.12),
                3: pw.FractionColumnWidth(0.38),
              },
              children: [
                pw.TableRow(
                  children: [
                    _cell('Name:', isBold: true),
                    _cell(userName),
                    _cell('Period Covered:', isBold: true),
                    _cell(_getPeriodCoveredText(month, period)),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _cell('Position:', isBold: true),
                    _cell(userPosition),
                    _cell('Office:', isBold: true),
                    _cell(userOffice),
                  ],
                ),
              ],
            ),
          );
          result.add(pw.SizedBox(height: 5));

          // Main Table - Split into smaller chunks to prevent truncation
          const rowsPerTable = 20;
          for (int i = 0; i < tableData.length; i += rowsPerTable) {
            final chunk = tableData.sublist(
              i,
              min(i + rowsPerTable, tableData.length),
            );
            
            result.add(
              pw.Table(
                border: pw.TableBorder.all(),
                tableWidth: pw.TableWidth.max,
                columnWidths:
                    isAnnexA
                        ? {
                          0: pw.FractionColumnWidth(0.12),
                          1: pw.FractionColumnWidth(0.38),
                          2: pw.FractionColumnWidth(0.38),
                          3: pw.FractionColumnWidth(0.12),
                        }
                        : {
                          0: pw.FractionColumnWidth(0.12),
                          1: pw.FractionColumnWidth(0.88),
                        },
                children: [
                  if (i == 0)
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children:
                          isAnnexA
                              ? [
                                _cell(tableHeaders[0], isBold: true, center: true),
                                _cell(tableHeaders[1], isBold: true),
                                _cell(tableHeaders[2], isBold: true),
                                _cell(tableHeaders[3], isBold: true, center: true),
                              ]
                              : [
                                _cell(tableHeaders[0], isBold: true, center: true),
                                _cell(tableHeaders[1], isBold: true),
                              ],
                    ),
                  ...chunk.map(
                    (row) => pw.TableRow(
                      children:
                          isAnnexA
                              ? [
                                _cellWidget(row[0]),
                                _cellWidget(row[1]),
                                _cellWidget(row[2]),
                                _cellWidget(row[3], center: true),
                              ]
                              : [
                                _cellWidget(row[0], center: true),
                                _cellWidget(row[1]),
                              ],
                    ),
                  ),
                ],
              ),
            );
            // No need for SizedBox between tables as TableBorder already provides visual separation
          }

          // Approval Table
          result.add(
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1.2),
              columnWidths:
                  isAnnexA
                      ? {
                        0: pw.FractionColumnWidth(0.12),
                        1: pw.FractionColumnWidth(0.88),
                      }
                      : {
                        0: pw.FractionColumnWidth(0.12),
                        1: pw.FractionColumnWidth(0.88),
                      },
              children: [
                pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    _cell('Prepared by:', center: true),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(height: 20),
                          pw.Text(userName, style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    _cell('Approved by:', center: true),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(height: 20),
                          pw.Text(
                            supervisor,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            supervisorDesignation,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          result.add(pw.SizedBox(height: 10));
          result.add(
            pw.Center(
              child: pw.Text(
                '*** THIS IS A SYSTEM-GENERATED REPORT. NOTHING FOLLOWS. ***',
                style: pw.TextStyle(color: PdfColors.grey, fontSize: 6),
              ),
            ),
          );

          return result;
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'accomplishments_${DateFormat('yyyy-MM').format(month)}.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _cell(String text, {bool isBold = false, bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  pw.Widget _cellWidget(dynamic cell, {bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child:
          cell is pw.Widget
              ? cell
              : pw.Text(
                cell as String,
                textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
                style: const pw.TextStyle(fontSize: 9),
              ),
    );
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

  String _sanitizeText(String text) {
    if (text.isEmpty) return text;
    // Normalize newlines
    String sanitized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    // Remove null bytes and dangerous control characters, but keep common Unicode
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    // Collapse 3+ newlines into 2
    sanitized = sanitized.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return sanitized.trim();
  }

  List<String> _splitTextIntoChunks(String text, {int maxLines = 20, int maxChars = 800}) {
    if (text.isEmpty) return [''];
    
    final lines = text.split('\n');
    final chunks = <String>[];
    List<String> currentChunkLines = [];
    int currentCharCount = 0;

    for (var line in lines) {
      // Split the line itself if it's too long
      if (line.length > maxChars) {
        if (currentChunkLines.isNotEmpty) {
          chunks.add(currentChunkLines.join('\n'));
          currentChunkLines = [];
          currentCharCount = 0;
        }
        for (int i = 0; i < line.length; i += maxChars) {
          int end = min(i + maxChars, line.length);
          chunks.add(line.substring(i, end));
        }
        continue;
      }

      if (currentChunkLines.isNotEmpty && 
          (currentChunkLines.length >= maxLines || currentCharCount + line.length > maxChars)) {
        chunks.add(currentChunkLines.join('\n'));
        currentChunkLines = [];
        currentCharCount = 0;
      }
      
      currentChunkLines.add(line);
      currentCharCount += line.length;
    }

    if (currentChunkLines.isNotEmpty) {
      chunks.add(currentChunkLines.join('\n'));
    }

    return chunks.isEmpty ? [''] : chunks;
  }

  pw.Widget _createFormattedRichText(String text, {bool isBold = false}) {
    if (text.isEmpty) return pw.Text('');
    final List<pw.TextSpan> textSpans = [];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      if (i > 0) {
        textSpans.add(pw.TextSpan(text: '\n'));
      }

      String line = lines[i].trim();
      if (line.startsWith('- ') || line.startsWith('* ')) {
        textSpans.add(
          pw.TextSpan(
            text: '• ',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
          ),
        );
        textSpans.add(
          pw.TextSpan(
            text: line.substring(2),
            style: const pw.TextStyle(fontSize: 9),
          ),
        );
      } else {
        textSpans.add(
          pw.TextSpan(
            text: line,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : null,
              fontSize: 9,
            ),
          ),
        );
      }
    }

    return pw.RichText(
      text: pw.TextSpan(
        children: textSpans.isNotEmpty ? textSpans : [pw.TextSpan(text: '')],
      ),
    );
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
      bottom: 0,
      right: 0,
      child: FloatingActionButton(
        mini: true,
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
