-- Luapad
-- An in-game scripting environment
-- by DarKSunrise aka Assassini
-- Ported to GMod 13 by SparkZ

luapad = {}

luapad.debugmode = true
luapad.forcedownload = true
luapad.IgnoreConsoleOpen = true

local BASE_DELIMS = "|" -- General symbol used for separator
local BASE_PANLSZ = 2 / 3 -- The ration panel will use according to the screen size
local BASE_FOLDER = "luapad/" -- Default application folder in the data file system
local ICON_FORMAT = "icon16/%s.png" -- Icon path format string
local BASE_FMNAME = "untitled%d.txt" -- Untitled new file format string
local PANL_STORKY = "gmod_luapad"    -- Dedicated tab panel key to store stream info
local FORM_ASOUND = "ambient/water/drip%d.wav"
local DATM_FORMAT = "%Y-%m-%d %H:%M:%S"
local DEBG_FORMAT = "Found routine [%s] in %s"
local CONV_CFLAGS = bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY)

-- They can still do cs lua if you don't have 'sv_allowcslua 0'!!!
local VAR_ADM = CreateConVar("luapad_adminonly",  1, CONV_CFLAGS, "Makes the luapad addon admin only", 0, 1)
local VAR_MXF = CreateConVar("luapad_maxunamed", 10, CONV_CFLAGS, "Makes the luapad addon admin only", 0, 100)
local VAR_MXR = CreateConVar("luapad_maxrecurs", 20, CONV_CFLAGS, "Recurse depth when opening a file system", 0, 100)
local VAR_EDT = CreateConVar("luapad_endataorg",  1, CONV_CFLAGS, "File operation in the whole data folder", 0, 1)

local COLOR_STATUS = {
  ["#TEMCO#"] = Color(0 ,  0 ,  0,  0 ),
  ["STAT_OK"] = Color(72, 205, 72, 255),
  ["STAT_WR"] = Color(205,140, 72, 255),
  ["STAT_ER"] = Color(205, 72, 72, 255),
  ["COMS_OK"] = Color(92, 205, 92, 255),
  ["COMS_WR"] = Color(205,140, 92, 255),
  ["COMS_ER"] = Color(205, 92, 92, 255),
}

local ACCEPTED_STEAMS = {
  ["luapad.Upload"] = true,
  ["luapad.UploadClient"] = true
}

-- https://heyter.github.io/js-famfamfam-search/
-- Extension configurations
local ENABLE_EXTENS = {
  ["txt"]       = {Icon = "page_white_text"        },
  ["lua"]       = {Icon = "page_white_code"        },
  ["c"]         = {Icon = "page_white_c"           },
  ["h"]         = {Icon = "page_white_h"           },
  ["cpp"]       = {Icon = "page_white_cplusplus"   },
  ["csproj" ]   = {Icon = "page_white_visualstudio"},
  ["vcxproj"]   = {Icon = "page_white_visualstudio"},
  ["vbproj" ]   = {Icon = "page_white_visualstudio"},
  ["fsproj" ]   = {Icon = "page_white_visualstudio"},
  ["pyproj" ]   = {Icon = "page_white_visualstudio"},
  ["dbproj" ]   = {Icon = "page_white_visualstudio"},
  ["wixproj"]   = {Icon = "page_white_visualstudio"},
  ["cs"]        = {Icon = "page_white_csharp"      },
  ["rb"]        = {Icon = "page_white_ruby"        },
  ["ru"]        = {Icon = "page_white_ruby"        },
  ["sh"]        = {Icon = "page_white_tux"         },
  ["md"]        = {Icon = "page_white_put"         },
  ["sql"]       = {Icon = "page_white_database"    },
  ["csv"]       = {Icon = "page_white_excel"       },
  ["tsv"]       = {Icon = "page_white_excel"       },
  ["json"]      = {Icon = "page_white_code_red"    },
  ["yaml"]      = {Icon = "page_white_wrench"      },
  ["xml"]       = {Icon = "page_white_excel"       },
  ["php"]       = {Icon = "page_white_php"         },
  ["html"]      = {Icon = "page_white_world"       },
  ["svg"]       = {Icon = "page_white_vector"      },
  ["coffee"]    = {Icon = "page_white_cup"         },
  ["litcoffee"] = {Icon = "page_white_cup"         }
}

-- Browsed folder configurations
local ENABLE_FOLDER = {
  ["data"     ] = {ID = 1, Icon = "table_save"},
  ["lua"      ] = {ID = 2, Icon = "page_code" },
  ["addons"   ] = {ID = 3, Icon = "package"   },
  ["download" ] = {ID = 4, Icon = "transmit"  },
  ["gamemodes"] = {ID = 5, Icon = "joystick"  }
}

local RESTRICTED_FILES = {
  "data/"..BASE_FOLDER.."welcome.txt",
  "data/"..BASE_FOLDER.."saved_tabs.txt",
  "data/"..BASE_FOLDER.."server_globals.txt",
  "addons/luapad/data/"..BASE_FOLDER.."welcome.txt",
  "addons/luapad/data/"..BASE_FOLDER.."saved_tabs.txt",
  "addons/luapad/data/"..BASE_FOLDER.."server_globals.txt",
}

local FMSYNTAX_HILIGHT = {
  N = "luapad._sG", -- Name
  I = "[\"%s\"]",   -- Index
  V = " = \"%s\"",  -- Value
  H = " = {}"       -- Header
}

local PATPATH_CONVERT = {
  {"[\\/]+", "/"}, {"%.%./", ""},
  {"^[/]+" , "" }, {"[/]+$", ""},
  Sors = {"^data/", "", 1},
  Base = {"^"..BASE_FOLDER, "", 1},
}

local FMSYNTAX_METATYP = {
  ["string"            ] = {ID = TYPE_STRING          },
  ["table"             ] = {ID = TYPE_TABLE           },
  ["thread"            ] = {ID = TYPE_THREAD          },
  ["Entity"            ] = {ID = TYPE_ENTITY          },
  ["Player"            ] = {ID = TYPE_ENTITY          },
  ["Weapon"            ] = {ID = TYPE_ENTITY          },
  ["NPC"               ] = {ID = TYPE_ENTITY          },
  ["Vehicle"           ] = {ID = TYPE_ENTITY          },
  ["CSEnt"             ] = {ID = TYPE_ENTITY          },
  ["NextBot"           ] = {ID = TYPE_ENTITY          },
  ["Vector"            ] = {ID = TYPE_VECTOR          },
  ["Angle"             ] = {ID = TYPE_ANGLE           },
  ["PhysObj"           ] = {ID = TYPE_PHYSOBJ         },
  ["ISave"             ] = {ID = TYPE_SAVE            },
  ["IRestore"          ] = {ID = TYPE_RESTORE         },
  ["CTakeDamageInfo"   ] = {ID = TYPE_DAMAGEINFO      },
  ["CEffectData"       ] = {ID = TYPE_EFFECTDATA      },
  ["CMoveData"         ] = {ID = TYPE_MOVEDATA        },
  ["CRecipientFilter"  ] = {ID = TYPE_RECIPIENTFILTER },
  ["CUserCmd"          ] = {ID = TYPE_USERCMD         },
  ["IMaterial"         ] = {ID = TYPE_MATERIAL        },
  ["Panel"             ] = {ID = TYPE_PANEL           },
  ["CLuaParticle"      ] = {ID = TYPE_PARTICLE        },
  ["CLuaEmitter"       ] = {ID = TYPE_PARTICLEEMITTER },
  ["ITexture"          ] = {ID = TYPE_TEXTURE         },
  ["ConVar"            ] = {ID = TYPE_CONVAR          },
  ["IMesh"             ] = {ID = TYPE_IMESH           },
  ["VMatrix"           ] = {ID = TYPE_MATRIX          },
  ["CSoundPatch"       ] = {ID = TYPE_SOUND           },
  ["pixelvis_handle_t" ] = {ID = TYPE_PIXELVISHANDLE  },
  ["DynamicLight"      ] = {ID = TYPE_DLIGHT          },
  ["IVideoWriter"      ] = {ID = TYPE_VIDEO           },
  ["File"              ] = {ID = TYPE_FILE            },
  ["CLuaLocomotion"    ] = {ID = TYPE_LOCOMOTION      },
  ["PathFollower"      ] = {ID = TYPE_PATH            },
  ["CNavArea"          ] = {ID = TYPE_NAVAREA         },
  ["IGModAudioChannel" ] = {ID = TYPE_SOUNDHANDLE     },
  ["CNavLadder"        ] = {ID = TYPE_NAVLADDER       },
  ["CNewParticleEffect"] = {ID = TYPE_PARTICLESYSTEM  },
  ["ProjectedTexture"  ] = {ID = TYPE_PROJECTEDTEXTURE},
  ["PhysCollide"       ] = {ID = TYPE_PHYSCOLLIDE     },
  ["SurfaceInfo"       ] = {ID = TYPE_SURFACEINFO     },
  ["Color"             ] = {ID = TYPE_COLOR           }
}

--[[
 * The path provided is always relative to the game folder
]]
function canOperateIn(sPath)
  local tP = PATPATH_CONVERT
  local bB, sB, oB = luapad.GetPath(sPath)
  if(bB) then -- In the data folder
    if(VAR_EDT:GetBool()) then return true end
    local nS, nE = sB:find(tP.Base[1])
    if(nS and nE and nS == 1) then return true end
  end; return false
