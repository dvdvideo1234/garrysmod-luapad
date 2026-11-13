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
 * https://www.w3schools.com/colors/colors_converter.asp
]]
local COLOR_HIGHLIGHT = {
  Skin = { -- Current skin
    ["gui.currentline"] = {"colTextEntryBorder"         },
    ["gui.selection"  ] = {"colTextEntryTextHighlight"  },
    ["gui.caretbase"  ] = {"colTextEntryTextCursor"     },
    ["gui.rownumbers" ] = {"colTextEntryTextPlaceholder"},
    ["gui.rowlinebar" ] = {"colTextEntryBorder"         },
    ["gui.background" ] = {"colTextEntryBG"             },
    ["code.none"      ] = {"colTextEntryText"           }
  },
  Reuse = {
    ["code.hyperlink" ] = "code.operator" ,
    ["code.number"    ] = "code.none"     ,
    ["code.library"   ] = "code.function" ,
    ["code.function"  ] = "code.none"     ,
    ["code.enumerator"] = "code.number"   ,
    ["code.metatable" ] = "code.function" ,
    ["code.string"    ] = "code.library"  ,
    ["code.construct" ] = "code.library"  ,
    ["code.operator"  ] = "code.construct",
    ["code.comment"   ] = "code.metatable",
    ["code.string2"   ] = "code.string"
  },
  Default = {
    ["Light"] = {
      ["gui.currentline"] = {Color(220, 220, 220, 255)},
      ["gui.selection"  ] = {Color(170, 170, 170, 255)},
      ["gui.caretbase"  ] = {Color( 72,  61, 139, 255)},
      ["gui.rownumbers" ] = {Color(128, 128, 128, 255)},
      ["gui.rowlinebar" ] = {Color(215, 215, 215, 255)},
      ["gui.background" ] = {Color(250, 250, 250, 255)},
      ["code.none"      ] = {Color(  0,   0,   0, 255)},
      ["code.hyperlink" ] = {Color(  9, 105, 218, 255)},
      ["code.number"    ] = {Color(218, 165,  32, 255)},
      ["code.library"   ] = {Color(215, 100, 255, 255)},
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
      ["code.hyperlink" ] = {Color( 88, 166, 255, 255)},
      ["code.number"    ] = {Color(218, 165,  32, 255)},
      ["code.library"   ] = {Color(220, 220, 170, 255)},
      ["code.function"  ] = {Color(215, 100, 170, 255)},
      ["code.enumerator"] = {Color(184, 134,  11, 255)},
      ["code.metatable" ] = {Color(  0, 255, 125, 255)},
      ["code.string"    ] = {Color(206, 145, 120, 255)},
      ["code.construct" ] = {Color(197, 134, 192, 255)},
      ["code.operator"  ] = {Color(  0, 255, 255, 255)},
      ["code.comment"   ] = {Color(  0, 200,   0, 255)}
    }
  }
}

