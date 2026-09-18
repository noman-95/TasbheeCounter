import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class QuranPracticeScreen extends StatefulWidget {
  const QuranPracticeScreen({super.key});

  @override
  State<QuranPracticeScreen> createState() => _QuranPracticeScreenState();
}

class _QuranPracticeScreenState extends State<QuranPracticeScreen> {
  static const Color primaryGreen = Color(0xFF087F5B);

  static const _verses = <Map<String, String>>[
    {
      'number': '1',
      'arabic': 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
    },
    {
      'number': '2',
      'arabic': 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    },
    {
      'number': '3',
      'arabic': 'الرَّحْمَنِ الرَّحِيمِ',
    },
  ];

  final stt.SpeechToText _speech = stt.SpeechToText();

  int _index = 0;
  String _recognized = '';
  bool _listening = false;
  String _status =
      'Press the microphone and recite the displayed ayah.';
  double? _score;

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(
          RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'),
          '',
        )
        .replaceAll(
          RegExp(r'[^\u0600-\u06FF\s]'),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _words(String text) {
    return _normalize(text)
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
  }

  void _checkRecitation() {
    final expected = _words(_verses[_index]['arabic']!);
    final actual = _words(_recognized);

    if (expected.isEmpty) {
      setState(() => _score = 0);
      return;
    }

    int matches = 0;

    final limit =
        actual.length < expected.length
            ? actual.length
            : expected.length;

    for (int i = 0; i < limit; i++) {
      if (actual[i] == expected[i]) {
        matches++;
      }
    }

    final score = (matches / expected.length) * 100;

    setState(() {
      _score = score;
      _status = actual.isEmpty
          ? 'No Arabic speech was detected. Try again.'
          : 'Prototype comparison complete. This checks recognized words only; it is not a Tajweed verdict.';
    });
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();

      if (mounted) {
        setState(() => _listening = false);
      }

      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;

        setState(() {
          _listening = status == 'listening';
        });
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _listening = false;
          _status =
              'Microphone/speech error. Please check microphone permission.';
        });
      },
    );

    if (!available) {
      setState(() {
        _status =
            'Speech recognition is not available on this device.';
      });
      return;
    }

    setState(() {
      _recognized = '';
      _score = null;
      _status = 'Listening… Recite the ayah clearly.';
      _listening = true;
    });

    await _speech.listen(
      localeId: 'ar',
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _recognized = result.recognizedWords;
        });

        if (result.finalResult) {
          _speech.stop();

          setState(() {
            _listening = false;
          });

          _checkRecitation();
        }
      },
    );
  }

  void _next() {
    if (_index >= _verses.length - 1) return;

    setState(() {
      _index++;
      _recognized = '';
      _score = null;
      _status =
          'Press the microphone and recite the displayed ayah.';
    });
  }

  void _previous() {
    if (_index <= 0) return;

    setState(() {
      _index--;
      _recognized = '';
      _score = null;
      _status =
          'Press the microphone and recite the displayed ayah.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final verse = _verses[_index];
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran Practice'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Text(
                'سُورَةُ الْفَاتِحَة',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Ayah ${verse['number']} of 3',
                style: TextStyle(
                  color:
                      isDark ? Colors.white70 : Colors.black54,
                ),
              ),

              const SizedBox(height: 18),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(18, 28, 18, 24),
                  child: Column(
                    children: [
                      Text(
                        verse['arabic']!,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 31,
                          height: 2.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        _recognized.isEmpty
                            ? 'Your recitation will appear here…'
                            : _recognized,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.8,
                          color: _recognized.isEmpty
                              ? Colors.grey
                              : primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _toggleListening,
                  icon: Icon(
                    _listening
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                  ),
                  label: Text(
                    _listening
                        ? 'Stop Recitation'
                        : 'Recite Ayah',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed:
                    _recognized.isEmpty
                        ? null
                        : _checkRecitation,
                icon: const Icon(
                  Icons.check_circle_outline,
                ),
                label: const Text('Check Recitation'),
              ),

              const SizedBox(height: 16),

              if (_score != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_score!.round()}% word match',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Prototype feedback — not a Tajweed judgment.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      isDark ? Colors.white70 : Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _index == 0 ? null : _previous,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _index == _verses.length - 1
                              ? null
                              : _next,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}