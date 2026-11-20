import re

with open('lib/data/song_catalog.dart', 'r', encoding='utf-8') as f:
    text = f.read()

pattern = re.compile(r'const Song\s*\((.*?)\),', re.DOTALL)
matches = pattern.findall(text)
print(f"Total current catalog songs: {len(matches)}")
for i, m in enumerate(matches, 1):
    sid = re.search(r"id:\s*'([^']+)'", m)
    title = re.search(r"title:\s*'([^']+)'", m)
    lang = re.search(r"language:\s*'([^']+)'", m)
    yt = re.search(r"youtubeVideoId:\s*'([^']+)'", m)
    norm = re.search(r"normalAudioPath:\s*'([^']+)'", m)
    karaoke = re.search(r"karaokeAudioPath:\s*([^,\n]+)", m)
    lyrics = re.search(r"lyricsPath:\s*([^,\n]+)", m)
    isKaraokeAvail = "isKaraokeAvailable: true" in m
    
    sid_val = sid.group(1) if sid else '?'
    t_val = title.group(1) if title else '?'
    l_val = lang.group(1) if lang else '?'
    yt_val = yt.group(1) if yt else '-'
    norm_val = norm.group(1) if norm else '-'
    k_val = karaoke.group(1) if karaoke else '-'
    ly_val = lyrics.group(1) if lyrics else '-'
    print(f"{i:2d}. [{l_val:8s}] {t_val:28s} | ID: {sid_val:10s} | YT: {yt_val:11s} | Norm: {norm_val[:20]:20s} | Karaoke: {k_val[:20]:20s} | KaraokeAvail: {isKaraokeAvail}")
