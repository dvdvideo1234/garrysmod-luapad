-- Andreas "Syranide" Svensson's editor for Wire Expression 2
-- edited by DarKSunrise aka Assassini
-- to work with Luapad and with Lua-syntax
if (SERVER) then
  return
end

local KEYWORD_TOKENS = {
  ["if"      ] = true,
  ["elseif"  ] = true,
  ["else"    ] = true,
  ["then"    ] = true,
  ["end"     ] = true,
  ["function"] = true,
  ["do"      ] = true,
  ["while"   ] = true,
  ["for"     ] = true,
  ["repeat"  ] = true,
  ["until"   ] = true,
  ["break"   ] = true,
  ["in"      ] = true,
  ["local"   ] = true,
  ["true"    ] = true,
  ["false"   ] = true,
  ["nil"     ] = true,
  ["NULL"    ] = true,
  ["and"     ] = true,
  ["not"     ] = true,
  ["or"      ] = true,
  ["||"      ] = true,
  ["&&"      ] = true
}

--[[
 * Default theme customization
 * [1] : Current color used for a bunch of text
 * [2] : Use bold text style when drawing
]]
local COLOR_HIGHLIGHT = {
  ["gui.background" ] = {Base = Color(220, 220, 220, 255), Skin = "colTextEntryBG"},
  ["gui.verticalbar"] = {Base = Color(170, 170, 170, 255), Skin = "colTextEntryBorder"},
  ["gui.blinkcursor"] = {Base = Color( 72,  61, 139, 255), Skin = "colTextEntryTextCursor"},
  ["gui.rownumbers" ] = {Base = Color(128, 128, 128, 255), Skin = "colTextEntryTextPlaceholder"},
  ["gui.rowpaintbeg"] = {Base = Color(215, 215, 215, 255), Skin = "colTextEntryTextHighlight"},
  ["gui.rowpaintend"] = {Base = Color(250, 250, 250, 255), Skin = "colTextEntryBG"},
  ["code.none"      ] = {Base = Color(  0,   0,   0, 255), Skin = "colTextEntryText"},
  ["code.number"    ] = {Base = Color(218, 165,  32, 255)},
  ["code.function"  ] = {Base = Color(100, 100, 255, 255)},
  ["code.enumerator"] = {Base = Color(184, 134,  11, 255)},
  ["code.metatable" ] = {Base = Color(140, 100,  90, 255)},
  ["code.string"    ] = {Base = Color(120, 120, 120, 255)},
  ["code.construct" ] = {Base = Color(  0,   0, 255, 255)},
  ["code.operator"  ] = {Base = Color(  0,   0, 128, 255)},
  ["code.comment"   ] = {Base = Color(  0, 120,   0, 255)}
}

luapad.EditorPanel = {}

-- Create fonts
surface.CreateFont("LuapadEditor", {font = "Courier New", size = 16, weight = 400})
surface.CreateFont("LuapadEditor_Bold", {font = "Courier New", size = 16, weight = 800})

function luapad.EditorPanel:Init()
  self:SetCursor("beam")

  surface.SetFont("LuapadEditor")
  self.FontWidth, self.FontHeight = surface.GetTextSize(" ")

  self.Rows = {""}
  self.Caret = {1, 1}
  self.Start = {1, 1}
  self.Scroll = {1, 1}
  self.Size = {1, 1}
  self.Undo = {}
  self.Redo = {}
  self.PaintRows = {}

  self.Blink = RealTime()

  self.ScrollBar = vgui.Create("DVScrollBar", self)
  self.ScrollBar:SetUp(1, 1)

  self.TextEntry = vgui.Create("TextEntry", self)
  self.TextEntry:SetMultiline(true)
  self.TextEntry:SetAllowNonAsciiCharacters(true)
  self.TextEntry:SetSize(0, 0)

  self.TextEntry.OnLoseFocus = function(self)
    self.Parent:CustomOnLoseFocus()
  end
  self.TextEntry.OnTextChanged = function(self)
    self.Parent:CustomOnTextChanged()
  end
  self.TextEntry.OnKeyCodeTyped = function(self, code)
    self.Parent:CustomOnKeyCodeTyped(code)
  end

  self:SetThemeDefault()

  self.TextEntry.Parent = self

  self.LastClick = 0
end

function luapad.EditorPanel:GetThemeKeys()
  local tT = self.Highlight
  if(not tT) then return nil end
  local tK = table.GetKeys(tT)
  table.sort(tK, function(u, v) return u < v end)
  return tK -- Array with palette keys
end

function luapad.EditorPanel:GetTheme(sT)
  local tT = self.Highlight
  if(not tT) then return nil end
  if(not sT) then return nil end
  return tT[sT][1]
end

function luapad.EditorPanel:SetTheme(sT, vC)
  local tT = self.Highlight
  if(not tT) then return nil end
  if(not sT) then return nil end
  return tT[sT][1] = vC
end

