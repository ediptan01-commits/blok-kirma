import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Real CC0 firearm recordings for gunshots; offline procedural sounds for other effects.
/// WAV assets are bundled during Android build (see tool/fetch_audio.sh).
class GameAudio {
  final _players = List.generate(8, (_) => AudioPlayer());
  final _sounds = <String, Uint8List>{};
  final _random = Random(17);
  int _index = 0;
  bool enabled = true;
  final _last = <String, DateTime>{};

  GameAudio() {
    for (final id in ['shot','laser','rocket','hit','boom','power',
                      'coin','fever','hurt','boss','start']) {
      _sounds[id] = _build(id);
    }
  }

  Uint8List _build(String type) {
    const sampleRate = 22050;
    final duration = switch(type) {
      'shot' => .15, 'boom' => .38, 'boss' => .48, 'hurt' => .42,
      'laser' => .18, 'rocket' => .24, 'fever' => .38,
      'power' => .24, 'coin' => .13, _ => .11
    };
    final frames = (sampleRate * duration).round();
    final result = ByteData(44 + frames * 2);
    void writeAscii(int offset, String str) {
      for (var i = 0; i < str.length; i++) {
        result.setUint8(offset + i, str.codeUnitAt(i));
      }
    }
    writeAscii(0,'RIFF');result.setUint32(4,36+frames*2,Endian.little);
    writeAscii(8,'WAVE');writeAscii(12,'fmt ');
    result.setUint32(16,16,Endian.little);
    result.setUint16(20,1,Endian.little);
    result.setUint16(22,1,Endian.little);
    result.setUint32(24,sampleRate,Endian.little);
    result.setUint32(28,sampleRate*2,Endian.little);
    result.setUint16(32,2,Endian.little);
    result.setUint16(34,16,Endian.little);
    writeAscii(36,'data');
    result.setUint32(40,frames*2,Endian.little);
    var lowNoise = 0.0;
    for (var i = 0; i < frames; i++) {
      final t = i/sampleRate;
      final u = t/duration;
      final white = _random.nextDouble()*2-1;
      lowNoise = lowNoise*.87 + white*.13;
      double sample;
      switch(type) {
        case 'shot':
          final crack=white*exp(-t*85);
          final low=sin(2*pi*(130-75*u)*t)*exp(-t*23);
          sample=.56*crack+.45*low+.15*lowNoise*exp(-t*15);
        case 'boom':
          sample=.47*lowNoise*exp(-t*7)+
              .46*sin(2*pi*(105-68*u)*t)*exp(-t*5);
        case 'rocket':
          sample=.55*lowNoise*exp(-t*11)+
              .40*sin(2*pi*(220-110*u)*t)*exp(-t*10);
        case 'laser':
          sample=.65*sin(2*pi*(920-640*u)*t)*exp(-t*16)+
              .2*sin(2*pi*(1320-800*u)*t)*exp(-t*18);
        case 'hit':
          sample=.45*white*exp(-t*55)+.35*sin(2*pi*460*t)*exp(-t*32);
        case 'power':
        case 'fever':
          sample=(.50*sin(2*pi*(390+650*u)*t)+
              .22*sin(2*pi*(720+800*u)*t))*sin(pi*u).abs();
        case 'coin':
          sample=.55*sin(2*pi*980*t)*exp(-t*25);
        case 'hurt':
        case 'boss':
          sample=.65*sin(2*pi*(180-120*u)*t)*exp(-t*5)+
              .25*lowNoise*exp(-t*8);
        default:
          sample=.42*sin(2*pi*(450+350*u)*t)*exp(-t*20);
      }
      // Fade tail to avoid a click when playback ends.
      sample *= min(1.0,(1-u)*14);
      result.setInt16(44+i*2,(sample.clamp(-1.0,1.0)*29000).round(),Endian.little);
    }
    return result.buffer.asUint8List();
  }

  Future<void> _playRealShot(AudioPlayer player,int variant) async {
    try {
      await player.stop();
      // Genuine near-field M45 submachine-gun shot recording (CC0).
      await player.play(AssetSource('audio/mp5-report-$variant.wav'),volume:.55);
    }catch(_){
      // Offline developer builds without fetched assets still have a fallback.
      try {
        await player.play(BytesSource(_sounds['shot']!),volume:.40);
      }catch(_){}
    }
  }

  void play(String effect) {
    if (!enabled) return;
    final now=DateTime.now();
    final threshold=effect=='shot'?105:effect=='hit'?70:0;
    final previous=_last[effect];
    if (previous!=null && now.difference(previous).inMilliseconds<threshold) return;
    _last[effect]=now;
    final player=_players[_index++ % _players.length];
    if(effect=='shot'){
      unawaited(_playRealShot(player,(_index-1)%3));
    }else{
      final data=_sounds[effect]??_sounds['start']!;
      player.stop().then((_)=>player.play(BytesSource(data),volume:.48))
        .catchError((Object _) {});
    }
  }

  Future<void> dispose() async {
    for (final p in _players) { await p.dispose(); }
  }
}
