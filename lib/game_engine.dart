import 'dart:math';
import 'package:flutter/material.dart';

const double gameWidth = 420;
const double gameHeight = 590;
const double dangerLine = 489;
const double gunLine = 540;
const double gridTop = 67;
const double rowGap = 35;
const brickWidth = 35.2;
const brickHeight = 31.0;
const brickPalette = <Color>[
  Color(0xFF36DCC8), Color(0xFFAD8BFF), Color(0xFFFFBB61),
  Color(0xFFFF6C90), Color(0xFF62B8FF)
];

enum GamePhase { ready, playing, paused, lost }
enum BrickKind { ordinary, stone, bomb, electric, gold, armored, prism, column }
enum BrickShape { rectangle, hexagon, diamond, triangle }
enum Weapon { machine, spread, laser, rocket }
enum DropKind { rapid, shield, heart, coins }

class Brick {
  Brick(this.x, this.y, this.kind, this.health, this.color,
    {this.width = brickWidth,this.height = brickHeight,
     this.shape = BrickShape.rectangle,this.tier = 0});
  double x, y;
  final BrickKind kind;
  int health;
  final Color color;
  final double width, height;
  final BrickShape shape;
  final int tier;
  bool acceptsHit(double px,double py){
    final u=(px-x)/width,v=(py-y)/height;
    if(u<0||u>1||v<0||v>1)return false;
    switch(shape){
      case BrickShape.rectangle: return true;
      case BrickShape.hexagon: return (u-.5).abs() <= .32+.18*(1-(v-.5).abs()*2);
      case BrickShape.diamond: return (u-.5).abs()+(v-.5).abs()<=.53;
      case BrickShape.triangle: return (u-.5).abs()<=.07+.44*v;
    }
  }
}

class Shot {
  Shot(this.x, this.y, this.vx, this.vy, this.damage, this.rocket);
  double x, y, vx, vy;
  final int damage;
  final bool rocket;
}

class Drop {
  Drop(this.x, this.y, this.kind);
  double x, y;
  DropKind kind;
  double phase = 0;
}

class Dust {
  Dust(this.x, this.y, this.vx, this.vy, this.life, this.color)
      : initial = life;
  double x, y, vx, vy, life;
  final double initial;
  final Color color;
}

class Ray {
  Ray(this.x1, this.y1, this.x2, this.y2, this.color, this.life)
      : initial = life;
  final double x1, y1, x2, y2;
  final Color color;
  double life;
  final double initial;
}

class Boss {
  Boss(this.health) : maximum = health;
  double x = 142, y = 82, vx = 70, health, maximum, attackTimer = 1.5;
}

class EnemyShot {
  EnemyShot(this.x, this.y, this.vx);
  double x, y, vx;
}

class BlockGame {
  BlockGame(this.sound) { reset(); }
  final void Function(String) sound;
  final random = Random();

  GamePhase phase = GamePhase.ready;
  final bricks = <Brick>[];
  final shots = <Shot>[];
  final drops = <Drop>[];
  final dust = <Dust>[];
  final rays = <Ray>[];
  final enemyShots = <EnemyShot>[];
  final unlocked = <Weapon>{Weapon.machine};
  final upgrades = <String,int>{'damage': 0, 'speed': 0, 'spread': 0};

  Boss? boss;
  Weapon weapon = Weapon.machine;
  int score = 0, coins = 120, lives = 5, level = 1, destroyed = 0;
  int total = 0, rowNumber = 0, power = 1, speedMode = 1;
  double gunX = 210, targetX = 210, elapsed = 0, shotClock = 0, speed = 65;
  double fever = 0, feverSeconds = 0, shieldSeconds = 0, rapidSeconds = 0;
  double invincibleSeconds = 0, pressure = 0;
  double recoil = 0, shake = 0, flash = 0, messageSeconds = 0;
  String message = '';
  bool auto = false, shopOpen = false;

