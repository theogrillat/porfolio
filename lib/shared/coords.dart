import 'package:flutter/widgets.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/utils.dart';

class BoxItem {
  BoxPosition position;
  int order;

  BoxItem({
    required this.position,
    required this.order,
  });
}

abstract class Items {
  BuildContext context;
  Items(this.context);

  bool get portait => isPortrait(context);

  BoxItem buildItem(
    int order,
    Coords desktopStart,
    Coords desktopEnd,
    Coords mobileStart,
    Coords mobileEnd,
  ) {
    return BoxItem(
      position: BoxPosition(
        start: portait ? mobileStart : desktopStart,
        end: portait ? mobileEnd : desktopEnd,
      ),
      order: order,
    );
  }
}

class SharedItems extends Items {
  SharedItems(super.context);

  BoxItem get menu {
    Coords desktopStart = Coords(5, 0);
    Coords desktopEnd = Coords(6, 3);

    Coords mobileStart = Coords(1, 0);
    Coords mobileEnd = Coords(3, 6);

    return buildItem(1, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get menuBarrier {
    Coords desktopStart = Coords(0, 0);
    Coords desktopEnd = Coords(4, 3);

    Coords mobileStart = Coords(0, 0);
    Coords mobileEnd = Coords(0, 6);

    return buildItem(1, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }
}

class LandingItems extends Items {
  LandingItems(super.context);

  BoxItem get semiCircle {
    Coords desktopStart = Coords(0, 0);
    Coords desktopEnd = Coords(0, 1);

    Coords mobileStart = Coords(0, 0);
    Coords mobileEnd = Coords(0, 1);

    return buildItem(1, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get projectButton {
    Coords desktopStart = Coords(2, 0);
    Coords desktopEnd = Coords(2, 0);

    Coords mobileStart = Coords(2, 5);
    Coords mobileEnd = Coords(2, 5);

    return buildItem(2, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get grillat {
    Coords desktopStart = Coords(1, 1);
    Coords desktopEnd = Coords(5, 1);

    Coords mobileStart = Coords(0, 4);
    Coords mobileEnd = Coords(3, 4);

    return buildItem(3, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get theo {
    Coords desktopStart = Coords(4, 2);
    Coords desktopEnd = Coords(6, 2);

    Coords mobileStart = Coords(1, 3);
    Coords mobileEnd = Coords(3, 3);

    return buildItem(4, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get rotatingTriangle {
    Coords desktopStart = Coords(6, 0);
    Coords desktopEnd = Coords(6, 0);

    Coords mobileStart = Coords(3, 0);
    Coords mobileEnd = Coords(3, 0);

    return buildItem(5, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get aboutButton {
    Coords desktopStart = Coords(3, 2);
    Coords desktopEnd = Coords(3, 2);

    Coords mobileStart = Coords(1, 2);
    Coords mobileEnd = Coords(1, 2);

    return buildItem(6, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get wideTriangle {
    Coords desktopStart = Coords(0, 3);
    Coords desktopEnd = Coords(1, 3);

    Coords mobileStart = Coords(2, 6);
    Coords mobileEnd = Coords(3, 6);

    return buildItem(7, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get contactButton {
    Coords desktopStart = Coords(5, 3);
    Coords desktopEnd = Coords(5, 3);

    Coords mobileStart = Coords(0, 6);
    Coords mobileEnd = Coords(0, 6);

    return buildItem(8, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }
}

class ProjectItems extends Items {
  ProjectItems(super.context);

  BoxItem get stack {
    Coords desktopStart = Coords(2, 0);
    Coords desktopEnd = Coords(3, 1);

    Coords mobileStart = Coords(0, 3);
    Coords mobileEnd = Coords(1, 4);

    return buildItem(1, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get description {
    Coords desktopStart = Coords(3, 2);
    Coords desktopEnd = Coords(5, 3);

    Coords mobileStart = Coords(0, 1);
    Coords mobileEnd = Coords(3, 2);

    return buildItem(2, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get title {
    Coords desktopStart = Coords(4, 0);
    Coords desktopEnd = Coords(6, 0);

    Coords mobileStart = Coords(1, 0);
    Coords mobileEnd = Coords(3, 0);

    return buildItem(3, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get previousButton {
    Coords desktopStart = Coords(2, 3);
    Coords desktopEnd = Coords(2, 3);

    Coords mobileStart = Coords(2, 4);
    Coords mobileEnd = Coords(2, 4);

    return buildItem(4, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get nextButton {
    Coords desktopStart = Coords(6, 2);
    Coords desktopEnd = Coords(6, 2);

    Coords mobileStart = Coords(3, 3);
    Coords mobileEnd = Coords(3, 3);

    return buildItem(5, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get homeButton {
    Coords desktopStart = Coords(4, 1);
    Coords desktopEnd = Coords(4, 1);

    Coords mobileStart = Coords(0, 0);
    Coords mobileEnd = Coords(0, 0);

    return buildItem(6, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem screenshot(int index) {
    Coords? desktopStart;
    Coords? desktopEnd;

    if (index <= 1) {
      desktopStart = Coords(0 + index, 0);
      desktopEnd = Coords(0 + index, 1);
    } else {
      desktopStart = Coords(index - 2, 2);
      desktopEnd = Coords(index - 2, 3);
    }

    Coords mobileStart = Coords(0 + index, 5);
    Coords mobileEnd = Coords(0 + index, 6);

    return buildItem(
      index + 7,
      desktopStart,
      desktopEnd,
      mobileStart,
      mobileEnd,
    );
  }
}

class AboutItems extends Items {
  AboutItems(super.context);

  BoxItem get avatar {
    Coords desktopStart = Coords(0, 0);
    Coords desktopEnd = Coords(1, 1);

    Coords mobileStart = Coords(0, 0);
    Coords mobileEnd = Coords(1, 1);

    return buildItem(1, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get theo {
    Coords desktopStart = Coords(0, 3);
    Coords desktopEnd = Coords(2, 3);

    Coords mobileStart = Coords(0, 2);
    Coords mobileEnd = Coords(2, 2);

    return buildItem(2, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get homeButton {
    Coords desktopStart = Coords(6, 0);
    Coords desktopEnd = Coords(6, 0);

    Coords mobileStart = Coords(3, 1);
    Coords mobileEnd = Coords(3, 1);

    return buildItem(3, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get skillsButton {
    Coords desktopStart = Coords(5, 1);
    Coords desktopEnd = Coords(5, 1);

    Coords mobileStart = Coords(2, 5);
    Coords mobileEnd = Coords(2, 5);

    return buildItem(4, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get wideTriangle {
    Coords desktopStart = Coords(3, 3);
    Coords desktopEnd = Coords(4, 3);

    Coords mobileStart = Coords(2, 6);
    Coords mobileEnd = Coords(3, 6);

    return buildItem(5, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get rotatingTriangle {
    Coords desktopStart = Coords(0, 2);
    Coords desktopEnd = Coords(0, 2);

    Coords mobileStart = Coords(2, 0);
    Coords mobileEnd = Coords(2, 0);

    return buildItem(6, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get bio {
    Coords desktopStart = Coords(2, 0);
    Coords desktopEnd = Coords(4, 2);

    Coords mobileStart = Coords(0, 3);
    Coords mobileEnd = Coords(3, 4);

    return buildItem(7, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get skills {
    Coords desktopStart = Coords(5, 2);
    Coords desktopEnd = Coords(6, 3);

    Coords mobileStart = Coords(0, 5);
    Coords mobileEnd = Coords(1, 6);

    return buildItem(8, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }
}

class SkillsItems extends Items {
  SkillsItems(super.context);

  BoxItem get backButton {
    Coords desktopStart = Coords(0, 3);
    Coords desktopEnd = Coords(0, 3);

    Coords mobileStart = Coords(0, 6);
    Coords mobileEnd = Coords(0, 6);

    return buildItem(1, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get title {
    Coords desktopStart = Coords(0, 0);
    Coords desktopEnd = Coords(6, 0);

    Coords mobileStart = Coords(0, 0);
    Coords mobileEnd = Coords(3, 0);

    return buildItem(2, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }

  BoxItem get cloud {
    Coords desktopStart = Coords(2, 1);
    Coords desktopEnd = Coords(6, 3);

    Coords mobileStart = Coords(0, 1);
    Coords mobileEnd = Coords(3, 5);

    return buildItem(3, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }
}

class ContactItems extends Items {
  ContactItems(super.context);

  BoxItem get sphere {
    Coords desktopStart = Coords(2, 0);
    Coords desktopEnd = Coords(4, 2);

    Coords mobileStart = Coords(0, 0);
    Coords mobileEnd = Coords(1, 1);

    return buildItem(1, desktopStart, desktopEnd, mobileStart, mobileEnd);
  }
}
