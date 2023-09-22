import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PastLogin extends StatefulWidget {
  final String userId;
  final String qrCodeData;
  final String currentTime;

  const PastLogin({
    Key? key,
    required this.userId,
    required this.qrCodeData,
    required this.currentTime,
  }) : super(key: key);

  @override
  State<PastLogin> createState() => _PastLoginState();
}

class _PastLoginState extends State<PastLogin> {
  List<LoginHistory> loginHistory = [];

  Future<void> fetchLoginHistory() async {
    try {
      final userUid = widget.userId; // Get the user's UID from the widget
      final historyCollection =
          FirebaseFirestore.instance.collection('login_history');

      final snapshot = await historyCollection
          .where('userId', isEqualTo: userUid)
          .orderBy('time',
              descending: true) // Assuming 'time' is the timestamp of the login
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          loginHistory = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return LoginHistory(
              loginTime: data['time'] != null
                  ? DateFormat('yyyy-MM-dd HH:mm:ss')
                      .format((data['time'] as Timestamp).toDate())
                  : 'N/A',
              ipAddress: data['ipAddress'] ?? 'N/A',
              location: data['location'] ?? 'N/A',
            );
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching login history: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLoginHistory();
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
          TextButton(
            onPressed: () async {
              final User? user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final qrCodeData = widget.qrCodeData;
                final currentTime = widget.currentTime;

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
              'Last login at ${widget.currentTime}',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: loginHistory.length,
              itemBuilder: (context, index) {
                final history = loginHistory[index];
                return ListTile(
                  title: Text(
                    'Login Time: ${history.loginTime}',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IP Address: ${history.ipAddress}',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      Text(
                        'Location: ${history.location}',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LoginHistory {
  final String loginTime;
  final String ipAddress;
  final String location;

  LoginHistory({
    required this.loginTime,
    required this.ipAddress,
    required this.location,
  });
}
