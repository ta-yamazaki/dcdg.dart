import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor2.dart';

/// A visitor that collects all class elements defined within
/// a particular library.
///
/// The visitor can optionally limit the classes collected to those that
/// are exported from the library. This means that they are public,
/// and are either not subject to any `show` or `hide` clause, are
/// included in a `show` clause, or are not included in a `hide` clause.
class ClassElementCollector extends RecursiveElementVisitor2<void> {
  final List<ClassElement> _classElements = [];

  final bool _exportOnly;

  ClassElementCollector({
    bool exportedOnly = false,
  }) : _exportOnly = exportedOnly;

  Iterable<ClassElement> get classElements => _classElements;

  @override
  void visitClassElement(ClassElement element) {
    _classElements.add(element);
  }

  @override
  void visitLibraryElement(LibraryElement element) {
    element.visitChildren(this);

    if (!_exportOnly) {
      return;
    }

    for (final export in element.firstFragment.libraryExports) {
      final hiddenNames = <String>{};
      final shownNames = <String>{};

      for (final combinator in export.combinators) {
        if (combinator is HideElementCombinator) {
          hiddenNames.addAll(combinator.hiddenNames);
        }

        if (combinator is ShowElementCombinator) {
          shownNames.addAll(combinator.shownNames);
        }
      }

      final collector = ClassElementCollector(
        exportedOnly: _exportOnly,
      );
      export.exportedLibrary?.accept(collector);

      bool shouldInclude(ClassElement element) {
        if (shownNames.isEmpty && hiddenNames.isEmpty) {
          return true;
        }

        final shouldShow =
            shownNames.isNotEmpty && shownNames.contains(element.name);
        final shouldHide =
            hiddenNames.isNotEmpty && hiddenNames.contains(element.name);
        return _exportOnly ? (shouldShow && !shouldHide) : true;
      }

      collector.classElements.where(shouldInclude).forEach(visitClassElement);
    }
  }
}
