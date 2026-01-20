#!/usr/bin/env npx tsx

/**
 * Loom Transcript Fetcher
 *
 * Fetches the transcript from a Loom video URL.
 * Usage: npx tsx bin/-/loom-transcriptor.ts <loom-url>
 *
 * The transcript is extracted from Loom's Apollo state and fetched from their CDN.
 */

interface LoomTranscriptWord {
  text: string;
  start_ts: number;
  end_ts: number;
}

interface LoomTranscriptPhrase {
  ts: number;
  value: string;
}

interface LoomTranscriptData {
  source_lang?: string;
  timecoded_text?: LoomTranscriptWord[];
  phrases?: LoomTranscriptPhrase[];
}

interface ApolloVideoData {
  name?: string;
  description?: string;
  chapters?: string;
  video_properties?: {
    duration?: number;
    durationMs?: number;
  };
}

interface ApolloTranscriptDetails {
  source_url?: string;
  captions_source_url?: string;
  language?: string;
}

async function fetchLoomTranscript(url: string): Promise<void> {
  // Validate URL
  const loomUrlMatch = url.match(/loom\.com\/share\/([a-zA-Z0-9]+)/);
  if (!loomUrlMatch) {
    console.error("Error: Invalid Loom URL. Expected format: https://www.loom.com/share/<video-id>");
    process.exit(1);
  }

  const videoId = loomUrlMatch[1];

  try {
    // Fetch the Loom page
    const response = await fetch(url, {
      headers: {
        "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      },
    });

    if (!response.ok) {
      console.error(`Error: Failed to fetch Loom page (${response.status})`);
      process.exit(1);
    }

    const html = await response.text();

    // Extract __APOLLO_STATE__ JSON
    const apolloMatch = html.match(/window\.__APOLLO_STATE__\s*=\s*(\{[\s\S]*?\});/);
    if (!apolloMatch) {
      console.error("Error: Could not find Apollo state in page");
      process.exit(1);
    }

    const apolloState = JSON.parse(apolloMatch[1]);

    // Find video data
    const videoKey = Object.keys(apolloState).find(
      (k) => k.startsWith("RegularUserVideo:") && k.includes(videoId)
    );
    const videoData: ApolloVideoData | undefined = videoKey ? apolloState[videoKey] : undefined;

    // Find transcript details
    const transcriptKey = Object.keys(apolloState).find((k) => k.startsWith("VideoTranscriptDetails:"));
    const transcriptDetails: ApolloTranscriptDetails | undefined = transcriptKey
      ? apolloState[transcriptKey]
      : undefined;

    // Output video metadata
    console.log("# Loom Video Transcript\n");
    console.log(`**Title:** ${videoData?.name || "Untitled"}`);
    if (videoData?.description) {
      console.log(`\n**Description:** ${videoData.description}`);
    }
    if (videoData?.video_properties?.duration) {
      const duration = videoData.video_properties.duration;
      const minutes = Math.floor(duration / 60);
      const seconds = Math.round(duration % 60);
      console.log(`\n**Duration:** ${minutes}:${seconds.toString().padStart(2, "0")}`);
    }
    console.log(`\n**Video ID:** ${videoId}`);

    if (videoData?.chapters) {
      console.log("\n**Chapters:**");
      console.log(videoData.chapters);
    }

    console.log("\n---\n");

    // Fetch transcript from source URL
    if (!transcriptDetails?.source_url) {
      console.log("*No transcript available for this video.*");
      console.log("\nThis could mean:");
      console.log("- The video is still being processed");
      console.log("- Transcription was disabled for this video");
      console.log("- The video has no spoken audio");
      process.exit(0);
    }

    const transcriptResponse = await fetch(transcriptDetails.source_url, {
      headers: {
        "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      },
    });

    if (!transcriptResponse.ok) {
      console.error(`Error: Failed to fetch transcript (${transcriptResponse.status})`);
      process.exit(1);
    }

    const transcriptData: LoomTranscriptData = await transcriptResponse.json();

    const formatTimestamp = (seconds: number): string => {
      const mins = Math.floor(seconds / 60);
      const secs = Math.floor(seconds % 60);
      return `${mins}:${secs.toString().padStart(2, "0")}`;
    };

    // Handle phrases format (newer Loom format)
    if (transcriptData.phrases && transcriptData.phrases.length > 0) {
      console.log("## Transcript\n");

      for (const phrase of transcriptData.phrases) {
        console.log(`**[${formatTimestamp(phrase.ts)}]** ${phrase.value}\n`);
      }
    }
    // Handle timecoded_text format (older format)
    else if (transcriptData.timecoded_text && transcriptData.timecoded_text.length > 0) {
      console.log("## Transcript\n");

      const PARAGRAPH_GAP_SECONDS = 3;
      let currentParagraph: string[] = [];
      let paragraphStartTime = 0;
      let lastEndTime = 0;

      for (const word of transcriptData.timecoded_text) {
        if (currentParagraph.length > 0 && word.start_ts - lastEndTime > PARAGRAPH_GAP_SECONDS) {
          console.log(`**[${formatTimestamp(paragraphStartTime)}]** ${currentParagraph.join(" ")}\n`);
          currentParagraph = [];
        }

        if (currentParagraph.length === 0) {
          paragraphStartTime = word.start_ts;
        }

        currentParagraph.push(word.text);
        lastEndTime = word.end_ts;
      }

      if (currentParagraph.length > 0) {
        console.log(`**[${formatTimestamp(paragraphStartTime)}]** ${currentParagraph.join(" ")}\n`);
      }
    } else {
      console.log("*Transcript is empty.*");
      process.exit(0);
    }

    console.log("\n---\n*Transcript extracted from Loom*");
  } catch (error) {
    if (error instanceof SyntaxError) {
      console.error("Error: Failed to parse video data");
      console.error(error.message);
    } else if (error instanceof Error) {
      console.error(`Error: ${error.message}`);
    } else {
      console.error("Error: Unknown error occurred");
    }
    process.exit(1);
  }
}

// Main
const url = process.argv[2];

if (!url) {
  console.log("Usage: npx tsx bin/-/loom-transcriptor.ts <loom-url>");
  console.log("");
  console.log("Example:");
  console.log("  npx tsx bin/-/loom-transcriptor.ts https://www.loom.com/share/abc123def456");
  process.exit(1);
}

fetchLoomTranscript(url);
