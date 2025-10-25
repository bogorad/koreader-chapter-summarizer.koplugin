--[[--
Chapter Summarizer Plugin for KOReader

@module koplugin.ChapterSummarizer
--]]
--

local DataStorage = require("datastorage")
local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local LuaSettings = require("luasettings")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")
local T = require("ffi/util").template
local logger = require("logger")
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")
local lfs = require("libs/libkoreader-lfs")
local Screen = require("device").screen

local ChapterSummarizer = WidgetContainer:extend({
  name = "chaptersummarizer",
  is_doc_only = true,
})

function ChapterSummarizer:init()
  logger.info("ChapterSummarizer: Initializing")
  self.settings = LuaSettings:open(("%s/%s"):format(DataStorage:getSettingsDir(), "chapter_summarizer.lua"))
  self.api_key = self.settings:readSetting("api_key", "")
  self.model = self.settings:readSetting("model", "x-ai/grok-4-fast")
  self.prompt = self.settings:readSetting(
    "prompt",
    "Summarize chapter in 3-5 paragraphs. Do not inflate the paragraph count, only grow the number above 3 if necessary. Return ONLY plain text without any markdown formatting, bullet points, or special characters."
  )
  self.max_summary_tokens = self.settings:readSetting("max_summary_tokens", 1000)
  self:onDispatcherRegisterActions()
  self.ui.menu:registerToMainMenu(self)
end

function ChapterSummarizer:onDispatcherRegisterActions()
  Dispatcher:registerAction("chapter_summarizer_summarize", {
    category = "none",
    event = "SummarizeChapter",
    title = _("Summarize Current Chapter"),
    general = false,
    reader = true,
  })
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
      {
        text = _("Summary History"),
        callback = function()
          self:showSummaryHistory()
        end,
      },
    },
  }
end

function ChapterSummarizer:onSummarizeChapter()
  self:summarizeChapter()
  return true
end

function ChapterSummarizer:getCurrentChapter()
  local doc = self.ui.document
  local toc = doc:getToc()
  local current_page = self.view.state.page or self.ui.paging.current_page
  if not toc or #toc == 0 then
    return nil, _("This document has no table of contents")
  end
  local current_chapter, next_chapter = nil, nil
  for i, entry in ipairs(toc) do
    if entry.page <= current_page then
      current_chapter = entry
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

function ChapterSummarizer:extractChapterText(chapter_info)
  local doc = self.ui.document
  local text_parts = {}

  UIManager:show(InfoMessage:new({
    text = _("Extracting chapter text..."),
  }))

  -- For EPUB and other CRE documents (reflowable formats)
  if doc.info.has_pages == false then
    -- Get XPointers for start and end pages
    local start_xp = doc:getPageXPointer(chapter_info.start_page)
    local end_xp = doc:getPageXPointer(chapter_info.end_page)

    if start_xp and end_xp then
      local ok, text = pcall(function()
        return doc:getTextFromXPointers(start_xp, end_xp, false)
      end)

      if ok and text and text.text then
        return text.text
      end
    end
  end

  -- Fallback: Extract page by page (works for all formats including PDFs)
  -- Limit to 50 pages to avoid excessive token usage
  local max_pages = math.min(chapter_info.end_page, chapter_info.start_page + 50)

  for page = chapter_info.start_page, max_pages do
    local ok, page_text = pcall(function()
      -- For CRE documents, we need to navigate to the page and get text
      if doc.getPageXPointer then
        local xp = doc:getPageXPointer(page)
        if xp then
          return doc:getTextFromXPointer(xp)
        end
      else
        -- For PDF/DJVU documents
        return doc:getPageText(page)
      end
    end)

    if ok and page_text then
      table.insert(text_parts, page_text)
    end
  end

  if #text_parts == 0 then
    return nil
  end

  local full_text = table.concat(text_parts, "\n\n")

  -- Clean up text
  full_text = full_text:gsub("\r\n", "\n")
  full_text = full_text:gsub("[ \t]+", " ")
  full_text = full_text:gsub("\n\n+", "\n\n")

  return full_text
