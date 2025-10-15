import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';

class TimeSyncState {
  final bool isLoading;
  final bool isOfflineMode;
  final String message;
  
  TimeSyncState({
    required this.isLoading,
    required this.isOfflineMode,
    required this.message,
  });
}

class AppLoadingScreen extends StatefulWidget {
  final Future<void> Function(bool offlineMode) onInitializationComplete;
  
  const AppLoadingScreen({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> {
  TimeSyncState _state = TimeSyncState(
    isLoading: true,
    isOfflineMode: false,
    message: 'Synchronizing time with server...',
  );
  bool _showRetryOptions = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _syncTime();
  }

  Future<void> _syncTime() async {
    setState(() {
      _state = TimeSyncState(
        isLoading: true,
        isOfflineMode: false,
        message: 'Synchronizing time with server...',
      );
      _showRetryOptions = false;
    });

    // Set timeout timer for 10 seconds
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _state = TimeSyncState(
            isLoading: false,
            isOfflineMode: false,
            message: 'Unable to synchronize time. Check your connection.',
          );
          _showRetryOptions = true;
        });
      }
    });

    try {
      // Attempt to get NTP time
      final int ntpOffset = await NTP.getNtpOffset();
      
      // Cancel timeout timer since we got a response
      _timeoutTimer?.cancel();
      
      if (mounted) {
        setState(() {
          _state = TimeSyncState(
            isLoading: false,
            isOfflineMode: false,
            message: 'Time synchronized successfully!',
          );
        });
        
        // Small delay to show success message
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          widget.onInitializationComplete(false);
        }
      }
    } catch (e) {
      // Cancel timeout timer since we got an error
      _timeoutTimer?.cancel();
      
      if (mounted) {
        setState(() {
          _state = TimeSyncState(
            isLoading: false,
            isOfflineMode: false,
            message: 'Failed to synchronize time.',
          );
          _showRetryOptions = true;
        });
      }
    }
  }

  void _proceedOffline() {
    setState(() {
      _state = TimeSyncState(
        isLoading: false,
        isOfflineMode: true,
        message: 'Proceeding in offline mode...',
      );
    });
    
    // Small delay to show message
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        widget.onInitializationComplete(true);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.access_time,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            
            // Status message
            Text(
              _state.message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // Loading indicator
            if (_state.isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'This ensures accurate time tracking',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
            
            // Retry options
            if (_showRetryOptions) ...[
              const SizedBox(height: 20),
              const Text(
                'Would you like to try again or proceed offline?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _syncTime,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 20),
                  OutlinedButton(
                    onPressed: _proceedOffline,
                    child: const Text('Proceed Offline'),
                  ),
                ],
              ),
            ],
            
            // Offline mode confirmation
            if (_state.isOfflineMode) ...[
              const SizedBox(height: 20),
              const Icon(
                Icons.cloud_off,
                size: 40,
                color: Colors.orange,
              ),
              const SizedBox(height: 10),
              const Text(
                'Some features will be disabled',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}