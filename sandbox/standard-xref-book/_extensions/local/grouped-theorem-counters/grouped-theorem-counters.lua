local stringify = pandoc.utils.stringify

local state = {
  xref = {},
  group_for_class = {},
  group_classes = {},
  is_book = false,
  is_html = quarto.doc.is_format("html"),
  current_file = "",
  labels = {
    theorem = "Theorem",
    lemma = "Lemma",
    proposition = "Proposition",
    corollary = "Corollary",
    conjecture = "Conjecture",
    definition = "Definition",
    example = "Example",
    exercise = "Exercise",
    problem = "Problem"
  }
}

local function norm(s)
  return tostring(s):lower()
end

local function label_for_class(class_name)
  local key = norm(class_name)
  return state.labels[key] or (key:sub(1, 1):upper() .. key:sub(2))
end

local function detect_grouped_class(div)
  local fallback = nil
  for _, class_name in ipairs(div.classes) do
    local key = norm(class_name)
    if state.group_for_class[key] then
      if key ~= "theorem" then
        return key
      end
      if not fallback then
        fallback = key
      end
    end
  end
  return fallback
end

local function parse_config(meta)
  local cfg = meta["grouped-theorem-counters"]
  if not cfg and meta.extensions then
    cfg = meta.extensions["grouped-theorem-counters"]
  end

  if not cfg or not cfg.groups then
    return
  end

  for group_name, group_def in pairs(cfg.groups) do
    if group_def and group_def.classes then
      local group_key = tostring(group_name)
      if not state.group_classes[group_key] then
        state.group_classes[group_key] = {}
      end
      for _, class_item in ipairs(group_def.classes) do
        local class_name = norm(stringify(class_item))
        state.group_for_class[class_name] = group_key
        table.insert(state.group_classes[group_key], class_name)
      end
    end
  end

  if cfg.labels then
    for key, value in pairs(cfg.labels) do
      state.labels[norm(key)] = stringify(value)
    end
  end
end

local function read_source_file(relpath)
  local candidates = { relpath }
  local project_dir = os.getenv("QUARTO_PROJECT_DIR")
  if project_dir and project_dir ~= "" then
    table.insert(candidates, project_dir .. "/" .. relpath)
  end

  local resolved = quarto.utils.resolve_path(relpath)
  if resolved then
    table.insert(candidates, resolved)
  end

  for _, candidate in ipairs(candidates) do
    local fh = io.open(candidate, "r")
    if fh then
      local source = fh:read("*a")
      fh:close()
      return source
    end
  end

  return nil
end

local function add_doc_to_map(doc, chapter_prefix, file_base)
  local counters = {}
  for _, group_name in pairs(state.group_for_class) do
    counters[group_name] = 0
  end

  doc:walk {
    Div = function(el)
      local class_name = detect_grouped_class(el)
      if class_name and el.identifier ~= "" then
        local group_name = state.group_for_class[class_name]
        counters[group_name] = (counters[group_name] or 0) + 1

        local num = tostring(counters[group_name])
        if chapter_prefix ~= "" then
          num = chapter_prefix .. "." .. num
        end

        state.xref[el.identifier] = {
          label = label_for_class(class_name),
          number = num,
          file = file_base
        }
      end
      return nil
    end
  }
end

local function precompute_book_map(meta)
  if not (meta.book and meta.book.render) then
    return false
  end

  for _, entry in ipairs(meta.book.render) do
    if tostring(stringify(entry.type)) == "chapter" and entry.file then
      local chapter_file = stringify(entry.file)
      local chapter_prefix = ""
      if entry.number then
        chapter_prefix = stringify(entry.number)
      end

      local source = read_source_file(chapter_file)
      if source then
        local ok, parsed = pcall(pandoc.read, source, "markdown")
        if ok and parsed then
          local file_base = pandoc.path.split_extension(chapter_file)
          add_doc_to_map(parsed, chapter_prefix, file_base)
        end
      end
    end
  end

  return true
end

