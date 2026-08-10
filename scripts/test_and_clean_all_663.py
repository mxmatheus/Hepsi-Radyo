import urllib.request
import urllib.parse
import json
import os
import concurrent.futures

def test_stream_url(radio):
    name = radio.get('name', '')
    url = radio.get('stream_url', '')
    if not url:
        return radio, False

    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'VLC/3.0.18 LibVLC/3.0.18'})
        with urllib.request.urlopen(req, timeout=3.5) as resp:
            if resp.status in (200, 206, 301, 302):
                return radio, True
    except Exception:
        pass

    return radio, False

def main():
    json_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'default_radios.json')
    with open(json_path, 'r', encoding='utf-8') as f:
        radios = json.load(f)

    total = len(radios)
    print(f"Toplam {total} adet radyo akis testi baslatiliyor (Concurrent threads)...")

    working_radios = []
    failed_radios = []

    with concurrent.futures.ThreadPoolExecutor(max_workers=30) as executor:
        futures = [executor.submit(test_stream_url, r) for r in radios]
        for future in concurrent.futures.as_completed(futures):
            radio, is_ok = future.result()
            if is_ok:
                working_radios.append(radio)
            else:
                failed_radios.append(radio)

    print(f"\nTest Sonuclari:")
    print(f"Calisan Radyo Sayisi: {len(working_radios)}")
    print(f"Baglanilamayan Radyo Sayisi: {len(failed_radios)}")

    # For failed radios, attempt Radio-Browser API lookup
    if failed_radios:
        print("\nCalismayan radyolar icin Radio-Browser API'den alternatif linkler araniyor...")
        resolved_fixes = 0

        for r in failed_radios:
            r_name = r.get('name', '').strip()
            if len(r_name) < 2:
                continue

            try:
                encoded_name = urllib.parse.quote(r_name)
                api_url = f"https://de1.api.radio-browser.info/json/stations/byname/{encoded_name}"
                req = urllib.request.Request(api_url, headers={'User-Agent': 'HepsiRadyo/1.0'})
                with urllib.request.urlopen(req, timeout=3) as resp:
                    candidates = json.loads(resp.read().decode('utf-8'))
                    for c in candidates:
                        alt_url = c.get('url_resolved') or c.get('url')
                        if alt_url and alt_url != r.get('stream_url'):
                            try:
                                alt_req = urllib.request.Request(alt_url, headers={'User-Agent': 'VLC/3.0.18'})
                                with urllib.request.urlopen(alt_req, timeout=3) as alt_resp:
                                    if alt_resp.status in (200, 206):
                                        r['stream_url'] = alt_url
                                        r['is_active'] = True
                                        working_radios.append(r)
                                        resolved_fixes += 1
                                        print(f"  [FIXED] {r_name} -> {alt_url}")
                                        break
                            except Exception:
                                continue
            except Exception:
                pass

        print(f"Alternatif link ile kurtarilan radyo sayisi: {resolved_fixes}")

    # Mark remaining failed radios as inactive
    all_radios_map = {r['name'].lower(): r for r in working_radios}
    for r in radios:
        n_low = r['name'].lower()
        if n_low in all_radios_map:
            r['stream_url'] = all_radios_map[n_low]['stream_url']
            r['is_active'] = True
        else:
            r['is_active'] = False

    active_count = sum(1 for r in radios if r.get('is_active'))
    print(f"\nFinal Dataset: Toplam {len(radios)} radyodan {active_count} tanesi aktif ve %100 calisiyor!")

    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(radios, f, ensure_ascii=False, indent=2)

    print(f"{json_path} basariyla guncellendi!")

if __name__ == '__main__':
    main()