function luapad.EditorPanel:SetThemeArea(pD, bR)
  local tS = self.Highlight
  if(not tT) then return nil end
  if(not pE) then return nil end
  local tD = pD:GetTable().Highlight
  if(not tD) then return nil end
  for sT, vT in pairs(tS) do
    local vS, vD = vT, tD[sT]
    if(vS and vD) then
      if(bR) then
        vD[1] = vS[1]
      else
        vS[1] = vD[1]
      end
    end
  end
end

function luapad.EditorPanel:SetThemeDefault()
  self.Highlight = (self.Highlight or {})
  table.Empty(self.Highlight) -- Clear highlighting
  for sT, tC in pairs(COLOR_HIGHLIGHT) do
    self.Highlight[sT] = {tC.Base, false}
  end -- Update the string expression
  self.Highlight["code.string2"] = self.Highlight["code.string"]
end

function luapad.EditorPanel:SetThemeFile(sN)
  if(not isstring(sN)) then return end
  local bN = luapad.IsHere(sN)
  local tC = luapad.GetConfig("THMDEF")
  local sE = luapad.GetConfig("PATNLN")
  local sN = (bN and sN or tC[2])..".txt"
  self:SetThemeDefault() -- Ignore missing gaps
  if(sN == tC[2]) then return end
  if(not file.IsDir(tC[1], "DATA")) then file.CreateDir(tC[1]) end
  -- Open the file so the theme can be extracted
  local sF = file.Read(tC[1]..sN, "rb", "DATA")
  if(not sF) then -- The file open attempt has failed
    luapad.SetConsole("Failed opening highlight: %s%s", "STAT_WR", tC[1], sN)
    return -- Exit the routine end report the status
  end
  local tW = sE:Explode(sF, true)
  local sD = luapad.GetConfig("DELIMS")
  for iD = 1, #tW do -- Every line contains token and color
    local tT = sD:Explode(tW[iD]) -- Empty lines
    local sT = tT[1]:Trim() -- Color token to search for
    if(self.Highlight[sT]) then
      local nR = luapad.ToColor(tT[2]:Trim(), 0)
      local nG = luapad.ToColor(tT[3]:Trim(), 0)
      local nB = luapad.ToColor(tT[4]:Trim(), 0)
      local nA = luapad.ToColor(tT[5]:Trim(), 255)
      self.Highlight[sT][1] = Color(nR, nG, nB, nA)
    end
  end
end

function luapad.EditorPanel:SaveThemeFile(sN)
  if(not isstring(sN)) then return end
  local bN = luapad.IsHere(sN)
  local tC = luapad.GetConfig("THMDEF")
  local sN = (bN and sN or tC[2]):lower()..".txt"
  if(not file.IsDir(tC[1], "DATA")) then file.CreateDir(tC[1]) end
  -- Open the file so the theme can be extracted
  local fO = file.Open(tC[1]..sN, "wb", "DATA")
  if(not fO) then -- The file open attempt has failed
    luapad.SetConsole("Failed opening highlight: %s%s", "STAT_WR", tC[1], sN)
    return -- Exit the routine end report the status
  end
  local tK, tO = self:GetThemeKeys(), {}
  local sD = luapad.GetConfig("DELIMS")
  for iK = 1, #tK do -- Every line contains token and color
    local vK = tK[iK]; tO[1] = vK
    local vC = self:GetTheme(vK)
    tO[2], tO[3], tO[4], tO[5] = vC:unpack()
    fO:Write(table.concat(tO, sD)); fO:Write("\n")
  end
  fO:Flush(); fO:Close()
end

function luapad.EditorPanel:SetThemeSkin(tS)
  self:SetThemeDefault() -- Ignore missing gaps
  local tS = (tS or derma.GetDefaultSkin())
  local sD = luapad.GetConfig("DELIMS")
  for sT, tC in pairs(COLOR_HIGHLIGHT) do
    if(tC.Skin) then
      local vC, tK = tS, sD:Explode(tC.Skin)
      for iD = 1, #tK do vC = vC[tK[iD]] end
      if(vC) then self.Highlight[sT][1] = vC end
    end
  end -- Update the string expression
end

function luapad.EditorPanel:RequestFocus()
  self.TextEntry:RequestFocus()
end

function luapad.EditorPanel:OnGetFocus()
  self.TextEntry:RequestFocus()
end

function luapad.EditorPanel:CursorToCaret()
  local x, y = self:CursorPos()

  x = x - (self.FontWidth * 3 + 6)
  x = ((x < 0) and 0 or x)
  y = ((y < 0) and 0 or y)

  local last = #self.Rows
  local line = math.floor(y / self.FontHeight)
  local char = math.floor(x / self.FontWidth + 0.5)

  line = line + self.Scroll[1]
  char = char + self.Scroll[2]
  line = ((line > last) and last or line)

  local length = string.len(self.Rows[line])
  if (char > length + 1) then
    char = length + 1
  end

  return {line, char}
end

