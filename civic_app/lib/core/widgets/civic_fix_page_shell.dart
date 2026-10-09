import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';
import 'civic_fix_content_container.dart';
import 'civic_fix_page_header.dart';

/// Standardized Page Shell for all CivicFix views.
///
/// Follows Design.md:
/// - Editorial porcelain background (#F8F9FF)
/// - Responsive max-width constraint (1280px default)
/// - Integrated [CivicFixPageHeader] slot
/// - Support for optional scrolling, floating action button, app bar, and drawer
class CivicFixPageShell extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final CivicFixPageHeader? header;
  final bool scrollable;
  final bool containWidth;
  final double maxWidth;
  final EdgeInsetsGeometry? contentPadding;
  final Color? backgroundColor;
  final Key? scaffoldKey;

  const CivicFixPageShell({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.header,
    this.scrollable = false,
    this.containWidth = true,
    this.maxWidth = CivicFixBreakpoints.maxContentWidth,
    this.contentPadding,
    this.backgroundColor,
    this.scaffoldKey,
  });

  /// Shell optimized for single-form workflows (680px max width).
  const CivicFixPageShell.form({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.header,
    this.scrollable = true,
    this.contentPadding,
    this.backgroundColor,
    this.scaffoldKey,
  })  : containWidth = true,
        maxWidth = CivicFixBreakpoints.maxFormWidth;

  /// Shell optimized for full-bleed map displays.
  const CivicFixPageShell.map({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.header,
    this.contentPadding,
    this.backgroundColor,
    this.scaffoldKey,
  })  : containWidth = false,
        maxWidth = double.infinity,
        scrollable = false;

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (header != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header!,
          body,
        ],
      );
    } else {
      content = body;
    }

    if (containWidth) {
      content = CivicFixContentContainer(
        maxWidth: maxWidth,
        padding: contentPadding,
        child: content,
      );
    } else if (contentPadding != null) {
      content = Padding(
        padding: contentPadding!,
        child: content,
      );
    }

    if (scrollable) {
      content = SingleChildScrollView(
        child: content,
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: backgroundColor ?? CivicFixColors.canvas,
      appBar: appBar,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: SafeArea(
        top: appBar == null,
        bottom: bottomNavigationBar == null,
        child: content,
      ),
    );
  }
}
