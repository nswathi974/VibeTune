import re

with open('lib/data/song_catalog.dart', 'r', encoding='utf-8') as f:
    content = f.read()

parts = re.split(r'(\n\s*const Song\([^;]+?\n\s*\),)', content)

# Header is before the first const Song(
header_idx = content.find('static final List<Song> _rawSongs = [')
if header_idx != -1:
    header = content[:header_idx + len('static final List<Song> _rawSongs = [')]
    rest = content[header_idx + len('static final List<Song> _rawSongs = ['):]
    footer_idx = rest.rfind('];')
    songs_part = rest[:footer_idx]
    footer = rest[footer_idx:]

    dummy_ids = {
        'vt_exclusive_01', 'vt_exclusive_02',
        'vt_studio_hi', 'vt_studio_ka', 'vt_studio_te', 'vt_studio_ta', 'vt_studio_ml',
        'stream_fusion_01'
    }

    raw_blocks = re.split(r'(?=\n\s*const Song\()', songs_part)
    kept_blocks = []
    removed_count = 0

    for b in raw_blocks:
        if not b.strip():
            continue
        id_m = re.search(r"id:\s*'([^']+)'", b)
        if id_m:
            sid = id_m.group(1)
            is_unplayable = 'isPlayable: false' in b
            if sid in dummy_ids or is_unplayable:
                removed_count += 1
                continue
        kept_blocks.append(b)

    new_content = header + ''.join(kept_blocks) + footer
    with open('lib/data/song_catalog.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Removed {removed_count} dummy songs. Kept {len(kept_blocks)} verified songs.")