function luapad.EditorPanel:OnMousePressed(code)
  local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)

  if (code == MOUSE_LEFT) then
    local cucar = self:CursorToCaret()
    if ((CurTime() - self.LastClick) < 1 and
      cucar[1] == self.Caret[1] and
      cucar[2] == self.Caret[2] and self.Temp
    ) then
      self.Start = self:GetWordStart(self.Caret)
      self.Caret = self:GetWordEnd(self.Caret)
      self.Temp = false
      return
    end

    self.Temp = true

    self.LastClick = CurTime()
    self:RequestFocus()
    self.Blink = RealTime()
    self.MouseDown = true
    self.Caret = self:CursorToCaret()

    if (not shift) then
      self.Start = self:CursorToCaret()
    end
  elseif (code == MOUSE_RIGHT) then
    local pMenu = DermaMenu()

    if (self:CanUndo()) then
      pMenu:AddOption(
        "Undo", function()
          self:DoUndo()
        end
      )
    end
    if (self:CanRedo()) then
      pMenu:AddOption(
        "Redo", function()
          self:DoRedo()
        end
      )
    end

    if (self:CanUndo() or self:CanRedo()) then
      pMenu:AddSpacer()
    end

    if (self:HasSelection()) then
      pMenu:AddOption(
        "Cut", function()
          if (self:HasSelection()) then
            self.clipboard = self:GetSelection()
            self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
            SetClipboardText(self.clipboard)
            self:SetSelection()
          end
        end
      )
      pMenu:AddOption(
        "Copy", function()
          if (self:HasSelection()) then
            self.clipboard = self:GetSelection()
            self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
            SetClipboardText(self.clipboard)
          end
        end
      )
    end

    pMenu:AddOption(
      "Paste", function()
        if (self.clipboard) then
          self:SetSelection(self.clipboard)
        else
          self:SetSelection()
        end
      end
    )

    if (self:HasSelection()) then
      pMenu:AddOption(
        "Delete", function()
          self:SetSelection()
        end
      )
    end

    pMenu:AddSpacer()

    pMenu:AddOption(
      "Select all", function()
        self:SelectAll()
      end
    )

    pMenu:Open()
  end
end

function luapad.EditorPanel:OnMouseReleased(code)
  if (not self.MouseDown) then
    return
  end

  if (code == MOUSE_LEFT) then
    self.MouseDown = nil
    if (not self.Temp) then
      return
    end
    self.Caret = self:CursorToCaret()
  end
end

function luapad.EditorPanel:SetText(text)
  self.Rows = string.Explode("\n", text)
  local last = #self.Rows

  if (self.Rows[last] ~= "") then
    last = last + 1
    self.Rows[last] = ""
  end

  self.Caret = {1, 1}
  self.Start = {1, 1}
  self.Scroll = {1, 1}
  self.Undo = {}
  self.Redo = {}
  self.PaintRows = {}

  self.ScrollBar:SetUp(self.Size[1], last - 1)
end

function luapad.EditorPanel:GetText()
  return string.Implode("\n", self.Rows)
end

function luapad.EditorPanel:NextChar()
  if (not self.char) then
    return
  end

  self.str = self.str .. self.char
  self.pos = self.pos + 1

  if (self.pos <= string.len(self.line)) then
    self.char = string.sub(self.line, self.pos, self.pos)
  else
    self.char = nil
  end
end

function luapad.EditorPanel:SyntaxColorLine(row)
  local cols = {}
  local lasttable
  self.line = self.Rows[row]
  self.pos = 0
  self.multy = nil
  self.token = nil
  self.char = ""
  self.str = ""

  self:NextChar()

  while self.char do
    local token = ""
    self.str = ""

    while self.char and self.char == " " do
      self:NextChar()
    end
    if (not self.char) then
      break
    end

    if(self.multy and self.char == "]") then
      local last, multy = self.char, self.multy
      self:NextChar()
      while(self.char and self.char == "=") do
        multy = multy - 1
        self:NextChar()
      end
      if(multy == 0 and self.char == last) then
        token = "code.none" -- Equals are same amount as start
        self.token, self.multy = nil, nil -- Reset multi line
      else -- Otherwise continue with the multi line comment/string
        token = self.token or "code.none" -- Keep the last token
      end
    elseif (self.char >= "0" and self.char <= "9") then
      while self.char and (self.char >= "0" and self.char <= "9" or
                           self.char == "." or self.char == "_") do
        self:NextChar()
      end

      token = "code.number"
    elseif (self.char >= "a" and self.char <= "z" or self.char >= "A" and self.char <= "Z") then

      while self.char and (self.char >= "a" and self.char <= "z" or
                           self.char >= "A" and self.char <= "Z" or
                           self.char >= "0" and self.char <= "9" or self.char == "_") do
        self:NextChar()
      end

      local sstr = string.Trim(self.str)
      local gstr = luapad.CheckGlobal(sstr)
      local tgstr = type(gstr)

      if (KEYWORD_TOKENS[sstr]) then

        token = "code.construct"

      elseif (gstr and (tgstr == "function" or gstr == "f" or gstr == "e" or gstr == "m" or tgstr == "table") or (lasttable and lasttable[sstr])) then
         -- Could be better code, but what the hell; it works
        if (tgstr == "table") then
          lasttable = gstr
        end

        if ((gstr == "e") and sstr == string.upper(sstr)) then
          token = "code.enumerator"
        elseif (gstr == "m") then
          token = "code.metatable"
        else
          token = "code.function"
        end

      else
        lasttable = nil
        token = "code.none"
      end

    elseif (self.char == "\"") then

      self:NextChar()
      while(self.char and self.char ~= "\"") do
        if (self.char == "\\") then
          self:NextChar()
        end
        self:NextChar()
      end
      self:NextChar()

      token = "code.string"
    elseif (self.char == "'") then
      local last = self.char
      self:NextChar()
      while(self.char and self.char ~= last) do
        if (self.char == "\\") then
          self:NextChar()
        end
        self:NextChar()
      end
      self:NextChar()

      token = "code.string2"
    elseif (self.char == "/" or self.char == "-") then
      local last = self.char
      self:NextChar()

      if (self.char == last) then
        while(self.char and self.char == last) do
          self:NextChar()
        end

        token = "code.comment"
      else
        token = "code.none"
      end
    elseif (self.char == "[") then
      local last, multy = self.char, 0
      self:NextChar()

      while(self.char and self.char == "=") do
        self:NextChar()
        multy = multy + 1
      end
      if (self.char == last) then
        self.multy = multy
        self:NextChar()
        if(token ~= "code.comment") then
          token = "code.string"
        end
        self.token = token
      end
        token = "code.none"
      end
    else
      self:NextChar()
      token = "code.operator"
    end

    local tC = self.Highlight[token]
    local nH = #cols

    if (nH > 1 and tC == cols[nH][2]) then
      cols[nH][1] = cols[nH][1] .. self.str
    else
      cols[nH + 1] = {self.str, tC}
    end
  end

  return cols
