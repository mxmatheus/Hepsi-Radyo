import json
import os

INPUT_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "data", "default_radios.json")

def clean_and_deduplicate():
    if not os.path.exists(INPUT_PATH):
        print("Input file not found.")
        return

    with open(INPUT_PATH, "r", encoding="utf-8") as f:
        radios = json.load(f)

    print(f"Orijinal okunan radyo sayısı: {len(radios)}")

    unique_radios = {}
    for r in radios:
        name = r.get("name", "").strip()
        stream_url = r.get("stream_url", "").strip()

        if not name or not stream_url:
            continue

        # Clean malformed markdown links in favicon
        favicon = r.get("favicon_url") or ""
        if "]" in favicon:
            favicon = favicon.split("]")[0].strip()
        if favicon and not favicon.startswith("http"):
            favicon = None

        # Normalize key by lowercase name
        norm_key = name.lower()
        
        # If radio already exists, prefer the one with a valid favicon or seed source
        if norm_key in unique_radios:
            existing = unique_radios[norm_key]
            if not existing.get("favicon_url") and favicon:
                existing["favicon_url"] = favicon
            if existing.get("source") != "seed" and r.get("source") == "seed":
                unique_radios[norm_key] = r
        else:
            r["favicon_url"] = favicon
            unique_radios[norm_key] = r

    cleaned_list = list(unique_radios.values())
    print(f"Tekrarlayanlar temizlendi. Kalan temiz radyo sayısı: {len(cleaned_list)}")

    with open(INPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(cleaned_list, f, ensure_ascii=False, indent=2)

    print("default_radios.json başarıyla güncellendi!")

if __name__ == "__main__":
    clean_and_deduplicate()
