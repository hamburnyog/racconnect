import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:racconnect/data/models/email_settings_model.dart';
import 'package:racconnect/data/repositories/email_settings_repository.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailFormKey = GlobalKey<FormState>();
  final _serverFormKey = GlobalKey<FormState>();
  final EmailSettingsRepository _emailRepository = EmailSettingsRepository();

  // Server URL Controllers & States
  late TextEditingController _serverUrlController;
  bool _isTestingServer = false;
  bool _isSavingServer = false;
  String? _serverTestMessage;
  bool? _serverTestSuccess;
  String? _activeCustomUrl;

  // SMTP Controllers & States
  late TextEditingController _smtpUsernameController;
  late TextEditingController _smtpPasswordController;
  late TextEditingController _smtpServerController;
  late TextEditingController _smtpPortController;
  late TextEditingController _smtpFromEmailController;
  late TextEditingController _smtpFromNameController;
  late TextEditingController _testEmailController;

  bool _isLoading = true;
  bool _isSavingEmail = false;
  bool _isTestingEmail = false;
  bool _obscurePassword = true;

  EmailSettingsModel? _existingSettings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _serverUrlController = TextEditingController();

    _smtpUsernameController = TextEditingController();
    _smtpPasswordController = TextEditingController();
    _smtpServerController = TextEditingController(text: 'smtp.gmail.com');
    _smtpPortController = TextEditingController(text: '587');
    _smtpFromEmailController = TextEditingController();
    _smtpFromNameController = TextEditingController(text: 'RACCONNECT Forum');
    _testEmailController = TextEditingController();

    _loadAllSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serverUrlController.dispose();
    _smtpUsernameController.dispose();
    _smtpPasswordController.dispose();
    _smtpServerController.dispose();
    _smtpPortController.dispose();
    _smtpFromEmailController.dispose();
    _smtpFromNameController.dispose();
    _testEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSettings() async {
    setState(() => _isLoading = true);

    // 1. Load Server URL
    try {
      final customUrl = await PocketBaseClient.getCustomUrl();
      _activeCustomUrl = customUrl;
      _serverUrlController.text = (customUrl != null && customUrl.isNotEmpty)
          ? customUrl
          : PocketBaseClient.instance.baseURL;
    } catch (_) {
      _serverUrlController.text = PocketBaseClient.instance.baseURL;
    }

    // 2. Load Email Settings
    try {
      final settings = await _emailRepository.getSettings();
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

  // --- PocketBase Server Operations ---

  Future<void> _testServerConnection() async {
    final candidateUrl = _serverUrlController.text.trim();
    if (candidateUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a server URL to test.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTestingServer = true;
      _serverTestMessage = null;
      _serverTestSuccess = null;
    });

    final success = await PocketBaseClient.testConnection(candidateUrl);

    if (mounted) {
      setState(() {
        _isTestingServer = false;
        _serverTestSuccess = success;
        _serverTestMessage = success
            ? 'Successfully connected to PocketBase server at $candidateUrl!'
            : 'Could not connect to $candidateUrl. Please ensure PocketBase is running and reachable.';
      });
    }
  }

  Future<void> _saveServerUrl() async {
    final newUrl = _serverUrlController.text.trim();
    if (newUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid PocketBase URL.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSavingServer = true);

    try {
      await PocketBaseClient.updateBaseUrl(newUrl);
      final active = await PocketBaseClient.getCustomUrl();

      if (mounted) {
        setState(() {
          _activeCustomUrl = active;
          _serverUrlController.text = PocketBaseClient.instance.baseURL;
          _serverTestSuccess = null;
          _serverTestMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PocketBase URL updated to ${PocketBaseClient.instance.baseURL}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingServer = false);
    }
  }

  Future<void> _resetServerUrl() async {
    setState(() => _isSavingServer = true);
    try {
      await PocketBaseClient.resetToDefault();
      if (mounted) {
        setState(() {
          _activeCustomUrl = null;
          _serverUrlController.text = PocketBaseClient.instance.baseURL;
          _serverTestSuccess = null;
          _serverTestMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server URL reset to default: ${PocketBaseClient.instance.baseURL}'),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingServer = false);
    }
  }

  // --- Email Settings Operations ---

  Future<void> _saveEmailSettings() async {
    setState(() => _isSavingEmail = true);
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

      final saved = await _emailRepository.saveSettings(newSettings);
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
            content: Text('Failed to save email settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingEmail = false);
    }
  }

  Future<void> _sendTestEmail() async {
    final testRecipient = _testEmailController.text.trim();
    if (testRecipient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a recipient email address for testing.'),
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

    setState(() => _isTestingEmail = true);

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
<p>This is a test email sent from the RACCONNECT Settings module.</p>
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
      if (mounted) setState(() => _isTestingEmail = false);
    }
  }

  void _onSavePressed() {
    if (_tabController.index == 0) {
      _saveServerUrl();
    } else {
      _saveEmailSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;
    final isSaving = _isSavingServer || _isSavingEmail;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        children: [
          Card(
            color: Theme.of(context).primaryColor,
            child: Column(
              children: [
                ListTile(
                  minTileHeight: 70,
                  leading: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
                  title: const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    !isSmallScreen
                        ? 'Configure PocketBase server connection and SMTP email parameters'
                        : 'Server URL & Email Settings',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  trailing: MobileButton(
                    isSmallScreen: isSmallScreen,
                    onPressed: isSaving ? () {} : _onSavePressed,
                    icon: isSaving
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
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.dns_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Backend Server'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_unread_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Email & SMTP'),
                        ],
                      ),
                    ),
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
                      controller: _tabController,
                      children: [
                        // Tab 1: PocketBase Server Configuration
                        _buildServerConfigTab(isSmallScreen),
                        // Tab 2: Google App Password & SMTP Config
                        _buildEmailConfigTab(isSmallScreen),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerConfigTab(bool isSmallScreen) {
    final currentBaseUrl = PocketBaseClient.instance.baseURL;
    final isCustom = _activeCustomUrl != null && _activeCustomUrl!.isNotEmpty;

    return SingleChildScrollView(
      child: Form(
        key: _serverFormKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PocketBase Backend URL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Configure the PocketBase instance URL. You can point this to localhost or an IP address on your local network (LAN) to test or run offline without public internet.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),

              // Active Connection Status Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCustom ? Colors.blue.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCustom ? Colors.blue.shade300 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCustom ? Icons.lan_outlined : Icons.cloud_done_outlined,
                      color: isCustom ? Colors.blue.shade700 : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCustom ? 'Active: Custom Server URL' : 'Active: Default Environment URL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isCustom ? Colors.blue.shade900 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            currentBaseUrl,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCustom)
                      TextButton.icon(
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text('Reset', style: TextStyle(fontSize: 12)),
                        onPressed: _isSavingServer ? null : _resetServerUrl,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Server URL input field
              TextFormField(
                controller: _serverUrlController,
                decoration: InputDecoration(
                  labelText: 'PocketBase Server URL',
                  hintText: 'e.g. http://127.0.0.1:8090 or http://192.168.1.100:8090',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _serverUrlController.clear(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Test & Apply Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isTestingServer ? null : _testServerConnection,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _isTestingServer
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering, size: 18),
                      label: const Text('Test Connection'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSavingServer ? null : _saveServerUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _isSavingServer
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text('Save & Apply URL'),
                    ),
                  ),
                ],
              ),

              // Test result feedback banner
              if (_serverTestMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _serverTestSuccess == true
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _serverTestSuccess == true
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _serverTestSuccess == true
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: _serverTestSuccess == true
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _serverTestMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _serverTestSuccess == true
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // Local Network & Offline Guide Card
              const Text(
                'Localhost & LAN Setup Guide',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'How to serve PocketBase over your Local Network:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Same Computer (macOS Desktop / Simulator):\n'
                      '   Use: http://127.0.0.1:8090\n\n'
                      '2. Other Devices on Local Wi-Fi / LAN (Phones, Tablets):\n'
                      '   Start PocketBase with:\n'
                      '   ./pocketbase serve --http=0.0.0.0:8090\n'
                      '   Then enter your host machine local IP:\n'
                      '   http://192.168.x.x:8090\n\n'
                      '3. Android Emulator:\n'
                      '   Use: http://10.0.2.2:8090\n\n'
                      'All file downloads, avatars, and real-time database queries will immediately route to your configured backend.',
                      style: TextStyle(fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailConfigTab(bool isSmallScreen) {
    return SingleChildScrollView(
      child: Form(
        key: _emailFormKey,
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
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                  onPressed: _isTestingEmail ? null : _sendTestEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  icon: _isTestingEmail
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
    );
  }
}

/// Backwards-compatibility alias
typedef EmailSettingsPage = SettingsPage;