end

function luapad.EditorPanel:PaintLine(row)
  if (row > #self.Rows) then
    return
  end

  if (not self.PaintRows[row]) then
    self.PaintRows[row] = self:SyntaxColorLine(row)
  end

  local width, height = self.FontWidth, self.FontHeight
  local scstr, scend  = self.Scroll[1], self.Scroll[2]
  local castr, caend  = self.Caret[1] , self.Caret[2]

  if (row == castr and self.TextEntry:HasFocus()) then
    surface.SetDrawColor(self:GetTheme("gui.background"))
    surface.DrawRect(width * 3 + 5, (row - scstr) * height, self:GetWide() - (width * 3 + 5), height)
  end

  if (self:HasSelection()) then
    local start, stop = self:MakeSelection(self:Selection())
    local line, char = start[1], start[2]
    local endline, endchar = stop[1], stop[2]

    surface.SetDrawColor(self:GetTheme("gui.verticalbar"))
    local length = string.len(self.Rows[row]) - scend + 1

    char = char - scend
    if (char < 0) then
      char = 0
    end

    endchar = endchar - scend
    if (endchar < 0) then
      endchar = 0
    end

    if (row == line and line == endline) then
      surface.DrawRect(char * width + width * 3 + 6, (row - scstr) * height, width * (endchar - char), height)
    elseif (row == line) then
      surface.DrawRect(char * width + width * 3 + 6, (row - scstr) * height, width * (length - char + 1), height)
    elseif (row == endline) then
      surface.DrawRect(width * 3 + 6, (row - scstr) * height, width * endchar, height)
    elseif (row > line and row < endline) then
      surface.DrawRect(width * 3 + 6, (row - scstr) * height, width * (length + 1), height)
    end
  end

  draw.SimpleText(tostring(row), "LuapadEditor", width * 3, (row - scstr) * height, self:GetTheme("gui.rownumbers"), TEXT_ALIGN_RIGHT)

  local offset = -scend + 1
  for i, cell in ipairs(self.PaintRows[row]) do
    local ccon, cstr, cend = cell[1], cell[2][1], cell[2][2]
    if (offset < 0) then
      if (string.len(ccon) > -offset) then
        line = string.sub(ccon, -offset + 1)
        offset = string.len(line)

        if (cend) then
          draw.SimpleText(line, "LuapadEditorBold", width * 3 + 6, (row - scstr) * height, cstr)
        else
          draw.SimpleText(line, "LuapadEditor", width * 3 + 6, (row - scstr) * height, cstr)
        end
      else
        offset = offset + string.len(ccon)
      end
    else
      if (cend) then
        draw.SimpleText(ccon, "LuapadEditorBold", offset * width + width * 3 + 6, (row - scstr) * height, cstr)
      else
        draw.SimpleText(ccon, "LuapadEditor", offset * width + width * 3 + 6, (row - scstr) * height, cstr)
      end

      offset = offset + string.len(ccon)
    end
  end

  if (row == castr and self.TextEntry:HasFocus()) then
    if ((RealTime() - self.Blink) % 0.8 < 0.4) then
      if (caend - scend >= 0) then
        surface.SetDrawColor(self:GetTheme("gui.blinkcursor"))
        surface.DrawRect((caend - scend) * width + width * 3 + 6,
                         (castr - scstr) * height, 1, height)
      end
    end
  end
end

function luapad.EditorPanel:PerformLayout()
  self.ScrollBar:SetSize(16, self:GetTall())
  self.ScrollBar:SetPos(self:GetWide() - 16, 0)

  self.Size[1] = math.floor(self:GetTall() / self.FontHeight) - 1
  self.Size[2] = math.floor((self:GetWide() - (self.FontWidth * 3 + 6) - 16) / self.FontWidth) - 1

  self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
end

function luapad.EditorPanel:Paint(w, h)
  if (not input.IsMouseDown(MOUSE_LEFT)) then
    self:OnMouseReleased(MOUSE_LEFT)
  end

  if (not self.PaintRows) then
    self.PaintRows = {}
  end

  if (self.MouseDown) then
    self.Caret = self:CursorToCaret()
  end

  surface.SetDrawColor(self:GetTheme("gui.rowpaintbeg"))
  surface.DrawRect(0, 0, self.FontWidth * 3 + 4, self:GetTall())

  surface.SetDrawColor(self:GetTheme("gui.rowpaintend"))
  surface.DrawRect(self.FontWidth * 3 + 5, 0, self:GetWide() - (self.FontWidth * 3 + 5), self:GetTall())

  self.Scroll[1] = math.floor(self.ScrollBar:GetScroll() + 1)

  for i = self.Scroll[1], self.Scroll[1] + self.Size[1] + 1 do
    self:PaintLine(i)
  end

  return true
end

function luapad.EditorPanel:SetCaret(caret)
  self.Caret = self:CopyPosition(caret)
  self.Start = self:CopyPosition(caret)
  self:ScrollCaret()
end

function luapad.EditorPanel:CopyPosition(caret)
  return {caret[1], caret[2]}
end

function luapad.EditorPanel:MovePosition(caret, offset)
  local caret = {caret[1], caret[2]}

  if (offset > 0) then
    while true do
      local length = string.len(self.Rows[caret[1]]) - caret[2] + 2
      if (offset < length) then
        caret[2] = caret[2] + offset
        break
      elseif (caret[1] == #self.Rows) then
        caret[2] = caret[2] + length - 1
        break
      else
        offset = offset - length
        caret[1] = caret[1] + 1
        caret[2] = 1
      end
    end
  elseif (offset < 0) then
    offset = -offset

    while true do
      if (offset < caret[2]) then
        caret[2] = caret[2] - offset
        break
      elseif (caret[1] == 1) then
        caret[2] = 1
        break
      else
        offset = offset - caret[2]
        caret[1] = caret[1] - 1
        caret[2] = string.len(self.Rows[caret[1]]) + 1
      end
    end
  end

  return caret
end

function luapad.EditorPanel:HasSelection()
  return self.Caret[1] ~= self.Start[1] or self.Caret[2] ~= self.Start[2]
end

function luapad.EditorPanel:Selection()
  return {{self.Caret[1], self.Caret[2]}, {self.Start[1], self.Start[2]}}
end

function luapad.EditorPanel:MakeSelection(selection)
  local start, stop = selection[1], selection[2]

  if (start[1] < stop[1] or start[1] == stop[1] and start[2] < stop[2]) then
    return start, stop
  else
    return stop, start
  end
end

function luapad.EditorPanel:GetArea(selection)
  local start, stop = self:MakeSelection(selection)

  if (start[1] == stop[1]) then
    return string.sub(self.Rows[start[1]], start[2], stop[2] - 1)
  else
    local text = string.sub(self.Rows[start[1]], start[2])

    for i = start[1] + 1, stop[1] - 1 do
      text = text .. "\n" .. self.Rows[i]
    end

    return text .. "\n" .. string.sub(self.Rows[stop[1]], 1, stop[2] - 1)
  end
end

function luapad.EditorPanel:SetArea(selection, text, isundo, isredo, before, after)
  local start, stop = self:MakeSelection(selection)

  local buffer = self:GetArea(selection)

  if (start[1] ~= stop[1] or start[2] ~= stop[2]) then
    -- clear selection
    self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. string.sub(self.Rows[stop[1]], stop[2])
    self.PaintRows[start[1]] = false

    for i = start[1] + 1, stop[1] do
      table.remove(self.Rows, start[1] + 1)
      table.remove(self.PaintRows, start[1] + 1)
      self.PaintRows = {} -- TODO: fix for cache errors
    end

    -- add empty row at end of file (TODO!)
    if (self.Rows[#self.Rows] ~= "") then
      self.Rows[#self.Rows + 1] = ""
      self.PaintRows[#self.Rows + 1] = false
    end
  end

  if (not text or text == "") then
    self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)

    self.PaintRows = {}

    self:OnTextChanged()

    if (isredo) then
      self.Undo[#self.Undo + 1] = {{self:CopyPosition(start), self:CopyPosition(start)}, buffer, after, before}
      return before
    elseif (isundo) then
      self.Redo[#self.Redo + 1] = {{self:CopyPosition(start), self:CopyPosition(start)}, buffer, after, before}
      return before
    else
      self.Redo = {}
      self.Undo[#self.Undo + 1] = {{self:CopyPosition(start), self:CopyPosition(start)}, buffer, self:CopyPosition(selection[1]), self:CopyPosition(start)}
      return start
    end
  end

  -- insert text
  local rows = string.Explode("\n", text)

  local remainder = string.sub(self.Rows[start[1]], start[2])
  self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. rows[1]
  self.PaintRows[start[1]] = false

  for i = 2, #rows do
    table.insert(self.Rows, start[1] + i - 1, rows[i])
    table.insert(self.PaintRows, start[1] + i - 1, false)
    self.PaintRows = {} -- TODO: fix for cache errors
  end

  local stop = {start[1] + #rows - 1, string.len(self.Rows[start[1] + #rows - 1]) + 1}

  self.Rows[stop[1]] = self.Rows[stop[1]] .. remainder
  self.PaintRows[stop[1]] = false

  -- add empty row at end of file (TODO!)
  if (self.Rows[#self.Rows] ~= "") then
    self.Rows[#self.Rows + 1] = ""
    self.PaintRows[#self.Rows + 1] = false
    self.PaintRows = {} -- TODO: fix for cache errors
  end

  self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)

  self.PaintRows = {}

  self:OnTextChanged()

  if (isredo) then
    self.Undo[#self.Undo + 1] = {{self:CopyPosition(start), self:CopyPosition(stop)}, buffer, after, before}
    return before
  elseif (isundo) then
    self.Redo[#self.Redo + 1] = {{self:CopyPosition(start), self:CopyPosition(stop)}, buffer, after, before}
    return before
  else
    self.Redo = {}
    self.Undo[#self.Undo + 1] = {{self:CopyPosition(start), self:CopyPosition(stop)}, buffer, self:CopyPosition(selection[1]), self:CopyPosition(stop)}
    return stop
  end
end

function luapad.EditorPanel:GetSelection()
  return self:GetArea(self:Selection())
end

function luapad.EditorPanel:SetSelection(text)
  self:SetCaret(self:SetArea(self:Selection(), text))
end

function luapad.EditorPanel:CustomOnLoseFocus()
  if (self.TabFocus) then
    self:RequestFocus()
    self.TabFocus = nil
  end
end

function luapad.EditorPanel:CustomOnTextChanged()
  local ctrlv = false
  local text = self.TextEntry:GetText()
  self.TextEntry:SetText("")

  if input.IsKeyDown(KEY_BACKQUOTE) and luapad.ignoreconsoleopen then
    return
  end

  local alt = input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)
  local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)

  if (control and not alt) then
    -- ctrl+[shift+]key
    if (input.IsKeyDown(KEY_V)) then
      -- ctrl+[shift+]V
      ctrlv = true
    else
      -- ctrl+[shift+]key with key ~= V
      return
    end
  end

  if (text == "") then
    return
  end
  if (not ctrlv) then
    if (text == "\n") then
      return
    end
    if (text == "end") then
      local row = self.Rows[self.Caret[1]]
    end
  end

  self:SetSelection(text)
end

function luapad.EditorPanel:OnMouseWheeled(delta)
  self.Scroll[1] = self.Scroll[1] - 4 * delta
  if (self.Scroll[1] < 1) then
    self.Scroll[1] = 1
  end
  if (self.Scroll[1] > #self.Rows) then
    self.Scroll[1] = #self.Rows
  end
  self.ScrollBar:SetScroll(self.Scroll[1] - 1)
end

function luapad.EditorPanel:ScrollCaret()
  if (self.Caret[1] - self.Scroll[1] < 2) then
    self.Scroll[1] = self.Caret[1] - 2
    if (self.Scroll[1] < 1) then
      self.Scroll[1] = 1
    end
  end

  if (self.Caret[1] - self.Scroll[1] > self.Size[1] - 2) then
    self.Scroll[1] = self.Caret[1] - self.Size[1] + 2
    if (self.Scroll[1] < 1) then
      self.Scroll[1] = 1
    end
  end

  if (self.Caret[2] - self.Scroll[2] < 4) then
    self.Scroll[2] = self.Caret[2] - 4
    if (self.Scroll[2] < 1) then
      self.Scroll[2] = 1
    end
  end

  if (self.Caret[2] - 1 - self.Scroll[2] > self.Size[2] - 4) then
    self.Scroll[2] = self.Caret[2] - 1 - self.Size[2] + 4
    if (self.Scroll[2] < 1) then
      self.Scroll[2] = 1
    end
  end

  self.ScrollBar:SetScroll(self.Scroll[1] - 1)
end

function unIndent(line)
  local i = line:find("%S")
  if (i == nil or i > 5) then
    i = 5
  end
  return line:sub(i)
end

function luapad.EditorPanel:CanUndo()
  return #self.Undo > 0
end

function luapad.EditorPanel:DoUndo()
  local tU = self.Undo
  local nU = #tU
  if (nU <= 0) then return end
  local tC = tU[nU]; tU[nU] = nil
  self:SetCaret(self:SetArea(tC[1], tC[2], true, false, tC[3], tC[4]))
end

function luapad.EditorPanel:CanRedo()
  return #self.Redo > 0
end

function luapad.EditorPanel:DoRedo()
  local tR = self.Redo
  local nR = #tR
  if (nR <= 0) then return end
  local tC = tR[nR]; tR[nR] = nil
  self:SetCaret(self:SetArea(tC[1], tC[2], false, true, tC[3], tC[4]))
end

function luapad.EditorPanel:SelectAll()
  local nR = #self.Rows
  self.Caret = {nR, string.len(self.Rows[nR]) + 1}
  self.Start = {1, 1}
  self:ScrollCaret()
end

function luapad.EditorPanel:CustomOnKeyCodeTyped(code)
  self.Blink = RealTime()

  local alt = input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)
  local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
  local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)

  if (control and alt and code == KEY_S) then
    luapad.SaveAsScript()
  end

  if (alt) then
    return
  end

  if (control) then
    if (code == KEY_A) then
      self:SelectAll()
    elseif (code == KEY_Z) then
      self:DoUndo()
    elseif (code == KEY_Y) then
      self:DoRedo()
    elseif (code == KEY_X) then
      if (self:HasSelection()) then
        self.clipboard = self:GetSelection()
        self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
        SetClipboardText(self.clipboard)
        self:SetSelection()
      end
    elseif (code == KEY_C) then
      if (self:HasSelection()) then
        self.clipboard = self:GetSelection()
        self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
        SetClipboardText(self.clipboard)
      end
    elseif (code == KEY_Q) then
      self:GetParent():Close()
    elseif (code == KEY_S) then
      luapad.SaveScript()
    elseif (code == KEY_O) then
      luapad.OpenScript()
    elseif (code == KEY_N) then
      luapad.NewTab()
    elseif (code == KEY_UP) then
      self.Scroll[1] = self.Scroll[1] - 1
      if (self.Scroll[1] < 1) then
        self.Scroll[1] = 1
      end
    elseif (code == KEY_DOWN) then
      self.Scroll[1] = self.Scroll[1] + 1
    elseif (code == KEY_LEFT) then
      if (self:HasSelection() and not shift) then
        self.Start = self:CopyPosition(self.Caret)
      else
        self.Caret = self:GetWordStart(self:MovePosition(self.Caret, -2))
      end

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_RIGHT) then
      if (self:HasSelection() and not shift) then
        self.Start = self:CopyPosition(self.Caret)
      else
        self.Caret = self:GetWordEnd(self:MovePosition(self.Caret, 1))
      end

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_HOME) then
      self.Caret[1] = 1
      self.Caret[2] = 1

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_END) then
      self.Caret[1] = #self.Rows
      self.Caret[2] = 1

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_T) then
      luapad.RunScriptServer()
    elseif (code == KEY_G) then
      luapad.RunScriptClient()
    elseif (code == KEY_B) then
      luapad.RunScriptServer()
      luapad.RunScriptClient()
    end

  else
    if (code == KEY_ENTER) then
      local row = self.Rows[self.Caret[1]]:sub(1, self.Caret[2] - 1)
      local diff = (row:find("%S") or (row:len() + 1)) - 1
      local tabs = string.rep("    ", math.floor(diff / 4))
      self:SetSelection("\n" .. tabs)
    elseif (code == KEY_UP) then
      if (self.Caret[1] > 1) then
        self.Caret[1] = self.Caret[1] - 1

        local length = string.len(self.Rows[self.Caret[1]])
        if (self.Caret[2] > length + 1) then
          self.Caret[2] = length + 1
        end
      end

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_DOWN) then
      if (self.Caret[1] < #self.Rows) then
        self.Caret[1] = self.Caret[1] + 1

        local length = string.len(self.Rows[self.Caret[1]])
        if (self.Caret[2] > length + 1) then
          self.Caret[2] = length + 1
        end
      end

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_LEFT) then
      if (self:HasSelection() and not shift) then
        self.Start = self:CopyPosition(self.Caret)
      else
        self.Caret = self:MovePosition(self.Caret, -1)
      end

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_RIGHT) then
      if (self:HasSelection() and not shift) then
        self.Start = self:CopyPosition(self.Caret)
      else
        self.Caret = self:MovePosition(self.Caret, 1)
      end

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_PAGEUP) then
      self.Caret[1] = self.Caret[1] - math.ceil(self.Size[1] / 2)
      self.Scroll[1] = self.Scroll[1] - math.ceil(self.Size[1] / 2)
      if (self.Caret[1] < 1) then
        self.Caret[1] = 1
      end

      local length = string.len(self.Rows[self.Caret[1]])
      if (self.Caret[2] > length + 1) then
        self.Caret[2] = length + 1
      end
      if (self.Scroll[1] < 1) then
        self.Scroll[1] = 1
      end

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_PAGEDOWN) then
      self.Caret[1] = self.Caret[1] + math.ceil(self.Size[1] / 2)
      self.Scroll[1] = self.Scroll[1] + math.ceil(self.Size[1] / 2)
      if (self.Caret[1] > #self.Rows) then
        self.Caret[1] = #self.Rows
      end
      if (self.Caret[1] == #self.Rows) then
        self.Caret[2] = 1
      end

      local length = string.len(self.Rows[self.Caret[1]])
      if (self.Caret[2] > length + 1) then
        self.Caret[2] = length + 1
      end

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_HOME) then
      local row = self.Rows[self.Caret[1]]
      local first_char = row:find("%S") or row:len() + 1
      if (self.Caret[2] == first_char) then
        self.Caret[2] = 1
      else
        self.Caret[2] = first_char
      end

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_END) then
      local length = string.len(self.Rows[self.Caret[1]])
      self.Caret[2] = length + 1

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_BACKSPACE) then
      if (self:HasSelection()) then
        self:SetSelection()
      else
        local buffer = self:GetArea({self.Caret, {self.Caret[1], 1}})
        if (self.Caret[2] % 4 == 1 and string.len(buffer) > 0 and string.rep(" ", string.len(buffer)) == buffer) then
          self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -4)}))
        else
          self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -1)}))
        end
      end
    elseif (code == KEY_DELETE) then
      if (self:HasSelection()) then
        self:SetSelection()
      else
        local buffer = self:GetArea({{self.Caret[1], self.Caret[2] + 4}, {self.Caret[1], 1}})
        if (self.Caret[2] % 4 == 1 and string.rep(" ", string.len(buffer)) == buffer and string.len(self.Rows[self.Caret[1]]) >= self.Caret[2] + 4 - 1) then
          self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 4)}))
        else
          self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 1)}))
        end
      end
    end
  end

  if (code == KEY_TAB or (control and (code == KEY_I or code == KEY_O))) then
    if (code == KEY_O) then
      shift = not shift
    end
    if (code == KEY_TAB and control) then
      shift = not shift
    end
    if (self:HasSelection()) then
      self:Indent(shift)
    else
      if (shift) then
        local newpos = self.Caret[2] - 4
        if (newpos < 1) then
          newpos = 1
        end
        self.Start = {self.Caret[1], newpos}
        if (self:GetSelection():find("%S")) then
          self.Start = self:CopyPosition(self.Caret)
        else
          self:SetSelection("")
        end
      else
        local count = (self.Caret[2] + 2) % 4 + 1
        self:SetSelection(string.rep(" ", count))
      end
    end
    self.TabFocus = true
  end

  if (control) then
    self:OnShortcut(code)
  end