  // Yeni geometriler: her 5 bölümde farklı ebat, kolon ve şekil.
  int get waveTier => (level-1) ~/ 5;
  int get waveColumns => [10,8,12,9][waveTier%4];
  double get waveHeight => [31.0,38.0,27.0,35.0][waveTier%4];
  double get wavePitch => waveHeight+4;
  BrickShape get waveShape => BrickShape.values[waveTier%4];
  String get waveName => switch(waveShape){
    BrickShape.rectangle=>'DİKDÖRTGEN',
    BrickShape.hexagon=>'ALTIGEN',
    BrickShape.diamond=>'ELMAS',
    BrickShape.triangle=>'ÜÇGEN',
  };
  int get goal => 150 + (level - 1) * 80;
  double get progress => boss != null
      ? (1 - boss!.health / boss!.maximum).clamp(0.0,1.0)
      : (destroyed / goal).clamp(0.0,1.0);
  double get feverProgress => feverSeconds > 0 ? 1 : fever / 100;

  void reset() {
    phase = GamePhase.ready;
    bricks.clear();shots.clear();drops.clear();dust.clear();rays.clear();
    enemyShots.clear();
    unlocked..clear()..add(Weapon.machine);
    upgrades['damage'] = 0;
    upgrades['speed'] = 0;
    upgrades['spread'] = 0;
    score = 0;coins = 120;lives = 5;level = 1;destroyed = 0;
    total = 0;rowNumber = 0;power = 1;
    gunX = 210;targetX = 210;elapsed = 0;shotClock = 0;speed = 65;
    fever = 0;feverSeconds = 0;shieldSeconds = 0;rapidSeconds = 0;
    invincibleSeconds = 0;pressure = 0;
    recoil = 0;shake = 0;flash = 0;messageSeconds = 0;
    message = '';auto = false;shopOpen = false;boss = null;
    weapon = Weapon.machine;
    for (var r = 0; r < 5; r++) { addRow(gridTop + r * wavePitch); }
  }

  void startOrPause() {
    if (shopOpen) return;
    if (phase == GamePhase.playing) {
      phase = GamePhase.paused;
    } else if (phase == GamePhase.lost) {
      reset();
      phase = GamePhase.playing;
      sound('start');
    } else {
      phase = GamePhase.playing;
      sound('start');
    }
  }

  void announce(String value, [double time = 1.6]) {
    message = value;
    messageSeconds = time;
  }

  void addRow(double y) {
    final row = rowNumber++;
    final columns=waveColumns;
    const gap=2.8;
    final width=(gameWidth-44-(columns-1)*gap)/columns;
    final height=waveHeight;
    for(var col=0;col<columns;col++){
      if(row%7==5 && col==(row*3)%columns)continue;
      final chance=random.nextDouble();
      // İlerleyen bölümlerde yeni bloklar ve giderek değişen dalga düzenleri.
      // Her yeni türün görünmesi bazı sıralarda garanti edilir.
      final BrickKind kind;
      if (level >= 4 && row % 4 == 0 && col == 4) {
        kind = BrickKind.column;
      } else if (level >= 3 && row % 3 == 0 && col == 6) {
        kind = BrickKind.prism;
      } else if (level >= 2 && row % 2 == 0 && col == 2) {
        kind = BrickKind.armored;
      } else if (level >= 4 && chance < .065) {
        kind = BrickKind.column;
      } else if (level >= 3 && chance < .13) {
        kind = BrickKind.prism;
      } else if (level >= 2 && chance < .21) {
        kind = BrickKind.armored;
      } else {
        kind = chance < .285 ? BrickKind.bomb
            : chance < .35 ? BrickKind.electric
            : chance < .46 ? BrickKind.gold
            : chance < .63 ? BrickKind.stone : BrickKind.ordinary;
      }
      final int health = switch(kind) {
        BrickKind.armored => 6 + min<int>(4, (level - 2) ~/ 2),
        BrickKind.stone => level > 3 ? 5 : 4,
        BrickKind.column => 2,
        BrickKind.prism => 2,
        BrickKind.ordinary => random.nextDouble() < .25 ? 2 : 1,
        _ => 1,
      };
      bricks.add(Brick(22+col*(width+gap),y,kind,
          health+waveTier*(kind==BrickKind.armored?2:1),
          brickPalette[(col+row~/2+waveTier)%brickPalette.length],
          width:width,height:height,shape:waveShape,tier:waveTier));
    }
  }

  void particles(double x, double y, Color color,
      [int count = 12, double force = 1]) {
    for (var i=0; i<count; i++) {
      final a = random.nextDouble() * pi * 2;
      final v = (35 + random.nextDouble() * 180) * force;
      dust.add(Dust(x,y,cos(a)*v,sin(a)*v,.25+random.nextDouble()*.45,color));
    }
    if (dust.length > 350) dust.removeRange(0,dust.length-350);
  }

