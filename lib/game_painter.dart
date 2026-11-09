import 'dart:math';
import 'package:flutter/material.dart';
import 'game_engine.dart';

class GamePainter extends CustomPainter {
  GamePainter(this.g);
  final BlockGame g;
  static const pale=Color(0xFFEAF5FF);

  void rounded(Canvas c,double x,double y,double w,double h,double radius,Color color){
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h),Radius.circular(radius)),
      Paint()..color=color);
  }

  void label(Canvas c,String text,double x,double y,{double size=12,
      Color color=pale,FontWeight weight=FontWeight.bold}){
    final painter=TextPainter(
      text:TextSpan(text:text,style:TextStyle(fontSize:size,fontWeight:weight,color:color)),
      textDirection:TextDirection.ltr,maxLines:1,
    )..layout();
    painter.paint(c,Offset(x-painter.width/2,y-painter.height/2));
  }

  @override
  void paint(Canvas canvas, Size size){
    canvas.save();
    canvas.scale(size.width/gameWidth,size.height/gameHeight);
    final c=canvas;
    rounded(c,0,0,gameWidth,gameHeight,0,const Color(0xFF101D32));
    final grid=Paint()..color=const Color(0xFF2E455D)..strokeWidth=.5;
    for(var x=0.0;x<gameWidth;x+=21){c.drawLine(Offset(x,0),Offset(x,gameHeight),grid);}
    for(var y=0.0;y<gameHeight;y+=21){c.drawLine(Offset(0,y),Offset(gameWidth,y),grid);}
    if(g.feverSeconds>0){
      rounded(c,0,0,gameWidth,gameHeight,0,const Color(0x20FFAD52));
    }
    label(c,g.boss==null?'BLOK AKIŞI':'BOSS SAVAŞI',85,26,size:10,
      color:const Color(0xFFADC4D9));
    label(c,'↓ '+g.speed.round().toString()+' px/sn',362,26,size:10,
      color:const Color(0xFF7DFFE1));
    c.drawLine(const Offset(13,43),const Offset(407,43),
      Paint()..color=const Color(0xFF38546E));

    if(g.pressure>.55){
      rounded(c,0,44,gameWidth,dangerLine-44,0,
        Color.fromARGB(((g.pressure-.55)*70).round(),255,54,78));
    }
    final dangerPaint=Paint()..color=const Color(0xFFFF839B)
      ..strokeWidth=g.power==4?3:1.6;
    for(var x=10.0;x<409;x+=15){
      c.drawLine(Offset(x,dangerLine),Offset(min(x+8,409),dangerLine),dangerPaint);
    }
    label(c,'TEHLİKE ÇİZGİSİ',358,dangerLine-10,size:9,
      color:const Color(0xFFFFAABB));
    rounded(c,0,gameHeight-71,gameWidth,71,0,const Color(0xFF1B3452));
    c.drawLine(const Offset(0,519),const Offset(420,519),
      Paint()..color=const Color(0xFF467D94));

    for(final b in g.bricks){
      if(b.y+brickHeight<43||b.y>gameHeight)continue;
      final color=switch(b.kind) {
        BrickKind.stone=>const Color(0xFF8597B1),
        BrickKind.gold=>const Color(0xFFFFCB67),
        BrickKind.bomb=>const Color(0xFFFF798D),
        BrickKind.electric=>const Color(0xFFA79DFF),
        BrickKind.ordinary=>b.color,
      };
      rounded(c,b.x,b.y+3,brickWidth,brickHeight,4,const Color(0xFF071322));
      rounded(c,b.x,b.y,brickWidth,brickHeight-3,4,color);
      rounded(c,b.x+4,b.y+3,brickWidth-8,2,1,const Color(0x99FFFFFF));
      final symbol=switch(b.kind) {
        BrickKind.bomb=>'✹',BrickKind.electric=>'ϟ',
        BrickKind.gold=>'★',
        _=>b.health>1?b.health.toString():'—',
      };
      label(c,symbol,b.x+brickWidth/2,b.y+15,size:16,
        color:b.kind==BrickKind.bomb?const Color(0xFFFFE8B9):const Color(0xFF26364C),
        weight:FontWeight.w900);
    }

    final boss=g.boss;
    if(boss!=null){
      rounded(c,88,49,244,10,4,const Color(0xFF2B3851));
      rounded(c,88,49,244*(boss.health/boss.maximum).clamp(0.0,1.0),10,4,
        const Color(0xFFFF667D));
      label(c,'BOSS '+max(0,boss.health.ceil()).toString()+' HP',
        210,43,size:10,color:const Color(0xFFFFC7D1));
      rounded(c,boss.x,boss.y,136,74,12,const Color(0xFF905B89));
      rounded(c,boss.x+11,boss.y+13,114,52,9,const Color(0xFF24374F));
      rounded(c,boss.x+24,boss.y+24,30,25,8,const Color(0xFFFF956F));
      rounded(c,boss.x+82,boss.y+24,30,25,8,const Color(0xFFFF956F));
      label(c,'◆',boss.x+68,boss.y+55,size:17,color:const Color(0xFFFF8096));
    }

    for(final ray in g.rays){
      final opacity=(ray.life/ray.initial).clamp(0.0,1.0);
      c.drawLine(Offset(ray.x1,ray.y1),Offset(ray.x2,ray.y2),
        Paint()..color=ray.color.withValues(alpha:opacity)..strokeWidth=9);
      c.drawLine(Offset(ray.x1,ray.y1),Offset(ray.x2,ray.y2),
        Paint()..color=Colors.white.withValues(alpha:opacity)..strokeWidth=2);
    }
    for(final p in g.shots){
      rounded(c,p.x-(p.rocket?4:2),p.y-10,p.rocket?8:4,17,3,
        p.rocket?const Color(0xFFFFD69B):const Color(0xFFC7FFFF));
    }
    for(final shot in g.enemyShots){
      c.drawCircle(Offset(shot.x,shot.y),7,
        Paint()..color=const Color(0xFFFF8690));
    }
    for(final p in g.drops){
      final dy=p.y+sin(p.phase)*3;
      final color=switch(p.kind){
        DropKind.rapid=>const Color(0xFFFFD27B),
        DropKind.shield=>const Color(0xFF83C4FF),
        DropKind.heart=>const Color(0xFFFF92AA),
        DropKind.coins=>const Color(0xFFFFDC81),
      };
      rounded(c,p.x-16,dy-16,32,32,7,const Color(0xFF26394D));
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(p.x-16,dy-16,32,32),
          const Radius.circular(7)),
        Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=2,
      );
      final icon=switch(p.kind){
        DropKind.rapid=>'ϟ',DropKind.shield=>'◆',
        DropKind.heart=>'♥',DropKind.coins=>'★',
      };
      label(c,icon,p.x,dy,size:19,color:color);
    }
    for(final p in g.dust) {
      c.drawCircle(Offset(p.x,p.y),2.2,
        Paint()..color=p.color.withValues(
          alpha:(p.life/p.initial).clamp(0.0,1.0)));
    }

    final gunColor=g.feverSeconds>0?const Color(0xFFFFBE66):
      g.power==4?const Color(0xFFFF866A):const Color(0xFF30DAC3);
    if(g.shieldSeconds>0){
      c.drawArc(Rect.fromCircle(center:Offset(g.gunX,gunLine-14),radius:34),
        pi,pi,false,Paint()..color=const Color(0xFF83D8FF)
          ..style=PaintingStyle.stroke..strokeWidth=3);
    }
    rounded(c,g.gunX-13,gunLine-24,26,42,6,gunColor);
    final barrels=g.weapon==Weapon.rocket?[-9.0,9.0]:
      g.weapon==Weapon.spread?[-12.0,0,12.0]:
      g.weapon==Weapon.laser?[0.0]:
      g.power==1?[0.0]:[-12.0,0,12.0];
    for(final dx in barrels){
      rounded(c,g.gunX+dx-5,gunLine-38+g.recoil*7,10,29,4,
        const Color(0xFFB9D6E8));
      rounded(c,g.gunX+dx-3,gunLine-39+g.recoil*7,6,5,2,
        const Color(0xFF203248));
    }
    rounded(c,g.gunX-25,gunLine,50,18,7,const Color(0xFF537EAD));
    rounded(c,g.gunX-18,gunLine+3,36,6,3,const Color(0xFFBFDDEA));
    rounded(c,g.gunX-5,gunLine+4,10,9,3,const Color(0xFF41F1D7));
    if(g.feverSeconds>0){
      label(c,'🔥 FEVER '+g.feverSeconds.toStringAsFixed(1)+'s',
        210,79,size:19,color:const Color(0xFFFFD78A));
    }
    if(g.messageSeconds>0 && g.phase==GamePhase.playing){
      rounded(c,55,280,310,48,11,const Color(0xE2102035));
      label(c,g.message,210,303,size:17,color:const Color(0xFFFFDC9C),
        weight:FontWeight.w900);
    }
    if(g.phase!=GamePhase.playing){
      rounded(c,0,0,gameWidth,gameHeight,0,const Color(0xEA0A1527));
      rounded(c,35,185,350,226,16,const Color(0xFF192B42));
      final title=switch(g.phase) {
        GamePhase.ready=>'BLOK KIRMA',
        GamePhase.paused=>'DURAKLATILDI',
        GamePhase.lost=>'OYUN BİTTİ',
        GamePhase.playing=>'',
      };
      final subtitle=switch(g.phase){
        GamePhase.ready=>'Silahını geliştir, blokları kır!',
        GamePhase.paused=>'Devam etmek için Başlat.',
        GamePhase.lost=>'Bütün canların tükendi.',
        GamePhase.playing=>'',
      };
      label(c,title,210,246,size:26,color:const Color(0xFF8AFFF0),
        weight:FontWeight.w900);
      label(c,subtitle,210,287,size:14);
      label(c,'Patlamalar · FEVER · Boss · Mağaza',210,317,size:11,
        color:const Color(0xFFB0C7DC));
      rounded(c,108,341,204,45,10,const Color(0xFF35D8C4));
      label(c,g.phase==GamePhase.paused?'▶ DEVAM ET':
        g.phase==GamePhase.lost?'▶ TEKRAR OYNA':'▶ BAŞLA',
        210,364,size:15,color:const Color(0xFF09313B),
        weight:FontWeight.w900);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate)=>true;
}
