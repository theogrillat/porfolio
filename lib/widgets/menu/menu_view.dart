import 'package:flutter/material.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/shared/coords.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:portfolio/widgets/hover.dart';
import 'package:stacked/stacked.dart';
import 'menu_viewmodel.dart';

class MenuView extends StatelessWidget {
  const MenuView({
    super.key,
    required this.homeModel,
    required this.boxSize,
  });

  final HomeViewmodel homeModel;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MenuViewModel>.reactive(
      viewModelBuilder: () => MenuViewModel(),
      onViewModelReady: (model) => model.onInit(),
      onDispose: (model) => model.onDispose(),
      builder: (context, model, child) {
        return GridBox(
          show: homeModel.showMenu,
          transitionDuration: const Duration(milliseconds: 300),
          transitionCurve: Curves.easeInOutCubicEmphasized,
          background: homeModel.backgroundColor,
          foreground: homeModel.foregroundColor,
          boxSize: boxSize,
          item: SharedItems(context).menu,
          fakeBorders: false,
          extendLeft: true,
          child: (box) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: isPortrait(context) ? 55 : homeModel.menuButtonSize(context) - Constants.edgeWidth(context) * 2,
                  padding: const EdgeInsets.only(left: 25),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PROJETS'.toUpperCase(),
                          style: Typos(context).large(color: homeModel.foregroundColor),
                        ),
                        if (homeModel.filterSkills.isNotEmpty)
                          Hover(
                            showCursor: true,
                            child: (h) => GestureDetector(
                              onTap: () => homeModel.clearFilter(),
                              child: Container(
                                height: isPortrait(context) ? 55 : homeModel.menuButtonSize(context) - Constants.edgeWidth(context) * 2,
                                padding: const EdgeInsets.only(left: 15, right: 15),
                                decoration: BoxDecoration(
                                  color: h ? homeModel.foregroundColor : Colors.transparent,
                                ),
                                child: Center(
                                  child: Stack(
                                    children: [
                                      Opacity(
                                        opacity: h ? 0 : 1,
                                        child: Center(
                                          child: Text(
                                            'CLEAR FILTER',
                                            style: Typos(context).large(color: homeModel.foregroundColor).copyWith(
                                                  decoration: TextDecoration.underline,
                                                  decorationThickness: 2,
                                                  decorationStyle: TextDecorationStyle.dotted,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        left: 0,
                                        bottom: 0,
                                        child: Opacity(
                                          opacity: h ? 1 : 0,
                                          child: Center(
                                            child: Text(
                                              homeModel.filterSkills.isEmpty ? '' : '<${homeModel.filterSkills.join('•')}>',
                                              style: Typos(context).large(color: homeModel.backgroundColor.withValues(alpha: h ? 0.7 : 1.0)).copyWith(
                                                    decoration: TextDecoration.lineThrough,
                                                    decorationThickness: 2,
                                                    decorationColor: homeModel.backgroundColor,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: Constants.edgeWidth(context),
                  color: homeModel.foregroundColor,
                ),
                Builder(builder: (context) {
                  List<Project> projects = homeModel.prjs;
                  projects.sort((a, b) => a.priority.compareTo(b.priority));
                  if (homeModel.filterSkills.isNotEmpty) {
                    // projects.sort((a, b) {
                    //   bool aIsPartOfFilter = homeModel.filteredProjects.any((p) => p.id == a.id);
                    //   bool bIsPartOfFilter = homeModel.filteredProjects.any((p) => p.id == b.id);
                    //   if (aIsPartOfFilter && !bIsPartOfFilter) return -1;
                    //   if (!aIsPartOfFilter && bIsPartOfFilter) return 1;
                    //   return 1;
                    // });
                    List<Project> filteredProjects = homeModel.filteredProjects;
                    List<Project> unfilteredProjects = projects.where((p) => !filteredProjects.any((f) => f.id == p.id)).toList();
                    projects = filteredProjects + unfilteredProjects;
                  }
                  return Expanded(
                    child: ListView.builder(
                      itemCount: projects.length,
                      padding: const EdgeInsets.all(0),
                      itemBuilder: (context, index) {
                        Project project = projects[index];
                        bool isSelected = homeModel.currentProject?.id == project.id;
                        bool isPartOfFilter = homeModel.filterSkills.isEmpty ? true : homeModel.filteredProjects.any((p) => p.id == project.id);
                        return Hover(
                          showCursor: true,
                          child: (h) => GestureDetector(
                            onTap: () => homeModel.goToThisProject(project),
                            child: Opacity(
                              opacity: isPartOfFilter || h ? 1 : 0.3,
                              child: Container(
                                height: 75 - Constants.edgeWidth(context),
                                padding: EdgeInsets.only(left: 25, right: h ? 25 : 0),
                                decoration: BoxDecoration(
                                  color: h ? homeModel.foregroundColor : Colors.transparent,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (homeModel.anyProjectIsSelected)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 10),
                                        child: Opacity(
                                          opacity: isSelected ? 1 : 0,
                                          child: Text(
                                            '/',
                                            style: Typos(context).large(color: h ? homeModel.backgroundColor : homeModel.foregroundColor),
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        project.title,
                                        style: Typos(context).large(color: h ? homeModel.backgroundColor : homeModel.foregroundColor),
                                      ),
                                    ),
                                    Text(
                                      '->',
                                      style: Typos(context).regular(color: h ? homeModel.backgroundColor : Colors.transparent),
                                    ),
                                    if (isPartOfFilter && !h)
                                      Container(
                                        height: homeModel.menuButtonSize(context) - Constants.edgeWidth(context) * 2,
                                        padding: const EdgeInsets.only(left: 15, right: 15),
                                        child: Center(
                                          child: Text(
                                            homeModel.filterSkills.isEmpty ? '' : '<${homeModel.filterSkills.join('•')}>',
                                            style: Typos(context).large(color: homeModel.foregroundColor),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class MenuBarrier extends StatelessWidget {
  const MenuBarrier({
    super.key,
    required this.homeModel,
    required this.boxSize,
  });

  final HomeViewmodel homeModel;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    return GridBox(
      show: homeModel.showMenu,
      transparent: true,
      transitionDuration: const Duration(milliseconds: 300),
      transitionCurve: Curves.easeInOutCubicEmphasized,
      background: homeModel.backgroundColor,
      foreground: homeModel.foregroundColor,
      boxSize: boxSize,
      item: SharedItems(context).menuBarrier,
      fakeBorders: false,
      extendLeft: true,
      child: (box) {
        return Container(
          // color: Colors.red,
          child: GestureDetector(
            onTap: homeModel.toggleMenu,
          ),
        );
      },
    );
  }
}
