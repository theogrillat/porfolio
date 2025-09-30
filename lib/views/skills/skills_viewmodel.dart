import 'package:flutter/material.dart';
import 'package:portfolio/models/about.dart';
import 'package:portfolio/services/db.dart';
import 'package:stacked/stacked.dart';

class SkillsViewModel extends BaseViewModel {
  About? _about;
  About? get about => _about;

  bool _showSkills = false;
  bool get showSkills => _showSkills;

  List<SkillCategory> get skillCategories => about?.skillCategories ?? [];

  SkillCategory? _selectedSkillCategory;
  SkillCategory? get selectedSkillCategory => _selectedSkillCategory;

  List<String> get tags => selectedSkillCategory?.skills.map((e) => e.name).toList() ?? skillCategories.map((e) => e.name).toList();
  List<String> get clickableTags => tags.where((e) => isClickable(e)).toList();

  void setSelectedSkills(SkillCategory skillCategory) {
    _selectedSkillCategory = skillCategory;
    notifyListeners();
  }

  Offset? _lastClickPosition;
  Offset? get lastClickPosition => _lastClickPosition;

  void onTagTap(int? skillId, Offset? clickPostion) async {
    if (skillId == null) return;

    _lastClickPosition = clickPostion;
    notifyListeners();

    print('On Tag Tap postion: ${clickPostion?.dx}, ${clickPostion?.dy}');

    String? categoryName = clickableTags[skillId];
    SkillCategory? cat = skillCategories.firstWhere((e) => e.name == categoryName);
    setSelectedSkills(cat);
    notifyListeners();
  }

  bool isClickable(String skill) {
    return skillCategories.map((e) => e.name).contains(skill);
  }

  void unselectSkills() {
    _selectedSkillCategory = null;
    notifyListeners();
  }

  void onInit() async {
    _about = await DbService().getAbout();
    notifyListeners();
    _showSkills = true;
    notifyListeners();
    for (var skillCategory in skillCategories) {
      print('--------------------------------');
      print(skillCategory.name);
      print(skillCategory.skills);
    }
  }

  void onDispose() {}
}