end

function canUserAccess(pUser)
  if not IsValid(pUser) then
    return false
  elseif VAR_ADM:GetBool() then
    local bA = (pUser:IsAdmin() or pUser:IsSuperAdmin())
    if not bA then
      pUser:ChatPrint("Sorry "..pUser:Nick()..", only admins can use Luapad.")
    end
    return bA
  else
    return true
  end
end

if (SERVER) then
  util.AddNetworkString("luapad.Upload")
  util.AddNetworkString("luapad.UploadCallback")
  util.AddNetworkString("luapad.UploadClient")
  util.AddNetworkString("luapad.UploadClientCallback")
  util.AddNetworkString("luapad.DownloadRunClient")

  if (luapad.forcedownload) then
    AddCSLuaFile("autorun/luapad.lua")
    AddCSLuaFile("autorun/luapad_editor.lua")
  end

  if(not file.Exists(BASE_FOLDER.."server_globals.txt", "DATA")) then

    local fSin = file.Open(BASE_FOLDER.."server_globals.txt", "wb", "DATA")

    if(fSin) then

      local tMeta, tEnum = {}, {}

      local sN, sV = FMSYNTAX_HILIGHT.N, FMSYNTAX_HILIGHT.V
      local sI, sH = FMSYNTAX_HILIGHT.I, FMSYNTAX_HILIGHT.H

      fSin:Write("-- This is an automatically generated cache file for server-side\n")
      fSin:Write("-- The content includes global functions, meta-tables, and enumerations\n")
      fSin:Write("-- Don't touch it, or you'll probably mess up your syntax highlighting\n")
      fSin:Write("-- The timestamp of this generated file is ["..os.date(DATM_FORMAT).."]\n")
      fSin:Write("\n"); fSin:Write(sN); fSin:Write(sH); fSin:Write("\n")

      fSin:Write("\n\n-- Global functions and libraries\n\n")
      for k, v in pairs(_G) do
        if (isfunction(v)) then
          fSin:Write(sN)
          fSin:Write(sI:format(k))
          fSin:Write(sV:format("f"))
          fSin:Write("\n")
        elseif (istable(v)) then local bH = true
          for n, e in pairs(v) do
            if (isfunction(e)) then
              if(bH) then -- Print the library header
                fSin:Write(sN)
                fSin:Write(sI:format(k))
                fSin:Write(sH)
                fSin:Write("\n"); bH = false
              end -- Print the library members
              fSin:Write(sN)
              fSin:Write(sI:format(k))
              fSin:Write(sI:format(n))
              fSin:Write(sV:format("f"))
              fSin:Write("\n")
            end
          end -- Enumerators are neither functions nor tables
        elseif(string.upper(k) == k) then
          table.insert(tEnum, k)
        end -- Enumerators have uppercase names
      end

      local nE = #tEnum
      if(nE > 0) then

        fSin:Write("\n\n-- Enumerations\n\n")
        table.sort(tEnum, function(u, v) return u < v end)

        for iE = 1, #tEnum do
          local sK = tEnum[iE]
          fSin:Write(sN)
          fSin:Write(sI:format(sK))
          fSin:Write(sV:format("e"))
          fSin:Write("\n")
        end
      end

      fSin:Write("\n\n-- Meta-tables\n\n")
      -- https://wiki.facepunch.com/gmod/Enums/TYPE
      for k, v in pairs(FMSYNTAX_METATYP) do
        if (v.ID) then -- Type exists in TypeID
          local m = FindMetaTable(k)
          if(m and istable(m)) then
            for n, e in pairs(m) do
              if (isfunction(e) and not tMeta[n]) then
                fSin:Write(sN)
                fSin:Write(sI:format(n))
                fSin:Write(sV:format("m"))
                fSin:Write("\n"); tMeta[n] = true
              end
            end
          end
        end
      end

      fSin:Flush(); fSin:Close()
      resource.AddFile("data/"..BASE_FOLDER.."server_globals.txt")
    end
  end

  if(not file.Exists(BASE_FOLDER.."welcome.txt", "DATA")) then
    resource.AddFile("data/"..BASE_FOLDER.."welcome.txt")
  end

  if(not file.Exists(BASE_FOLDER.."about.txt", "DATA")) then
    resource.AddFile("data/"..BASE_FOLDER.."about.txt")
  end

  function luapad.Upload(len, ply)
    if not canUserAccess(ply) then
      return
    end

    local str = net.ReadString()
    if (str and (ply:IsAdmin() or ply:IsSuperAdmin())) then
      RunString(str)
    end

    net.Start("luapad.UploadCallback")
    net.Send(ply)
  end

  net.Receive("luapad.Upload", luapad.Upload)

  function luapad.UploadClient(len, ply)
    if not canUserAccess(ply) then
      return
    end

    local str = net.ReadString()
    if (str and (ply:IsAdmin() or ply:IsSuperAdmin())) then
      net.Start("luapad.DownloadRunClient")
      net.WriteString(str)
      net.Send(player.GetAll())
    end
    net.Start("luapad.UploadClientCallback")
    net.Send(ply)
  end

  net.Receive("luapad.UploadClient", luapad.UploadClient)

  local function AcceptStream(ply, handler, id)
    if (ply:IsAdmin() or ply:IsSuperAdmin()) and ACCEPTED_STEAMS[handler] then
      return true
    end
    if (not ply:IsAdmin()) and ACCEPTED_STEAMS[handler] then
      return false
    end
  end

  hook.Add("AcceptStream", "luapad.AcceptStream", AcceptStream)

  return
end

if (CLIENT) then
  function luapad.DownloadRunClient(len)
    luapad.RunScriptClientFromServer(net.ReadString())
  end
  net.Receive("luapad.DownloadRunClient", luapad.DownloadRunClient)
end

if (file.Exists(BASE_FOLDER.."server_globals.txt", "DATA")) then
  RunString(file.Read(BASE_FOLDER.."server_globals.txt", "DATA"))
else
  include("server_globals.lua")
end

function luapad.About()
  if (not file.Exists(BASE_FOLDER.."about.txt", "DATA")) then
    return
  end
  luapad.AddTab("about.txt", file.Read(BASE_FOLDER.."about.txt", "DATA"), "data/"..BASE_FOLDER)
end

-- https://heyter.github.io/js-famfamfam-search/
function luapad.ToIcon(sIco)
  return ICON_FORMAT:format(tostring(sIco))
end

--[[
 * Shows a standard confirmation dialog window
 * sMsg  > The massage being send to the user
 * sTxt  > Enable text entry and fill it with this value
 * fnSuc > Function to run then the feft button is clicked
 * fnDsc > Function to run then the right button is clicked
 * sSuc  > Label to use for the feft button
 * sDsc  > Label to use for the right button
]]
function luapad.ShowConfirmDialog(sMsg, sTxt, fnSuc, fnDsc, sSuc, sDsc)
  local pFrame = vgui.Create("DFrame")
  if(not IsValid(pFrame)) then return end

  pFrame:SetTitle("Luapad")
  pFrame:SetDraggable(false)
  pFrame:ShowCloseButton(false)
  pFrame:SetBackgroundBlur(true)
  pFrame:SetDrawOnTop(true)

  local pSors = vgui.Create("DPanel", pFrame)
  if(not IsValid(pSors)) then return end

  pSors:SetPaintBackground(false)

  local pText
  local pMesg = vgui.Create("DLabel", pSors)
  if(not IsValid(pMesg)) then return end

  pMesg:SetText(sMsg or "<Message text here>")
  pMesg:SizeToContents()
  pMesg:SetContentAlignment(5)
  pMesg:SetTextColor(color_white)

  if(sTxt ~= nil) then
    pText = vgui.Create("DTextEntry", pSors)
    if(not IsValid(pText)) then return end

    pText:SetText(tostring(sTxt or ""))
    pText.OnEnter = function()
      pFrame:Close()
      local bS, sE = pcall(fnSuc, pText:GetValue()); if(not bS) then
        luapad.SetStatus("Enter [%s] error: %s", "STAT_ER", pText:GetValue(), sE) end
    end
  end

  local pBase = vgui.Create("DPanel", pFrame)
  if(not IsValid(pBase)) then return end

  pBase:SetTall(30)
  pBase:SetPaintBackground(false)

  local pA = vgui.Create("DButton", pBase)
  if(not IsValid(pA)) then return end
  pA:SetText( sSuc or "#dialog.ok" )
  pA:SizeToContents()
  pA:SetTall(20)
  pA:SetWide(pA:GetWide() + 20)
  pA:SetPos(5, 5)
  pA.DoClick = function()
    pFrame:Close()
    if(pText) then
      local bS, sE = pcall(fnSuc, pText:GetValue()); if(not bS) then
        luapad.SetStatus("Accept [%s] error: %s", "STAT_ER", pText:GetValue(), sE) end
    else
      local bS, sE = pcall(fnSuc); if(not bS) then
        luapad.SetStatus("Accept error: %s", "STAT_ER", sE) end
    end
  end

  local pC = vgui.Create("DButton", pBase)
  if(not IsValid(pC)) then return end

  pC:SetText(sDsc or "#dialog.cancel")
  pC:SizeToContents()
  pC:SetTall(20)
  pC:SetWide(pA:GetWide() + 20)
  pC:SetPos(5, 5)
  pC.DoClick = function()
    pFrame:Close()
    if (fnDsc) then
      if(pText) then
        local bS, sE = pcall(fnDsc, pText:GetValue()); if(not bS) then
          luapad.SetStatus("Cancel [%s] error: %s", "STAT_ER", pText:GetValue(), sE) end
      else
        local bS, sE = pcall(fnDsc); if(not bS) then
          luapad.SetStatus("Cancel error: %s", "STAT_ER", sE) end
      end
    end
  end
  pC:MoveRightOf(pA, 5)

  pBase:SetWide(pA:GetWide() + 5 + pC:GetWide() + 10)

  local nW, nH = pMesg:GetSize()
  nW = math.max( nW, 400 )

  pFrame:SetSize(nW + 50, nH + 25 + 75 + 10)
  pFrame:Center()

  pSors:StretchToParent(5, 25, 5, 45)
  pMesg:StretchToParent(5, 5, 5, 35)

  if(pText) then
    pText:StretchToParent(5, nil, 5, nil)
    pText:AlignBottom(5)
    pText:RequestFocus()
    pText:SelectAllText(true)
  end

  pBase:CenterHorizontal()
  pBase:AlignBottom(8)

  pFrame:MakePopup()
  pFrame:DoModal()

  return pFrame
