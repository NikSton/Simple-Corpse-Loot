CorpseLoot = CorpseLoot or {}
include("corpseloot/sh_config.lua")
if SERVER then
	AddCSLuaFile("corpseloot/sh_config.lua")
	AddCSLuaFile("corpseloot/cl_init.lua")
	include("corpseloot/sv_init.lua")
else
	include("corpseloot/cl_init.lua")
end