  void energy(double value) {
    if (feverSeconds > 0) return;
    fever = (fever + value).clamp(0.0, 100.0);
    if (fever >= 100) {
      fever = 0;
      feverSeconds = 8;
      flash = .6;
      announce('FEVER MODU!', 2);
      sound('fever');
    }
  }

  void hitBrick(Brick brick, int damage, [int depth = 0]) {
    if (!bricks.contains(brick) || depth > 55) return;
    brick.health -= damage;
    energy(1.2);
    particles(brick.x+brick.width/2,brick.y+brick.height/2,brick.color,3,.5);
    if (brick.health <= 0) {
      destroyBrick(brick,depth);
    } else {
      sound('hit');
    }
  }

  void destroyBrick(Brick brick, [int depth = 0]) {
    if (depth > 55 || !bricks.remove(brick)) return;
    destroyed++;
    total++;
    score += (12 + level * 3) * (feverSeconds > 0 ? 2 : 1);
    coins += brick.kind == BrickKind.gold ? 28 : brick.kind == BrickKind.armored ? 12 : 3;
    final x = brick.x + brick.width/2, y = brick.y+brick.height/2;
    particles(x,y,brick.color,brick.kind == BrickKind.bomb?24:11);
    energy(brick.kind == BrickKind.stone ? 12 : 8);

    if (brick.kind == BrickKind.bomb) {
      sound('boom');shake = .35;flash = .22;
      for (final other in List<Brick>.of(bricks)) {
        final dx=other.x+other.width/2-x, dy=other.y+other.height/2-y;
        if (dx*dx+dy*dy < 69*69) hitBrick(other,2,depth+1);
      }
    } else if (brick.kind == BrickKind.electric) {
      sound('power');
      final nearest=List<Brick>.of(bricks);
      nearest.sort((a,b) {
        final da=pow(a.x+a.width/2-x,2)+pow(a.y+a.height/2-y,2);
        final db=pow(b.x+b.width/2-x,2)+pow(b.y+b.height/2-y,2);
        return da.compareTo(db);
      });
      for (final other in nearest.take(4)) {
        final ox=other.x+other.width/2,oy=other.y+other.height/2;
        final dx=ox-x,dy=oy-y;
        if (dx*dx+dy*dy<120*120) {
          rays.add(Ray(x,y,ox,oy,const Color(0xFFB2EEFF),.17));
          hitBrick(other,2,depth+1);
        }
      }
    } else if (brick.kind == BrickKind.column) {
      // Sütun kırıcı: aynı dikey hattaki yakın bloklara 2 hasar.
      sound('boom');flash=max(flash,.12);
      for (final other in List<Brick>.of(bricks)) {
        if ((other.x-brick.x).abs()<8 && (other.y-brick.y).abs()<wavePitch*4.3) {
          rays.add(Ray(x,y,other.x+other.width/2,
              other.y+other.height/2,const Color(0xFFFFAC72),.16));
          hitBrick(other,2,depth+1);
        }
      }
    } else if (brick.kind == BrickKind.prism) {
      energy(30);
      sound('power');
      announce('PRİZMA +30 FEVER');
    } else if (brick.kind == BrickKind.armored) {
      sound('hit');
    } else if (brick.kind == BrickKind.gold) {
      sound('coin');
    } else {
      sound('hit');
    }

    if (total%14==0 || random.nextDouble()<.085) {
      drops.add(Drop(x,y,DropKind.values[random.nextInt(DropKind.values.length)]));
    }
  }

  void hitBoss(double damage) {
    final b = boss;
    if (b == null) return;
    b.health -= damage;
    score += (damage * 2).round();
    shake = max(shake,.06);
    if (b.health <= 0) {
      particles(b.x+68,b.y+35,const Color(0xFFFFB373),65,2);
      sound('boom');
      coins += 150;
      score += 900;
      lives = min(5,lives+1);
      boss = null;
      enemyShots.clear();
      bricks.clear();
      level++;
      destroyed = 0;
      rowNumber=0;
      for (var r=0;r<5;r++) {addRow(gridTop+r*wavePitch);}
      announce('BOSS YENILDI! +150 ALTIN',2.5);
    }
  }