end

function ChapterSummarizer:estimateTokens(text)
  return math.ceil(#text / 4)
end

function ChapterSummarizer:truncateText(text, max_tokens)
  local max_chars = max_tokens * 4
  if #text > max_chars then
    logger.warn("Chapter text truncated")
    return text:sub(1, max_chars) .. "\n\n[Text truncated]"
  end
  return text
end

function ChapterSummarizer:callOpenRouter(messages)
  if not self.api_key or self.api_key == "" then
    return nil, _("Please configure your OpenRouter API key in settings")
  end
  local request_body =
    json.encode({ model = self.model, messages = messages, temperature = 0.7, max_tokens = self.max_summary_tokens })
  local response_body = {}
  local res, code = http.request({
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
  })
  if code ~= 200 then
    if code == 401 then
      return nil, _("Invalid API key")
    elseif code == 402 then
      return nil, _("Insufficient credits")
    elseif code == 429 then
      return nil, _("Rate limited")
    else
      return nil, _("API error: ") .. tostring(code)
    end
  end
  local ok, response_data = pcall(json.decode, table.concat(response_body))
  if not ok or response_data.error then
    return nil, _("API error")
  end
  if not response_data.choices or #response_data.choices == 0 then
    return nil, _("No response")
  end
  return response_data.choices[1].message.content, nil, response_data.usage
end

function ChapterSummarizer:summarizeChapter()
  local chapter_info, err = self:getCurrentChapter()
  if not chapter_info then
    UIManager:show(InfoMessage:new({ text = err }))
    return
  end
  local page_count = chapter_info.end_page - chapter_info.start_page + 1
  if page_count > 100 then
    UIManager:show(require("ui/widget/confirmbox"):new({
      text = T(_("Long chapter (%1 pages). Continue?"), page_count),
      ok_callback = function()
        self:performSummarize(chapter_info)
      end,
    }))
    return
  end
  self:performSummarize(chapter_info)
end

function ChapterSummarizer:performSummarize(chapter_info)
  local progress = InfoMessage:new({ text = _("Extracting text...") })
  UIManager:show(progress)
  UIManager:forceRePaint()
  local text = self:extractChapterText(chapter_info)
  if not text or #text == 0 then
    UIManager:close(progress)
    UIManager:show(InfoMessage:new({ text = _("Failed to extract text") }))
    return
  end
  text = self:truncateText(text, 8000)
  UIManager:close(progress)
  progress = InfoMessage:new({ text = _("Generating summary...") })
  UIManager:show(progress)
  UIManager:forceRePaint()
  local summary, api_err, usage = self:callOpenRouter({
    { role = "system", content = self.prompt },
    { role = "user", content = string.format("Chapter: %s\n\n%s", chapter_info.title, text) },
  })
  UIManager:close(progress)
  if not summary then
    UIManager:show(InfoMessage:new({ text = api_err, timeout = 3 }))
    return
  end
  self:showSummary(chapter_info.title, summary, usage)
end

function ChapterSummarizer:showSummary(chapter_title, summary, usage)
  local usage_text = ""
  if usage then
    local cost = (usage.prompt_tokens * 0.0005 + usage.completion_tokens * 0.0015) / 1000
    usage_text = string.format(
      "\n\n---\nTokens: %d+%d=%d\nCost: $%.4f",
      usage.prompt_tokens or 0,
      usage.completion_tokens or 0,
      usage.total_tokens or 0,
      cost
    )
  end
  UIManager:show(require("ui/widget/textviewer"):new({
    title = _("Chapter Summary"),
    text = string.format("Chapter: %s\n\n%s%s", chapter_title, summary, usage_text),
    buttons_table = {
      {
        {
          text = _("Copy"),
          callback = function()
            local Device = require("device")
            if Device.hasClipboard() then
              Device.setClipboardText(summary)
            end
            UIManager:show(InfoMessage:new({ text = _("Copied"), timeout = 1 }))
          end,
        },
        {
          text = _("Save"),
          callback = function()
            self:saveSummary(chapter_title, summary)
          end,
        },
        { text = _("Close") },
      },
    },
  }))
end

function ChapterSummarizer:saveSummary(chapter_title, summary)
  local dir = DataStorage:getDataDir() .. "/summaries"
  lfs.mkdir(dir)
  local filename = chapter_title:gsub("[^%w%s-]", ""):gsub("%s+", "_")
  local filepath = string.format("%s/%s_%s.txt", dir, os.date("%Y%m%d_%H%M%S"), filename)
  local file = io.open(filepath, "w")
  if file then
    file:write(
      string.format(
        "Chapter: %s\nDate: %s\nModel: %s\n\n%s\n",
        chapter_title,
        os.date("%Y-%m-%d %H:%M:%S"),
        self.model,
        summary
      )
    )
    file:close()
    UIManager:show(InfoMessage:new({ text = _("Saved!"), timeout = 2 }))
  end
end

function ChapterSummarizer:showSummaryHistory()
  local dir = DataStorage:getDataDir() .. "/summaries"
  if lfs.attributes(dir, "mode") ~= "directory" then
    UIManager:show(InfoMessage:new({ text = _("No summaries yet") }))
    return
  end
  local files = {}
  for file in lfs.dir(dir) do
    if file:match("%.txt$") then
      table.insert(files, file)
    end
  end
  if #files == 0 then
    UIManager:show(InfoMessage:new({ text = _("No summaries yet") }))
    return
  end
  table.sort(files, function(a, b)
    return a > b
  end)
  local items = {}
  for _, file in ipairs(files) do
    table.insert(items, {
      text = file:gsub("%.txt$", ""):gsub("_", " "),
      callback = function()
        self:viewSavedSummary(dir .. "/" .. file)
      end,
    })
  end
  UIManager:show(require("ui/widget/menu"):new({
    title = _("Summary History"),
    item_table = items,
    width = Screen:getWidth(),
    height = Screen:getHeight(),
  }))
end

function ChapterSummarizer:viewSavedSummary(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return
  end
  local content = file:read("*all")
  file:close()
  UIManager:show(require("ui/widget/textviewer"):new({ title = _("Saved Summary"), text = content }))
end

function ChapterSummarizer:showSettings()
  self.settings_dialog = require("ui/widget/multiinputdialog"):new({
    title = _("Chapter Summarizer Settings"),
    fields = {
      {
        text = self.api_key,
        hint = "sk-or-v1-...",
        input_type = "text",
        password = true,
        description = _("OpenRouter API Key"),
      },
      { text = self.model, hint = "x-ai/grok-beta", input_type = "text", description = _("Model") },
      { text = self.prompt, hint = "Summarize...", input_type = "text", description = _("Prompt") },
      {
        text = tostring(self.max_summary_tokens),
        hint = "500",
        input_type = "number",
        description = _("Max Tokens (100-2000)"),
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
  })
  UIManager:show(self.settings_dialog)
  self.settings_dialog:onShowKeyboard()
end

function ChapterSummarizer:saveSettings()
  local fields = self.settings_dialog:getFields()
  self.api_key = fields[1]:gsub("^%s*(.-)%s*$", "%1")
  self.model = fields[2]:gsub("^%s*(.-)%s*$", "%1")
  self.prompt = fields[3]:gsub("^%s*(.-)%s*$", "%1")
  self.max_summary_tokens = math.max(100, math.min(2000, tonumber(fields[4]) or 500))
  self.settings:saveSetting("api_key", self.api_key)
  self.settings:saveSetting("model", self.model)
  self.settings:saveSetting("prompt", self.prompt)
  self.settings:saveSetting("max_summary_tokens", self.max_summary_tokens)
  self.settings:flush()
  UIManager:close(self.settings_dialog)
  UIManager:show(InfoMessage:new({ text = _("Settings saved!"), timeout = 1 }))
end

return ChapterSummarizer
