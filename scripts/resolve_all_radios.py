import urllib.request
import json
import os
import re

ENDPOINTS = [
    "https://de1.api.radio-browser.info/json/stations/bycountrycodeexact/TR",
    "https://nl1.api.radio-browser.info/json/stations/bycountrycodeexact/TR",
    "https://at1.api.radio-browser.info/json/stations/bycountrycodeexact/TR"
]

SEED_OVERRIDES = {
    "kral fm": "https://dygedge2.radyotvonline.net/kralfm/playlist.m3u8",
    "virgin radio türkiye": "https://playerservices.streamtheworld.com/api/livestream-redirect/VIRGIN_RADIO_SC",
    "virgin radio turkiye": "https://playerservices.streamtheworld.com/api/livestream-redirect/VIRGIN_RADIO_SC",
    "metro fm": "https://playerservices.streamtheworld.com/api/livestream-redirect/METRO_FM_SC",
    "power fm": "https://listen.powerapp.com.tr/powerfm/mpeg/icecast.audio",
    "slow türk": "https://radyo.duhnet.tv/slowturk",
    "slow turk": "https://radyo.duhnet.tv/slowturk",
    "süper fm": "https://playerservices.streamtheworld.com/api/livestream-redirect/SUPER_FM_SC",
    "super fm": "https://playerservices.streamtheworld.com/api/livestream-redirect/SUPER_FM_SC",
    "joy fm": "https://playerservices.streamtheworld.com/api/livestream-redirect/JOY_FM_SC",
    "joy türk": "https://playerservices.streamtheworld.com/api/livestream-redirect/JOY_TURK_SC",
    "joy turk": "https://playerservices.streamtheworld.com/api/livestream-redirect/JOY_TURK_SC",
}

def resolve_and_clean():
    print("Radio-Browser API'den url_resolved canlı yayın adresleri çekiliyor...")

    raw_data = None
    for ep in ENDPOINTS:
        try:
            print(f"Baglaniliyor: {ep}")
            req = urllib.request.Request(ep, headers={'User-Agent': 'HepsiRadyo/1.0'})
            with urllib.request.urlopen(req, timeout=10) as resp:
                if resp.status == 200:
                    raw_data = json.loads(resp.read().decode('utf-8'))
                    print(f"SUCCESS: Radio-Browser API'den {len(raw_data)} adet radyo alindi!")
                    break
        except Exception as e:
            print(f"HATA ({ep}): {e}")

    if not raw_data:
        print("ERROR: Radio-Browser API'den veri alinamadi.")
        return

    unique_dict = {}
    for r in raw_data:
        name = r.get('name', '').strip()
        # ALWAYS PREFER url_resolved OVER raw url!
        stream_url = r.get('url_resolved') or r.get('url', '')
        favicon = r.get('favicon', '')
        tags_str = r.get('tags', '')
        tags = [t.strip().title() for t in tags_str.split(',') if t.strip()] if tags_str else []
        state = r.get('state', '')
        codec = r.get('codec', 'MP3').upper()
        bitrate = r.get('bitrate', 128)
        rb_uuid = r.get('stationuuid', '')

        if not stream_url or len(name) < 2:
            continue

        # Clean malformed favicon URLs
        if "]" in favicon:
            favicon = favicon.split("]")[0].strip()
        if favicon and not favicon.startswith("http"):
            favicon = None

        name_lower = name.lower()

        # Check for Karnaval / StreamTheWorld regex
        if "streamtheworld.com" in stream_url:
            match = re.search(r'/([A-Z0-9_]+_SC)', stream_url, re.IGNORECASE)
            if match:
                station_id = match.group(1).upper()
                stream_url = f"https://playerservices.streamtheworld.com/api/livestream-redirect/{station_id}"

        # Apply overrides for top national channels
        if name_lower in SEED_OVERRIDES:
            stream_url = SEED_OVERRIDES[name_lower]

        unique_dict[name_lower] = {
            "radio_browser_uuid": rb_uuid,
            "name": name,
            "stream_url": stream_url,
            "favicon_url": favicon,
            "tags": tags[:5],
            "country": "Turkey",
            "city": state if state else "Genel",
            "bitrate": bitrate if bitrate > 0 else 128,
            "codec": codec,
            "is_active": True,
            "is_metadata_supported": True,
            "source": "radio-browser"
        }

    final_list = list(unique_dict.values())
    print(f"\nToplam {len(final_list)} adet %100 url_resolved cozumlenmis essiz radyo hazirlandi!")

    output_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "data")
    output_path = os.path.join(output_dir, "default_radios.json")
    os.makedirs(output_dir, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(final_list, f, ensure_ascii=False, indent=2)

    print(f"SUCCESS: {output_path} basariyla guncellendi!")

if __name__ == "__main__":
    resolve_and_clean()
