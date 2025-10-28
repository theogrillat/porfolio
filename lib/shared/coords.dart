import 'package:flutter/widgets.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/utils.dart';

enum Target { desktop, mobile }

class BoxItem {
  PlatformPosition position;
  int order;

  BoxItem({
    required this.position,
    required this.order,
  });
}

class PlatformPosition {
  BoxPosition postition;
  BoxPosition? fullscreen;
  Target target;

  bool get hasFullscreen => fullscreen != null;

  PlatformPosition({
    required this.postition,
    this.fullscreen,
    required this.target,
  });
}

abstract class Items {
  BuildContext context;
  Items(this.context);

  bool get portait => isPortrait(context);

  BoxItem buildItem(
    int order, {
    required PlatformPosition desktop,
    required PlatformPosition mobile,
  }) {
    return BoxItem(
      position: portait ? mobile : desktop,
      order: order,
    );
  }
}

class SharedItems extends Items {
  SharedItems(super.context);

  BoxItem get menu {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(5, 0),
        end: Coords(6, 3),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(1, 0),
        end: Coords(3, 6),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get menuBarrier {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 0),
        end: Coords(4, 3),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 0),
        end: Coords(0, 6),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }
}

class LandingItems extends Items {
  LandingItems(super.context);

  BoxItem get semiCircle {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 0),
        end: Coords(0, 1),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 0),
        end: Coords(0, 1),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get projectButton {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(2, 0),
        end: Coords(2, 0),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(2, 5),
        end: Coords(2, 5),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get grillat {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(1, 1),
        end: Coords(5, 1),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 4),
        end: Coords(3, 4),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get theo {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(4, 2),
        end: Coords(6, 2),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(1, 3),
        end: Coords(3, 3),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get rotatingTriangle {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(6, 0),
        end: Coords(6, 0),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(3, 0),
        end: Coords(3, 0),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get aboutButton {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(3, 2),
        end: Coords(3, 2),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(1, 2),
        end: Coords(1, 2),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get wideTriangle {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 3),
        end: Coords(1, 3),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(2, 6),
        end: Coords(3, 6),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get contactButton {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(5, 3),
        end: Coords(5, 3),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 6),
        end: Coords(0, 6),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }
}

class ProjectItems extends Items {
  ProjectItems(super.context);

  BoxItem get stack {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(2, 0),
        end: Coords(3, 1),
      ),
      fullscreen: BoxPosition(
        start: Coords(1, 0),
        end: Coords(5, 3),
      ),
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 3),
        end: Coords(1, 4),
      ),
      fullscreen: BoxPosition(
        start: Coords(0, 1),
        end: Coords(3, 5),
      ),
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get description {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(3, 2),
        end: Coords(5, 3),
      ),
      fullscreen: BoxPosition(
        start: Coords(1, 0),
        end: Coords(5, 3),
      ),
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 1),
        end: Coords(3, 2),
      ),
      fullscreen: BoxPosition(
        start: Coords(0, 0),
        end: Coords(3, 6),
      ),
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get title {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(4, 0),
        end: Coords(6, 0),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(1, 0),
        end: Coords(3, 0),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get previousButton {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(2, 3),
        end: Coords(2, 3),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(2, 4),
        end: Coords(2, 4),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get nextButton {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(6, 2),
        end: Coords(6, 2),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(3, 3),
        end: Coords(3, 3),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get homeButton {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(4, 1),
        end: Coords(4, 1),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 0),
        end: Coords(0, 0),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem screenshot(int index, List<bool> isLandscape) {
    assert(isLandscape.length == 4, 'Must have exactly 4 screenshots');

    int landscapeCount = isLandscape.where((l) => l).length;
    assert(landscapeCount == 0 || landscapeCount == 2 || landscapeCount == 4,
        'Must have 0, 2, or 4 landscape screenshots');

    Coords desktopStart;
    Coords desktopEnd;
    Coords mobileStart;
    Coords mobileEnd;

    if (landscapeCount == 0) {
      // All portrait
      // Desktop (2×4): each takes 1 column × 2 rows, arranged in 2 columns
      int col = index % 2;
      int rowStart = (index ~/ 2) * 2;
      desktopStart = Coords(col, rowStart);
      desktopEnd = Coords(col, rowStart + 1);

      // Mobile (4×2): each takes 1 column × 2 rows, arranged in 4 columns
      mobileStart = Coords(index, 5);
      mobileEnd = Coords(index, 6);

    } else if (landscapeCount == 4) {
      // All landscape
      // Desktop (2×4): each takes 2 columns × 1 row, stacked vertically
      desktopStart = Coords(0, index);
      desktopEnd = Coords(1, index);

      // Mobile (4×2): each takes 2 columns × 1 row, arranged 2 per row
      int row = 5 + (index ~/ 2);
      int colStart = (index % 2) * 2;
      mobileStart = Coords(colStart, row);
      mobileEnd = Coords(colStart + 1, row);

    } else {
      // Mix of 2 landscape + 2 portrait
      List<int> landscapeIndices = [];
      List<int> portraitIndices = [];

      for (int i = 0; i < 4; i++) {
        if (isLandscape[i]) {
          landscapeIndices.add(i);
        } else {
          portraitIndices.add(i);
        }
      }

      if (landscapeIndices.contains(index)) {
        int landscapePosition = landscapeIndices.indexOf(index);

        // Desktop: Landscape takes 2 columns × 1 row, stacked at top
        desktopStart = Coords(0, landscapePosition);
        desktopEnd = Coords(1, landscapePosition);

        // Mobile: Landscape takes 2 columns × 1 row, positioned on right
        mobileStart = Coords(2, 5 + landscapePosition);
        mobileEnd = Coords(3, 5 + landscapePosition);

      } else {
        int portraitPosition = portraitIndices.indexOf(index);

        // Desktop: Portrait takes 1 column × 2 rows, positioned below landscapes
        desktopStart = Coords(portraitPosition, 2);
        desktopEnd = Coords(portraitPosition, 3);

        // Mobile: Portrait takes 1 column × 2 rows, positioned on left
        mobileStart = Coords(portraitPosition, 5);
        mobileEnd = Coords(portraitPosition, 6);
      }
    }

    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: desktopStart,
        end: desktopEnd,
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: mobileStart,
        end: mobileEnd,
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(
      index + 7,
      desktop: desktop,
      mobile: mobile,
    );
  }

}

class AboutItems extends Items {
  AboutItems(super.context);

  BoxItem get avatar {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 0),
        end: Coords(1, 1),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 0),
        end: Coords(1, 1),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get theo {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 3),
        end: Coords(2, 3),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 2),
        end: Coords(2, 2),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get homeButton {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(6, 0),
        end: Coords(6, 0),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(3, 1),
        end: Coords(3, 1),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get skillsButton {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(5, 1),
        end: Coords(5, 1),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(2, 5),
        end: Coords(2, 5),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get wideTriangle {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(3, 3),
        end: Coords(4, 3),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(2, 6),
        end: Coords(3, 6),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get rotatingTriangle {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 2),
        end: Coords(0, 2),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(2, 0),
        end: Coords(2, 0),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get bio {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(2, 0),
        end: Coords(4, 2),
      ),
      fullscreen: BoxPosition(
        start: Coords(1, 0),
        end: Coords(5, 3),
      ),
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 3),
        end: Coords(3, 4),
      ),
      fullscreen: BoxPosition(
        start: Coords(0, 0),
        end: Coords(3, 6),
      ),
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get skills {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(5, 2),
        end: Coords(6, 3),
      ),
      fullscreen: BoxPosition(
        start: Coords(1, 0),
        end: Coords(5, 3),
      ),
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 5),
        end: Coords(1, 6),
      ),
      fullscreen: BoxPosition(
        start: Coords(0, 1),
        end: Coords(3, 5),
      ),
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }
}

