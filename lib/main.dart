import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: QRViewExample(),
    );
  }
}

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String qrText = 'Scan a QR code';

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Scanner'),
      ),
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.blue,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: MediaQuery.of(context).size.width * 0.8,
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  color: Colors.blue.shade50,
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: <Widget>[
                      Text(
                        'Scan result:',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      Text(
                        qrText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _handleScannedData(qrText),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shadowColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: Text('Open Link'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.camera_alt, color: Colors.white, size: 30),
              onPressed: () {
                if (controller != null) {
                  controller!.flipCamera();
                }
              },
            ),
          ),
          Positioned(
            top: 100,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.flash_on, color: Colors.white, size: 30),
              onPressed: () {
                if (controller != null) {
                  controller!.toggleFlash();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        qrText = scanData.code!; // Correctly assign the string value
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _handleScannedData(String data) {
    if (_isValidURL(data)) {
      _launchURLInChrome(data);
    } else if (_isValidEmail(data)) {
      _showInfoDialog('Email Address', data);
    } else if (_isValidPhoneNumber(data)) {
      _launchPhoneNumber(data);
    } else {
      _showInfoDialog('Scanned Data', data);
    }
  }

  bool _isValidURL(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(r'^\+?[0-9]{10,13}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  void _launchURLInChrome(String url) async {
    final chromeUrl = 'googlechrome://navigate?url=$url';
    if (await canLaunch(chromeUrl)) {
      await launch(chromeUrl);
    } else {
      await launch(url);
    }
  }

  void _launchPhoneNumber(String phoneNumber) async {
    final uri = 'tel:$phoneNumber';
    if (await canLaunch(uri)) {
      await launch(uri);
    } else {
      _showErrorDialog('Invalid Phone Number',
          'The scanned QR code does not contain a valid phone number.');
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
