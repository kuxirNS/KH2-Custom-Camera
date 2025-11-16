LUAGUI_NAME = "Custom-Camera"
LUAGUI_AUTH = "kuxir"
LUAGUI_DESC = "Lua script to edit KH2 camera. Requires KH2FM-Mods-equations19/KH2-Lua-Library"

local can_edit_camera = true --set this to false if shortcuts conflict with other scripts

local function ResetCamera()

preset_default = {
Name = "Default",
FoV = 100,
Height = 85 ,
Angle = -3 ,
Kbm_Stiffness_Y = 10.0,
Pad_Stiffness_Y = 10.0,
Stiffness_X = 10,
Swivel_X_Speed = 10.0,
AutoCam_Speed = 10.0
}
preset_optimized = {
Name = "Optimized",
FoV = 114,
Height = 85 ,
Angle = -3 ,
Kbm_Stiffness_Y = 10.0,
Pad_Stiffness_Y = 11.0,
Stiffness_X = 11,
Swivel_X_Speed = 11.0,
AutoCam_Speed = 11.5
}
preset_kh1 = {
Name = "KH1",
FoV = 94 ,
Height = 62 ,
Angle = -3 ,
Kbm_Stiffness_Y = 10.0,
Pad_Stiffness_Y = 13.0,
Stiffness_X = 9,
Swivel_X_Speed = 10.0,
AutoCam_Speed = 10.0
}
preset_moba = {
Name = "Moba",
FoV = 100,
Height = 180,
Angle = 5 ,
Kbm_Stiffness_Y = 10.0,
Pad_Stiffness_Y = 7,
Stiffness_X = 7 ,
Swivel_X_Speed = 11.0,
AutoCam_Speed = 8.0
}
preset_casual = {
Name = "Casual",
FoV = 100,
Height = 80 ,
Angle = -3 ,
Kbm_Stiffness_Y = 10.0,
Pad_Stiffness_Y = 12.0,
Stiffness_X = 8 ,
Swivel_X_Speed = 11.0,
AutoCam_Speed = 10.0
}
end

function _OnInit()
	ResetCamera()
	Preset = preset_default
	
	kh2libstatus, kh2lib = pcall(require, "kh2lib")
	if not kh2libstatus then
		print("ERROR (Custom Camera): KH2-Lua-Library mod is not installed")
		CanExecute = false
		return
	end
	Log("Camera Settings 1.0.0")
	RequireKH2LibraryVersion(2)
	RequirePCGameVersion()
	GameVersion = kh2lib.GameVersion
	GameVersionString = kh2lib.GameVersionString
	Input = kh2lib.Input
	Timer = kh2lib.Timer
	CamTyp = kh2lib.CamTyp
	NextFrame = 0
	NextLog = 0
	bAllowEdit = can_edit_camera
	CanExecute = kh2lib.CanExecute
	if not CanExecute then
		return
	end
	VersionCheck()
	if not CanExecute then
		return
	end
	ApplyPreset(Preset)
	LogCamera("shortcuts")
end

function ApplyPreset(param)
	Camera = param
	NewFoV = Camera.FoV*0.015
	NewHeight = Camera.Height*2
	NewAngle = Camera.Angle*50
	NewKbm_Stiffness_Y = Camera.Kbm_Stiffness_Y*0.04
	NewPad_Stiffness_Y = Camera.Pad_Stiffness_Y*0.007
	NewStiffness_X = Camera.Stiffness_X*0.003
	NewSwivel_X_Speed = Camera.Swivel_X_Speed*0.005235987902
	NewAutoCam_Speed = Camera.AutoCam_Speed*0.0004363323096
--
	WriteFloat(HeightAddr, NewHeight)
	WriteFloat(HeightAddr+0x0564, -NewHeight)
	WriteFloat(AngleAddr, NewAngle)
	WriteFloat(AngleAddr+0x0564, NewAngle*1.4666666666666)
	WriteFloat(Kbm_Stiff_Y_Addr, NewKbm_Stiffness_Y)
	WriteFloat(Pad_Stiff_Y_Addr, NewPad_Stiffness_Y)
	WriteFloat(Stiff_X_Addr, NewStiffness_X)
