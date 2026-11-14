const fs = require('fs');

const content = fs.readFileSync('C:/vibetune/VibeTune/lib/data/song_catalog.dart', 'utf8');
const songBlocks = content.split(/const Song\s*\(/g).slice(1);

const songs = [];
for (const b of songBlocks) {
  const getId = b.match(/id:\s*'([^']+)'/);
  const getTitle = b.match(/title:\s*'([^']+)'/);
  const getArtist = b.match(/artist:\s*'([^']+)'/);
  const getLang = b.match(/language:\s*'([^']+)'/);
  const getPlayable = b.match(/isPlayable:\s*([^,\n]+)/);
  const getLyricsPath = b.match(/lyricsPath:\s*([^,\n]+)/);

  if (getId && getTitle && getArtist) {
    songs.push({
      id: getId[1],
      title: getTitle[1],
      artist: getArtist[1],
      language: getLang ? getLang[1] : 'Unknown',
      isPlayable: getPlayable ? getPlayable[1].trim() === 'true' : true,
      hasLocalLyrics: !!(getLyricsPath && getLyricsPath[1].trim() && getLyricsPath[1].trim() !== "''"),
    });
  }
}

console.log(`Auditing ${songs.length} songs against LRCLIB...`);

async function run() {
  const summary = {
    exactSynced: [],
    exactPlain: [],
    searchSynced: [],
    searchPlain: [],
    localOnly: [],
    notFound: []
  };

  for (let i = 0; i < songs.length; i++) {
    const s = songs[i];
    // First artist name only for cleaner search (e.g. "Arijit Singh, Pritam" -> "Arijit Singh")
    const primaryArtist = s.artist.split(/[,&]/)[0].trim();

    try {
      // 1. Try exact match
      const url = `https://lrclib.net/api/get?track_name=${encodeURIComponent(s.title)}&artist_name=${encodeURIComponent(primaryArtist)}`;
      const res = await fetch(url, { headers: { 'User-Agent': 'VibeTune-MCA-Audit/1.0' } });

      if (res.status === 200) {
        const data = await res.json();
        if (data.syncedLyrics) {
          summary.exactSynced.push({ id: s.id, title: s.title, artist: s.artist, lang: s.language });
          console.log(`[${i+1}/${songs.length}] EXACT SYNCED: "${s.title}" (${s.language})`);
          continue;
        } else if (data.plainLyrics) {
          summary.exactPlain.push({ id: s.id, title: s.title, artist: s.artist, lang: s.language });
          console.log(`[${i+1}/${songs.length}] EXACT PLAIN: "${s.title}" (${s.language})`);
          continue;
        }
      }

      // 2. Try search
      const sUrl = `https://lrclib.net/api/search?q=${encodeURIComponent(s.title + ' ' + primaryArtist)}`;
      const sRes = await fetch(sUrl, { headers: { 'User-Agent': 'VibeTune-MCA-Audit/1.0' } });
      if (sRes.status === 200) {
        const list = await sRes.json();
        const match = list.find(item => {
          const t = (item.trackName || '').toLowerCase();
          return t.includes(s.title.toLowerCase()) || s.title.toLowerCase().includes(t);
        });

        if (match && match.syncedLyrics) {
          summary.searchSynced.push({ id: s.id, title: s.title, artist: s.artist, match: match.trackName, lang: s.language });
          console.log(`[${i+1}/${songs.length}] SEARCH SYNCED: "${s.title}" -> "${match.trackName}" (${s.language})`);
          continue;
        } else if (match && match.plainLyrics) {
          summary.searchPlain.push({ id: s.id, title: s.title, artist: s.artist, match: match.trackName, lang: s.language });
          console.log(`[${i+1}/${songs.length}] SEARCH PLAIN: "${s.title}" -> "${match.trackName}" (${s.language})`);
          continue;
        }
      }

      if (s.hasLocalLyrics) {
        summary.localOnly.push({ id: s.id, title: s.title, lang: s.language });
        console.log(`[${i+1}/${songs.length}] LOCAL ASSET: "${s.title}" (${s.language})`);
      } else {
        summary.notFound.push({ id: s.id, title: s.title, lang: s.language });
        console.log(`[${i+1}/${songs.length}] NO LYRICS: "${s.title}" (${s.language})`);
      }
    } catch (err) {
      console.log(`[${i+1}/${songs.length}] ERR for "${s.title}": ${err.message}`);
    }

    // Gentle 100ms throttle
    await new Promise(r => setTimeout(r, 120));
  }

  console.log('\n=============================================');
  console.log('AUDIT SUMMARY:');
  console.log(`Total Songs: ${songs.length}`);
  console.log(`Exact Synced in LRCLIB: ${summary.exactSynced.length}`);
  console.log(`Search Synced in LRCLIB: ${summary.searchSynced.length}`);
  console.log(`Plain Lyrics in LRCLIB: ${summary.exactPlain.length + summary.searchPlain.length}`);
  console.log(`Local Verified Assets: ${summary.localOnly.length}`);
  console.log(`Total with Genuine Lyrics: ${summary.exactSynced.length + summary.searchSynced.length + summary.exactPlain.length + summary.searchPlain.length + summary.localOnly.length}`);
  console.log(`Missing Lyrics: ${summary.notFound.length}`);
  console.log('=============================================\n');
}

run();

