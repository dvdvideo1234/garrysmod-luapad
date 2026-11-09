-- Andreas "Syranide" Svensson's editor for Wire Expression 2
-- Edited by DarKSunrise aka Assassini to work with Luapad and with Lua-syntax

if (SERVER) then
  return
end

local KEYWORD_TOKENS = {
    ["if"]       = true,
    ["elseif"]   = true,
    ["else"]     = true,
    ["then"]     = true,
    ["end"]      = true,
    ["function"] = true,
    ["do"]       = true,
    ["while"]    = true,
    ["break"]    = true,
    ["for"]      = true,
    ["in"]       = true,
    ["local"]    = true,
    ["true"]     = true,
    ["false"]    = true,
    ["nil"]      = true,
    ["NULL"]     = true,
    ["and"]      = true,
    ["not"]      = true,
    ["or"]       = true,
    ["||"]       = true,
    ["&&"]       = true,
    ["!"]        = true,
    ["!="]       = true,
    ["return"]   = true,
    ["continue"] = true,
    ["goto"]     = true,
    ["repeat"]   = true,
    ["until"]    = true,
    ["~="]       = true
}

--[[
 * Default theme customization
]]
local COLOR_HIGHLIGHT = {
  ["#"] = { -- Current skin
    ["gui.currentline"] = {"colTextEntryTextPlaceholder"},
    ["gui.selection"  ] = {"colTextEntryTextHighlight"  },
    ["gui.caretbase"  ] = {"colTextEntryTextCursor"     },
    ["gui.rownumbers" ] = {"colTextEntryTextPlaceholder"},
    ["gui.rowlinebar" ] = {"colTextEntryBorder"         },
    ["gui.background" ] = {"colTextEntryBG"             },
    ["code.none"      ] = {"colTextEntryText"           }
  },
  ["Light"] = {
    ["gui.currentline"] = {Color(220, 220, 220, 255)},
    ["gui.selection"  ] = {Color(170, 170, 170, 255)},
    ["gui.caretbase"  ] = {Color( 72,  61, 139, 255)},
    ["gui.rownumbers" ] = {Color(128, 128, 128, 255)},
    ["gui.rowlinebar" ] = {Color(215, 215, 215, 255)},
    ["gui.background" ] = {Color(250, 250, 250, 255)},
    ["code.none"      ] = {Color(  0,   0,   0, 255)},
    ["code.number"    ] = {Color(218, 165,  32, 255)},
    ["code.function"  ] = {Color(100, 100, 255, 255)},
    ["code.enumerator"] = {Color(184, 134,  11, 255)},
    ["code.metatable" ] = {Color(140, 100,  90, 255)},
    ["code.string"    ] = {Color(120, 120, 120, 255)},
    ["code.construct" ] = {Color(  0,   0, 255, 255)},
    ["code.operator"  ] = {Color(  0,   0, 128, 255)},
    ["code.comment"   ] = {Color(  0, 120,   0, 255)}
  },
  ["Dark"] = {
    ["gui.currentline"] = {Color( 20,  20,  20, 255)},
    ["gui.selection"  ] = {Color( 70,  70,  70, 255)},
    ["gui.caretbase"  ] = {Color(255, 255, 255, 255)},
    ["gui.rownumbers" ] = {Color(128, 128, 128, 255)},
    ["gui.rowlinebar" ] = {Color( 15,  15,  15, 255)},
    ["gui.background" ] = {Color( 50,  50,  50, 255)},
    ["code.none"      ] = {Color(255, 255, 255, 255)},
    ["code.number"    ] = {Color(218, 165,  32, 255)},
    ["code.function"  ] = {Color(220, 220, 170, 255)},
    ["code.enumerator"] = {Color(184, 134,  11, 255)},
    ["code.metatable" ] = {Color(  0, 255, 125, 255)},
    ["code.string"    ] = {Color(206, 145, 120, 255)},
    ["code.construct" ] = {Color(197, 134, 192, 255)},
    ["code.operator"  ] = {Color(  0, 255, 255, 255)},
    ["code.comment"   ] = {Color(  0, 200,   0, 255)}
  }
}

local TOKEN_CLASSIFY = {
  G = {["f"] = true, ["e"] = true, ["m"] = true}, -- Syntax
  T = {["function"] = true, ["table"] = true}, -- Libraries
  S = {"\"", "'", Esc = "\\"}, -- String and escape character
  C = {"-", "/"}, -- Comment definitions with pre processor
  M = {"[", "=", "]"} -- Multi-line token definition
}

