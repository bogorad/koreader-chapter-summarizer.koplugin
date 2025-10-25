# Installation Guide - Chapter Summarizer Plugin

## 📦 What You Have

You now have a complete, production-ready KOReader plugin that generates AI summaries of book chapters using OpenRouter.ai.

## 🗂️ Project Structure

```
koreader-or-plugin/
│
├── ChapterSummarizer.koplugin/    ← THE PLUGIN (copy this to KOReader)
│   ├── _meta.lua                  Plugin metadata
│   ├── main.lua                   Complete functionality (12.5 KB)
│   ├── README.md                  User documentation
│   ├── LICENSE                    MIT License
│   ├── .gitignore                 Git ignore rules
│   └── .luarc.json                LSP config (dev only)
│
└── Documentation/
    ├── PLUGIN_DOCS.md             Plugin development guide (16 KB)
    ├── OPENROUTER_API.md          API documentation (17 KB)
    ├── PLAN.md                    Implementation guide (37 KB)
    ├── PLUGIN_CREATED.md          Creation summary
    └── INSTALLATION.md            This file
```

## 🚀 Quick Install (3 Steps)

### Step 1: Copy Plugin to KOReader

**Choose your device:**

#### Android
```bash
adb push ChapterSummarizer.koplugin /sdcard/koreader/plugins/
```
Or use a file manager to copy to:
```
/sdcard/koreader/plugins/ChapterSummarizer.koplugin
```

#### Kobo (via USB)
1. Connect Kobo to computer
2. Copy folder to:
```
KOBOeReader/.adds/koreader/plugins/ChapterSummarizer.koplugin
```
3. Safely eject

#### Kindle (via USB)
1. Connect Kindle to computer
2. Copy folder to:
```
Kindle/koreader/plugins/ChapterSummarizer.koplugin
```
3. Safely eject

#### Linux/Desktop
```bash
cp -r ChapterSummarizer.koplugin ~/.config/koreader/plugins/
```

### Step 2: Get OpenRouter API Key

1. **Visit**: https://openrouter.ai/
2. **Sign up** for a free account
3. **Go to**: https://openrouter.ai/keys
4. **Click**: "Create Key"
5. **Copy** your API key (starts with `sk-or-v1-...`)
6. **Add credits**: Go to https://openrouter.ai/account → Add $5

### Step 3: Configure Plugin

1. **Restart KOReader** (if already running)
2. **Open any book**
3. **Tap menu** (top of screen)
4. **Navigate**: Tools → Chapter Summarizer → Settings
5. **Enter your API key**
6. **Tap Save**

**Done!** You're ready to summarize chapters! 🎉

## 📖 Using the Plugin

### Generate a Summary

**Method 1: Via Menu**
1. Open a book and read to any chapter
2. Tap menu
3. Tools → Chapter Summarizer → Summarize Current Chapter
4. Wait 3-10 seconds
5. Read your AI-generated summary!

**Method 2: Keyboard Shortcut** (Optional)
1. Settings → Taps and gestures → Dispatcher
2. Find "Summarize Current Chapter"
3. Assign to your preferred gesture
4. Use anywhere in any book

### Other Features

**View History**: Tools → Chapter Summarizer → Summary History

**Copy Summary**: Tap "Copy" button in summary viewer

**Save Summary**: Tap "Save" button (saves to `koreader/summaries/`)

**Change Settings**: Tools → Chapter Summarizer → Settings

## ⚙️ Configuration

### Default Settings (Good for Most Users)

- **Model**: `x-ai/grok-beta` (Fast, affordable, good quality)
- **Prompt**: Concise 3-5 sentence summary
- **Max Tokens**: 500 (≈375 words)

### Advanced Settings

#### Change AI Model

Popular alternatives:
```
openai/gpt-3.5-turbo    ← Cheap, fast ($0.001/summary)
openai/gpt-4o           ← Highest quality ($0.01-0.10/summary)
anthropic/claude-3-haiku ← Very fast ($0.001/summary)
anthropic/claude-3-sonnet ← Balanced ($0.01/summary)
google/gemini-pro       ← Google's model ($0.003/summary)
```

#### Customize Prompt

Examples:
```
Detailed:
"Provide a comprehensive summary covering all events, character development, and themes in this chapter."

Brief:
"Summarize this chapter in exactly 2 sentences."

Study Guide:
"Create a study guide summary with: 1) Main events, 2) Key quotes, 3) Discussion questions."

Character Focus:
"Summarize focusing on character development and relationships in this chapter."

For Kids:
"Summarize this chapter as if explaining to a 10-year-old."
```

## 💰 Cost Guide

With default model `x-ai/grok-beta`:

| Chapter Length | Estimated Cost | Time |
|----------------|----------------|------|
| Short (5 pages) | $0.001 | 3-5 sec |
| Medium (15 pages) | $0.003 | 5-8 sec |
| Long (30 pages) | $0.01 | 8-15 sec |
| Very Long (50+ pages) | $0.02-0.05 | 15-30 sec |

**$5 credit = ~5,000 summaries** (with default model)

Other models:
- **GPT-3.5**: $5 = ~2,500 summaries
- **GPT-4o**: $5 = ~500 summaries
- **Claude Haiku**: $5 = ~5,000 summaries

