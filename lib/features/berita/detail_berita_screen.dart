import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/news_article.dart';
import '../../data/repositories/news_repository.dart';
import '../../shared/layouts/app_page.dart';
import 'berita_screen.dart';

class DetailBeritaScreen extends StatelessWidget {
  const DetailBeritaScreen({
    super.key,
    required this.newsRepository,
    required this.arguments,
  });

  final NewsRepository newsRepository;
  final NewsRouteArguments arguments;

  @override
  Widget build(BuildContext context) {
    final NewsArticle article = arguments.article;

    return AppPage(
      title: 'Detail Berita',
      description:
          'Baca ringkasan berita terlebih dahulu sebelum melihat analisis dampaknya.',
      children: <Widget>[
        Text(
          article.title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${article.source} - ${DateFormatter.formatDateTime(article.publishedAt)} - ${article.category}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            article.summary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (article.url.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Link sumber',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                SelectableText(
                  article.url,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () {
            context.push(
              RouteConstants.beritaAnalisis,
              extra: NewsRouteArguments(article: article),
            );
          },
          child: const Text('Analisis Dampak'),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'MoneyPilot tidak memberi rekomendasi beli atau jual. Analisis ditampilkan untuk membantu belajar dan memahami konteks berita.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
