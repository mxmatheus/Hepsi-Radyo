import urllib.request
import json
import os
import sys
import argparse
from resolve_all_radios import resolve_and_clean, SEED_OVERRIDES

SEED_RADIOS = [
    {
        "radio_browser_uuid": "seed-kral-fm",
        "name": "Kral FM",
        "stream_url": "https://dygedge2.radyotvonline.net/kralfm/playlist.m3u8",
        "favicon_url": "https://upload.wikimedia.org/wikipedia/tr/6/6f/Kral_FM_logo.png",
        "tags": ["Arabesk", "Pop", "Damar"],
        "country": "Turkey",
        "city": "İstanbul",
        "bitrate": 128,
        "codec": "AAC",
        "is_active": True,
        "is_metadata_supported": True,
        "source": "seed"
    },
    {
        "radio_browser_uuid": "seed-virgin-radio",
        "name": "Virgin Radio Türkiye",
        "stream_url": "https://playerservices.streamtheworld.com/api/livestream-redirect/VIRGIN_RADIO_SC",
        "favicon_url": "https://i.karnavalcdn.com/media/site_media/icons/android-icon-192x192.png",
        "tags": ["Pop", "Rock", "Yabancı Hits"],
        "country": "Turkey",
        "city": "İstanbul",
        "bitrate": 128,
        "codec": "MP3",
        "is_active": True,
        "is_metadata_supported": True,
        "source": "seed"
    },
    {
        "radio_browser_uuid": "seed-metro-fm",
        "name": "Metro FM",
        "stream_url": "https://playerservices.streamtheworld.com/api/livestream-redirect/METRO_FM_SC",
        "favicon_url": "https://i.karnavalcdn.com/media/site_media/icons/android-icon-192x192.png",
        "tags": ["Yabancı Pop", "Hit"],
        "country": "Turkey",
        "city": "İstanbul",
        "bitrate": 128,
        "codec": "MP3",
        "is_active": True,
        "is_metadata_supported": True,
        "source": "seed"
    },
    {
        "radio_browser_uuid": "seed-power-fm",
        "name": "Power FM",
        "stream_url": "https://listen.powerapp.com.tr/powerfm/mpeg/icecast.audio",
        "favicon_url": "https://www.powerapp.com.tr/assets/images/radios/powerFm.png",
        "tags": ["Yabancı Pop", "Hit", "Dance"],
        "country": "Turkey",
        "city": "İstanbul",
        "bitrate": 128,
        "codec": "AAC",
        "is_active": True,
        "is_metadata_supported": True,
        "source": "seed"
    },
    {
        "radio_browser_uuid": "seed-slow-turk",
        "name": "Slow Türk",
        "stream_url": "https://radyo.duhnet.tv/slowturk",
        "favicon_url": "https://www.slowturk.com.tr/favicon.ico",
        "tags": ["Aşk Şarkıları", "Slow Pop", "Türkçe"],
        "country": "Turkey",
        "city": "İstanbul",
        "bitrate": 128,
        "codec": "MP3",
        "is_active": True,
        "is_metadata_supported": True,
        "source": "seed"
    },
    {
        "radio_browser_uuid": "seed-super-fm",
        "name": "Süper FM",
        "stream_url": "https://playerservices.streamtheworld.com/api/livestream-redirect/SUPER_FM_SC",
        "favicon_url": "https://www.superfm.com.tr/favicon.ico",
        "tags": ["Türkçe Pop", "Hit"],
        "country": "Turkey",
        "city": "İstanbul",
        "bitrate": 128,
        "codec": "AAC",
        "is_active": True,
        "is_metadata_supported": True,
        "source": "seed"
    }
]

def parse_env_file():
    env_vars = {}
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    if os.path.exists(env_path):
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, val = line.split("=", 1)
                    env_vars[key.strip()] = val.strip().strip("'").strip('"')
    return env_vars

def fetch_and_clean_radios(target_url=None, target_key=None, clean_old=True):

    output_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "data")
    output_path = os.path.join(output_dir, "default_radios.json")

    with open(output_path, "r", encoding="utf-8") as f:
        radios = json.load(f)

    radios_dict = {r["radio_browser_uuid"]: r for r in radios}
    for s in SEED_RADIOS:
        radios_dict[s["radio_browser_uuid"]] = s
        for r in radios:
            if r.get("name", "").lower() == s["name"].lower():
                r["stream_url"] = s["stream_url"]
                r["favicon_url"] = s["favicon_url"]

    result_list = [r for r in radios_dict.values() if r.get("is_active", True) is not False]
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(result_list, f, ensure_ascii=False, indent=2)

    print(f"Aktarılacak toplam doğrulanmış aktif radyo sayısı: {len(result_list)}")

    env_file_vars = parse_env_file()
    supabase_url = target_url or os.environ.get("SUPABASE_URL") or env_file_vars.get("SUPABASE_URL")
    supabase_key = target_key or os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_ANON_KEY") or env_file_vars.get("SUPABASE_SERVICE_ROLE_KEY") or env_file_vars.get("SUPABASE_ANON_KEY")

    if supabase_url and supabase_key:
        print(f"\nSupabase bağlantısı kuruluyor ({supabase_url})...")
        
        if clean_old:
            try:
                print("Eski radyo kayıtları Supabase'den temizleniyor...")
                delete_endpoint = f"{supabase_url.rstrip('/')}/rest/v1/radios?id=not.is.null"
                delete_req = urllib.request.Request(
                    delete_endpoint,
                    headers={
                        "apikey": supabase_key,
                        "Authorization": f"Bearer {supabase_key}"
                    },
                    method="DELETE"
                )
                with urllib.request.urlopen(delete_req) as del_resp:
                    print("✅ Eski radyo verileri başarıyla silindi!")
            except Exception as del_err:
                print(f"⚠️ Temizleme Uyarısı: {del_err}")

        print("Güncellenmiş temiz radyolar Supabase veritabanınıza yükleniyor...")
        try:
            headers = {
                "apikey": supabase_key,
                "Authorization": f"Bearer {supabase_key}",
                "Content-Type": "application/json",
                "Prefer": "resolution=merge-duplicates"
            }
            target_endpoint = f"{supabase_url.rstrip('/')}/rest/v1/radios"
            
            batch_size = 100
            success_count = 0
            for i in range(0, len(result_list), batch_size):
                batch = result_list[i:i+batch_size]
                req = urllib.request.Request(
                    target_endpoint,
                    data=json.dumps(batch).encode('utf-8'),
                    headers=headers,
                    method="POST"
                )
                with urllib.request.urlopen(req) as resp:
                    if resp.status in (200, 201):
                        success_count += len(batch)
                        print(f"Paket {i//batch_size + 1} aktarıldı ({len(batch)} radyo). Durum: {resp.status}")
            print(f"\n🎉 HARİKA! Toplam {success_count} adet temiz url_resolved radyo Supabase veritabanınıza başarıyla yüklendi!")
        except Exception as err:
            print(f"❌ Supabase aktarım hatası: {err}")
    else:
        print("\nNot: SUPABASE_URL veya SUPABASE_SERVICE_ROLE_KEY girilmedi.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="HepsiRadyo Sync Script")
    parser.add_argument("--url", help="Supabase Project URL")
    parser.add_argument("--key", help="Supabase Service Role Key or Anon Key")
    args = parser.parse_args()
    
    fetch_and_clean_radios(target_url=args.url, target_key=args.key)
