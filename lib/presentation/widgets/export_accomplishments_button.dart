import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';
import 'package:racconnect/data/models/accomplishment_model.dart';
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
    if (_isExporting) return;

    // Get user info and context before async gap to avoid BuildContext issues
    final authState = context.read<AuthCubit>().state;
    final attendanceCubit = context.read<AttendanceCubit>();
    String userName = 'Unknown User';
    String userPosition = '';
    String userOffice = '';
    
    if (authState is AuthenticatedState) {
      // Try to get name from profile first
      userName = '${authState.user.profile?.firstName ?? ''} ${authState.user.profile?.lastName ?? ''}'.trim();
      if (userName.isEmpty) {
        // Fallback to user name from UserModel
        userName = authState.user.name;
      }
      if (userName.isEmpty) {
        // Last resort fallback
        userName = 'Unknown User';
      }
      
      // Get position and office (using sectionName as office)
      userPosition = authState.user.profile?.position ?? '';
      userOffice = authState.user.profile?.sectionName ?? '';
    }

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
      if (authState is! AuthenticatedState) {
        throw Exception('User not authenticated');
      }
      final employeeNumber = authState.user.profile?.employeeNumber;
      if (employeeNumber == null || employeeNumber.isEmpty) {
        throw Exception('Employee number not found');
      }

      // Fetch accomplishments for the selected month
      final startDate = DateTime(widget.selectedYear, widget.selectedMonth, 1);
      final endDate = DateTime(widget.selectedYear, widget.selectedMonth + 1, 1)
          .subtract(const Duration(days: 1));
      
      final accomplishmentRepository = AccomplishmentRepository();
      final allAccomplishments = await accomplishmentRepository
          .getEmployeeAccomplishmentsForMonth(employeeNumber, startDate, endDate);

      // Filter accomplishments to only include days with WFH time logs
      // We need to check if there are attendance records with WFH type for each accomplishment date
      final attendanceRepository = attendanceCubit.attendanceRepository;
      final attendanceRecords = await attendanceRepository.getEmployeeAttendanceForMonth(
        employeeNumber, 
        startDate,
      );

      // Filter to only WFH attendance records
      final wfhAttendanceRecords = attendanceRecords
          .where((record) => record.type.toLowerCase().contains('wfh'))
          .toList();

      // Create a set of dates that have WFH attendance
      final wfhDates = <DateTime>{};
      for (var record in wfhAttendanceRecords) {
        final date = DateTime(record.timestamp.year, record.timestamp.month, record.timestamp.day);
        wfhDates.add(date);
      }

      // Filter accomplishments to only include those with WFH attendance
      final wfhAccomplishments = allAccomplishments.where((accomplishment) {
        final accomplishmentDate = DateTime(accomplishment.date.year, accomplishment.date.month, accomplishment.date.day);
        return wfhDates.contains(accomplishmentDate);
      }).toList();

      // Generate PDF content with only WFH accomplishments
      final pdfFile = await _generatePDF(wfhAccomplishments, startDate, userName, userPosition, userOffice);
      
      if (!mounted) return;
      
      // Check platform and handle accordingly
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: Share the PDF file
        final params = ShareParams(
          subject: 'Accomplishments Report - ${DateFormat('MMMM yyyy').format(startDate)}',
          files: [XFile(pdfFile.path)],
        );
        
        final result = await SharePlus.instance.share(params);
        
        if (!mounted) return;
        
        if (result.status == ShareResultStatus.success) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('PDF exported successfully! Thank you for sharing!'),
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

  Future<File> _generatePDF(List<AccomplishmentModel> accomplishments, DateTime month, String userName, String userPosition, String userOffice) async {
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
                            font: pw.Font.times(),
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'REGIONAL ALTERNATIVE CHILD CARE OFFICE IV-A CALABARZON',
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontSize: 12,
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
              pw.Text(
                'ANNEX A',
                style: pw.TextStyle(
                  font: pw.Font.times(),
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'WORK FROM HOME ACCOMPLISHMENT REPORT',
                style: pw.TextStyle(
                  font: pw.Font.times(),
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 20),
              
              // User info in 2x2 table format
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
                        width: 250,
                        child: pw.Text(
                          'NAME: $userName',
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 250,
                        child: pw.Text(
                          'PERIOD COVERED: ${DateFormat('MMMM yyyy').format(month)}',
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        width: 250,
                        child: pw.Text(
                          'POSITION: $userPosition',
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 250,
                        child: pw.Text(
                          'OFFICE: $userOffice',
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Accomplishments table with remarks column
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Date', 
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Target/s', 
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Accomplishment/s', 
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Remarks', 
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
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
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            DateFormat('MMM dd, yyyy').format(accomplishment.date),
                            style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            accomplishment.target,
                            style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            accomplishment.accomplishment,
                            style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '', // Blank remarks column
                            style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontSize: 9,
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
                            font: pw.Font.times(),
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 30),
                        pw.Text(
                          '___________________________',
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontSize: 12,
                          ),
                        ),
                        pw.Text(
                          '(Signature over Printed Name)',
                          style: pw.TextStyle(
                            font: pw.Font.times(),
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
                            font: pw.Font.times(),
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 30),
                        pw.Text(
                          '___________________________',
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontSize: 12,
                          ),
                        ),
                        pw.Text(
                          'Immediate Supervisor',
                          style: pw.TextStyle(
                            font: pw.Font.times(),
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
    final fileName = 'accomplishments_${DateFormat('yyyy-MM').format(month)}.pdf';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 70, // Position above the import button
      right: 5,
      child: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _exportToPDF,
        child: _isExporting
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Icon(Icons.picture_as_pdf, color: Colors.white),
      ),
    );
  }
}