local function text_inlines(text)
  local parsed = pandoc.read(text, "markdown")
  if parsed.blocks[1] and parsed.blocks[1].t == "Para" then
    return parsed.blocks[1].content
  end
  return pandoc.Inlines { pandoc.Str(text) }
end

local function rewrite_title_in_para(para, info)
  local replaced = false

  for i, inl in ipairs(para.content) do
    if inl.t == "Span" then
      local has_title_class = false
      for _, c in ipairs(inl.classes) do
        if c == "theorem-title" then
          has_title_class = true
          break
        end
      end

      if has_title_class then
        local old = stringify(inl.content)
        local suffix = old:match("^%S+%s+[%d%.]+(.*)$") or ""
        local new_text = info.label .. " " .. info.number .. suffix
        inl.content = pandoc.Inlines { pandoc.Strong(text_inlines(new_text)) }
        para.content[i] = inl
        replaced = true
        break
      end
    elseif inl.t == "Strong" then
      local old = stringify(inl.content)
      local suffix = old:match("^%S+%s+[%d%.]+(.*)$")
      if suffix then
        local new_text = info.label .. " " .. info.number .. suffix
        inl.content = text_inlines(new_text)
        para.content[i] = inl
        replaced = true
        break
      end
    end
  end

  return replaced
end

local function rewrite_grouped_div(el)
  local info = state.xref[el.identifier]
  if not info then
    return nil
  end

  local class_name = detect_grouped_class(el) or "theorem"

  local kept = pandoc.List {}
  for _, class_item in ipairs(el.classes) do
    local key = norm(class_item)
    if not state.group_for_class[key] then
      kept:insert(class_item)
    end
  end
  kept:insert("grouped-theorem")
  kept:insert("grouped-theorem-" .. class_name)
  el.classes = kept

  if el.content[1] and el.content[1].t == "Para" then
    rewrite_title_in_para(el.content[1], info)
  end

  return el
end

local function rewrite_grouped_link(el)
  local id = el.target:match("#([A-Za-z][A-Za-z0-9%-%_:%.]*)$")
  if not id then
    return nil
  end

  local info = state.xref[id]
  if not info then
    return nil
  end

  el.classes = pandoc.List {}
  el.attributes = {}

  if state.is_html and state.is_book and info.file and info.file ~= state.current_file then
    el.target = info.file .. ".html#" .. id
  else
    el.target = "#" .. id
  end

  el.content = pandoc.Inlines {
    pandoc.Str(info.label),
    pandoc.Space(),
    pandoc.Str(info.number)
  }

  return el
end

local function inject_pdf_counter_sharing()
  if not quarto.doc.is_format("pdf") then
    return
  end

  local lines = {}
  for _, classes in pairs(state.group_classes) do
    local base = classes[1]
    if base then
      for i = 2, #classes do
        local cls = classes[i]
        table.insert(lines, string.format(
          "\\@ifundefined{c@%s}{}{\\@ifundefined{c@%s}{}{\\let\\c@%s\\c@%s\\let\\the%s\\the%s}}",
          cls, base, cls, base, cls, base
        ))
      end
    end
  end

  if #lines > 0 then
    local tex = "\\makeatletter\n" .. table.concat(lines, "\n") .. "\n\\makeatother\n"
    quarto.doc.include_text("before-body", tex)
  end
end

return {
  {
    Meta = function(meta)
      state.current_file = pandoc.path.split_extension(
        pandoc.path.filename(PANDOC_STATE.output_file or "")
      )
      state.is_book = meta.book ~= nil

      parse_config(meta)
      if not next(state.group_for_class) then
        return meta
      end

      precompute_book_map(meta)
      return meta
    end
  },
  {
    Pandoc = function(doc)
      if not next(state.group_for_class) then
        return doc
      end

      inject_pdf_counter_sharing()
      doc = doc:walk { Div = rewrite_grouped_div }
      doc = doc:walk { Link = rewrite_grouped_link }
      return doc
    end
  }
}
