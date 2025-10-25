# Chapter Summarizer Plugin - Implementation Plan

A comprehensive step-by-step guide for building a KOReader plugin that extracts the current chapter and generates AI summaries using OpenRouter.ai API.

## Table of Contents
- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Phase 1: Environment Setup](#phase-1-environment-setup)
- [Phase 2: Basic Plugin Structure](#phase-2-basic-plugin-structure)
- [Phase 3: Chapter Text Extraction](#phase-3-chapter-text-extraction)
- [Phase 4: Settings Management](#phase-4-settings-management)
- [Phase 5: OpenRouter API Integration](#phase-5-openrouter-api-integration)
- [Phase 6: Summary Display](#phase-6-summary-display)
- [Phase 7: User Interface Polish](#phase-7-user-interface-polish)
- [Phase 8: Testing & Optimization](#phase-8-testing--optimization)
- [Phase 9: Documentation](#phase-9-documentation)
- [Phase 10: Deployment](#phase-10-deployment)
- [Troubleshooting](#troubleshooting)

## Project Overview

### What We're Building

A KOReader plugin called "Chapter Summarizer" that:
1. Extracts text from the current chapter of an ebook
2. Sends the chapter text to OpenRouter.ai with a customizable prompt
3. Displays the AI-generated summary to the user
4. Allows users to configure their API key, prompt, and preferred model

### Features

- ✅ Extract current chapter text from EPUB, PDF, and other formats
- ✅ Configurable OpenRouter API key
- ✅ Customizable summary prompt
- ✅ Model selection (GPT-3.5, GPT-4, Claude, etc.)
- ✅ Summary history
- ✅ Copy summary to clipboard
- ✅ Error handling and user feedback
- ✅ Token usage tracking

### Technical Stack

- **Language**: Lua
- **Framework**: KOReader Plugin API
- **HTTP Library**: LuaSocket
- **JSON**: Built-in json module
- **UI**: KOReader widgets (TextViewer, InputDialog, etc.)
- **API**: OpenRouter.ai Chat Completions

## Prerequisites

### Skills Required

- Basic Lua programming (variables, functions, tables)
- Understanding of HTTP requests
- Basic JSON knowledge
- Git for version control
- Text editor or IDE

### Software Requirements

- Git
- Text editor (VS Code recommended)
- Lua Language Server (optional but recommended)
- KOReader (for testing) or emulator

### Accounts & Keys

1. OpenRouter.ai account
2. API key from OpenRouter
3. Some credits in your OpenRouter account

## Phase 1: Environment Setup

### Step 1.1: Create Project Directory

```bash
# Create the plugin directory
mkdir ChapterSummarizer.koplugin
cd ChapterSummarizer.koplugin

# Initialize git repository
git init -b main

# Create .gitignore
cat > .gitignore << EOL
.DS_Store
*.swp
*~
.vscode/
koreader/
EOL
```

### Step 1.2: Add KOReader as Submodule

```bash
# Add KOReader source for reference
git submodule add https://github.com/koreader/koreader.git
```

This will take a few minutes to clone.

### Step 1.3: Configure LSP

Create `.luarc.json` for autocomplete support:

```bash
cat > .luarc.json << 'EOL'
{
  "workspace": {
    "library": ["./koreader/frontend"],
    "ignoreDir": [".vscode", ".git", "koreader/.git"]
  },
  "diagnostics": {
    "globals": ["G_reader_settings"]
  }
}
EOL
```

### Step 1.4: Set Up IDE (VS Code)

If using VS Code:

1. Install "Lua" extension by sumneko
2. Open the folder in VS Code
3. Wait for Lua Language Server to index the files

**Checkpoint**: You should now have autocomplete for KOReader modules!

## Phase 2: Basic Plugin Structure

### Step 2.1: Create Metadata File

Create `_meta.lua`:

```lua
local _ = require("gettext")
return {
    name = "chaptersummarizer",
    fullname = _("Chapter Summarizer"),
    description = _([[Extracts the current chapter and generates an AI summary using OpenRouter.ai API. Configure your API key and custom prompt in the settings.]]),
}
```

**What this does**: Defines plugin name and description shown in KOReader's plugin manager.

### Step 2.2: Create Basic Main File

Create `main.lua`:

```lua
--[[--
Chapter Summarizer Plugin for KOReader

Extracts chapter text and generates summaries using OpenRouter.ai

@module koplugin.ChapterSummarizer
--]]--

local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")
local logger = require("logger")

local ChapterSummarizer = WidgetContainer:extend{
    name = "chaptersummarizer",
    is_doc_only = true,  -- Only works when a document is open
}

function ChapterSummarizer:init()
    logger.info("ChapterSummarizer: Initializing plugin")
    self.ui.menu:registerToMainMenu(self)
end

function ChapterSummarizer:addToMainMenu(menu_items)
    menu_items.chapter_summarizer = {
        text = _("Chapter Summarizer"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = _("Summarize Current Chapter"),
                callback = function()
                    self:summarizeChapter()
                end,
            },
            {
                text = _("Settings"),
                callback = function()
                    self:showSettings()
                end,
            },
        },
    }
end

function ChapterSummarizer:summarizeChapter()
    UIManager:show(InfoMessage:new{
        text = _("Summarize feature coming soon!"),
        timeout = 2,
    })
end

function ChapterSummarizer:showSettings()
    UIManager:show(InfoMessage:new{
        text = _("Settings coming soon!"),
        timeout = 2,
    })
end

return ChapterSummarizer
```

### Step 2.3: Test Basic Plugin

**If you have KOReader installed:**

```bash
# Copy plugin to KOReader plugins directory
cp -r ../ChapterSummarizer.koplugin ~/.config/koreader/plugins/

# Or on your device
scp -r ChapterSummarizer.koplugin user@device:/mnt/onboard/.adds/koreader/plugins/
```

**Test**: 
1. Open KOReader
2. Open any book
3. Tap the menu
4. Look for "Chapter Summarizer" under Tools
5. Verify the menu appears and shows "coming soon" messages

**Checkpoint**: Plugin loads and menu appears!

## Phase 3: Chapter Text Extraction

### Step 3.1: Understand Document Structure

Add debugging function to `main.lua`:

```lua
function ChapterSummarizer:debugDocumentInfo()
    local doc = self.ui.document
    local toc = doc:getToc()
    
    logger.info("Document info:")
    logger.info("  Pages:", doc:getPageCount())
    logger.info("  Current page:", self.view.state.page)
    logger.info("  TOC entries:", #toc)
    
    for i, entry in ipairs(toc) do
        logger.info(string.format("  [%d] %s (page %d, depth %d)", 
            i, entry.title, entry.page, entry.depth))
    end
end
```

Add to menu for testing:

```lua
{
    text = _("Debug Document Info"),
    callback = function()
        self:debugDocumentInfo()
    end,
},
```

### Step 3.2: Find Current Chapter

Add this function to find which chapter we're in:

```lua
function ChapterSummarizer:getCurrentChapter()
    local doc = self.ui.document
    local toc = doc:getToc()
    
    -- Get current page
    local current_page = self.view.state.page or self.ui.paging.current_page
    
    if not toc or #toc == 0 then
        return nil, _("This document has no table of contents")
    end
    
    -- Find the chapter we're currently in
    local current_chapter = nil
    local next_chapter = nil
    
    for i, entry in ipairs(toc) do
        if entry.page <= current_page then
            current_chapter = entry
            -- Look ahead for next chapter (same depth level)
            for j = i + 1, #toc do
                if toc[j].depth <= entry.depth then
                    next_chapter = toc[j]
                    break
                end
            end
        else
            break
        end
    end
    
    if not current_chapter then
        return nil, _("Could not determine current chapter")
    end
    
    return {
        title = current_chapter.title,
        start_page = current_chapter.page,
        end_page = next_chapter and (next_chapter.page - 1) or doc:getPageCount(),
        depth = current_chapter.depth,
    }
end
```

### Step 3.3: Extract Chapter Text

This is format-specific. For now, we'll extract page by page:

```lua
function ChapterSummarizer:extractChapterText(chapter_info)
    local doc = self.ui.document
    local text_parts = {}
    
    -- Show progress
    UIManager:show(InfoMessage:new{
        text = _("Extracting chapter text..."),
    })
    
    -- For EPUB and other reflowable formats
    if doc.info.has_pages == false then
        -- Try to get text from the document
        -- This is a simplified approach
        local start_pos = doc:getPosFromPageNumber(chapter_info.start_page)
        local end_pos = doc:getPosFromPageNumber(chapter_info.end_page)
        
        if start_pos and end_pos then
            local ok, text = pcall(function()
                return doc:getTextFromPositions(start_pos, end_pos)
            end)
            
            if ok and text then
                return text
            end
        end
    end
    
    -- Fallback: Extract page by page (works for all formats)
    for page = chapter_info.start_page, math.min(chapter_info.end_page, chapter_info.start_page + 50) do
        local ok, page_text = pcall(function()
            return doc:getPageText(page)
        end)
        
        if ok and page_text then
            table.insert(text_parts, page_text)
        end
    end
    
    local full_text = table.concat(text_parts, "\n\n")
    
    -- Clean up text
    full_text = full_text:gsub("\r\n", "\n")
    full_text = full_text:gsub("[ \t]+", " ")
    full_text = full_text:gsub("\n\n+", "\n\n")
    
    return full_text
end
```

### Step 3.4: Add Token Estimation

Add helper function to estimate tokens (rough approximation):

```lua
function ChapterSummarizer:estimateTokens(text)
    -- Rough estimate: 1 token ≈ 4 characters
    return math.ceil(#text / 4)
end

function ChapterSummarizer:truncateText(text, max_tokens)
    local max_chars = max_tokens * 4
    if #text > max_chars then
        logger.warn("Chapter text truncated from", #text, "to", max_chars, "characters")
        return text:sub(1, max_chars) .. "\n\n[Text truncated due to length]"
    end
    return text
end
```

### Step 3.5: Update Summarize Function

```lua
function ChapterSummarizer:summarizeChapter()
    -- Get current chapter
    local chapter_info, err = self:getCurrentChapter()
    if not chapter_info then
        UIManager:show(InfoMessage:new{
            text = err or _("Failed to get chapter information"),
        })
        return
    end
    
    -- Extract text
    local text = self:extractChapterText(chapter_info)
    if not text or #text == 0 then
        UIManager:show(InfoMessage:new{
            text = _("Failed to extract chapter text"),
        })
        return
    end
    
    -- Estimate tokens
    local tokens = self:estimateTokens(text)
    logger.info("Chapter text:", #text, "characters,", tokens, "estimated tokens")
    
    -- Truncate if needed (save room for prompt and response)
    text = self:truncateText(text, 8000)
    
    -- For now, just show the extracted text
    local TextViewer = require("ui/widget/textviewer")
    UIManager:show(TextViewer:new{
        title = chapter_info.title,
        text = string.format("Chapter: %s\nPages: %d-%d\nLength: %d chars\n\n%s",
            chapter_info.title,
            chapter_info.start_page,
            chapter_info.end_page,
            #text,
            text:sub(1, 1000) .. "..."
        ),
    })
end
```

**Checkpoint**: You should be able to extract and view chapter text!

## Phase 4: Settings Management

### Step 4.1: Initialize Settings

Add to the beginning of `main.lua`:

```lua
local LuaSettings = require("luasettings")
```

Update `init()` function:

```lua
function ChapterSummarizer:init()
    logger.info("ChapterSummarizer: Initializing plugin")
    
    -- Initialize settings
    self.settings = LuaSettings:open(
        ("%s/%s"):format(DataStorage:getSettingsDir(), "chapter_summarizer.lua")
    )
    
    -- Load settings with defaults
    self.api_key = self.settings:readSetting("api_key", "")
    self.model = self.settings:readSetting("model", "openai/gpt-3.5-turbo")
    self.prompt = self.settings:readSetting("prompt", 
        "Please provide a concise summary of this chapter in 3-5 sentences, highlighting the key points and main ideas.")
    self.max_summary_tokens = self.settings:readSetting("max_summary_tokens", 500)
    
    self.ui.menu:registerToMainMenu(self)
end
```

Add at top of file:

```lua
local DataStorage = require("datastorage")
```

### Step 4.2: Create Settings Dialog

```lua
function ChapterSummarizer:showSettings()
    local MultiInputDialog = require("ui/widget/multiinputdialog")
    
    self.settings_dialog = MultiInputDialog:new{
        title = _("Chapter Summarizer Settings"),
        fields = {
            {
                text = self.api_key,
                hint = "sk-or-v1-...",
                input_type = "text",
                password = true,
                description = _("OpenRouter API Key"),
            },
            {
                text = self.model,
                hint = "openai/gpt-3.5-turbo",
                input_type = "text",
                description = _("Model (e.g., openai/gpt-4o, anthropic/claude-3-haiku)"),
            },
            {
                text = self.prompt,
                hint = "Summarize this chapter...",
                input_type = "text",
                description = _("Summary Prompt"),
            },
            {
                text = tostring(self.max_summary_tokens),
                hint = "500",
                input_type = "number",
                description = _("Max Summary Tokens"),
            },
        },
        buttons = {
            {
                {
                    text = _("Cancel"),
                    callback = function()
                        UIManager:close(self.settings_dialog)
                    end,
                },
                {
                    text = _("Save"),
                    is_enter_default = true,
                    callback = function()
                        self:saveSettings()
                    end,
                },
            },
        },
    }
    
    UIManager:show(self.settings_dialog)
    self.settings_dialog:onShowKeyboard()
end

function ChapterSummarizer:saveSettings()
    -- Get values from dialog
    local fields = self.settings_dialog:getFields()
    
    self.api_key = fields[1]:gsub("^%s*(.-)%s*$", "%1")  -- Trim whitespace
    self.model = fields[2]:gsub("^%s*(.-)%s*$", "%1")
    self.prompt = fields[3]:gsub("^%s*(.-)%s*$", "%1")
    self.max_summary_tokens = tonumber(fields[4]) or 500
    
    -- Validate API key format
    if self.api_key ~= "" and not self.api_key:match("^sk%-or%-") then
        UIManager:show(InfoMessage:new{
            text = _("Warning: API key should start with 'sk-or-'"),
            timeout = 3,
        })
    end
    
    -- Save to file
    self.settings:saveSetting("api_key", self.api_key)
    self.settings:saveSetting("model", self.model)
    self.settings:saveSetting("prompt", self.prompt)
    self.settings:saveSetting("max_summary_tokens", self.max_summary_tokens)
    self.settings:flush()
    
    UIManager:close(self.settings_dialog)
    
    UIManager:show(InfoMessage:new{
        text = _("Settings saved!"),
        timeout = 1,
    })
end
```

**Checkpoint**: Settings can be configured and saved!

## Phase 5: OpenRouter API Integration

### Step 5.1: Add HTTP Libraries

At the top of `main.lua`:

```lua
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")
```

### Step 5.2: Create API Client Function

```lua
function ChapterSummarizer:callOpenRouter(messages)
    -- Validate API key
    if not self.api_key or self.api_key == "" then
        return nil, _("Please configure your OpenRouter API key in settings")
    end
    
    -- Build request body
    local request_data = {
        model = self.model,
        messages = messages,
        temperature = 0.7,
        max_tokens = self.max_summary_tokens,
    }
    
    local request_body = json.encode(request_data)
    logger.dbg("API Request:", request_body)
    
    -- Prepare response table
    local response_body = {}
    
    -- Make HTTP request
    local res, code, response_headers, status = http.request{
        url = "https://openrouter.ai/api/v1/chat/completions",
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#request_body),
            ["Authorization"] = "Bearer " .. self.api_key,
            ["HTTP-Referer"] = "https://github.com/koreader/koreader",
            ["X-Title"] = "KOReader Chapter Summarizer",
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body),
    }
    
    logger.dbg("API Response Code:", code)
    
    -- Handle HTTP errors
    if code ~= 200 then
        local error_body = table.concat(response_body)
        logger.err("API Error:", code, error_body)
        
        if code == 401 then
            return nil, _("Invalid API key")
        elseif code == 402 then
            return nil, _("Insufficient credits in OpenRouter account")
        elseif code == 429 then
            return nil, _("Rate limited. Please try again later.")
        else
            return nil, _("API error: ") .. tostring(code)
        end
    end
    
    -- Parse response
    local response_text = table.concat(response_body)
    local ok, response_data = pcall(json.decode, response_text)
    
    if not ok then
        logger.err("JSON decode error:", response_data)
        return nil, _("Failed to parse API response")
    end
    
    -- Check for API error in response
    if response_data.error then
        logger.err("API error:", response_data.error.message)
        return nil, _("API error: ") .. response_data.error.message
    end
    
    -- Extract content
    if not response_data.choices or #response_data.choices == 0 then
        return nil, _("No response from API")
    end
    
    local content = response_data.choices[1].message.content
    local usage = response_data.usage
    
    return content, nil, usage
end
```

### Step 5.3: Update Summarize Function

```lua
function ChapterSummarizer:summarizeChapter()
    -- Get current chapter
    local chapter_info, err = self:getCurrentChapter()
    if not chapter_info then
        UIManager:show(InfoMessage:new{
            text = err or _("Failed to get chapter information"),
        })
        return
    end
    
    -- Show progress
    local progress = InfoMessage:new{
        text = _("Extracting chapter text..."),
    }
    UIManager:show(progress)
    UIManager:forceRePaint()
    
    -- Extract text
    local text = self:extractChapterText(chapter_info)
    if not text or #text == 0 then
        UIManager:close(progress)
        UIManager:show(InfoMessage:new{
            text = _("Failed to extract chapter text"),
        })
        return
    end
    
    -- Truncate if needed
    text = self:truncateText(text, 8000)
    
    -- Update progress
    UIManager:close(progress)
    progress = InfoMessage:new{
        text = _("Generating summary..."),
    }
    UIManager:show(progress)
    UIManager:forceRePaint()
    
    -- Build messages for API
    local messages = {
        {
            role = "system",
            content = self.prompt,
        },
        {
            role = "user",
            content = string.format("Chapter: %s\n\n%s", chapter_info.title, text),
        },
    }
    
    -- Call API
    local summary, api_err, usage = self:callOpenRouter(messages)
    
    UIManager:close(progress)
    
    if not summary then
        UIManager:show(InfoMessage:new{
            text = api_err or _("Failed to generate summary"),
            timeout = 3,
        })
        return
    end
    
    -- Show summary
    self:showSummary(chapter_info.title, summary, usage)
end
```

**Checkpoint**: Plugin can now generate summaries using OpenRouter API!

## Phase 6: Summary Display

### Step 6.1: Create Summary Display

```lua
function ChapterSummarizer:showSummary(chapter_title, summary, usage)
    local TextViewer = require("ui/widget/textviewer")
    
    -- Format usage info
    local usage_text = ""
    if usage then
        local cost_estimate = (usage.prompt_tokens * 0.0005 + usage.completion_tokens * 0.0015) / 1000
        usage_text = string.format(
            "\n\n---\nTokens: %d in + %d out = %d total\nEst. cost: $%.4f",
            usage.prompt_tokens,
            usage.completion_tokens,
            usage.total_tokens,
            cost_estimate
        )
    end
    
    local full_text = string.format(
        "Chapter: %s\n\n%s%s",
        chapter_title,
        summary,
        usage_text
    )
    
    local viewer = TextViewer:new{
        title = _("Chapter Summary"),
        text = full_text,
        justified = true,
        buttons_table = {
            {
                {
                    text = _("Copy"),
                    callback = function()
                        -- Copy to clipboard (if supported)
                        local Device = require("device")
                        if Device.hasClipboard() then
                            Device.setClipboardText(summary)
                            UIManager:show(InfoMessage:new{
                                text = _("Summary copied to clipboard"),
                                timeout = 1,
                            })
                        end
                    end,
                },
                {
                    text = _("Save"),
                    callback = function()
                        self:saveSummary(chapter_title, summary)
                    end,
                },
                {
                    text = _("Close"),
                    callback = function()
                        UIManager:close(viewer)
                    end,
                },
            },
        },
    }
    
    UIManager:show(viewer)
end
```

### Step 6.2: Add Save Summary Function

```lua
function ChapterSummarizer:saveSummary(chapter_title, summary)
    local dump = require("dump")
    
    -- Create summaries directory
    local summaries_dir = ("%s/%s"):format(
        DataStorage:getDataDir(), 
        "summaries"
    )
    
    local ok = lfs.mkdir(summaries_dir)
    
    -- Create filename from chapter title
    local filename = chapter_title:gsub("[^%w%s-]", ""):gsub("%s+", "_")
    local filepath = ("%s/%s_%s.txt"):format(
        summaries_dir,
        os.date("%Y%m%d_%H%M%S"),
        filename
    )
    
    -- Write summary to file
    local file = io.open(filepath, "w")
    if file then
        file:write("Chapter: " .. chapter_title .. "\n")
        file:write("Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
        file:write("Model: " .. self.model .. "\n")
        file:write("\n" .. summary .. "\n")
        file:close()
        
        UIManager:show(InfoMessage:new{
            text = _("Summary saved to:\n") .. filepath,
            timeout = 3,
        })
    else
        UIManager:show(InfoMessage:new{
            text = _("Failed to save summary"),
        })
    end
end
```

Add at top:

```lua
local lfs = require("libs/libkoreader-lfs")
```

**Checkpoint**: Summaries can be displayed, copied, and saved!

## Phase 7: User Interface Polish

### Step 7.1: Add Keyboard Shortcut

```lua
function ChapterSummarizer:onDispatcherRegisterActions()
    Dispatcher:registerAction("chapter_summarizer_summarize", {
        category = "none",
        event = "SummarizeChapter",
        title = _("Summarize Current Chapter"),
        general = false,
        reader = true,
    })
end

function ChapterSummarizer:onSummarizeChapter()
    self:summarizeChapter()
    return true
end
```

Update `init()`:

```lua
function ChapterSummarizer:init()
    logger.info("ChapterSummarizer: Initializing plugin")
    
    -- ... existing settings code ...
    
    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
end
```

### Step 7.2: Add Summary History

```lua
function ChapterSummarizer:showSummaryHistory()
    local summaries_dir = ("%s/%s"):format(
        DataStorage:getDataDir(), 
        "summaries"
    )
    
    -- Check if directory exists
    local mode = lfs.attributes(summaries_dir, "mode")
    if mode ~= "directory" then
        UIManager:show(InfoMessage:new{
            text = _("No summaries saved yet"),
        })
        return
    end
    
    -- List summary files
    local files = {}
    for file in lfs.dir(summaries_dir) do
        if file:match("%.txt$") then
            table.insert(files, file)
        end
    end
    
    if #files == 0 then
        UIManager:show(InfoMessage:new{
            text = _("No summaries saved yet"),
        })
        return
    end
    
    -- Sort by date (newest first)
    table.sort(files, function(a, b) return a > b end)
    
    -- Create menu
    local Menu = require("ui/widget/menu")
    local menu_items = {}
    
    for _, file in ipairs(files) do
        table.insert(menu_items, {
            text = file:gsub("%.txt$", ""),
            callback = function()
                self:viewSavedSummary(summaries_dir .. "/" .. file)
            end,
        })
    end
    
    local menu = Menu:new{
        title = _("Summary History"),
        item_table = menu_items,
        is_borderless = true,
        is_popout = false,
        width = Screen:getWidth(),
        height = Screen:getHeight(),
    }
    
    UIManager:show(menu)
end

function ChapterSummarizer:viewSavedSummary(filepath)
    local file = io.open(filepath, "r")
    if not file then
        UIManager:show(InfoMessage:new{
            text = _("Failed to open summary file"),
        })
        return
    end
    
    local content = file:read("*all")
    file:close()
    
    local TextViewer = require("ui/widget/textviewer")
    UIManager:show(TextViewer:new{
        title = _("Saved Summary"),
        text = content,
    })
end
```

Add to menu:

```lua
{
    text = _("Summary History"),
    callback = function()
        self:showSummaryHistory()
    end,
},
```

Add at top:

```lua
local Screen = require("device").screen
```

### Step 7.3: Improve Error Messages

Replace generic error messages with more helpful ones:

```lua
function ChapterSummarizer:showError(title, message, details)
    local ConfirmBox = require("ui/widget/confirmbox")
    
    UIManager:show(ConfirmBox:new{
        text = message .. (details and ("\n\n" .. details) or ""),
        ok_text = _("OK"),
        ok_callback = function()
            -- Do nothing
        end,
        cancel_text = details and _("View Log") or nil,
        cancel_callback = details and function()
            logger.err(title, message, details)
        end or nil,
    })
end
```

**Checkpoint**: User interface is polished and user-friendly!

## Phase 8: Testing & Optimization

### Step 8.1: Test Different Formats

Test your plugin with:
- [ ] EPUB files
- [ ] PDF files
- [ ] MOBI files (if supported)
- [ ] Books with TOC
- [ ] Books without TOC
- [ ] Very long chapters
- [ ] Very short chapters
- [ ] Books with images

### Step 8.2: Handle Edge Cases

Add checks for edge cases:

```lua
function ChapterSummarizer:validateChapter(chapter_info)
    if not chapter_info then
        return false, _("No chapter information available")
    end
    
    local page_count = chapter_info.end_page - chapter_info.start_page + 1
    
    if page_count > 100 then
        local ConfirmBox = require("ui/widget/confirmbox")
        UIManager:show(ConfirmBox:new{
            text = T(_("This chapter is very long (%1 pages). Summarizing may take a while and use many tokens. Continue?"), page_count),
            ok_callback = function()
                return true
            end,
        })
        return false
    end
    
    if page_count < 1 then
        return false, _("Invalid chapter range")
    end
    
    return true
end
```

### Step 8.3: Add Retry Logic

```lua
function ChapterSummarizer:callOpenRouterWithRetry(messages, max_retries)
    max_retries = max_retries or 3
    local last_error = nil
    
    for attempt = 1, max_retries do
        local content, err, usage = self:callOpenRouter(messages)
        
        if content then
            return content, nil, usage
        end
        
        last_error = err
        
        -- Don't retry on auth errors
        if err:find("Invalid API key") or err:find("Insufficient credits") then
            break
        end
        
        -- Wait before retry
        if attempt < max_retries then
            logger.info("Retry attempt", attempt, "after error:", err)
            -- Simple blocking wait (not ideal but works)
            os.execute("sleep 2")
        end
    end
    
    return nil, last_error
end
```

### Step 8.4: Optimize Memory

```lua
function ChapterSummarizer:cleanupResources()
    -- Clear any cached data
    collectgarbage("collect")
end
```

Call after operations:

```lua
function ChapterSummarizer:summarizeChapter()
    -- ... existing code ...
    
    -- Cleanup
    self:cleanupResources()
end
```

### Step 8.5: Performance Testing

Add timing:

```lua
function ChapterSummarizer:summarizeChapter()
    local start_time = os.time()
    
    -- ... existing code ...
    
    local elapsed = os.time() - start_time
    logger.info("Summary generation took", elapsed, "seconds")
end
```

**Checkpoint**: Plugin handles edge cases and performs well!

## Phase 9: Documentation

### Step 9.1: Create README.md

```markdown
# Chapter Summarizer Plugin for KOReader

AI-powered chapter summaries using OpenRouter.ai

## Features

- Extract text from current chapter
- Generate AI summaries with customizable prompts
- Support for multiple AI models (GPT-4, Claude, etc.)
- Save and view summary history
- Token usage tracking

## Installation

1. Download `ChapterSummarizer.koplugin.zip`
2. Extract to your KOReader plugins directory:
   - Android: `/sdcard/koreader/plugins/`
   - Kobo: `/mnt/onboard/.adds/koreader/plugins/`
   - Kindle: `/mnt/us/koreader/plugins/`
3. Restart KOReader
4. Enable plugin in: Menu > Plugins > Chapter Summarizer

## Setup

1. Get an API key from [OpenRouter.ai](https://openrouter.ai/)
2. Add credits to your OpenRouter account
3. In KOReader, open any book
4. Go to Menu > Tools > Chapter Summarizer > Settings
5. Enter your API key
6. (Optional) Customize the model and prompt
7. Save settings

## Usage

### Summarize Current Chapter

1. Open a book
2. Navigate to any chapter
3. Menu > Tools > Chapter Summarizer > Summarize Current Chapter
4. Wait for the summary to generate
5. View, copy, or save the summary

### View History

Menu > Tools > Chapter Summarizer > Summary History

### Keyboard Shortcut

You can assign a keyboard shortcut:
1. Menu > Settings > Taps and gestures > Dispatcher
2. Find "Summarize Current Chapter"
3. Assign to a gesture or button

## Models

Popular models you can use:
- `openai/gpt-3.5-turbo` - Fast and cheap ($0.50/$1.50 per 1M tokens)
- `openai/gpt-4o` - Most capable ($5/$15 per 1M tokens)
- `anthropic/claude-3-haiku` - Fast and affordable ($0.25/$1.25 per 1M tokens)
- `anthropic/claude-3-sonnet` - Balanced ($3/$15 per 1M tokens)

See [OpenRouter Models](https://openrouter.ai/models) for full list.

## Troubleshooting

### "Please configure your API key"
- Go to Settings and enter your OpenRouter API key

### "Invalid API key"
- Check that your API key starts with `sk-or-`
- Verify it's copied correctly (no spaces)

### "Insufficient credits"
- Add credits to your OpenRouter account

### "Failed to extract chapter text"
- Some books don't have proper chapter markers
- Try a different book or page

### "Chapter is very long"
- Long chapters use more tokens and cost more
- The plugin will truncate very long chapters

## Support

- Report issues: [GitHub Issues](https://github.com/yourusername/chapter-summarizer)
- KOReader Forum: [koreader.rocks](https://github.com/koreader/koreader/discussions)

## License

MIT License - See LICENSE file

## Credits

- KOReader Team
- OpenRouter.ai
```

### Step 9.2: Add Inline Comments

Go through your code and add helpful comments:

```lua
-- Extract chapter boundaries from table of contents
function ChapterSummarizer:getCurrentChapter()
    -- ... code with comments ...
end
```

### Step 9.3: Create CHANGELOG.md

```markdown
# Changelog

## [1.0.0] - 2025-01-XX

### Added
- Initial release
- Chapter text extraction from EPUB and PDF
- OpenRouter API integration
- Configurable prompts and models
- Summary history
- Copy to clipboard
- Save summaries to file
- Token usage tracking
```

**Checkpoint**: Documentation is complete and helpful!

## Phase 10: Deployment

### Step 10.1: Create Package

```bash
# Create a zip file for distribution
zip -r ChapterSummarizer.koplugin.zip ChapterSummarizer.koplugin/ \
    -x "*.git*" \
    -x "*koreader/*" \
    -x "*.DS_Store"
```

### Step 10.2: Test Installation

Test the installation process:

1. Create a fresh KOReader install (or use emulator)
2. Install your plugin from the zip
3. Verify it works correctly

### Step 10.3: Create GitHub Repository

```bash
# Create repo on GitHub, then:
git remote add origin https://github.com/yourusername/koreader-chapter-summarizer.git
git add .
git commit -m "Initial release"
git push -u origin main

# Create a release
git tag v1.0.0
git push origin v1.0.0
```

### Step 10.4: Submit to KOReader (Optional)

If you want your plugin included in KOReader:

1. Fork [koreader/koreader](https://github.com/koreader/koreader)
2. Add your plugin to `plugins/`
3. Create a pull request
4. Follow review process

**Checkpoint**: Plugin is packaged and ready for distribution!

## Troubleshooting

### Common Issues

#### Plugin doesn't appear in menu
- Check `_meta.lua` name matches directory
- Look for Lua syntax errors
- Check KOReader logs

#### "attempt to index nil value"
- Add nil checks: `if self.ui and self.ui.document then`
- Verify `is_doc_only` is set correctly

#### API calls fail
- Test API key with curl first
- Check network connectivity
- Verify JSON encoding/decoding

#### Memory issues on device
- Reduce max chapter length
- Clear cache more often
- Test on actual device, not just emulator

### Debug Commands

```lua
-- Add throughout code for debugging
logger.info("Variable value:", variable)
logger.dbg("Debug info:", table)
logger.err("Error:", error_message)
```

View logs:
- Emulator: Check terminal output
- Device: Check `/mnt/onboard/.adds/koreader/crash.log`

## Next Steps

### Possible Enhancements

1. **Streaming support** - Show summary as it's generated
2. **Multiple chapters** - Summarize a range of chapters
3. **Compare models** - Generate summaries with different models
4. **Export formats** - Export to Markdown, PDF
5. **Cloud sync** - Sync summaries across devices
6. **Custom templates** - Different summary styles
7. **Highlight extraction** - Include highlighted passages
8. **Translation** - Translate summaries to other languages

### Learning Resources

- [KOReader Documentation](https://koreader.rocks/doc/)
- [Lua Programming Guide](https://www.lua.org/pil/)
- [OpenRouter API Docs](https://openrouter.ai/docs)
- Example plugins in KOReader source

## Conclusion

You now have a complete, working Chapter Summarizer plugin! 

Key achievements:
- ✅ Extract chapter text from ebooks
- ✅ Integrate with OpenRouter API
- ✅ Generate AI summaries
- ✅ Manage settings and history
- ✅ Handle errors gracefully
- ✅ Polish UI/UX
- ✅ Document everything

**Congratulations on building your first KOReader plugin!** 🎉

---

## Quick Reference

### File Structure
```
ChapterSummarizer.koplugin/
├── _meta.lua           # Plugin metadata
├── main.lua            # Main plugin code
├── README.md           # User documentation
├── CHANGELOG.md        # Version history
└── LICENSE             # License file
```

### Key Functions
```lua
:init()                        -- Initialize plugin
:addToMainMenu()               -- Add menu entries
:getCurrentChapter()           -- Find current chapter
:extractChapterText()          -- Extract text
:callOpenRouter()              -- API call
:showSummary()                 -- Display results
:saveSettings()                -- Save configuration
```

### Testing Checklist
- [ ] Plugin loads without errors
- [ ] Settings can be configured
- [ ] Chapter detection works
- [ ] Text extraction works
- [ ] API calls succeed
- [ ] Summaries display correctly
- [ ] History feature works
- [ ] Error handling works
- [ ] Works on actual device

Happy coding! 🚀