local TOKEN_CLASSIFY = {
  SKP = {[" "] = true, ["\t"] = true}, -- Skip characters
  SEL = {W = "\r\n", L = "\n", M = "\r"}, -- System EOLs
  EOL = {E = "[\r\n]+", I = "\n"}, -- General pattern for splitting
  URL = "https?://%S+%.%S+", -- URL pattern matching
  COM = {["-"] = "--.*$", ["/"] = "//.*$"}, -- Comments
  NUM = "[0-9%.][0-9%.]+", -- A number literal matching numbers
  STR = {
    E = "\\", -- Escape character. Ignore the end
    D = {M = "\"", Q = '"[^"]*"', E = '".*$'},
    S = {M = "\'", Q = "'[^']*'", E = "'.*$"}
  }, -- String patterns literal matching
  MUL = {S = "%[=*%[", E = "%]=*%]"},
  GTK = {["f"] = true, ["e"] = true, ["m"] = true}, -- Syntax
  TTK = {["function"] = true, ["table"] = true}, -- Libraries
  S = {"\"", "'", Esc = "\\"}, -- String and escape character
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

function PANEL:GetThemeKeys()
  local tT = self:GetTable().Highlight
  if(not tT) then return nil end
  local tK = table.GetKeys(tT)
  local tM = table.Copy(COLOR_HIGHLIGHT.Skin)
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

function  PANEL:SetThemeReuse(bD)
  local tR = COLOR_HIGHLIGHT.Reuse
  local tH = self:GetTable().Highlight
  for sR, sK in pairs(tR) do
    local iC = 10 -- Make maximum 10 jumps
    local sC = sR -- Reuse start index
    local tC = tH[sC] -- Start data
    while(iC > 0 and sC and not tC) do iC = iC - 1
      sC = tR[sC] -- Navigate to the next key
      tC = tH[sC] -- Navigate to the next data
    end -- Find a color with 10 jumps max
    if(tC and istable(tC) and IsColor(tC[1])) then
      tH[sR] = tC -- Color has been navigated
    else -- Otherwise
      local vC = (bD and color_white or color_black)
      tH[sR] = {vC, false} -- Base color no bold
    end
  end
end

function PANEL:SetThemeDefault(bD, bB)
  local tH = self:GetTable().Highlight or {}
  self.Highlight = tH; table.Empty(tH)
  local bD, bB = tobool(bD), tobool(bB)
  local sK = (bD and "Dark" or "Light")
  local tT = COLOR_HIGHLIGHT.Default[sK]
  for sT, tC in pairs(tT) do -- Default theme
    local bO = ((tC[2] ~= nil) and tobool(tC[2]) or bB)
    tH[sT] = {tC[1], bO} -- Reference copy
  end -- Update the string expression
  self:SetThemeReuse(tobool(bD))
  self:RefreshView()
  self:InvalidateLayout()
end

function PANEL:SetThemeInvert()
  local tH = self:GetTable().Highlight
  if(not tH) then return end
  if(not istable(tH)) then return end
  if(table.IsEmpty(tH)) then return end
  for sT, tC in pairs(tH) do -- Default theme
    local vC = tC[1]:Copy()
    luapad.GetInvertColor(vC, true)
    tH[sT][1] = vC -- Assign new color
  end
end

function PANEL:RequestFocus()
  self.TextEntry:RequestFocus()
end

function PANEL:OnGetFocus()
  self.TextEntry:RequestFocus()
end

function PANEL:SetEmptyRow()
  local tTab = self:GetTable()
  local iCn = self:GetRownum()
  local tRw = tTab.Rows
  if(not tRw) then return end
  local tPn = tTab.PaintRows
  if(not tPn) then return end
  if (tRw[iCn] ~= "") then
    table.insert(tRw, "")
    table.insert(tPn, false)
    iCn = iCn + 1
  end
  return iCn
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

    if (self:HasSelection()) then
      local sS = self:GetSelection()
      local sU = sS:match(TOKEN_CLASSIFY.URL)
      if(sU) then
        pMenu:AddSpacer()
        pMenu:AddOption(
          "Follow", function()
            gui.OpenURL(sU)
          end):SetImage(luapad.ToIcon("world_link"))
      end
    end

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
  local g_NP = TOKEN_CLASSIFY.EOL.E

  self.Rows = string.Explode(g_NP, text, true)

  print("Rows:", #self.Rows)

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
  local g_NL = TOKEN_CLASSIFY.EOL.I
  return string.Implode(g_NL, self.Rows)
end

function PANEL:SetLineBlock(vM, vT)
  local tT = self.Token
  if(vM ~= nil) then tT.M = vM end
  if(vT ~= nil) then tT.T = vT end
end

function PANEL:GetLineBlock()
  local tT = self.Token
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
    self:SetLineBlock(false, false)
  end
end

function PANEL:Concat(sA, sB, sC)
  local tB = self.Buff
  tB[1], tB[2] = sA, sB
  return table.concat(tB, sC)
end

function PANEL:NextChar()
  local sLast = self.Char
  if (not sLast) then return end
  local sLine = self.Line
  local iPos  = (self.Pos + 1)

  self.Pos = iPos
  self.Str = self:Concat(self.Str, sLast)

  if (iPos <= string.len(sLine)) then
    self.Char = string.sub(sLine, iPos, iPos)
  else
    self.Char = nil
  end

  return self.Char, sLast
end

function PANEL:NextSpan(sP, bN)
  local sL = self.Line
  local iP = self.Pos
  local sS = self.Str
  local nL = string.len(sL)
  if(iP > nL) then
    self.Char = nil
    return false, sS
  end
  local iS, iE = sL:find(sP, iP, bN)
  if(not (iS and iE)) then return false, sS end
  sS = self:Concat(self.Str, sL:sub(iS, iE))
  iP = iE + 1
  self.Str, self.Pos = sS, iP
  self.Char = sL:sub(iP, iP)
  return true
end

function PANEL:SyntaxColorLine(row)
  local tRow = self.PaintRows[row]
  if(tRow) then return tRow end

  local tLib = {}; tRow = {}
  local g_Skip = TOKEN_CLASSIFY.SKP
  local g_Coms = TOKEN_CLASSIFY.COM
  local g_Glob = TOKEN_CLASSIFY.GTK
  local g_Type = TOKEN_CLASSIFY.TTK
  local g_Patn = TOKEN_CLASSIFY.NUM
  local g_Strm = TOKEN_CLASSIFY.S
  local g_Muln = TOKEN_CLASSIFY.M

  self:InitColorLine(row)

  local char, last = self:NextChar()

  print("Loop:", row, char)

  while char do
    local token = ""
    self.Str = ""

    while(char and g_Skip[char]) do
      char, last = self:NextChar()
    end

    if(not char) then break end

    local multy, mtoken = self:GetLineBlock()

    if(mtoken) then
      if(multy) then
        if(char == g_Muln[3]) then
          local multy, open = multy, char
          char, last = self:NextChar()
          while(char and char == g_Muln[2]) do
            multy = multy - 1
            char, last = self:NextChar()
          end
           -- Equals are same amount as start
          if(multy == 0 and char == open) then
            char, last = self:NextChar()
            token = (mtoken or "code.none")
            -- Reset multi line block
            self:SetLineBlock(false, false)
          else -- Continue with the line block color
            token = (mtoken or "code.none")
            char, last = self:NextChar()
          end -- Keep the last token
        else -- Keep the last token
          token = (mtoken or "code.none")
          char, last = self:NextChar()
        end
      else -- Keep the last token
        token = (mtoken or "code.none")
        char, last = self:NextChar()
      end
    elseif (self:NextSpan(g_Patn)) then
      token = "code.number"
    --elseif ((char >= "0" and char <= "9") or char == ".") then
    --  while char and (char >= "0" and char <= "9" or
    --                  char == "." or char == "_") do
    --    char, last = self:NextChar()
    --  end
    --
    --  token = "code.number"
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

      elseif ((gstr and (g_Type[tgstr] or g_Glob[gstr])) or
              (sstr and tLib.Src and tLib.Src[sstr])) then
      -- Could be better code, but what the hell; it works
        if (tgstr == "table") then
          tLib.Src, token = gstr, "code.library"

          if(tLib.Nam) then
            tLib.Nam = self:Concat(tLib.Nam, sstr, ".")
          else
            tLib.Nam = sstr
          end

        elseif ((gstr == "e") and sstr == string.upper(sstr)) then
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

    elseif (char == g_Strm[1]) then

      -- print("String:", "|"..self.Line:sub(self.Pos, -1).."|")

      char, last = self:NextChar()
      while(char and char ~= g_Strm[1]) do
        if (char == g_Strm.Esc) then
          char, last = self:NextChar()
        end
        char, last = self:NextChar()
      end
      char, last = self:NextChar()

      token = "code.string"
    elseif (char == g_Strm[2]) then
      char, last = self:NextChar()
      while(char and char ~= g_Strm[2]) do
        if (char == g_Strm.Esc) then
          char, last = self:NextChar()
        end
        char, last = self:NextChar()
      end
      char, last = self:NextChar()

      token = "code.string2"
    elseif (g_Coms[char]) then
      char, last = self:NextChar()

      if (char == last) then
        while(char and char == last) do
          char, last = self:NextChar()
        end
        token = "code.comment"
        self:SetLineBlock(false, token)
      else
        token = "code.none"
        self:SetLineBlock(false, false)
      end
    elseif (char == g_Muln[1]) then
      local multy, open = 0, char
      char, last = self:NextChar()
      while(char and char == g_Muln[2]) do
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
        self:SetLineBlock(multy, token)
      else
        self:SetLineBlock(false, false)
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

    print(common.stringPadL(tostring(row), 5),
          common.stringPadL(tostring(token), 20),
          common.stringPadL(tostring(self.Pos), 5),
          common.stringPadL("|"..tostring(tRow[#tRow][1]):sub(-20,-1).."|", 20),
          common.stringPadL(tostring(self.Line):sub(self.Pos,self.Pos), 2)
          )
  end
  -- Comment was spawned to the end of line
  local multy, mtoken = self:GetLineBlock()
  if(not multy) then
    self:SetLineBlock(false, false)
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
    local sline, schar = start[1], start[2]
    local eline, echar =  stop[1],  stop[2]

    surface.SetDrawColor(guiSE:Unpack())
    local length = string.len(self.Rows[row]) - scend + 1

    schar = math.max(schar - scend, 0)
    echar = math.max(echar - scend, 0)

    if (row == sline and sline == eline) then
      surface.DrawRect(schar * width + width * 3 + 6, (row - scstr) * height, width * (echar - schar), height)
    elseif (row == sline) then
      surface.DrawRect(schar * width + width * 3 + 6, (row - scstr) * height, width * (length - schar + 1), height)
    elseif (row == eline) then
      surface.DrawRect(width * 3 + 6, (row - scstr) * height, width * echar, height)
    elseif (row > sline and row < eline) then
      surface.DrawRect(width * 3 + 6, (row - scstr) * height, width * (length + 1), height)
    end
  end

  draw.SimpleText(tostring(row), self:GetFontName(), width * 3, (row - scstr) * height, guiRN, TEXT_ALIGN_RIGHT)

  local offset = (-scend + 1)
  for i, cell in ipairs(tRow) do
    local ccon, csr, cen = cell[1], cell[2][1], cell[2][2]

    if (offset < 0) then
      if (string.len(ccon) > -offset) then
        local suline = string.sub(ccon, -offset + 1); offset = string.len(suline)
        draw.SimpleText(suline, self:GetFontName(cen), width * 3 + 6, (row - scstr) * height, csr)
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
 * Render from the first line otherwise the multi-line comments are not triggered correctly
 * It is possible the beginning of the screen to be in the middle of a multi-line comment
 * Because of that the rendering should start from the last row that is not a multi-line entry
]]
function PANEL:GetRenderBounds()
  local tTab = self:GetTable()
  local tPar = tTab.PaintRows
  local iS = tTab.Scroll[1]
  local iE = (iS + tTab.Size[1] + 1)
  if(not tPar) then return 1, iE end
  if(table.IsEmpty(tPar)) then return 1, iE end
  while(iS > 1 and tPar[iS]) do
    if(not tPar[iS][3]) then break end
    iS = iS - 1 -- Get the previous row
  end -- Find the first not multi-line row
  return iS, iE -- Return render bounds
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

  local iS, iE = self:GetRenderBounds()
  print("Bounds:", iS, iE)
  for iR = iS, iE do
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
  local g_NL = TOKEN_CLASSIFY.EOL.I
  local start, stop = self:MakeSelection(selection)

  if (start[1] == stop[1]) then
    return string.sub(self.Rows[start[1]], start[2], stop[2] - 1)
  else
    local iS, iE = (start[1] + 1), (stop[1] - 1)
    local text = string.sub(self.Rows[start[1]], start[2])
    local extra = string.sub(self.Rows[stop[1]], 1, stop[2] - 1)

    if iS <= iE then
      local chunk = table.concat(self.Rows, g_NL, iS, iE)
      text = text .. g_NL .. chunk
    end

    return text .. g_NL .. extra
  end
end

function PANEL:SetArea(selection, text, isundo, isredo, before, after)
  local g_NP = TOKEN_CLASSIFY.EOL.E
  local start, stop = self:MakeSelection(selection)
  local buffer = self:GetArea(selection)
  local sline, schar = start[1], start[2]
  local eline, echar =  stop[1],  stop[2]

  if (sline ~= eline or schar ~= echar) then
    -- Clear selection
    self.Rows[sline] = string.sub(self.Rows[sline], 1, schar - 1)..
                       string.sub(self.Rows[eline], echar)
    self.PaintRows[sline] = false

    for i = sline + 1, eline do
      table.remove(self.Rows, sline + 1)
      table.remove(self.PaintRows, sline + 1)
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

  local tRows = string.Explode(g_NP, text, true) -- Insert text
  local nRows = #tRows -- Count the marked lines once

  local remainder = string.sub(self.Rows[sline], schar)
  self.Rows[sline] = string.sub(self.Rows[sline], 1, schar - 1) .. tRows[1]
  self.PaintRows[sline] = false

  for i = 2, nRows do
    table.insert(self.Rows, sline + i - 1, tRows[i])
    table.insert(self.PaintRows, sline + i - 1, false)
    self:RefreshView() -- TODO: fix for cache errors
  end

  local stop = {sline + nRows - 1, string.len(self.Rows[sline + nRows - 1]) + 1}

  self.Rows[eline] = self.Rows[eline] .. remainder
  self.PaintRows[eline] = false

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

function PANEL:GetSystemEOL()
  local tS = TOKEN_CLASSIFY.SEL
  if(system.IsOSX()) then return tS.M end
  if(system.IsLinux()) then return tS.L end
  if(system.IsWindows()) then return tS.W end
  return tS.L -- Defaults to Linux
end

function PANEL:ToSelection()
  local g_NL = TOKEN_CLASSIFY.EOL.I
  local sT = self:GetSystemEOL()
  self.Clips = self:GetSelection()
  SetClipboardText(string.Replace(self.Clips, g_NL, sT))
end

function PANEL:CustomOnLoseFocus()
  if (self.TabFocus) then
    self:RequestFocus()
    self.TabFocus = nil
  end
end

function PANEL:CustomOnTextChanged()
  local ctrlv = false
  local g_NL = TOKEN_CLASSIFY.EOL.I
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
    else -- ctrl+[shift+]key with key ~= V
      return
    end
  end

  if (text == "") then
    return
  end
  if (not ctrlv) then
    if (text == g_NL) then
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
  local sign = ((delta > 0 and 1) or (delta < 0 and -1) or 0)
  local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)

  if(control and sign ~= 0) then
    local iF = self:GetFontInfo() + sign
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
  local g_NL = TOKEN_CLASSIFY.EOL.I; self.Blink = RealTime()
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
      self:SetSelection(g_NL .. tabs)
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
  local g_NL = TOKEN_CLASSIFY.EOL.I
  local tScr = self:CopyPosition(self.Scroll)
  local tStr, tCar = self:MakeSelection(self:Selection())

  tStr[2] = 1
  if (tCar[2] ~= 1) then
    tCar[1] = tCar[1] + 1
    tCar[2] = 1
  end

  self.Caret = self:CopyPosition(tCar)
  self.Start = self:CopyPosition(tStr)

  if (self.Caret[2] == 1) then
    self.Caret = self:MovePosition(self.Caret, -1)
  end

  if (shift) then
    local tmp = self:GetSelection():gsub(g_NL.." ? ? ? ?", g_NL)
    self:SetSelection(self:UnIndent(tmp))
  else
    self:SetSelection("    " .. self:GetSelection():gsub(g_NL, g_NL.."    "))
  end

  self.Caret = self:CopyPosition(tCar)
  self.Start = self:CopyPosition(tStr)
  self.Scroll = self:CopyPosition(tScr)
  self:ScrollCaret()
end

function PANEL:OnTextChanged()
end

function PANEL:OnShortcut()
end

vgui.Register("DLuapadEditor", PANEL, "DPanel")