end

--[[
 * Normalizes a path to the gmod file system
 * sOrg > The path to be checked and converted
 * fP   > Flag if the `sP` is relative to the data folder
 * sP   > Converted path for accessing the data folder
 * oP   > Original converted path relative to the game folder
]]
function luapad.GetPath(sOrg)
  local fP, sP, oP
  local tP = PATPATH_CONVERT
  local sD = ("data/" .. BASE_FOLDER)
  local sB = tostring(sOrg or sD)
        sB = ((sB == "") and sD or sB)
  -- Copy of the path origin and convert it
  for iP = 1, #tP do
    sB = string.gsub(sB, unpack(tP[iP]))
  end
  -- Check if we are in the data/ folder and remove
  fP, sP, oP = false, sB, sB
  -- The path is relative to the data folder
  if(string.find(sB, tP.Sors[1]) == 1) then
    fP, sP = true, string.gsub(sB, unpack(tP.Sors))
  end
  -- Return the normalized path and flag
  return fP, sP.."/", oP.."/"
end

function luapad.CheckGlobal(func)
  if (luapad._sG[func] ~= nil) then
    local sN = FMSYNTAX_HILIGHT.N
    if (luapad.debugmode) then
      print(DEBG_FORMAT:format(func, sN))
    end
    return luapad._sG[func]
  end
  if (_G[func] ~= nil) then
    if (luapad.debugmode) then
      print(DEBG_FORMAT:format(func, "_G"))
    end
    return _G[func]
  end

  return false
end

function luapad.OnPlayerQuit()
end

function luapad.SaveTabs()
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local tO, tW = {"", "", "", ""}, {}
  local tI = pS:GetItems()
  local aT = pS:GetActiveTab()
  for iD = 1, #tI do
    local tP = tI[iD]
    local pT = tP.Tab
    if(IsValid(pT)) then
      local tS = :GetStreamInfo()
      tO[1], tO[2] = tS.Name , tS.Path
      tO[3], tO[4] = (tS.Mark or ""), tS.Icon
      if(pT == aT) then tO[1] = "*" .. tO[1] end
      table.insert(tW, table.concat(tO, BASE_DELIMS))
    end
  end
  file.Write(BASE_FOLDER.."saved_tabs.txt", table.concat(tW, "\n"))
end

function luapad.LoadTabs()
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end
   pS:Clear() -- The * symbol is invalid for a file name
  -- Read the saved tabs file and load the related files
  local sF = file.Read(BASE_FOLDER.."saved_tabs.txt", "DATA" )
  if(not sF) then return end -- File not found then bail out
  local tW, aT = ("[\r\n]+"):Explode(sF, true), nil
  for iD = 1, #tW do -- Basically we have one tab on one line
    local tO = BASE_DELIMS:Explode(tW[iD]) -- Empty lines are excluded
    local bA = (string.sub(tO[1], 1, 1) == "*") -- File name starts with * when active
    if(bA) then tO[1] = string.sub(tO[1], 2, -1) end
    local bB, sB, oB, pT = luapad.GetPath(tO[2])
    if(bB) then -- Load a tab relative to the data folder
      pT = luapad.AddTab(tO[1], file.Read(sB..tO[1], "DATA"), oB, tO[3], tO[4])
    else -- Load a tab relative to the game folder
      pT = luapad.AddTab(tO[1], file.Read(oB..tO[1], "GAME"), oB, tO[3], tO[4])
    end -- Store the last tab found as active tab reference
    aT = ((bA and IsValid(pT)) and pT or aT)
  end
  -- If a tab is marked as active set the last one marked
  if(aT and IsValid(aT)) then pS:SetActiveTab(aT) end
end

function luapad.Toggle()
  if (SERVER or not canUserAccess(LocalPlayer())) then
    return
  end

  if (IsValid(luapad.Frame) and not luapad.debugmode) then
    luapad.Frame:SetVisible(not luapad.Frame:IsVisible())
    return
  end

  -- Build it, if it doesn't exist
  local nW, nH = ScrW(), ScrH()
  luapad.Frame = vgui.Create("DFrame")
  local mB = BASE_PANLSZ
  local mR = (1 - BASE_PANLSZ) / 2
  local sW, sH = mB * nW, mB * nH
  local pW, pH = mR * nW, mR * nH
  luapad.Frame:SetSize(sW, sH)
  luapad.Frame:SetPos(pW, pH)
  luapad.Frame:SetTitle("Luapad")
  luapad.Frame:SetVisible(true)
  luapad.Frame:ShowCloseButton(true)

  if(luapad.debugmode) then
    luapad.Frame:SetDeleteOnClose(true)
  else
    luapad.Frame:SetDeleteOnClose(false)

    function luapad.Frame:OnClose()
      self:SetVisible(true)
      luapad.Toggle()
      luapad.SaveTabs()
    end -- Thanks Microosoft -SparkZ
  end

  luapad.Frame:MakePopup()

  luapad.Toolbar = vgui.Create("DIconLayout", luapad.Frame)
  luapad.Toolbar:SetPos(5, 30)
  luapad.Toolbar:SetSize(luapad.Frame:GetWide() - 6, 25)
  luapad.Toolbar:GetSpaceX(5)
  luapad.Toolbar:SetSpaceY(5)
  luapad.Toolbar:SetLayoutDir(LEFT)
  luapad.Toolbar:DockPadding(2,2,2,2)
  luapad.Toolbar:Dock(TOP)
  luapad.Toolbar:SetStretchWidth(true)
  luapad.Toolbar:SetStretchHeight(false)

  local nX, nY = luapad.Toolbar:GetPos()
  local nW, nH = luapad.Toolbar:GetSize()
  local oW, oH = luapad.Frame:GetSize()
  luapad.PropertySheet = vgui.Create("DPropertySheet", luapad.Frame)
  luapad.PropertySheet:SetPos(5, nY + nH + 15)
  luapad.PropertySheet:SetSize(oW - 6, oH - 80)
  luapad.PropertySheet:SetPadding(2)
  luapad.PropertySheet:SetFadeTime(0)
  luapad.PropertySheet:DockPadding(2,2,2,2)
  luapad.PropertySheet:Dock(TOP)

  function luapad.PropertySheet:OnActiveTabChanged(pO, pN)
    if(IsValid(pN)) then
      local tS = pN:GetStreamInfo()
      luapad.Frame:SetTitle("Luapad - " .. tS.Path .. tS.Name)
    elseif(IsValid(pO)) then
      local tS = pO:GetStreamInfo()
      luapad.Frame:SetTitle("Luapad - " .. tS.Path .. tS.Name)
    else
      luapad.Frame:SetTitle("Luapad")
    end
  end

  function luapad.PropertySheet:GetTabIndex(pTre)
    if(not IsValid(pTre)) then return nil end
    local tT = self:GetItems()
    for iT = 1, #tT do local tP = tT[iT]
      if(pTre == tP.Tab) then return iT end
    end; return nil
  end

  local oW, oH = luapad.Frame:GetSize()
  luapad.Statusbar = vgui.Create("DIconLayout", luapad.Frame)
  luapad.Statusbar:SetPos(3, oH - 22)
  luapad.Statusbar:SetSize(oW - 6, 22)
  luapad.Statusbar:GetSpaceX(1)
  luapad.Statusbar:SetSpaceY(1)
  luapad.Statusbar:SetLayoutDir(LEFT)
  luapad.Statusbar:SetStretchWidth(true)
  luapad.Statusbar:SetStretchHeight(false)
  luapad.Statusbar.PerformLayout = luapad.Toolbar.PerformLayout
  luapad.Statusbar:DockMargin(5,5,5,5)
  luapad.Statusbar:DockPadding(2,2,2,2)
  luapad.Statusbar:Dock(TOP)
  luapad.Statusbar:InvalidateLayout(true)

  luapad.AddToolbarItem("New (CTRL + N) / Active tab origin"   , "page_add"   , luapad.NewTab, luapad.NewTabActive)
  luapad.AddToolbarItem("Open (CTRL + O) / Open file browser"  , "folder_page", luapad.OpenTab, luapad.OpenBrowse)
  luapad.AddToolbarItem("Save (CTRL + S) / Save all tabs"      , "disk"       , luapad.SaveScript, luapad.SaveAll)
  luapad.AddToolbarItem("Save As (CTRL + ALT + S)"             , "page_save"  , luapad.SaveAsScript)
  luapad.AddToolbarSpacer()
  luapad.AddToolbarItem("Execute / Execute realm", "table_lightning", luapad.RunScriptClient, luapad.RunScriptMenu)
  luapad.AddToolbarItem("Refresh / Refresh all"  , "table_refresh"  , luapad.RefreshTabActive, luapad.RefreshTabAll)
  luapad.AddToolbarItem("Load tabs / Save tabs"  , "table_multiple" , luapad.LoadTabs, luapad.SaveTabs)
  luapad.AddToolbarItem("Close / Close all"      , "table_delete"   , luapad.CloseTabActive, luapad.CloseTabAll)

  if (file.Exists(BASE_FOLDER.."saved_tabs.txt", "DATA")) then
    luapad.LoadTabs()
  elseif (file.Exists(BASE_FOLDER.."welcome.txt", "DATA")) then
    luapad.AddTab("welcome.txt", file.Read(BASE_FOLDER.."welcome.txt", "DATA"), "data/"..BASE_FOLDER)
  else
    luapad.NewTab()
  end

  luapad.PropertySheet:InvalidateLayout(true)
  luapad.Toolbar:InvalidateLayout(true)
