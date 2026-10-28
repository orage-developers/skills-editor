# FFmpeg

Cutting, conversion, scaling, compression, audio extraction and export preparation. Always inspect before editing and re-inspect after.

## Inspect

```bash
ffprobe -v error -show_entries format=duration,bit_rate:stream=index,codec_type,codec_name,width,height,r_frame_rate,pix_fmt,sample_rate,channels -of compact in.mp4
```

Note variable frame rate (phone footage), rotation metadata and audio sample rate before cutting.

## Cut

```bash
# Frame-accurate cut (re-encode). Use for anything that ships.
ffmpeg -ss 12.40 -to 18.90 -i in.mp4 -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k cut.mp4

# Fast rough cut (stream copy, snaps to keyframes). Previews only.
ffmpeg -ss 12.4 -to 18.9 -i in.mp4 -c copy rough.mp4
```

Cut on word boundaries from the transcript, with 40–80 ms of padding so consonants aren't clipped.

## Normalize sources

```bash
# Constant 30 fps, square pixels, standard color, 48 kHz audio
ffmpeg -i in.mov -vf "fps=30,setsar=1,format=yuv420p" -c:v libx264 -crf 18 -c:a aac -ar 48000 norm.mp4
```

## Reframe

```bash
# 16:9 → 9:16 center crop
ffmpeg -i in.mp4 -vf "crop=ih*9/16:ih,scale=1080:1920" -c:a copy vertical.mp4

# 16:9 → 9:16 with blurred background fill
ffmpeg -i in.mp4 -filter_complex \
 "[0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=30:5[bg]; \
  [0:v]scale=1080:-2[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2" -c:a copy vertical-fill.mp4

# Fit with letterbox in brand color
ffmpeg -i in.mp4 -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=0x111111" fit.mp4
```

## Join

```bash
# Same codec/size/fps: concat demuxer
printf "file '%s'\n" part1.mp4 part2.mp4 part3.mp4 > list.txt
ffmpeg -f concat -safe 0 -i list.txt -c copy joined.mp4

# Mixed sources: concat filter (re-encodes)
ffmpeg -i a.mp4 -i b.mp4 -filter_complex "[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[v][a]" -map "[v]" -map "[a]" joined.mp4
```

## Audio

```bash
ffmpeg -i in.mp4 -vn -ac 1 -ar 16000 speech.wav          # for transcription
ffmpeg -i in.mp4 -vn -c:a aac -b:a 192k audio.m4a         # extract
ffmpeg -i in.mp4 -i music.mp3 -filter_complex \
 "[1:a]volume=0.18[m];[0:a][m]amix=inputs=2:duration=first:dropout_transition=0[a]" \
 -map 0:v -map "[a]" -c:v copy -c:a aac mixed.mp4         # music bed under voice
```

Duck music under speech with `sidechaincompress` when the voice must stay clear:

```bash
-filter_complex "[1:a]volume=0.35[m];[m][0:a]sidechaincompress=threshold=0.03:ratio=8:attack=20:release=300[duck];[0:a][duck]amix=inputs=2:duration=first[a]"
```

## Loudness: −14 LUFS, true peak < −1 dBTP

Two-pass `loudnorm` for finals:

```bash
# Pass 1: measure
ffmpeg -i in.mp4 -af loudnorm=I=-14:TP=-1.5:LRA=11:print_format=json -f null - 2>&1 | tail -12
# Pass 2: apply measured values
ffmpeg -i in.mp4 -af loudnorm=I=-14:TP=-1.5:LRA=11:measured_I=<I>:measured_TP=<TP>:measured_LRA=<LRA>:measured_thresh=<thresh>:offset=<offset>:linear=true \
 -c:v copy -c:a aac -b:a 192k -ar 48000 loud.mp4
```

Target TP −1.5 so the result stays below −1 after AAC encoding. `scripts/qa.sh` reports the final values.

## Captions

```bash
# Burn an SRT/ASS (simple style). For word-timed animated captions use Hyperframes.
ffmpeg -i in.mp4 -vf "subtitles=captions.srt:force_style='FontName=Inter,FontSize=18,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=1,Outline=2,MarginV=180'" -c:a copy subbed.mp4
```

## Overlay an alpha layer

```bash
# Graphics rendered with alpha (e.g. ProRes 4444 or WebM VP9) over footage
ffmpeg -i base.mp4 -i overlay.mov -filter_complex "[0:v][1:v]overlay=0:0:format=auto" -c:a copy comp.mp4
```

## Export presets

```bash
# Reel / social final (1080×1920, 30 fps)
ffmpeg -i in.mp4 -vf "scale=1080:1920:flags=lanczos,fps=30,format=yuv420p" \
 -c:v libx264 -profile:v high -preset slow -crf 18 -maxrate 12M -bufsize 24M \
 -c:a aac -b:a 192k -ar 48000 -movflags +faststart out.mp4

# 16:9 final: same with scale=1920:1080
# Small preview for chat review
ffmpeg -i in.mp4 -vf "scale=-2:960" -c:v libx264 -crf 28 -preset veryfast -c:a aac -b:a 96k -movflags +faststart preview.mp4

# Contact sheet of frames for visual QA
ffmpeg -i in.mp4 -vf "fps=1/2,scale=270:-1,tile=6x3" -frames:v 1 sheet.png
```

## Pitfalls

- `-ss` before `-i` is fast and, with re-encoding, accurate; with `-c copy` it snaps to keyframes.
- Phone footage is often VFR: normalize to CFR before mixing with rendered graphics.
- Check rotation (`side_data_list`) — FFmpeg auto-rotates on decode, but cropped math must use the rotated size.
- Always `format=yuv420p` for H.264 deliverables or some players show a black screen.
