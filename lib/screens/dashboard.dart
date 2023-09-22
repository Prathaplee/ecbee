import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:ecbee/screens/past_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class Dashboard extends StatefulWidget {
  final String loginTime;

  const Dashboard({Key? key, required this.loginTime});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int randomNumber = 0; // Initialize with 0
  String currentTime = ''; // Initialize with an empty string
  late Timer timer; // Timer to update the time
  final DatabaseReference databaseRef = FirebaseDatabase.instance.reference();
  final Reference storageRef = FirebaseStorage.instance.ref().child('qr_images');

  @override
  void initState() {
    super.initState();
    generateRandomNumber();
    updateTime(); // Initial call to update the time
    // Start a timer to update the time every second
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => updateTime());
  }

  void updateTime() {
    final String formattedTime = DateFormat.Hm().format(DateTime.now());
    setState(() {
      currentTime = formattedTime;
    });
  }

  // Dispose the timer to prevent memory leaks
  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void generateRandomNumber() {
    // Generate a random number between 1 and 99999
    final random = Random();
    final generatedNumber = random.nextInt(99999) + 1;

    setState(() {
      randomNumber = generatedNumber;
    });
  }
  void _saveData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create a QR image
        final QrPainter qrPainter = QrPainter(
          data: randomNumber.toString(),
          version: QrVersions.auto,
          color: Colors.black,
          emptyColor: Colors.white,
        );

        // Generate an image data as Uint8List
        final imageData = (await qrPainter.toImageData(200))?.buffer.asUint8List();

        // Define a unique path for the image in Firebase Storage
        final imagePath = '${user.uid}/qr_image.png';

        // Upload the QR image to Firebase Storage
        await storageRef.child(imagePath).putData(imageData!);

        // Display a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR image saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving QR image: $e'); // Log the specific error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving QR image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            height: 100,
            color: Colors.deepPurple, // Grey color for the top section
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('PLUGIN', style: TextStyle(fontSize: 20)),
                  ),
                ),
                Container(
                  width: 200.0, // Set the width of the container
                  child: QrImageView(
                    data: randomNumber.toString(), // Use randomNumber as QR code data
                    version: QrVersions.auto,
                    size: 200.0, // Set the size of the QR code
                    backgroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 16), // Add some spacing
                Text(
                  'Generated number',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  '$randomNumber',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1), // Border properties
                borderRadius: BorderRadius.circular(10), // Rounded border
              ),
              child: TextButton(
                onPressed: () async {
                  final User? user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    final qrCodeData = randomNumber.toString();
                    final currentTime = DateFormat('h:mm a').format(DateTime.now());

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PastLogin(
                          userId: user.uid,
                          qrCodeData: qrCodeData,
                          currentTime: currentTime,
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  'Last login at Today, ${DateFormat('h:mm a').format(DateTime.now())}',
                  style: TextStyle(fontSize: 16, color: Colors.white),

                ),
              ),
            ),
            SizedBox(height: 16), // Add some spacing

            ElevatedButton(
              onPressed: () async {
                try {
                  FirebaseDatabase.instance.ref().child("Generated Number").set(randomNumber);
                  final User? user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    final folderPath = 'Qr_images'; // Change this to your desired folder path
                    final imagePath = '$folderPath/${user.uid}/qr_image.png';

                    // Create a QR image
                    final QrPainter qrPainter = QrPainter(
                      data: randomNumber.toString(),
                      version: QrVersions.auto,
                      color: Colors.black,
                      emptyColor: Colors.white,
                    );

                    // Generate an image data as Uint8List
                    final qrCodeSize = 200; // Set the size of the QR code image
                    final recorder = PictureRecorder();
                    final canvas = Canvas(recorder, Rect.fromPoints(Offset(0, 0), Offset(qrCodeSize.toDouble(), qrCodeSize.toDouble())));
                    qrPainter.paint(canvas, Size(qrCodeSize.toDouble(), qrCodeSize.toDouble()));
                    final picture = recorder.endRecording();
                    final img = await picture.toImage(qrCodeSize, qrCodeSize);
                    final ByteData? byteData = await img.toByteData(format: ImageByteFormat.png);
                    if (byteData != null) {
                      final ByteData nonNullableByteData = byteData;
                      final imageData = nonNullableByteData.buffer.asUint8List();
                      await storageRef.child(imagePath).putData(imageData);

                      // Now you can use imageData
                    } else {
                      // Handle the case where byteData is null
                    }
                    // Upload the QR image to Firebase Storage using the specified path

                    // Display a success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('QR image saved successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error saving QR image: $e'); // Log the specific error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving QR image. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.white24),
                shape: MaterialStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                minimumSize: MaterialStateProperty.all<Size>(
                  Size(260, 50.0),
                ),
              ),
              child: Text('SAVE', style: TextStyle(fontSize: 20)),
            ),

          ],
        ),
      ),
    );
  }
}
