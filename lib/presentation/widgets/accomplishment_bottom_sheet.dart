import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/accomplishment_model.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';

class AccomplishmentBottomSheet extends StatefulWidget {
  final DateTime day;
  final VoidCallback? onAccomplishmentSaved;

  const AccomplishmentBottomSheet({
    required this.day,
    this.onAccomplishmentSaved,
    super.key,
  });

  @override
  State<AccomplishmentBottomSheet> createState() =>
      _AccomplishmentBottomSheetState();
}

class _AccomplishmentBottomSheetState extends State<AccomplishmentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _accomplishmentRepository = AccomplishmentRepository();
  final _targetController = TextEditingController();
  final _accomplishmentController = TextEditingController();
  AccomplishmentModel? _accomplishment;
  bool _isAccomplishmentCopied = false;
  bool _isTargetCopied = false;

  @override
  void initState() {
    super.initState();
    _loadAccomplishment();
  }

  Future<void> _loadAccomplishment() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
      final employeeNumber = authState.user.profile?.employeeNumber;
      if (employeeNumber == null) return;
      final accomplishment = await _accomplishmentRepository
          .getAccomplishmentByDate(widget.day, employeeNumber);
      if (!mounted) return;
      if (accomplishment != null) {
        setState(() {
          _accomplishment = accomplishment;
          _targetController.text = accomplishment.target;
          _accomplishmentController.text = accomplishment.accomplishment;
        });
      }
    }
  }

  Future<void> _saveAccomplishment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Capture the context before async operations
    final currentContext = context;
    final authState = currentContext.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
      final employeeNumber = authState.user.profile?.employeeNumber;
      if (employeeNumber == null) return;

      final navigator = Navigator.of(currentContext);

      if (_accomplishment != null) {
        await _accomplishmentRepository.updateAccomplishment(
          id: _accomplishment!.id!,
          date: widget.day,
          target: _targetController.text,
          accomplishment: _accomplishmentController.text,
          employeeNumber: employeeNumber,
        );
      } else {
        await _accomplishmentRepository.addAccomplishment(
          date: widget.day,
          target: _targetController.text,
          accomplishment: _accomplishmentController.text,
          employeeNumber: employeeNumber,
        );
      }
      if (!mounted) return;
      navigator.pop();

      if (widget.onAccomplishmentSaved != null) {
        widget.onAccomplishmentSaved!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Accomplishments',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat('MMMM dd, y').format(widget.day),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          DateFormat('EEEE').format(widget.day),
                          style: TextStyle(
                            color: Colors.yellow,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: SvgPicture.asset(
                        'assets/images/creative.svg',
                        height: 100,
                        colorFilter: ColorFilter.mode(
                          Colors.white.withAlpha(50),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _targetController,
                readOnly: false,
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  labelText: 'Target',
                  border: OutlineInputBorder(),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      icon: Icon(_isTargetCopied ? Icons.check : Icons.copy),
                      color: _isTargetCopied ? Colors.green : null,
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _targetController.text),
                        );
                        setState(() {
                          _isTargetCopied = true;
                        });
                        Future.delayed(Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() {
                              _isTargetCopied = false;
                            });
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accomplishmentController,
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  labelText: 'Accomplishment',
                  border: OutlineInputBorder(),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      icon: Icon(
                        _isAccomplishmentCopied ? Icons.check : Icons.copy,
                      ),
                      color: _isAccomplishmentCopied ? Colors.green : null,
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _accomplishmentController.text),
                        );
                        setState(() {
                          _isAccomplishmentCopied = true;
                        });
                        Future.delayed(Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() {
                              _isAccomplishmentCopied = false;
                            });
                          }
                        });
                      },
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _saveAccomplishment,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_accomplishment != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirm Deletion"),
                            content: const Text(
                              "Are you sure you want to delete this accomplishment record?",
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text("Delete"),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmed == true && mounted) {
                        // Delete the accomplishment
                        try {
                          await _accomplishmentRepository.deleteAccomplishment(
                            id: _accomplishment!.id!,
                          );

                          if (!mounted) return;

                          // Close the bottom sheet
                          navigator.pop();

                          // Notify parent to refresh
                          if (widget.onAccomplishmentSaved != null) {
                            widget.onAccomplishmentSaved!();
                          }

                          // Show success message
                          if (!mounted) return;
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Accomplishment deleted successfully',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;

                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error deleting accomplishment: $e',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 10),
                          Text(
                            'Delete Record',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