-- Create fonts
local FONT_SIZE = {
  ID = 2, -- Default font index
  Form = "%s%s%d", -- Name pattern
  Name = "LuapadCode", -- Base name
  Size = {12, 16, 20, 24, 28, 32}
}

for iF = 1, #FONT_SIZE.Size do
  local iS = FONT_SIZE.Size[iF]
  local sR = FONT_SIZE.Form:format(FONT_SIZE.Name, "R", iS)
  local sB = FONT_SIZE.Form:format(FONT_SIZE.Name, "B", iS)
  surface.CreateFont(sR, {font = "Courier New", size = iS, weight = 400})
  surface.CreateFont(sB, {font = "Courier New", size = iS, weight = 800})
end

local PANEL = {}

function PANEL:Init()
  self:SetCursor("beam")
  self:SetFontInfo()

  self.Rows = {""}
  self.Caret = {1, 1}
  self.Start = {1, 1}
  self.Scroll = {1, 1}
  self.Size = {1, 1}
  self.Undo = {}
  self.Redo = {}
  self.Token = {} -- Multi-line comment token info
  self.Line = "" -- Reference to current line
  self.Str = "" -- Already processed character set
  self.Pos = 0 -- Current processed line position
  self.Char = "" -- The current read character
  self.Buff = {"", ""} -- General concatenation
  self.Clips = nil -- Holds the current clipboard
  self.Blink = RealTime()

  self.ScrollBar = vgui.Create("DVScrollBar", self)
  self.ScrollBar:SetUp(1, 1)

  self.TextEntry = vgui.Create("DTextEntry", self)
  self.TextEntry:SetMultiline(true)
  self.TextEntry:SetAllowNonAsciiCharacters(true)
  self.TextEntry:SetSize(0, 0)

  function self.TextEntry:OnLoseFocus()
    self:GetParent():CustomOnLoseFocus()
  end

  function self.TextEntry:OnTextChanged()
    self:GetParent():CustomOnTextChanged()
  end

  function self.TextEntry:OnKeyCodeTyped(code)
    self:GetParent():CustomOnKeyCodeTyped(code)
  end

  self:SetThemeDefault()
  self.LastClick = 0
end

function PANEL:GetRownum()
  return #self.Rows
end

function PANEL:GetFontSize()
  return self.FontWidth, self.FontHeight
end

function PANEL:RefreshView()
  local tR = self:GetTable().PaintRows -- Clear row cache
  if(istable(tR)) then table.Empty(tR) else self.PaintRows = {} end
end