  void explode(double x,double y,double radius,int damage) {
    sound('boom');
    shake = .19;
    particles(x,y,const Color(0xFFFFBB7B),24,1.4);
    for (final b in List<Brick>.of(bricks)) {
      final dx=b.x+b.width/2-x,dy=b.y+b.height/2-y;
      if (dx*dx+dy*dy<radius*radius) hitBrick(b,damage);
    }
    final b=boss;
    if(b!=null) {
      final dx=b.x+68-x,dy=b.y+37-y;
      if(dx*dx+dy*dy < pow(radius+50,2)) hitBoss(damage*5.0);
    }
  }

  void shoot() {
    final int damage=1+upgrades['damage']!+min<int>(4,waveTier)+(power>=3?1:0)+(power==4?1:0)+(feverSeconds>0?1:0);
    recoil=1;
    if(weapon==Weapon.laser) {
      rays.add(Ray(gunX,gridTop-18,gunX,gunLine-40,const Color(0xFFA1FFFF),.14));
      final hits=bricks.where((b)=>b.acceptsHit(gunX,b.y+b.height*.58)).toList();
      hits.sort((a,b)=>b.y.compareTo(a.y));
      for (final b in hits.take(3+power+upgrades['spread']!)) {
        hitBrick(b,damage);
      }
      final b=boss;
      if(b!=null&&gunX>=b.x&&gunX<=b.x+136) hitBoss(damage*1.8);
      sound('laser');
      return;
    }
    final offsets=<double>[], velocities=<double>[];
    if(weapon==Weapon.machine) {
      final count=power==1?1:power==2?3:power==3?5:7;
      for(var i=0;i<count;i++){
        offsets.add((i-(count-1)/2)*9);velocities.add(0);
      }
      for(var i=1;i<=upgrades['spread']!;i++) {
        offsets.addAll([-24.0-i*8,24.0+i*8]);
        velocities.addAll([-12.0*i,12.0*i]);
      }
    } else if(weapon==Weapon.spread) {
      final count=5+power*2+upgrades['spread']!;
      for(var i=0;i<count;i++){
        offsets.add(0);velocities.add((i-(count-1)/2)*42);
      }
    } else {
      final count=power>=4?3:power>=2?2:1;
      for(var i=0;i<count;i++){
        offsets.add((i-(count-1)/2)*19);
        velocities.add((i-(count-1)/2)*28);
      }
    }
    for(var i=0;i<offsets.length;i++){
      shots.add(Shot((gunX+offsets[i]).clamp(5.0,415.0),
          gunLine-42,velocities[i],weapon==Weapon.rocket?-560:-950,
          damage,weapon==Weapon.rocket));
    }
    if(shots.length>220)shots.removeRange(0,shots.length-220);
    sound(weapon==Weapon.rocket?'rocket':'shot');
  }

  double fireInterval() {
    final base=switch(weapon) {
      Weapon.machine=>.098,Weapon.spread=>.29,
      Weapon.laser=>.16,Weapon.rocket=>.38
    };
    final result=base*[1.0,1.0,.87,.75,.68][power]*
      pow(.87,upgrades['speed']!)*pow(.93,min(5,waveTier))*(rapidSeconds > 0 ? 0.65 : 1.0)*(feverSeconds > 0 ? 0.72 : 1.0);
    return max(weapon == Weapon.rocket ? 0.14 : 0.042,result).toDouble();
  }

  void summonBoss() {
    bricks.clear();shots.clear();enemyShots.clear();rowNumber=0;
    boss=Boss(320.0+max(0,level-5)*50);
    addRow(212);addRow(247);
    announce('BOSS SAVASI!',2);sound('boss');
  }
  void bossDemo() {
    reset();level=5;coins=180;phase=GamePhase.playing;summonBoss();
  }
  void advance() {
    level++;destroyed=0;
    if(level%5==0) {
      summonBoss();
    } else {
      coins+=20;
      if((level-1)%5==0){
        rowNumber=0;
        announce('YENİ DALGA: '+waveName+' · SİLAH GÜÇLENDİ!',3);
        sound('power');
        return;
      }
      final newKind = switch(level) {
        2 => 'YENİ: ZIRHLI BLOKLAR!',
        3 => 'YENİ: FEVER PRİZMALARI!',
        4 => 'YENİ: SÜTUN KIRICILAR!',
        _ => 'BOLUM $level +20 ALTIN',
      };
      announce(newKind,2.4);
      sound('power');
    }
  }

