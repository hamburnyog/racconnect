import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:racconnect/utility/app_info.dart';

class LogoWithVersion extends StatefulWidget {
  const LogoWithVersion({super.key});

  @override
  State<LogoWithVersion> createState() => _LogoWithVersionState();
}

class _LogoWithVersionState extends State<LogoWithVersion> {
  late Future<String> _versionFuture;

  @override
  void initState() {
    super.initState();
    _versionFuture = AppInfo.getAppVersion();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _versionFuture,
      builder: (context, snapshot) {
        final version = snapshot.data ?? '1.0.0';

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  text: 'RACCO',
                  style: GoogleFonts.righteous(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Theme.of(context).primaryColor,
                  ),
                  children: [
                    TextSpan(
                      text: 'nnect',
                      style: GoogleFonts.righteous(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'v$version',
                style: GoogleFonts.aBeeZee(
                  fontSize: 10,
                  color: Theme.of(context).disabledColor,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
