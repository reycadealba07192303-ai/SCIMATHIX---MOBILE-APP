# Icon Convention

SCIMATHIX uses **two icon libraries only**:

1. **Cupertino Icons** (`package:flutter/cupertino.dart` → `CupertinoIcons`) — the primary icon set for the iOS-style UI.
2. **Fluent UI System Icons** (`package:fluentui_system_icons/fluentui_system_icons.dart` → `FluentIcons`) — for icons not available in Cupertino, or where a richer/filled glyph is needed.

## Rules

- Prefer `CupertinoIcons` for common UI glyphs (back arrows, chevrons, bell, person, search, etc.).
- Use `FluentIcons` when Cupertino lacks a suitable glyph (e.g. specialized education, analytics, or filled status icons). Fluent icon names follow the pattern `FluentIcons.<name>_<size>_<style>`, e.g. `FluentIcons.book_24_filled`, `FluentIcons.trophy_24_regular`.
- Do NOT introduce new icon packages. `font_awesome_flutter` and `Icons` (Material) are legacy — do not add new usages; migrate to Cupertino or Fluent when touching a screen.
- Material `Icons.*` are acceptable only where already present and not worth churning; new code should use Cupertino or Fluent.

## Import

```dart
import 'package:flutter/cupertino.dart';                       // CupertinoIcons
import 'package:fluentui_system_icons/fluentui_system_icons.dart'; // FluentIcons
```

## Sizing/style

Fluent icons come in 12/16/20/24/28/32/48 sizes and `regular`/`filled` styles. Default to `_24_regular` for inline icons and `_24_filled` for selected/active states.