end

--[[
 * Populates the status bar with the popper message
 * The message alpha is fading until it disappears
 * sFmt > Message format. All substitutions are strings
 * sKey > Color key from the status table
 * ...  > The values that match the format string
 * Returns: The Created label panel
]]
function luapad.SetStatus(sFmt, sKey, ...)
  if(not sKey) then return end
  local cDrw = COLOR_STATUS[sKey]
  if(not cDrw) then return end
  local cTmc = COLOR_STATUS["#TEMCO#"]

  local nC, tC = select("#", ...), {...}
  for iC = 1, nC do tC[iC] = tostring(tC[iC]) end

  -- Moce color data to status color
  cTmc.r, cTmc.g = cDrw.r, cDrw.g
  cTmc.b, cTmc.a = cDrw.b, cDrw.a

  timer.Remove("luapad.Statusbar.Fade")
  luapad.Statusbar:Clear()

  local pLab = vgui.Create("DLabel", luapad.Statusbar)
  pLab:SetText(sFmt:format(unpack(tC)))
  pLab:SetTextColor(cTmc) -- Reference assignment
  pLab:SizeToContents()

  timer.Create(
    "luapad.Statusbar.Fade", 0.01, 0, function()
      if(not IsValid(pLab)) then return end
      local cBar = pLab:GetTextColor()
      cBar.a = math.Clamp(cBar.a - 1, 0, 255)
      pLab:SetTextColor(cBar)

      if (cBar.a == 0) then
        timer.Remove("luapad.Statusbar.Fade")
        if(IsValid(pLab)) then pLab:Remove() end
      end
    end
  )

  luapad.Statusbar:Add(pLab)
  -- https://wiki.facepunch.com/gmod/HL2_Sound_List
  surface.PlaySound(FORM_ASOUND:format(math.random(1, 4)))

  return pLab
end

--[[
 * This can add a custom item to the toolbar that adds custom behavior
 * vTip      > Tooltip used for help text
 * sIco      > Image icon to be displayed with
 * act(LRMD) > Action functions done by the user mouse
]]
function luapad.AddToolbarItem(vTip, sIco, actL, actR, actM, actD)
  local pB = luapad.Toolbar
  if(not IsValid(pB)) then return end

  local pBut, nS = pB:Add("DImageButton"), 22
  if(not IsValid(pBut)) then return end
  -- Configure image and help text
  pBut:SetImage(luapad.ToIcon(sIco or "lightning"))
  if(vTip ~= nil) then pBut:SetTooltip(tostring(vTip)) end
  pBut:SetSize(nS, nS) -- Make the button a square image that runs functions
  -- Do not pass the button reference here unless the button must be changed
  if(actL) then
    function pBut:DoClick()
      local bS, sE = pcall(actL); if(not bS) then
        luapad.SetStatus("LeftClick [%s] error: %s", "STAT_ER", pBut:GetTooltip(), sE) end
    end
  end
  if(actR) then
    function pBut:DoRightClick()
      local bS, sE = pcall(actR); if(not bS) then
        luapad.SetStatus("RightClick [%s] error: %s", "STAT_ER", pBut:GetTooltip(), sE) end
    end
  end
  if(actM) then
    function pBut:DoMiddleClick()
      local bS, sE = pcall(actM); if(not bS) then
        luapad.SetStatus("MiddleClick [%s] error: %s", "STAT_ER", pBut:GetTooltip(), sE) end
    end
  end
  if(actD) then
    function pBut:DoDoubleClick()
      local bS, sE = pcall(actD); if(not bS) then
        luapad.SetStatus("DoubleClick [%s] error: %s", "STAT_ER", pBut:GetTooltip(), sE) end
    end
  end

  return pBut
end

function luapad.AddToolbarSpacer()
  local pLab = luapad.Toolbar:Add("DLabel")
  if(not IsValid(pLab)) then return end

  pLab:SetText(" "..BASE_DELIMS.." ")
  pLab:SizeToContents()

  return pLab
end

--[[
 * Closes a tab via name, full path or mark
 * Closes only one tab if matched
]]
function luapad.CloseTabName(name, mark)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end
  -- Check the property sheet tab
  local tI = pS:GetItems()
  local nI = #tI
  if(nI == 0) then
    return -- Nothing to close
  else -- At least one tab
    local sS  = tostring(mark or name)
    -- The context menu option is available
    local sO = tS.Path .. tS.Name
    local sN, sM = tS.Name, tS.Mark
    for iD = 1, #tI do
      local tP = tI[iD]
      local cT = tP.Tab
      local tS = cT:GetStreamInfo()
      if(sM and sM:find(sS, 1, true)) then
        if(nI > 1) then -- More tabs
          pS:CloseTab(cT, true)
        else -- Only one tab is open
          pS:Clear()
        end; break
      end
      if(sO and sO:find(sS, 1, true)) then
         if(nI > 1) then -- More tabs
          pS:CloseTab(cT, true)
        else -- Only one tab is open
          pS:Clear()
        end; break
      end
      if(sN and sN:find(sS, 1, true)) then
         if(nI > 1) then -- More tabs
          pS:CloseTab(cT, true)
        else -- Only one tab is open
          pS:Clear()
        end; break
      end
    end; pS:InvalidateLayout()
  end
end

