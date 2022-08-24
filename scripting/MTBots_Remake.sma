/*

Multitrainer Bots Lite by ScriptedSnark
https://github.com/ScriptedSnark/MTBots-Lite

Adrenaline Gamer plugin.

For AMX Mod X 1.10.

Thanks to KORD_12.7 for HL Stocks include (hl.inc), tmp64 for model render fix advice.

*/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <hl>

#define PLUGIN	"Multitrainer Bots Lite"
#define AUTHOR	"ScriptedSnark"
#define VERSION	"0.9b"

new is_bot[32]
new origin_resp[3], origin_fix[3]
new bot_model[32], bot_name[32], name[32]
new players[32], inum, player


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say /bot", "MTBot_Make")
	register_clcmd("say /remove", "MTBot_Remove")
	RegisterHam(Ham_Killed, "player", "MTBot_BotDeath", 1);
	RegisterHam(Ham_Spawn, "player", "MTBot_AGRespawn", 1);
	RegisterHam(Ham_TakeDamage, "player", "BotTakeDamage");
	register_message(get_user_msgid("Vote"), "AutoVote")
}

public plugin_precache()
{
	precache_sound("vox/destroyed.wav")
}

public plugin_cfg()
{
	config_load()
}

public get_bot_spawn(id)
{
}

public MTBot_Make(id)
{
	if (hl_get_user_spectator(id))
	{
		client_print(id, print_chat, "[MTBots-Lite] You can't create a bot when you are a spectator!")
		return PLUGIN_HANDLED;
	}

	new playername[32]
	get_user_name(id, playername, charsmax(playername))

	formatex(name, 255, "%s %d", bot_name, random_num(100, 300)) 
	new id_bot = engfunc(EngFunc_CreateFakeClient, name)
	
	if(!id_bot) {
		client_print(id, print_chat, "[MTBots-Lite] A bot can't join! This server may be full.")
	}

	if(pev_valid(id_bot)) {
		engfunc(EngFunc_FreeEntPrivateData, id_bot)
		dllfunc(MetaFunc_CallGameEntity, "player", id_bot)
		set_user_info(id_bot, "rate", "3500")
		set_user_info(id_bot, "cl_updaterate", "25")
		set_user_info(id_bot, "cl_lw", "1")
		set_user_info(id_bot, "cl_lc", "1")
		set_user_info(id_bot, "cl_dlmax", "128")
		set_user_info(id_bot, "_ah", "0")
		set_user_info(id_bot, "dm", "0")
		set_user_info(id_bot, "tracker", "0")
		set_user_info(id_bot, "friends", "0")
		set_user_info(id_bot, "*bot", "1" )
		hl_set_user_team(id_bot, bot_model)
		set_pev(id_bot, pev_flags, pev( id_bot, pev_flags ) | FL_FAKECLIENT)
		set_pev(id_bot, pev_colormap, id_bot)
		set_pev(id_bot, pev_gravity, 1.0)
		set_pev(id_bot, pev_health, 100)
		set_pev(id_bot, pev_weapons, 0)
		set_user_gravity(id_bot, 1.0)
		dllfunc(DLLFunc_ClientConnect, id_bot, "bot", "127.0.0.1")
		dllfunc(DLLFunc_ClientPutInServer, id_bot)
		engfunc(EngFunc_RunPlayerMove, id_bot, Float:{0.0,0.0,0.0}, 0.0, 0.0, 0.0, 0, 0, 76)
		set_pev(id_bot, pev_velocity, Float:{0.625,-235.5,0.0})
		engfunc(EngFunc_RunPlayerMove, id_bot, Float:{20.4425,270.4504,0.0}, 250.0, 0.0, 0.0, 0, 8, 10)
		pev(id_bot, pev_origin, 1.0)
		pev(id_bot, pev_velocity, 320.0)
		hl_user_spawn(id_bot)
		engfunc(EngFunc_DropToFloor, id_bot)
		set_pev(id_bot, pev_effects, (pev(id_bot, pev_effects) | 1 ))
		set_pev(id_bot, pev_solid, SOLID_BBOX)
		set_user_rendering(id_bot, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 100)

		if (hl_get_user_spectator(id_bot))
		{
			client_print(id, print_chat, "[MTBots-Lite] You can't create a bot when match is started!")
			server_cmd("kick #%i", get_user_userid(id_bot))
		}
		else
		{
			client_print(0, print_chat, "[MTBots-Lite] %s^^0 created a bot.", playername)
			get_bot_spawn(id_bot)
		}
	}

	return PLUGIN_CONTINUE;
}

public BotTakeDamage(victim, inflictor, attacker, Float:dmg, dmgbits)
{
}

public MTBot_BotDeath(id) {
	get_user_info(id, "*bot", is_bot, 255)
	if (str_to_num(is_bot) != 0 && !hl_get_user_spectator(id)) {
		set_task(1.1, "MTBot_Respawn", id)
	}
}

public MTBot_AGRespawn(id)
{
    get_user_info(id, "*bot", is_bot, 255)
    if (str_to_num(is_bot) != 0) {
	    engfunc(EngFunc_DropToFloor, id)
	}
}

public MTBot_Respawn(id)
{
	origin_fix[0] = 1000
	origin_fix[1] = -5000
	origin_fix[2] = 8100
	
	hl_user_spawn(id)
	get_bot_spawn(id)
	get_user_origin(id, origin_resp, 0)
	set_task(0.05, "MTBot_FixRender", id)
	set_user_origin(id, origin_fix)
}

public MTBot_FixRender(id)
{
	set_user_origin(id, origin_resp)
	engfunc(EngFunc_DropToFloor, id)
}

public AutoVote(id)
{
	get_players(players, inum)
	
	for(new i; i < inum; i++) {
		player = players[i]

		if(!is_user_connected(players[i]))
            return PLUGIN_HANDLED;

		get_user_info(players[i], "*bot", is_bot, 255)
		if (str_to_num(is_bot) != 0) {
		    engclient_cmd(players[i], "yes")
		}  
	}

	return PLUGIN_CONTINUE;
}

public MTBot_Remove(id)
{
	get_players(players, inum)

	client_cmd(0, "spk vox/destroyed.wav")
	
	for(new i; i < inum; i++) {
		player = players[i]
		get_user_info(player, "*bot", is_bot, 255)
		if (str_to_num(is_bot) != 0) {
			server_cmd("kick #%i", get_user_userid(players[i]))
		}
	}
}

config_load() {		
	static path[64]
	get_localinfo("amxx_configsdir", path, charsmax(path))
	format(path, charsmax(path), "%s/mtbots-lite.ini", path)
    
	if (!file_exists(path)) {
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
		set_fail_state(error)
		return
	}
    
	static linedata[128], key[64], value[32]
	new file = fopen(path, "rt")
    
	while (file && !feof(file)) {
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
       
		if (!linedata[0] || linedata[0] == '/') continue;
       
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
		trim(key)
		trim(value)
		
		if (equal(key, "MODEL"))
		    bot_model = value
		else if (equal(key, "NAME_BOT"))
		    bot_name = value
	}
	if (file) fclose(file)
}
