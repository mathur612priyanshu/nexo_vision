import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/attendance_report.dart';
import 'package:flutter_application_1/innerScreens/attendance_screen.dart';
import 'package:flutter_application_1/screens/attendance_status.dart';
import 'package:flutter_application_1/screens/display_notes_page.dart';
import 'package:flutter_application_1/screens/display_pyq_screen.dart';
import 'package:flutter_application_1/screens/faculty_list.dart';
import 'package:flutter_application_1/innerScreens/login_screen.dart';
import 'package:flutter_application_1/innerScreens/profile_page.dart';
import 'package:flutter_application_1/innerScreens/register_face.dart';
import 'package:flutter_application_1/screens/webView.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Define GlobalKey for Scaffold
  final CarouselSliderController carouselController =
      CarouselSliderController();
  int currentIdx = 0;

  List imageList = [
    {"id": 1, "image_path": 'assets/images/img1.gif'},
    {"id": 2, "image_path": 'assets/images/img2.webp'},
    {"id": 3, "image_path": 'assets/images/img3.jpg'},
    {"id": 4, "image_path": 'assets/images/img4.jpg'},
    {"id": 5, "image_path": 'assets/images/img5.jpeg'},
    {"id": 6, "image_path": 'assets/images/img6.jpg'},
    {"id": 7, "image_path": 'assets/images/img7.jpeg'},
  ];

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }
    String userId = user?.uid ?? "null"; // Get the UID of the current user

    // method to know the current user is teacher or student
    Future<bool> isTeacher() async {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      String role = userDoc.exists ? userDoc['role'] : "Student";
      return role == "Teacher";
    }

    return Scaffold(
      key: _scaffoldKey, // Assign the key to Scaffold

      //Appbar
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState
                ?.openDrawer(); // Open the drawer using the key
          },
          icon: const Icon(
            Icons.menu,
            weight: 900, // For boldness if using Flutter 3.10 or later
            color: Colors.white,
          ),
        ),
        title: const Text(
          "Nexo Vision",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey,
      ),

      // call to drawer function
      drawer: drawer(),

      body: Column(
        children: [
          // call to slider function
          slider(),

          // grid view
          Expanded(
            child: Container(
              color: const Color.fromARGB(255, 211, 211, 211),
              // margin: EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              child: GridView.count(
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                crossAxisCount: 2,
                children: [
                  // erp button
                  InkWell(
                    onTap: () {
                      openWebPage(
                          context,
                          "https://iimt.icloudems.com/corecampus/index.php",
                          "ERP");
                    },
                    child: Card(
                      color: Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(
                                  width: MediaQuery.of(context).size.width / 3,
                                  height: MediaQuery.of(context).size.width / 3,
                                  child: Image.asset('assets/images/erp.avif')),
                              const Text(
                                "ERP",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  //Attendance module button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FutureBuilder<bool>(
                                    future: isTeacher(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(); // Show nothing while loading
                                      }
                                      if (snapshot.hasData &&
                                          snapshot.data == true) {
                                        return AttendanceReportScreen();
                                      }
                                      return AttendanceStatusPage(); // Return empty space if not a teacher
                                    },
                                  )));
                    },
                    child: Card(
                      color: Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(
                                  width: MediaQuery.of(context).size.width / 3,
                                  height: MediaQuery.of(context).size.width / 3,
                                  child: Image.asset(
                                      'assets/images/attendance.jpg')),
                              const Text(
                                "Attendance",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  //iimt website button
                  InkWell(
                    onTap: () {
                      openWebPage(
                          context, "https://www.iimtindia.net/", "IIMT");
                    },
                    child: Card(
                      color: Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(
                                  width: MediaQuery.of(context).size.width / 3,
                                  height: MediaQuery.of(context).size.width / 3,
                                  child: Image.asset('assets/images/web.png')),
                              const Text(
                                "Website",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // pyq button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PYQListPage()));
                    },
                    child: Card(
                      color: Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(
                                  width: MediaQuery.of(context).size.width / 3,
                                  height: MediaQuery.of(context).size.width / 3,
                                  child: Image.asset('assets/images/pyq.webp')),
                              const Text(
                                "PYQ",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Notes button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DisplayNotesPage()));
                    },
                    child: Card(
                      color: Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(
                                  width: MediaQuery.of(context).size.width / 3,
                                  height: MediaQuery.of(context).size.width / 3,
                                  child:
                                      Image.asset('assets/images/notes.png')),
                              const Text(
                                "Notes",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  //Faculty Button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TeacherListScreen()));
                    },
                    child: Card(
                      color: Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(
                                  width: MediaQuery.of(context).size.width / 3,
                                  height: MediaQuery.of(context).size.width / 3,
                                  child:
                                      Image.asset('assets/images/faculty.png')),
                              const Text(
                                "Faculty",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

//******************************************************************functions***************************************************************************** */

  // drawer function implementation
  Widget drawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // header of Navigation Drawer
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueGrey,
            ),
            child: Text(
              'Navigation Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),

          //Home button
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              // Handle navigation
              Navigator.pop(context);
            },
          ),

          // Profile button
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              // Handle navigation
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()));
            },
          ),

          //Settings
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Handle navigation
              Navigator.pop(context);
            },
          ),

          // logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              // Handle logout
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  //**********************************************************************/

  // implementation of slider function to slide photos
  Widget slider() {
    return Stack(
      children: [
        CarouselSlider(
          items: imageList
              .map((item) => Image.asset(
                    item['image_path'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ))
              .toList(),
          carouselController: carouselController,
          options: CarouselOptions(
            scrollPhysics: const BouncingScrollPhysics(),
            autoPlay: true,
            aspectRatio: 2,
            viewportFraction: 1,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(seconds: 2),
            onPageChanged: (index, reason) {
              setState(() {
                currentIdx = index;
              });
            },
          ),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: imageList.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => carouselController.animateToPage(entry.key),
                child: AnimatedContainer(
                  width: currentIdx == entry.key ? 15.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: currentIdx == entry.key ? Colors.white : Colors.grey,
                  ),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
