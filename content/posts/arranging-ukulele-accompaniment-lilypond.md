---
title: Arranging Ukulele Accompaniment for Irish Tunes in LilyPond
date: 2026-02-22T23:30:00+10:00
draft: false
tags:
  - music
  - lilypond
---
I've been learning [tin whistle](https://surreal.live/en-au/entertainer/tin-whistlin-dave) online through [Conor Lamb's Tin Whistle Workshops](https://whistleworkshops.com/). Conor is a member of [Realta](https://www.conorlambmusic.com/realta/) and last week he led the class through "The Fermanagh Highland". He also accepts bitcoin on lightning for payment, which is a nice bonus.

The class materials include a PDF of the sheet music. I wanted to get that into a format I could manipulate -- add chords, strum patterns, and eventually record myself playing along. I fed the PDF to [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Anthropic's AI coding assistant) and asked it to transcribe the notation into [LilyPond](https://lilypond.org/) markup. LilyPond is a text-based music engraving system -- like LaTeX for sheet music. You describe music in a markup language and it produces publication-quality scores.

Claude read the PDF, produced a clean `.ly` file, and from there I could ask it to analyse the harmony, add ukulele chords, work out strumming patterns, and generate chord diagrams -- all as text that compiles to a printable score. The entire arrangement workflow happened in conversation, with Claude writing the LilyPond code and compiling it to check for errors at each step.

The tune is in D major, 4/4 time, and follows the standard Irish dance tune structure: an A part (repeated) and a B part.

## The melody

```lilypond
melody = \fixed c' {
  \key d \major
  \time 4/4
  \partial 4 d'8 b |
  \repeat volta 2 {
    a4 fis8 d a8 d' d' b |
    a4 fis8 d e fis g b |
    a4 fis8 a a4 fis8 a |
  }
  \alternative {
    { b8 g e g fis d d'8 b | }
    { g8 e g fis d4 d4 \bar "||" }
  }
  % Part B continues...
}
```

## Working out the chords

For a tune in D major, the workhorse chords are I (D), IV (G), and V (A). Irish trad harmony tends to be simple -- you're supporting the melody, not competing with it. I went bar by bar, looking at which notes fall on strong beats and which triad they outline:

| Bar | Strong-beat notes | Chord |
|-----|-------------------|-------|
| m1 | a, fis, a, d' | D |
| m2 | a, fis, e, g | D (2 beats) -- G (2 beats) |
| m3 | a, fis, a, fis | D |
| Alt 1 | b, g, fis, d | G (2 beats) -- D (2 beats) |

Where a bar sits entirely within one triad, it gets a single whole-bar chord. Where the harmony shifts mid-bar (usually at the half-bar), it gets two half-note chords. Most of Part B follows the same logic with A major appearing as the V chord.

In LilyPond, this translates to a `\chordmode` block that mirrors the melody's repeat structure:

```lilypond
harmonies = \chordmode {
  \time 4/4
  \partial 4 d4 |
  \repeat volta 2 {
    d1 |
    d2 g |
    d1 |
  }
  \alternative {
    { g2 d | }
    { g2 d | }
  }
  % Part B: d1 | d2 a | d1 | g2 a | ...
}
```

Drop that into a `\new ChordNames` context and LilyPond renders chord symbols (D, G, A) above the staff automatically.

## Strum patterns

A single strumming pattern for every bar sounds robotic. Instead I used three main patterns, chosen based on what's happening harmonically:

**Full drive** (single-chord bars): a quarter-note downstroke followed by six alternating eighth-note down-up strokes. This is the main engine for bars that sit on one chord.

```
Beat:  1    2  &  3  &  4  &
Strum: |    | \/ | \/ | \/
       q    e e  e e  e e
```

**Two-group** (chord-change bars): when the chord changes at the half-bar, the pattern restarts on beat 3 to emphasise the new root. Two groups of quarter + two eighths.

**Phrase endings**: the second-time bar at the end of Part A settles with two quarter-note downstrokes. The penultimate bar of Part B builds with steady quarters leading into a triplet figure that matches the melody's energy in the final bar.

In LilyPond I notated these on a `RhythmicStaff` (a single-line percussion-style staff) with `\downbow` and `\upbow` markings:

```lilypond
strum = {
  \time 4/4
  \partial 4 c4\downbow |
  \repeat volta 2 {
    % Full drive
    c4\downbow c8\downbow c\upbow c\downbow c\upbow c\downbow c\upbow |
    % Two-group (chord change at half-bar)
    c4\downbow c8\downbow c\upbow c4\downbow c8\downbow c\upbow |
    % Full drive
    c4\downbow c8\downbow c\upbow c\downbow c\upbow c\downbow c\upbow |
  }
  % ...
}
```

## Chord diagrams

LilyPond can render fret diagrams using `\fret-diagram-terse`. For a ukulele you set `string-count` to 4 and specify each string's fret number (or `o` for open):

```lilypond
\markup {
  \override #'(fret-diagram-details . (
    (string-count . 4)
    (top-fret-thickness . 3)
  ))
  {
    \column { \fret-diagram-terse "2;2;2;o;" "D" }
    \column { \fret-diagram-terse "o;2;3;2;" "G" }
    \column { \fret-diagram-terse "2;1;o;o;" "A" }
  }
}
```

These render as proper fret grid diagrams with dots and open-string markers at the bottom of the page, giving you a quick visual reference for the three chords.

## Putting it all together

The score block combines all three layers -- chord symbols, melody, and strum rhythm -- in a simultaneous `<< >>` block:

```lilypond
\score {
  <<
    \new ChordNames \harmonies
    \new Staff \melody
    \new RhythmicStaff \with {
      instrumentName = "Strum"
    } \strum
  >>
  \layout { }
  \midi { \tempo 4 = 120 }
}
```

One `lilypond` command and you get a PDF with all three staves aligned, plus a MIDI file you can use as a practice reference. The MIDI is useful as a click track when recording.

## Recording with Audacity

With the arrangement sorted, I used Audacity's overdub feature to layer the two parts. I should say upfront: I am a total novice on the ukulele, and the instrument I used was my son's little uke. Not exactly a professional setup.

1. **Enable overdub**: Edit > Preferences > Recording > "Play other tracks while recording"
2. **Track 1 -- ukulele chords**: Record the strumming part. I played it at a comfortable (slow) tempo, then used Effect > Change Tempo to speed it up 30% without raising the pitch. A nice cheat for when your fingers can't keep up with the tune yet.
3. **Track 2 -- tin whistle melody**: Put on headphones, hit record again. Audacity plays back Track 1 while you record the melody on a new track.

Headphones are essential for the second pass, otherwise the mic picks up the playback. If the overdub feels slightly out of sync, adjust the latency compensation in Recording preferences.

## Finding someone to play with

Recording yourself on both instruments works, but what I'm really after is a live accompanist for the whistle. Guitar is the traditional choice for backing Irish tunes -- it's what you'll see at most sessions. The ukulele is a bit of an oddball for this, though it was fun to try.

Someone suggested I look into finding a harpist, which would be a beautiful pairing with the whistle. The Irish harp has a long history alongside traditional melody instruments, and the tonal range would complement the whistle better than the bright chop of a uke. That's the next thing to explore.

## Was it worth the effort?

For a three-chord tune, writing out the arrangement in LilyPond might seem like overkill. But the process of going bar-by-bar through the chord analysis forced me to actually think about why D works here and G works there, rather than just fumbling until something sounds right. And having the strum patterns notated meant I could practise them separately before trying to record.

The real payoff is that this is now a template. The next tune I arrange -- same key, same structure -- I can reuse the strum patterns and just update the chord progression. Irish trad is full of D-major reels and jigs with I-IV-V harmony. The Fermanagh won't be the last.
