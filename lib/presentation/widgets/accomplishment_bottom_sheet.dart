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

  const AccomplishmentBottomSheet({required this.day, this.onAccomplishmentSaved, super.key});

  @override
  State<AccomplishmentBottomSheet> createState() =>
      _AccomplishmentBottomSheetState();
}

class _AccomplishmentBottomSheetState extends State<AccomplishmentBottomSheet> {
  final _accomplishmentRepository = AccomplishmentRepository();
  final _targetController = TextEditingController();
  final _accomplishmentController = TextEditingController();
  AccomplishmentModel? _accomplishment;
  bool _isAccomplishmentCopied = false;

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
    final navigator = Navigator.of(context);
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
      final employeeNumber = authState.user.profile?.employeeNumber;
      if (employeeNumber == null) return;

      if (_accomplishment != null) {
        // Update existing accomplishment
        await _accomplishmentRepository.updateAccomplishment(
          id: _accomplishment!.id!,
          date: widget.day,
          target: _targetController.text,
          accomplishment: _accomplishmentController.text,
          employeeNumber: employeeNumber,
        );
      } else {
        // Create new accomplishment
        await _accomplishmentRepository.addAccomplishment(
          date: widget.day,
          target: _targetController.text,
          accomplishment: _accomplishmentController.text,
          employeeNumber: employeeNumber,
        );
      }
      if (!mounted) return;
      navigator.pop();
      
      // Notify that an accomplishment was saved
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
                        Colors.white.withValues(alpha: 0.2),
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
              readOnly: true,
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Target',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade200,
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: 26.0),
                  child: Icon(Icons.lock),
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
                    icon: Icon(_isAccomplishmentCopied ? Icons.check : Icons.copy),
                    color: _isAccomplishmentCopied ? Colors.green : null,
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _accomplishmentController.text),
                      );
                      setState(() {
                        _isAccomplishmentCopied = true;
                      });
                      // Reset the icon after 2 seconds
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
          ],
        ),
      ),
    );
  }
}
