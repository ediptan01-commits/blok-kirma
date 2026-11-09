import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'game_engine.dart';
import 'game_audio.dart';
import 'game_painter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlokKirmaApp());
}

class BlokKirmaApp extends StatelessWidget {
  const BlokKirmaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Blok Kırma',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3:true,brightness:Brightness.dark,
      scaffoldBackgroundColor:const Color(0xFF0A1525),
      colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF36DCC8),brightness:Brightness.dark)),
    home:const BlokKirmaPage(),
  );
}

class BlokKirmaPage extends StatefulWidget {
  const BlokKirmaPage({super.key});
  @override
  State<BlokKirmaPage> createState()=>_BlokKirmaPageState();
}

class _BlokKirmaPageState extends State<BlokKirmaPage> with SingleTickerProviderStateMixin {
  late final GameAudio audio;
  late final BlockGame game;
  late final Ticker ticker;
  Duration? previous;
  final focus=FocusNode();
  bool left=false,right=false,dragging=false,keyFiring=false;

  @override
  void initState() {
    super.initState();
    audio=GameAudio();
    game=BlockGame(audio.play);
    ticker=createTicker((elapsed) {
      final old=previous;previous=elapsed;
      if(!mounted)return;
      final dt=old==null?0.0:((elapsed-old).inMicroseconds/1000000).clamp(0.0,.035);
      setState(()=>game.tick(dt,left:left,right:right,fire:dragging||keyFiring));
    })..start();
  }

  @override
  void dispose() {
    ticker.dispose();focus.dispose();audio.dispose();super.dispose();
  }

  void toggle() {
    setState(() {
      game.startOrPause();
      if(game.phase!=GamePhase.playing){dragging=false;keyFiring=false;}
    });
    focus.requestFocus();
  }
  void restart() {
    setState(() {
      game.reset();left=false;right=false;dragging=false;keyFiring=false;
      game.startOrPause();
    });
  }
  void bossDemo() {
    setState(() {dragging=false;keyFiring=false;game.bossDemo();});
  }

  String gunName(Weapon w)=>switch(w) {
    Weapon.machine=>'Taramalı',Weapon.spread=>'Saçmalı',
    Weapon.laser=>'Lazer',Weapon.rocket=>'Roket'
  };
  String gunIcon(Weapon w)=>switch(w) {
    Weapon.machine=>'🔫',Weapon.spread=>'💥',
    Weapon.laser=>'⚡',Weapon.rocket=>'🚀'
  };

  Widget smallStat(String label,String value,[Color color=Colors.white])=>Container(
    margin:const EdgeInsets.only(left:4),padding:const EdgeInsets.symmetric(horizontal:7,vertical:5),
    decoration:BoxDecoration(color:const Color(0xFF203047),borderRadius:BorderRadius.circular(9),
      border:Border.all(color:const Color(0xFF405671))),
    child:Column(children:[
      Text(label,style:const TextStyle(fontSize:9,color:Color(0xFFAFBDD1))),
      Text(value,style:TextStyle(fontSize:14,fontWeight:FontWeight.w900,color:color)),
    ]),
  );