class SkillsItems extends Items {
  SkillsItems(super.context);

  BoxItem get backButton {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 3),
        end: Coords(0, 3),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 6),
        end: Coords(0, 6),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get title {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 0),
        end: Coords(6, 0),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 0),
        end: Coords(3, 0),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get cloud {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(2, 1),
        end: Coords(6, 3),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 1),
        end: Coords(3, 5),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }
}

class ContactItems extends Items {
  ContactItems(super.context);

  BoxItem get title {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 0),
        end: Coords(2, 0),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 0),
        end: Coords(2, 0),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get homeBtn {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(6, 2),
        end: Coords(6, 2),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(3, 0),
        end: Coords(3, 0),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get email {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(3, 0),
        end: Coords(6, 0),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(1, 1),
        end: Coords(3, 1),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get smallTriangle {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 1),
        end: Coords(0, 1),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(1, 3),
        end: Coords(1, 3),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get firstName {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(1, 1),
        end: Coords(3, 1),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 2),
        end: Coords(1, 2),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get lastName {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(4, 1),
        end: Coords(6, 1),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(2, 3),
        end: Coords(3, 3),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get message {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 2),
        end: Coords(4, 3),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 4),
        end: Coords(2, 5),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  BoxItem get sendBtn {
    PlatformPosition desktop = PlatformPosition(
      postition: BoxPosition(
        start: Coords(5, 3),
        end: Coords(5, 3),
      ),
      fullscreen: null,
      target: Target.desktop,
    );

    PlatformPosition mobile = PlatformPosition(
      postition: BoxPosition(
        start: Coords(0, 6),
        end: Coords(0, 6),
      ),
      fullscreen: null,
      target: Target.mobile,
    );

    return buildItem(1, desktop: desktop, mobile: mobile);
  }

  // BoxItem get wideTriangle {
  //   PlatformPosition desktop = PlatformPosition(
  //     postition: BoxPosition(
  //       start: Coords(5, 3),
  //       end: Coords(6, 3),
  //     ),
  //     fullscreen: null,
  //     target: Target.desktop,
  //   );

  //   PlatformPosition mobile = PlatformPosition(
  //     postition: BoxPosition(
  //       start: Coords(0, 0),
  //       end: Coords(0, 0),
  //     ),
  //     fullscreen: null,
  //     target: Target.mobile,
  //   );

  //   return buildItem(1, desktop: desktop, mobile: mobile);
  // }
}