  void fillRows() {
    if(bricks.isEmpty) {
      addRow(boss==null?gridTop:207);return;
    }
    var top=double.infinity;
    for(final b in bricks){top=min(top,b.y);}
    final minY=boss==null?gridTop:185.0;
    var count=0;
    while(top>=minY+wavePitch-.5 && count++<12) {
      top-=wavePitch;addRow(top);
    }
  }

  double desiredSpeed() {
    final density=(bricks.length/(waveColumns*10.5)).clamp(0.0,1.0);
    return (55+51*pow(1-density,1.3)+min(28,(level-1)*2.5)+waveTier*3)*
        [.78,1.0,1.28][speedMode];
  }

  void updatePower() {
    var bottom=gridTop;
    for(final b in bricks){bottom=max(bottom,b.y+b.height);}
    pressure=((bottom-(dangerLine-265))/265).clamp(0.0,1.0);
    final dangerPower=pressure>.80?4:pressure>.55?3:pressure>.27?2:1;
    power=max(dangerPower,min(4,waveTier+1));
  }

  void takeDrop(Drop p) {
    switch(p.kind) {
      case DropKind.rapid:rapidSeconds=9;announce('HIZLI ATES: 9 SN');
      case DropKind.shield:shieldSeconds=16;announce('KALKAN AKTIF');
      case DropKind.heart:lives=min(5,lives+1);announce('+1 CAN');
      case DropKind.coins:coins+=40;announce('+40 ALTIN');
    }
    sound('power');
  }

  void hurt() {
    if(invincibleSeconds>0)return;
    invincibleSeconds=1.2;
    if(shieldSeconds>0){
      shieldSeconds=0;announce('KALKAN KURTARDI');sound('hit');return;
    }
    lives--;shake=.7;flash=.5;sound('hurt');
    announce(lives>0?'-1 CAN':'OYUN BITTI');
    if(lives<=0){phase=GamePhase.lost;auto=false;}
  }

