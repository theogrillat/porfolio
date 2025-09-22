import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:async';
import 'dart:math';

enum RevealDirection {
  start,
  end,
  center,
}

enum AnimateOn {
  view,
  hover,
}

class DecryptedText extends StatefulWidget {
  final String text;
  final int speed;
  final int maxIterations;
  final bool sequential;
  final RevealDirection revealDirection;
  final bool useOriginalCharsOnly;
  final String characters;
  final TextStyle? textStyle;
  final TextStyle? encryptedTextStyle;
  final AnimateOn animateOn;

  const DecryptedText({
    Key? key,
    required this.text,
    this.speed = 50,
    this.maxIterations = 10,
    this.sequential = false,
    this.revealDirection = RevealDirection.start,
    this.useOriginalCharsOnly = false,
    this.characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#\$%^&*()_+',
    this.textStyle,
    this.encryptedTextStyle,
    this.animateOn = AnimateOn.hover,
  }) : super(key: key);

  @override
  State<DecryptedText> createState() => _DecryptedTextState();
}

class _DecryptedTextState extends State<DecryptedText> {
  late List<String> lines;
  late List<String> displayLines;
  bool isHovering = false;
  bool isScrambling = false;
  late List<Set<int>> revealedIndicesPerLine;
  bool hasAnimated = false;
  Timer? animationTimer;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    lines = widget.text.split('\n');
    displayLines = List.from(lines);
    revealedIndicesPerLine = List.generate(lines.length, (index) => <int>{});
    print('DecryptedText initialized with ${lines.length} lines');
  }

  @override
  void dispose() {
    animationTimer?.cancel();
    super.dispose();
  }

  int getNextIndex(Set<int> revealedSet, int lineLength) {
    switch (widget.revealDirection) {
      case RevealDirection.start:
        return revealedSet.length;
      case RevealDirection.end:
        return lineLength - 1 - revealedSet.length;
      case RevealDirection.center:
        final middle = lineLength ~/ 2;
        final offset = revealedSet.length ~/ 2;
        final nextIndex = revealedSet.length % 2 == 0 ? middle + offset : middle - offset - 1;

        if (nextIndex >= 0 && nextIndex < lineLength && !revealedSet.contains(nextIndex)) {
          return nextIndex;
        }

        for (int i = 0; i < lineLength; i++) {
          if (!revealedSet.contains(i)) return i;
        }
        return 0;
    }
  }

  List<String> getAvailableChars() {
    if (widget.useOriginalCharsOnly) {
      return widget.text.split('').where((char) => char != ' ').toSet().toList();
    } else {
      return widget.characters.split('');
    }
  }

  String shuffleLine(String originalLine, Set<int> currentRevealed) {
    final availableChars = getAvailableChars();
    return originalLine.split('').asMap().entries.map((entry) {
      final index = entry.key;
      final char = entry.value;

      // Keep spaces as they are
      if (char == ' ') return ' ';

      // If this character is already revealed, show the original
      if (currentRevealed.contains(index)) return originalLine[index];

      // Otherwise, show a random character
      return availableChars[random.nextInt(availableChars.length)];
    }).join('');
  }

  void startAnimation() {
    print('Starting animation - isHovering: $isHovering');
    animationTimer?.cancel();

    if (!isHovering) {
      setState(() {
        displayLines = List.from(lines);
        for (var revealedSet in revealedIndicesPerLine) {
          revealedSet.clear();
        }
        isScrambling = false;
      });
      print('Animation stopped - showing original text');
      return;
    }

    // Clear all revealed indices and start scrambling immediately
    setState(() {
      for (var revealedSet in revealedIndicesPerLine) {
        revealedSet.clear();
      }
      isScrambling = true;
      // Start with scrambled text immediately for all lines
      for (int i = 0; i < lines.length; i++) {
        displayLines[i] = shuffleLine(lines[i], revealedIndicesPerLine[i]);
      }
    });
    print('Animation started - scrambling: $isScrambling');

    int currentIteration = 0;

    animationTimer = Timer.periodic(Duration(milliseconds: widget.speed), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (widget.sequential) {
          bool allLinesComplete = true;

          // Process each line independently
          for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
            final line = lines[lineIndex];
            final revealedIndices = revealedIndicesPerLine[lineIndex];

            if (revealedIndices.length < line.length) {
              allLinesComplete = false;
              final nextIndex = getNextIndex(revealedIndices, line.length);
              if (nextIndex >= 0 && nextIndex < line.length) {
                revealedIndices.add(nextIndex);
                print('Line $lineIndex: Revealed character at index $nextIndex: "${line[nextIndex]}"');
              }
              // Keep scrambling unrevealed characters in this line
              displayLines[lineIndex] = shuffleLine(line, revealedIndices);
            } else {
              // This line is complete, show original
              displayLines[lineIndex] = line;
            }
          }

          if (allLinesComplete) {
            timer.cancel();
            isScrambling = false;
            print('Animation complete - all lines revealed');
          }
        } else {
          // Non-sequential mode: scramble all characters for maxIterations
          for (int i = 0; i < lines.length; i++) {
            displayLines[i] = shuffleLine(lines[i], revealedIndicesPerLine[i]);
          }
          currentIteration++;
          if (currentIteration >= widget.maxIterations) {
            timer.cancel();
            isScrambling = false;
            displayLines = List.from(lines);
            print('Animation complete - max iterations reached');
          }
        }
      });
    });
  }

  void onHoverChange(bool hovering) {
    if (isHovering == hovering) return;

    print('Hover changed: $hovering');
    setState(() {
      isHovering = hovering;
    });

    startAnimation();
  }

  void onVisibilityChanged(VisibilityInfo info) {
    if (widget.animateOn == AnimateOn.view && info.visibleFraction > 0.1 && !hasAnimated) {
      setState(() {
        hasAnimated = true;
        isHovering = true;
      });
      startAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building with ${displayLines.length} lines, scrambling: $isScrambling, hovering: $isHovering');

    Widget textWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: displayLines.asMap().entries.map((lineEntry) {
        final lineIndex = lineEntry.key;
        final displayLine = lineEntry.value;
        final revealedIndices = revealedIndicesPerLine[lineIndex];

        return RichText(
          text: TextSpan(
            children: displayLine.split('').asMap().entries.map((charEntry) {
              final charIndex = charEntry.key;
              final char = charEntry.value;
              final isRevealed = revealedIndices.contains(charIndex);
              final isRevealedOrDone = isRevealed || !isScrambling || !isHovering;

              return TextSpan(
                text: char,
                style: isRevealedOrDone ? (widget.textStyle ?? const TextStyle()) : (widget.encryptedTextStyle ?? const TextStyle()),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );

    // Add hover functionality if needed
    if (widget.animateOn == AnimateOn.hover) {
      textWidget = MouseRegion(
        onEnter: (_) => onHoverChange(true),
        onExit: (_) => onHoverChange(false),
        child: textWidget,
      );
    }

    // Add visibility detection if needed
    if (widget.animateOn == AnimateOn.view) {
      textWidget = VisibilityDetector(
        key: Key('decrypted_text_${widget.text.hashCode}'),
        onVisibilityChanged: onVisibilityChanged,
        child: textWidget,
      );
    }

    return textWidget;
  }
}