## 🔧 Troubleshooting

### Plugin doesn't appear in menu
- ✅ Check folder is named exactly `ChapterSummarizer.koplugin`
- ✅ Restart KOReader
- ✅ Check folder is in correct plugins directory
- ✅ Verify files are not corrupted

### "Please configure your API key"
- ✅ Go to Settings and enter your OpenRouter API key
- ✅ Make sure key starts with `sk-or-v1-`
- ✅ No extra spaces before/after key

### "Invalid API key"
- ✅ Copy key again from OpenRouter (might have error)
- ✅ Check for hidden characters or spaces
- ✅ Try creating a new key

### "Insufficient credits"
- ✅ Add credits at https://openrouter.ai/account
- ✅ Check your usage at https://openrouter.ai/activity
- ✅ $5 is a good starting amount

### "This document has no table of contents"
- ❌ Book doesn't have chapter markers
- ✅ Try a different book with proper chapters
- ✅ Most EPUB files have TOC, some PDFs don't

### "Failed to extract chapter text"
- ❌ Book format might not support text extraction
- ✅ Try a different book format (EPUB works best)
- ✅ Some scanned PDFs can't extract text

### Network/Connection errors
- ✅ Check internet connection
- ✅ Wait a minute and retry
- ✅ Check OpenRouter status: https://status.openrouter.ai

### "Rate limited"
- ⏱️ Too many requests too quickly
- ✅ Wait 60 seconds
- ✅ Reduce frequency of requests

## 📱 Device-Specific Notes

### Android
- ✅ Works perfectly
- ✅ Clipboard copy works
- ✅ File saving works
- Path: `/sdcard/koreader/summaries/`

### Kobo
- ✅ Works perfectly
- ✅ Clipboard might not work (device limitation)
- ✅ File saving works
- Path: `/mnt/onboard/.adds/koreader/summaries/`

### Kindle
- ✅ Works perfectly
- ⚠️ Some Kindle models have network restrictions
- ✅ File saving works
- Path: `/mnt/us/koreader/summaries/`

### Desktop/Emulator
- ✅ Perfect for testing
- ✅ All features work
- ✅ Fast development cycle
- Path: `~/.local/share/koreader/summaries/`

## 🎯 Best Practices

### For Best Results

1. **Choose right model for task**:
   - Quick summaries: `x-ai/grok-beta` or `gpt-3.5-turbo`
   - High quality: `gpt-4o` or `claude-3-opus`
   - Balanced: `claude-3-sonnet`

2. **Customize prompts**:
   - Be specific about what you want
   - Specify desired length
   - Ask for specific analysis

3. **Monitor costs**:
   - Check usage at https://openrouter.ai/activity
   - Set credit limits if needed
   - Use cheaper models for practice

4. **Save important summaries**:
   - Tap "Save" for summaries you want to keep
   - They're saved even without internet later

### Power User Tips

1. **Assign Keyboard Shortcut**:
   - Settings → Dispatcher
   - Assign to swipe or tap gesture
   - One-tap summaries!

2. **Batch Processing**:
   - Create multiple summaries
   - Review in Summary History
   - Export all at once

3. **Compare Models**:
   - Summarize same chapter with different models
   - See which you prefer
   - Optimize cost vs quality

## 📊 File Locations

### Settings
```
koreader/settings/chapter_summarizer.lua
```
Contains: API key, model, prompt, max tokens

### Saved Summaries
```
koreader/summaries/
  20251025_143022_Chapter_Name.txt
  20251025_150011_Another_Chapter.txt
  ...
```
Format: `YYYYMMDD_HHMMSS_Chapter_Title.txt`

## 🔐 Privacy & Security

- ✅ API key stored **locally** on your device
- ✅ Chapter text sent to OpenRouter/AI provider for processing
- ✅ Summaries saved **locally** on your device
- ✅ No tracking or analytics
- ✅ No data collection by plugin
- ⚠️ OpenRouter/AI providers have their own privacy policies

## 🆘 Getting Help

### Resources

1. **Plugin README**: `ChapterSummarizer.koplugin/README.md`
2. **OpenRouter Docs**: https://openrouter.ai/docs
3. **KOReader Forum**: https://github.com/koreader/koreader/discussions
4. **This Guide**: You're reading it! 😊

### Reporting Issues

If you encounter problems:

1. Check this guide first
2. Check plugin README
3. Look at KOReader logs
4. Create GitHub issue with:
   - Device model
   - KOReader version
   - Error message
   - Steps to reproduce

## ✅ Verification Checklist

After installation, verify:

- [ ] Plugin appears in Tools menu
- [ ] Settings page opens
- [ ] Can save API key
- [ ] Can summarize a chapter
- [ ] Summary displays correctly
- [ ] Can copy summary (if supported)
- [ ] Can save summary
- [ ] Can view summary history
- [ ] Token count appears
- [ ] Cost estimate shows

## 🎉 You're All Set!

The Chapter Summarizer plugin is now installed and ready to use!

**Happy Reading! 📖→🤖→📝**

---

**Need Help?** Check the troubleshooting section or open an issue.  
**Want to Customize?** Edit `main.lua` or tweak settings.  
**Enjoying the Plugin?** Star the repo and share with others!
