class About {
  final String avatar;
  final String bio;
  final List<SkillCategory> skillCategories;
  final List<String> mainSkills;

  About({
    required this.avatar,
    required this.bio,
    required this.skillCategories,
    required this.mainSkills,
  });

  About.fromMap(Map<String, dynamic> data)
      : avatar = data['avatar'] ?? '',
        bio = data['bio'] ?? '',
        skillCategories = ((data['skillCategories'] ?? []) as List<dynamic>).map((e) {
          return SkillCategory.fromMap(e as Map<String, dynamic>);
        }).toList(),
        mainSkills = (data['mainSkills'] ?? []).cast<String>();
}

class SkillCategory {
  final String name;
  final List<String> skills;

  SkillCategory({
    required this.name,
    required this.skills,
  });

  SkillCategory.fromMap(Map<String, dynamic> data)
      : name = data['name'] ?? '',
        skills = ((data['skills'] ?? []) as List<dynamic>).map((e) => e.toString()).toList();
}
