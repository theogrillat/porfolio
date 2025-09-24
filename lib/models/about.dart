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

class Skill {
  final String name;
  final int level;

  Skill({
    required this.name,
    required this.level,
  });

  Skill.fromMap(Map<String, dynamic> data)
      : name = data['name'] ?? '',
        level = data['level'] ?? 0;
}

class SkillCategory {
  final String name;
  final List<Skill> skills;

  SkillCategory({
    required this.name,
    required this.skills,
  });

  SkillCategory.fromMap(Map<String, dynamic> data)
      : name = data['name'] ?? '',
        skills = ((data['skills'] ?? []) as List<dynamic>).map((e) => Skill.fromMap(e as Map<String, dynamic>)).toList();
}
