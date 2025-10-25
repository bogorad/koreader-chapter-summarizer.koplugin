# Chapter Summarizer Plugin for KOReader

AI-powered chapter summaries using OpenRouter.ai and Grok-4-Fast

## Features

- Extract text from the current chapter you're reading
- Generate AI summaries with customizable prompts
- Fast summaries using x-ai/grok-4-fast by default
- Save summaries for later review
- Copy summaries to clipboard
- View summary history
- Customizable AI model and parameters

## Installation

### Option 1: Manual Installation

1. Download the `ChapterSummarizer.koplugin` folder
2. Copy it to your KOReader plugins directory:
   - **Android**: `/sdcard/koreader/plugins/`
   - **Kobo**: `/mnt/onboard/.adds/koreader/plugins/`
   - **Kindle**: `/mnt/us/koreader/plugins/`
   - **Other**: `~/.config/koreader/plugins/`
3. Restart KOReader
4. The plugin will be automatically enabled

### Option 2: Git Clone

```bash
cd /path/to/koreader/plugins/
git clone https://github.com/bogorad/koreader-chapter-summarizer.git
```

## Setup

### 1. Get an OpenRouter API Key

1. Visit [https://openrouter.ai/](https://openrouter.ai/)
2. Sign up for an account
3. Go to [Keys](https://openrouter.ai/keys)
4. Click "Create Key"
5. Copy your API key (starts with `sk-or-v1-...`)

### 2. Add Credits

1. Go to your [OpenRouter account](https://openrouter.ai/account)
2. Click "Add Credits"
3. Add at least $5 to start (summaries cost ~$0.0001-0.01 each depending on model)

### 3. Configure Plugin

1. Open any book in KOReader
2. Tap the menu (top of screen)
3. Go to **Tools** → **Chapter Summarizer** → **Settings**
4. Enter your API key
5. (Optional) Change the model or prompt
6. Tap **Save**

## Usage

### Summarize Current Chapter

**Method 1: Via Menu**

1. Open a book and navigate to any chapter
2. Tap menu → **Tools** → **Chapter Summarizer** → **Summarize Current Chapter**
3. Wait a few seconds for the summary to generate
4. Read, copy, or save the summary

**Method 2: Via Keyboard Shortcut**

1. Go to **Settings** → **Taps and gestures** → **Dispatcher**
2. Find "Summarize Current Chapter"
3. Assign it to a gesture or button
4. Use your shortcut anytime to summarize

### View Summary History

- Menu → **Tools** → **Chapter Summarizer** → **Summary History**
- Tap any saved summary to view it

## Supported AI Models

The plugin works with any OpenRouter-supported model. Popular choices:

### Fast & Affordable

- **x-ai/grok-4-fast** (default) - Very fast, good quality
- **google/gemini-2.5-flash-lite**
- **qwen/qwen3-235b-a22b-thinking-2507**

See [all models](https://openrouter.ai/models) on OpenRouter.

## Settings

### API Key

Your OpenRouter API key (required). Keep this private! Setting a limit of $3 is recommended for peace of mind.

### Model

The AI model to use. Format: `provider/model-name`

Examples:

- `x-ai/grok-4-fast` (default, fast)
- `google/gemini-2.5-flash-lite`
- `qwen/qwen3-235b-a22b-thinking-2507`

### Prompt

The instruction given to the AI. Default:

> "Please provide a concise summary of this chapter in 3-5 sentences, highlighting the key points and main ideas."

Customize it for different styles:

- Detailed: "Provide a detailed summary covering all major events and character developments"
- Brief: "Summarize this chapter in exactly 2 sentences"
- Questions: "List the 3 most important questions this chapter raises"
- For students: "Summarize this chapter as if explaining to a 10-year-old"

### Max Summary Tokens

Maximum length of the generated summary in tokens (~words), 1000 is the defalt. Higher = longer summaries but more cost.

## Requirements

- KOReader (any recent version)
- OpenRouter account with credits (`:free` models are also supported but not recommended)
- Internet connection (when generating summaries)
- Books with table of contents (most EPUB and PDF files)

## Limitations

- **Requires TOC**: Books must have a table of contents for chapter detection
- **Page limit**: Very long chapters (>50 pages) are truncated to save tokens
- **Network required**: Must have internet to generate summaries (viewing saved summaries works offline)
- **Cost**: Each summary costs a small amount based on the model and chapter length

## Troubleshooting

### "Please configure your OpenRouter API key"

- Go to Settings and add your API key
- Make sure it starts with `sk-or-v1-`

### "This document has no table of contents"

- The book doesn't have chapter markers
- Try a different book with proper chapters
- Some PDF files lack TOC even if they have visual chapters

### "Invalid API key"

- Check your API key is correct (no extra spaces)
- Verify it's active in your OpenRouter account
- Try creating a new key

### "Insufficient credits"

- Add more credits to your OpenRouter account
- Check your usage at [openrouter.ai/activity](https://openrouter.ai/activity)

### "API error" or "Rate limited"

- Too many requests too quickly
- Wait a minute and try again
- Check OpenRouter status

### "Failed to extract chapter text"

- Some book formats don't support text extraction
- Try a different book
- Check the book opens correctly in KOReader

## Privacy & Security

- Your API key is stored locally on your device
- Chapter text is sent to OpenRouter/AI providers for processing
- Summaries are saved locally on your device
- No data is collected by this plugin

## Development

### File Structure

```
ChapterSummarizer.koplugin/
├── _meta.lua           # Plugin metadata
├── main.lua            # Main plugin code
└── README.md           # This file
```

### License

MIT License - see LICENSE file

## Credits

- **KOReader Team** - Amazing ebook reader platform
- **OpenRouter** - Unified AI API
- **x.ai** - Grok AI model

## Support

- KOReader Forum: [koreader.rocks](https://github.com/koreader/koreader/discussions)
- OpenRouter Docs: [openrouter.ai/docs](https://openrouter.ai/docs)

## Changelog

### Version 1.0.0

- Initial release
- Chapter extraction from EPUB and PDF
- OpenRouter API integration
- Configurable prompts and models
- Summary history
- Copy to clipboard
- Save summaries to file
- Token usage tracking
- Default model: x-ai/grok-beta
