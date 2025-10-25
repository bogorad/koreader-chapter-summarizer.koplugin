# KOReader Plugin Development Guide

## Table of Contents
- [Introduction](#introduction)
- [Getting Started](#getting-started)
- [Plugin Structure](#plugin-structure)
- [Core Components](#core-components)
- [Hello World Example](#hello-world-example)
- [Key Modules & APIs](#key-modules--apis)
- [Development Workflow](#development-workflow)
- [Best Practices](#best-practices)
- [Resources](#resources)

## Introduction

### What are KOReader Plugins?

KOReader is an open-source ebook reader application that supports PDF, DJVU, EPUB, FB2, and many more formats. It runs on various devices including Kindle, Kobo, PocketBook, Ubuntu Touch, and Android devices. The entire frontend is written in **Lua**, making it highly extensible through plugins.

Plugins allow you to:
- Add new features to the reader
- Integrate with external services
- Customize the reading experience
- Process and transform documents
- Add UI elements and menu items
- Handle events and gestures

### Why Develop Plugins?

- **Easy to Learn**: If you know basic Lua or are willing to learn, you can create plugins
- **No Compilation**: Lua is interpreted, so you can test changes immediately
- **Rich API**: Access to document manipulation, UI widgets, settings, and more
- **Active Community**: Many example plugins to learn from
- **Direct Integration**: Your plugin becomes part of the KOReader experience

## Getting Started

### Prerequisites

- Basic knowledge of Lua programming
- Text editor or IDE (VS Code, Vim, Emacs, etc.)
- Git for version control
- KOReader source code (for reference and LSP)

### Development Environment Setup

#### 1. Create Plugin Directory

By convention, KOReader plugins use the `.koplugin` suffix:

```bash
mkdir MyPlugin.koplugin
cd MyPlugin.koplugin
git init -b main
```

#### 2. Add KOReader as Submodule

This gives you access to the source code for reference and enables LSP autocomplete:

```bash
git submodule add https://github.com/koreader/koreader.git
```

#### 3. Configure LSP (Language Server Protocol)

Create a `.luarc.json` file in your plugin root directory:

```json
{
  "workspace": {
    "library": ["./koreader/frontend"],
    "ignoreDir": [".vscode", ".git"]
  }
}
```

This tells your editor where to find KOReader's Lua modules for autocomplete and type checking.

## Plugin Structure

### Required Files

Every KOReader plugin must have at least two files:

1. **`_meta.lua`** - Plugin metadata and description
2. **`main.lua`** - Main plugin logic and entrypoint

### Directory Structure

```
MyPlugin.koplugin/
├── _meta.lua           # Plugin metadata
├── main.lua            # Main plugin code
├── settings.lua        # Settings management (optional)
├── assets/             # Images, icons (optional)
│   └── icon.png
├── lib/                # Helper modules (optional)
│   └── utils.lua
└── README.md           # Documentation
```

### Naming Conventions

- Plugin directory: `PluginName.koplugin`
- Main module: `main.lua`
- Metadata: `_meta.lua`
- Additional modules: lowercase with underscores (e.g., `api_client.lua`)

## Core Components

### 1. WidgetContainer

Base class for all plugins. Provides:
- Event handling
- Widget lifecycle management
- Child widget management
- Painting and layout

```lua
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local MyPlugin = WidgetContainer:extend{
    name = "my_plugin",
    is_doc_only = false,  -- false = works everywhere, true = only in document view
}
```

### 2. UIManager

Manages the UI, windows, and screen updates:

```lua
local UIManager = require("ui/uimanager")

-- Show a widget
UIManager:show(widget)

-- Close a widget
UIManager:close(widget)

-- Schedule a function
UIManager:scheduleIn(2, function()
    print("Executed after 2 seconds")
end)

-- Refresh screen
UIManager:setDirty(widget, "partial")
```

### 3. Dispatcher

Event system for registering and triggering actions:

```lua
local Dispatcher = require("dispatcher")

-- Register an action
Dispatcher:registerAction("my_action", {
    category = "none",
    event = "MyEvent",
    title = _("My Action"),
    general = true,
})
```

### 4. Event System

Events are messages passed through the widget tree. Each event has:
- `name`: Event identifier
- `args`: Arguments passed to the handler

Widgets implement event handlers with the pattern `on{EventName}`:

```lua
function MyPlugin:onMyEvent(arg1, arg2)
    -- Handle the event
    return true  -- true = event consumed, stops propagation
end
```

### 5. Settings Management

Store plugin configuration:

```lua
local LuaSettings = require("luasettings")

-- Open settings file
self.settings = LuaSettings:open("path/to/settings.lua")

-- Read setting
local value = self.settings:readSetting("key", default_value)

-- Save setting
self.settings:saveSetting("key", value)

-- Flush to disk
self.settings:flush()
```

## Hello World Example

### `_meta.lua`

```lua
local _ = require("gettext")
return {
    name = "hello_world",
    fullname = _("Hello World"),
    description = _([[This is a Hello World plugin that demonstrates basic plugin functionality.]]),
}
```

### `main.lua`

```lua
--[[--
Hello World Plugin for KOReader

@module koplugin.HelloWorld
--]]--

local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local HelloWorld = WidgetContainer:extend{
    name = "hello_world",
    is_doc_only = false,
}

-- Register dispatcher action for keyboard shortcuts
function HelloWorld:onDispatcherRegisterActions()
    Dispatcher:registerAction("helloworld_action", {
        category = "none",
        event = "HelloWorld",
        title = _("Hello World"),
        general = true,
    })
end

-- Initialize plugin
function HelloWorld:init()
    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
end

-- Add menu entry
function HelloWorld:addToMainMenu(menu_items)
    menu_items.hello_world = {
        text = _("Hello World"),
        sorting_hint = "more_tools",  -- Which menu to appear in
        callback = function()
            self:showMessage()
        end,
    }
end

-- Show the message
function HelloWorld:showMessage()
    local popup = InfoMessage:new{
        text = _("Hello World from KOReader!"),
        timeout = 2,  -- Auto-close after 2 seconds
    }
    UIManager:show(popup)
end

-- Event handler (can be triggered by Dispatcher)
function HelloWorld:onHelloWorld()
    self:showMessage()
    return true
end

return HelloWorld
```

### Explanation

**`_meta.lua` breakdown:**
- `name`: Internal identifier (must match directory name without `.koplugin`)
- `fullname`: Display name shown in plugin manager
- `description`: Description shown in plugin manager
- `_()`: gettext function for internationalization

**`main.lua` breakdown:**
1. **Module imports**: Require all needed modules
2. **Widget definition**: Extend WidgetContainer
3. **Dispatcher registration**: Register actions for keyboard shortcuts
4. **Initialization**: Called when plugin loads
5. **Menu integration**: Add entry to main menu
6. **Event handlers**: Handle events (named `on{EventName}`)

## Key Modules & APIs

### UI Widgets

#### InfoMessage
Simple notification popup:

```lua
local InfoMessage = require("ui/widget/infomessage")

local message = InfoMessage:new{
    text = "Hello!",
    timeout = 3,  -- Auto-close after 3 seconds
}
UIManager:show(message)
```

#### ConfirmBox
Yes/No dialog:

```lua
local ConfirmBox = require("ui/widget/confirmbox")

UIManager:show(ConfirmBox:new{
    text = _("Are you sure?"),
    ok_callback = function()
        -- User clicked OK
    end,
    cancel_callback = function()
        -- User clicked Cancel
    end,
})
```

#### InputDialog
Text input dialog:

```lua
local InputDialog = require("ui/widget/inputdialog")

self.input_dialog = InputDialog:new{
    title = _("Enter Text"),
    input = "default value",
    input_type = "text",
    buttons = {
        {
            {
                text = _("Cancel"),
                callback = function()
                    UIManager:close(self.input_dialog)
                end,
            },
            {
                text = _("OK"),
                is_enter_default = true,
                callback = function()
                    local text = self.input_dialog:getInputText()
                    -- Use the text
                    UIManager:close(self.input_dialog)
                end,
            },
        },
    },
}
UIManager:show(self.input_dialog)
self.input_dialog:onShowKeyboard()
```

#### TextViewer
Display formatted text:

```lua
local TextViewer = require("ui/widget/textviewer")

local viewer = TextViewer:new{
    title = _("Document"),
    text = long_text,
    justified = true,
}
UIManager:show(viewer)
```

#### ButtonDialog
Grid of buttons:

```lua
local ButtonDialog = require("ui/widget/buttondialog")

UIManager:show(ButtonDialog:new{
    title = _("Choose Action"),
    buttons = {
        {
            {
                text = _("Action 1"),
                callback = function()
                    -- Action 1
                end,
            },
            {
                text = _("Action 2"),
                callback = function()
                    -- Action 2
                end,
            },
        },
        {
            {
                text = _("Cancel"),
                callback = function()
                    -- Cancel
                end,
            },
        },
    },
})
```

### Document API

Access the current document:

```lua
-- In ReaderUI context (is_doc_only = true plugins)
local document = self.ui.document

-- Get page count
local pages = document:getPageCount()

-- Get current page
local current_page = self.ui.paging.current_page

-- Get table of contents
local toc = document:getToc()
-- Returns: { {title = "Chapter 1", page = 1}, ... }

-- For text documents (EPUB, etc.)
local text = document:getTextFromPositions(start_pos, end_pos)
```

### Network Requests

KOReader includes LuaSocket for network operations:

```lua
local socket = require("socket")
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")

-- Simple GET request
local response_body = {}
local res, code, headers = http.request{
    url = "https://api.example.com/data",
    sink = ltn12.sink.table(response_body)
}

if code == 200 then
    local data = json.decode(table.concat(response_body))
    -- Process data
end

-- POST request with JSON
local request_body = json.encode({key = "value"})
local response_body = {}
local res, code = http.request{
    url = "https://api.example.com/endpoint",
    method = "POST",
    headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = #request_body,
        ["Authorization"] = "Bearer " .. api_key,
    },
    source = ltn12.source.string(request_body),
    sink = ltn12.sink.table(response_body),
}
```

### Internationalization (i18n)

Use gettext for translations:

```lua
local _ = require("gettext")

-- Simple translation
local text = _("Hello World")

-- Translation with placeholders
local text = T(_("Page %1 of %2"), current_page, total_pages)

-- Plural forms
local text = N_("1 page", "%1 pages", count)
```

### Logging

```lua
local logger = require("logger")

logger.info("Information message")
logger.warn("Warning message")
logger.err("Error message")
logger.dbg("Debug message")
```

## Development Workflow

### 1. Local Development

Create your plugin in the KOReader plugins directory:
```bash
cd koreader/plugins/
mkdir MyPlugin.koplugin
cd MyPlugin.koplugin
```

### 2. Testing

Run KOReader in emulator mode:
```bash
cd koreader
./kodev build
./kodev run
```

Or copy plugin to your device and test:
```bash
scp -r MyPlugin.koplugin user@device:/path/to/koreader/plugins/
```

### 3. Debugging

Add debug prints:
```lua
local logger = require("logger")
logger.dbg("Debug: ", variable)
```

Check logs on device or emulator for errors.

### 4. Code Quality

Use `luacheck` for static analysis:
```bash
luacheck main.lua
```

### 5. Packaging

Create a zip file for distribution:
```bash
zip -r MyPlugin.koplugin.zip MyPlugin.koplugin/
```

## Best Practices

### 1. Error Handling

Always wrap risky operations:
```lua
local ok, result = pcall(function()
    return risky_operation()
end)

if not ok then
    logger.err("Error:", result)
    UIManager:show(InfoMessage:new{
        text = _("An error occurred"),
    })
    return
end
```

### 2. Settings Persistence

Save settings after changes:
```lua
self.settings:saveSetting("key", value)
self.settings:flush()
```

### 3. Widget Cleanup

Close widgets when done:
```lua
function MyPlugin:onClose()
    UIManager:close(self.dialog)
    -- Clean up resources
end
```

### 4. Event Consumption

Return `true` to stop event propagation:
```lua
function MyPlugin:onMyEvent()
    -- Handle event
    return true  -- Prevents other widgets from receiving this event
end
```

### 5. Internationalization

Always wrap user-facing strings:
```lua
-- Good
text = _("Hello World")

-- Bad
text = "Hello World"
```

### 6. Documentation

Add LDoc comments:
```lua
--[[--
Processes the document text.

@param text string The input text
@return string The processed text
--]]
function MyPlugin:processText(text)
    return text:upper()
end
```

### 7. Performance

Avoid blocking operations:
```lua
-- Show progress indicator for long operations
UIManager:show(InfoMessage:new{
    text = _("Processing..."),
})

-- Do work
process_data()

-- Update UI
UIManager:close(progress_message)
```

## Resources

### Official Documentation
- [KOReader Documentation](https://koreader.rocks/doc/)
- [KOReader GitHub](https://github.com/koreader/koreader)
- [Plugin API Reference](https://koreader.rocks/doc/modules/pluginloader.html)
- [Development Guide](https://koreader.rocks/doc/topics/Development_guide.md.html)
- [Events Documentation](https://koreader.rocks/doc/topics/Events.md.html)

### Example Plugins
Study these well-written plugins:
- [HelloWorld](https://github.com/koreader/koreader/tree/master/plugins/hello.koplugin) - Basic example
- [Wallabag](https://github.com/koreader/koreader/tree/master/plugins/wallabag.koplugin) - Network integration
- [Calibre](https://github.com/koreader/koreader/tree/master/plugins/calibre.koplugin) - Complex features
- [Terminal](https://github.com/koreader/koreader/tree/master/plugins/terminal.koplugin) - Advanced UI

### Community
- [KOReader Forum](https://github.com/koreader/koreader/discussions)
- [Discord Server](https://discord.gg/kindle)
- [Reddit r/koreader](https://www.reddit.com/r/koreader/)

### Lua Resources
- [Lua Reference Manual](https://www.lua.org/manual/5.1/)
- [Programming in Lua](https://www.lua.org/pil/)
- [Learn Lua in Y Minutes](https://learnxinyminutes.com/docs/lua/)

### Development Tools
- [kopl CLI](https://github.com/consoleaf/kopl) - Plugin development CLI
- [Lua Language Server](https://github.com/LuaLS/lua-language-server) - LSP for editors
- [luacheck](https://github.com/mpeterv/luacheck) - Static analyzer

## Common Issues

### Plugin Not Loading
- Check plugin directory name ends with `.koplugin`
- Verify `_meta.lua` name field matches directory
- Check for syntax errors in Lua files
- Look at KOReader logs for error messages

### Events Not Working
- Make sure handler is named `on{EventName}`
- Return `true` to consume event
- Register with Dispatcher if using keyboard shortcuts

### UI Not Updating
- Call `UIManager:setDirty()` after changes
- Make sure widgets are shown with `UIManager:show()`
- Close old widgets before showing new ones

### Settings Not Saving
- Call `self.settings:flush()` after changes
- Check file permissions on device
- Verify settings path is correct

### Network Requests Failing
- Check device has network access
- Verify API endpoint URL
- Add proper error handling
- Check for SSL/TLS issues

---

**Happy Plugin Development!** 🚀
