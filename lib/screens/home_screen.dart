import 'quran_practice_screen.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../data/zikr_data.dart';
import '../models/zikr_model.dart';
import '../services/storage_service.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ZikrModel selectedZikr = ZikrData.allZikr.first;

  int count = 0;
  int selectedTarget = 33;
  int todayCount = 0;
  int totalCount = 0;

  bool isLoading = true;

  final List<int> targetOptions = [
    33,
    99,
    100,
    1000,
  ];

  static const Color primaryGreen = Color(0xFF087F5B);
  static const Color lightGreen = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final savedZikrId = await StorageService.getZikr();
    final savedTarget = await StorageService.getTarget();

    ZikrModel savedZikr = ZikrData.allZikr.first;

    if (savedZikrId != null) {
      for (final zikr in ZikrData.allZikr) {
        if (zikr.id == savedZikrId) {
          savedZikr = zikr;
          break;
        }
      }
    }

    final savedCount = await StorageService.getZikrCount(
      savedZikr.id,
    );

    final savedToday = await StorageService.getTodayZikrCount(
      savedZikr.id,
    );

    final savedTotal = await StorageService.getTotal();

    if (!mounted) return;

    setState(() {
      selectedZikr = savedZikr;
      selectedTarget = savedTarget;
      count = savedCount;
      todayCount = savedToday;
      totalCount = savedTotal;
      isLoading = false;
    });
  }

  Future<void> _incrementCount() async {
    if (count >= selectedTarget) {
      return;
    }

    final vibrationEnabled =
        await StorageService.getVibration();

    if (vibrationEnabled) {
      final hasVibrator =
          await Vibration.hasVibrator();

      if (hasVibrator) {
        await Vibration.vibrate(
          duration: 30,
        );
      }
    }

    final newCount = count + 1;

    await StorageService.saveZikrCount(
      selectedZikr.id,
      newCount,
    );

    final newTodayCount =
        await StorageService.addTodayZikr(
      selectedZikr.id,
    );

    final newTotal = totalCount + 1;

    await StorageService.saveTotal(
      newTotal,
    );

    if (!mounted) return;

    setState(() {
      count = newCount;
      todayCount = newTodayCount;
      totalCount = newTotal;
    });

    if (newCount == selectedTarget) {
      final now = DateTime.now();

      final date =
          '${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')}/'
          '${now.year}';

      await StorageService.saveHistory(
        date,
        selectedZikr.name,
        selectedTarget,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Alhamdulillah! Target complete 🎉\n'
            'History saved successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetCount() async {
    await StorageService.resetZikrCount(
      selectedZikr.id,
    );

    if (!mounted) return;

    setState(() {
      count = 0;
    });
  }

  Future<void> _changeZikr(
    ZikrModel zikr,
  ) async {
    final savedCount =
        await StorageService.getZikrCount(
      zikr.id,
    );

    final savedToday =
        await StorageService.getTodayZikrCount(
      zikr.id,
    );

    setState(() {
      selectedZikr = zikr;
      selectedTarget = zikr.defaultTarget;
      count = savedCount;
      todayCount = savedToday;
    });

    await StorageService.saveZikr(
      zikr.id,
    );

    await StorageService.saveTarget(
      zikr.defaultTarget,
    );
  }

  Future<void> _changeTarget(
    int target,
  ) async {
    setState(() {
      selectedTarget = target;
    });

    await StorageService.saveTarget(
      target,
    );
  }

  void _customTargetDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Custom Target',
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter target',
              hintText: 'Example: 500',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
                controller.dispose();
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final value = int.tryParse(
                  controller.text,
                );

                if (value == null || value <= 0) {
                  return;
                }

                setState(() {
                  selectedTarget = value;
                });

                await StorageService.saveTarget(
                  value,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(
                    dialogContext,
                  );
                }

                controller.dispose();
              },
              child: const Text(
                'Set Target',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          isDarkMode: widget.isDarkMode,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );

    await _loadData();
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const HistoryScreen(),
      ),
    );

    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: primaryGreen,
          ),
        ),
      );
    }

    final progress = selectedTarget == 0
        ? 0.0
        : (count / selectedTarget)
            .clamp(0.0, 1.0);

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Tasbih Counter',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openHistory,
            icon: const Icon(
              Icons.history_rounded,
            ),
            tooltip: 'History',
          ),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(
              Icons.settings_rounded,
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            25,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  18,
                  24,
                  18,
                  22,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF18332B)
                      : lightGreen,
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: primaryGreen.withOpacity(
                      0.15,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: primaryGreen,
                      size: 25,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedZikr.arabic,
                      textAlign: TextAlign.center,
                      textDirection:
                          TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 31,
                        height: 1.7,
                        fontWeight:
                            FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(
                                0.18,
                              )
                            : Colors.white.withOpacity(
                                0.75,
                              ),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'ترجمہ',
                            textDirection:
                                TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            selectedZikr.translation,
                            textAlign:
                                TextAlign.center,
                            textDirection:
                                TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 19,
                              height: 1.7,
                              fontWeight:
                                  FontWeight.w500,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      selectedZikr.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .cardColor,
                  borderRadius:
                      BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        isDark ? 0.15 : 0.06,
                      ),
                      blurRadius: 15,
                      offset:
                          const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'TARGET  •  $selectedTarget',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.bold,
                        color: primaryGreen,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 205,
                          height: 205,
                          child:
                              CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 13,
                            strokeCap:
                                StrokeCap.round,
                            backgroundColor: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                            color: primaryGreen,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '$count',
                              style:
                                  const TextStyle(
                                fontSize: 62,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    primaryGreen,
                              ),
                            ),
                            Text(
                              'COUNT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold,
                                letterSpacing: 2,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _incrementCount,
                      child: Container(
                        width: 125,
                        height: 125,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryGreen,
                          boxShadow: [
                            BoxShadow(
                              color: primaryGreen
                                  .withOpacity(0.35),
                              blurRadius: 18,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(
                                Icons
                                    .touch_app_rounded,
                                color: Colors.white,
                                size: 29,
                              ),
                              SizedBox(height: 3),
                              Text(
                                'TAP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight:
                                      FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<ZikrModel>(
                value: selectedZikr,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.menu_book_rounded,
                    color: primaryGreen,
                  ),
                  labelText: 'Select Zikr',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).cardColor,
                ),
                items: ZikrData.allZikr.map(
                  (zikr) {
                    return DropdownMenuItem<
                        ZikrModel>(
                      value: zikr,
                      child: Text(
                        zikr.name,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _changeZikr(value);
                  }
                },
              ),
              const SizedBox(height: 13),
              DropdownButtonFormField<String>(
                value: targetOptions.contains(
                  selectedTarget,
                )
                    ? selectedTarget.toString()
                    : 'Custom',
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.flag_rounded,
                    color: primaryGreen,
                  ),
                  labelText: 'Select Target',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).cardColor,
                ),
                items: [
                  ...targetOptions.map(
                    (target) =>
                        DropdownMenuItem<String>(
                      value: target.toString(),
                      child: Text('$target'),
                    ),
                  ),
                  const DropdownMenuItem<String>(
                    value: 'Custom',
                    child: Text('Custom'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  if (value == 'Custom') {
                    _customTargetDialog();
                  } else {
                    _changeTarget(
                      int.parse(value),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _resetCount,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text(
                    'Reset Current Count',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        primaryGreen,
                    side: const BorderSide(
                      color: primaryGreen,
                      width: 1.4,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .cardColor,
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItem(
                      icon:
                          Icons.touch_app_rounded,
                      title: 'Current',
                      value: '$count',
                    ),
                    Container(
                      height: 45,
                      width: 1,
                      color:
                          Colors.grey.withOpacity(
                        0.3,
                      ),
                    ),
                    _statItem(
                      icon: Icons.today_rounded,
                      title: 'Today',
                      value: '$todayCount',
                    ),
                    Container(
                      height: 45,
                      width: 1,
                      color:
                          Colors.grey.withOpacity(
                        0.3,
                      ),
                    ),
                    _statItem(
                      icon:
                          Icons.all_inclusive_rounded,
                      title: 'Total',
                      value: '$totalCount',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: primaryGreen,
          size: 24,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }
}