--
	LogCamera("all")
end

function VersionCheck()
	local offset
	if GameVersion == 0x020A then
	offset = 0x0
	elseif GameVersion == 0x030A then
	offset = 0x01C0
	else
		LogError(GameVersionString.." is not implemented")
		CanExecute = false
		return
	end
	HeightAddr = 0x5B1F50-offset
	AngleAddr = 0x5B1F54-offset
	Kbm_Stiff_Y_Addr = 0x5B1F4C-offset
	Pad_Stiff_Y_Addr = 0x5B1F48-offset
	Stiff_X_Addr = 0x5B1F44-offset
	LogSuccess("Using addresses for "..GameVersionString)
end

function LogCamera(param)
local switch = param
	if switch == "all" then
		Log(" ")
		LogMessage(Camera.Name.." Preset Applied")
		Log("Field of View "..Camera.FoV)
		Log("Height "..Camera.Height)
		Log("Angle "..Camera.Angle)
		Log("Mouse CameraY Stiffness "..Camera.Kbm_Stiffness_Y)
		Log("Controller CameraY Stiffness "..Camera.Pad_Stiffness_Y)
		Log("CameraX Stiffness "..Camera.Stiffness_X)
		Log("Controller SwivelX Speed "..Camera.Swivel_X_Speed)
		Log("AutoCam Speed "..Camera.AutoCam_Speed)
		Log(" ")
		return
	elseif switch == "shortcuts" then
		LogMessage([[Shortcuts 
[Hold L1+R3] Edit

      Left   -  FoV   +   Right
      Down   - Height +    Up            L3 Reset to Default
       L2    - Angle  +    R2

[Hold L1+R1] Presets

              Up   'Casual'
             Down  'Moba'
             Right 'KH1'                 L3 Reset to Default
             Left  'Optimized'
]])
		return
	elseif ReadInt(Timer) < NextLog then
		return
		
	elseif switch == "fov" then
		Log("<EDIT> Field of View "..Camera.FoV)
		NextLog = ReadInt(Timer)+15
		return
		
	elseif switch == "height" then
		Log("<EDIT> Height "..Camera.Height)
		NextLog = ReadInt(Timer)+15
		return
		
	elseif switch == "angle" then
		Log("<EDIT> Angle "..Camera.Angle)
		NextLog = ReadInt(Timer)+15
		return
		
	elseif switch == "preset" then
		Log("Loaded Preset  "..Camera.Name)
		NextLog = ReadInt(Timer)+15
		return
		
	end
end

local function ChangeFoV(param)
local switch = param
	if 0 <= Camera.FoV and Camera.FoV < 200 then
		
		if switch == "decr" then
			Camera.FoV = Camera.FoV - 2
		
		elseif switch == "incr" then
			Camera.FoV = Camera.FoV + 2
			
		end
		
		if ReadByte(CamTyp-0x04) == 1 then-----small room
			NewFoV = Camera.FoV*0.0104
		else
			NewFoV = Camera.FoV*0.015
		end
		LogCamera("fov")
		return
		
	else
		Camera.FoV = 100
		return
	end
end

local function ChangeHeight(param)
local switch = param
	if -50 <= Camera.Height and Camera.Height < 200 then
		
		if switch == "decr" then
			Camera.Height = Camera.Height - 2.5
			
		elseif switch == "incr" then
			Camera.Height = Camera.Height + 2.5
			
		end
		
		NewHeight = Camera.Height*2
		LogCamera("height")
		return
		
	else
		Camera.Height = 85
		return
	end
end

local function ChangeAngle(param)
local switch = param
	if -13 <= Camera.Angle and Camera.Angle < 7 then
		
		if switch == "decr" then
			Camera.Angle = Camera.Angle - 0.1
			
		elseif switch == "incr" then
			Camera.Angle = Camera.Angle + 0.1
			
		end
		
		NewAngle = Camera.Angle*50
		LogCamera("angle")
		return
		
	else
		Camera.Angle = -3
		return
	end
