import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/news_impact_analysis.dart';
import '../../data/repositories/news_repository.dart';
import '../../shared/layouts/app_page.dart';
import 'berita_screen.dart';

class AnalisisBeritaScreen extends StatefulWidget {
  const AnalisisBeritaScreen({
    super.key,
    required this.newsRepository,
    required this.arguments,
  });

  final NewsRepository newsRepository;
  final NewsRouteArguments arguments;

  @override
  State<AnalisisBeritaScreen> createState() => _AnalisisBeritaScreenState();
}

class _AnalisisBeritaScreenState extends State<AnalisisBeritaScreen> {
  late Future<NewsImpactAnalysis> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Analisis Berita',
      description:
          'Analisis ini bersifat edukatif, menggunakan bahasa probabilistik, dan tetap perlu dibaca dengan hati-hati.',
      children: <Widget>[
        FutureBuilder<NewsImpactAnalysis>(
          future: _future,
          builder:
              (
                BuildContext context,
                AsyncSnapshot<NewsImpactAnalysis> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _AnalysisMessage(
                    title: 'Sedang menyusun analisis berbasis data...',
                    description:
                        'MoneyPilot sedang merangkum dampak potensial berita ini dengan gaya yang lebih aman untuk pemula.',
                  );
                }

                if (snapshot.hasError) {
                  final String message = snapshot.error is AppException
                      ? (snapshot.error as AppException).message
                      : 'Analisis belum bisa dibuat sekarang. Coba lagi nanti.';
                  return _AnalysisError(message: message, onRetry: _retry);
                }

                final NewsImpactAnalysis analysis = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _MetadataBanner(analysis: analysis),
                    const SizedBox(height: AppSpacing.lg),
                    _ScoreRow(analysis: analysis),
                    const SizedBox(height: AppSpacing.lg),
                    _Section(
                      title: 'Dampak Potensial',
                      content: Text(analysis.dampakPotensial),
                    ),
                    _Section(
                      title: 'Aset Terdampak',
                      content: _StringList(values: analysis.asetTerdampak),
                    ),
                    _Section(
                      title: 'Rantai Sebab-Akibat',
                      content: _StringList(values: analysis.rantaiSebabAkibat),
                    ),
                    _Section(
                      title: 'Data Pendukung',
                      content: _StringList(values: analysis.dataPendukung),
                    ),
                    _Section(
                      title: 'Skenario Positif',
                      content: Text(analysis.skenarioPositif),
                    ),
                    _Section(
                      title: 'Skenario Negatif',
                      content: Text(analysis.skenarioNegatif),
                    ),
                    _Section(
                      title: 'Hal yang Perlu Dipantau',
                      content: _StringList(
                        values: analysis.halYangPerluDipantau,
                      ),
                    ),
                    _Section(
                      title: 'Kesimpulan untuk Pemula',
                      content: Text(analysis.kesimpulanPemula),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        analysis.disclaimer,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
        ),
      ],
    );
  }

  Future<NewsImpactAnalysis> _loadAnalysis() {
    return widget.newsRepository.analyzeNews(widget.arguments.article);
  }

  void _retry() {
    setState(() {
      _future = _loadAnalysis();
    });
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.analysis});

  final NewsImpactAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ScoreCard(
            label: 'Skor Dampak',
            value: '${analysis.impactScore}/100',
            tone: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ScoreCard(
            label: 'Skor Keyakinan',
            value: '${analysis.confidenceScore}/100',
            tone: analysis.confidenceScore >= 60
                ? AppColors.success
                : AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: tone,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content});

  final String title;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            child: content,
          ),
        ],
      ),
    );
  }
}

class _StringList extends StatelessWidget {
  const _StringList({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: values
          .map(
            (String value) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text('- $value'),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _AnalysisMessage extends StatelessWidget {
  const _AnalysisMessage({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AnalysisError extends StatelessWidget {
  const _AnalysisError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Analisis belum tersedia',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}


class _MetadataBanner extends StatelessWidget {
  const _MetadataBanner({required this.analysis});

  final NewsImpactAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final List<Widget> badges = <Widget>[];

    if (analysis.isCached) {
      badges.add(const _Badge(label: 'Dari Cache', color: AppColors.textSecondary));
    }

    if (analysis.isFallback) {
      badges.add(const _Badge(label: 'Analisis Fallback Edukatif', color: AppColors.warning));
    } else if (analysis.isAiGenerated) {
      badges.add(const _Badge(label: 'Dihasilkan oleh AI', color: AppColors.primaryDark));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: badges,
        ),
        if (analysis.isFallback && analysis.fallbackReason != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Catatan sistem: ${analysis.fallbackReason}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}