-- Usage: [text]{.explain color="yellow" note="Explanation with $math$."}
-- Non-HTML formats keep only the highlighted text.

local highlight_class = "explain"
local rendered_class = "explained-highlight"

local color_aliases = {
  yellow = "#fff3bf",
  gold = "#ffe8a3",
  orange = "#ffddb3",
  green = "#d9f7d7",
  mint = "#d4f5e9",
  blue = "#dceeff",
  purple = "#eadffd",
  pink = "#ffdbe8",
  red = "#ffd6d6",
  gray = "#e8ecef",
  grey = "#e8ecef"
}

local border_aliases = {
  yellow = "#b7791f",
  gold = "#b7791f",
  orange = "#c05621",
  green = "#3f8f46",
  mint = "#2c7a7b",
  blue = "#2b6cb0",
  purple = "#6b46c1",
  pink = "#b83280",
  red = "#c53030",
  gray = "#64748b",
  grey = "#64748b"
}

local note_attributes = {
  "note",
  "explanation",
  "data-note",
  "data-explanation"
}

local color_attributes = {
  "color",
  "highlight-color",
  "background",
  "bg"
}

local counter = 0

local function has_class(classes, class)
  for _, existing_class in ipairs(classes) do
    if existing_class == class then
      return true
    end
  end
  return false
end

local function copy_attributes(attributes)
  local copied = {}
  for key, value in pairs(attributes) do
    copied[key] = value
  end
  return copied
end

local function first_attribute(attributes, names)
  for _, name in ipairs(names) do
    if attributes[name] and attributes[name] ~= "" then
      return attributes[name]
    end
  end
  return nil
end

local function clean_css_value(value)
  if not value then
    return nil
  end

  value = value:gsub("^%s+", ""):gsub("%s+$", "")
  if value == "" or value:find("[;{}]") then
    return nil
  end

  return color_aliases[value:lower()] or value
end

local function add_style_property(attributes, property, value)
  value = clean_css_value(value)
  if not value then
    return
  end

  local style = attributes.style or ""
  if style ~= "" and not style:match(";%s*$") then
    style = style .. ";"
  end

  attributes.style = style .. " " .. property .. ": " .. value .. ";"
end

local function parsed_note_inlines(note)
  local document = pandoc.read(note, "markdown")
  local inlines = pandoc.List()

  for index, block in ipairs(document.blocks) do
    if index > 1 then
      inlines:insert(pandoc.LineBreak())
    end

    if block.t == "Plain" or block.t == "Para" then
      inlines:extend(block.content)
    else
      inlines:insert(pandoc.Str(pandoc.utils.stringify(block)))
    end
  end

  return inlines
end

local function stripped_span(element)
  return element.content
end

function Span(element)
  if not has_class(element.classes, highlight_class)
    and not has_class(element.classes, rendered_class) then
    return nil
  end

  if not FORMAT:match("html") then
    return stripped_span(element)
  end

  local attributes = copy_attributes(element.attributes)
  local note = first_attribute(attributes, note_attributes)
  local color = first_attribute(attributes, color_attributes)
  local border_color = attributes["border-color"]
  local text_color = attributes["text-color"]
  local popup_color = attributes["popup-color"]

  for _, name in ipairs(note_attributes) do
    attributes[name] = nil
  end
  for _, name in ipairs(color_attributes) do
    attributes[name] = nil
  end
  attributes["border-color"] = nil
  attributes["text-color"] = nil
  attributes["popup-color"] = nil

  if color and not border_color then
    border_color = border_aliases[color:lower()] or color
  end

  add_style_property(attributes, "--explain-bg", color)
  add_style_property(attributes, "--explain-border", border_color)
  add_style_property(attributes, "--explain-text", text_color)
  add_style_property(attributes, "--explain-popover-bg", popup_color)

  if not attributes.tabindex then
    attributes.tabindex = "0"
  end

  local classes = pandoc.List(element.classes)
  if not has_class(classes, rendered_class) then
    classes:insert(rendered_class)
  end

  local content = pandoc.List(element.content)

  if note then
    counter = counter + 1

    local popup_id = "explain-popover-" .. counter
    if element.identifier and element.identifier ~= "" then
      popup_id = element.identifier .. "-explanation"
    end

    local popup = pandoc.Span(
      parsed_note_inlines(note),
      pandoc.Attr(popup_id, { "explain-popover" }, {})
    )
    content:insert(popup)

    if attributes["aria-describedby"] then
      attributes["aria-describedby"] = attributes["aria-describedby"] .. " " .. popup_id
    else
      attributes["aria-describedby"] = popup_id
    end
  end

  return pandoc.Span(
    content,
    pandoc.Attr(element.identifier, classes, attributes)
  )
end
