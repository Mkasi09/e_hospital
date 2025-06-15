import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadFileToCloudinaryAndFirestore({
  required File file,
  required String fileName,
  required CollectionReference patientFilesCollection,
  required BuildContext context,

}) async {
  try {
    final cloudinaryUploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/dzz3iovq5/raw/upload');

    final request = http.MultipartRequest('POST', cloudinaryUploadUrl)
      ..fields['upload_preset'] = 'ehospital'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);
    final data = json.decode(responseData.body);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (response.statusCode == 200) {
      final downloadUrl = data['secure_url'];
      await patientFilesCollection.add({
        'title': fileName,
        'date': DateTime.now(),
        'status': 'pending',
        'downloadUrl': downloadUrl,
        'userId': currentUser?.uid
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded to Cloudinary.')),
      );
    } else {
      throw Exception('Upload failed: ${data['error']['message']}');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload failed: $e')),
    );
  }
}

