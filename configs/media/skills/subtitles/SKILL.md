---
name: subtitles
description: Translates a video's subtitles on this machine with the `subtitles` command — yt-dlp fetches them, PLaMo translates them locally, and every timestamp stays as it was. Also translates a local .srt.
when_to_use: 動画の字幕を訳したいとき、字幕付きで内容を知りたいとき — 「この動画の字幕を日本語にして」「YouTube の字幕訳して」「この .srt を翻訳して」「字幕取って」。
---

# Subtitles

The `subtitles` command is installed wherever this skill is, together with
`yt-dlp` and `plamo-translate`; there is no need to look for them.

## Goal

- **Target:** one translated `.srt` for the video or file the user named.
- **Done when:**
  - the path `subtitles` printed exists;
  - it has as many cues as the source `.srt` next to it (`grep -c -- '-->'`);
  - each cue's timing line matches the source's, in order.
- **Report:** the path of the translated file, and which track it came from
  (uploaded subtitles, or YouTube's automatic captions).
- **Hand over:** nothing; a video with no captions at all is reported, not
  worked around.

## Run

```bash
subtitles "<video URL>"            # English subtitles into Japanese
subtitles path/to/talk.en.srt      # a local file, no download
subtitles -sub-lang ko -from Korean -to Japanese "<video URL>"
```

- For a URL, the fetched `.srt` and its translation `<title>.ja.srt` go to
  the current directory (`-dir` to change it). For a local file, the
  translation goes beside it.
- A URL copied from a playlist (`&list=…`) fetches only that one video.
- It takes roughly a quarter of the video's length on an M-series Mac,
  since every 20 subtitles load the model once. Run it in the background
  for a long video.
- `-from` and `-to` take plamo-translate's language names (`English`,
  `Japanese`, `Korean`, …); `-sub-lang` takes YouTube's code (`en`, `ko`).

## When it fails

- **"has neither … subtitles nor …-orig captions":** the video has no
  captions in that language. Say so; local transcription is not set up.
- **HTTP 429 from YouTube:** do not retry with `yt-dlp --sub-langs ja` or
  another player client. YouTube rate-limits its own translated captions,
  and `subtitles` already asks only for untranslated tracks. A 429 there
  is plain rate limiting; tell the user and wait.
- **plamo-translate errors:** run `plamo-translate --input hello --from
  English --to Japanese` once to see the model download or load error
  on its own.
