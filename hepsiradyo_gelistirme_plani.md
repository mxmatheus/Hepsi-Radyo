# HepsiRadyo — Geliştirme Planı ve Agent Prompt Serisi

## 1. Proje Özeti

**HepsiRadyo**, Radio-Browser API üzerinden Türkiye'deki tüm radyoları çeken, bu verileri kendi Supabase veritabanımızda tutup yönetebildiğimiz (ekleme/çıkarma/düzenleme), CORS sorunlarına takılmadan radyo metadatalarını (o an çalan şarkı bilgisi) full-screen player'da gösterebilen, premium ve elit tasarımlı bir Flutter radyo uygulamasıdır.

**Karar verilen yönler:**
- **Backend:** Supabase (Postgres + Auth + Edge Functions + Realtime)
- **Tema:** Sistemin light/dark moduna uyum sağlayan ama kendine özgü, premium bir renk paleti olan **tek** tema (Derin Sinyal / Sıcak Frekans gibi iki ayrı temaya bölünmüyor — bunun yerine tek kimlikli bir tema, sistem moduna göre iki görünüm sunuyor)
- **Top 50 verisi:** Supabase'de tutulur, cihazlar arası senkron, gerçek global sıralama

---

## 2. Teknoloji Yığını

| Katman | Teknoloji |
|---|---|
| Uygulama | Flutter (iOS, Android, Web) |
| State Management | Riverpod |
| Ses Motoru | just_audio + audio_service (arka plan çalma, lock screen kontrolleri, MediaSession) |
| Backend | Supabase (Postgres, Auth, Edge Functions, Realtime, Storage — logo barındırma için) |
| Metadata/CORS Proxy | Supabase Edge Function (Deno) — ICY metadata + Radio-Browser isteklerini proxy'ler |
| Veri Kaynağı | Radio-Browser API (ilk yükleme + periyodik senkron) |
| Yerel Cache | Hive veya sqflite (favoriler, son çalınanlar, offline liste cache'i) |
| Kimlik | Supabase Auth (anonim oturum — cihazı tanımlamak ve tıklama istatistiğini kullanıcıya değil cihaza/hesaba bağlamak için) |

**Neden Edge Function şart?** Tarayıcı (Flutter Web) veya bazı native senaryolarda radyo stream'inin ICY metadata'sını (`icy-metadata: 1` header'ı ile alınan "şu an çalan şarkı" bilgisini) doğrudan çekmek CORS'a takılır çünkü çoğu radyo sunucusu `Access-Control-Allow-Origin` döndürmez. Supabase Edge Function bu isteği sunucu tarafında yapıp bize temiz JSON döner, CORS sorunu tamamen ortadan kalkar.

---

## 3. Supabase Veritabanı Şeması

```sql
-- Radyolar
create table radios (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  stream_url text not null,
  favicon_url text,
  tags text[],               -- kategori/etiketler
  country text default 'Turkey',
  city text,
  bitrate int,
  codec text,
  is_active boolean default true,
  is_metadata_supported boolean default true, -- ICY metadata destekliyor mu
  source text default 'radio-browser',        -- 'radio-browser' | 'manual'
  radio_browser_uuid text,   -- orijinal kaynakla eşleştirme (merge/upsert için)
  sort_order int,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Kategoriler
create table categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon text,
  color text,
  sort_order int
);

create table radio_categories (
  radio_id uuid references radios(id) on delete cascade,
  category_id uuid references categories(id) on delete cascade,
  primary key (radio_id, category_id)
);

-- Cihaz/kullanıcı (anonim auth ile eşleşir)
create table devices (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid references auth.users(id),
  created_at timestamptz default now()
);

-- Favoriler
create table favorites (
  device_id uuid references devices(id) on delete cascade,
  radio_id uuid references radios(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (device_id, radio_id)
);

-- Tıklama/dinlenme kayıtları (Top 50 hesaplaması için ham veri)
create table radio_clicks (
  id bigint generated always as identity primary key,
  radio_id uuid references radios(id) on delete cascade,
  device_id uuid references devices(id),
  clicked_at timestamptz default now()
);

-- Performans için: günlük/haftalık/tüm zamanlar toplamlarını materialized view ya da
-- Edge Function ile periyodik hesaplayıp radio_stats tablosuna yazıyoruz.
create table radio_stats (
  radio_id uuid references radios(id) on delete cascade,
  period text not null,       -- 'daily' | 'weekly' | 'all_time'
  click_count int default 0,
  rank int,
  period_start date,          -- daily/weekly için pencere başlangıcı
  updated_at timestamptz default now(),
  primary key (radio_id, period, period_start)
);
```

> Not: `radio_clicks` çok büyüyeceği için 30-90 gün sonrasını temizleyen bir cron (Supabase Scheduled Edge Function) ekleyeceğiz. `radio_stats` zaten özet tuttuğu için tarihçe kaybolmaz.

---

## 4. Tema Sistemi

- **Tek kimlik, iki görünüm:** Marka rengi olarak koyu, doygun bir **British Racing Green** (`#0B3D2E` civarı) + vurgu rengi olarak derin bir **Wine Red / Bordeaux** (`#6B1E2B` civarı) ikilisi kullanılır. Light modda arka plan sıcak ivory/krem tonlarda (`#F4F1EA` gibi, saf beyaz değil), dark modda British Racing Green'in neredeyse siyaha yakın en koyu tonu (`#0A1F17` gibi) temel arka plan olur, wine red ise vurgu/aksiyon rengi (aktif sekme, play butonu, rozet vb.) olarak kullanılır. Sistem temasını takip eder ama Material'ın vanilya light/dark'ından çok daha kimlikli, "İngiliz klasik otomobili / özel kulüp" hissi veren bir palet.
- **Cam/Glass efektleri:** Navigasyon barı ve player arka planı için blur + saydamlık (`BackdropFilter`), albüm kapağı/logo renklerinden dinamik gradient (Palette generator ile logodan renk çıkarımı) — her radyo kendine has bir "ambiyans" rengiyle player'ı boyar, ancak bu dinamik renk her zaman British Racing Green/Wine Red tabanının üzerine yumuşak bir overlay olarak biner, temel kimliği ezmez.
- **Tipografi:** Başlıklarda daha karakterli, hafif serif dokunuşlu bir display font (klasik/elit hissi güçlendirir), içerikte okunabilir bir grotesk — premium/elit hissi tipografiden de gelmeli.
- **Mikro animasyonlar:** Play/pause geçişleri, eşitleyici çubuğu animasyonu, kart hover/basılı durumları.

---

## 5. Navigasyon — Floating Pill Bar

- Ekranın altında sabit, kenarlardan boşluklu, glass efektli bir "hap" (pill) şeklinde menü.
- Aşağı scroll → küçülür/daralır (sadece ikonlar, veya tamamen collapse olup küçük bir dot'a iner — Apple'ın yeni tab bar davranışına benzer).
- Yukarı scroll veya sayfa tepesine dönünce → tekrar genişler (etiketli, tam boy).
- Alt player (mini player) çalıyorsa, pill bar'ın hemen üstünde ayrı bir "Dynamic Island" tarzı mini player kapsülü belirir; ona dokununca full-screen player açılır.
- 5 sekme: **Ana Sayfa, Top 50, Kategoriler, Favoriler, Ayarlar**

---

## 6. Sayfa Detayları

### Ana Sayfa
- Üstte sponsorlu banner carousel (otomatik kayan, dot indicator)
- "Trend Radyolar" yatay kaydırmalı bölüm (Top 50'nin ilk birkaçı)
- Kategori grid'i (kısayol olarak)
- "Son Dinlenenler" bölümü

### Top 50
- Üstte segment control: **Günlük / Haftalık / Tüm Zamanlar**
- Liste maksimum 10 radyo gösterir (spesifikasyona göre — istersen tamamı 50'ye çıkarılabilir, şu an 10 ile sınırlı tuttum, sen onayla)
- Sıralama `radio_stats` tablosundan, cihazın attığı `radio_clicks` event'lerinin Supabase'de toplanmasıyla oluşur
- Başlangıçta boş/az veri olacağı için "Henüz yeterli veri yok" placeholder + mevcut olanları göster

### Kategoriler
- Grid halinde kategori kartları (Haber, Müzik türleri, Yerel, vs. — Radio-Browser tag'lerinden türetilir + biz manuel düzenleriz)
- Kategoriye tıklanınca o kategoriye ait radyo listesi

### Favoriler
- Kullanıcının kalp attığı radyolar, Supabase'de `favorites` tablosunda (cihaz/hesap bazlı, çoklu cihazda senkron)

### Ayarlar
- Tema tercihi (sistem/açık/koyu — opsiyonel override)
- Ses kalitesi tercihi (varsa birden fazla bitrate seçeneği)
- Uyku zamanlayıcı varsayılanı
- Bildirim tercihleri
- Uygulama hakkında / versiyon

### Full-Screen Player
- Albüm kapağı yerine radyo logosu + logo renginden türetilmiş dinamik arka plan gradyanı
- **Şarkı bilgisi:** Edge Function üzerinden çekilen ICY metadata (`icy-title` → sanatçı/şarkı ayrıştırma), periyodik polling (örn. 15sn) veya stream destekliyorsa gerçek zamanlı
- Metadata desteklemeyen radyolarda sadece radyo adı/sloganı gösterilir (bu yüzden `is_metadata_supported` alanı var)
- Play/pause, ses seviyesi, favori butonu, paylaş butonu, uyku zamanlayıcı kısayolu

---

## 7. Ek Özellik Önerileri (Sen Karar Ver)

Bunlardan istediklerini işaretle, prompt serisine dahil edelim:

1. **Lock screen / kontrol merkezi medya kontrolleri** (audio_service ile — neredeyse zorunlu, radyo appleri için standart) ++
2. **Uyku zamanlayıcı** (zaten planında var, dahil ediyorum) ++
3. **Chromecast / AirPlay desteği** (orta-zor, ayrı bir prompt bloğu gerektirir)
4. **Android Auto / CarPlay** (ileri seviye, ayrı faz olarak önerilir) ++
5. **"Benzer radyolar" önerisi** (aynı kategori/tag'e göre basit öneri motoru) ++
6. **Rozet/başarım sistemi** (ör. "100 saat dinleme", "10 farklı radyo keşfet" — hafif gamification, elit hissi güçlendirebilir) ++
7. **Push bildirim** (favori radyoda özel yayın/duyuru gibi bir şey varsa — şu an için gerekli değilse atlanabilir) ++
8. **Widget desteği** (ana ekran widget'ı ile hızlı radyo açma) ++
9. **Arama** (radyo adı, şehir, tag bazlı — Top 50/Kategoriler'e ek olarak mutlaka olmalı, prompt serisine dahil ettim) ++
10. **Basit admin paneli** — Supabase Studio zaten CRUD yapmana izin veriyor ama istersen uygulama içine gizli bir "Yönetici Modu" (belirli bir gesture/pin ile açılan) ekleyip radyo ekleme/düzenleme/silmeyi orada da yapabiliriz. **Bunu yapalım mı yoksa Supabase Studio yeterli mi?** Basit admin paneli olmalı.

---

## 8. Agent Prompt Serisi

Aşağıdaki promptlar sırasıyla bir AI ajanına (Claude Code vb.) verilmek üzere tasarlanmıştır. Her prompt bir öncekinin çıktısı üzerine inşa eder.

### Prompt 0 — Proje İskeleti ve Klasör Yapısı
```
HepsiRadyo adında yeni bir Flutter projesi oluştur. iOS, Android ve Web hedeflerini destekleyecek şekilde yapılandır.
Klasör yapısını feature-first mimariyle kur: lib/core, lib/features/{home,top50,categories,favorites,settings,player}, lib/shared.
Riverpod, go_router, just_audio, audio_service, supabase_flutter, hive, hive_flutter, cached_network_image paketlerini pubspec.yaml'a ekle.
main.dart'ta Riverpod ProviderScope, Hive init ve Supabase init iskeletini (env değişkenleri ile) hazırla ama henüz gerçek Supabase anahtarlarını yazma, .env / --dart-define yapısını kur.
```

### Prompt 1 — Supabase Şeması
```
Supabase projesi için şu SQL şemasını migration dosyası olarak oluştur: radios, categories, radio_categories, devices, favorites, radio_clicks, radio_stats tabloları (yukarıdaki şema — [şemayı buraya yapıştır]).
Row Level Security politikaları ekle: radios ve categories herkese okunabilir (anon read), favorites ve radio_clicks sadece kendi device_id'sine yazabilir/okuyabilir.
radio_stats tablosunu hesaplayan bir Postgres fonksiyonu + bunu günlük/saatlik çalıştıracak bir Supabase Scheduled Function (cron) tanımla.
```

### Prompt 2 — Radio-Browser Veri Çekme ve Aktarma Scripti
```
Python ile Radio-Browser API'den Türkiye'deki tüm radyoları çeken, mevcut Python scriptimi (Türkçe karakter uyumlu casing düzeltmesi içeren) referans alarak genişleten bir script yaz.
Script şunu yapmalı: Radio-Browser'dan veri çek → normalize et (isim, tag, favicon, bitrate, codec) → radio_browser_uuid alanına göre Supabase'deki radios tablosuna upsert et (merge stratejisi: elimizde zaten manuel düzenlenmiş bir kayıt varsa onun is_active, tags, sort_order gibi alanlarını EZME, sadece stream_url/bitrate gibi teknik alanları güncelle).
Script'i tekrar tekrar çalıştırılabilir (idempotent) yap ve çalıştırma sonunda kaç kayıt eklendi/güncellendi/atlandı raporla.
```

### Prompt 3 — Supabase Edge Function: CORS-Safe Metadata Proxy
```
Deno tabanlı bir Supabase Edge Function yaz: get-stream-metadata.
Bu fonksiyon bir radio stream URL'i parametre olarak alır, sunucu tarafında Icy-MetaData: 1 header'ı ile isteği açar, ICY metadata bloğunu parse eder (StreamTitle içinden sanatçı - şarkı ayrıştırması yap, "Artist - Title" formatını böl).
CORS header'larını (Access-Control-Allow-Origin: *) fonksiyon cevabına ekle ki Flutter Web'den sorunsuz çağrılabilsin.
Metadata bulunamazsa veya stream ICY desteklemiyorsa temiz bir { supported: false } cevabı dön ve radios tablosundaki is_metadata_supported alanını buna göre güncelleyecek ayrı bir yardımcı fonksiyon/endpoint de ekle.
```

### Prompt 4 — Tema Sistemi
```
Flutter'da tek kimlikli, sistem light/dark moduna uyan ama kendine özgü premium bir tema sistemi kur (ThemeExtension kullan).
Renk paleti: British Racing Green (#0B3D2E civarı) marka rengi + Wine Red/Bordeaux (#6B1E2B civarı) vurgu rengi, light modda sıcak ivory/krem (#F4F1EA civarı) arka planlar, dark modda British Racing Green'in en koyu tonu (#0A1F17 civarı) arka planlar.
Glassmorphism yardımcı widget'ları (BlurredContainer gibi) oluştur. Tipografi için Google Fonts'tan hafif serif dokunuşlu, karakterli bir display font + okunabilir bir grotesk seç ve TextTheme'i tanımla.
Radyo logosundan dominant renk çıkarıp o rengi player arka planına gradyan olarak, British Racing Green/Wine Red tabanının üzerine yumuşak bir overlay şeklinde uygulayan bir yardımcı fonksiyon (palette_generator paketiyle) yaz.
```

### Prompt 5 — Floating Pill Navigation Bar
```
Alt navigasyon için Apple'ın yeni scroll-morphing tab bar tasarımına benzer bir floating pill widget'ı oluştur.
Davranış: sayfa yukarı scroll edilirken (kullanıcı aşağı kaydırırken) bar daralıp sadece ikonlara/küçük bir kapsüle iner, scroll yukarı yönde veya idle olduğunda tam boy (ikon+etiket) haline geri döner.
5 sekmeyi (Ana Sayfa, Top 50, Kategoriler, Favoriler, Ayarlar) go_router ile bağla, aktif sekmeyi vurgula.
Bir radyo çalarken pill bar'ın hemen üstünde görünen, dokununca full-screen player'ı açan mini "Dynamic Island" tarzı bir player kapsülü ekle.
```

### Prompt 6 — Ana Sayfa
```
Ana Sayfa'yı oluştur: üstte otomatik kayan sponsorlu banner carousel (dot indicator ile), "Trend Radyolar" yatay liste (Top 50'nin ilk 5-6'sı), kategori kısayolları grid'i, "Son Dinlenenler" bölümü (Hive'dan okunur).
Tüm veri Riverpod provider'ları üzerinden Supabase'den (radios, radio_stats join) çekilsin, loading/error state'leri şık skeleton loader'larla gösterilsin.
```

### Prompt 7 — Kategoriler Sayfası
```
Kategoriler sayfasını grid layout ile oluştur, her kategori kartında ikon+renk+radyo sayısı göster.
Kategoriye tıklanınca o kategoriye ait radyoların listelendiği bir alt sayfa aç (radio_categories join sorgusu ile).
```

### Prompt 8 — Radyo Kartı, Mini Player ve Ses Motoru
```
just_audio + audio_service ile arka planda çalabilen, lock screen/kontrol merkezi entegrasyonlu bir AudioPlayerService oluştur (Riverpod provider olarak expose et).
Ortak bir RadioCard widget'ı yaz (logo, isim, çalıyor animasyonu). Karta tıklanınca: (1) çalmayı başlat, (2) radio_clicks tablosuna bir kayıt at (device_id ile), (3) mini player'ı güncelle.
```

### Prompt 9 — Full-Screen Player ve Metadata Gösterimi
```
Full-screen player ekranını oluştur: radyo logosu, dinamik gradyan arka plan (logodan çıkarılan renk), play/pause, ses seviyesi, favori, paylaş, uyku zamanlayıcı kısayolu.
Prompt 3'te yazdığımız get-stream-metadata Edge Function'ını periyodik (15sn) polling ile çağırıp "şu an çalıyor" alanını güncelle; is_metadata_supported false ise bu alanı gizle ve yerine radyo sloganını göster.
Şarkı değiştiğinde yumuşak bir crossfade/slide animasyonu uygula.
```

### Prompt 10 — Favoriler
```
Favoriler sayfasını oluştur, Supabase favorites tablosuna bağlı (cihaz/hesap bazlı senkron). Favori ekleme/çıkarma optimistic UI ile anında yansısın, arka planda Supabase'e yazılsın.
Boş durumda "Henüz favori radyon yok" şık bir empty state göster.
```

### Prompt 11 — Top 50 Sayfası ve İstatistik Mantığı
```
Top 50 sayfasını oluştur: Günlük / Haftalık / Tüm Zamanlar segment control'ü, radio_stats tablosundan period'a göre filtrelenmiş, rank'e göre sıralı maksimum 10 kayıt listelensin.
Her radyo kartında sıralama numarası, dinleme sayısı (opsiyonel) ve bir önceki periyoda göre yükseliş/düşüş oku (varsa) gösterilsin.
Veri azken/boşken placeholder state tasarla.
```

### Prompt 12 — Arama
```
Üst bar'a veya ayrı bir sekmeye radyo adı, şehir, tag bazlı arama ekle (Supabase full-text search veya basit ilike sorgusu ile). Debounce'lu arama input'u ve sonuç listesi oluştur.
```

### Prompt 13 — Ayarlar Sayfası
```
Ayarlar sayfasını oluştur: tema override (sistem/açık/koyu), uyku zamanlayıcı varsayılan süresi, bildirim tercihi toggle'ları, uygulama hakkında/versiyon bilgisi, (varsa) hesap/cihaz bilgisi.
```

### Prompt 14 — Uyku Zamanlayıcı
```
Player'a uyku zamanlayıcı özelliği ekle: kullanıcı süre seçer (15/30/45/60dk veya "bölüm sonu" gibi bir seçenek), süre dolunca ses kademeli fade-out ile durur. Zamanlayıcı aktifken player'da geri sayım göstergesi olsun.
```

### Prompt 15 — Offline/Cache ve Performans
```
Radyo listesini ve favorileri Hive ile local cache'le, internet yokken son bilinen listeyi göster (stream çalınamayacağı için uyarı göster ama UI çökmesin).
Logo görsellerini cached_network_image ile cache'le. Supabase sorgularına basit bir stale-while-revalidate stratejisi uygula.
```

### Prompt 16 — Cilalama (Polish) ve Mikro Animasyonlar
```
Tüm sayfalara geçiş animasyonları, play/pause buton animasyonu, eşitleyici çubuğu animasyonu (çalarken), kart basılı/hover durumları ekle. Haptic feedback (tıklamalarda hafif titreşim) ekle.
Genel tutarlılık kontrolü yap: spacing, border-radius, gölge değerlerini bir design token dosyasında (app_theme_tokens.dart) merkezileştir.
```

### Prompt 17 — Test, İkon, Splash ve Yayın Hazırlığı
```
Uygulama ikonu ve splash screen'i (flutter_launcher_icons, flutter_native_splash) tema paletine uygun şekilde oluştur.
Kritik akışlar için widget testleri yaz (radyo çalma, favori ekleme, top50 listesi render). Android/iOS build ayarlarını (permissions: internet, background audio) kontrol et.
```

---

## 9. Karar Bekleyen Açık Nokta

- **Admin paneli:** Uygulama içine gizli bir yönetici modu eklensin mi, yoksa radyo ekleme/çıkarma/düzenleme işlemlerini doğrudan Supabase Studio üzerinden mi yapacaksın? Cevabına göre Prompt serisine bir "Prompt 18 — Admin Modu" ekleyebilirim.
