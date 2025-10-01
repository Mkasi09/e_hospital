import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../firebase_options.dart';

class UploadHospitalsScreen extends StatefulWidget {
  @override
  _UploadHospitalsScreenState createState() => _UploadHospitalsScreenState();
}

class _UploadHospitalsScreenState extends State<UploadHospitalsScreen> {
  bool _isUploading = false;
  String _status = "Ready to upload";
  int _uploadedCount = 0;
  int _totalHospitals = 0;

  // Complete list of Mpumalanga hospitals
  final List<Map<String, dynamic>> mpumalangaHospitals = [
    {
      "name": "Rob Ferreira Provincial Hospital",
      "location": "Nelspruit, Mpumalanga",
      "type": "Regional",
      "doctors": [
        "Dr. Smith",
        "Dr. Patel",
        "Dr. van der Merwe",
        "Dr. Khumalo",
        "Dr. Nkosi",
        "Dr. Botha",
        "Dr. Mabuza",
      ],
    },
    {
      "name": "Witbank Hospital",
      "location": "Emalahleni, Mpumalanga",
      "type": "Regional",
      "doctors": [
        "Dr. van Niekerk",
        "Dr. Dlamini",
        "Dr. Pretorius",
        "Dr. Shabangu",
        "Dr. Meyer",
        "Dr. Ndlovu",
      ],
    },
    {
      "name": "Ermelo Provincial Hospital",
      "location": "Ermelo, Mpumalanga",
      "type": "Regional",
      "doctors": [
        "Dr. Grobler",
        "Dr. Masango",
        "Dr. van Rensburg",
        "Dr. Maseko",
        "Dr. Steyn",
        "Dr. Sibiya",
      ],
    },
    {
      "name": "Mapulaneng Hospital",
      "location": "Bushbuckridge, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. Maluleke",
        "Dr. Chauke",
        "Dr. Mnisi",
        "Dr. Mkhabela",
        "Dr. Nkuna",
        "Dr. Mokoena",
      ],
    },
    {
      "name": "Temba Hospital",
      "location": "Kanyamazane, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. Mabunda",
        "Dr. Baloyi",
        "Dr. Mahlangu",
        "Dr. Nxumalo",
        "Dr. Shongwe",
        "Dr. Mthethwa",
      ],
    },
    {
      "name": "Matibidi Hospital",
      "location": "Matibidi, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. Nkambule",
        "Dr. Mamba",
        "Dr. Dlamini",
        "Dr. Simelane",
        "Dr. Hlophe",
        "Dr. Magagula",
      ],
    },
    {
      "name": "Shongwe Hospital",
      "location": "Kamhlushwa, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. Zwane",
        "Dr. Mtshali",
        "Dr. Ngwenya",
        "Dr. Mkhwanazi",
        "Dr. Cele",
        "Dr. Zulu",
      ],
    },
    {
      "name": "Tonga Hospital",
      "location": "Tonga, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. Ntimane",
        "Dr. Mboweni",
        "Dr. Sithole",
        "Dr. Mhlongo",
        "Dr. Nkosi",
        "Dr. Mdluli",
      ],
    },
    {
      "name": "Embhuleni Hospital",
      "location": "Badplaas, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. Vilakazi",
        "Dr. Mthembu",
        "Dr. Buthelezi",
        "Dr. Zungu",
        "Dr. Mngomezulu",
        "Dr. Ntuli",
      ],
    },
    {
      "name": "Carolina Hospital",
      "location": "Carolina, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. de Wet",
        "Dr. van Zyl",
        "Dr. Maseko",
        "Dr. Sithole",
        "Dr. Potgieter",
        "Dr. Nkosi",
      ],
    },
    {
      "name": "Elijah Mango Hospital",
      "location": "KwaMhlanga, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. Mahlangu",
        "Dr. Nkosi",
        "Dr. Masina",
        "Dr. Mokoena",
        "Dr. Skosana",
        "Dr. Mkhize",
      ],
    },
    {
      "name": "Benedictine Hospital",
      "location": "Ntunda, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. Ndlovu",
        "Dr. Mkhwanazi",
        "Dr. Zwane",
        "Dr. Mthethwa",
        "Dr. Cele",
        "Dr. Zulu",
      ],
    },
    {
      "name": "Philadelphia Hospital",
      "location": "Philadelphia, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. van Staden",
        "Dr. Marais",
        "Dr. Moolman",
        "Dr. Nkosi",
        "Dr. Smit",
        "Dr. Jacobs",
      ],
    },
    {
      "name": "Evander Hospital",
      "location": "Evander, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. Venter",
        "Dr. du Plessis",
        "Dr. Mkhize",
        "Dr. Naidoo",
        "Dr. Govender",
        "Dr. Pillay",
      ],
    },
    {
      "name": "Barberton Hospital",
      "location": "Barberton, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. Ross",
        "Dr. Ferreira",
        "Dr. Mabuza",
        "Dr. van Tonder",
        "Dr. Nkosi",
        "Dr. Steyn",
      ],
    },
    {
      "name": "Lydenburg Hospital",
      "location": "Lydenburg, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. Coetzee",
        "Dr. Mahlangu",
        "Dr. van der Walt",
        "Dr. Nkosi",
        "Dr. Pretorius",
        "Dr. Mkhize",
      ],
    },
    {
      "name": "Middelburg Hospital",
      "location": "Middelburg, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. van Rensburg",
        "Dr. Maseko",
        "Dr. Botha",
        "Dr. Nkosi",
        "Dr. Olivier",
        "Dr. Mkhwanazi",
      ],
    },
    {
      "name": "Belfast Hospital",
      "location": "Belfast, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. van Niekerk",
        "Dr. Mdluli",
        "Dr. Smit",
        "Dr. Nkosi",
        "Dr. Jacobs",
        "Dr. Mkhize",
      ],
    },
    {
      "name": "Amsterdam Hospital",
      "location": "Amsterdam, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. van der Merwe",
        "Dr. Mthombeni",
        "Dr. de Beer",
        "Dr. Nkosi",
        "Dr. Swanepoel",
        "Dr. Mkhwanazi",
      ],
    },
    {
      "name": "Piet Retief Hospital",
      "location": "Piet Retief, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. van Zyl",
        "Dr. Maseko",
        "Dr. Steyn",
        "Dr. Nkosi",
        "Dr. Venter",
        "Dr. Mkhize",
      ],
    },
    {
      "name": "Standerton Hospital",
      "location": "Standerton, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. van Staden",
        "Dr. Mahlangu",
        "Dr. Marais",
        "Dr. Nkosi",
        "Dr. Smit",
        "Dr. Mkhwanazi",
      ],
    },
    {
      "name": "Eerstehoek Hospital",
      "location": "Eerstehoek, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. van Tonder",
        "Dr. Mabuza",
        "Dr. Ross",
        "Dr. Nkosi",
        "Dr. Ferreira",
        "Dr. Mkhize",
      ],
    },
    {
      "name": "Kriel Hospital",
      "location": "Kriel, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. van Rensburg",
        "Dr. Maseko",
        "Dr. Botha",
        "Dr. Nkosi",
        "Dr. Olivier",
        "Dr. Mkhwanazi",
      ],
    },
    {
      "name": "Secunda Hospital",
      "location": "Secunda, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. van Niekerk",
        "Dr. Mdluli",
        "Dr. Smit",
        "Dr. Nkosi",
        "Dr. Jacobs",
        "Dr. Mkhize",
      ],
    },
    {
      "name": "Breyten Hospital",
      "location": "Breyten, Mpumalanga",
      "type": "District",
      "doctors": [
        "Dr. van der Merwe",
        "Dr. Mthombeni",
        "Dr. de Beer",
        "Dr. Nkosi",
        "Dr. Swanepoel",
        "Dr. Mkhwanazi",
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _totalHospitals = mpumalangaHospitals.length;
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized successfully");
      setState(() {
        _status = "Ready to upload ($_totalHospitals hospitals)";
      });
    } catch (e) {
      print("Error initializing Firebase: $e");
      setState(() {
        _status = "Error initializing Firebase: $e";
      });
    }
  }

  Future<void> uploadHospitals() async {
    if (_totalHospitals == 0) {
      setState(() {
        _status = "No hospitals to upload";
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
      _status = "Starting upload...";
    });

    final db = FirebaseFirestore.instance;

    try {
      for (var hospital in mpumalangaHospitals) {
        try {
          await db.collection('hospitals').doc(hospital['name']).set(hospital);
          setState(() {
            _uploadedCount++;
            _status =
                "Uploaded $_uploadedCount/$_totalHospitals: ${hospital['name']}";
          });
          print('✅ Uploaded: ${hospital['name']}');

          // Small delay to avoid overwhelming Firebase
          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          print('❌ Error uploading ${hospital['name']}: $e');
        }
      }

      setState(() {
        _status = "✅ All $_totalHospitals hospitals uploaded successfully!";
      });

      // Show success dialog
      _showSuccessDialog();
    } catch (e) {
      print('❌ General error uploading hospitals: $e');
      setState(() {
        _status = "❌ Error uploading hospitals: $e";
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Upload Complete"),
          content: Text(
            "Successfully uploaded $_totalHospitals hospitals to Firebase!",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> clearAllHospitals() async {
    setState(() {
      _isUploading = true;
      _status = "Clearing all hospitals...";
    });

    final db = FirebaseFirestore.instance;

    try {
      final querySnapshot = await db.collection('hospitals').get();
      final batch = db.batch();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      setState(() {
        _status = "✅ All hospitals cleared from database!";
      });

      print('All hospitals cleared successfully');
    } catch (e) {
      print('Error clearing hospitals: $e');
      setState(() {
        _status = "❌ Error clearing hospitals: $e";
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  double get _progress {
    if (_totalHospitals == 0) return 0.0;
    return _uploadedCount / _totalHospitals;
  }

  Future<void> uploadDoctorsToUsersCollection() async {
    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
      _status = "Starting doctor upload...";
    });

    final db = FirebaseFirestore.instance;

    try {
      // First, get all hospitals to map hospital names to IDs
      final hospitalsSnapshot = await db.collection('hospitals').get();
      final hospitalMap = <String, String>{};

      for (var hospitalDoc in hospitalsSnapshot.docs) {
        final hospitalData = hospitalDoc.data() as Map<String, dynamic>;
        hospitalMap[hospitalData['name']] = hospitalDoc.id;
      }

      int totalDoctors = 0;

      // Count total doctors first
      for (var hospital in mpumalangaHospitals) {
        totalDoctors += (hospital['doctors'] as List).length;
      }

      int doctorCount = 0;

      // Upload doctors for each hospital
      for (var hospital in mpumalangaHospitals) {
        final hospitalName = hospital['name'] as String;
        final hospitalId = hospitalMap[hospitalName];
        final doctors = hospital['doctors'] as List<String>;

        if (hospitalId == null) {
          print('❌ Hospital ID not found for: $hospitalName');
          continue;
        }

        for (var doctorName in doctors) {
          try {
            // Extract first name for email
            final firstName = doctorName.replaceAll('Dr. ', '').split(' ')[0];
            final email = "${firstName.toLowerCase()}@gmail.com";

            // Generate specialty (you can customize this logic)
            final specialty = _generateSpecialty(doctorName);

            final doctorData = {
              "createdAt": FieldValue.serverTimestamp(),
              "email": email,
              "hospitalId": hospitalId,
              "hospitalName": hospitalName,
              "name": doctorName,
              "profilePicture":
                  "https://res.cloudinary.com/dzz3iovq5/raw/upload/v1751109518/f6v8iyiiab4kmqbfwsdw.png",
              "requiresPasswordReset": false,
              "role": "doctor",
              "specialty": specialty,
            };

            await db.collection('users').add(doctorData);

            doctorCount++;
            setState(() {
              _uploadedCount = doctorCount;
              _status =
                  "Uploaded $doctorCount/$totalDoctors doctors: $doctorName";
            });

            print('✅ Uploaded doctor: $doctorName');

            // Small delay to avoid overwhelming Firebase
            await Future.delayed(Duration(milliseconds: 50));
          } catch (e) {
            print('❌ Error uploading doctor $doctorName: $e');
          }
        }
      }

      setState(() {
        _status = "✅ All $totalDoctors doctors uploaded successfully!";
      });
    } catch (e) {
      print('❌ General error uploading doctors: $e');
      setState(() {
        _status = "❌ Error uploading doctors: $e";
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  String _generateSpecialty(String doctorName) {
    // Simple logic to assign specialties based on name or random
    // You can customize this as needed
    final specialties = [
      "Cardiologist",
      "Neurologist",
      "Pediatrician",
      "Surgeon",
      "Dermatologist",
      "Psychiatrist",
      "Oncologist",
      "Orthopedist",
      "Gynecologist",
      "Radiologist",
    ];

    // Use the doctor's name to deterministically assign a specialty
    final hash = doctorName.hashCode.abs();
    return specialties[hash % specialties.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Mpumalanga Hospitals"),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _isUploading ? Icons.cloud_upload : Icons.cloud_done,
                      size: 50,
                      color: _isUploading ? Colors.orange : Colors.green,
                    ),
                    SizedBox(height: 10),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color:
                            _status.contains("❌")
                                ? Colors.red
                                : _status.contains("✅")
                                ? Colors.green
                                : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    if (_isUploading && _totalHospitals > 0)
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    if (_isUploading && _totalHospitals > 0)
                      SizedBox(height: 10),
                    if (_isUploading && _totalHospitals > 0)
                      Text(
                        "Progress: $_uploadedCount/$_totalHospitals (${(_progress * 100).toStringAsFixed(1)}%)",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Upload Button
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton.icon(
                  onPressed: uploadHospitals,
                  icon: Icon(Icons.cloud_upload),
                  label: Text(
                    "Upload All Hospitals",
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: Colors.blue[700],
                  ),
                ),

            SizedBox(height: 15),
            // Add this button alongside your existing buttons
            if (!_isUploading)
              ElevatedButton.icon(
                onPressed: uploadDoctorsToUsersCollection,
                icon: Icon(Icons.person_add),
                label: Text(
                  "Upload Doctors to Users",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.green[700],
                ),
              ),

            // Clear Database Button
            if (!_isUploading)
              OutlinedButton.icon(
                onPressed: clearAllHospitals,
                icon: Icon(Icons.delete_outline),
                label: Text("Clear All Hospitals"),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  foregroundColor: Colors.red,
                ),
              ),

            SizedBox(height: 20),

            // Info Text
            Text(
              "Total Hospitals: $_totalHospitals\n"
              "Each hospital has 6 doctors",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
