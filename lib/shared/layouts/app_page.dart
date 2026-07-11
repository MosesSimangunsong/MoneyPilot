import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../widgets/app_section_header.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.children,
    this.description,
    this.actions,
    this.floatingActionButton,
    this.header,
    this.padding,
    this.scrollable = true,
  });

  final String title;
  final String? description;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? header;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final String? trimmedDescription = description?.trim();
    final List<Widget> content = <Widget>[
      header ??
          AppSectionHeader(
            title: title,
            subtitle: trimmedDescription?.isNotEmpty == true
                ? trimmedDescription
                : null,
          ),
      const SizedBox(height: AppSpacing.xl),
      ...children,
    ];

    return Scaffold(
      appBar: AppBar(actions: actions),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: scrollable
            ? ListView(
                padding:
                    padding ??
                    const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.lg,
                      AppSpacing.screenHorizontal,
                      AppSpacing.xxxl,
                    ),
                children: content,
              )
            : Padding(
                padding:
                    padding ??
                    const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.lg,
                      AppSpacing.screenHorizontal,
                      AppSpacing.xxxl,
                    ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content,
                ),
              ),
      ),
    );
  }
}