  void tick(double dt,{required bool left,required bool right,required bool fire}) {
    recoil=max(0,recoil-dt*11);shake=max(0,shake-dt*7);
    flash=max(0,flash-dt*2);messageSeconds=max(0,messageSeconds-dt);
    for(final p in List<Dust>.of(dust)){
      p.life-=dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=145*dt;
      if(p.life<=0)dust.remove(p);
    }
    for(final b in List<Ray>.of(rays)){
      b.life-=dt;if(b.life<=0)rays.remove(b);
    }
    if(phase!=GamePhase.playing||shopOpen)return;
    elapsed+=dt;
    feverSeconds=max(0,feverSeconds-dt);
    rapidSeconds=max(0,rapidSeconds-dt);
    shieldSeconds=max(0,shieldSeconds-dt);
    invincibleSeconds=max(0,invincibleSeconds-dt);

    if(auto) {
      Drop? pickup;
      for(final p in drops) {
        if(p.y>345&&p.y<gunLine&&(p.x-gunX).abs()<135){pickup=p;break;}
      }
      if(pickup!=null) {
        targetX=pickup.x;
      }else{
        Brick? selected;
        var best=-double.infinity;
        for(final b in bricks){
          final rating=b.y*1.5-(b.x+b.width/2-gunX).abs()*.08+
            ((b.kind==BrickKind.bomb||b.kind==BrickKind.electric)?36:0);
          if(rating>best){best=rating;selected=b;}
        }
        if(selected!=null)targetX=selected.x+selected.width/2;
        else if(boss!=null)targetX=boss!.x+68;
      }
    }else {
      if(left)targetX-=430*dt;
      if(right)targetX+=430*dt;
    }
    targetX=targetX.clamp(20.0,400.0);
    gunX+=(targetX-gunX)*min(1,dt*19);
    updatePower();
    // Basılı tutunca ateş; otomatik tarama ayrıca açılabilir.
    // Boşta geçen sürede mermiler birikmez.
    final interval=fireInterval();
    if(auto || fire) {
      shotClock+=dt;
      var count=0;
      while(shotClock>=interval&&count++<5) {shoot();shotClock-=interval;}
    } else {
      shotClock=min(shotClock,interval);
    }

    speed+=(desiredSpeed()-speed)*min(1,dt*3.5);
    final displacement=speed*dt;
    for(final b in bricks){b.y+=displacement;}

    final activeBoss=boss;
    if(activeBoss!=null){
      activeBoss.x+=activeBoss.vx*dt;
      if(activeBoss.x<20||activeBoss.x+136>400){
        activeBoss.vx=-activeBoss.vx;
        activeBoss.x=activeBoss.x.clamp(20.0,264.0);
      }
      activeBoss.attackTimer-=dt;
      if(activeBoss.attackTimer<=0){
        activeBoss.attackTimer=1.7;
        enemyShots.add(EnemyShot(activeBoss.x+68,activeBoss.y+74,
            (gunX-(activeBoss.x+68))*.34));
      }
    }
    for(final p in List<EnemyShot>.of(enemyShots)){
      p.x+=p.vx*dt;p.y+=220*dt;
      if(p.y>gunLine-15){
        if((p.x-gunX).abs()<28)hurt();
        enemyShots.remove(p);
      }
    }

    for(final p in List<Shot>.of(shots)){
      final previousY=p.y;
      p.x+=p.vx*dt;p.y+=p.vy*dt;
      Brick? target;
      var closest=-double.infinity;
      for(final b in bricks) {
        if(p.x>=b.x-3&&p.x<=b.x+b.width+3&&
            previousY>=b.y-3&&p.y<=b.y+b.height+3&&
            b.acceptsHit(p.x,b.y+b.height*.57)){
          if(b.y>closest){closest=b.y;target=b;}
        }
      }
      if(target!=null) {
        if(p.rocket) {
          explode(p.x,target.y+target.height,75,p.damage+2);
        } else {
          hitBrick(target,p.damage);
        }
        shots.remove(p);
      }else if(boss!=null&&p.x>=boss!.x&&p.x<=boss!.x+136&&
          previousY>=boss!.y&&p.y<=boss!.y+74){
        hitBoss(p.rocket?p.damage*6.0:p.damage.toDouble());
        if(p.rocket){sound('boom');particles(p.x,p.y,const Color(0xFFFFB87D),18);}
        shots.remove(p);
      }else if(p.y<37||p.x<0||p.x>gameWidth){
        shots.remove(p);
      }
    }

    for(final p in List<Drop>.of(drops)){
      p.y+=130*dt;p.phase+=4*dt;
      if(p.y>=gunLine-30&&(p.x-gunX).abs()<28){
        takeDrop(p);drops.remove(p);
      }else if(p.y>gameHeight)drops.remove(p);
    }

    fillRows();
    if(invincibleSeconds<=0&&bricks.any((b)=>b.y+b.height>=dangerLine)){
      final overdue=bricks.where((b)=>b.y+b.height>dangerLine-53).toList();
      for(final b in overdue){
        bricks.remove(b);
        particles(b.x,b.y,const Color(0xFFFF7190),5);
      }
      hurt();
    }
    updatePower();
    if(boss==null&&destroyed>=goal)advance();
  }

  int upgradePrice(String name){
    final n=upgrades[name]??0;
    return switch(name){
      'damage'=>65+n*65,'speed'=>55+n*55,'spread'=>70+n*65,_=>55};
  }
  int weaponPrice(Weapon w)=>switch(w){
    Weapon.machine=>0,Weapon.spread=>90,Weapon.laser=>110,Weapon.rocket=>140};
  bool purchaseWeapon(Weapon w){
    if(unlocked.contains(w)||coins<weaponPrice(w))return false;
    coins-=weaponPrice(w);unlocked.add(w);weapon=w;sound('coin');return true;
  }
  bool purchaseUpgrade(String key){
    if(key=='heal'){
      if(lives>=5||coins<55)return false;
      coins-=55;lives++;sound('coin');return true;
    }
    final n=upgrades[key]??0;
    final maxLevel=key=='spread'?3:4;
    final price=upgradePrice(key);
    if(n>=maxLevel||coins<price)return false;
    coins-=price;upgrades[key]=n+1;sound('coin');return true;
  }
}
