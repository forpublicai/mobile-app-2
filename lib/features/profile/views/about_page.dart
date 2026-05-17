import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/models/server_about_info.dart';
import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/widgets/conduit_components.dart';
import '../widgets/settings_page_scaffold.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(serverAboutInfoProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final serverAboutAsync = ref.watch(serverAboutInfoProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return SettingsPageScaffold(
      title: l10n.aboutApp,
      children: [
        SettingsSectionHeader(title: l10n.appInformation),
        const SizedBox(height: Spacing.sm),
        packageInfoAsync.when(
          data: (info) => _buildAppCard(context, l10n, info),
          loading: () => _buildLoadingCard(context),
          error: (_, _) => _buildMessageCard(context, l10n.unableToLoadAppInfo),
        ),
        settingsSectionGap,
        SettingsSectionHeader(title: l10n.serverInformation),
        const SizedBox(height: Spacing.sm),
        serverAboutAsync.when(
          data: (about) => about == null
              ? _buildMessageCard(context, l10n.serverInfoUnavailable)
              : _buildServerCard(context, l10n, about),
          loading: () => _buildLoadingCard(context),
          error: (_, _) =>
              _buildMessageCard(context, l10n.unableToLoadOpenWebuiSettings),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return const ConduitCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.lg),
        child: Center(child: ConduitLoadingIndicator()),
      ),
    );
  }

  Widget _buildServerCard(
    BuildContext context,
    AppLocalizations l10n,
    ServerAboutInfo about,
  ) {
    return ConduitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutRow(label: l10n.serverNameLabel, value: about.name),
          const SizedBox(height: Spacing.sm),
          _AboutRow(label: l10n.serverVersionLabel, value: about.version),
          if (about.latestVersion != null) ...[
            const SizedBox(height: Spacing.sm),
            _AboutRow(
              label: l10n.latestVersionLabel,
              value: about.latestVersion!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppCard(
    BuildContext context,
    AppLocalizations l10n,
    PackageInfo info,
  ) {
    final versionLabel = info.buildNumber.isEmpty
        ? info.version
        : '${info.version} (${info.buildNumber})';

    return ConduitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutRow(label: l10n.appVersion, value: versionLabel),
        ],
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, String message) {
    return ConduitCard(
      child: Text(
        message,
        style: context.conduitTheme.bodyMedium?.copyWith(
          color: context.conduitTheme.sidebarForeground.withValues(alpha: 0.75),
        ),
      ),
    );
  }

}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: theme.bodySmall?.copyWith(
              color: theme.sidebarForeground.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            value,
            style: theme.bodyMedium?.copyWith(
              color: theme.sidebarForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
