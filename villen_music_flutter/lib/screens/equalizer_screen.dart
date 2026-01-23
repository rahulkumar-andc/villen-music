// Equalizer Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/providers/audio_provider.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  List<AndroidEqualizerBand>? _bands;
  bool _enabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEqualizer();
  }

  Future<void> _loadEqualizer() async {
    final audio = context.read<AudioProvider>();
    final bands = await audio.getEqualizerBands();
    setState(() {
      _bands = bands;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        backgroundColor: Colors.transparent,
        actions: [
          Switch(
            value: _enabled,
            activeColor: AppTheme.accentMagenta,
            onChanged: (val) async {
              setState(() => _enabled = val);
              await context.read<AudioProvider>().setEqualizerEnabled(val);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bands == null || _bands!.isEmpty
              ? const Center(child: Text("Equalizer not available on this device"))
              : Column(
                  children: [
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _bands!.length,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemBuilder: (context, index) {
                          final band = _bands![index];
                          final freq = band.centerFrequency < 1000
                              ? '${band.centerFrequency.toInt()} Hz'
                              : '${(band.centerFrequency / 1000).toStringAsFixed(1)} kHz';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(freq, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${band.gain.toStringAsFixed(1)} dB'),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  activeTrackColor: AppTheme.accentMagenta,
                                  inactiveTrackColor: Colors.grey[800],
                                  thumbColor: AppTheme.primaryPurple,
                                ),
                                child: Slider(
                                  value: band.gain,
                                  min: -15.0, // Typical range, adjust if min/max provided
                                  max: 15.0,
                                  onChanged: _enabled ? (val) {
                                    setState(() {
                                      band.gain = val;
                                    });
                                    context.read<AudioProvider>().setBandGain(index, val);
                                  } : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