--[[
 * Closes the tab by view panel reference
 * pTre > The tab reference that must be closed
]]
function luapad.CloseTabView(pTre)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local iT = pS:GetTabIndex(pTre)
  if(not iT) then return end

  -- Avoid triggering active tab close
  local aT = pS:GetActiveTab()
  if(aT == pTre) then
    luapad.CloseTabActive()
    return
  end

  local tI = pS:GetItems()

  if(#tI == 1) then
    pS:Clear()
  else
    pS:CloseTab(pTre, true)
  end

  pS:InvalidateLayout()
end

--[[
 * Closes all tabs to the left
 * No tabs are found the index is empty
 * pTre > The tab to use as reference
 * bInc > Close also the reference tab
]]
function luapad.CloseTabLeft(pTre, bInc)
  if(not IsValid(pTre)) then return end
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end
  local iT = pS:GetTabIndex(pTre)
  if(not iT) then return end
  if(not bInc) then iT = iT - 1 end
  local tI = pS:GetItems()
  -- Calculated closed tabs count
  local cT, nT = tI[1].Tab, iT
  -- Close all to the left including last
  if(iT == #tI) then pS:Clear(); return end
  pS:SetActiveTab(tI[iT + 1].Tab)
  -- Clear all inactive tabs
  while(tI[1] and IsValid(cT)) do
    -- Remove a tab and register it
    pS:CloseTab(cT, true); nT = nT - 1
    if(nT <= 0) then break end
    cT = tI[1].Tab
  end
end

--[[
 * Closes all tabs to the right
 * No tabs are found the index is empty
 * pTre > The tab to use as reference
 * bInc > Close also the reference tab
]]
function luapad.CloseTabRight(pTre, bInc)
  if(not IsValid(pTre)) then return end
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end
  local iT = pS:GetTabIndex(pTre)
  if(not iT) then return end
  local tI = pS:GetItems()
  if(not bInc) then iT = iT + 1 end
  -- Calculated closed tabs count
  local nT = (#tI - iT + 1)
  -- Close all to the right including 1-st
  if(iT == 1) then pS:Clear(); return end
  pS:SetActiveTab(tI[iT - 1].Tab)
  -- Clear all inactive tabs
  local cT = tI[iT].Tab
  while(tI[iT] and IsValid(cT) and nT > 0) do
    -- Remove a tab and register it
    pS:CloseTab(cT, true); nT = nT - 1
    if(nT <= 0) then break end
    cT = tI[iT].Tab
  end
end

--[[
 * Closes the active tab
]]
function luapad.CloseTabActive()
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local nT = #pS.Items

  if(nT == 0) then
    return
  elseif(nT == 1) then
    pS:Clear()
  else
    local aT = pS:GetActiveTab()
    local iT = pS:GetTabIndex(aT)

    if(not IsValid(aT)) then return end
    if(not iT) then return end

    if(iT == 1) then
      pS:SetActiveTab(pS.Items[2].Tab)
    else -- Avoid triggering active tab close
      pS:SetActiveTab(pS.Items[iT - 1].Tab)
    end

    pS:CloseTab(aT, true)
    pS:InvalidateLayout()
  end
end

--[[
 * Closes Other tabs
]]
function luapad.CloseTabOther(pTre)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local iT = pS:GetTabIndex(pTre)
  if(not iT) then return end

  luapad.CloseTabLeft(pTre)
  luapad.CloseTabRight(pTre)
end

--[[
 * Closes all the tabs
]]
function luapad.CloseTabAll()
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  pS:Clear()
end

--[[
 * Refreshes all the tabs on name/marker
]]
function luapad.RefreshTabName(name, mark)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local tI = pS:GetItems()
  local nI, nU = #tI, 0
  if(nI <= 0) then return end

  local sS  = tostring(mark or name)

  for iT = 1, nT do
    local cT = tI[iT].Tab
    if(IsValid(cT)) then
      local tS, bS = cT:GetStreamInfo(), false
      local sD, sN, sM = tS.Path, tS.Name, tS.Mark
      local bB, sB, oB = luapad.GetPath(sD)
      if(bB) then
        local sO = (sD .. sN)
        local sF = (sB .. sN)
        if(sM and sM:find(sS, 1, true)) then
          bS = true  -- Match by marker
        elseif(sO and sO:find(sS, 1, true)) then
          bS = true -- Match by origin
        elseif(sN and sN:find(sS, 1, true)) then
          bS = true -- Match by name
        else -- Assign false in other cases
          bS = false -- Do not match anything
        end
        if(bS) then
          local sCon = file.Read(sF, "DATA")
          if(sCon) then
            nU = nU + 1; cT:SetContents(sCon)
          else
            luapad.SetStatus("File [%s%s] refresh failed! Processed [%s] of [%s] tabs!", "STAT_ER", oB, sN, nU, nI)
            return
          end
        end
      end
    end
  end

  -- In case the loop is executed
  if(nU <= 0) then -- All tabs are not from the data folder
    luapad.SetStatus("No tabs have been refreshed (check the origin access rights)!", "STAT_WR")
  else -- Not every tab may be from the data folder
    luapad.SetStatus("Refreshed successfully [%s] of [%s] tabs!", "STAT_OK", nU, nI)
  end
end

function luapad.RefreshTabView(pTre)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local iT = pS:GetTabIndex(pTre)
  if(not iT) then return end

  -- Avoid triggering active tab close
  local aT = pS:GetActiveTab()
  if(aT == pTre) then
    luapad.RefreshTabActive()
    return
  end

  local tS = pTre:GetStreamInfo()
  local sD, sN = tS.Path, tS.Name
  local bB, sB, oB = luapad.GetPath(sD)

  if(bB) then
    local sF = (sB .. sN)
    local sCon = file.Read(sF, "DATA")
    if(sCon) then pTre:SetContents(sCon)
      luapad.SetStatus("File successfully refreshed!", "STAT_OK")
    else
      luapad.SetStatus("File [%s%s] not found!", "STAT_ER", oB, sN)
    end
  else
    luapad.SetStatus("File [%s%s] refresh not supported!", "STAT_WR", oB, sN)
  end
end

--[[
 * Refreshes all tabs to the left
 * No tabs are found the index is empty
 * pTre > The tab to use as reference
 * bInc > Close also the reference tab
]]
function luapad.RefreshTabLeft(pTre, bInc)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local iT = pS:GetTabIndex(pTre)
  if(not iT) then return end

  local tI = pS:GetItems()
  local nI, nU = #tI, 0
  if(nI <= 0) then return end

  local iE = (bInc and iT or (iT - 1))

  for iR = 1, iE do
    local cT = tI[iR].Tab
    if(IsValid(cT)) then
      local tS = cT:GetStreamInfo()
      local sD, sN = tS.Path , tS.Name
      local bB, sB, oB = luapad.GetPath(sD)
      if(bB) then
        local sF = (sB .. sN)
        local sCon = file.Read(sF, "DATA")
        if(sCon) then
          nU = nU + 1; cT:SetContents(sCon)
        else
          luapad.SetStatus("File [%s%s] refresh failed! Processed [%s] of [%s] tabs!", "STAT_ER", oB, sN, nU, nI)
          return
        end
      end
    end
  end

  -- In case the loop is executed
  if(nU <= 0) then -- All tabs are not from the data folder
    luapad.SetStatus("No tabs have been refreshed (check the origin access rights)!", "STAT_WR")
  else -- Not every tab may be from the data folder
    luapad.SetStatus("Refreshed successfully [%s] of [%s] tabs!", "STAT_OK", nU, nI)
  end
end

--[[
 * Refreshes all tabs to the right
 * No tabs are found the index is empty
 * pTre > The tab to use as reference
 * bInc > Close also the reference tab
]]
function luapad.RefreshTabRight(pTre, bInc)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local iT = pS:GetTabIndex(pTre)
  if(not iT) then return end

  local tI = pS:GetItems()
  local nI, nU = #tI, 0
  if(nI <= 0) then return end

  local iS = (bInc and iT or (iT + 1))

  for iR = iS, nI do
    local cT = tI[iR].Tab
    if(IsValid(cT)) then
      local tS = cT:GetStreamInfo()
      local sD, sN = tS.Path , tS.Name
      local bB, sB, oB = luapad.GetPath(sD)
      if(bB) then
        local sF = (sB .. sN)
        local sCon = file.Read(sF, "DATA")
        if(sCon) then
          nU = nU + 1; cT:SetContents(sCon)
        else
          luapad.SetStatus("File [%s%s] refresh failed! Processed [%s] of [%s] tabs!", "STAT_ER", oB, sN, nU, nI)
          return
        end
      end
    end
  end

  -- In case the loop is executed
  if(nU <= 0) then -- All tabs are not from the data folder
    luapad.SetStatus("No tabs have been refreshed (check the origin access rights)!", "STAT_WR")
  else -- Not every tab may be from the data folder
    luapad.SetStatus("Refreshed successfully [%s] of [%s] tabs!", "STAT_OK", nU, nI)
  end
end

--[[
 * Refreshes the active tab
]]
function luapad.RefreshTabActive()
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local aT = pS:GetActiveTab()
  if(not IsValid(aT)) then return end

  local tS = aT:GetStreamInfo()
  if(not tS) then return end

  local sD, sN = tS.Path, tS.Name
  local bB, sB, oB = luapad.GetPath(sD)

  if(bB) then
    local sF, sT = (sB .. sN), (aT:GetContents() or "")

    local sCon = file.Read(sF, "DATA")
    if(sCon) then aT:SetContents(sCon)
      luapad.SetStatus("File successfully refreshed!", "STAT_OK")
    else
      luapad.SetStatus("File [%s%s] not found!", "STAT_ER", oB, sN)
    end
  else
    luapad.SetStatus("File [%s%s] refresh not supported!", "STAT_WR", oB, sN)
  end
end

--[[
 * Refreshes all tabs to the right
 * No tabs are found the index is empty
 * pTre > The tab to use as reference
 * bInc > Close also the reference tab
]]
function luapad.RefreshTabOther(pTre)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local iT = pS:GetTabIndex(pTre)
  if(not iT) then return end

  local tI = pS:GetItems()
  local nI, nU = #tI, 0
  if(nI <= 0) then return end

  for iR = 1, nI do
    local cT = tI[iR].Tab
    if(iR ~= iT and IsValid(cT)) then
      local tS = cT:GetStreamInfo()
      local sD, sN = tS.Path , tS.Name
      local bB, sB, oB = luapad.GetPath(sD)
      if(bB) then
        local sF = (sB .. sN)
        local sCon = file.Read(sF, "DATA")
        if(sCon) then
          nU = nU + 1; cT:SetContents(sCon)
        else
          luapad.SetStatus("File [%s%s] refresh failed! Processed [%s] of [%s] tabs!", "STAT_ER", oB, sN, nU, nI)
          return
        end
      end
    end
  end

  -- In case the loop is executed
  if(nU <= 0) then -- All tabs are not from the data folder
    luapad.SetStatus("No tabs have been refreshed (check the origin access rights)!", "STAT_WR")
  else -- Not every tab may be from the data folder
    luapad.SetStatus("Refreshed successfully [%s] of [%s] tabs!", "STAT_OK", nU, nI)
  end
end

function luapad.RefreshTabAll()
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local tI = pS:GetItems()
  local nI, nU = #tI, 0
  if(nI <= 0) then return end

  for iR = 1, nI do
    local cT = tI[iR].Tab
    if(IsValid(cT)) then
      local tS = cT:GetStreamInfo()
      local sD, sN = tS.Path, tS.Name
      local bB, sB, oB = luapad.GetPath(sD)
      if(bB) then
        local sF = (sB .. sN)
        local sCon = file.Read(sF, "DATA")
        if(sCon) then
          nU = nU + 1; cT:SetContents(sCon)
        else
          luapad.SetStatus("File [%s%s] refresh failed! Processed [%s] of [%s] tabs!", "STAT_ER", oB, sN, nU, nI)
          return
        end
      end
    end
  end

  -- In case the loop is executed
  if(nU <= 0) then -- All tabs are not from the data folder
    luapad.SetStatus("No tabs have been refreshed (check the origin access rights)!", "STAT_WR")
  else -- Not every tab may be from the data folder
    luapad.SetStatus("Refreshed successfully [%s] of [%s] tabs!", "STAT_OK", nU, nI)
  end
end

--[[
 * Adds a tab to the property sheet files
 * name > The file name used used for streaming
 * cont > Text panel contents manipulated
 * path > The file path. Relative to the game folder
 * term > Tab custom title instead of the file name
]]
function luapad.AddTab(name, cont, path, term, icon)
  local sPth = tostring(path or "")
  local sNam = tostring(name or "")
  local sCon = tostring(cont or "")
  local sIco = tostring(icon or "page_white")
  local sTag = ((mark ~= nil and mark ~= "") and tostring(mark) or nil)

  local pSheet = luapad.PropertySheet
  if(not IsValid(pSheet)) then return end

  local pPan = vgui.Create("DPanel", pSheet)
  if(not IsValid(pPan)) then return end

  local nW, nH = pSheet:GetSize()
  pPan:SetSize(nW, nH - 22)
  pPan:Dock(FILL)

  local nW, nH = pPan:GetSize()
  local pText = vgui.Create("LuapadEditor", pPan)
  if(not IsValid(pText)) then return end

  pText:SetSize(nW, nH)
  pText:SetText(sCon)
  pText:Dock(FILL)
  pText:RequestFocus()
  pText:SizeToContents()

  local tInfo = pSheet:AddSheet(tostring(sTag or sNam), pPan, luapad.ToIcon(sIco), false, false)
  local pTab  = tInfo.Tab; pTab[PANL_STORKY] = {}
  local tSor  = pTab[PANL_STORKY]

  tSor.Name = sNam -- The actual file name associated with the tab
  tSor.Path = sPth -- File path always relative to the game folder
  tSor.Mark = sTag -- Tab mark in case provided is displayed instead of name
  tSor.Icon = sIco -- Custom tab icon usually defined by the file extension

  pTab:SetTooltip(sPth .. sNam)

  --[[
   * Retrieves the storage info from the tab
  ]]
  function pTab:GetStreamInfo()
    return self[PANL_STORKY]
  end

  --[[
   * Retrieves the editor text area panel
  ]]
  function pTab:GetTextArea()
    return self:GetPanel():GetChildren()[1]
  end

  --[[
   * Retrieves the text from this tab
  ]]
  function pTab:GetContents()
    local pText = self:GetTextArea()
    if(not IsValid(pText)) then return "" end
    return pText:GetText()
  end

  --[[
   * Retrieves the text from this tab
  ]]
  function pTab:SetContents(sCon)
    local pText = self:GetTextArea()
    if(not IsValid(pText)) then end
    local sCon = tostring(sCon or "")
    pText:SetText(sCon)
    pText:RequestFocus()
    pText:SizeToContents()
  end

  --[[
   * Makes this tab the active one
  ]]
  function pTab:DoClick()
    self:GetPropertySheet():SetActiveTab(self)
  end

  --[[
   * Close the tab middle-clicked
  ]]
  function pTab:DoMiddleClick()
    local pS = self:GetPropertySheet()
    local tI = pS:GetItems()
    if(#tI == 1) then pS:Clear() else
      pS:CloseTab(self, true)
    end
  end

  --[[
   * Open a new tab
  ]]
  function pTab:DoDoubleClick()
    local tS = self:GetStreamInfo()
    local bB, sB, oB = luapad.GetPath(tS.Path)
    if(bB) then
      luapad.NewTab(nil, oB)
    else
      luapad.NewTab()
    end
  end

  --[[
   * Show some tab options
  ]]
  function pTab:DoRightClick()
    local pMenu = DermaMenu()
    if(not IsValid(pMenu)) then return end
    pMenu:SetPos(gui.MousePos())
    -- Copy tab internals
    local pIn, pOp = pMenu:AddSubMenu("Copy")
    pOp:SetIcon(luapad.ToIcon("table_multiple"))
    pIn:AddOption("Name", function()
      SetClipboardText(self:GetStreamInfo().Name)
    end):SetImage(luapad.ToIcon("page_green"))
    pIn:AddOption("Label", function()
      SetClipboardText(self:GetStreamInfo().Mark)
    end):SetImage(luapad.ToIcon("tag_green"))
    pIn:AddOption("Path", function()
      SetClipboardText(self:GetStreamInfo().Path)
    end):SetImage(luapad.ToIcon("folder"))
    pIn:AddOption("Full", function()
      local tS = self:GetStreamInfo()
      SetClipboardText(tS.Path .. tS.Name)
    end):SetImage(luapad.ToIcon("folder_page"))
    pIn:AddOption("Index", function()
      local pS = self:GetPropertySheet()
      local iT = pS:GetTabIndex(self)
      SetClipboardText(tostring(iT or "N/A"))
    end):SetImage(luapad.ToIcon("key"))
    -- File operations
    local pIn, pOp = pMenu:AddSubMenu("File")
    pOp:SetIcon(luapad.ToIcon("table_lightning"))
    pIn:AddOption("New" , function()
      local tS = self:GetStreamInfo()
      luapad.NewTab(nil, tS.Path)
    end):SetImage(luapad.ToIcon("page_add"))
    pIn:AddOption("Open", function()
      local tS = self:GetStreamInfo()
      luapad.OpenTab(tS.Path)
    end):SetImage(luapad.ToIcon("folder_page"))
    pIn:AddOption("Save", function()
      luapad.SaveScript(self)
    end):SetImage(luapad.ToIcon("disk"))
    pIn:AddOption("Save As", function()
      luapad.SaveAsScript(self)
    end):SetImage(luapad.ToIcon("page_save"))
    pIn:AddOption("Delete", function()
      luapad.DeleteScript(self)
    end):SetImage(luapad.ToIcon("page_delete"))
    -- Refresh a tab
    local pIn, pOp = pMenu:AddSubMenu("Refresh")
    pOp:SetIcon(luapad.ToIcon("table_refresh"))
    pIn:AddOption("This", function()
      luapad.RefreshTabView(self)
    end):SetImage(luapad.ToIcon("arrow_down"))
    pIn:AddOption("Active", function()
      luapad.RefreshTabActive()
    end):SetImage(luapad.ToIcon("arrow_refresh"))
    pIn:AddOption("Right", function()
      luapad.RefreshTabRight(self)
    end):SetImage(luapad.ToIcon("arrow_right"))
    pIn:AddOption("Left", function()
      luapad.RefreshTabLeft(self)
    end):SetImage(luapad.ToIcon("arrow_left"))
    pIn:AddOption("Right (+)", function()
      luapad.RefreshTabRight(self, true)
    end):SetImage(luapad.ToIcon("arrow_turn_right"))
    pIn:AddOption("Left (+)", function()
      luapad.RefreshTabLeft(self, true)
    end):SetImage(luapad.ToIcon("arrow_turn_left"))
    pIn:AddOption("Others", function()
      luapad.RefreshTabOther(self)
    end):SetImage(luapad.ToIcon("arrow_out"))
    pIn:AddOption("All", function()
      luapad.RefreshTabAll()
    end):SetImage(luapad.ToIcon("arrow_in"))
    -- Run a script
    local pIn, pOp = pMenu:AddSubMenu("Run")
    pOp:SetIcon(luapad.ToIcon("table_go"))
    pIn:AddOption("Client", function()
      luapad.RunScriptClient()
    end):SetImage(luapad.ToIcon("user_go"))
    pIn:AddOption("Server", function()
      luapad.RunScriptServer()
    end):SetImage(luapad.ToIcon("computer_go"))
    pIn:AddOption("Shared", function()
      luapad.RunScriptClient()
      luapad.RunScriptServer()
    end):SetImage(luapad.ToIcon("building_go"))
    pIn:AddOption("Broadcast", function()
      luapad.RunScriptServerClient()
    end):SetImage(luapad.ToIcon("feed_go"))
    -- Close tabs
    local pIn, pOp = pMenu:AddSubMenu("Close")
    pOp:SetIcon(luapad.ToIcon("table_delete"))
    pIn:AddOption("This", function()
      luapad.CloseTabView(self)
    end):SetImage(luapad.ToIcon("arrow_down"))
    pIn:AddOption("Active", function()
      luapad.CloseTabActive()
    end):SetImage(luapad.ToIcon("arrow_refresh"))
    pIn:AddOption("Right", function()
      luapad.CloseTabRight(self)
    end):SetImage(luapad.ToIcon("arrow_right"))
    pIn:AddOption("Left", function()
      luapad.CloseTabLeft(self)
    end):SetImage(luapad.ToIcon("arrow_left"))
    pIn:AddOption("Right (+)", function()
      luapad.CloseTabRight(self, true)
    end):SetImage(luapad.ToIcon("arrow_turn_right"))
    pIn:AddOption("Left (+)", function()
      luapad.CloseTabLeft(self, true)
    end):SetImage(luapad.ToIcon("arrow_turn_left"))
    pIn:AddOption("Others", function()
      luapad.CloseTabOther(self)
    end):SetImage(luapad.ToIcon("arrow_out"))
    pIn:AddOption("All", function()
      luapad.CloseTabAll()
    end):SetImage(luapad.ToIcon("arrow_in"))

    -- Open menu
    pMenu:Open()
  end

  pSheet:SetActiveTab(pTab)
  pSheet:InvalidateLayout()

  return pTab
end

function luapad.IsOpen(name, path)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return false end

  local tI = pS:GetItems()
  local nI = #tI
  if(nI <= 0) then return false end

  local sPth = tostring(path or "")
  local sNam = tostring(name or "")

  if(sPth ~= "") then
    sNam = sPth .. sNam
  end

  for iD = 1, nI do
    local tP = tI[iD]
    local tS = tP.Tab:GetStreamInfo()
    local sF = tS.Path .. tS.Name
    local sN, sM = tS.Name, tS.Mark
    if(sPth ~= "") then
      if(sF == sNam) then return true end
    else
      if(sN == sNam) then return true end
      if(sM == sNam) then return true end
    end
  end; return false
end

--[[
 * Adds a new tab to the property sheet files
 * New tabs must always be opened in the data folder
 * cont > Text panel contents manipulated
 * path > The file path relative to the game folder
]]
function luapad.NewTab(cont, path)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local bB, sB, oB = luapad.GetPath(path)

  if(bB) then
    local nF = VAR_MXF:GetInt()
    local sO = sB .. BASE_FMNAME
    local tI, iF = pS:GetItems(), nil
    local sCon = tostring(cont or "")

    file.CreateDir(sB)

    for iD = 1, nF do
      local sF = sO:format(iD)
      local sN = BASE_FMNAME:format(iD)
      if (not file.Exists(sF, "DATA") and not luapad.IsOpen(sN)) then
        iF = iD
        break
      end
    end

    if(iF) then -- Index is present open the file
      luapad.AddTab(BASE_FMNAME:format(iF), sCon, oB)
      luapad.SetStatus("Open the next name available!", "STAT_OK")
    else -- Rise a status bar message
      luapad.SetStatus("There are more than [%s] files in [%s] origin! (clean the folder)", "STAT_ER", nF, oB)
    end
  else
    luapad.SetStatus("Creating a file here [%s] is not allowed!", "STAT_WR", oB)
  end
end

--[[
 * Adds a new tab relative to the active tab path
]]
function luapad.NewTabActive()
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local aT = pS:GetActiveTab()
  if(not IsValid(aT)) then return end

  local tS = aT:GetStreamInfo()
  if(not (tS and tS.Path)) then return end

  luapad.NewTab(nil, tS.Path)
end

--[[
 * Every request is relative to the main game folder
 * Paths starting with `data/` use the `data` folder
 * This is done so that the file can be reloaded properly
 * Otherwise it will just read the game file system where
 * the content is refreshed during the game startup
]]
function luapad.OpenTree()
  local pSheet = luapad.PropertySheet
  if(not IsValid(pSheet)) then return end

  if (luapad.BrowserTree) then
    local pB = luapad.BrowserTree
    if(IsValid(pB)) then pB:Remove() end
    luapad.BrowserTree = nil
  end

  local nX, nY = pSheet:GetPos()
  local nW, nH = pSheet:GetSize()

  luapad.BrowserTree = vgui.Create("DTree", luapad.Frame)
  luapad.BrowserTree:SetPadding(5)
  luapad.BrowserTree:SetPos(nX + (nW - nW / 4), nY + 22)
  luapad.BrowserTree:SetSize(nW / 4, nH - 23)

  local nW, nH = luapad.BrowserTree:GetSize()
  local pClose = vgui.Create("DButton", luapad.BrowserTree)
  pClose:SetPos(nW - 65, 4)
  pClose:SetSize(45, 22)
  pClose:SetText(">")
  pClose:SetTooltip("Close")

  function pClose:DoClick()
    luapad.BrowserTree:Remove()
  end

  function luapad.BrowserTree:PopulateNode(pNode, sPath, tConf, iStag)
    local iStag = math.floor(tonumber(iStag) or 0)
    if(iStag <= 0) then return end
    -- Recursion guard has passed. Generate stage
    local tF, tD = file.Find(sPath .. "*", "GAME", "nameasc")
    if(not (tF or tD)) then return end
    -- Folders
    if(tD) then
      for iD = 1, #tD do
        local sD = tD[iD]
        local pC = pNode:AddNode(sD, luapad.ToIcon("folder"))
              pC.DirPath = sPath .. sD .. "/"
              pC:SetTooltip(pC.DirPath)
        -- Click a folder
        function pC:DoClick()
          local bEx = pC:GetExpanded()
          if(input.IsKeyDown(KEY_LSHIFT)) then
            pC:ExpandRecurse(not bEx)
          else
            pC:SetExpanded(not bEx)
          end
        end
        function pC:DoMiddleClick()
          local bEx = pC:GetExpanded()
          pC:ExpandRecurse(not bEx)
        end
        function pC:DoRightClick()
          SetClipboardText(pC.DirPath)
        end
        -- Expand the folder when clicked wherever
        pC.Expander.DoClick       = pC.DoClick
        pC.Expander.DoMiddleClick = pC.DoMiddleClick
        pC.Expander.DoRightClick  = pC.DoRightClick
        -- Use this as base and attach the rest
        self:PopulateNode(pC, pC.DirPath, tConf, iStag - 1)
      end
    end
    -- Files
    if(tF) then
      for iF = 1, #tF do
        local sF = tF[iF]
        local sE = string.GetExtensionFromFilename(sF)
        local tE = ENABLE_EXTENS[sE] -- Extension
        if(tE) then
          local sI = luapad.ToIcon(tE.Icon or "page")
          local pC = pNode:AddNode(sF, sI)
          pC.DirPath, pC.IsFile = sPath, true
          pC:SetTooltip(sF)
          -- Click a file
          function pC:DoClick()
            if(not self.IsFile) then return end
            local sD, sF = self.DirPath, self:GetText()
            if(luapad.IsOpen(sF, sD)) then return end
            local sE = string.GetExtensionFromFilename(sF)
            local tE = (sE and ENABLE_EXTENS[sE] or nil)
            local sI = (tE and tE.Icon or nil)
            local bB, sB = luapad.GetPath(sD)
            if(bB) then -- The contents in the data folder are refreshed on write
              luapad.AddTab(sF, file.Read(sB .. sF, "DATA"), sD, nil, sI)
            else -- Every other folder could not be refreshed but read
              luapad.AddTab(sF, file.Read(sD .. sF, "GAME"), sD, nil, sI)
            end
          end
          function pC:DoRightClick()
            local sD, sF = self.DirPath, self:GetText()
            SetClipboardText(sD .. sF)
          end
          pC.DoDoubleClick = pC.DoClick
        end
      end
    end
  end

  function luapad.BrowserTree:PopulateTree(sName, sIco)
    local sName = string.Trim(sName, "/")
    local pRoot = self:AddNode(sName)
    if (not IsValid(pRoot)) then return end

    -- Check of the leading folder is enabled
    local sSors = string.match(sName, "^([^/\\]+)", 1)
    local tConf = ENABLE_FOLDER[sSors]
    if(not tConf) then return end

    pRoot.Icon:SetImage(luapad.ToIcon((sIco or tConf.Icon) or "computer"))

    self:PopulateNode(pRoot, sName .. "/", tConf, VAR_MXR:GetInt())
  end

  return luapad.BrowserTree
end

function luapad.OpenTab(path)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local pB = luapad.OpenTree()
  if(not IsValid(pB)) then return end

  local tI = pS:GetItems()

  if(path ~= nil) then
    local bB, sB, oB = luapad.GetPath(path)
    pB:PopulateTree(oB)
    luapad.SetStatus("Origin is %s. Using [%s] as base folder.", "STAT_OK", "provided", oB)
  elseif(#tI == 0) then -- No active tab is present and path is empty
    pB:PopulateTree("data")
    luapad.SetStatus("Origin is %s. Using [%s] as base folder.", "STAT_OK", "/data", "default")
  else -- If editor is not empty there will always be an active tab
    local aT = pS:GetActiveTab()
    if(not IsValid(aT)) then return end
    local tS = aT:GetStreamInfo()
    pB:PopulateTree(tS.Path)
    luapad.SetStatus("Origin is %s. Using [%s] as base folder.", "STAT_OK", tS.Path, "active tab")
  end
end

function luapad.OpenBrowse()
  local tK = table.GetKeys(ENABLE_FOLDER)
  table.sort(tK, function(u, v)
    local ru = ENABLE_FOLDER[u]
    local rv = ENABLE_FOLDER[v]
    return (ru.ID < rv.ID)
  end)
  local pMenu = DermaMenu()
  if(not IsValid(pMenu)) then return end
  pMenu:SetPos(gui.MousePos())
  local uI = "computer"
  for iD = 1, #tK do
    local sD = tK[iD]
    local sU = sD:gsub("^%l", string.upper)
    local sI = (ENABLE_FOLDER[sD].Icon or uI)
    pMenu:AddOption(sU, function()
      local pB = luapad.OpenTree()
      if(not IsValid(pB)) then return end
      pB:PopulateTree(sD)
    end):SetImage(luapad.ToIcon(sI))
  end
end

function luapad.SaveScript(pTre)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local pT = (pTre or pS:GetActiveTab())
  if(not IsValid(pT)) then return end

  local iT = pS:GetTabIndex(pT)
  if(not iT) then return end

  local tS = pT:GetStreamInfo()
  local sD, sN = tS.Path, tS.Name

  local bB, sB, oB = luapad.GetPath(sD)

  if(bB) then
    if(not canOperateIn(oB)) then
      luapad.SetStatus("File [%s%s] save failed! (origin is restricted)", "STAT_ER", oB, sN)
      return
    end

    local sF, sC = (sB .. sN), (pT:GetContents() or "")

    if (not file.Exists(sF, "DATA")) then
      luapad.SaveAsScript()
    else
      if (table.HasValue(RESTRICTED_FILES, oB .. sN)) then
        luapad.SetStatus("File [%s%s] save failed! (file is restricted)", "STAT_ER", oB, sN)
        return
      end

      file.Write(sF, sC)

      if file.Exists(sF, "DATA") then
        luapad.SetStatus("File [%s%s] successfully saved!", "STAT_OK", oB, sN)
      else
        luapad.SetStatus("File [%s%s] save failed! (check your filename)", "STAT_ER", oB, sN)
      end
    end
  else
    luapad.SetStatus("File [%s%s] cannot be overwritten!", "STAT_WR", oB, sN)
  end
end

function luapad.SaveAsScript(pTre)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local pT = (pTre or pS:GetActiveTab())
  if(not IsValid(pT)) then return end

  local iT = pS:GetTabIndex(pT)
  if(not iT) then return end

  local tS = pT:GetStreamInfo()

  luapad.ShowConfirmDialog(
    "You are about to save a file, please enter the desired filename.",
    tS.Path .. tS.Name,

    function(sName)
      if (table.HasValue(RESTRICTED_FILES, sName)) then
        luapad.SetStatus("File [%s] save failed! (file is restricted)", "STAT_ER", sName)
        return
      end

      local sD = string.GetPathFromFilename(sName)
      local sN = string.GetFileFromFilename(sName)
      local bB, sB, oB = luapad.GetPath(sD)

      if(bB) then
        if(not canOperateIn(oB)) then
          luapad.SetStatus("File [%s%s] save failed! (origin is restricted)", "STAT_ER", oB, sN)
          return
        end

        local sF, sC = (sB .. sN), (pT:GetContents() or "")

        file.CreateDir(sB)
        file.Write(sF, sC)

        if file.Exists(sF, "DATA") then
          luapad.SetStatus("File [%s%s] successfully saved!", "STAT_OK", oB, sN)
          tS.Path, tS.Name = oB, sN -- Update path and name
          pT:SetText(tS.Name)
          pS:SetActiveTab(pT)
        else
          luapad.SetStatus("File [%s%s] save failed! (check your filename)", "STAT_ER", oB, sN)
        end
      else
        luapad.SetStatus("File [%s%s] cannot be overwritten!", "STAT_WR", oB, sN)
      end
    end, nil, "Save", "Cancel"
  )
end

function luapad.SaveAll()
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local tI = pS:GetItems()
  local nI, nU = #tI, 0
  if(nI <= 0) then return end

  for iT = 1, nI do
    local cT = tI[iT].Tab
    if(IsValid(cT)) then
      local sD, sN = tS.Path, tS.Name
      local bB, sB, oB = luapad.GetPath(sD)
      if(bB) then
        if(not canOperateIn(oB)) then
          luapad.SetStatus("File [%s%s] save failed! (origin is restricted)", "STAT_ER", oB, sN)
          return
        end
        local sF, sC = (sB .. sN), (pT:GetContents() or "")
        file.CreateDir(sB); file.Write(sF, sC)
        if(file.Exists(sF, "DATA")) then
          nU = nU + 1
        else
          luapad.SetStatus("File [%s%s] save failed! Processed [%s] of [%s] tabs!", "STAT_ER", oB, sN, nU, nI)
          return -- First unsuccessful file
        end
      end
    end
  end

  -- In case the loop is executed
  if(nU <= 0) then -- All tabs are not from the data folder
    luapad.SetStatus("No tabs have been saved (check the origin access rights)!", "STAT_WR")
  else -- Not every tab may be from the data folder
    luapad.SetStatus("Saved successfully [%s] of [%s] tabs!", "STAT_OK", nU, nI)
  end
end

--[[
 * Delete the associated file with a given tab
 * Tab reference to be deleted. Defaults to active
]]
function luapad.DeleteScript(pTre)
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local pT = (pTre or pS:GetActiveTab())
  if(not IsValid(pT)) then return end

  local iT = pS:GetTabIndex(pT)
  if(not iT) then return end

  local tS = pT:GetStreamInfo()

  luapad.ShowConfirmDialog(
    "Confirm deletion of the file: ".. tS.Path .. tS.Name, nil,
    function()
      local sD, sN = tS.Path, tS.Name
      local bB, sB, oB = luapad.GetPath(sD)

      if(bB) then

        if(not canOperateIn(oB)) then
          luapad.SetStatus("File [%s%s] delete failed! (origin is restricted)", "STAT_ER", oB, sN)
          return
        end

        local sF = (sB .. sN)

        if (not file.Exists(sF, "DATA")) then
          luapad.SetStatus("File [%s%s] already missing!", "STAT_WR", oB, sN)
          return
        else
          if (table.HasValue(RESTRICTED_FILES, oB .. sN)) then
            luapad.SetStatus("File [%s%s] delete failed! (file is restricted)", "STAT_ER", oB, sN)
            return
          end

          if file.Delete(sF) then
            luapad.SetStatus("File [%s%s] successfully deleted!", "STAT_OK", oB, sN)
          else
            luapad.SetStatus("File [%s%s] delete failed (check your filename)! ", "STAT_ER", oB, sN)
          end
        end
      else
        luapad.SetStatus("File [%s%s] cannot be deleted!", "STAT_WR", oB, sN)
      end
    end, nil, "Delete", "Cancel"
  )
end

function luapad.RunScriptClient()
  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local aT = pS:GetActiveTab()
  if(not IsValid(aT)) then return end

  local sC = aT:GetContents()
  local bS, sE = pcall(RunString, sC)
  if bS then
    luapad.SetStatus("Code ran successfully!", "STAT_OK")
  else
    luapad.SetStatus("Runtime error: %s", "STAT_ER", sE)
  end
end

function luapad.RunScriptClientFromServer(script)
  local bS, sE = pcall(RunString, script)
  if bS then
    luapad.SetStatus("Code ran successfully!", "COMS_OK")
  else
    luapad.SetStatus("Runtime error: %s", "COMS_ER", sE)
  end
end

function luapad.RunScriptServer()
  if SERVER or not canUserAccess(LocalPlayer()) then
    return
  end

  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local aT = pS:GetActiveTab()
  if(not IsValid(aT)) then return end

  local sC, bA = aT:GetContents()

  net.Receive("luapad.UploadCallback", function() bA = true end)

  net.Start("luapad.Upload")
  net.WriteString(sC)
  net.SendToServer()

  luapad.SetStatus("Upload to server completed! (check server console for errors)", "COMS_OK")

  if (bA) then
    luapad.SetStatus("Upload accepted, now uploading...", "COMS_OK")
  else
    luapad.SetStatus("Upload denied by server! (maybe you are not an admin)", "COMS_ER")
  end
end

function luapad.RunScriptServerClient()
  if SERVER or not canUserAccess(LocalPlayer()) then
    return
  end

  local pS = luapad.PropertySheet
  if(not IsValid(pS)) then return end

  local aT = pS:GetActiveTab()
  if(not IsValid(aT)) then return end

  local sC, bA = aT:GetContents()

  net.Receive("luapad.UploadClientCallback", function() bA = true end)

  net.Start("luapad.UploadClient")
  net.WriteString(sC)
  net.SendToServer()

  luapad.SetStatus("Upload to client completed! (check server console for errors)", "COMS_OK")

  if (bA) then
    luapad.SetStatus("Upload accepted, now uploading...", "COMS_OK")
  else
    luapad.SetStatus("Upload denied by server! (maybe you are not an admin)", "COMS_ER")
  end
end

function luapad.RunScriptMenu()
  local pMenu = DermaMenu()
  if(not IsValid(pMenu)) then return end
  pMenu:SetPos(gui.MousePos())
  -- Run a script
  pMenu:AddOption("Client", function()
    luapad.RunScriptClient()
  end):SetImage(luapad.ToIcon("user_go"))
  pMenu:AddOption("Server", function()
    luapad.RunScriptServer()
  end):SetImage(luapad.ToIcon("server_go"))
  pMenu:AddOption("Shared", function()
    luapad.RunScriptClient()
    luapad.RunScriptServer()
  end):SetImage(luapad.ToIcon("building_go"))
  pMenu:AddOption("Broadcast", function()
    luapad.RunScriptServerClient()
  end):SetImage(luapad.ToIcon("feed_go"))
end

concommand.Add("Luapad", luapad.Toggle)
