import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/news_article.dart';
import '../../data/repositories/news_repository.dart';
import '../../shared/layouts/app_page.dart';

class BeritaScreen extends StatefulWidget {
  const BeritaScreen({super.key, required this.newsRepository});

  final NewsRepository newsRepository;

  @override
  State<BeritaScreen> createState() => _BeritaScreenState();
}

class _BeritaScreenState extends State<BeritaScreen> {
  static const List<String> _categories = <String>[
    'Semua',
    'Indonesia',
    'Global',
    'Saham',
    'Forex',
    'Komoditas',
    'Suku Bunga',
    'Geopolitik',
    'IPO',
    'Kripto',
  ];

  late Future<List<NewsArticle>> _future;
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _future = _loadNews();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Berita',
      description:
          'Pantau ringkasan berita finansial terbaru yang relevan untuk keputusan belajarmu.',
      children: <Widget>[
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(width: AppSpacing.sm);
            },
            itemBuilder: (BuildContext context, int index) {
              final String category = _categories[index];
              final bool isSelected = category == _selectedCategory;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) {
                  if (_selectedCategory == category) {
                    return;
                  }
                  setState(() {
                    _selectedCategory = category;
                    _future = _loadNews();
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<List<NewsArticle>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<NewsArticle>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _MessageBox(
                title: 'Sedang mengambil berita terbaru...',
                description:
                    'MoneyPilot sedang menyiapkan daftar berita yang relevan untukmu.',
              );
            }

            if (snapshot.hasError) {
              final String message = snapshot.error is AppException
                  ? (snapshot.error as AppException).message
                  : 'MoneyPilot belum bisa mengambil berita karena koneksi bermasalah.';
              return _RetryBox(
                title: 'Berita belum bisa dimuat',
                description: message,
                onRetry: _refresh,
              );
            }

            final List<NewsArticle> articles = snapshot.data ?? <NewsArticle>[];
            if (articles.isEmpty) {
              return _RetryBox(
                title: 'Berita belum tersedia',
                description:
                    'Coba perbarui beberapa saat lagi atau pilih kategori lain.',
                onRetry: _refresh,
              );
            }

            return Column(
              children: <Widget>[
                for (
                  int index = 0;
                  index < articles.length;
                  index++
                ) ...<Widget>[
                  _NewsTile(
                    article: articles[index],
                    onTap: () => _openDetail(articles[index]),
                  ),
                  if (index < articles.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<List<NewsArticle>> _loadNews() {
    return widget.newsRepository.getNews(
      category: _selectedCategory == 'Semua' ? null : _selectedCategory,
      limit: 12,
    );
  }

  void _refresh() {
    setState(() {
      _future = _loadNews();
    });
  }

  Future<void> _openDetail(NewsArticle article) async {
    await context.push(
      RouteConstants.beritaDetail,
      extra: NewsRouteArguments(article: article),
    );
    if (!mounted) {
      return;
    }
    _refresh();
  }
}

class NewsRouteArguments {
  const NewsRouteArguments({required this.article});

  final NewsArticle article;
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.article, required this.onTap});

  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${article.source} - ${DateFormatter.formatDateTime(article.publishedAt)} - ${article.category}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              article.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.title, required this.description});

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

class _RetryBox extends StatelessWidget {
  const _RetryBox({
    required this.title,
    required this.description,
    required this.onRetry,
  });

  final String title;
  final String description;
  final VoidCallback onRetry;

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
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(onPressed: onRetry, child: const Text('Muat Ulang')),
        ],
      ),
    );
  }
}
