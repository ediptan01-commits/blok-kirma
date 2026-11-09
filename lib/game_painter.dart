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

  Path blockPath(Brick b){
    final x=b.x,y=b.y,w=b.width,h=b.height;
    switch(b.shape){
      case BrickShape.rectangle:
        return Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h),const Radius.circular(4)));
      case BrickShape.hexagon:
        return Path()..moveTo(x+w*.22,y)..lineTo(x+w*.78,y)
          ..lineTo(x+w,y+h*.5)..lineTo(x+w*.78,y+h)
          ..lineTo(x+w*.22,y+h)..lineTo(x,y+h*.5)..close();
      case BrickShape.diamond:
        return Path()..moveTo(x+w*.5,y)..lineTo(x+w,y+h*.5)
          ..lineTo(x+w*.5,y+h)..lineTo(x,y+h*.5)..close();
      case BrickShape.triangle:
        return Path()..moveTo(x+w*.5,y)
          ..lineTo(x+w,y+h)..lineTo(x,y+h)..close();
    }
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
    label(c,g.boss==null?'DALGA ${g.waveTier+1} · ${g.waveName}':'BOSS SAVAŞI',120,26,size:10,
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
      if(b.y+b.height<43||b.y>gameHeight)continue;
      final color=switch(b.kind) {
        BrickKind.stone=>const Color(0xFF8597B1),
        BrickKind.gold=>const Color(0xFFFFCB67),
        BrickKind.bomb=>const Color(0xFFFF798D),
        BrickKind.electric=>const Color(0xFFA79DFF),
        BrickKind.armored=>const Color(0xFF526888),
        BrickKind.prism=>const Color(0xFFEC85F5),
        BrickKind.column=>const Color(0xFFFFA66F),
        BrickKind.ordinary=>b.color,
      };
      final shape=blockPath(b);
      c.drawPath(shape.shift(const Offset(0,3)),Paint()..color=const Color(0xFF071322));
      c.drawPath(shape,Paint()..color=color);
      c.save();c.clipPath(shape);
      c.drawRect(Rect.fromLTWH(b.x,b.y,b.width,b.height*.3),Paint()..color=const Color(0x35FFFFFF));
      c.restore();
      final symbol=switch(b.kind){
        BrickKind.bomb=>'✹',BrickKind.electric=>'ϟ',BrickKind.gold=>'★',
        BrickKind.armored=>b.health.toString(),BrickKind.prism=>'◆',
        BrickKind.column=>'↟',_=>b.health>1?b.health.toString():'—',
      };
      label(c,symbol,b.x+b.width/2,b.y+b.height*(b.shape==BrickShape.triangle?.69:.53),
        size:min(16.0,b.width*.47),
        color:b.kind==BrickKind.bomb||b.kind==BrickKind.armored?
          const Color(0xFFFFE8B9):const Color(0xFF26364C),
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

    drawGun(c);
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

  void drawGun(Canvas c){
    c.save();
    c.translate(g.gunX,gunLine+g.recoil*2.6);
    final machine=g.weapon==Weapon.machine;
    final metal=Paint()..shader=const LinearGradient(
      colors:[Color(0xFF263A49),Color(0xFFCDD4DB),Color(0xFF465B70)],
      begin:Alignment.centerLeft,end:Alignment.centerRight,
    ).createShader(const Rect.fromLTWH(-45,-63,90,84));
    final dark=Paint()..color=const Color(0xFF172836);
    // Ağır makineli tüfek yuvası, mekanizma ve perçinler.
    rounded(c,-33,10,66,12,6,const Color(0xFF304E68));
    rounded(c,-25,12,50,5,2,const Color(0xFF9BACB9));
    for(final side in [-27.0,27.0]){
      c.drawCircle(Offset(side,15),3,Paint()..color=const Color(0xFFDFE5E6));
      c.drawCircle(Offset(side,15),1.4,dark);
    }
    if(g.shieldSeconds>0){
      c.drawArc(const Rect.fromLTWH(-39,-71,78,78),pi,pi,false,
        Paint()..color=const Color(0xFF8CDEFF)
          ..strokeWidth=3..style=PaintingStyle.stroke);
    }
    // Mühimmat kutusu ve metalik fişek şeridi.
    rounded(c,-40,-13,22,24,4,const Color(0xFF364B3D));
    rounded(c,-37,-10,16,4,1,const Color(0xFF8FA276));
    for(var i=0;i<5;i++){
      rounded(c,-18+i*3.2,-13-i*1.8,3.5,7,1,const Color(0xFFD1A751));
    }
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-22,-28,44,36),
      const Radius.circular(8)),metal);
    rounded(c,-17,-26,34,7,3,const Color(0xFF283B4C));
    rounded(c,-15,-15,30,4,1,const Color(0xFF9CAAB9));
    if(machine){
      // Altı namlulu döner taramalı silah. Gerçekçi metal yüzey / ısı kalkanı.
      final spin=g.elapsed*(g.recoil>0?35:2);
      for(var i=0;i<6;i++){
        final angle=spin+i*pi/3;
        final dx=cos(angle)*7;
        rounded(c,dx-2,-62+g.recoil*5,4.2,44,1.5,
          i.isEven?const Color(0xFFCDD7DD):const Color(0xFF3C5368));
        rounded(c,dx-2,-61+g.recoil*5,4.2,5,1,const Color(0xFF192B36));
      }
      rounded(c,-12,-45,24,8,3,const Color(0xFF2C4355));
      for(var i=0;i<4;i++){
        c.drawCircle(Offset(-7+i*4.6,-41),1.1,
          Paint()..color=const Color(0xFFC7D0D1));
      }
      rounded(c,-12,-23,24,6,3,const Color(0xFF9CABBA));
      c.drawOval(const Rect.fromLTWH(-10,-66,20,7),dark);
      for(var i=0;i<3;i++){
        c.drawCircle(Offset((i-1)*5,-62),1.6,
          Paint()..color=const Color(0xFFB8C6C5));
      }
    }else{
      final barrels=g.weapon==Weapon.rocket?[-9.0,9.0]:
        g.weapon==Weapon.spread?[-10.0,0.0,10.0]:[0.0];
      for(final dx in barrels){
        c.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(dx-5,-58+g.recoil*5,10,39),
          const Radius.circular(3)),metal);
        rounded(c,dx-3,-60+g.recoil*5,6,5,2,const Color(0xFF12242C));
      }
      rounded(c,-13,-25,26,7,3,const Color(0xFF8497A8));
    }
    rounded(c,-11,4,22,11,3,g.feverSeconds>0?
      const Color(0xFFFFB064):const Color(0xFF3DDCC5));
    if(g.recoil>.35&&machine){
      // Ateş sırasında boş kovanlar sağa dökülür.
      for(var i=0;i<3;i++){
        final fraction=(g.elapsed*15+i*.31)%1.0;
        c.save();c.translate(21+fraction*14,-12+fraction*18);
        c.rotate(.45+fraction*2.4);
        rounded(c,0,0,5,2.3,1,const Color(0xFFE3B25D));
        c.restore();
      }
    }
    if(g.recoil>.15){
      final fireColor=g.feverSeconds>0?
        const Color(0xFFFFC448):const Color(0xFFFFE3A0);
      final tip=machine?-67.0:-60.0;
      final muzzle=Path()..moveTo(0,tip+5)
        ..lineTo(-9,tip-6)..lineTo(-2,tip-11)
        ..lineTo(0,tip-22-g.recoil*8)
        ..lineTo(4,tip-9)..lineTo(10,tip-6)..close();
      c.drawPath(muzzle,Paint()..color=fireColor);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate)=>true;
}
