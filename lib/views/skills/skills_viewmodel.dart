import 'package:flutter/material.dart';
import 'package:portfolio/models/about.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/services/db.dart';
import 'package:stacked/stacked.dart';

// ============================================================================
// SKILLS VIEWMODEL
// ============================================================================

class SkillsViewModel extends BaseViewModel {
  // ============================================================================
  // PROPERTIES
  // ============================================================================

  About? _about;
  About? get about => _about;

  List<Project> _prjs = [];

  bool _showSkills = false;
  bool get showSkills => _showSkills;

  List<SkillCategory> get skillCategories => about?.skillCategories ?? [];

  SkillCategory? _selectedSkillCategory;
  SkillCategory? get selectedSkillCategory => _selectedSkillCategory;

  List<String> get tags => selectedSkillCategory?.skills.map((e) => e.name).toList() ?? skillCategories.map((e) => e.name).toList();

  List<String> get clickableTags {
    return tags.where((e) => isClickable(e)).toList();
  }

  Offset? _lastClickPosition;
  Offset? get lastClickPosition => _lastClickPosition;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  void onInit({required List<Project> projects}) async {
    _prjs = projects;
    _about = await DbService().getAbout();
    notifyListeners();
    _showSkills = true;
    notifyListeners();
  }

  void onDispose() {}

  // ============================================================================
  // PUBLIC METHODS
  // ============================================================================

  void setSelectedSkills(SkillCategory skillCategory) {
    _selectedSkillCategory = skillCategory;
    notifyListeners();
  }

  bool isClickable(String skill) {
    bool isCategory = skillCategories.map((e) => e.name).contains(skill);
    bool isInProject = _prjs.map((e) => e.techStack).toList().expand((e) => e).contains(skill);
    return isCategory || isInProject;
  }

  void unselectSkills() {
    _selectedSkillCategory = null;
    notifyListeners();
  }

  // ============================================================================
  // EVENT HANDLERS
  // ============================================================================

  void onTagTap(int? skillId, String text, Offset? clickPostion, Function(String) filterProjects) async {
    print('onTagTap');
    print(skillId);
    print(text);
    print(clickPostion);

    _lastClickPosition = clickPostion;
    notifyListeners();

    // Check if a category is already selected
    bool insideCategory = _selectedSkillCategory != null;

    if (insideCategory) {
      List<Project> projects = _prjs.where((e) => e.techStack.contains(text)).toList();
      if (projects.isNotEmpty) {
        print('Projects found: ${projects.length}');
        filterProjects(text);
      }
    } else {
      SkillCategory? cat = skillCategories.firstWhere((e) => e.name == text);
      setSelectedSkills(cat);
    }

    // String? categoryName = clickableTags[skillId];
    // SkillCategory? cat = skillCategories.firstWhere((e) => e.name == categoryName);
    // setSelectedSkills(cat);
  }
}
