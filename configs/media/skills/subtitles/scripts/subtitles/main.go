// subtitles fetches a video's subtitles with yt-dlp and translates them
// locally with plamo-translate, keeping every timestamp as it was.
//
//	subtitles [flags] <video URL | file.srt>
//
// It prints the path of the translated .srt.
package main

import (
	"bytes"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// languageCodes names the output file the way yt-dlp names its input;
// a language not listed falls back to its lower-cased name.
var languageCodes = map[string]string{
	"Japanese": "ja", "English": "en", "Chinese": "zh", "Korean": "ko",
}

func main() {
	subLang := flag.String("sub-lang", "en", "subtitle language to download, as yt-dlp names it")
	from := flag.String("from", "English", "language of the subtitles, as plamo-translate names it")
	to := flag.String("to", "Japanese", "language to translate into, as plamo-translate names it")
	chunk := flag.Int("chunk", 20, "subtitles sent to plamo-translate per call")
	dir := flag.String("dir", ".", "directory the downloaded and translated .srt files go to")
	flag.Usage = func() {
		fmt.Fprintln(flag.CommandLine.Output(), "usage: subtitles [flags] <video URL | file.srt>")
		flag.PrintDefaults()
	}
	flag.Parse()
	if flag.NArg() != 1 || *chunk < 1 {
		flag.Usage()
		os.Exit(2)
	}
	out, err := run(flag.Arg(0), *subLang, *from, *to, *chunk, *dir)
	if err != nil {
		fmt.Fprintln(os.Stderr, "subtitles:", err)
		os.Exit(1)
	}
	fmt.Println(out)
}

func run(target, subLang, from, to string, chunk int, dir string) (string, error) {
	src := target
	if !isLocalSRT(target) {
		var err error
		if src, err = download(target, subLang, dir); err != nil {
			return "", err
		}
	}
	raw, err := os.ReadFile(src)
	if err != nil {
		return "", err
	}
	cues, err := translateCues(parseSRT(string(raw)), chunk, plamo(from, to))
	if err != nil {
		return "", err
	}
	out := outputPath(src, subLang, to)
	return out, os.WriteFile(out, []byte(formatSRT(cues)), 0o644)
}

func isLocalSRT(target string) bool {
	return strings.EqualFold(filepath.Ext(target), ".srt")
}

// download asks yt-dlp for the uploaded subtitles, or failing that the
// automatic captions in the video's own language.
func download(url, subLang, dir string) (string, error) {
	if src, err := fetch(url, dir, uploadedSubs(subLang)); err != nil || src != "" {
		return src, err
	}
	src, err := fetch(url, dir, automaticCaptions(subLang))
	if err == nil && src == "" {
		err = fmt.Errorf("%q has neither %s subtitles nor %s-orig captions", url, subLang, subLang)
	}
	return src, err
}

// AIDEV-NOTE: never a translated track. YouTube answers HTTP 429 to captions
// it translated itself (yt-dlp#13831). A bare automatic `en` can be one, so
// automatic captions are asked for as `<lang>-orig`; uploaded ones may carry a
// region (`en-US`), so `<lang>-.*` is asked for with translated tracks skipped,
// since those are named `<lang>-<source>`.
func uploadedSubs(subLang string) []string {
	return []string{"--write-subs", "--sub-langs", subLang + "," + subLang + "-.*",
		"--extractor-args", "youtube:skip=translated_subs"}
}

// automaticCaptions come as ttml because yt-dlp's default vtt rolls each line
// through three cues.
func automaticCaptions(subLang string) []string {
	return []string{"--write-auto-subs", "--sub-langs", subLang + "-orig", "--sub-format", "ttml"}
}

// ytdlpArgs keeps a watch URL copied from a playlist to its one video;
// otherwise every video's subtitles land in tmp.
func ytdlpArgs(tmp, url string, subs []string) []string {
	args := []string{"--skip-download", "--no-playlist", "--convert-subs", "srt", "-P", tmp, "-o", "%(title)s.%(ext)s"}
	return append(append(args, subs...), url)
}

// fetch runs yt-dlp into a fresh directory, so the .srt it wrote is the only
// one there, and returns "" when it wrote none.
func fetch(url, dir string, subs []string) (string, error) {
	tmp, err := os.MkdirTemp(dir, ".subtitles-")
	if err != nil {
		return "", err
	}
	defer os.RemoveAll(tmp)
	cmd := exec.Command("yt-dlp", ytdlpArgs(tmp, url, subs)...)
	cmd.Stdout, cmd.Stderr = os.Stderr, os.Stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("yt-dlp: %w", err)
	}
	found, _ := filepath.Glob(filepath.Join(tmp, "*.srt"))
	if len(found) == 0 {
		return "", nil
	}
	dst := filepath.Join(dir, filepath.Base(found[0]))
	return dst, os.Rename(found[0], dst)
}

func plamo(from, to string) translator {
	return func(text string) (string, error) {
		var stdout bytes.Buffer
		cmd := exec.Command("plamo-translate", plamoArgs(from, to, text)...)
		cmd.Stdout, cmd.Stderr = &stdout, os.Stderr
		if err := cmd.Run(); err != nil {
			return "", fmt.Errorf("plamo-translate: %w", err)
		}
		return stdout.String(), nil
	}
}

// plamoArgs joins the text to --input: as a separate argument, argparse reads
// a subtitle such as "-Yeah." as an unknown flag and plamo-translate exits.
func plamoArgs(from, to, text string) []string {
	return []string{"--from", from, "--to", to, "--no-stream", "--input=" + text}
}

func outputPath(src, subLang, to string) string {
	stem := strings.TrimSuffix(src, ".srt")
	stem = strings.TrimSuffix(strings.TrimSuffix(stem, "."+subLang+"-orig"), "."+subLang)
	code, ok := languageCodes[to]
	if !ok {
		code = strings.ToLower(to)
	}
	return stem + "." + code + ".srt"
}