end

local function SetNextFrame(num)
	NextFrame = ReadInt(Timer)+num
end

local function Update()
	if ReadByte(CamTyp) == 2 then-------LockON
		WriteFloat(CamTyp-0x10, NewFoV)
	else
		WriteFloat(CamTyp+0x98, NewFoV)
	end
	WriteFloat(CamTyp-0xB8, NewSwivel_X_Speed)
	WriteFloat(CamTyp-0xC0, NewAutoCam_Speed)
end

function _OnFrame()
	if ReadInt(Timer) < NextFrame then
		return
	end
	if not CanExecute then
		return
	end
	
	if ReadByte(CamTyp-0x04) == 1 then-----small room
		NewFoV = Camera.FoV*0.0104
	else
		NewFoV = Camera.FoV*0.015
	end
	Update()
	SetNextFrame(8)
	if bAllowEdit then
		---------------Hold R3+L1---------------
		if ReadByte(Input + 0x02) == 0x82 then
			SetNextFrame(1)
			if ReadByte(Input + 0xD0) == 0x14 then
				ChangeHeight("incr")
				WriteFloat(HeightAddr, NewHeight)
				WriteFloat(HeightAddr+0x0564, -NewHeight)
				SetNextFrame(7)
				return
				
			elseif ReadByte(Input + 0xD0) == 0x44 then
				ChangeHeight("decr")
				WriteFloat(HeightAddr, NewHeight)
				WriteFloat(HeightAddr+0x0564, -NewHeight)
				SetNextFrame(7)
				return
				
			elseif ReadByte(Input + 0xD0) == 0x24 then
				ChangeFoV("incr")
				SetNextFrame(7)
				Update()
				return
				
			elseif ReadByte(Input + 0xD0) == 0x06 then
				ResetCamera()
				ApplyPreset(preset_default)
				SetNextFrame(30)
				Update()
				return
				
			elseif ReadByte(Input + 0x04) == 0x0D then
				ChangeAngle("incr")
				WriteFloat(AngleAddr, NewAngle)
				WriteFloat(AngleAddr+0x0564, NewAngle*1.4666666666666)
				SetNextFrame(7)
				Update()
				return
				
			end
		elseif ReadByte(Input + 0x02) == 0x83 and ReadByte(Input + 0xD0) == 0x84 then
			ChangeFoV("decr")
			SetNextFrame(7)
			Update()
			return
		elseif ReadByte(Input + 0x02) == 0x80 or ReadByte(Input + 0x02) == 0x81 then
			SetNextFrame(1)
			if ReadByte(Input + 0x04) == 0x06 then
				ChangeAngle("decr")
				WriteFloat(AngleAddr, NewAngle)
				WriteFloat(AngleAddr+0x0564, NewAngle*1.4666666666666)
				SetNextFrame(7)
				Update()
				return
				---------------L1+R1---------------
			elseif ReadByte(Input + 0x04) == 0x0C then
				if ReadByte(Input + 0xD0) == 0x10 then
					ResetCamera()
					ApplyPreset(preset_optimized)
					SetNextFrame(30)
					Update()
					return
					
				elseif ReadByte(Input + 0xD0) == 0x20 then
					ResetCamera()
					ApplyPreset(preset_kh1)
					SetNextFrame(30)
					Update()
					return
					
				elseif ReadByte(Input + 0xD0) == 0x40 then
					ResetCamera()
					ApplyPreset(preset_moba)
					SetNextFrame(30)
					Update()
					return
					
				elseif ReadByte(Input + 0xD0) == 0x02 then
					ResetCamera()
					ApplyPreset(preset_default)
					SetNextFrame(30)
					Update()
					return
					
				elseif ReadByte(Input + 0xD0) == 0x80 then
					ResetCamera()
					ApplyPreset(preset_casual)
					SetNextFrame(30)
					Update()
					return
				end
			end
		end
	end
end