package main

import (
	"slices"
	"testing"
)

func TestOutputPathReplacesTheSourceLanguageWithTheTarget(t *testing.T) {
	for _, c := range []struct{ src, from, to, want string }{
		{"talk.en.srt", "en", "Japanese", "talk.ja.srt"},
		{"talk.en-orig.srt", "en", "Japanese", "talk.ja.srt"},
		{"dir/talk.srt", "en", "Japanese", "dir/talk.ja.srt"},
		{"talk.en.srt", "en", "German", "talk.german.srt"},
	} {
		if got := outputPath(c.src, c.from, c.to); got != c.want {
			t.Errorf("outputPath(%q, %q, %q) = %q, want %q", c.src, c.from, c.to, got, c.want)
		}
	}
}

func TestPlamoArgsKeepTextThatLooksLikeAFlag(t *testing.T) {
	args := plamoArgs("English", "Japanese", "-Yeah.")
	if last := args[len(args)-1]; last != "--input=-Yeah." {
		t.Fatalf("plamoArgs ends with %q, want the text joined to --input so argparse cannot read it as a flag", last)
	}
}

func TestYtdlpArgsFetchOnlyTheVideoNotItsPlaylist(t *testing.T) {
	url := "https://www.youtube.com/watch?v=X&list=PLY"
	args := ytdlpArgs("/tmp/x", url, uploadedSubs("en"))
	if !slices.Contains(args, "--no-playlist") || args[len(args)-1] != url {
		t.Fatalf("ytdlpArgs = %q, want --no-playlist and the URL last", args)
	}
}

func TestUploadedSubsTakeRegionalTracksButNotTranslatedOnes(t *testing.T) {
	args := uploadedSubs("en")
	if !hasPair(args, "--sub-langs", "en,en-.*") || !hasPair(args, "--extractor-args", "youtube:skip=translated_subs") || slices.Contains(args, "--write-auto-subs") {
		t.Fatalf("uploadedSubs = %q", args)
	}
}

func TestAutomaticCaptionsAreTheUntranslatedTrackAsTTML(t *testing.T) {
	args := automaticCaptions("en")
	if !hasPair(args, "--sub-langs", "en-orig") || !hasPair(args, "--sub-format", "ttml") || slices.Contains(args, "--write-subs") {
		t.Fatalf("automaticCaptions = %q", args)
	}
}

func TestIsLocalSRTIgnoresCase(t *testing.T) {
	for in, want := range map[string]bool{"talk.srt": true, "TALK.SRT": true, "https://youtu.be/x": false} {
		if got := isLocalSRT(in); got != want {
			t.Errorf("isLocalSRT(%q) = %v, want %v", in, got, want)
		}
	}
}

func hasPair(args []string, flag, value string) bool {
	i := slices.Index(args, flag)
	return i >= 0 && i+1 < len(args) && args[i+1] == value
}
