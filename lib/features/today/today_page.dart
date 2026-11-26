import 'package:flutter/material.dart';
import 'package:luma/core/l10n/gen/app_localizations.dart';

/// Placeholder route opened by a notification tap.
///
/// The reader and today's plan day are wired up in a later step.
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  static const routeName = '/today';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.todayTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Text(
            l10n.todayPlaceholder,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
