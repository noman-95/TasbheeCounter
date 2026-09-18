import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];

  bool isLoading = true;
  bool isClearing = false;

  static const Color primaryGreen = Color(0xFF087F5B);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final savedHistory = await StorageService.getHistory();

    if (!mounted) return;

    setState(() {
      history = List<Map<String, dynamic>>.from(
        savedHistory.reversed,
      );
      isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    if (history.isEmpty || isClearing) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clear History',
          ),
          content: const Text(
            'Are you sure you want to delete all history?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete All',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      isClearing = true;
    });

    try {
      await StorageService.clearHistory();

      if (!mounted) return;

      setState(() {
        history.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'History cleared successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isClearing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              onPressed:
                  isClearing ? null : _clearHistory,
              icon: isClearing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,
                    ),
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            )
          : history.isEmpty
              ? _emptyHistory()
              : RefreshIndicator(
                  color: primaryGreen,
                  onRefresh: _loadHistory,
                  child: _historyList(),
                ),
    );
  }

  Widget _emptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 85,
              color: primaryGreen.withOpacity(0.65),
            ),
            const SizedBox(height: 20),
            const Text(
              'No History Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Complete a Zikr target and your history '
              'will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyList() {
    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];

        final date =
            item['date']?.toString() ?? '';

        final zikrName =
            item['zikrName']?.toString() ?? '';

        final count = item['count'] is num
            ? (item['count'] as num).toInt()
            : int.tryParse(
                  item['count']?.toString() ?? '',
                ) ??
                0;

        return Card(
          margin:
              const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration:
                      BoxDecoration(
                    color:
                        primaryGreen.withOpacity(
                      0.10,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color:
                        primaryGreen,
                    size: 29,
                  ),
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        zikrName.isEmpty
                            ? 'Zikr'
                            : zikrName,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons
                                .calendar_today_rounded,
                            size: 14,
                            color:
                                Colors.grey,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            date,
                            style:
                                const TextStyle(
                              fontSize:
                                  13,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  children: [
                    Text(
                      '$count',
                      style:
                          const TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            primaryGreen,
                      ),
                    ),
                    const Text(
                      'times',
                      style:
                          TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}