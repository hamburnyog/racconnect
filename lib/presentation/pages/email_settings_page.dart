

import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:racconnect/data/models/email_settings_model.dart';
import 'package:racconnect/data/repositories/email_settings_repository.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';

class EmailSettingsPage extends StatefulWidget {
  const EmailSettingsPage({super.key});

  @override
  State<EmailSettingsPage> createState() => _EmailSettingsPageState();
}

class _EmailSettingsPageState extends State<EmailSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final EmailSettingsRepository _repository = EmailSettingsRepository();

  late TextEditingController _smtpUsernameController;
  late TextEditingController _smtpPasswordController;
  late TextEditingController _smtpServerController;
  late TextEditingController _smtpPortController;
  late TextEditingController _smtpFromEmailController;
  late TextEditingController _smtpFromNameController;
  late TextEditingController _testEmailController;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  bool _obscurePassword = true;

  EmailSettingsModel? _existingSettings;

  @override
  void initState() {
    super.initState();
    _smtpUsernameController = TextEditingController();
    _smtpPasswordController = TextEditingController();
    _smtpServerController = TextEditingController(text: 'smtp.gmail.com');
    _smtpPortController = TextEditingController(text: '587');
    _smtpFromEmailController = TextEditingController();
    _smtpFromNameController = TextEditingController(text: 'RACCONNECT Forum');
    _testEmailController = TextEditingController();

    _loadSettings();
  }

  @override
  void dispose() {
    _smtpUsernameController.dispose();
    _smtpPasswordController.dispose();
    _smtpServerController.dispose();
    _smtpPortController.dispose();
    _smtpFromEmailController.dispose();
    _smtpFromNameController.dispose();
    _testEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _repository.getSettings();
      if (mounted && settings != null) {
        _existingSettings = settings;
        _smtpUsernameController.text = settings.smtpUsername;
        _smtpPasswordController.text = settings.smtpPassword;
        _smtpServerController.text = settings.smtpServer;
        _smtpPortController.text = settings.smtpPort.toString();
        _smtpFromEmailController.text = settings.smtpFromEmail;
        _smtpFromNameController.text = settings.smtpFromName;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading email settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final newSettings = EmailSettingsModel(
        id: _existingSettings?.id,
        key: 'default',
        smtpUsername: _smtpUsernameController.text.trim(),
        smtpPassword: _smtpPasswordController.text.trim(),
        smtpServer: _smtpServerController.text.trim(),
        smtpPort: int.tryParse(_smtpPortController.text.trim()) ?? 587,
        smtpFromEmail: _smtpFromEmailController.text.trim(),
        smtpFromName: _smtpFromNameController.text.trim(),
        preAdoptionTemplate: _existingSettings?.preAdoptionTemplate ?? '',
        fosterCareTemplate: _existingSettings?.fosterCareTemplate ?? '',
      );

      final saved = await _repository.saveSettings(newSettings);
      _existingSettings = saved;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sendTestEmail() async {
    final testRecipient = _testEmailController.text.trim();
    if (testRecipient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a recipient email address for testing in the SMTP tab.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = _smtpUsernameController.text.trim();
    final pass = _smtpPasswordController.text.trim();
    final server = _smtpServerController.text.trim();
    final port = int.tryParse(_smtpPortController.text.trim()) ?? 587;
    final from = _smtpFromEmailController.text.trim().isNotEmpty
        ? _smtpFromEmailController.text.trim()
        : user;
    final name = _smtpFromNameController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both SMTP Username and App Password.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isTesting = true);

    try {
      final smtpServerInstance = SmtpServer(
        server,
        port: port,
        username: user,
        password: pass,
      );

      final messageBody = '''
<h3>RACCONNECT Email Configuration Test</h3>
<p>Hello!</p>
<p>This is a test email sent from the RACCONNECT Email Settings module.</p>
<p>If you are receiving this, your Google App Password and SMTP parameters are <b>working properly</b>.</p>
<hr>
<p><small>Timestamp: ${DateTime.now().toString()}</small></p>
''';

      final message = Message()
        ..from = Address(from, name)
        ..recipients.add(testRecipient)
        ..subject = 'RACCONNECT Test Email'
        ..html = messageBody;

      await send(message, smtpServerInstance);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test email sent successfully to $testRecipient!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test email failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;

    return DefaultTabController(
      length: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          children: [
            Card(
              color: Theme.of(context).primaryColor,
              child: Column(
                children: [
                  ListTile(
                    minTileHeight: 70,
                    leading: const Icon(Icons.mark_email_unread_outlined, color: Colors.white),
                    title: const Text(
                      'Email Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      !isSmallScreen
                          ? 'Configure Google App Password and SMTP server'
                          : 'Configure email settings',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    trailing: MobileButton(
                      isSmallScreen: isSmallScreen,
                      onPressed: _isSaving ? () {} : _saveSettings,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: 'Save',
                    ),
                  ),
                  const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(text: 'Google App Password'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
                      child: TabBarView(
                        children: [
                          // Tab 1: Google App Password & SMTP Config
                          SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SMTP Credentials & Security',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Configure your Google App Password securely here. Credentials are saved directly to PocketBase and will not be exposed on public repositories.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _smtpUsernameController,
                                      decoration: const InputDecoration(
                                        labelText: 'SMTP Username / Google Email',
                                        hintText: 'e.g. racco@gmail.com',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.email_outlined),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _smtpPasswordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: 'Google App Password',
                                        hintText: '16-character App Password',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.key_outlined),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (isSmallScreen) ...[
                                      TextFormField(
                                        controller: _smtpServerController,
                                        decoration: const InputDecoration(
                                          labelText: 'SMTP Host',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.dns_outlined),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _smtpPortController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Port',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ] else
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              controller: _smtpServerController,
                                              decoration: const InputDecoration(
                                                labelText: 'SMTP Host',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(Icons.dns_outlined),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _smtpPortController,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: 'Port',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _smtpFromEmailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Sender Email (From)',
                                        hintText: 'Leave empty to use SMTP Username',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.send_outlined),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _smtpFromNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Sender Display Name',
                                        hintText: 'e.g. RACCONNECT Forum',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.badge_outlined),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Divider(),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Test Email Connection',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Send a quick test email to verify credentials before emailing forum attendees.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _testEmailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Recipient Email Address',
                                        hintText: 'e.g. test@example.com',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.mark_email_read_outlined),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _isTesting ? null : _sendTestEmail,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                        ),
                                        icon: _isTesting
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.send),
                                        label: const Text('Test SMTP Connection'),
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
            ),
          ],
        ),
      ),
    );
  }
}
