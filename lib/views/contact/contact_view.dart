import 'package:flutter/material.dart';
import 'package:portfolio/shared/coords.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:portfolio/widgets/animated_skew.dart';
import 'package:portfolio/widgets/boxbutton.dart';
import 'package:portfolio/widgets/form-input/form_input_view.dart';
import 'package:portfolio/widgets/pressure/pressure_view.dart';
import 'package:rive/rive.dart';
import 'package:stacked/stacked.dart';
import 'contact_viewmodel.dart';

class ContactView extends StatelessWidget {
  const ContactView({
    super.key,
    required this.boxSize,
    required this.goHome,
    required this.homeModel,
  });

  final double boxSize;
  final Function goHome;
  final HomeViewmodel homeModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ContactViewModel>.reactive(
      viewModelBuilder: () => ContactViewModel(),
      onViewModelReady: (model) => model.onInit(),
      onDispose: (model) => model.onDispose(),
      builder: (context, model, child) {
        return Stack(
          children: [
            GridBox(
              show: homeModel.currentGridIndex >= 1,
              boxSize: boxSize,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              item: ContactItems(context).title,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              topPadding: homeModel.topPadding,
              child: (box) {
                int n = 'contact'.length;
                return PressureView(
                  box: box,
                  text: "CONTACT",
                  width: box.boxSize * box.position.width,
                  height: box.boxSize * box.position.height,
                  radius: boxSize * 1.5,
                  minWidth: 10,
                  maxWidth: 150 / n,
                  maxWeight: 600,
                  strength: 1.5,
                  mousePositionStream: homeModel.cursorPositionStream,
                  leftViewportOffset: box.position.getLeftOffsetFromViewport(
                    context: context,
                    boxSize: boxSize,
                  ),
                );
              },
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 2,
              boxSize: boxSize,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              item: ContactItems(context).homeBtn,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              topPadding: homeModel.topPadding,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: () {
                  homeModel.goToHome();
                },
                invert: true,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    width: box.boxSize,
                    scale: 1.5,
                    child: Text(
                      '/home',
                      style: Typos(context).large(color: box.background),
                    ),
                  ),
                ),
              ),
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 3,
              boxSize: boxSize,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              item: ContactItems(context).email,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              topPadding: homeModel.topPadding,
              child: (box) {
                return FormInputView(
                  box: box,
                  label: 'email',
                  controller: model.emailController,
                );
              },
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 4,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              boxSize: boxSize,
              item: ContactItems(context).smallTriangle,
              topPadding: homeModel.topPadding,
              child: (box) => RiveAnimation.asset('assets/triangle.riv'),
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 5,
              boxSize: boxSize,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              item: ContactItems(context).firstName,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              topPadding: homeModel.topPadding,
              child: (box) {
                return FormInputView(
                  box: box,
                  label: 'prénom',
                  controller: model.firstNameController,
                );
              },
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 6,
              boxSize: boxSize,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              item: ContactItems(context).lastName,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              topPadding: homeModel.topPadding,
              child: (box) {
                return FormInputView(
                  box: box,
                  label: 'nom',
                  controller: model.lastNameController,
                );
              },
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 7,
              boxSize: boxSize,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              item: ContactItems(context).message,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              topPadding: homeModel.topPadding,
              child: (box) {
                return FormInputView(
                  box: box,
                  label: 'message',
                  controller: model.messageController,
                  isTextAera: true,
                );
              },
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 8,
              boxSize: boxSize,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              item: ContactItems(context).sendBtn,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              topPadding: homeModel.topPadding,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: () {
                  model.send(homeModel.triggerToast);
                },
                invert: false,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    width: box.boxSize,
                    scale: 1.5,
                    child: Text(
                      '/send',
                      style: Typos(context).large(color: box.background),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