end

function luapad.EditorPanel:GetWordStart(caret)
  local line = string.ToTable(self.Rows[caret[1]])
  if (#line < caret[2]) then
    return caret
  end
  for i = 0, caret[2] do
    local idx = (caret[2] - i)
    local car = line[idx]

    if (not car) then
      return {caret[1], idx + 1}
    end
    if (car >= "a" and car <= "z" or
        car >= "A" and car <= "Z" or
        car >= "0" and car <= "9") then
    else
      return {caret[1], idx + 1}
    end
  end
  return {caret[1], 1}
end

function luapad.EditorPanel:GetWordEnd(caret)
  local line = string.ToTable(self.Rows[caret[1]])
  if (#line < caret[2]) then
    return caret
  end
  for i = caret[2], #line do
    local car = line[i]

    if (not car) then
      return {caret[1], i}
    end
    if (car >= "a" and car <= "z" or
        car >= "A" and car <= "Z" or
        car >= "0" and car <= "9") then
    else
      return {caret[1], i}
    end
  end
  return {caret[1], #line + 1}
end

function luapad.EditorPanel:Indent(shift)
  local tab_scroll = self:CopyPosition(self.Scroll)
  local tab_start, tab_caret = self:MakeSelection(self:Selection())
  tab_start[2] = 1

  if (tab_caret[2] ~= 1) then
    tab_caret[1] = tab_caret[1] + 1
    tab_caret[2] = 1
  end

  self.Caret = self:CopyPosition(tab_caret)
  self.Start = self:CopyPosition(tab_start)

  if (self.Caret[2] == 1) then
    self.Caret = self:MovePosition(self.Caret, -1)
  end

  if (shift) then
    local tmp = self:GetSelection():gsub("\n ? ? ? ?", "\n")
    self:SetSelection(unIndent(tmp))
  else
    self:SetSelection("    " .. self:GetSelection():gsub("\n", "\n    "))
  end

  self.Caret = self:CopyPosition(tab_caret)
  self.Start = self:CopyPosition(tab_start)
  self.Scroll = self:CopyPosition(tab_scroll)
  self:ScrollCaret()
end

function luapad.EditorPanel:OnTextChanged()
end

function luapad.EditorPanel:OnShortcut()
end

vgui.Register("LuapadEditor", luapad.EditorPanel, "Panel")