  Widget action(String label,VoidCallback callback,{bool primary=false,bool selected=false})=>
    Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),
      child:ElevatedButton(
        onPressed:callback,
        style:ElevatedButton.styleFrom(
          backgroundColor:primary?const Color(0xFF31D6C2):
            selected?const Color(0xFF175C61):const Color(0xFF293C56),
          foregroundColor:primary?const Color(0xFF082A35):Colors.white,
          side:BorderSide(color:selected?const Color(0xFF47E9D1):const Color(0xFF415A75)),
          padding:const EdgeInsets.symmetric(horizontal:3,vertical:10),
          shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(9)),
        ),
        child:FittedBox(fit:BoxFit.scaleDown,
          child:Text(label,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800))),
      ),
    ));

  Widget meter(String label,String value,double progress,Color color)=>Column(children:[
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Text(label,style:TextStyle(fontSize:11,fontWeight:FontWeight.bold,color:color)),
      Text(value,style:TextStyle(fontSize:11,fontWeight:FontWeight.bold,color:color)),
    ]),
    const SizedBox(height:5),
    ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(
      value:progress.clamp(0.0,1.0),minHeight:8,
      color:color,backgroundColor:const Color(0xFF293950))),
  ]);

  void openShop(){
    if(game.shopOpen)return;
    setState(()=>game.shopOpen=true);
    showModalBottomSheet<void>(
      context:context,showDragHandle:true,isScrollControlled:true,
      backgroundColor:const Color(0xFF17283E),
      builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh){
        Widget item(String name,String desc,int cost,bool disabled,VoidCallback buy)=>
          Container(
            padding:const EdgeInsets.all(9),
            decoration:BoxDecoration(color:const Color(0xFF22374F),
              borderRadius:BorderRadius.circular(10),
              border:Border.all(color:const Color(0xFF46617A))),
            child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              Text(name,style:const TextStyle(fontSize:13,fontWeight:FontWeight.bold)),
              const SizedBox(height:4),
              Text(desc,style:const TextStyle(fontSize:11,color:Color(0xFFAFBED3))),
              const Spacer(),
              ElevatedButton(
                onPressed:disabled?null:(){setState(buy);refresh((){});},
                style:ElevatedButton.styleFrom(
                  backgroundColor:const Color(0xFF35D9C4),
                  foregroundColor:const Color(0xFF082B35),
                  padding:const EdgeInsets.symmetric(horizontal:4)),
                child:Text(disabled?'Alındı / Yetersiz':'🪙 '+cost.toString(),
                  style:const TextStyle(fontSize:11,fontWeight:FontWeight.bold)),
              )
            ]),
          );
        final items=<Widget>[];
        for(final w in Weapon.values.skip(1)){
          final owned=game.unlocked.contains(w),price=game.weaponPrice(w);
          items.add(item(gunIcon(w)+' '+gunName(w),'Yeni silah aç.',price,
            owned||game.coins<price,()=>game.purchaseWeapon(w)));
        }
        for(final key in ['damage','speed','spread']){
          final n=game.upgrades[key]!,limit=key=='spread'?3:4,price=game.upgradePrice(key);
          final name=switch(key){
            'damage'=>'💪 Mermi Hasarı','speed'=>'⚡ Ateş Hızı',_=>'🎯 Ek Mermiler'
          };
          items.add(item(name,'Seviye '+n.toString()+'/'+limit.toString(),price,
            n>=limit||game.coins<price,()=>game.purchaseUpgrade(key)));
        }
        items.add(item('♥ Can Doldur','Bir can kazan.',55,
          game.lives>=5||game.coins<55,()=>game.purchaseUpgrade('heal')));
        return SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(14,0,14,12),
          child:Column(mainAxisSize:MainAxisSize.min,children:[
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
              const Text('🛒 Silah Mağazası',
                style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
              Text('🪙 '+game.coins.toString(),
                style:const TextStyle(color:Color(0xFFFFDC7F),fontWeight:FontWeight.w900)),
            ]),
            const Padding(padding:EdgeInsets.all(8),child:Text(
              'Blokları kırarak altın kazan. Satın almalar oyun boyunca geçerlidir.',
              style:TextStyle(fontSize:11,color:Color(0xFFB3C6D7)))),
            Flexible(child:GridView.count(crossAxisCount:2,childAspectRatio:1.4,
              mainAxisSpacing:7,crossAxisSpacing:7,shrinkWrap:true,children:items)),
          ]),
        ));
      }),
    ).whenComplete((){
      if(mounted)setState(()=>game.shopOpen=false);
      focus.requestFocus();
    });
  }

  KeyEventResult onKey(FocusNode node,KeyEvent event){
    final down=event is KeyDownEvent||event is KeyRepeatEvent;
    if(event.logicalKey==LogicalKeyboardKey.arrowLeft||event.logicalKey==LogicalKeyboardKey.keyA){
      setState(()=>left=down);return KeyEventResult.handled;
    }
    if(event.logicalKey==LogicalKeyboardKey.arrowRight||event.logicalKey==LogicalKeyboardKey.keyD){
      setState(()=>right=down);return KeyEventResult.handled;
    }
    if(event.logicalKey==LogicalKeyboardKey.space){
      if(event is KeyDownEvent && game.phase==GamePhase.ready)toggle();
      setState(()=>keyFiring=down);
      return KeyEventResult.handled;
    }
    if(event.logicalKey==LogicalKeyboardKey.keyP&&event is KeyDownEvent){
      toggle();return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context){
    final g=game;
    final progressText=g.boss==null
      ?g.destroyed.toString()+' / '+g.goal.toString()
      :'👑 '+max(0,g.boss!.health.ceil()).toString()+' HP';
    return Scaffold(body:SafeArea(
      child:Focus(focusNode:focus,autofocus:true,onKeyEvent:onKey,
        child:Center(child:ConstrainedBox(
          constraints:const BoxConstraints(maxWidth:540),
          child:SingleChildScrollView(padding:const EdgeInsets.all(10),
            child:Container(
              padding:const EdgeInsets.all(12),
              decoration:BoxDecoration(color:const Color(0xFF111E2F),
                borderRadius:BorderRadius.circular(18),
                border:Border.all(color:const Color(0xFF38516B))),
              child:Column(mainAxisSize:MainAxisSize.min,children:[
                Row(children:[
                  const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text('BLOK KIRMA',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900,
                      color:Color(0xFF4CE3D0))),
                    Text('SAVAŞ ARENASI · 8.0',
                      style:TextStyle(fontSize:10,color:Color(0xFFA2B8CD))),
                  ])),
                  smallStat('PUAN',g.score.toString()),
                  smallStat('ALTIN',g.coins.toString(),const Color(0xFFFFDD82)),
                  smallStat('CAN','♥'+g.lives.toString(),const Color(0xFFFFA2AF)),
                ]),
                const SizedBox(height:9),
                LayoutBuilder(builder:(ctx,box)=>AspectRatio(
                  aspectRatio:gameWidth/gameHeight,
                  child:ClipRRect(borderRadius:BorderRadius.circular(12),
                    child:RawGestureDetector(
                      key:const ValueKey('game-arena'),
                      behavior:HitTestBehavior.opaque,
                      gestures:<Type,GestureRecognizerFactory>{
                        EagerGestureRecognizer:GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                          (EagerGestureRecognizer instance) {},
                        ),
                      },
                      child:Listener(
                        behavior:HitTestBehavior.opaque,
                      onPointerDown:(e){
                        focus.requestFocus();
                        if(g.phase!=GamePhase.playing)toggle();
                        if(g.phase==GamePhase.playing&&!g.shopOpen) {
                          setState((){
                            g.auto=false;
                            g.targetX=(e.localPosition.dx/box.maxWidth*gameWidth).clamp(20.0,400.0);
                            dragging=true;
                          });
                        }
                      },
                      onPointerMove:(e){if(dragging&&g.phase==GamePhase.playing){
                        setState(()=>g.targetX=(e.localPosition.dx/box.maxWidth*gameWidth).clamp(20.0,400.0));
                      }},
                      onPointerUp:(_)=>setState(()=>dragging=false),
                      onPointerCancel:(_)=>setState(()=>dragging=false),
                      child:CustomPaint(painter:GamePainter(g),child:const SizedBox.expand()),
                      ),
                    ),
                  ),
                )),
                const SizedBox(height:11),
                meter('⚡ FEVER',g.feverSeconds>0?'AKTİF · '+g.feverSeconds.toStringAsFixed(1)+' sn':
                  g.fever.floor().toString()+'%',g.feverProgress,const Color(0xFFFFB969)),
                const SizedBox(height:9),
                meter('BÖLÜM '+g.level.toString()+' · '+g.waveName,progressText,g.progress,const Color(0xFF39DBC6)),
                const SizedBox(height:9),
                Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                  Text('Blok: '+g.bricks.length.toString(),style:const TextStyle(fontSize:10)),
                  Text('GÜÇ '+g.power.toString(),style:const TextStyle(fontSize:10)),
                  Text('↓ '+g.speed.round().toString()+' px/sn',
                    style:const TextStyle(fontSize:10)),
                  Text(g.feverSeconds>0?'🔥 FEVER':g.shieldSeconds>0?'🛡️ Kalkan':'Normal',
                    style:const TextStyle(fontSize:10)),
                ]),
                const SizedBox(height:9),
                Row(children:[
                  action(g.phase==GamePhase.playing?'Ⅱ Duraklat':
                    g.phase==GamePhase.paused?'▶ Devam':'▶ Başlat',toggle,primary:true),
                  action(g.auto?'✓ Tara Açık':'↔ Otomatik',(){
                    setState((){
                      if(g.phase==GamePhase.ready)g.startOrPause();
                      g.auto=!g.auto;
                    });
                  },selected:g.auto),
                  action('🛒 Mağaza',openShop),
                ]),
                const SizedBox(height:9),
                const Align(alignment:Alignment.centerLeft,child:Text('SİLAH SEÇİMİ',
                  style:TextStyle(fontSize:10,color:Color(0xFFA4BED3),fontWeight:FontWeight.bold))),
                const SizedBox(height:5),
                Row(children:Weapon.values.map((w){
                  final unlocked=g.unlocked.contains(w),selected=g.weapon==w;
                  return Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:2),
                    child:OutlinedButton(
                      onPressed:(){
                        if(!unlocked){openShop();return;}
                        setState(()=>g.weapon=w);
                      },
                      style:OutlinedButton.styleFrom(
                        backgroundColor:selected?const Color(0xFF195B60):const Color(0xFF20334A),
                        side:BorderSide(color:selected?const Color(0xFF4CEBD8):const Color(0xFF3C5670)),
                        padding:const EdgeInsets.symmetric(horizontal:1,vertical:7)),
                      child:Column(children:[
                        Text(unlocked?gunIcon(w):'🔒',style:const TextStyle(fontSize:18)),
                        FittedBox(child:Text(gunName(w),style:const TextStyle(fontSize:10))),
                      ]),
                    ),
                  ));
                }).toList()),
                const SizedBox(height:8),
                const Text('BASILI TUT = ATEŞ ET · SÜRÜKLE = NİŞAN AL',
                  textAlign:TextAlign.center,
                  style:TextStyle(fontSize:11,color:Color(0xFF69E9D5),fontWeight:FontWeight.w800)),
                const SizedBox(height:10),
                Wrap(spacing:6,runSpacing:4,alignment:WrapAlignment.center,children:[
                  TextButton(onPressed:bossDemo,child:const Text('👑 Boss Dene')),
                  TextButton(onPressed:restart,child:const Text('↻ Yeni Oyun')),
                  TextButton(onPressed:()=>setState(()=>audio.enabled=!audio.enabled),
                    child:Text(audio.enabled?'🔊 Ses Açık':'🔇 Ses Kapalı')),
                  DropdownButton<int>(isDense:true,underline:const SizedBox(),
                    value:g.speedMode,
                    items:const [
                      DropdownMenuItem(value:0,child:Text('Normal')),
                      DropdownMenuItem(value:1,child:Text('Hızlı')),
                      DropdownMenuItem(value:2,child:Text('Turbo')),
                    ],
                    onChanged:(value){if(value!=null)setState(()=>g.speedMode=value);}),
                ]),
                const Text('Oyun alanını basılı tutup sürükle; ekran kaymaz. Ateş etmek için basılı tut; Otomatik modu isteğe bağlı. '
                  'Tehlike çizgisine yaklaştıkça silah güçlenir.',
                  style:TextStyle(color:Color(0xFF9BB3C8),fontSize:10,height:1.5),
                  textAlign:TextAlign.center),
              ]),
            ),
          ),
        )),
      ),
    ));
  }
}
