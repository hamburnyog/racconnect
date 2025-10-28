import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';

class UniformReminderCard extends StatefulWidget {
  const UniformReminderCard({super.key});

  @override
  State<UniformReminderCard> createState() => _UniformReminderCardState();
}

class _UniformReminderCardState extends State<UniformReminderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        String? gender;
        if (authState is AuthenticatedState) {
          gender = authState.user.profile?.gender;
        }

        String? assetName;
        if (gender != null) {
          if (gender.toLowerCase() == 'male' || gender.toLowerCase() == 'm') {
            assetName = 'assets/images/boys-uniform-nobg.png';
          } else if (gender.toLowerCase() == 'female' ||
              gender.toLowerCase() == 'f') {
            assetName = 'assets/images/girls-uniform-nobg.png';
          }
        }

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header that can be tapped to expand/collapse
              // Check if it's weekend (Saturday = 6, Sunday = 7)
              DateTime.now().weekday >= 6 && DateTime.now().weekday <= 7
                  ? const SizedBox.shrink() // Hide on weekends
                  : GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.checkroom, // Shirt/dress icon
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Uniform Reminder', // Updated title
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
              // Expandable content
              AnimatedCrossFade(
                firstChild: Container(height: 0),
                secondChild:
                    _isExpanded
                        ? Container(
                          height:
                              200, // Set a fixed height for the expanded content
                          decoration: BoxDecoration(
                            image:
                                assetName != null
                                    ? DecorationImage(
                                      image: AssetImage(assetName),
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          Alignment
                                              .center, // Show top portion of the image
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withValues(
                                          alpha: 0.2,
                                        ), // Much lighter overlay
                                        BlendMode.srcOver,
                                      ),
                                    )
                                    : null,
                          ),
                          child: Stack(
                            children: [
                              if (assetName == null)
                                const Center(
                                  child: Icon(
                                    Icons.question_mark,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                ),
                              Container(
                                // Lighter overlay to improve text readability
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(
                                        alpha: 0.3,
                                      ), // Much lighter gradient
                                    ],
                                    stops: const [0.6, 1.0],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text:
                                                'First Working Day of Month: ASEAN-Inspired, Monday: Barong/Filipiniana',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const TextSpan(
                                            text:
                                                ', Other Weekdays: At Least Smart Casual (Tue: White, Wed: Black, Thu: Gray, Friday: Any Color)',
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        : Container(height: 0), // Collapsed state
                crossFadeState:
                    _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        );
      },
    );
  }
}
