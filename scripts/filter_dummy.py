import re

with open('lib/data/song_catalog.dart', 'r', encoding='utf-8') as f:
    content = f.read()

dummy_ids = {
    'vt_exclusive_01', 'vt_exclusive_02',
    'vt_studio_hi', 'vt_studio_ka', 'vt_studio_te', 'vt_studio_ta', 'vt_studio_ml',
    'stream_fusion_01'
}

# Match Song definitions
songs = []
for block in re.split(r'\n\s*const Song\(', content)[1:]:
    id_match = re.search(r"id:\s*'([^']+)'", block)
    title_match = re.search(r"title:\s*'([^']+)'", block)
    is_playable = 'isPlayable: false' not in block
    if id_match and title_match:
        sid = id_match.group(1)
        title = title_match.group(1)
        is_dummy = sid in dummy_ids or not is_playable
        songs.append((sid, title, is_dummy))

print(f"Total songs: {len(songs)}")
dummies = [s for s in songs if s[2]]
print(f"Total dummy songs to remove: {len(dummies)}")
for s in dummies:
    print(f"  - {s[0]}: {s[1]}")
