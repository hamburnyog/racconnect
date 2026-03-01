import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/forum_attendee.dart';
import 'package:racconnect/data/repositories/forum_repository.dart';

class ForumImport {
  final BuildContext context;
  final VoidCallback? onImportSuccess;
  final ForumRepository _repository = ForumRepository();

  ForumImport({
    required this.context,
    this.onImportSuccess,
  });

  final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);
  final ValueNotifier<String> statusNotifier = ValueNotifier('Preparing...');
  late BuildContext dialogContext;

  Future<void> pickAndImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      dialogTitle: 'Select certificates file (.csv)',
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final csvString = await file.readAsString();
    final fields = CsvCodec().decoder.convert(csvString);

    if (fields.length <= 1) {
      _showSnackBar('The selected file is empty or only contains headers.', false);
      return;
    }

    // Index 0 is header, so data starts at index 1 (which is actual row 2 in Excel)
    final List<Map<String, dynamic>> indexedRows = [];
    for (int i = 1; i < fields.length; i++) {
      indexedRows.add({
        'index': i + 1, // Original CSV row number
        'data': fields[i],
      });
    }

    // Filter out rows that are completely empty or missing a name
    final validRows = indexedRows.where((row) {
      final data = row['data'] as List<dynamic>;
      if (data.isEmpty) return false;
      
      // Check if it's a "dummy" row or just empty columns
      final hasData = data.any((cell) => cell.toString().trim().isNotEmpty);
      if (!hasData) return false;

      // Ensure we have at least 3 columns for name extraction
      if (data.length < 3) return false;
      
      final name = data[2].toString().trim();
      return name.isNotEmpty;
    }).toList();

    if (validRows.isEmpty) {
      _showSnackBar('No valid certificate records found in the file.', false);
      return;
    }

    await _processBatch(validRows);
  }

    Future<void> _processBatch(List<Map<String, dynamic>> rows) async {
      if (!context.mounted) return;
  
      _showProgressDialog();
  
      int total = rows.length;
          int success = 0;
          int skippedCount = 0;
          final failedDetails = <String>[];
      
          try {
            // 1. Fetch existing attendees to detect duplicates
            final existingAttendees = await _repository.getAttendees();
              // Create sets for fast lookup
        final existingNamesWithDates = existingAttendees.map((a) {
          final dateKey = a.forumDate != null
              ? DateFormat('yyyy-MM-dd').format(a.forumDate!)
              : 'no-date';
          return '${a.name.toLowerCase().trim()}_$dateKey';
        }).toSet();
  
        final existingEmails = existingAttendees
            .expand((a) => a.emails)
            .map((e) => e.toLowerCase().trim())
            .toSet();
  
        List<Map<String, dynamic>> remaining = List.from(rows);
  
        while (remaining.isNotEmpty) {
          final nextRetry = <Map<String, dynamic>>[];
  
          for (int i = 0; i < remaining.length; i++) {
            final entry = remaining[i];
            final row = entry['data'] as List<dynamic>;
            final rowNum = entry['index'] as int;
  
            // Padding row to handle missing trailing commas
            while (row.length < 9) {
              row.add('');
            }
  
            try {
              // Data Cleanup
              String clean(dynamic value) {
                return value
                    .toString()
                    .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .trim();
              }
  
              final dateStr = clean(row[1]);
              final name = clean(row[2]);
              final address = clean(row[5]);
  
              if (name.isEmpty) {
                failedDetails.add('Row $rowNum: Name is empty after cleaning');
                continue;
              }
  
              // Email extraction
              final rawEmail = row[8].toString();
              final currentEmails = rawEmail
                  .split(RegExp(r'[/,\s]+'))
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty && e.contains('@'))
                  .toList();
  
              final emailString = currentEmails.join(' / ');
  
              String type = 'Pre-adoption';
              if (row.length > 9) {
                final rawCategory = clean(row[9]).toLowerCase();
                if (rawCategory.contains('foster care')) {
                  type = 'Foster Care';
                }
              }
  
              DateTime? forumDate;
              String dateKeyPart = 'no-date';
              final dateFormats = [
                'MM/dd/yyyy',
                'M/d/yyyy',
                'yyyy-MM-dd',
                'MM-dd-yyyy',
                'd/M/yyyy'
              ];
  
              if (dateStr.isNotEmpty) {
                for (var format in dateFormats) {
                  try {
                    forumDate = DateFormat(format).parse(dateStr);
                    dateKeyPart = DateFormat('yyyy-MM-dd').format(forumDate);
                    break;
                  } catch (_) {}
                }
              }
  
              // Duplicate Check
              final currentNameDateKey = '${name.toLowerCase()}_$dateKeyPart';
              bool isDuplicate =
                  existingNamesWithDates.contains(currentNameDateKey);
  
              if (!isDuplicate && currentEmails.isNotEmpty) {
                isDuplicate = currentEmails.any(
                  (e) => existingEmails.contains(e.toLowerCase()),
                );
              }
  
                          if (isDuplicate) {
                            skippedCount++;
                          } else {
                            final attendee = ForumAttendee(
                              name: name,
                              address: address,
                              email: emailString,
                              type: type,
                              forumDate: forumDate,
                            );
                            await _repository.addAttendee(attendee);
                            success++;
              
                            existingNamesWithDates.add(currentNameDateKey);
                            for (var e in currentEmails) {
                              existingEmails.add(e.toLowerCase());
                            }
                          }
                                  } catch (e) {
                                    nextRetry.add(entry);
                                  }
                        
                                  final processedCount =
                                      success + skippedCount + failedDetails.length + nextRetry.length;
                                  progressNotifier.value = processedCount / total;
                                  statusNotifier.value =
                                      '✅ $success | ⏭️ $skippedCount | 🔁 ${nextRetry.length}';
                                }
                        
                                if (nextRetry.length == remaining.length && nextRetry.isNotEmpty) {
                                  for (var f in nextRetry) {
                                    final rowData = f['data'] as List<dynamic>;
                                    final name = rowData.length > 2 ? rowData[2].toString() : 'Unknown';
                                    final rowNum = f['index'] as int;
                        
                                    String errorMsg = 'Please check the data format';
                                    try {
                                      String clean(dynamic value) => value
                                          .toString()
                                          .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
                                          .replaceAll(RegExp(r'\s+'), ' ')
                                          .trim();
                                      
                                      final currentEmails = rowData[8]
                                          .toString()
                                          .split(RegExp(r'[/,\s]+'))
                                          .map((e) => e.trim())
                                          .where((e) => e.isNotEmpty && e.contains('@'))
                                          .toList();
                        
                                      await _repository.addAttendee(ForumAttendee(
                                        name: clean(rowData[2]),
                                        address: clean(rowData[5]),
                                        email: currentEmails.join(' / '),
                                      ));
                                    } catch (e) {
                                      final errStr = e.toString().toLowerCase();
                                      if (errStr.contains('unique')) {
                                        errorMsg = 'This record already exists';
                                      } else if (errStr.contains('validation')) {
                                        errorMsg = 'Check if email or date is valid';
                                      } else if (errStr.contains('clientexception')) {
                                        errorMsg = 'Server rejected the data';
                                      }
                                    }
                                    failedDetails.add('Row $rowNum: $name - $errorMsg');
                                  }
                                  break;
                                }
                        
                                remaining = nextRetry;
                              }
                            } catch (e) {
                              if (context.mounted) {
                                _showSnackBar('An error occurred during import: $e', false);
                              }
                            }
                        
                            if (context.mounted) {
                              try {
                                Navigator.of(dialogContext).pop();
                              } catch (_) {}
                            }
                        
                            _showImportSummary(success, skippedCount, failedDetails);
                        
                            if (success > 0) {
                              onImportSuccess?.call();
                            }
                          }
                        
                          void _showImportSummary(
                              int success, int skipped, List<String> failed) {
                            if (!context.mounted) return;
                        
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('✅ Successfully added: $success', 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('⏭️ Skipped (Duplicates): $skipped'),
                                        Text('❌ Failed: ${failed.length}'),
                                        if (failed.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Failed Rows:',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                          ),
                                          const SizedBox(height: 8),
                                          ...failed.map((f) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                child: Text(f,
                                                    style: const TextStyle(fontSize: 11, color: Colors.red)),
                                              )),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          }  void _showProgressDialog() {
    if (!context.mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Importing',
      pageBuilder: (BuildContext dialogCtx, _, __) {
        dialogContext = dialogCtx;
        return AlertDialog(
          title: const Text('Importing Certificates'),
          content: SizedBox(
            height: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Processing CSV rows...'),
                const SizedBox(height: 12),
                ValueListenableBuilder<double>(
                  valueListenable: progressNotifier,
                  builder:
                      (_, value, __) => LinearProgressIndicator(value: value),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: statusNotifier,
                  builder: (_, value, __) => Text(value),
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
