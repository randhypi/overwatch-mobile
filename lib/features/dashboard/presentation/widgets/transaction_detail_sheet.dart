import 'package:flutter/material.dart';
import '../../domain/entities/transaction_group.dart';
import '../../domain/entities/log_pair.dart';
import '../../../../core/theme/app_colors.dart';

class TransactionDetailSheet extends StatefulWidget {
  final TransactionGroup group;
  final bool isPanel;

  const TransactionDetailSheet({
    super.key,
    required this.group,
    this.isPanel = false,
  });

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();

    // Auto-select tab based on available data?
    // Default to ISO (0) if present, else JSON (1)
    if (widget.group.isoPairs.isEmpty && widget.group.jsonPairs.isNotEmpty) {
      _tabController.index = 1;
      _pageController = PageController(initialPage: 1);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          widget.isPanel
              ? double.infinity
              : MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            widget.isPanel
                ? null
                : const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          if (!widget.isPanel)
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  "Transaction Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    widget.group.refNum,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            onTap:
                (index) => _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
            tabs: [
              _buildTab("ISO 8583", widget.group.isoPairs.isNotEmpty),
              _buildTab("JSON / API", widget.group.jsonPairs.isNotEmpty),
            ],
          ),

          // Page View (Swipeable)
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => _tabController.animateTo(index),
              children: [
                _buildLogList(widget.group.isoPairs, "ISO"),
                _buildLogList(widget.group.jsonPairs, "JSON"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool hasData) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (hasData) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogList(List<LogPair> pairs, String type) {
    if (pairs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              "No $type Data Found",
              style: TextStyle(color: Colors.grey.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pairs.length,
      itemBuilder: (context, index) {
        final pair = pairs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Log #${index + 1}",
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),

              // Request Block
              _buildCodeBlock("Request", pair.request.content),
              const SizedBox(height: 12),

              // Response Block
              if (pair.response != null)
                _buildCodeBlock("Response", pair.response!.content)
              else
                _buildCodeBlock(
                  "Response",
                  "Waiting for response...",
                  isWaiting: true,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCodeBlock(
    String label,
    String content, {
    bool isWaiting = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E222A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.copy,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              content,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: isWaiting ? Colors.grey : AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
