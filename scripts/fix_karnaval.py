import json
import re

path = 'assets/data/default_radios.json'
with open(path, 'r', encoding='utf-8') as f:
    radios = json.load(f)

updated_count = 0
for r in radios:
    url = r.get('stream_url', '')
    if 'streamtheworld.com' in url:
        match = re.search(r'/([A-Z0-9_]+_SC)', url, re.IGNORECASE)
        if match:
            station_id = match.group(1).upper()
            new_url = f'https://playerservices.streamtheworld.com/api/livestream-redirect/{station_id}'
            r['stream_url'] = new_url
            r['is_active'] = True
            updated_count += 1
            print(f"{r['name']} -> {new_url}")

# Ensure Seed radios are updated
seed_updates = {
    "Virgin Radio Türkiye": "https://playerservices.streamtheworld.com/api/livestream-redirect/VIRGIN_RADIO_SC",
    "Metro FM": "https://playerservices.streamtheworld.com/api/livestream-redirect/METRO_FM_SC",
    "Süper FM": "https://playerservices.streamtheworld.com/api/livestream-redirect/SUPER_FM_SC",
    "Joy FM": "https://playerservices.streamtheworld.com/api/livestream-redirect/JOY_FM_SC",
    "Joy Türk": "https://playerservices.streamtheworld.com/api/livestream-redirect/JOY_TURK_SC",
    "Kral FM": "https://dygedge2.radyotvonline.net/kralfm/playlist.m3u8",
    "Slow Türk": "https://radyo.duhnet.tv/slowturk",
    "Power FM": "https://listen.powerapp.com.tr/powerfm/mpeg/icecast.audio",
}

for r in radios:
    for name, s_url in seed_updates.items():
        if r['name'].lower() == name.lower():
            r['stream_url'] = s_url

with open(path, 'w', encoding='utf-8') as f:
    json.dump(radios, f, ensure_ascii=False, indent=2)

print(f"\nToplam {updated_count} adet Karnaval/StreamTheWorld radyosu resmi dinamik HTTPS linkine dönüştürüldü!")