function PANEL:SetFontInfo(iD)
  -- Calculate the proper font index
  local tS = FONT_SIZE.Size -- The array of font sizes
  local iD = math.floor(math.Clamp((tonumber(iD) or 0), 0, #tS))
  local iF = (tS[iD] and iD or FONT_SIZE.ID) -- Font index
  local iS = tS[iF] -- The actual font size in pixels
  local sR = FONT_SIZE.Form:format(FONT_SIZE.Name, "R", iS)
  local sB = FONT_SIZE.Form:format(FONT_SIZE.Name, "B", iS)
  -- Pick the actual bold or regular font
  surface.SetFont(sR) -- Get proper value from text size
  -- Update the current text size in pixels
  self.FontWidth, self.FontHeight = surface.GetTextSize(" ")
  self.FontName = {ID = iF, R = sR, B = sB}
  self:RefreshView()
  self:InvalidateLayout()
end

function PANEL:GetFontInfo()
  local tN = self:GetTable().FontName
  return tN.ID, table.Copy(FONT_SIZE.Size), FONT_SIZE.ID
end

function PANEL:GetFontName(bB)
  local tN = self:GetTable().FontName
  return (bB and tN.B or tN.R)
end

function PANEL:SetEmptyRow()
  local m_Tab = self:GetTable()
  local m_Cn = self:GetRownum()
  local m_Rw = m_Tab.Rows
  local m_Pn = m_Tab.PaintRows
  if(not m_Rw) then return end
  if(not m_Pn) then return end
  if (m_Rw[m_Cn] ~= "") then
    table.insert(m_Rw, "")
    table.insert(m_Pn, false)
    m_Cn = m_Cn + 1
  end
  return m_Cn
end

function PANEL:GetThemeKeys()
  local tT = self:GetTable().Highlight
  if(not tT) then return nil end
  local tK = table.GetKeys(tT)
  local tM = table.Copy(COLOR_HIGHLIGHT["#"])
  table.sort(tK, function(u, v) return u < v end)
  return tK, tM -- Array with palette keys
end

function PANEL:GetTheme(sT)
  local tT = self:GetTable().Highlight
  if(not tT) then return nil end
  if(not sT) then return nil end
  return tT[sT][1]
end

function PANEL:SetTheme(sT, vC)
  local tT = self:GetTable().Highlight
  if(not tT) then return nil end
  if(not sT) then return nil end
  if(not vC) then return nil end
  tT[sT][1] = vC
end

function PANEL:SetThemeArea(pD, bR)
  local tS = self:GetTable().Highlight
  if(not istable(tS)) then return nil end
  if(not IsValid(pD)) then return nil end
  local tD = pD:GetTable().Highlight
  if(not istable(tD)) then return nil end
  for sT, vT in pairs(tS) do
    local vD = tD[sT]
    if(bR) then
      vD[1] = vT[1]
    else
      vT[1] = vD[1]
    end
  end
  self:RefreshView()
  self:InvalidateLayout()
end

function PANEL:SetThemeDefault(bD, bB)
  local tH = self:GetTable().Highlight or {}
  self.Highlight = tH; table.Empty(tH)
  local sK = (tobool(bD) and "Dark" or "Light")
  local tT, bB = COLOR_HIGHLIGHT[sK], tobool(bB)
  for sT, vC in pairs(tT) do -- Default theme
    local bO = (vC[2] ~= nil) and tobool(vC[2]) or bB
    tH[sT] = {vC[1], bO} -- Reference copy
  end -- Update the string expression
  tH["code.string2"] = tH["code.string"]
  self:RefreshView()
  self:InvalidateLayout()
end

function PANEL:RequestFocus()
  self.TextEntry:RequestFocus()
end

function PANEL:OnGetFocus()
  self.TextEntry:RequestFocus()
end

function PANEL:CursorToCaret()
  local x, y = self:CursorPos()

  x = x - (self.FontWidth * 3 + 6)
  x = ((x < 0) and 0 or x)
  y = ((y < 0) and 0 or y)

  local last, leng = self:GetRownum(), 0
  local line = math.floor(y / self.FontHeight)
  local char = math.floor(x / self.FontWidth + 0.5)

  line = line + self.Scroll[1]
  char = char + self.Scroll[2]
  line = ((line > last) and last or line)
  leng = string.len(self.Rows[line])
  char = math.min(char, leng + 1)

  return {line, char}
end

function PANEL:OnMousePressed(code)
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
    if(not IsValid(pMenu)) then return end
    pMenu:SetParent(self)

    if (self:CanUndo()) then
      pMenu:AddOption(
        "Undo", function()
          self:DoUndo()
        end):SetImage(luapad.ToIcon("arrow_undo"))
    end
    if (self:CanRedo()) then
      pMenu:AddOption(
        "Redo", function()
          self:DoRedo()
        end):SetImage(luapad.ToIcon("arrow_redo"))
    end

    if (self:CanUndo() or self:CanRedo()) then
      pMenu:AddSpacer()
    end

    if (self:HasSelection()) then
      pMenu:AddOption(
        "Cut", function()
          if (self:HasSelection()) then
            self:ToSelection()
            self:SetSelection()
          end
        end):SetImage(luapad.ToIcon("cut"))
      pMenu:AddOption(
        "Copy", function()
          if (self:HasSelection()) then
            self:ToSelection()
          end
        end):SetImage(luapad.ToIcon("page_copy"))
    end

    pMenu:AddOption(
      "Paste", function()
        if (self.Clips) then
          self:SetSelection(self.Clips)
        else
          self:SetSelection()
        end
      end):SetImage(luapad.ToIcon("page_paste"))

    if (self:HasSelection()) then
      pMenu:AddOption(
        "Delete", function()
          self:SetSelection()
        end):SetImage(luapad.ToIcon("page_delete"))
    end

    pMenu:AddSpacer()

    pMenu:AddOption(
      "Select all", function()
        self:SelectAll()
      end):SetImage(luapad.ToIcon("pencil"))

    pMenu:Open()
    pMenu:MakePopup()
  end
end

function PANEL:OnMouseReleased(code)
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

function PANEL:SetText(text)
  self.Rows = string.Explode("\n", text)

  local last = self:SetEmptyRow()

  self.Caret = {1, 1}
  self.Start = {1, 1}
  self.Scroll = {1, 1}
  self.Undo = {}
  self.Redo = {}

  self:RefreshView()
  self.ScrollBar:SetUp(self.Size[1], last - 1)
end

function PANEL:GetText()
  return string.Implode("\n", self.Rows)
end

function PANEL:MultiLineBlock(vM, vT)
  local tT = self.Token
  if(vM ~= nil) then tT.M = vM end
  if(vT ~= nil) then tT.T = vT end
  return tT.M, tT.T
end

function PANEL:InitColorLine(row)
  if(not row) then return end
  self.Line = self.Rows[row]

  self.Pos = 0
  self.Str = ""
  self.Char = ""
  self.Buff[1] = ""
  self.Buff[2] = ""

  if(row == 1) then
    self:MultiLineBlock(false, false)
  end
end

function PANEL:Concat(sA, sB, sC)
  self.Buff[1] = sA
  self.Buff[2] = sB
  return table.concat(self.Buff, sC)
end

function PANEL:NextChar()
  local last = self.Char
  if (not last) then return end

  self.Str = self:Concat(self.Str, self.Char)
  self.Pos = self.Pos + 1

  if (self.Pos <= string.len(self.Line)) then
    self.Char = string.sub(self.Line, self.Pos, self.Pos)
  else
    self.Char = nil
  end

  return self.Char, last
end

function PANEL:SyntaxColorLine(row)
  local tRow = self.PaintRows[row]
  if(tRow) then return tRow end

  local tLib = {}; tRow = {}
  local m_Glob = TOKEN_CLASSIFY.G
  local m_Type = TOKEN_CLASSIFY.T
  local m_Strm = TOKEN_CLASSIFY.S
  local m_Coms = TOKEN_CLASSIFY.C
  local m_Muln = TOKEN_CLASSIFY.M

  self:InitColorLine(row)

  local char, last = self:NextChar()

  while char do
    local token = ""
    self.Str = ""

    while(char and char == " ") do
      char, last = self:NextChar()
    end

    if(not char) then break end

    local multy, mtoken = self:MultiLineBlock()

    if(multy) then
      if(char == m_Muln[3]) then
        local multy, open = multy, char
        char, last = self:NextChar()
        while(char and char == m_Muln[2]) do
          multy = multy - 1
          char, last = self:NextChar()
        end
         -- Equals are same amount as start
        if(multy == 0 and char == open) then
          char, last = self:NextChar()
          token = (mtoken or "code.none")
          -- Reset multi line block
          self:MultiLineBlock(false, false)
        else -- Otherwise continue with the multi line color
          token = (mtoken or "code.none") -- Keep the last token
        end
      else
        char, last = self:NextChar()
        token = (mtoken or "code.none") -- Keep the last token
      end
    elseif (char >= "0" and char <= "9") then
      while char and (char >= "0" and char <= "9" or
                      char == "." or char == "_") do
        char, last = self:NextChar()
      end

      token = "code.number"
    elseif (char >= "a" and char <= "z" or char >= "A" and char <= "Z" or char == "_") then

      while char and (char >= "a" and char <= "z" or
                      char >= "A" and char <= "Z" or
                      char >= "0" and char <= "9" or char == "_") do
        char, last = self:NextChar()
      end

      local sstr = string.Trim(self.Str)
      local gstr = luapad.CheckGlobal(sstr, tLib)
      local tgstr = type(gstr)

      if (KEYWORD_TOKENS[sstr]) then

        token = "code.construct"

      elseif ((gstr and (m_Type[tgstr] or m_Glob[gstr])) or
              (sstr and tLib.Src and tLib.Src[sstr])) then
      -- Could be better code, but what the hell; it works
        if (tgstr == "table") then
          tLib.Src = gstr

          if(tLib.Nam) then
            tLib.Nam = self:Concat(tLib.Nam, sstr, ".")
          else
            tLib.Nam = sstr
          end
        end

        if ((gstr == "e") and sstr == string.upper(sstr)) then
          token = "code.enumerator"
        elseif (gstr == "m") then
          token = "code.metatable"
        else
          token = "code.function"
        end

      else
        tLib.Src = nil
        tLib.Nam = nil
        token = "code.none"
      end

    elseif (char == m_Strm[1]) then

      char, last = self:NextChar()
      while(char and char ~= m_Strm[1]) do
        if (char == m_Strm.Esc) then
          char, last = self:NextChar()
        end
        char, last = self:NextChar()
      end
      char, last = self:NextChar()

      token = "code.string"
    elseif (char == m_Strm[2]) then
      char, last = self:NextChar()
      while(char and char ~= m_Strm[2]) do
        if (char == m_Strm.Esc) then
          char, last = self:NextChar()
        end
        char, last = self:NextChar()
      end
      char, last = self:NextChar()

      token = "code.string2"
    elseif (char == m_Coms[1] or char == m_Coms[2]) then
      char, last = self:NextChar()

      if (char == last) then
        while(char and char == last) do
          char, last = self:NextChar()
        end
        token = "code.comment"
        self:MultiLineBlock(false, token)
      else
        token = "code.none"
        self:MultiLineBlock(false, false)
      end
    elseif (char == m_Muln[1]) then
      local multy, open = 0, char
      char, last = self:NextChar()
      while(char and char == m_Muln[2]) do
        char, last = self:NextChar()
        multy = multy + 1
      end
      if (char == open) then
        char, last = self:NextChar()
        if(mtoken == "code.comment") then
          token = mtoken
        else
          token = "code.string"
        end
        self:MultiLineBlock(multy, token)
      else
        self:MultiLineBlock(false, false)
        token = "code.none" -- Reset multi line
      end
    else
      char, last = self:NextChar()
      token = "code.operator"
    end

    local tC = self.Highlight[token]
    local nH = #tRow

    if (nH > 1 and tC == tRow[nH][2]) then
      tRow[nH][1] = self:Concat(tRow[nH][1], self.Str)
    else
      table.insert(tRow, {self.Str, tC, (multy ~= nil)})
    end
  end
  -- Cache the highlight view
  self.PaintRows[row] = tRow
  -- Return the calculated row
  return tRow
end

function PANEL:PaintLine(row, guiCB, guiSE, guiRN, guiCL)
  if (row > self:GetRownum()) then return end

  local tRow = self:SyntaxColorLine(row)
  local width, height = self.FontWidth, self.FontHeight
  local scstr, scend  = self.Scroll[1], self.Scroll[2]
  local castr, caend  = self.Caret[1] , self.Caret[2]

  if (row == castr and self.TextEntry:HasFocus()) then
    surface.SetDrawColor(guiCL:Unpack())
    surface.DrawRect(width * 3 + 5, (row - scstr) * height, self:GetWide() - (width * 3 + 5), height)
  end

  if (self:HasSelection()) then
    local start, stop = self:MakeSelection(self:Selection())
    local line, char = start[1], start[2]
    local endline, endchar = stop[1], stop[2]

    surface.SetDrawColor(guiSE:Unpack())
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

  draw.SimpleText(tostring(row), self:GetFontName(), width * 3, (row - scstr) * height, guiRN, TEXT_ALIGN_RIGHT)

  local offset = -scend + 1
  for i, cell in ipairs(tRow) do
    local ccon, csr, cen = cell[1], cell[2][1], cell[2][2]

    if (offset < 0) then
      if (string.len(ccon) > -offset) then
        line = string.sub(ccon, -offset + 1)
        offset = string.len(line)
        draw.SimpleText(line, self:GetFontName(cen), width * 3 + 6, (row - scstr) * height, csr)
      else
        offset = offset + string.len(ccon)
      end
    else
      draw.SimpleText(ccon, self:GetFontName(cen), offset * width + width * 3 + 6, (row - scstr) * height, csr)
      offset = offset + string.len(ccon)
    end
  end

  if (row == castr and self.TextEntry:HasFocus()) then
    if ((RealTime() - self.Blink) % 0.8 < 0.4 and caend >= scend) then
        surface.SetDrawColor(guiCB:Unpack())
        surface.DrawRect((caend - scend) * width + width * 3 + 6,
                         (castr - scstr) * height, 1, height)
    end
  end
end

function PANEL:PerformLayout()
  local nW, nH = self:GetFontSize()
  local mW, mT = self:GetWide(), self:GetTall()

  self.ScrollBar:SetSize(16, mT)
  self.ScrollBar:SetPos(mW - 16, 0)
  self.Size[1] = math.floor(mT / nH) - 1
  self.Size[2] = math.floor((mW - (nW * 3 + 6) - 16) / nW) - 1

  self.ScrollBar:SetUp(self.Size[1], self:GetRownum() - 1)
end

--[[
 * Render from the first line otherwise the multiline coments are not triggered correctly
 * It is possible the beginning of the screen to be in the middle of a multiline comment
 * Because of that the rendering should start from the last row that is not a multiline entry
]]
function PANEL:GetRenderBounds()
  local m_Tab = self:GetTable()
  local m_Par = m_Tab.PaintRows
  local m_S = m_Tab.Scroll[1]
  local m_E = (m_S + m_Tab.Size[1] + 1)
  if(not m_Par) then return 1, m_E end
  if(table.IsEmpty(m_Par)) then return 1, m_E end
  while(m_S > 1 and m_Par[m_S]) do
    if(not m_Par[m_S][3]) then break end
    m_S = m_S - 1 -- Get the previos row
  end -- Find the first not multiline row
  return m_S, m_E -- Return render bounds
end

function PANEL:Paint(w, h)
  if (not input.IsMouseDown(MOUSE_LEFT)) then
    self:OnMouseReleased(MOUSE_LEFT)
  end

  if (not self.PaintRows) then
    self:RefreshView()
  end

  if (self.MouseDown) then
    self.Caret = self:CursorToCaret()
  end

  local mW, mT = self:GetWide(), self:GetTall()

  surface.SetDrawColor(self:GetTheme("gui.rowlinebar"):Unpack())
  surface.DrawRect(0, 0, self.FontWidth * 3 + 4, mT)

  surface.SetDrawColor(self:GetTheme("gui.background"):Unpack())
  surface.DrawRect(self.FontWidth * 3 + 5, 0, mW - (self.FontWidth * 3 + 5), mT)

  self.Scroll[1] = math.floor(self.ScrollBar:GetScroll() + 1)

  local guiCB = self:GetTheme("gui.caretbase")
  local guiSE = self:GetTheme("gui.selection")
  local guiRN = self:GetTheme("gui.rownumbers")
  local guiCL = self:GetTheme("gui.currentline")

  local m_S, m_E = self:GetRenderBounds()
  for iR = m_S, m_E do
    self:PaintLine(iR, guiCB, guiSE, guiRN, guiCL)
  end

  return true
end

function PANEL:SetCaret(caret)
  self.Caret = self:CopyPosition(caret)
  self.Start = self:CopyPosition(caret)
  self:ScrollCaret()
end

function PANEL:CopyPosition(caret)
  return {caret[1], caret[2]}
end

function PANEL:MovePosition(caret, offset)
  local caret = {caret[1], caret[2]}

  if (offset > 0) then
    while true do
      local length = string.len(self.Rows[caret[1]]) - caret[2] + 2
      if (offset < length) then
        caret[2] = caret[2] + offset
        break
      elseif (caret[1] == self:GetRownum()) then
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

function PANEL:HasSelection()
  return (self.Caret[1] ~= self.Start[1] or self.Caret[2] ~= self.Start[2])
end

function PANEL:Selection()
  return {{self.Caret[1], self.Caret[2]}, {self.Start[1], self.Start[2]}}
end

function PANEL:MakeSelection(selection)
  local start, stop = selection[1], selection[2]

  if (start[1] < stop[1] or start[1] == stop[1] and start[2] < stop[2]) then
    return start, stop
  else
    return stop, start
  end
end

function PANEL:GetArea(selection)
  local start, stop = self:MakeSelection(selection)

  if (start[1] == stop[1]) then
    return string.sub(self.Rows[start[1]], start[2], stop[2] - 1)
  else
    local text = string.sub(self.Rows[start[1]], start[2])
    local m_S, m_E = (start[1] + 1), (stop[1] - 1)

    if m_S <= m_E then
      local chunk = table.concat(self.Rows, "\n", m_S, m_E)
      text = text .. "\n" .. chunk
    end

    return text .. "\n" .. string.sub(self.Rows[stop[1]], 1, stop[2] - 1)
  end
end

function PANEL:SetArea(selection, text, isundo, isredo, before, after)

  local start, stop = self:MakeSelection(selection)
  local buffer = self:GetArea(selection)

  if (start[1] ~= stop[1] or start[2] ~= stop[2]) then
    -- Clear selection
    self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1)..
                          string.sub(self.Rows[stop[1]], stop[2])
    self.PaintRows[start[1]] = false

    for i = start[1] + 1, stop[1] do
      table.remove(self.Rows, start[1] + 1)
      table.remove(self.PaintRows, start[1] + 1)
      self:RefreshView()
    end

    self:SetEmptyRow()
  end

  if (not text or text == "") then
    self.ScrollBar:SetUp(self.Size[1], self:GetRownum() - 1)

    self:RefreshView()
    self:OnTextChanged()

    if (isredo) then
      local tU = {self:CopyPosition(start), self:CopyPosition(start)}
      table.insert(self.Undo, {tU, buffer, after, before})
      return before
    elseif (isundo) then
      local tU = {self:CopyPosition(start), self:CopyPosition(start)}
      table.insert(self.Redo, {tU, buffer, after, before})
      return before
    else
      local tU = {self:CopyPosition(start), self:CopyPosition(start)}
      self.Redo = self.Redo or {}; table.Empty(self.Redo)
      table.insert(self.Undo, {tU, buffer, self:CopyPosition(selection[1]), self:CopyPosition(start)})
      return start
    end
  end

  -- Insert text
  local rows = string.Explode("\n", text)

  local remainder = string.sub(self.Rows[start[1]], start[2])
  self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. rows[1]
  self.PaintRows[start[1]] = false

  for i = 2, #rows do
    table.insert(self.Rows, start[1] + i - 1, rows[i])
    table.insert(self.PaintRows, start[1] + i - 1, false)
    self:RefreshView() -- TODO: fix for cache errors
  end

  local stop = {start[1] + #rows - 1, string.len(self.Rows[start[1] + #rows - 1]) + 1}

  self.Rows[stop[1]] = self.Rows[stop[1]] .. remainder
  self.PaintRows[stop[1]] = false

  self:SetEmptyRow()
  self.ScrollBar:SetUp(self.Size[1], self:GetRownum() - 1)

  self:RefreshView()
  self:OnTextChanged()

  if (isredo) then
    local tU = {self:CopyPosition(start), self:CopyPosition(stop)}
    table.insert(self.Undo, {tU, buffer, after, before})
    return before
  elseif (isundo) then
    local tU = {self:CopyPosition(start), self:CopyPosition(stop)}
    table.insert(self.Redo, {tU, buffer, after, before})
    return before
  else
    local tU = {self:CopyPosition(start), self:CopyPosition(stop)}
    self.Redo = self.Redo or {}; table.Empty(self.Redo)
    table.insert(self.Undo, {tU, buffer, self:CopyPosition(selection[1]), self:CopyPosition(stop)})
    return stop
  end
end

function PANEL:GetSelection()
  return self:GetArea(self:Selection())
end

function PANEL:SetSelection(text)
  self:SetCaret(self:SetArea(self:Selection(), text))
end

function PANEL:ToSelection()
  self.Clips = self:GetSelection()
  self.Clips = string.Replace(self.Clips, "\n", "\r\n")
  SetClipboardText(self.Clips)
end

function PANEL:CustomOnLoseFocus()
  if (self.TabFocus) then
    self:RequestFocus()
    self.TabFocus = nil
  end
end

function PANEL:CustomOnTextChanged()
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

function PANEL:OnMouseWheeled(delta)
  local m_Scroll = self.Scroll
  local m_Sign = ((delta > 0 and 1) or (delta < 0 and -1) or 0)
  local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)

  if(control and m_Sign ~= 0) then
    local iF = self:GetFontInfo() + m_Sign
    local iS = ((iF == 0) and 1 or iF)
    local tS = self:GetParent():GetStreamInfo()
    self:SetFontInfo(iS)
    tS.Font = self:GetFontInfo()
  else
    m_Scroll[1] = math.max(m_Scroll[1] - 4 * delta, 1)
    m_Scroll[1] = math.min(m_Scroll[1], self:GetRownum())
    self.ScrollBar:SetScroll(m_Scroll[1] - 1)
  end
end

function PANEL:ScrollCaret()
  local m_Size = self.Size
  local m_Caret = self.Caret
  local m_Scroll = self.Scroll

  if (m_Caret[1] - m_Scroll[1] < 2) then
    m_Scroll[1] = math.max(m_Caret[1] - 2, 1)
  end

  if (m_Caret[1] - m_Scroll[1] > m_Size[1] - 2) then
    m_Scroll[1] = math.max(m_Caret[1] - m_Size[1] + 2, 1)
  end

  if (m_Caret[2] - m_Scroll[2] < 4) then
    m_Scroll[2] = math.max(m_Caret[2] - 4, 1)
  end

  if (m_Caret[2] - 1 - m_Scroll[2] > m_Size[2] - 4) then
    m_Scroll[2] = math.max(m_Caret[2] - 1 - m_Size[2] + 4, 1)
  end

  self.ScrollBar:SetScroll(m_Scroll[1] - 1)
end

function PANEL:UnIndent(line)
  local iF = line:find("%S")
  local iS = (iF == nil or iF > 5) and 5 or iF
  return line:sub(iS)
end

function PANEL:CanUndo()
  return #self.Undo > 0
end

function PANEL:DoUndo()
  local tU = self.Undo
  local nU = #tU
  if (nU <= 0) then return end
  local tC = tU[nU]; tU[nU] = nil
  self:SetCaret(self:SetArea(tC[1], tC[2], true, false, tC[3], tC[4]))
end

function PANEL:CanRedo()
  return #self.Redo > 0
end

function PANEL:DoRedo()
  local tR = self.Redo
  local nR = #tR
  if (nR <= 0) then return end
  local tC = tR[nR]; tR[nR] = nil
  self:SetCaret(self:SetArea(tC[1], tC[2], false, true, tC[3], tC[4]))
end

function PANEL:SelectAll()
  local nR = self:GetRownum()
  self.Caret = {nR, string.len(self.Rows[nR]) + 1}
  self.Start = {1, 1}
  self:ScrollCaret()
end

function PANEL:CustomOnKeyCodeTyped(code)
  self.Blink = RealTime()

  local alt = input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)
  local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
  local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)

  if (control and alt and code == KEY_S) then
    luapad.SaveAsScript()
  end

  if (alt) then return end

  if (control) then
    if (code == KEY_A) then
      self:SelectAll()
    elseif (code == KEY_Z) then
      self:DoUndo()
    elseif (code == KEY_Y) then
      self:DoRedo()
    elseif (code == KEY_X) then
      if (self:HasSelection()) then
        self:ToSelection()
        self:SetSelection()
      end
    elseif (code == KEY_C) then
      if (self:HasSelection()) then
        self:ToSelection()
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
      self.Scroll[1] = math.max(self.Scroll[1] - 1, 1)
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
      self.Caret[1] = self:GetRownum()
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
      luapad.RunScriptClient()
      luapad.RunScriptServer(nil, true)
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
        self.Caret[2] = math.min(self.Caret[2], length + 1)
      end

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_DOWN) then
      if (self.Caret[1] < self:GetRownum()) then
        self.Caret[1] = self.Caret[1] + 1

        local length = string.len(self.Rows[self.Caret[1]])
        self.Caret[2] = math.min(self.Caret[2], length + 1)
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
      self.Caret[1] = math.max(self.Caret[1], 1)

      local length = string.len(self.Rows[self.Caret[1]])
      self.Caret[2] = math.min(self.Caret[2], length + 1)
      self.Scroll[1] = math.max(self.Scroll[1], 1)
      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_PAGEDOWN) then
      self.Caret[1] = self.Caret[1] + math.ceil(self.Size[1] / 2)
      self.Scroll[1] = self.Scroll[1] + math.ceil(self.Size[1] / 2)

      self.Caret[1] = math.min(self.Caret[1], self:GetRownum())

      if (self.Caret[1] == self:GetRownum()) then
        self.Caret[2] = 1
      end

      local length = string.len(self.Rows[self.Caret[1]])
      self.Caret[2] = math.min(self.Caret[2], length + 1)
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
        local newpos = math.max(self.Caret[2] - 4, 1)
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

function PANEL:GetWordStart(caret)
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

function PANEL:GetWordEnd(caret)
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

function PANEL:Indent(shift)
  local m_Scr = self:CopyPosition(self.Scroll)
  local m_Str, m_Car = self:MakeSelection(self:Selection())

  m_Str[2] = 1
  if (m_Car[2] ~= 1) then
    m_Car[1] = m_Car[1] + 1
    m_Car[2] = 1
  end

  self.Caret = self:CopyPosition(m_Car)
  self.Start = self:CopyPosition(m_Str)

  if (self.Caret[2] == 1) then
    self.Caret = self:MovePosition(self.Caret, -1)
  end

  if (shift) then
    local tmp = self:GetSelection():gsub("\n ? ? ? ?", "\n")
    self:SetSelection(self:UnIndent(tmp))
  else
    self:SetSelection("    " .. self:GetSelection():gsub("\n", "\n    "))
  end

  self.Caret = self:CopyPosition(m_Car)
  self.Start = self:CopyPosition(m_Str)
  self.Scroll = self:CopyPosition(m_Scr)
  self:ScrollCaret()
end

function PANEL:OnTextChanged()
end

function PANEL:OnShortcut()
end

vgui.Register("LuapadEditor", PANEL, "Panel")
