-- Andreas "Syranide" Svensson's editor for Wire Expression 2
-- Edited by DarKSunrise aka Assassini to work with Luapad and with Lua-syntax

if (SERVER) then
  return
end

--[[
 * Symbols drawn for invisible characters when the paragraph is shown
 * The localization file can override every symbol. When a phrase is missing
 * `language.GetPhrase` returns the key itself, so a built-in default is used
]]
local SHOW_PARAGRAPH = {
  ENDS = language.GetPhrase("luapad.show_paragraph.ends"),
  SPAS = language.GetPhrase("luapad.show_paragraph.spas"),
  TABS = language.GetPhrase("luapad.show_paragraph.tabs"),
  NBSP = language.GetPhrase("luapad.show_paragraph.nbsp"),
  EOLS = language.GetPhrase("luapad.show_paragraph.eols"),
  EOTC = language.GetPhrase("luapad.show_paragraph.eotc"),
  WRAP = language.GetPhrase("luapad.show_paragraph.wrap"),
  PRLO = language.GetPhrase("luapad.show_paragraph.prlo")
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
  KEY = {
    ["if"]       = true, ["elseif"]   = true, ["else"]     = true,
    ["then"]     = true, ["end"]      = true, ["function"] = true,
    ["do"]       = true, ["while"]    = true, ["break"]    = true,
    ["for"]      = true, ["in"]       = true, ["local"]    = true,
    ["true"]     = true, ["false"]    = true, ["nil"]      = true,
    ["NULL"]     = true, ["and"]      = true, ["not"]      = true,
    ["or"]       = true, ["return"]   = true, ["continue"] = true,
    ["goto"]     = true, ["repeat"]   = true, ["until"]    = true
  },
  OPS = {
    ["+"] = true, ["-"] = true, ["*"] = true,
    ["/"] = true, ["%"] = true, ["^"] = true,
    [">"] = true, ["<"] = true, ["#"] = true,
    ["^"] = true, ["!"] = true,
    -- Operators with two characters
    ["=="] = true, ["~="] = true,
    [">="] = true, ["<="] = true,
    [".."] = true, ["||"] = true,
    ["&&"] = true, ["!="] = true,
    -- Operators with three characters
    ["..."] = true -- Varargs
  },
  SKP = {E = "%s+", A = ".*$", W = "^%w$"}, -- Skip characters
  OSE = {W = "\r\n", L = "\n", M = "\r"}, -- System EOLs
  EOL = {E = "[\r\n]+", I = "\n", N = "\r\n?"}, -- General pattern for splitting
  URL = "https?://[^%s<>\"']+%.[^%s<>\"']+", -- URL pattern matching
  COM = { -- Comments configuration
    S = {["-"] = "%-[%-]+", ["/"] = "/[/]+"}, -- Comments single
    M = { -- Start character for every multi-line type
      {S = "%-%-%[=*%[", E = "%]=*%]", D = 2},
      {S =   "//%[=*%[", E = "%]=*%]", D = 2}
    } -- Finishes the multi-line comment definitions
  }, -- Finishes the total comment definitions
  NUM = {"0[xX]%x+", "%d*%.?%d+"}, -- A number literals matching numbers
  STR = { -- String patterns literal matching
    B = "%s[^%s]*%s", C = "[^%s]*%s", E = "[^%s]*$", L = "%s[^%s]*$",
    M = {{S = "%[=*%[", E = "%]=*%]"}},
    S = { -- Dedicated configuration for every character opening a string
      ["\""] = {R = "\\\"", T = "code.string" }, -- Double quote
      ["\'"] = {R = "\\\'", T = "code.string2"}  -- Single quote
    } -- Includes whenever escape sequence is present
  }, -- Contains the string configurations
  FNL = "[a-zA-Z_][a-zA-Z0-9_]*", -- Identifier token
  GTK = {["f"] = true, ["e"] = true, ["m"] = true}, -- Syntax
  TTK = {["function"] = true, ["table"] = true} -- Libraries
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
  self.Book = {ID = 0, Row = {}} -- Bookmarked
  self.Undo = {} -- Undo action stack
  self.Redo = {} -- Redo action stack
  self.Token = {} -- Multi-line comment token info
  self.Line = "" -- Reference to current line
  self.Str = "" -- Already processed character set
  self.Pos = 0 -- Current processed line position
  self.Char = "" -- The current read character
  self.Buff = {"", ""} -- General concatenation
  self.Span = {F = "", S = 0, E = 0} -- Span match
  self.Clips = nil -- Holds the current clipboard
  self.Blink = RealTime()
  self.WrapText = false -- Word wrap is disabled by default
  self.WrapDirty = true -- Visual lines layout must be rebuilt
  self.WrapCache = {} -- Segments cache indexed by the row text
  self.WrapFirst = {} -- First visual line of every row
  self.WrapRow = {} -- Row of every visual line
  self.WrapSeg = {} -- Segment index of every visual line

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

  function self.TextEntry:OnKeyCodePressed(code)
    self:GetParent():CustomOnKeyCodePressed(code)
  end

  self.LastClick = 0
  self:SetTabSize(4)
  self:SetTabInsert(false)
  self:SetGutterWidth(4)
  self:SetShowParagraph(false)
  self:SetThemeDefault()
end

--[[
 * Helper method for rows count
]]
function PANEL:GetRownum()
  return #self.Rows
end

--[[
 * Returns the size of one font cell symbol
]]
function PANEL:GetFontSize()
  return self.FontWidth, self.FontHeight
end

--[[
 * Whether the Tab key inserts a real tab character
 * instead of spaces up to the next tab stop
]]
function PANEL:GetTabInsert()
  return tobool(self.UseTabs)
end

function PANEL:SetTabInsert(bool)
  self.UseTabs = tobool(bool)
end

--[[
 * Rebuilds the row lookup from the bookmark array
 * The array is the only source of truth, the lookup is a cache for painting
]]
function PANEL:RefreshBookMarks()
  local tB = self:GetTable().Book
  if(not istable(tB)) then return end
  tB.Row = {}
  for iD = 1, #tB do
    tB.Row[tostring(tB[iD][1][1])] = true
  end
end

--[[
 * Toggles a bookmark on a row. The array is kept sorted by row
 * iR > Row to toggle. Defaults to the row of the selection start
]]
function PANEL:ToggleBookMark(iR)
  local tT = self:GetTable()
  local tR, tB = tT.Rows, tT.Book
  if(not istable(tR)) then return end
  if(not istable(tB)) then return end
  local iR = math.floor(tonumber(iR) or 0)
  local bR = (iR >= 1 and iR <= #tR) -- A valid row was passed
  local iB = (bR and iR or tT.Start[1]) -- Row of the bookmark
  local iF = 0 -- Bookmarks above the row
  for iD = 1, #tB do
    local vS = tB[iD][1][1]
    if(vS == iB) then -- Already bookmarked so remove it
      table.remove(tB, iD)
      if(iD < tB.ID) then tB.ID = tB.ID - 1 end
      tB.ID = math.min(tB.ID, #tB)
      self:RefreshBookMarks()
      return
    elseif(vS < iB) then
      iF = iF + 1
    end
  end
  local tS, tC -- A passed row gets its own position, not the current caret
  if(bR) then tS, tC = {iB, 1}, {iB, 1}
  else tS, tC = self:CopyPosition(tT.Start), self:CopyPosition(tT.Caret) end
  table.insert(tB, iF + 1, {tS, tC})
  tB.ID = iF + 1
  self:RefreshBookMarks()
end

--[[
 * Jumps to the next or previous bookmark relative to the caret row
 * bP > Go to the previous one. Wraps around at both ends
]]
function PANEL:SwitchBookMark(bP)
  local tT = self:GetTable()
  local tB, tR = tT.Book, tT.Rows
  if(not istable(tB)) then return end
  local nB = #tB
  if(nB == 0) then tB.ID = 0; return end
  local iC, iN = tT.Caret[1], nil
  if(bP) then
    for iD = nB, 1, -1 do
      if(tB[iD][1][1] < iC) then iN = iD; break end
    end
    iN = iN or nB -- Wrap to the last
  else
    for iD = 1, nB do
      if(tB[iD][1][1] > iC) then iN = iD; break end
    end
    iN = iN or 1 -- Wrap to the first
  end
  local function Place(tD, tV) -- Clamp in case the text changed
    local iRow = math.min(math.max(tV[1], 1), #tR)
    tD[1], tD[2] = iRow, math.min(math.max(tV[2], 1), string.len(tR[iRow]) + 1)
  end
  tB.ID = iN
  Place(tT.Start, tB[iN][1])
  Place(tT.Caret, tB[iN][2])
  self:ScrollCaret()
end

--[[
 * Removes bookmarks on deleted rows iS..iE and moves the ones below up
]]
function PANEL:DropBookMarkRows(iS, iE)
  local tB = self:GetTable().Book
  if(not istable(tB)) then return end
  local nD = iE - iS + 1
  local function Move(iR) -- Stored caret rows can sit inside the range too
    if(iR > iE) then return iR - nD end
    return math.min(iR, iS - 1)
  end
  for iD = #tB, 1, -1 do
    local tP = tB[iD]
    local iR = tP[1][1]
    if(iR >= iS and iR <= iE) then
      table.remove(tB, iD)
      if(iD < tB.ID) then tB.ID = tB.ID - 1 end
    elseif(iR > iE) then
      tP[1][1], tP[2][1] = Move(tP[1][1]), Move(tP[2][1])
    end
  end
  tB.ID = math.min(tB.ID, #tB)
  self:RefreshBookMarks()
end

--[[
 * Moves the bookmarks from row iS downwards after nC rows were inserted
]]
function PANEL:PushBookMarkRows(iS, nC)
  local tB = self:GetTable().Book
  if(not istable(tB)) then return end
  for iD = 1, #tB do
    local tP = tB[iD]
    if(tP[1][1] >= iS) then tP[1][1] = tP[1][1] + nC end
    if(tP[2][1] >= iS) then tP[2][1] = tP[2][1] + nC end
  end
  self:RefreshBookMarks()
end

function PANEL:IsBookMarkRow(iR)
  local tB = self:GetTable().Book
  if(not istable(tB) or not istable(tB.Row)) then return false end
  return (tB.Row[tostring(iR)] == true)
end

--[[
 * Trim trailing spaces
 * Registered as a single undo step covering only the changed rows
 * bF > Trim the leading spaces instead
]]
function PANEL:TrimSpaces(bF)
  local tR = self:GetTable().Rows
  if(not istable(tR)) then return end
  local sP = (bF and "^%s+" or "%s+$")
  local nR = self:GetRownum()
  local tN, iF, iL = {}, nil, nil -- Trimmed rows, first and last changed row
  for iR = 1, nR do
    local sO = tR[iR]
    local sN = string.gsub(sO, sP, "") -- Keep only the first return value
    tN[iR] = sN
    if(sN ~= sO) then iF = (iF or iR); iL = iR end
  end
  if(not iF) then return end -- Nothing changed so keep the undo stack clean

  -- Carets after the trim. Same row, column shifted by the removed leading spaces
  local function trimAdust(tP)
    local sO, sN, nC = tR[tP[1]], tN[tP[1]], tP[2]
    if(bF) then nC = math.max(nC - (#sO - #sN), 1) end
    return {tP[1], math.min(nC, #sN + 1)}
  end

  local tC = self:CopyPosition(self.Caret)
  local tS = self:CopyPosition(self.Start)
  local tCa, tSa = trimAdust(tC), trimAdust(tS)

  -- Replace only the changed rows. Same row count so the rows do not shift
  local tA = {{iF, 1}, {iL, string.len(tR[iL]) + 1}}
  self:SetArea(tA, table.concat(tN, "\n", iF, iL))

  self.Caret, self.Start = tCa, tSa
  -- SetArea stored {range, old text, caret before, caret after}
  -- Point them at the real carets, otherwise undo jumps to the first changed row
  local tU = self.Undo[#self.Undo]
  if(tU) then tU[3], tU[4] = tC, self:CopyPosition(tCa) end
end

--[[
 * Updates the visual tab size being drawn
]]
function PANEL:GetTabSize()
  return math.max(math.floor(tonumber(self.TabSize) or 4), 1)
end

function PANEL:SetTabSize(size)
  local nSz = math.max(math.floor(tonumber(size) or 4), 1)
  if(nSz == self.TabSize) then return end
  self.TabSize = nSz -- Store the new size
  self:RefreshView() -- Tab widths and wrap points change
end

--[[
 * Whether the paragraph should be shown
 * This draws symbols for invisible characters
]]
function PANEL:GetShowParagraph()
  return tobool(self.ShowParag)
end

function PANEL:SetShowParagraph(bool)
  self.ShowParag = tobool(bool)
  -- Symbols are drawn on top of the cached rows. No refresh is needed
end

--[[
 * Whether long rows are wrapped to fit the panel width
 * When enabled the vertical scroll works with visual lines
 * and the horizontal scroll is not used
]]
function PANEL:GetWordWrap()
  return tobool(self.WrapText)
end

function PANEL:SetWordWrap(bool)
  local bW = tobool(bool)
  if(bW == self:GetWordWrap()) then return end
  -- Keep the same row on the top of the view
  local iT = math.max(math.floor(tonumber(self.Scroll[1]) or 1), 1)
  if(self:GetWordWrap()) then -- Visual line to row
    self:UpdateWrap(); iT = (self.WrapRow[iT] or 1)
  end
  self.WrapText = bW
  self.WrapDirty = true
  self.Scroll[2] = 1
  if(bW) then -- Row to visual line
    self:UpdateWrap()
    iT = (self.WrapFirst[math.min(iT, self:GetRownum())] or 1)
  else
    self.ScrollBar:SetUp(self.Size[1], self:GetRownum() - 1)
  end
  self.Scroll[1] = iT
  self.ScrollBar:SetScroll(iT - 1)
end

--[[
 * How many screen cells fit in one visual line when wrapping
]]
function PANEL:GetWrapWidth()
  return math.max(math.floor(tonumber(self.Size[2]) or 0), 8)
end

--[[
 * Splits one row into visual line segments
 * Breaks after the last space or tab that fits, otherwise
 * breaks at the last character that fits (never inside UTF-8)
 * Visual offsets keep the tab stops of the whole row
 * Returns: S > Byte column where every segment starts
 *          V > Visual offset (0-based) where every segment starts
 *          E > Visual width of the whole row
]]
function PANEL:BuildWrap(line, wide)
  local tS, tV, tA = {1}, {0}, {}
  local vis, seg, svis, brk = 0, 1, 0, nil
  local pos, len = 1, string.len(line)
  while (pos <= len) do
    local byte = string.byte(line, pos)
    local cell = self:GetCellWidth(byte, vis)
    tA[pos] = vis -- Visual offset where this byte starts
    if (cell > 0 and pos > seg and (vis + cell - svis) > wide) then
      local cut = ((brk and brk > seg and brk <= pos) and brk or pos)
      seg, svis, brk = cut, tA[cut], nil
      tS[#tS + 1], tV[#tV + 1] = seg, svis
    else -- The character fits in the segment
      vis = vis + cell
      if (byte == 32 or byte == 9) then brk = pos + 1 end
      pos = pos + 1
    end
  end
  return {S = tS, V = tV, E = vis}
end

--[[
 * Rebuilds the visual lines layout when it is outdated
 * Segments are cached by the row text, so editing a row
 * or inserting rows only splits the rows that changed
 * Returns true when the layout has been rebuilt
]]
function PANEL:UpdateWrap()
  if(not self:GetWordWrap()) then return false end
  if(not self.WrapDirty) then return false end
  local nW, nT = self:GetWrapWidth(), self:GetTabSize()
  local tO = self.WrapCache -- Previous cache
  if(not tO or self.WrapSize ~= nW or self.WrapTabs ~= nT) then tO = {} end
  local tN, tF, tR, tG = {}, {}, {}, {}
  for iR = 1, self:GetRownum() do
    local sL = self.Rows[iR]
    local tC = (tN[sL] or tO[sL] or self:BuildWrap(sL, nW))
    tN[sL], tF[iR] = tC, (#tR + 1)
    for iK = 1, #tC.S do
      tR[#tR + 1], tG[#tG + 1] = iR, iK
    end
  end
  self.WrapCache, self.WrapSize, self.WrapTabs = tN, nW, nT
  self.WrapFirst, self.WrapRow, self.WrapSeg = tF, tR, tG
  self.WrapDirty = false
  self.ScrollBar:SetUp(self.Size[1], #tR - 1)
  return true
end

--[[
 * Returns the wrap segments of a row
]]
function PANEL:GetWrapRow(row)
  self:UpdateWrap()
  local sL = (self.Rows[row] or "")
  local tC = self.WrapCache[sL]
  if(not tC) then -- Should not happen, but stay safe
    tC = self:BuildWrap(sL, self:GetWrapWidth())
    self.WrapCache[sL] = tC
  end
  return tC
end

--[[
 * Returns the segment index that contains a column
 * A column on a segment start belongs to that segment
]]
function PANEL:GetWrapSegment(wrap, col)
  local tS, iK = wrap.S, 1
  for iD = 2, #tS do
    if (tS[iD] <= col) then iK = iD else break end
  end
  return iK
end

--[[
 * Amount of lines the vertical scroll works with
 * These are visual lines when wrapping, otherwise rows
]]
function PANEL:GetLineCount()
  if(not self:GetWordWrap()) then return self:GetRownum() end
  self:UpdateWrap()
  return math.max(#self.WrapRow, 1)
end

--[[
 * Converts a caret into a line and visual column (1-based)
 * Without wrapping these are the row and its visual column
 * With wrapping these are the visual line and the column inside it
]]
function PANEL:CaretToLine(caret)
  local iR, iC = caret[1], caret[2]
  local vC = self:ColumnToVisual(iR, iC)
  if(not self:GetWordWrap()) then return iR, vC end
  local tW = self:GetWrapRow(iR)
  local iK = self:GetWrapSegment(tW, iC)
  return (self.WrapFirst[iR] + iK - 1), (vC - tW.V[iK])
end

--[[
 * Converts a line and visual column (1-based) into a caret
 * Reverses `CaretToLine` and snaps on the closest character
]]
function PANEL:LineToCaret(line, vcol)
  local nL = self:GetLineCount()
  local iL = math.Clamp(math.floor(tonumber(line) or 1), 1, nL)
  if(not self:GetWordWrap()) then
    return {iL, self:VisualToColumn(iL, vcol)}
  end
  local iR, iK = self.WrapRow[iL], self.WrapSeg[iL]
  local tW = self:GetWrapRow(iR)
  local iC = self:VisualToColumn(iR, tW.V[iK] + math.max(vcol, 1))
  iC = math.max(iC, tW.S[iK]) -- Stay inside this segment
  if(iK < #tW.S) then -- The next segment start belongs to the next line
    iC = self:SnapColumn(iR, math.min(iC, tW.S[iK + 1] - 1), -1)
  end
  return {iR, iC}
end

--[[
 * Moves the caret with the given amount of lines
 * keeping its visual column as close as possible
]]
function PANEL:MoveCaretLines(delta)
  local iL, vC = self:CaretToLine(self.Caret)
  local tG = self.WrapGoal -- Remembered column of the previous move
  if (tG and tG[2] == self.Caret[1] and tG[3] == self.Caret[2]) then vC = tG[1] end
  self.Caret = self:LineToCaret(iL + delta, vC)
  self.WrapGoal = {vC, self.Caret[1], self.Caret[2]}
end

--[[
 * Gutter is the place with the line numbers and breakpoints
]]
function PANEL:GetGutterWidth()
  return math.max(tonumber(self.GutterWidth) or 4, 4)
end

function PANEL:SetGutterWidth(width)
  self.GutterWidth = math.max((tonumber(width) or 4), 4)
end

--[[
 * Returns how many screen cells a byte occupies when it
 * starts at visual offset `vis` (0-based). Tabs jump to the next stop.
]]
function PANEL:GetCellWidth(byte, vis)
  if (byte == 9) then -- Tabulation
    local tabw = self:GetTabSize()
    return tabw - vis % tabw
  end
  if (byte and byte >= 128 and byte <= 191) then
    return 0 -- UTF-8 continuation byte belongs to the previous character
  end
  return 1
end

--[[
 * Returns true when the byte at `col` is in the middle of a UTF-8 character
]]
function PANEL:IsInsideChar(line, col)
  local byte = string.byte(line, col)
  return (byte ~= nil and byte >= 128 and byte <= 191)
end

--[[
 * Moves a caret column off UTF-8 continuation bytes
 * dir < 0 snaps to the start of the character, otherwise past its end
]]
function PANEL:SnapColumn(row, col, dir)
  local line = self.Rows[row] or ""
  local step = ((dir and dir < 0) and -1 or 1)
  while (col > 1 and col <= string.len(line) and self:IsInsideChar(line, col)) do
    col = col + step
  end
  return col
end

--[[
 * Number of screen cells of a string without tabs
]]
function PANEL:GetCellCount(text)
  local _, cnt = string.gsub(text, "[^\128-\191]", "")
  return cnt
end

--[[
 * Byte index where the character after `cells` screen cells starts
 * in a string without tabs
]]
function PANEL:GetCellByte(text, cells)
  local col, len = 1, string.len(text)
  while (cells > 0 and col <= len) do
    col = col + 1
    while (col <= len and self:IsInsideChar(text, col)) do col = col + 1 end
    cells = cells - 1
  end
  return col
end

--[[
 * Converts a caret column (byte index, 1-based) on a row
 * into a visual column (screen cell index, 1-based)
]]
function PANEL:ColumnToVisual(row, col)
  local line = self.Rows[row] or ""
  local last = math.min(col - 1, string.len(line))
  local vis = 0
  for i = 1, last do
    vis = vis + self:GetCellWidth(string.byte(line, i), vis)
  end
  return (vis + col - last)
end

--[[
 * Converts a visual column (screen cell index, 1-based) on a row
 * into the nearest caret column (byte index, 1-based)
]]
function PANEL:VisualToColumn(row, vcol)
  local line = self.Rows[row] or ""
  local target, vis = (vcol - 1), 0
  for i = 1, string.len(line) do
    local w = self:GetCellWidth(string.byte(line, i), vis)
    if (target < vis + w) then
      if ((target - vis) <= (w / 2)) then return i end
      return self:SnapColumn(row, i + 1, 1)
    end
    vis = vis + w
  end
  return string.len(line) + 1
end

function PANEL:RefreshView()
  local tR = self:GetTable().PaintRows -- Clear row cache
  if(istable(tR)) then table.Empty(tR) else self.PaintRows = {} end
  self.WrapDirty = true -- Visual lines must be rebuilt
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
  local tH = self:GetTable().Highlight
  if(not istable(tH)) then return nil end
  if(not IsValid(pD)) then return nil end
  local tD = pD:GetTable().Highlight
  if(not istable(tD)) then return nil end
  for sT, vT in pairs(tH) do
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
  local vC = (bD and color_white or color_black)
  for sR, sK in pairs(tR) do
    local iC = 10 -- Make maximum 10 jumps
    local sC = sR -- Reuse start index
    local tC = tH[sC] -- Start data
    while(iC > 0 and sC and not tC) do
      sC = tR[sC] -- Navigate to the next key
      tC = tH[sC] -- Navigate to the next data
      iC = iC - 1 -- Increment the step count
    end -- Find a color with 10 jumps max
    if(tC and istable(tC) and IsColor(tC[1])) then
      tH[sR] = tC -- Color has been navigated
    else -- Otherwise -- Entry is not validated
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
  local mG = self:GetGutterWidth()
  local iX, iY = self:CursorPos()

  iX = iX - (self.FontWidth * mG + 6)
  iX = ((iX < 0) and 0 or iX)
  iY = ((iY < 0) and 0 or iY)

  local iR, iL = self:GetRownum(), 0
  local iH = math.floor(iY / self.FontHeight)
  local iW = math.floor(iX / self.FontWidth + 0.5)

  if (self:GetWordWrap()) then -- Visual line and column inside it
    return self:LineToCaret(iH + self.Scroll[1], iW + 1)
  end

  iH = iH + self.Scroll[1]
  iW = iW + self.Scroll[2] -- Visual column
  iH = ((iH > iR) and iR or iH)
  iW = self:VisualToColumn(iH, iW) -- Caret column

  return {iH, iW}
end

function PANEL:OnMousePressed(code)
  local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)

  if (code == MOUSE_LEFT) then
    local cucar = self:CursorToCaret()
    if ((CurTime() - self.LastClick) < 1 and
      cucar[1] == self.Caret[1] and
      cucar[2] == self.Caret[2] and self.CanMark
    ) then
      self.Start = self:GetWordStart(cucar)
      self.Caret = self:GetWordEnd(cucar)
      self.CanMark = false
      return
    end

    self.CanMark = true
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
    -- Undo previous changes
    if (self:CanUndo()) then
      pMenu:AddOption("Undo", function()
        self:DoUndo()
      end):SetImage(luapad.ToIcon("arrow_undo"))
    end
    -- Redo previous changes
    if (self:CanRedo()) then
      pMenu:AddOption("Redo", function()
        self:DoRedo()
      end):SetImage(luapad.ToIcon("arrow_redo"))
    end
    -- Draw a separator
    if (self:CanUndo() or self:CanRedo()) then
      pMenu:AddSpacer()
    end
    -- Cut mark contents
    if (self:HasSelection()) then
      pMenu:AddOption("Cut", function()
        if (self:HasSelection()) then
          self:ToSelection()
          self:SetSelection()
        end
      end):SetImage(luapad.ToIcon("cut"))
      -- Copy mark contents
      pMenu:AddOption("Copy", function()
        if (self:HasSelection()) then
          self:ToSelection()
        end
      end):SetImage(luapad.ToIcon("page_copy"))
    end
    -- Paste mark contents
    pMenu:AddOption("Paste", function()
      local bC = luapad.IsHere(self.Clips)
      self:SetSelection(bC and self.Clips or nil)
    end):SetImage(luapad.ToIcon("page_paste"))
    -- Delete mark contents
    if (self:HasSelection()) then
      pMenu:AddOption("Delete", function()
        self:SetSelection()
      end):SetImage(luapad.ToIcon("page_delete"))
    end
    -- Search for a string contents
    if (self:HasSelection()) then
      pMenu:AddOption("Search", function()
        luapad.OpenSearch(self:GetSelection())
      end):SetImage(luapad.ToIcon("find"))
    end
    -- Mark all contents
    pMenu:AddSpacer()
    pMenu:AddOption("Select all", function()
      self:SelectAll()
    end):SetImage(luapad.ToIcon("pencil"))
    -- Try to follow the selection as link
    if (self:HasSelection()) then
      local sS = self:GetSelection()
      local sU = sS:match(TOKEN_CLASSIFY.URL)
      if(sU) then
        pMenu:AddSpacer()
        pMenu:AddOption("Follow", function()
          gui.OpenURL(sU)
        end):SetImage(luapad.ToIcon("world_link"))
      end
    end
    -- Force menu on the foreground
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
    if (not self.CanMark) then
      return
    end
    self.Caret = self:CursorToCaret()
  end
end

--[[
 * Splits text into rows keeping empty lines
 * Any of "\r\n", "\r" or "\n" counts as one line break
]]
function PANEL:SplitLines(text)
  local tEOL = TOKEN_CLASSIFY.EOL
  local sT = string.gsub(tostring(text or ""), tEOL.N, tEOL.I)
  return string.Explode(tEOL.I, sT, false)
end

function PANEL:SetText(text)
  self.Rows = self:SplitLines(text)

  local last = self:SetEmptyRow()

  self.Caret = {1, 1}
  self.Start = {1, 1}
  self.Scroll = {1, 1}
  self.Undo = {}
  self.Redo = {}
  self.Book = {ID = 0, Row = {}}

  self:RefreshView()
  self.ScrollBar:SetUp(self.Size[1], self:GetLineCount() - 1)
  self.ScrollBar:SetScroll(0)
end

function PANEL:GetText()
  local g_NL = TOKEN_CLASSIFY.EOL.I
  return string.Implode(g_NL, self.Rows)
end

function PANEL:SetRowBlock(vM, vT, vC)
  local tT = self.Token
  if(vM ~= nil) then tT.M = vM end
  if(vT ~= nil) then tT.T = vT end
  if(vC ~= nil) then tT.C = vC end
end

function PANEL:GetRowBlock()
  local tT = self.Token
  return tT.M, tT.T, tT.C
end

function PANEL:InitColorRowID(row)
  if(not row) then return end
  self.Line = self.Rows[row]

  self.Pos = 0
  self.Str = ""
  self.Char = ""
  self.Buff[1] = ""
  self.Buff[2] = ""

  if(row == 1) then
    self:SetRowBlock(false, false)
  end
end

function PANEL:GetConcat(sA, sB, sC)
  local tB = self.Buff
  tB[1] = tostring(sA or "")
  tB[2] = tostring(sB or "")
  return table.concat(tB, sC)
end

function PANEL:ConsumeChar()
  local cP = self.Char
  if(not cP) then return end
  local sS = self.Str
  local sL = self.Line
  local iL = string.len(sL)
  local iP  = (self.Pos + 1)

  self.Pos = iP
  self.Str = self:GetConcat(sS, cP)

  if (iP <= iL) then
    self.Char = string.sub(sL, iP, iP)
  else
    self.Char = nil
  end

  return self.Char, cP
end

--[[
 * Captures a pattern as a span
 * sP > Pattern that must be checked
 * bN > Pass true to search as plain text
 * bF > Pass true to match only from the next position
 * tC > Multi-line configuration when provided
]]
function PANEL:CaptureSpan(sP, bN, bF, tC)
  local sP = tostring(sP or "")
  if(sP == "") then return false end
  local cP = self.Pos
  local sL = self.Line
  local tS = self.Span
  local iL = string.len(sL)
  tS.F, tS.S, tS.E, tS.C = "", 0, 0, nil
  if(cP > iL) then return false end
  local iS, iE = string.find(sL, sP, cP, bN)
  if(not (iS and iE)) then return false end
  if(bF and iS ~= cP) then return false end
  tS.F = string.sub(sL, iS, iE)
  tS.S, tS.E, tS.C = iS, iE, tC
  return true
end

--[[
 * Move to the end of the last match
 * iP > The cursor advances to this position
 *      When empty defaults to the last span
]]
function PANEL:AdvanceSpan(iP)
  local cP = self.Pos
  local sS = self.Str
  local sL = self.Line
  local tS = self.Span
  local iL = string.len(sL)
  local iP = (tonumber(iP) or tS.E)
  if(not iP or iP <= cP) then iP = cP end
  if(cP > iL) then self.Char = nil; return end
  self.Str = self:GetConcat(sS, string.sub(sL, cP, iP))
  iP = iP + 1; self.Pos = iP
  if(iP > iL) then self.Char = nil
  else self.Char = string.sub(sL, iP, iP) end
end

--[[
 * Updates the current row with a token
 * tRow > The row table to be updated
 * sT   > Current token from matching loop
 * bM   > The cell is a multi-line entry
]]
function PANEL:UpdateRowSpan(tRow, sT, bM)
  if(not istable(tRow)) then return end
  local tH = self:GetTable().Highlight
  if(not istable(tH)) then return end
  local oH, nH, sS = tH[sT], #tRow, self.Str
  -- Write the cell in the highlight array
  if(nH == 0) then -- No cells for this row
    table.insert(tRow, {sS, oH, bM})
    return -- Insert this cell and return
  end
  -- Update current cell with same color
  local tC = tRow[nH] -- Current sell
  local cS, cH = unpack(tC) -- Unpack
  if(oH == cH) then -- Same as previous
    tC[1] = self:GetConcat(cS, sS)
  else -- Different highlight than previous
    table.insert(tRow, {sS, oH, bM})
  end
end

--[[
 * Setups the panel to draw the next row
 * tRow > The row table to be updated
 * iD   > ID used to register the draw cells
]]
function PANEL:FinalizeRow(tRow, iD)
  -- Comment was spawned to the end of line
  local mM, mT = self:GetRowBlock()
  if(not mM) then
    self:SetRowBlock(false, false)
  end
  -- Cache the highlight view
  self.PaintRows[iD] = tRow
  return tRow
end

--[[
 * Consume text from the contents
 * sP > Pattern that must be checked
 * bN > Pass true to search as plain text
]]
function PANEL:ConsumeSpan(sP, bN)
  local bC = self:CaptureSpan(sP, bN, true)
  if(bC) then self:AdvanceSpan() end
  return bC
end

--[[
 * Consume text from the contents via pattern array
 * tP > Pattern array that must be checked
 * bN > Pass true to search as plain text
]]
function PANEL:ConsumeArray(tP, bN)
  if(not istable(tP)) then return false end
  for iP = 1, #tP do -- Array of patterns
    local bC = self:CaptureSpan(tP[iP], bN, true)
    if(bC) then self:AdvanceSpan(); return bC end
  end; return false -- Not found
end

--[[
 * Consume text from the contents via pattern
 * that is enclosed with keys start (S) and end (E)
 * tP > Pattern struct that must be checked
 * bN > Pass true to search as plain text
]]
function PANEL:ConsumeBetween(tP, bN)
  if(not istable(tP)) then return false end
  for iP = 1, #tP do -- Array of patterns
    local tC = tP[iP] -- Multi-line config
    local bC = self:CaptureSpan(tC.S, bN, true, tC)
    if(bC) then self:AdvanceSpan(); return bC end
  end; return false -- Not found
end

--[[
 * Returns the current character or scans ahead
 * iC > How many characters ahead should scan
 * bS > On success return the entire span
]]
function PANEL:GetChar(iC, bS)
  if(not iC) then
    return self.Char, self.Pos
  else
    local cP = self.Pos
    local sL = self.Line
    local iL = string.len(sL)
    local iC = math.max(cP + (tonumber(iC) or 0), cP)
    if(iC < 1 or iC > iL) then return nil end
    if(cP < 1 or cP > iL) then return nil end
    if(bS) then
      return string.sub(sL, cP, iC), iC
    else
      return string.sub(sL, iC, iC), iC
    end
  end
end

function PANEL:GetSpan(bD)
  if(bD) then
    return self.Span
  else
    local tS = self.Span
    return tS.F, tS.S, tS.E, tS.C
  end
end

function PANEL:SyntaxColorRowID(row)
  local tRow = self.PaintRows[row]
  if(tRow) then return tRow end

  local tLib, tRow = {}, {}
  local g_Skip = TOKEN_CLASSIFY.SKP
  local g_Coms = TOKEN_CLASSIFY.COM
  local g_Glob = TOKEN_CLASSIFY.GTK
  local g_Type = TOKEN_CLASSIFY.TTK
  local g_Patn = TOKEN_CLASSIFY.NUM
  local g_Keyw = TOKEN_CLASSIFY.KEY
  local g_Lifn = TOKEN_CLASSIFY.FNL
  local g_Strm = TOKEN_CLASSIFY.STR
  local g_Opts = TOKEN_CLASSIFY.OPS
  local g_Wurl = TOKEN_CLASSIFY.URL

  self:InitColorRowID(row)

  local char, last = self:ConsumeChar()

  while self:GetChar() do
    local token = ""
    self.Str = ""

    self:ConsumeSpan(g_Skip.E)
    char = self:GetChar()

    if(not char) then break end

    local multy, mtoken, conf = self:GetRowBlock()

    if(mtoken) then
      if(multy) then
        if(self:CaptureSpan(conf.E)) then
          local sM, iS, iE = self:GetSpan()
           -- Equals are same amount as start
          if(multy == sM:len()) then
            self:AdvanceSpan() -- Advance to the token
            token = (mtoken or "code.none")
            -- Reset multi line block
            self:SetRowBlock(false, false)
          else -- Continue with the line block color
            token = (mtoken or "code.none")
            self:ConsumeSpan(g_Skip.A)
          end -- Keep the previous token
        else -- Keep the previous token
          token = (mtoken or "code.none")
          self:ConsumeSpan(g_Skip.A)
        end
      else -- Keep the previous token
        token = (mtoken or "code.none")
        char, last = self:ConsumeChar()
      end
    elseif (self:ConsumeArray(g_Patn)) then
      token = "code.number"
    elseif(self:ConsumeSpan(g_Wurl)) then
      token = "code.hyperlink"
    elseif(self:ConsumeBetween(g_Coms.M)) then
      token = "code.comment"
      local sF, iS, iE, tC = self:GetSpan()
      local iS = (tonumber(tC.D) or 0)
      self:SetRowBlock(sF:len() - iS, token, tC)
      if(self:CaptureSpan(tC.E)) then
        self:AdvanceSpan()
        self:SetRowBlock(false, false)
      else
        self:ConsumeSpan(g_Skip.A)
      end
    elseif(self:ConsumeSpan(g_Coms.S[char])) then
      token = "code.comment"
      self:SetRowBlock(false, token)
      self:ConsumeSpan(g_Skip.A)
    elseif(g_Strm.S[char]) then
      local tU = g_Strm.S[char]
      local sE = g_Strm.E:format(char)
      local sC = g_Strm.C:format(char,char)
      local sL = g_Strm.L:format(char,char)
      local sB = g_Strm.B:format(char,char,char)
      if(self:ConsumeSpan(sB)) then
        local sR = tostring(tU.R or "")
        local eR = string.sub(sR, -1, -1)
        local cC, bF, nR = sC, true, string.len(sR)
        if(nR > 1 and eR == char) then -- Quote is escaped
          local cR = string.sub(self.Str,-nR,-1)
          local bC = (cR == sR) -- Is this token escaped
          while(bF and bC) do -- While the quote is escaped
            bF = self:ConsumeSpan(cC)
            cR = string.sub(self.Str,-nR,-1)
            bC = (cR == sR) -- Is this token escaped
          end -- Found a closing quote and continue is disabled
          if(not bF and bC) then self:ConsumeSpan(sE) end
        end -- Language has same quote that escapes entry
      else self:ConsumeSpan(sL) end
      token = tU.T -- Read the token from config
    elseif(self:ConsumeBetween(g_Strm.M)) then
      token = "code.string"
      local sF, iS, iE, tC = self:GetSpan()
      local iS = (tonumber(tC.D) or 0)
      self:SetRowBlock(sF:len() - iS, token, tC)
      if(self:CaptureSpan(tC.E)) then
        self:AdvanceSpan()
        self:SetRowBlock(false, false)
      else
        self:ConsumeSpan(g_Skip.A)
      end
    elseif (self:ConsumeSpan(g_Lifn)) then
      local sstr = string.Trim(self.Str)
      local gstr = luapad.CheckGlobal(sstr, tLib)
      local tgstr, keyw = type(gstr), g_Keyw[sstr]
      if (keyw and isbool(keyw)) then
        token = "code.construct"
      elseif ((gstr and (g_Type[tgstr] or g_Glob[gstr])) or
              (sstr and tLib.Src and tLib.Src[sstr]))
      then
        if (tgstr == "table") then
          tLib.Src, token = gstr, "code.library"
          if(tLib.Nam) then
            tLib.Nam = self:GetConcat(tLib.Nam, sstr, ".")
          else
            tLib.Nam = sstr
          end
        elseif ((gstr == "e" or not g_Type[tgstr]) and sstr == string.upper(sstr)) then
          token = "code.enumerator" -- Neither function nor table capitalized
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
    else
      local sS, iC = self:GetChar()
      local nS = g_Opts.__size__
      if(not nS) then nS = 0
        for nam, flg in pairs(g_Opts) do
          nS = math.max(nS, string.len(nam))
        end; g_Opts.__size__ = math.ceil(nS)
      end; token = nil -- Use the token as flag
      for iS = nS, 1, -1 do -- Check length
        local sP, iP = self:GetChar(iS - 1, true)
        if(sP) then -- There is a next character
          local bP = g_Opts[sP] -- Multi character
          if(bP and isbool(bP)) then
            token = "code.operator"
            self:AdvanceSpan(iC + iS - 1); break
          end -- Multi character operator is found
        end -- Operator is not populated
      end -- The character is not operator
      if(not token) then -- No operator has been matched
        char, last = self:ConsumeChar() -- Advance
        token = "code.none" -- Mark the symbol
      end -- Multi character operator is not found
    end

    -- Register this cell to the current row
    self:UpdateRowSpan(tRow, token, (multy ~= nil))

    if(luapad.debugsyntax) then
      local nL = 30
      local function con(str, len, char)
        local char = string.sub(tostring(char or " "),1,1)
        return string.rep(char, math.max(0, len - #str))..str
      end
      -- Build a message table
      local tM = {
        "Luapad.Syntax:",
        con(tostring(row), 5),
        con(tostring(token), 20),
        con(tostring(self.Pos), 5),
        con(tostring(#tRow), 5),
        con("|"..tostring(tRow[#tRow][1]):sub(-(nL - 2),-1).."|", nL),
        con(tostring(self.Line):sub(self.Pos,self.Pos), 2)
      }
      luapad.SetConsole(table.concat(tM, "\t"), "STAT_OK", sA, func, sN)
    end
  end

  return self:FinalizeRow(tRow, row)
end

--[[
 * Finds the next character that is drawn as a single cell instead of text
 * Tabs are always handled. When the paragraph is shown, spaces,
 * non-breaking spaces and control characters are handled as well
 * Returns the start and end bytes of the character or nil
]]
function PANEL:FindSpecial(text, pos, show)
  if (not show) then
    local iS = string.find(text, "\t", pos, true)
    return iS, iS
  end
  local iA = string.find(text, "[%c ]", pos)
  local iB = string.find(text, "\194\160", pos, true)
  if (iA and (not iB or iA < iB)) then return iA, iA end
  if (iB) then return iB, (iB + 1) end
  return nil
end

--[[
 * Draws plain text (no tabs) starting at visual offset `vcol` (0-based)
 * Only the cells inside the window [voff, vlim) are drawn
 * Returns the visual offset after the text
]]
function PANEL:PaintPlain(text, vcol, voff, vlim, font, color, base, posy)
  local clen = self:GetCellCount(text)
  local iA = math.max(voff - vcol, 0)
  local iB = (vlim and math.min(clen, vlim - vcol) or clen)
  if (iB > iA) then
    local iF = self:GetCellByte(text, iA)
    local iT = self:GetCellByte(text, iB) - 1
    draw.SimpleText(string.sub(text, iF, iT), font, base + (vcol + iA - voff) * self.FontWidth, posy, color)
  end
  return (vcol + clen)
end

--[[
 * Draws one visual line of a row. Without wrapping this is the whole row
 * row  > Row index being drawn
 * tRow > Highlighted cells of the row
 * posy > Vertical position in pixels
 * voff > Visual offset (0-based) drawn at the text start
 * vlim > Visual offset where drawing stops (nil for no limit)
 * tOpt > Flags and colors of the line
]]
function PANEL:PaintRowLine(row, tRow, posy, voff, vlim, tOpt)
  local mG = self:GetGutterWidth()
  local width, height = self.FontWidth, self.FontHeight
  local base = width * mG + 6
  local bShp = self:GetShowParagraph()
  local tSym = SHOW_PARAGRAPH

  if (tOpt.Line) then -- Highlight the current line
    surface.SetDrawColor(tOpt.CL:Unpack())
    surface.DrawRect(width * mG + 5, posy, self:GetWide() - (width * mG + 5), height)
  end

  if (self:HasSelection()) then
    local start, stop = self:MakeSelection(self:Selection())
    local sline, schar = start[1], start[2]
    local eline, echar =  stop[1],  stop[2]

    if (row >= sline and row <= eline) then
      -- Work in visual columns so tabs are covered by their real width
      local vS = (row == sline) and self:ColumnToVisual(row, schar) or 1
      local vE = (row == eline) and self:ColumnToVisual(row, echar)
                 or (self:ColumnToVisual(row, string.len(self.Rows[row]) + 1) + 1)
      local iA = math.max(vS - 1, voff)
      local iB = (vlim and math.min(vE - 1, vlim) or (vE - 1))
      if (iB > iA) then
        surface.SetDrawColor(tOpt.SE:Unpack())
        surface.DrawRect(base + (iA - voff) * width, posy, width * (iB - iA), height)
      end
    end
  end

  if (tOpt.First) then -- Row numbers are drawn only on the first line
    local sM = (self:IsBookMarkRow(row) and "*" or " ")
    draw.SimpleText(tostring(row)..sM, self:GetFontName(), width * mG, posy, tOpt.RN, TEXT_ALIGN_RIGHT)
  end

  -- Tabs are never passed to the renderer. Every cell is split on special
  -- characters, the plain chunks are drawn at their visual column and each
  -- tab only advances the visual column to the next tab stop. When the
  -- paragraph is shown, a symbol is drawn instead of every invisible character
  local vcol, fsym, nrow, used = 0, self:GetFontName(), #tRow, 0
  for _, cell in ipairs(tRow) do used = used + string.len(cell[1]) end
  -- The highlighter does not register trailing white space as a cell
  -- Draw it as plain text so tabs and paragraph symbols are placed there
  local none = self:GetTable().Highlight["code.none"]
  local tail = string.sub(self.Rows[row] or "", used + 1)
  if (tail ~= "") then nrow = nrow + 1 end
  for icl = 1, nrow do
    if (vlim and vcol >= vlim) then break end
    local cell = (tRow[icl] or {tail, none})
    local ccon, csr, cen = cell[1], cell[2][1], cell[2][2]
    local font, pos, len = self:GetFontName(cen), 1, string.len(ccon)
    while (pos <= len) do
      if (vlim and vcol >= vlim) then break end
      local iS, iE = self:FindSpecial(ccon, pos, bShp)
      local iP = (iS and (iS - 1) or len)
      if (iP >= pos) then
        vcol = self:PaintPlain(string.sub(ccon, pos, iP), vcol, voff, vlim, font, csr, base, posy)
      end
      if (not iS) then break end
      local byte = string.byte(ccon, iS)
      if (bShp and vcol >= voff and (not vlim or vcol < vlim)) then
        local sym = ((byte == 9 and tSym.TABS) or (byte == 32 and tSym.SPAS)
                  or (byte == 194 and tSym.NBSP) or tSym.PRLO)
        draw.SimpleText(sym, fsym, base + (vcol - voff) * width, posy, tOpt.RN)
      end
      vcol = vcol + self:GetCellWidth(byte, vcol)
      pos = iE + 1
    end
  end

  if (bShp) then -- Line endings
    if (tOpt.Last) then
      local vend = self:ColumnToVisual(row, string.len(self.Rows[row]) + 1) - 1
      if (vend >= voff and (not tOpt.Clip or vend < tOpt.Clip)) then
        local sym = ((row < self:GetRownum()) and tSym.EOLS or tSym.EOTC)
        draw.SimpleText(sym, fsym, base + (vend - voff) * width, posy, tOpt.RN)
      end
    elseif (vlim) then -- The row continues on the next visual line
      draw.SimpleText(tSym.WRAP, fsym, base + (vlim - voff) * width, posy, tOpt.RN)
    end
  end

  if (tOpt.Caret) then
    local vcar = self:ColumnToVisual(self.Caret[1], self.Caret[2]) - 1
    if ((RealTime() - self.Blink) % 0.8 < 0.4 and vcar >= voff) then
      surface.SetDrawColor(tOpt.CB:Unpack())
      surface.DrawRect(base + (vcar - voff) * width, posy, 1, height)
    end
  end
end

function PANEL:PaintRowID(row, guiCB, guiSE, guiRN, guiCL)
  if (row > self:GetRownum()) then return end

  local tRow = self:SyntaxColorRowID(row)
  local height, scstr = self.FontHeight, self.Scroll[1]
  local bCur = (row == self.Caret[1] and self.TextEntry:HasFocus())
  local tOpt = {CB = guiCB, SE = guiSE, RN = guiRN, CL = guiCL, Line = bCur}

  if (self:GetWordWrap()) then
    local tW = self:GetWrapRow(row)
    local iF, nS = self.WrapFirst[row], #tW.S
    local iK = (bCur and self:GetWrapSegment(tW, self.Caret[2]) or 0)
    local iB = scstr + self.Size[1] + 1
    for iD = 1, nS do
      local iL = (iF + iD - 1)
      if (iL > iB) then break end
      if (iL >= scstr) then
        tOpt.First, tOpt.Last, tOpt.Caret = (iD == 1), (iD == nS), (iD == iK)
        self:PaintRowLine(row, tRow, (iL - scstr) * height, tW.V[iD], tW.V[iD + 1], tOpt)
      end
    end
  else
    local voff = self.Scroll[2] - 1 -- Horizontal scroll
    local vlim = voff + self.Size[2] + 2 -- Skip cells after the panel edge
    tOpt.First, tOpt.Last, tOpt.Caret, tOpt.Clip = true, true, bCur, vlim
    self:PaintRowLine(row, tRow, (row - scstr) * height, voff, vlim, tOpt)
  end
end

function PANEL:PerformLayout()
  local mG = self:GetGutterWidth()
  local nW, nH = self:GetFontSize()
  local mW, mT = self:GetWide(), self:GetTall()

  local bW, oC, iT = self:GetWordWrap(), self.Size[2], nil
  if (bW and not self.WrapDirty) then -- Row on the top of the view
    iT = self.WrapRow[self.Scroll[1]]
  end

  self.ScrollBar:SetSize(16, mT)
  self.ScrollBar:SetPos(mW - 16, 0)
  self.Size[1] = math.floor(mT / nH) - 1
  self.Size[2] = math.floor((mW - (nW * mG + 6) - 16) / nW) - 1

  if (bW and oC ~= self.Size[2]) then
    -- Re-wrap and keep the same row on the top of the view
    self.WrapDirty = true
    self:UpdateWrap()
    if (iT and self.WrapFirst[iT]) then
      self.Scroll[1] = self.WrapFirst[iT]
      self.ScrollBar:SetScroll(self.Scroll[1] - 1)
    end
  end

  self.ScrollBar:SetUp(self.Size[1], self:GetLineCount() - 1)
end

--[[
 * Render from the first line otherwise the multi-line comments are not triggered correctly
 * It is possible the beginning of the screen to be in the middle of a multi-line comment
 * Because of that the rendering should start from the row which is not a multi-line entry
]]
function PANEL:GetRenderBounds()
  local tTab = self:GetTable()
  local tPar = tTab.PaintRows
  local iS = tTab.Scroll[1]
  local iE = (iS + tTab.Size[1] + 1)
  if(self:GetWordWrap()) then -- Convert visual lines to rows
    local nL = self:GetLineCount()
    iS = (tTab.WrapRow[math.Clamp(iS, 1, nL)] or 1)
    iE = (tTab.WrapRow[math.Clamp(iE, 1, nL)] or iS)
  end
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

  local mG = self:GetGutterWidth()
  local mW, mT = self:GetWide(), self:GetTall()

  surface.SetDrawColor(self:GetTheme("gui.rowlinebar"):Unpack())
  surface.DrawRect(0, 0, self.FontWidth * mG + 4, mT)

  surface.SetDrawColor(self:GetTheme("gui.background"):Unpack())
  surface.DrawRect(self.FontWidth * mG + 5, 0, mW - (self.FontWidth * mG + 5), mT)

  self:UpdateWrap() -- Rebuild visual lines when outdated
  self.Scroll[1] = math.floor(self.ScrollBar:GetScroll() + 1)

  local guiCB = self:GetTheme("gui.caretbase")
  local guiSE = self:GetTheme("gui.selection")
  local guiRN = self:GetTheme("gui.rownumbers")
  local guiCL = self:GetTheme("gui.currentline")

  local iS, iE = self:GetRenderBounds()
  for iR = iS, iE do
    self:PaintRowID(iR, guiCB, guiSE, guiRN, guiCL)
  end

  return true
end

function PANEL:SetCaret(caret, start)
  self.Caret = self:CopyPosition(caret)
  self.Start = self:CopyPosition(start or caret)
  self:ScrollCaret()
end

function PANEL:CopyPosition(caret)
  return {caret[1], caret[2]}
end

function PANEL:MovePosition(caret, offset)
  local tR, nR = self.Rows, self:GetRownum()
  local caret, dir = {caret[1], caret[2]}, offset -- Direction is kept for UTF-8 snapping

  if (offset > 0) then
    while true do
      local length = string.len(tR[caret[1]]) - caret[2] + 2
      if (offset < length) then
        caret[2] = caret[2] + offset
        break
      elseif (caret[1] == nR) then
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
        caret[2] = string.len(tR[caret[1]]) + 1
      end
    end
  end

  caret[2] = self:SnapColumn(caret[1], caret[2], dir)
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

    if (eline > sline) then
      self:DropBookMarkRows(sline + 1, eline)
    end
  end

  if (not text or text == "") then
    self:RefreshView()
    self.ScrollBar:SetUp(self.Size[1], self:GetLineCount() - 1)
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

  local tRows = self:SplitLines(text) -- Insert text
  local nRows = #tRows -- Count the marked lines once

  local remainder = string.sub(self.Rows[sline], schar)
  self.Rows[sline] = string.sub(self.Rows[sline], 1, schar - 1) .. tRows[1]
  self.PaintRows[sline] = false

  for i = 2, nRows do
    table.insert(self.Rows, sline + i - 1, tRows[i])
    table.insert(self.PaintRows, sline + i - 1, false)
    self:RefreshView() -- TODO: fix for cache errors
  end

  if (nRows > 1) then
    self:PushBookMarkRows(sline + 1, nRows - 1)
  end

  local stop = {sline + nRows - 1, string.len(self.Rows[sline + nRows - 1]) + 1}

  self.Rows[eline] = self.Rows[eline] .. remainder
  self.PaintRows[eline] = false

  self:SetEmptyRow()

  self:RefreshView()
  self.ScrollBar:SetUp(self.Size[1], self:GetLineCount() - 1)
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
  local tO = TOKEN_CLASSIFY.OSE
  if(system.IsOSX()) then return tO.M end
  if(system.IsLinux()) then return tO.L end
  if(system.IsWindows()) then return tO.W end
  return tO.L -- Defaults to Linux
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
    local tI = self:GetStreamInfo()
    self:SetFontInfo(iS)
    tI.Font = self:GetFontInfo()
  else
    m_Scroll[1] = math.max(m_Scroll[1] - 4 * delta, 1)
    m_Scroll[1] = math.min(m_Scroll[1], self:GetLineCount())
    self.ScrollBar:SetScroll(m_Scroll[1] - 1)
  end
end

function PANEL:ScrollCaret()
  local m_Size = self.Size
  local m_Caret = self.Caret
  local m_Scroll = self.Scroll

  -- Vertical scroll is measured in visual lines when wrapping
  local iLin, vCar = self:CaretToLine(m_Caret)

  if (iLin - m_Scroll[1] < 2) then
    m_Scroll[1] = math.max(iLin - 2, 1)
  end

  if (iLin - m_Scroll[1] > m_Size[1] - 2) then
    m_Scroll[1] = math.max(iLin - m_Size[1] + 2, 1)
  end

  if (self:GetWordWrap()) then -- Wrapped rows always fit horizontally
    m_Scroll[2] = 1
    self.ScrollBar:SetScroll(m_Scroll[1] - 1)
    return
  end

  -- Horizontal scroll is measured in visual columns
  if (vCar - m_Scroll[2] < 4) then
    m_Scroll[2] = math.max(vCar - 4, 1)
  end

  if (vCar - 1 - m_Scroll[2] > m_Size[2] - 4) then
    m_Scroll[2] = math.max(vCar - 1 - m_Size[2] + 4, 1)
  end

  self.ScrollBar:SetScroll(m_Scroll[1] - 1)
end

--[[
 * Removes one indentation level from the start of a line:
 * one leading tab, or up to tab-size leading spaces
]]
function PANEL:UnIndent(line)
  if (string.sub(line, 1, 1) == "\t") then
    return string.sub(line, 2)
  end
  local spaces = string.rep(" ?", self:GetTabSize())
  return (string.gsub(line, "^" .. spaces, "", 1))
end

--[[
 * Returns the column where one indentation step before the caret starts
 * A tab is one step, spaces go back to the previous tab stop
 * Returns nil when there is no whitespace right before the caret
]]
function PANEL:GetIndentStep(caret)
  local line, col = self.Rows[caret[1]] or "", caret[2]
  if (col <= 1) then return nil end
  if (string.byte(line, col - 1) == 9) then return col - 1 end
  local tabw = self:GetTabSize()
  local vcol = self:ColumnToVisual(caret[1], col)
  local need, step = ((vcol - 2) % tabw + 1), col
  while (need > 0 and step > 1 and string.byte(line, step - 1) == 32) do
    step, need = (step - 1), (need - 1)
  end
  return ((step < col) and step or nil)
end

--[[
 * Returns true when only tabs and spaces precede the caret
]]
function PANEL:IsInIndent(caret)
  local line = self.Rows[caret[1]] or ""
  local head = string.sub(line, 1, caret[2] - 1)
  return (not string.find(head, "[^ \t]"))
end

function PANEL:CanUndo()
  return #self.Undo > 0
end

function PANEL:DoUndo()
  local tU = self.Undo
  local nU = #tU
  if (nU <= 0) then return end
  local tC = table.remove(tU)
  self:SetCaret(self:SetArea(tC[1], tC[2], true, false, tC[3], tC[4]))
end

function PANEL:CanRedo()
  return #self.Redo > 0
end

function PANEL:DoRedo()
  local tR = self.Redo
  local nR = #tR
  if (nR <= 0) then return end
  local tC = table.remove(tR)
  self:SetCaret(self:SetArea(tC[1], tC[2], false, true, tC[3], tC[4]))
end

function PANEL:SelectAll()
  local nR = self:GetRownum()
  self.Start = {1, 1}
  self.Caret = {nR, string.len(self.Rows[nR]) + 1}
  self:ScrollCaret()
end

function PANEL:CustomOnKeyCodePressed(code)
  local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
  print(control, code)
  if (control) then
    if (code == KEY_F2) then
      self:ToggleBookMark(); return true
    end
  else
    if (code == KEY_F2) then
      self:SwitchBookMark(); return true
    end
  end
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
    elseif (code == KEY_LBRACKET) then
      local pS = luapad.SearchArea
      if(IsValid(pS)) then
        local pB = pS:GetButtonPrev()
        if(IsValid(pB)) then pB:DoClick() end
      end
    elseif (code == KEY_RBRACKET) then
      local pS = luapad.SearchArea
      if(IsValid(pS)) then
        local pB = pS:GetButtonNext()
        if(IsValid(pB)) then pB:DoClick() end
      end
    elseif (code == KEY_F) then
      luapad.OpenSearch(self:GetSelection())
    elseif (code == KEY_UP) then
      self.Scroll[1] = math.max(self.Scroll[1] - 1, 1)
      self.ScrollBar:SetScroll(self.Scroll[1] - 1)
    elseif (code == KEY_DOWN) then
      self.Scroll[1] = math.min(self.Scroll[1] + 1, self:GetLineCount())
      self.ScrollBar:SetScroll(self.Scroll[1] - 1)
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
      local row = self.Rows[self.Caret[1]]
      local rsub = string.sub(row, 1, self.Caret[2] - 1)
      local tabs = string.match(rsub, "^[ \t]*") -- Keep tabs and spaces as-is
      self:SetSelection(g_NL .. tabs)
    elseif (code == KEY_UP and self:GetWordWrap()) then
      self:MoveCaretLines(-1) -- Moves through the visual lines
      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_DOWN and self:GetWordWrap()) then
      self:MoveCaretLines(1) -- Moves through the visual lines
      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif ((code == KEY_PAGEUP or code == KEY_PAGEDOWN) and self:GetWordWrap()) then
      local half = math.ceil(self.Size[1] / 2)
      local sign = ((code == KEY_PAGEUP) and -1 or 1)
      self:MoveCaretLines(sign * half)
      self.Scroll[1] = math.Clamp(self.Scroll[1] + sign * half, 1, self:GetLineCount())
      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_UP) then
      if (self.Caret[1] > 1) then
        local vcol = self:ColumnToVisual(self.Caret[1], self.Caret[2])
        self.Caret[1] = self.Caret[1] - 1
        self.Caret[2] = self:VisualToColumn(self.Caret[1], vcol)
      end

      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_DOWN) then
      if (self.Caret[1] < self:GetRownum()) then
        local vcol = self:ColumnToVisual(self.Caret[1], self.Caret[2])
        self.Caret[1] = self.Caret[1] + 1
        self.Caret[2] = self:VisualToColumn(self.Caret[1], vcol)
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
      local vcol = self:ColumnToVisual(self.Caret[1], self.Caret[2])
      self.Caret[1] = self.Caret[1] - math.ceil(self.Size[1] / 2)
      self.Scroll[1] = self.Scroll[1] - math.ceil(self.Size[1] / 2)
      self.Caret[1] = math.max(self.Caret[1], 1)
      self.Caret[2] = self:VisualToColumn(self.Caret[1], vcol)
      self.Scroll[1] = math.max(self.Scroll[1], 1)
      self:ScrollCaret()

      if (not shift) then
        self.Start = self:CopyPosition(self.Caret)
      end
    elseif (code == KEY_PAGEDOWN) then
      local vcol = self:ColumnToVisual(self.Caret[1], self.Caret[2])
      self.Caret[1] = self.Caret[1] + math.ceil(self.Size[1] / 2)
      self.Scroll[1] = self.Scroll[1] + math.ceil(self.Size[1] / 2)

      self.Caret[1] = math.min(self.Caret[1], self:GetRownum())

      if (self.Caret[1] == self:GetRownum()) then
        self.Caret[2] = 1
      else
        self.Caret[2] = self:VisualToColumn(self.Caret[1], vcol)
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
        local step = self:IsInIndent(self.Caret) and self:GetIndentStep(self.Caret)
        if (step) then -- Remove one indentation level (tab or spaces to the previous stop)
          self:SetCaret(self:SetArea({self.Caret, {self.Caret[1], step}}))
        else
          self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -1)}))
        end
      end
    elseif (code == KEY_DELETE) then
      if (self:HasSelection()) then
        self:SetSelection()
      else
        local tabw = self:GetTabSize()
        local vcol = self:ColumnToVisual(self.Caret[1], self.Caret[2])
        local need = tabw - (vcol - 1) % tabw -- Spaces up to the next tab stop
        local ahead = string.sub(self.Rows[self.Caret[1]], self.Caret[2], self.Caret[2] + need - 1)
        if (self:IsInIndent(self.Caret) and need > 1 and ahead == string.rep(" ", need)) then
          self:SetCaret(self:SetArea({self.Caret, {self.Caret[1], self.Caret[2] + need}}))
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
        local step = self:GetIndentStep(self.Caret)
        if (step) then -- Remove a tab or spaces back to the previous stop
          self.Start = {self.Caret[1], step}
          self:SetSelection("")
        end
      else
        if (self:GetTabInsert()) then
          self:SetSelection("\t") -- Real tab render advances it to the next stop
        else
          local tabw = self:GetTabSize()
          local vcol = self:ColumnToVisual(self.Caret[1], self.Caret[2])
          self:SetSelection(string.rep(" ", tabw - (vcol - 1) % tabw))
        end
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
  local map = TOKEN_CLASSIFY.SKP.W
  for i = 0, caret[2] do
    local idx = (caret[2] - i)
    local car = line[idx]
    if(not (car and car:find(map))) then
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
  local map = TOKEN_CLASSIFY.SKP.W
  for i = caret[2], #line do
    local car = line[i]
    if(not (car and car:find(map))) then
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

  local tRows = string.Explode(g_NL, self:GetSelection(), false)
  if (shift) then
    for iD = 1, #tRows do tRows[iD] = self:UnIndent(tRows[iD]) end
  else
    local srp = (self:GetTabInsert() and "\t" or string.rep(" ", self:GetTabSize()))
    for iD = 1, #tRows do tRows[iD] = srp .. tRows[iD] end
  end
  self:SetSelection(table.concat(tRows, g_NL))

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
