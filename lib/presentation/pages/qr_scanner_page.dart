import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  final VoidCallback? onClose;
  const QRScannerPage({super.key, this.onClose});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanned = false;
  bool isInitialized = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose ?? () => Navigator.pop(context),
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              final torchState = state.torchState;
              switch (torchState) {
                case TorchState.off:
                  return IconButton(
                    icon: const Icon(Icons.flash_off, color: Colors.grey),
                    onPressed: () => controller.toggleTorch(),
                  );
                case TorchState.on:
                  return IconButton(
                    icon: const Icon(Icons.flash_on, color: Colors.yellow),
                    onPressed: () => controller.toggleTorch(),
                  );
                case TorchState.auto:
                  return IconButton(
                    icon: const Icon(Icons.flash_auto, color: Colors.blue),
                    onPressed: () => controller.toggleTorch(),
                  );
                case TorchState.unavailable:
                  return const SizedBox.shrink();
              }
            },
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              final cameraFacing = state.cameraDirection;
              switch (cameraFacing) {
                case CameraFacing.front:
                  return IconButton(
                    icon: const Icon(Icons.camera_front),
                    onPressed: () => controller.switchCamera(),
                  );
                case CameraFacing.back:
                  return IconButton(
                    icon: const Icon(Icons.camera_rear),
                    onPressed: () => controller.switchCamera(),
                  );
                case CameraFacing.external:
                  return IconButton(
                    icon: const Icon(Icons.camera),
                    onPressed: () => controller.switchCamera(),
                  );
                case CameraFacing.unknown:
                  return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            placeholderBuilder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
            onDetect: (capture) {
              if (isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  setState(() {
                    isScanned = true;
                  });
                  Navigator.pop(context, code);
                }
              }
            },
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              if (!state.isInitialized) {
                return const SizedBox.shrink();
              }
              return Stack(
                children: [
                  // Semi-transparent overlay with a hole in the middle
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.5),
                      BlendMode.srcOut,
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            backgroundBlendMode: BlendMode.dstOut,
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            height: 250,
                            width: 250,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Purple Bordered Square
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 250,
                      width: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  // Scanning Hint Text
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: const Center(
                      child: Text(
                        'Align QR code within the square',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
