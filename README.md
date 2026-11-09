# Blok Kırma 🎮

**Teknolojix** tarafından geliştirilen Flutter arcade oyunu.

## Oynanış
- Yukarıdan sürekli, sık ve hızlanarak inen renkli bloklar
- Tehlike çizgisine yaklaştıkça güçlenen silah
- Zincirleme bomba ve elektrik patlamaları
- İlk bölümde normal, taş, altın, bomba ve elektrik blokları
- 2. bölümde zırhlı, 3. bölümde FEVER prizması, 4. bölümde sütun kırıcı bloklar
- 6–10: büyük altıgen, 11–15: küçük elmas, 16–20: üçgen bloklar; dalgalar döngüsel devam eder
- Yeni dalgalarda blokların gerçek isabet alanı, dayanıklılığı ve silahın temel gücü değişir
- Buz ve dondurma mekanikleri kaldırıldı
- Düşen güç kutuları (kalkan, hızlı ateş, can, altın)
- FEVER sistemi ve uzun, kesintisiz bölümler
- Dört silah: taramalı, saçmalı, lazer, roket
- 5. bölüm ve her 5 bölümde bir boss
- Altınla silah satın alma ve güçlendirme
- Oyun alanında kayma yapmayan dokunmatik kontrol: basılı tutarak ateş et, sürükleyerek nişan al, bırakınca dur
- İsteğe bağlı otomatik hedef tarama/ateş; oyun başlayınca kendiliğinden ateş etmez
- Türkçe arayüz
- Daha gerçekçi, döner namlulu metalik taramalı silah görseli ve kovan animasyonu
- Oyun paketine yerleştirilen gerçek silah atışı kayıtları (CC0); diğer arcade sesleri sentez

## Android APK ve AAB
Depoya gönderilen her güncellemede GitHub Actions Flutter ile derleme yapar.
Actions → Blok Kırma - Android APK ve AAB → Son çalıştırma → Artifacts
bölümünden ZIP indirilir; APK ve AAB dosyaları içindedir.

workflow_dispatch ile elle de derleme başlatılabilir.

## Önemli: imzalama
Otomatik Flutter Android şablonundaki release derleme varsayılanı test amaçlı
debug anahtarıdır. Google Play üretim yüklemesi için kalıcı, güvenli bir
release/upload keystore oluşturulmalı ve signing ayarları yapılmalıdır.
Anahtar dosyası ve parolalar depoya eklenmemelidir.
Bu ilk APK/AAB çıktıları test ve inceleme içindir.

## Yerel çalışma
Flutter SDK ile:

- flutter create --platforms=android --project-name blok_kirma --org com.teknolojix .
- bash tool/fetch_audio.sh (internet bağlantısı gerekir; CC0 sesleri indirilir)
- flutter pub get
- flutter run
- flutter test

Mağaza satın almaları prototipte oyun içi altınladır; gerçek ödeme sistemi yoktur.
İlerleme bu sürümde yalnızca açık oyun oturumunda saklanır.
