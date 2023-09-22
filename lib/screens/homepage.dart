import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String loginTime;
  String? _verificationId; // Store the verification ID here
  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  String verificationIDRecieved = "";
  bool otpCodeVisible = false;

  @override
  void initState() {
    fetchLoginTime().then((time) {
      setState(() {
        loginTime = time;
      });
    });
    super.initState();
  }

  Future<String> fetchLoginTime() async {
    await Future.delayed(Duration(seconds: 2));
    return '10:00 AM';
  }

  Future<void> _verifyPhoneNumber() async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieve on Android
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          // Handle verification failure
          print('Verification Failed: $e');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Store the verification ID
          setState(() {
            _verificationId = verificationId;
            otpCodeVisible = true; // Set OTP code input to visible
            otpController.text = ""; // Clear the OTP input field
          });
          print('Verification ID: $verificationId');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Called when auto-retrieve times out
          // You can handle this if needed
        },
      );
    } catch (e) {
      print('Error verifying phone number: $e');
    }
  }

  Future<void> _signInWithOTP() async {
    try {
      if (_verificationId != null) {
        final AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!, // Use the stored verification ID
          smsCode: otpController.text,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);

        // Collect and save user details after successful login
        collectAndSaveUserDetails();

        // Navigate to the dashboard
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Dashboard(loginTime: loginTime)),
        );
      } else {
        print('Verification ID is null. Please request OTP first.');
      }
    } catch (e) {
      print('Error signing in with OTP: $e');
    }
  }

  Future<void> collectAndSaveUserDetails() async {
    try {
      // Get the user's location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get the user's IP address using an IP address API
      final ipAddress = await fetchIpAddress();

      // Save the user's details to Firebase Realtime Database
      final userUid = FirebaseAuth.instance.currentUser?.uid;
      if (userUid != null) {
        final databaseReference = FirebaseDatabase.instance.reference();
        await databaseReference.child('user_details').child(userUid).set({
          'ipAddress': ipAddress,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      }

      print('User IP: $ipAddress');
      print('User Location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error collecting and saving user details: $e');
    }
  }

  Future<String> fetchIpAddress() async {
    try {
      final response =
          await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        final data = response.body;
        final ipAddress = data.replaceAll(
            '"', ''); // Remove double quotes from the IP address
        return ipAddress;
      } else {
        throw Exception('Failed to fetch IP address');
      }
    } catch (e) {
      print('Error fetching IP address: $e');
      return 'Unknown';
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Column(
        children: [
          Container(
            height: 100,
            color: Colors.deepPurple,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Verify phone number when the "LOGIN" button is clicked
                      _verifyPhoneNumber();
                    },
                    child: const Text('LOGIN', style: TextStyle(fontSize: 20)),
                  ),
                  SizedBox(height: 60),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 20.0),
                      child: Text(
                        'Phone number',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        fillColor: Colors.deepPurple,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 20.0),
                      child: Text(
                        'OTP',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: otpController,
                      decoration: InputDecoration(
                        fillColor: Colors.deepPurple,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Container(
                      child: ElevatedButton(
                          onPressed: () {
                            if (otpCodeVisible) {
                              _signInWithOTP(); // Use this to trigger the OTP verification
                            } else {
                              _verifyPhoneNumber(); // Use this to request OTP
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.white24),
                            shape: MaterialStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            minimumSize: MaterialStateProperty.all<Size>(
                              Size(320, 50.0),
                            ),
                          ),
                          child: Text(otpCodeVisible ? "Verify" : "Login")),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
