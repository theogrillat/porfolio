import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portfolio/models/about.dart';
import 'package:portfolio/models/project.dart';

class DbService {
  FirebaseFirestore db = FirebaseFirestore.instance;

  // ABOUT

  Future<About?> getAbout() async {
    try {
      DocumentSnapshot doc = await db.collection('static').doc('about').get();
      if (!doc.exists) throw Error();
      return About.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print(e);
      return null;
    }
  }

  // PROJECTS

  Future<List<Project>> getAllProjects() async {
    try {
      CollectionReference ref = db.collection('projects');
      QuerySnapshot snapshot = await ref.get();
      inspect(snapshot.docs);
      List<Project> projects = snapshot.docs.map((doc) {
        String id = doc.id;
        return Project.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'id': id,
        });
      }).toList();
      return projects;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<Project?> getProjectById(String uid) async {
    try {
      DocumentSnapshot doc = await db.collection('projects').doc(uid).get();
      if (!doc.exists) throw Error();
      Project project = Project.fromMap((doc.data() as Map<String, dynamic>));
      return project;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
