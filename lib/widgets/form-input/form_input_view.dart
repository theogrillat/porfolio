import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/widgets/bool-insert/bool_insert_view.dart';
import 'package:stacked/stacked.dart';
import 'form_input_viewmodel.dart';

class FormInputView extends StatelessWidget {
  const FormInputView({
    required this.box,
    required this.controller,
    required this.label,
    this.isTextAera = false,
    super.key,
  });

  final Box box;
  final TextEditingController controller;
  final String label;
  final bool isTextAera;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<FormInputViewModel>.reactive(
      viewModelBuilder: () => FormInputViewModel(),
      onViewModelReady: (model) {
        model.onInit();
        model.setContext(context);
      },
      onDispose: (model) => model.onDispose(),
      builder: (context, model, child) {
        return SizedBox(
          width: box.boxSize * box.position.width,
          height: box.boxSize * box.position.height,
          child: Theme(
            data: Theme.of(context).copyWith(
              scrollbarTheme: ScrollbarThemeData(
                thumbVisibility: WidgetStateProperty.all(true),
                trackVisibility: WidgetStateProperty.all(false),
                thickness: WidgetStateProperty.all(10.0),
                radius: const Radius.circular(0.0),
                thumbColor: WidgetStateProperty.all(box.foreground),
                trackColor: WidgetStateProperty.all(box.background),
                trackBorderColor: WidgetStateProperty.all(box.background),
                crossAxisMargin: 0,
                mainAxisMargin: 0,
                interactive: true,
              ),
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.text,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubicEmphasized,
                    alignment: model.isFocused || controller.value.text.isNotEmpty ? Alignment.bottomLeft : Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                      child: Opacity(
                        opacity: 0.15,
                        child: Text(
                          label,
                          style: Typos(context).large(color: box.foreground).copyWith(fontSize: box.boxSize * 0.13),
                        ),
                      ),
                    ),
                  ),
                  BoolInsertView(
                    insert: isTextAera,
                    widget: (child) {
                      ScrollController controller = ScrollController();
                      return Scrollbar(
                        thickness: 25,
                        interactive: true,
                        controller: controller,
                        child: SingleChildScrollView(
                          controller: controller,
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: CupertinoTextField(
                      controller: controller,
                      focusNode: model.focusNode,
                      padding: const EdgeInsets.all(0.0),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                      cursorColor: box.foreground,
                      textAlignVertical: isTextAera ? TextAlignVertical.top : TextAlignVertical.center,
                      textAlign: isTextAera ? TextAlign.start : TextAlign.center,
                      maxLines: isTextAera ? 120 : 1,
                      style: Typos(context).large(color: box.foreground).copyWith(
                            fontSize: box.boxSize * (isTextAera ? 0.1 : 0.2),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
