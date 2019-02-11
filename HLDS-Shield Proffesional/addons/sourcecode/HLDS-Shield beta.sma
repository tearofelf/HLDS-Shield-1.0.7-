#if defined PrefixProtection
#else
#define PrefixProtection "[HLDS-Shield]"
#include <HLDS_Shield_function.hlds>
#endif

/*03/05/2018 
HLDS_Shield_func(index,print,msg[],emit,log,pedeapsa)
index - id = jucator , 0 nimic
print - 1..3 , 0 nu este nimic
emit - 1 trimite spk , 0 nu este nimic
log - de la 1 pana la 16 , 0 nu este nimic
pedeapsa - 1 kick cu sv_rejectconnection(doar daca el se afla pana in sv_connectclient)
- 2 ban cu sv_rejectconnection(doar daca el se afla pana in sv_connectclient)
- 3 un kick pentru o anume functie 
- 4 ban cu ajutorul net_adr(nu recomand folosirea pentru a bana jucatori reali , decat atacuri query/sv_connectclient balbal)
- 5 de rezerva (exact acelasi lucru ca la 3)
*/


// NOTE : add command "reload" in your server.cfg

public plugin_init(){
	Register()
	Register_Settings()
	
}
public plugin_precache(){
	is_server_compatibility()
	RegisterCvars()
	Hooks_init()
	Load_Settings()
}
public Hooks_init(){
	
	Registerforward()
	
	if(ServerVersion == 0){
		if(is_linux_server()){
			RegisterOkapiLinux()
		}
		else{
			RegisterOkapiWindows()
		}
	}
	set_task(1.0,"RegisterOrpheu")
	
}

public Registerforward(){
	
	register_forward(FM_ClientConnect,"pfnClientConnect")
	register_forward(FM_ClientUserInfoChanged,"pfnClientUserInfoChanged")
	register_forward(FM_GetGameDescription,"pfnGetGameDescription") 
	register_forward(FM_ClientCommand,"PfnClientCommand")
	register_forward(FM_ClientDisconnect,"PfnClientDisconnect")
	register_forward(FM_ClientPutInServer,"PfnClientPutInServer")
	register_forward(FM_Sys_Error,"pfnSys_Error")
	register_forward(FM_GameShutdown,"pfnSys_Error")
	
}
public RegisterCvars(){
	GameData=register_cvar("shield_gamedata","HLDS-Shield 1.0.7")
	KillBug=register_cvar("shield_kill_crash","1")
	NameBugShowMenu = register_cvar("shield_namebug_showmenu","1")
	SpectatorVguiBug = register_cvar("shield_vgui_specbug","1")
	Radio = register_cvar("shield_radio","1")
	CommandBug=register_cvar("shield_cmdbug","1")
	IlegalCmd=register_cvar("shield_ilegalcmd","1")
	NameBug=register_cvar("shield_name_bug_on_server","1")
	NameSpammer=register_cvar("shield_name_spammer","1")
	RandomSteamid=register_cvar("shield_steamid_hack","1")
	DuplicateSteamid=register_cvar("shield_steamid_duplicate","1")
	BanTime=register_cvar("shield_bantime","1")
	UnicodeName = register_cvar("shield_unicode_name_filter","1")
	CmdLimitVar = register_cvar("shield_commandlimit_filter","1")
	CmdlimitDestroy = register_cvar("shield_commandlimit_destory_file","240")
	CmdLimitMax = register_cvar("shield_commandlimit_execute","5")
	TimeNameChange = register_cvar("shield_namechange_delay_seconds","5")
	NameCharFix = register_cvar("shield_name_char_fix","1") // 1 replaced with utf8 char , 2 replaced with * for old build
	ChatCharFix = register_cvar("shield_chat_char_fix","1") // 1 replaced with utf8 char , 2 replaced with * for old build
	
	OptionSV_ConnectClient = register_cvar("shield_sv_connectclient_filter_option","1") // 1 - force return 2 - kick 3 - ban
	steamidgenerate=register_cvar("shield_steamid_generate_ip","1")
	steamidhash=register_cvar("shield_steamid_hash","1")
	RconSkippingCommand=register_cvar("shield_rcon_skipping_command","1")
	SV_RconCvar=register_cvar("shield_sv_rcon","1")
	ShutdownServer = register_cvar("shield_lost_connection","0") // warning but is 1 plugin returned host_servershutdown but is possbily not work correctly server
	LostConnectionSeconds = register_cvar("shield_lost_connection_seconds","15")
	DumpConnector = register_cvar("shield_dump_sv_connectclient","0")
	HLProxyFilter = register_cvar("shield_hlproxy_allow_server","1")
	HLTVFilter = register_cvar("shield_hltv_allow_server","1")
	FakePlayerFilter = register_cvar("shield_fakeplayer_filter","1")
	PrintErrorSysError = register_cvar("shield_syserror_print","1")
	UpdateClient = register_cvar("shield_update_vgui_client","1")
	NameProtector=register_cvar("shield_name_protector_sv_connect ","1")
	Queryviewer=register_cvar("shield_query_log","0")
	VAC=register_cvar("shield_vac","1")
	MaxOverflowed=register_cvar("shield_max_overflowed","1000")
	PrintUnMunge=register_cvar("shield_printf_decrypt_munge","0")
	PrintUnknown=register_cvar("shield_printf_offset_command","0")
	ParseConsistencyResponse=register_cvar("shield_parseConsistencyResponse","1")
	SendBadDropClient=register_cvar("shield_dropclient","1")
	LimitPrintf=register_cvar("shield_printf_limit","5")
	LimitQuery=register_cvar("shield_query_limit","80")
	LimitMunge=register_cvar("shield_munge_comamnd_limit","30")
	LimitExploit=register_cvar("shield_exploit_cmd_limit","5")
	LimitImpulse=register_cvar("shield_sv_runcmd_limit","100")
	LimitResources=register_cvar("shield_sv_parseresource_limit","1")
	PauseDlfile=register_cvar("shield_dlfile_pause","1")
	LimitPrintfRcon=register_cvar("shield_rcon_limit","10")
	
	if(ServerVersion == 0){
		register_srvcmd("shield_remove_function","RegisterRemoveFunction")
	}
	register_srvcmd("shield_replace_string","RegisterReplaceString")
	register_srvcmd("shield_remove_string","RegisterRemoveString")
	register_srvcmd("shield_fake_cvar","RegisterFakeCvar")
	register_srvcmd("shield_addcmd_fake","RegisterCmdFake")
	register_srvcmd("shield_reload","Register_Settings")
	
	register_clcmd("usersid","SV_UsersID")
}

public Load_Settings(){
	new szError[64],iError;
	
	g_MaxClients = get_global_int(GL_maxClients)
	g_iPattern = regex_compile("[+]",iError,szError,charsmax(szError),"i")
	valutsteamid = nvault_open("SteamHackDetector")
	g_aArray = ArrayCreate(1) 
	g_blackList = ArrayCreate(15)
	set_task(600.0,"Destroy_Memory",_,"",_,"b",_)
	
	new getlimit = get_pcvar_num(CmdlimitDestroy)
	set_task(float(getlimit),"Destroy_Fileiplist",_,"",_,"b",_)
	
	if(get_pcvar_num(SV_RconCvar)==2){
		RconRandom()
	}
}
public SV_ForceFullClientsUpdate_api(index){
	SV_ForceFullClientsUpdate()
}

public SV_UsersID(id){
	new players[a_max], num, tempid;
	get_players(players, num)
	for (new i=0; i<num; i++){
		tempid = players[i]
		client_print(id,print_console,"|User : %s - #%d|",UserName(tempid),get_user_userid(tempid))
	}
	return PLUGIN_HANDLED
}
public client_authorized(id){
	
	if(get_pcvar_num(RandomSteamid)>0){
		Shield_CheckSteamID(id,1)
	}
	if(get_pcvar_num(DuplicateSteamid)>0){
		SV_CheckForDuplicateSteamID(id)
	}
}

public UserImpulseFalse(id){
	UserCheckImpulse[id] = 0
}
public pfnClientConnect(id){
	usercheck[id]=1
	DelaySpamBotStop[id] = get_gametime() + 5.0;
	DelaySpamBotStart[id] = 0.0
	FalseAllFunction(id)
	Info_ValueForKey_Hook(id)
	
	if(ServerVersion == 1){ // rehlds
		if(get_pcvar_num(NameProtector)>0){
			for (new i = 0x00; i < sizeof (MessageHook); i++){
				if(containi(UserName(id),MessageHook[i]) != -0x01){
					HLDS_Shield_func(0,0,namebug,0,9,1)
					SV_RejectConnection_user(id,"Rejected")
				}
			}
		}
	}
	set_task(1.0,"UserImpulseFalse",id)
	
}
public SV_ParseConsistencyResponse_fix(){
	
}
public RegisterOrpheu(){
	
	if(ServerVersion == 0){
		if(!file_exists(orpheufile5)){
			server_print("%s Injected successfully %s",PrefixProtection,orpheufile5)
			Create_Signature("SV_ForceFullClientsUpdate")
			set_task(1.0,"debug_orpheu")
		}
		else{
			memory2++
		}
		if(!file_exists(orpheufile4)){
			server_print("%s Injected successfully %s",PrefixProtection,orpheufile4)
			Create_Signature("SV_Drop_f")
			set_task(1.0,"debug_orpheu")
		}
		else{
			memory2++
		}
		if(!file_exists(orpheufile2)){
			log_to_file(settings,"%s Injected successfully %s",PrefixProtection,orpheufile2)
			Create_Signature("MSG_ReadShort")
			set_task(1.0,"debug_orpheu")
		}
		else{
			memory2++
		}
		if(!file_exists(orpheufile3)){
			log_to_file(settings,"%s Injected successfully %s",PrefixProtection,orpheufile3)
			Create_Signature("MSG_ReadLong")
			set_task(1.0,"debug_orpheu")
		}
		else{
			memory2++
		}
		if(file_exists(orpheufile1)){
			executestringhook = OrpheuRegisterHook(OrpheuGetFunction("Cmd_ExecuteString"),"Cmd_ExecuteString_Fix")
			memory2++
		}
		else{
			log_to_file(settings,"%s Injected successfully %s",PrefixProtection,orpheufile1)
			Create_Signature("Cmd_ExecuteString")
			set_task(1.0,"debug_orpheu")
		}
		if(file_exists(orpheufile7)){
			new getcvar[a_max]
			if(get_cvar_string("dp_version",getcvar,charsmax(getcvar))){
				log_to_file(settings,"%s Function SteamIDHash dont work with dproto %s",PrefixProtection,getcvar)
			}
			else{
				getidstringhook = OrpheuRegisterHook(OrpheuGetFunction("SV_GetIDString"),"SV_GetIDString_Hook",OrpheuHookPost)
				memory2++
			}
		}
		else{
			log_to_file(settings,"%s Injected successfully %s",PrefixProtection,orpheufile7)
			Create_Signature("SV_GetIDString")
			set_task(1.0,"debug_orpheu")
		}
	}
	if(is_linux_server()){
		log_to_file(settings,"^n%s I loaded plugin with %d functions hooked in hlds [linux]^n",PrefixProtection,memory2)
	}
	else{
		log_to_file(settings,"^n%s I loaded plugin with %d functions hooked in hlds [windows]^n",PrefixProtection,memory2)
	}
	
	
	new AMXXVersion[a_max],RCONName[a_max],ServerInfo[a_max],Metamodinfo[a_max],get[a_max]
	
	get_amxx_verstring(AMXXVersion,charsmax(AMXXVersion))
	get_cvar_string("rcon_password",RCONName,charsmax(RCONName))
	get_cvar_string("sv_version",ServerInfo,charsmax(ServerInfo))
	get_cvar_string("metamod_version",Metamodinfo,charsmax(Metamodinfo))
	get_plugin(-1,get,charsmax(get))
	
	server_print("--------------------------------------------------------------------------------------")
	server_print("%s Amxx : %s",PrefixProtection,AMXXVersion)
	server_print("%s Plugin : %s",PrefixProtection,get)
	server_print("%s Rcon : %s",PrefixProtection,RCONName)
	server_print("%s Engine : %s",PrefixProtection,ServerInfo)
	server_print("%s MetaMod : %s",PrefixProtection,Metamodinfo)
	SV_UpTime(1)
	server_print("--------------------------------------------------------------------------------------")
}


public Cmd_ExecuteString_Fix()
{
	//all commands is blocked sended by sv_rcon
	if(get_pcvar_num(RconSkippingCommand)>0){
		if(cmpStr3(Argv3())){
			log_to_file(settings,"%s Cmd_ExecuetString : blocked this command ^"%s^"",PrefixProtection,Argv3())
			return okapi_ret_supercede
		}
	}
	if(get_pcvar_num(SV_RconCvar)==2){
		RconRandom()
	}
	if(is_linux_server()){
		if(containi(Argv3(),"say")!=-0x01 || containi(Argv3(),"say_team")!=-0x01){ 
			return okapi_ret_ignore
		}
		else{
			server_cmd("%s %s",Argv3(),Argv4())
		}
		
	}
	if(containi(Argv(),"dlfile")!=-0x01){
		return okapi_ret_ignore
	}
	else{
		new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
		if(id){
			if(get_pcvar_num(ParseConsistencyResponse)==0){
				PrintUnknown_function(id)
			}
			mungelimit[id]++
			if(!task_exists(0x01)){
				set_task(0.1,"LevFunction",id+TASK_ONE)
			}
			if(mungelimit[id] >= get_pcvar_num(LimitMunge)){
				mungelimit[id] = 0x00
				local++
				if(local >=get_pcvar_num(LimitPrintf)){
					return okapi_ret_ignore
				}
				else{
					if(is_user_connected(id)){
						HLDS_Shield_func(id,1,suspicious,1,16,1)
						if(get_pcvar_num(SendBadDropClient)>0){
							SV_Drop_function(id)
						}
					}
					return okapi_ret_supercede
				}
			}
		}
		else{
			if(get_pcvar_num(ParseConsistencyResponse)==0){
				PrintUnknown_function(id)
			}
		}
	}
	return okapi_ret_ignore
}

public plugin_cfg(){
	RegisterConfigPlugin()
}
public SV_Addip_f_Hook()
{
	holax++
	if(strlen(Argv1()) ||strlen(Argv2())){
		if(holax>=2){
			set_task(2.0,"destroy_holax")
			return okapi_ret_supercede
		}
		else{
			HLDS_Shield_func(0,0,"?",0,12,0)
		}
	}
	return okapi_ret_ignore
}

public Host_Kill_f_fix()
{
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	if(is_user_connecting(id)){
		if(get_pcvar_num(KillBug)>0){
			locala[id]++
			if(locala[id] >=get_pcvar_num(LimitExploit)){
				HLDS_Shield_func(id,0,killbug,1,0,1) // index print msg emit log pedeapsa
			}
			if(debug_s[id]==0){
				if(locala[id] == 3){
					locala[id]=1
					debug_s[id]=1
				}
			}
			if(get_pcvar_num(SendBadDropClient)>0){
				SV_Drop_function(id)
			}
			HLDS_Shield_func(id,0,killbug,1,1,0) // index print msg emit log pedeapsa
			
			return okapi_ret_supercede
		}
	}
	return okapi_ret_ignore
}
public SV_GetIDString_Hook(test)
{
	new getcvar[a_max]
	if(get_cvar_string("dp_version",getcvar,charsmax(getcvar))){
		log_to_file(settings,"%s Function SteamIDHash dont work with dproto %s",PrefixProtection,getcvar)
	}
	else{
		static buffer[a_max],encryptsteamid[34],stringadd[34],stringadd2[34]
		OrpheuGetReturn(buffer,charsmax(buffer))
		
		
		if(containi(buffer,"UNKNOWN") != -0x01 ||
		containi(buffer,"VALVE_ID_LAN") != -0x01 ||
		containi(buffer,"VALVE_ID_PENDING") != -0x01 ||
		containi(buffer,"STEAM_ID_PENDING") != -0x01 ||
		containi(buffer,"STEAM_ID_LAN") != -0x01){
			if(get_pcvar_num(steamidgenerate)>0){
				new data[net_adr],getip2[40],encryptsteamid[34]
				okapi_get_ptr_array(net_adrr(),data,net_adr)
				formatex(getip2,charsmax(getip2),"%d.%d.%d.%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
				md5(getip2, encryptsteamid)
				for (new i = 0x00; i < sizeof(AllCharString); i++){
					replace_all(encryptsteamid,charsmax(encryptsteamid),AllCharString[i],"^x00")
				}
				copy(encryptsteamid,charsmax(encryptsteamid),encryptsteamid[12]); 
				formatex(stringadd2,charsmax(stringadd2),"STEAM_0:0:%s",encryptsteamid)
				
				OrpheuSetReturn(stringadd2)
			}
		}
		else if(containi(buffer,"BOT") != -0x01 ||
			containi(buffer,"HLTV") != -0x01){
			return 1
		}
		else{
			if(get_pcvar_num(steamidhash)>0){
				md5(buffer, encryptsteamid)
				for (new i = 0x00; i < sizeof(AllCharString); i++){
					replace_all(encryptsteamid,charsmax(encryptsteamid),AllCharString[i],"^x00")
				}
				copy(encryptsteamid,charsmax(encryptsteamid),encryptsteamid[11]); 
				formatex(stringadd,charsmax(stringadd),"STEAM_0:0:%s",encryptsteamid)
				OrpheuSetReturn(stringadd)
			}
		}
	}
	return 0
}
public IsSafeDownloadFile_Hook()
{
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	limita[id]++
	if(!task_exists(0x01)){
		set_task(0.1,"Shield_ProtectionSpam",id+TASK_ONE3)
	}
	
	if(!is_linux_server()){ // only windows
		for (new i = 0x00; i < sizeof (SafeDownloadWindows); i++){
			if(containi(Args(),SafeDownloadWindows[i]) != -0x01){
				locala[id]++
				
				if(locala[id] >=get_pcvar_num(LimitExploit)){
					if(id){
						server_cmd("addip %d %s",get_pcvar_num(PauseDlfile),PlayerIP(id)) // mini pause
						return okapi_ret_supercede
					}
					else{
						HLDS_Shield_func(id,2,safefile,1,4,1)
						return okapi_ret_supercede
					}
					if(get_pcvar_num(SendBadDropClient)>0){
						if(locala[id] >=get_pcvar_num(LimitExploit)){
							SV_Drop_function(id)
						}
					}
					return okapi_ret_supercede
				}
				else{
					if(get_pcvar_num(SendBadDropClient)>0){
						if(locala[id] >=get_pcvar_num(LimitExploit)){
							SV_Drop_function(id)
						}
					}
					if(id){
						HLDS_Shield_func(id,2,safefile,1,5,1)
						return okapi_ret_supercede
					}
					else{
						HLDS_Shield_func(id,2,safefile,1,4,1)
						return okapi_ret_supercede
					}
				}
				return okapi_ret_supercede
			}
		}
	}
	for (new i = 0x00; i < sizeof (SafeDownload); i++){
		if(containi(Args(),SafeDownload[i]) != -0x01){
			locala[id]++
			
			if(locala[id] >=get_pcvar_num(LimitExploit)){
				
				if(id){
					server_cmd("addip %d %s",get_pcvar_num(PauseDlfile),PlayerIP(id)) // mini pause
					return okapi_ret_supercede
				}
				else{
					HLDS_Shield_func(id,2,safefile,1,4,1)
					return okapi_ret_supercede
				}
				if(get_pcvar_num(SendBadDropClient)>0){
					if(locala[id] >=get_pcvar_num(LimitExploit)){
						SV_Drop_function(id)
					}
				}
				return okapi_ret_supercede
			}
			else{
				if(get_pcvar_num(SendBadDropClient)>0){
					if(locala[id] >=get_pcvar_num(LimitExploit)){
						SV_Drop_function(id)
					}
				}
				if(id){
					HLDS_Shield_func(id,2,safefile,1,5,1)
					return okapi_ret_supercede
				}
				else{
					HLDS_Shield_func(id,2,safefile,1,4,1)
					return okapi_ret_supercede
				}
			}
			return okapi_ret_supercede
		}
	}
	locala[id]++
	if(is_user_connected(id) && is_user_connecting(id))
	{
		if(locala[id] >=get_pcvar_num(LimitExploit)){
			if(id){
				server_cmd("addip %d %s",get_pcvar_num(PauseDlfile),PlayerIP(id)) // mini pause
			}
			else{
				HLDS_Shield_func(id,2,safefile,1,4,1)
			}
			return okapi_ret_supercede;
		}
		else{
			if(get_pcvar_num(SendBadDropClient)>0){
				SV_Drop_function(id)
			}
			if(id){
				HLDS_Shield_func(id,2,safefile,1,5,1)
			}
			else{
				HLDS_Shield_func(id,2,safefile,1,4,1)
			}
		}
		return okapi_ret_supercede
		
	}
	
	if(cmpStr(Args())){
		locala[id]++
		if(locala[id] >=get_pcvar_num(LimitExploit)){
			server_cmd("addip %d %s",get_pcvar_num(PauseDlfile),PlayerIP(id)) // mini pause
			return okapi_ret_supercede
		}
		else{
			HLDS_Shield_func(id,0,safefile,0,5,1)
		}
		if(get_pcvar_num(SendBadDropClient)>0){
			SV_Drop_function(id)
		}
		return okapi_ret_supercede
	}
	return okapi_ret_ignore
}

public COM_UnMunge()
{
	if(get_pcvar_num(PrintUnMunge)>0){
		server_print("COM_UnMunge : %s",Argv())
	}
	return okapi_ret_ignore
}

public SV_New_f_Hook()
{
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	
	limitba[id]++
	if(limitba[id] >= get_pcvar_num(LimitExploit))
	{
		localas[id]++
		if(localas[id] >=get_pcvar_num(LimitPrintf)){
			HLDS_Shield_func(id,1,newbug,1,0,1)
			if(get_pcvar_num(SendBadDropClient)>0){
				SV_Drop_function(id)
			}
			return okapi_ret_supercede
		}
		else{
			limitba[id]=0x00
			if(!strlen(UserName(id))){
				HLDS_Shield_func(id,1,newbug,1,3,1)
				if(get_pcvar_num(SendBadDropClient)>0){
					SV_Drop_function(id)
				}
			}
			else{
				HLDS_Shield_func(id,2,newbug,1,5,1)
				if(get_pcvar_num(SendBadDropClient)>0){
					SV_Drop_function(id)
				}
			}
		}
		return okapi_ret_supercede
	}
	else{
		set_task(0.5,"sv_new_f_debug",id+TASK_ONE4)
	}
	return okapi_ret_ignore	
}

public pfnSys_Error(arg[]){
	if(get_pcvar_num(PrintErrorSysError)>0){
		log_to_file(settings,"%s I found a error in Sys_Error : (%s)",PrefixProtection,arg)
	}
}
public pfnGetGameDescription(){
	new GameDatax[200] 
	get_pcvar_string(GameData,GameDatax,charsmax(GameDatax));
	forward_return(FMV_STRING,GameDatax) 
	return FMRES_SUPERCEDE
}
public SV_Rcon_Hook()
{
	if(get_pcvar_num(SV_RconCvar) ==0 || get_pcvar_num(SV_RconCvar) ==1 || get_pcvar_num(SV_RconCvar) ==2){
		if(hola >=get_pcvar_num(LimitPrintfRcon)){
			return okapi_ret_supercede
		}
		else{
			HLDS_Shield_func(0,0,hldsrcon,0,14,0)
		}
	}
	
	if(get_pcvar_num(SV_RconCvar) ==0){
		hola++
		return okapi_ret_supercede
	}
	if(get_pcvar_num(SV_RconCvar) ==2){
		hola++
		RconRandom()
	}
	else if(get_pcvar_num(SV_RconCvar) ==1){
		hola++
		new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
		for (new i = 0x00; i < sizeof(ShieldServerCvarBlock); i++){
			if(containi(Args(),ShieldServerCvarBlock[i]) != -0x01 || containi(Argv(),ShieldServerCvarBlock[i]) != -0x01){
				new build[varmax]
				get_cvar_string("hostname",build,charsmax(build))
				if(equali(build,UserName(id))){
					if(hola >=get_pcvar_num(LimitPrintfRcon)){
						return okapi_ret_supercede
					}
					HLDS_Shield_func(0,0,ilegalcommand,0,11,0)
					return okapi_ret_supercede
				}
				else{
					locala[id]++
					if(locala[id] >=get_pcvar_num(LimitPrintf)){
						return okapi_ret_supercede
					}
					HLDS_Shield_func(0,0,ilegalcommand,0,1,0)
					return okapi_ret_supercede
				}
			}
		}
		if(get_pcvar_num(CommandBug)>0){
			for (new i = 0x00; i < sizeof(MessageHook); i++){
				if(containi(Args(),MessageHook[i])!= -0x01 || containi(Argv(),MessageHook[i])!= -0x01){
					if(id){
						locala[id]++
						if(locala[id] >=get_pcvar_num(LimitPrintf)){
							return okapi_ret_supercede
						}
						if(id){
							HLDS_Shield_func(id,1,cmdbug,1,1,0)
							return okapi_ret_supercede
						}
					}
					else{
						if(hola >=get_pcvar_num(LimitPrintf)){
							return okapi_ret_supercede
						}
						hola++
						HLDS_Shield_func(0,0,cmdbug,0,11,0)
						return okapi_ret_supercede
					}
				}
				
			}
		}
	}
	
	return okapi_ret_ignore
}
public PfnClientPutInServer(id){
	if(get_pcvar_num(UpdateClient)>0){
		SV_ForceFullClientsUpdate_api(id) // fix show players in vgui for old
	}
}
public CheckFiles(){
	if(file_size(locatie)==0){
		return PLUGIN_HANDLED
	}
	new fopendir = fopen(locatie, "rt")
	new fisierx[BUFFER_MAXIM]
	while(!feof(fopendir)){
		fgets(fopendir,fisierx,charsmax(fisierx))
		trim(fisierx)
		force_unmodified(force_exactfile, {0,0,0},{0,0,0},fisierx)
	}
	fclose(fopendir)
	return PLUGIN_CONTINUE
}
new CheckClient[33][26]

public inconsistent_file(id,const filename[], reason[64]){
	
	formatex(savefilename,charsmax(savefilename),"%s",filename)
	formatex(messagelong,charsmax(messagelong),"%s I detected suspicious file in your client , please delete file %s^n",PrefixProtection,filename)
	new fopendir = fopen(locatie, "rt")
	new fisierx[BUFFER_MAXIM]
	while(!feof(fopendir)){
		fgets(fopendir,fisierx,charsmax(fisierx))
		trim(fisierx)
		if(containi(filename,fisierx) != -1){
			copy(CheckClient[id], 25,fisierx) 
		}
	}
	fclose(fopendir)  
}

public SV_SendBan_fix(){
	if(!is_linux_server()){
		if(SV_CheckProtocolSpamming(2)){
			return okapi_ret_supercede
		}
	}
	if(SV_FilterAddress(1)){
		return okapi_ret_supercede
	}
	return okapi_ret_ignore
}

public SV_Drop_function(index){
	Add_SV_Drop_f()
	return okapi_ret_supercede
}

public Reject_user_for_file(id){
	if(~CheckClient[id][0]==0)
	{
	}
	setc(CheckClient[id], 25 ,0)
}
public client_command(id){
	if(get_pcvar_num(CmdLimitVar)>0){
		if(is_user_admin(id)){
			new size = file_size( ip_flitredcmd , 1 ) 
			for ( new i = 0 ; i < size ; i++ ){
				new szLine[ 128 ], iLen;
				read_file(ip_flitredcmd, i, szLine, charsmax( szLine ), iLen );
				if(containi(PlayerIP(id),szLine[i]) != -0x01){
					new size2 = file_size( limitfilecmd , 1 ) 
					for ( new i = 0 ; i < size2 ; i++ ){
						new szLine[ 128 ], iLen;
						read_file(limitfilecmd, i, szLine, charsmax( szLine ), iLen );
						if(containi(Argv(),szLine[i]) != -0x01){
							limitexecute[id] = 0x00
							client_print(id,print_console,"%s this command ^"%s^" is restricted for ^"%d^" seconds",PrefixProtection,Argv(),get_pcvar_num(CmdlimitDestroy))
							return PLUGIN_HANDLED	
						}
					}
				}
			}
			
			new size2 = file_size( limitfilecmd , 1 ) 
			for ( new i = 0 ; i < size2 ; i++ ){
				new szLine[ 128 ], iLen;
				read_file(limitfilecmd, i, szLine, charsmax( szLine ), iLen );
				if(containi(Argv(),szLine[i]) != -0x01){
					limitexecute[id]++ 
					if(limitexecute[id] >=get_pcvar_num(CmdLimitMax)){
						log_to_file(settings,"%s User ^"%s^" with address ip ^"%s^" restricted command ^"%s^" for ^"%d^" seconds",PrefixProtection,UserName(id),PlayerIP(id),Argv(),get_pcvar_num(CmdlimitDestroy))
						new fileid = fopen(ip_flitredcmd,"at")
						if(fileid){
							new compress[40];
							limitexecute[id]=0x00
							formatex(compress,charsmax(compress),"%s^n",PlayerIP(id))
							fputs(fileid,compress)
						}
						fclose(fileid)	
					}
				}
				
			}
		}
	}
	if(get_pcvar_num(Radio)>0){
		for (new i = 0x00; i < sizeof(RadioCommand); i++){
			if(containi(Argv(),RadioCommand[i]) != -0x01){
				HLDS_Shield_func(id,3,radiofunction,0,0,0)
				return PLUGIN_HANDLED
			}
		}
	}
	if(containi(Argv(),"say") != -0x01 || containi(Argv(),"say_team") != -0x01 ||
	containi(Argv(),"amx_") != -0x01){
		static Float:fGameTime;
		fGameTime = get_gametime()
		
		if(DelaySpamBotStop[id] > fGameTime){
			console_print(id,"%s Wait %f seconds to to allow access command ^"%s^"",PrefixProtection,get_gametime(),Argv())
			return PLUGIN_HANDLED
		}
	}
	if(get_pcvar_num(CommandBug)>0){
		new sizex = file_size( cmd_restricted , 1 ) 
		for ( new i = 0 ; i < sizex ; i++ ){
			new szLine2[ 128 ], iLen2;
			read_file(cmd_restricted, i, szLine2, charsmax( szLine2 ), iLen2 );
			if(containi(Args(),szLine2[i]) != -0x01 || containi(Argv(),szLine2[i]) != -0x01){
				if(id){
					locala[id]++
					if(locala[id] >=get_pcvar_num(LimitPrintf)){
						return PLUGIN_HANDLED
					}
					if(id){
						HLDS_Shield_func(id,1,cmdbug,1,1,0)
						return PLUGIN_HANDLED
					}
				}
			}
		}
		for (new i = 0x00; i < sizeof(MessageHook); i++){
			if(containi(Args(),MessageHook[i])!= -0x01 || containi(Argv(),MessageHook[i])!= -0x01){
				locala[id]++
				if(locala[id] >=get_pcvar_num(LimitPrintf)){
					return PLUGIN_HANDLED
				}
				else{
					if(debug_s[id]==0){
						if(locala[id] == 3){
							locala[id]=1
							debug_s[id]=1
						}
					}
					HLDS_Shield_func(id,1,cmdbug,0,5,0)
					return PLUGIN_HANDLED
				}
				return PLUGIN_HANDLED
			}
		}
	}
	if(get_pcvar_num(IlegalCmd)>0){
		if(containi(Argv(),"cl_setautobuy") != -0x01 ||
		containi(Argv(),"say_team") != -0x01 ||
		containi(Argv(),"rebuy") != -0x01 || 
		containi(Argv(),"say") != -0x01){	
			return PLUGIN_CONTINUE
		}
		else{
			for (new i = 0x00; i < sizeof(ShieldServerCvarBlock); i++){
				if(containi(Argv1(),ShieldServerCvarBlock[i]) != -0x01){
					locala[id]++
					if(locala[id] >=get_pcvar_num(LimitPrintf)){
						return PLUGIN_HANDLED
					}
					else{
						if(debug_s[id]==0){
							if(locala[id] == 3){
								locala[id]=1
								debug_s[id]=1
							}
						}
						HLDS_Shield_func(id,1,ilegalcommand,id,1,0)
						return PLUGIN_HANDLED;
					}
				}
			}
		}
	}
	if(containi(Args(),"shield_")!= -0x01){
		if(is_user_admin(id)){
			HLDS_Shield_func(id,2,hldsbug,1,1,0)
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}
public PfnClientCommand(id)
{
	new StringBuffer[100]
	if(is_user_connected(id)){
		UserCheckImpulse[id] = 1
		if(get_pcvar_num(UpdateClient)>0){
			SV_ForceFullClientsUpdate_api(id) // fix show players in vgui for old build
		}
	}
	
	mungelimit[id]++
	if(!task_exists(0x01)){
		set_task(0.1,"LevFunction",id+TASK_ONE)
	}
	if(mungelimit[id] >= get_pcvar_num(LimitMunge)){
		mungelimit[id] = 0x00
		locala[id]++
		if(locala[id] >=get_pcvar_num(LimitPrintf)){
			return 0x00 // for spam log :(
		}
		else{
			if(!strlen(UserName(id))){
				locala[id]++
				
				HLDS_Shield_func(id,1,suspicious,1,3,1)
				return FMRES_SUPERCEDE
			}
			else{
				locala[id]++
				HLDS_Shield_func(id,1,suspicious,1,1,1)
				return FMRES_SUPERCEDE
			}
			return FMRES_SUPERCEDE
		}
	}
	if(get_pcvar_num(SpectatorVguiBug)>0){
		if(equali(Argv(), "joinclass") || (equali(Argv(), "menuselect") && get_pdata_int(id,205) == 0x03)){
			if(get_user_team(id) == 3){
				set_pdata_int(id,205,0)
				engclient_cmd(id, "jointeam", "6")
				return FMRES_SUPERCEDE
			}
		}
	}
	if(get_pcvar_num(CommandBug)>0){
		if(containi(Argv1(),"@")!= -0x01){
			
		}
		else{
			if(get_pcvar_num(ChatCharFix)==1)
			{
				if(containi(Argv(),"say")!= -0x01 || containi(Argv(),"say_team")!= -0x01){
					read_argv(1,StringBuffer,charsmax(StringBuffer))
					replace_all(StringBuffer,charsmax(StringBuffer),"%","ï¼…")
					replace_all(StringBuffer,charsmax(StringBuffer),"#","ï¼ƒ")
					engclient_cmd(id,Argv(),StringBuffer)
				}
			}
			if(get_pcvar_num(ChatCharFix)==2){
				if(containi(Argv(),"say")!= -0x01 || containi(Argv(),"say_team")!= -0x01){
					read_argv(1,StringBuffer,charsmax(StringBuffer))
					replace_all(StringBuffer,charsmax(StringBuffer),"%","*")
					replace_all(StringBuffer,charsmax(StringBuffer),"#","*")
					engclient_cmd(id,Argv(),StringBuffer)
				}
			}
		}
	}
	return FMRES_IGNORED
}
public RegisterCmdFake()
{
	if(!strlen(Argv1())){server_print("shield_addcmd_fake <string> <1=concmd/2=srvcmd>");return PLUGIN_HANDLED;}
	if(containi(Argv2(),"1") != -0x01){
		register_concmd(Argv1(),"FakeFunction")
		server_print("Command ^"%s^" registred in concmd (%s)",Argv1(),Argv2())
		return PLUGIN_HANDLED
		
	}
	else{
		if(containi(Argv2(),"2") != -0x01){
			register_srvcmd(Argv1(),"FakeFunction")
			server_print("Command ^"%s^" registred in srvcmd (%s)",Argv1(),Argv2())
			return PLUGIN_HANDLED
			
		}
		else{
			server_print("shield_addcmd_fake <string> <1=concmd/2=srvcmd>")
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE;
}
public FakeFunction(){return PLUGIN_HANDLED;}

public RegisterFakeCvar()
{
	if(!strlen(Argv1())){
		server_print("%s shield_fake_cvar <cvar name> <value>",PrefixProtection)
		return PLUGIN_HANDLED
	}
	server_print("%s Cvar ^"%s^" with value ^"%s^" registred",PrefixProtection,Argv1(),Argv2())
	register_cvar(Argv1(),Argv2())
	return PLUGIN_CONTINUE
}

public RegisterRemoveString()
{
	new deletestring[a_max]
	formatex(deletestring,charsmax(deletestring),"^n",Argv1())
	if(!strlen(Argv1()) ){
		server_print("%s shield_remove_string <string>",PrefixProtection)
		return PLUGIN_HANDLED
	}
	okapi_engine_replace_string(Argv1(),deletestring)
	server_print("%s String ^"%s^" has been removed",PrefixProtection,Argv1())
	return PLUGIN_CONTINUE
}

public RegisterReplaceString()
{
	if(!strlen(Argv1())){
		server_print("%s shield_replace_string <old string> <new string>",PrefixProtection)
		return PLUGIN_HANDLED
	}
	server_print("%s Replaced : ^"%s^" --> ^"%s^"",PrefixProtection,Argv1(),Argv2())
	okapi_engine_replace_string(Argv1(),Argv2())
	return PLUGIN_CONTINUE
}

public Host_User_f_Reverse(){
	new steamid[255]
	new players[a_max], num, tempid;
	get_players(players, num)	
	
	server_print("^nuserid : uniqueid : name : ip")
	server_print("------ : ---------: ----")
	
	for (new i=0; i<num; i++){
		tempid = players[i]
		if(is_user_connected(tempid)){
			get_user_authid(tempid,steamid,charsmax(steamid))
		}
		server_print("      %d : %s : %s : %s",get_user_userid(tempid),steamid,UserName(tempid),PlayerIP(tempid))
	}
	server_print("%d users^n",num)
	
	return okapi_ret_supercede
}
public SV_FilterAddress(writememory){	
	
	new data[net_adr],getip2[40]
	okapi_get_ptr_array(net_adrr(),data,net_adr)
	formatex(getip2,charsmax(getip2),"%d.%d.%d.%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
	
	if(writememory == 1){ // citeste
		new size = file_size( ip_flitred , 1 ) 
		for ( new i = 0 ; i < size ; i++ ){
			new szLine[ 128 ], iLen;
			read_file(ip_flitred, i, szLine, charsmax( szLine ), iLen );
			if(containi(getip2,szLine[i]) != -0x01){
				return okapi_ret_supercede
			}
		}
	}
	if(writememory == 2){ // scrie
		new fileid = fopen(ip_flitred,"at")
		if(fileid){
			new compress[40];
			formatex(compress,charsmax(compress),"%s^n",getip2)
			fputs(fileid,compress)
		}
		fclose(fileid)	
	}
	return okapi_ret_ignore
}
public SV_ConnectionlessPacket_Hook()
{
	/* fix for
	SVC_GetChallenge();
	SVC_ServiceChallenge(); 
	SV_ConnectClient(); 
	SV_Rcon(&net_from);
	SVC_GameDllQuery(args);
	*/
	
	SV_CheckProtocolSpamming(2)
	
	if(SV_FilterAddress(1)){
		return okapi_ret_supercede
	}
	if(get_pcvar_num(Queryviewer)>0){
		new data[net_adr],getip2[40],ziua[a_max],puya[255]
		okapi_get_ptr_array(net_adrr(),data,net_adr)
		get_time("%m_%d_%Y",ziua,charsmax(ziua))
		formatex(getip2,charsmax(getip2),"%d.%d.%d.%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
		formatex(puya,charsmax(puya),"addons/amxmodx/configs/settings/HLDS-QueryViewer_%s.log",ziua)
		log_to_file(puya,"%s SV_ConnectionlessPacket : %s with address %s",PrefixProtection,Argv(),getip2)
	}
	if(containi(Argv(),"j")!=-0x01){
		set_task(1.0,"destroy_memhack")
		memhack++
		if(hola >=get_pcvar_num(LimitPrintf)){
			return okapi_ret_supercede
		}
		else{
			if(memhack>3)
			{
				hola++
				set_task(0.5,"destroy_memhack")
				HLDS_Shield_func(0,0,a2ack,0,11,4)
				return okapi_ret_supercede
			}
		}
	}
	return okapi_ret_ignore
}
public checkQuery()
{
	new count = 1;
	new currentIndex = 0;
	for (new i = 1; i < ArraySize(g_aArray); i++){
		if (ArrayGetCell( g_aArray, i ) == ArrayGetCell( g_aArray, currentIndex )){
			count++;
		}
		else{
			count--;
		}
		if (count == 0){
			currentIndex = i;
			count = 1;
		}
	}
	if(count >= get_pcvar_num(LimitQuery)){
		new stringTo[15]
		num_to_str( ArrayGetCell( g_aArray, currentIndex ), stringTo, charsmax(stringTo))
		ArrayPushString( g_blackList, stringTo)
		hola++
		if(hola >=get_pcvar_num(LimitPrintf)){
			return okapi_ret_supercede
		}
		else{
			SV_FilterAddress(2) // write
			HLDS_Shield_func(0,0,query,0,11,4)
			return okapi_ret_supercede
		}
	}
	ArrayClear(g_aArray)
	return okapi_ret_ignore
}
public Netchan_CheckForCompletion_Hook(int,int2,int3x)
{
	set_task(1.5, "destroy_fuck")
	fuck++
	if(fuck==2){
		if(int3x <= 1){
			//daca valoarea 1 se repeta de 2 ori clientul intra in void SafeFileToDownload
			//HLDS_Shield_func(0,0,overload3,0,8,4) //alta metoda nu stiu
			//return okapi_ret_supercede
		}
	}
	
	if(fuck==4){
		if(int3x == 5){ // sau SV_ParseResourceList dar am nevoie de msg_readlong
			HLDS_Shield_func(0,0,overload2,0,8,4)
			return okapi_ret_supercede
		}
	}
	if(int3x >= 107){
		hola++
		if(hola >=get_pcvar_num(LimitPrintf)){ //prea multe canale de conexiune = crash
			return okapi_ret_supercede
		}
		else{
			//new id = engfunc(EngFunc_GetCurrentPlayer)+0x01 = crash
			//SV_Drop_function(id) = crash
			HLDS_Shield_func(0,0,netch,0,8,4) // entitatea id nu exista in netchan_* , deci asta inseamna sys_error
		}
		return okapi_ret_supercede
	}
	return okapi_ret_ignore
}

public SV_CheckForDuplicateNames(userinfo[],bIsReconnecting,nExcludeSlot){
	
	if(IsInvalidFunction(1," Your userinfo is invalid")){
		return okapi_ret_supercede
	}
	return okapi_ret_ignore
}
public IsInvalidFunction(functioncall,stringexit[]){
	if(okapi_engine_find_string("(%d)%-0.*s")){
		
		new GetInvalid[0x78]
		BufferName(Argv4(),0x5DC,GetInvalid)
		
		if(functioncall == 1)
		{
			if(containi(Argv4(),"^x22")!=-0x01 || containi(Argv4(),"^x2E^x5C")!=-0x01 ||
			containi(Argv4(),"^x2E^x20")!=-0x01 || containi(Argv4(),"^x2E^xFA^x2E")!=-0x01 || 
			containi(Argv4(),"^x63^x6F^x6E^x73^x6F^x6C^x65")!=-0x01) {
				tralala++
				if(tralala>=get_pcvar_num(LimitPrintf)){
					HLDS_Shield_func(0,0,loopnamebug,0,9,4)
					tralala=0
				}
				else{
					HLDS_Shield_func(0,0,loopnamebug,0,9,3)
					replace(GetInvalid,31,"^x2E","")
					server_cmd("^x6B^x69^x63^x6B^x20^x25^x73^x22 ^x25^x73",GetInvalid,stringexit)
					server_cmd("^x6B^x69^x63^x6B^x20^x25^x73^x2e ^x25^x73",GetInvalid,stringexit)
					server_cmd("^x6B^x69^x63^x6B^x20^x75^x6E^x6E^x61^x6D^x65^x64^x20^x25^x73",stringexit)
					server_cmd("^x6B^x69^x63^x6B^x20^x75^x6E^x61^x6D^x65^x64^x20^x25^x73",stringexit)
					return 1
				}
			}
		}
		if(functioncall == 2){
			new checkduplicate[255]
			formatex(checkduplicate,charsmax(checkduplicate),"^x25^x73^x5C^x6E^x61^x6D^x65^x5C",GetInvalid)
			if(containi(Argv4(), checkduplicate) != -1){
				log_amx("%s : user ^"%s^" used many string ^"\name\^"",PrefixProtection,GetInvalid)
				return 1
			}
		}
	}
	return 0
}

public SV_ProcessFile_Hook()
{
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	locala[id]++
	if(locala[id] >=get_pcvar_num(LimitPrintf)){
		return okapi_ret_supercede
	}
	else{
		HLDS_Shield_func(id,1,processfilex,id,1,0)
	}
	return okapi_ret_supercede
}
public COM_FileWrite_Hook()
{
	return okapi_ret_supercede
}
public SV_ParseVoiceData_Fix()
{
	hola++
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	if(!is_user_connected(id)){
		new MSG_ReadShort = Add_MSG_ReadShort()
		new pampamx[200]
		new VoiceMax = 4096
		formatex(pampamx,charsmax(pampamx),"%s You are detected for %s (%d)",PrefixProtection,voicedatabug,MSG_ReadShort)
		if(hola >=get_pcvar_num(LimitPrintf)){
			if(MSG_ReadShort > VoiceMax || MSG_ReadShort < 0){
				SV_RejectConnection_user(id,pampamx)
				if(get_pcvar_num(SendBadDropClient)>0){
					SV_Drop_function(id)
				}
				HLDS_Shield_func(id,0,voicedatabug,0,0,3)
				return okapi_ret_supercede
			}
		}
		else{
			if(MSG_ReadShort > VoiceMax || MSG_ReadShort < 0){
				SV_RejectConnection_user(id,pampamx)
				if(get_pcvar_num(SendBadDropClient)>0){
					SV_Drop_function(id)
				}
				HLDS_Shield_func(id,0,voicedatabug,0,17,3)
				return okapi_ret_supercede
			}
		}
	}
	return okapi_ret_ignore
}
public SV_ParseStringCommand_fix()
{
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	
	for (new i = 0x00; i < sizeof (CommandAllowInpfnClientConnect); i++){
		if(containi(Argv(),CommandAllowInpfnClientConnect[i]) != -0x01){
			return okapi_ret_ignore
		}
	}
	if(checkuser[id]==0){
		if(is_user_connecting(id)){
			if(get_pcvar_num(SendBadDropClient)>0){
				SV_Drop_function(id)
				return okapi_ret_supercede
			}
			HLDS_Shield_func(id,0,bugclc,0,8,1)
			return okapi_ret_supercede
		}
	}
	return okapi_ret_ignore
}
public SV_ParseResourceList_Fix(){
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	locala[id]++
	new MSG_ReadShort = Add_MSG_ReadShort()
	new pampam[200]
	formatex(savedata,charsmax(savedata),"(resouces : %d)",MSG_ReadShort)
	formatex(pampam,charsmax(pampam),"%s You are detected for %s (%d)",PrefixProtection,overload2,MSG_ReadShort)
	if(locala[id] >=get_pcvar_num(LimitPrintf)){
		if(MSG_ReadShort>get_pcvar_num(LimitResources)){
			SV_RejectConnection_user(id,pampam)
			if(get_pcvar_num(SendBadDropClient)>0){
				SV_Drop_function(id)
			}
			HLDS_Shield_func(id,0,overload2,0,0,3)
			locala[id]=0
		}
		return okapi_ret_supercede
	}
	else{
		if(MSG_ReadShort>get_pcvar_num(LimitResources)){
			SV_RejectConnection_user(id,pampam)
			if(get_pcvar_num(SendBadDropClient)>0){
				SV_Drop_function(id)
			}
			HLDS_Shield_func(id,0,overload2,0,17,3)
			locala[id]=0
			return okapi_ret_supercede
		}
	}
	return okapi_ret_ignore
}
public NET_GetLong()
{
	hola++
	if(hola >=get_pcvar_num(LimitPrintf)){
		return okapi_ret_supercede
	}
	else{
		HLDS_Shield_func(0,0,netbug,0,11,4)
	}
	return okapi_ret_supercede;
}
public FS_Open_Hook(abc[])
{
	if(containi(abc,".ini")!=-0x01 || containi(abc,"server.cfg")!=-0x01){
		server_print("%s I found a access strange in ^"%s^"",PrefixProtection,abc)
		return okapi_ret_supercede
	}
	return okapi_ret_ignore
}
public SV_CheckPermisionforStatus(){
	
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	
	if(is_user_admin(id)){
		ReBuild_Status(1)
	}
	else{
		if(!id){
			ReBuild_Status(2) // is server
		}
		else{
			ReBuild_Status(0)
		}
	}
	return okapi_ret_supercede
}
public ReBuild_Status(steamidshow){
	
	new players[a_max],MapName[a_max],AddressHLDS[a_max],EngineHLDS[a_max],EngineHostName[a_max],num
	new PlayerName[a_max],PlayerSteamID[a_max],PingPlayer,LossPlayer
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	
	get_players(players, num)
	get_mapname(MapName,charsmax(MapName))
	get_cvar_string("net_address",AddressHLDS,charsmax(AddressHLDS))
	get_cvar_string("sv_version",EngineHLDS,charsmax(EngineHLDS))
	get_cvar_string("hostname",EngineHostName,charsmax(EngineHostName))
	
	if(steamidshow == 2){
		server_print("^nPlayers : %d/%d",get_playersnum(),get_maxplayers())
		server_print("Map : %s",MapName)
		server_print("TCP/IP : %s",AddressHLDS)
		server_print("Engine : %s",EngineHLDS)
		server_print("HostName : %s^n",EngineHostName)
	}
	else{
		client_print(id,print_console,"^nPlayers : %d/%d",get_playersnum(),get_maxplayers())
		client_print(id,print_console,"Map : %s",MapName)
		client_print(id,print_console,"TCP/IP : %s",AddressHLDS)
		client_print(id,print_console,"Engine : %s",EngineHLDS)
		client_print(id,print_console,"HostName : %s^n",EngineHostName)
	}
	
	if(steamidshow == 1){
		client_print(id,print_console,"[Name:] [UserID:] [SteamID:] [FRAG:] [TIME PLAYED:] [PING:]^n")
	}
	else if(steamidshow == 0){
		client_print(id,print_console,"[Name:] [UserID:] [FRAG:] [TIME PLAYED:] [PING:]^n")
	}
	else{
		server_print("[Name:] [UserID:] [SteamID:] [FRAG:] [TIME PLAYED:] [PING:]^n")
	}
	
	
	for(new i = 0 ; i < num ; i++){
		new PlayerTime=get_user_time(players[i])
		if(steamidshow == 1 || steamidshow == 2){
			get_user_authid(players[i],PlayerSteamID,charsmax(PlayerSteamID))
		}
		get_user_name(players[i],PlayerName,charsmax(PlayerName))
		get_user_ping(players[i],PingPlayer,LossPlayer)
		
		if(is_user_bot(players[i])){
			if(steamidshow == 3){
				server_print("[%s]-[VALVE_BOT]-[FRAGS : %d]-[%d Seconds]",PlayerName,get_user_frags(players[i]),PlayerTime)
			}
			else{
				client_print(id,print_console,"[%s]-[VALVE_BOT]-[FRAGS : %d]-[%d Seconds]",PlayerName,get_user_frags(players[i]),PlayerTime)
			}
		}
		
		if(steamidshow == 1){
			client_print(id,print_console,"[%s]-[%i]-[%s]-[%d]-[%d Seconds]-[%d]",PlayerName,get_user_userid(players[i]),PlayerSteamID,get_user_frags(players[i]),PlayerTime,PingPlayer)
		}
		else if(steamidshow == 0){
			client_print(id,print_console,"[%s]-[%i]-[%d]-[%d Seconds]-[%d]",PlayerName,get_user_userid(players[i]),get_user_frags(players[i]),PlayerTime,PingPlayer)
		}
		else{
			server_print("[%s]-[%i]-[%s]-[%d]-[%d Seconds]-[%d]",PlayerName,get_user_userid(players[i]),PlayerSteamID,get_user_frags(players[i]),PlayerTime,PingPlayer)
		}
	}
}
public SV_RunCmd_Hook()
{
	// functia este apelata mereu (loop)
	// asta trebui testat mai mult pe linux
	// testeaza cu 32 de jucatori si un atac catre server
	// testeaza doar cu 32 de jucatori si fara atac
	
	if(get_pcvar_num(LimitImpulse)==0){
		return okapi_ret_ignore
	}
	else if (get_pcvar_num(LimitImpulse)>0){
		new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
		if(id){
			if(is_user_connected(id))
			{
				if(UserCheckImpulse[id] == 0){
					limit[id]++
					if(limit[id] >= get_pcvar_num(LimitImpulse)){
						locala[id]++
						
						//if(get_pcvar_num(SendBadDropClient)>0){
						///	SV_Drop_function(id) == crash ?????
						//}
						
						if(locala[id] >=get_pcvar_num(LimitPrintf)){
							return okapi_ret_supercede
						}
						else{
							HLDS_Shield_func(id,0,cmdrun,0,1,1)
							UserCheckImpulse[id] = 1
							return okapi_ret_supercede;
						}
					}
				}
			}
		}
	}
	return okapi_ret_ignore
}
public SV_CheckForDuplicateSteamID(id){
	//procedure function fix sv_checkforduplicatesteamid
	
	new CertificateSteamID[50],AllUserCertificateSteamID[50]
	
	get_user_authid(id,CertificateSteamID,charsmax(CertificateSteamID))
	
	for(new i = 1; i <= g_MaxClients; i++){
		
		if(is_user_connected(i)){
			get_user_authid(i,AllUserCertificateSteamID,charsmax(AllUserCertificateSteamID))
		}
		if(containi(CertificateSteamID, AllUserCertificateSteamID) != -1){
			locala[id]++
			new longtext[255]
			formatex(longtext,charsmax(longtext),"%s Your SteamID is duplicated %s",PrefixProtection,CertificateSteamID)
			SV_RejectConnection_user(id,longtext)
			if(debug_s[id]==0){
				if(locala[id] == 3){
					locala[id]=1
					debug_s[id]=1
				}
			}
			HLDS_Shield_func(id,0,steamidhack,1,1,0)
		}		
	}
	//end
}
public Shield_CheckSteamID(id,payload)  {
	new ValutKey[71]
	new ValutData[256]
	
	format(ValutKey,70,"%s-IP", szip) 
	format(ValutData,255,"%s-SteamID", authid) 
	
	if(payload == 1)
	{
		nvault_set(valutsteamid, ValutKey, ValutData) 
		get_user_authid(id, authid2, charsmax(authid2))
		get_user_ip(id, szip2, charsmax(szip2), 0)
		
		if(equal(szip2, szip)) {
			if(!equal(authid2, authid)) {
				HLDS_Shield_func(id,0,steamidhack,1,1,1)
				if(get_pcvar_num(SendBadDropClient)>0){
					SV_Drop_function(id)
				}
			}
		}
	}
	else if(payload == 2){
		get_user_authid(id, authid, charsmax(authid))
		get_user_ip(id, szip, charsmax(szip), 0)
		nvault_set(valutsteamid, ValutKey, ValutData)
	}
	return PLUGIN_HANDLED
}
public plugin_end(){
	SV_UpTime(2)
	Destroy_Fileiplist()
	nvault_close(valutsteamid)
}
public SHIELD_NameDeBug(id){
	NameUnLock[id-TASK_ONE2] = 0
}

public SHIELD_NameDeBug2(id){
	NameUnLock[id] = 2
}
public pfnClientUserInfoChanged(id,buffer){
	static szOldName[a_max],szNewName[a_max],longformate[255]
	pev(id,pev_netname,szOldName,charsmax(szOldName))
	number++
	formatex(longformate,charsmax(longformate),"(%d)%s",number,szOldName)
	get_user_info(id,"name",szNewName,charsmax(szNewName))
	new lastname[a_max]
	if(is_user_admin(id)){
		if(!equal(lastname,UserName(id))){
			show_menu(id,0x00,"^n",0x01)
		}
	}
	if(get_pcvar_num(NameCharFix)==1){
		if(containi(szNewName,"&") !=-1){
			replace_all(szNewName,charsmax(szNewName),"&","ï¼†")
			replace_all(szNewName,charsmax(szNewName),"&","*")
			set_user_info(id,"name",szNewName) 
		}
		if(containi(szNewName,"%") !=-1){
			replace_all(szNewName,charsmax(szNewName),"%","ï¼…")
			replace_all(szNewName,charsmax(szNewName),"%","*")
			set_user_info(id,"name",szNewName) 
		}
		if(containi(szNewName,"#") !=-1){
			replace_all(szNewName,charsmax(szNewName),"#","ï¼ƒ")
			replace_all(szNewName,charsmax(szNewName),"#","*")
			set_user_info(id,"name",szNewName) 
		}
		
	}
	if(get_pcvar_num(NameCharFix)==2){
		if(containi(szNewName,"&") !=-1){
			replace_all(szNewName,charsmax(szNewName),"&","*")
			set_user_info(id,"name",szNewName) 
		}
		if(containi(szNewName,"%") !=-1){
			replace_all(szNewName,charsmax(szNewName),"%","*")
			set_user_info(id,"name",szNewName) 
		}
		if(containi(szNewName,"#") !=-1){
			replace_all(szNewName,charsmax(szNewName),"#","*")
			set_user_info(id,"name",szNewName) 
		}
		
	}
	
	if(get_pcvar_num(NameBug)>0){
		if(is_linux_server()){
			if(is_user_connected(id)){
				new Count=admins_num()
				new NameList[b_max],PWList[b_max],MyPW[a_max],PlayerPW[a_max]
				
				for (new i = 0x00; i < Count; ++i){	
					admins_lookup(i,AdminProp_Auth,NameList,charsmax(NameList))
					admins_lookup(i,AdminProp_Password,PWList,charsmax(PWList))
					get_cvar_string("amx_password_field",MyPW,charsmax(MyPW))
					get_user_info(id,MyPW,PlayerPW,charsmax(PlayerPW))
					if(equal(UserName(id),NameList)){
						if(!equal(PlayerPW,PWList)){
							HLDS_Shield_func(id,2,adminbug,1,1,1)
							return FMRES_SUPERCEDE
						}
					}
				}
			}
		}
		
		if(is_linux_server()){
			for (new i = 0x00; i < sizeof (MessageHook); i++){
				if(containi(Argv2(),MessageHook[i]) != -0x01){
					locala[id]++
					if(locala[id] >=get_pcvar_num(LimitPrintf)){
						set_user_info(id,"name",longformate)
						return FMRES_SUPERCEDE
					}
					else{
						if(debug_s[id]==0){
							if(locala[id] == 3){
								locala[id]=1
								debug_s[id]=1
							}
						}
						HLDS_Shield_func(id,1,namebug,1,5,0)
						set_user_info(id,"name",longformate) 
						return FMRES_SUPERCEDE
					}
				}
			}
		}
	}
	if(get_pcvar_num(NameBugShowMenu)>0){
		new lastname[a_max]
		get_user_info(id,"name",lastname,charsmax(lastname))
		if(!equal(lastname,UserName(id))){
			SV_CheckUserNameForMenuStyle(id,lastname)
		}
		
	}
	if(get_pcvar_num(NameSpammer)>0){
		new get_time_cvar = get_pcvar_num(TimeNameChange)
		if(containi(szNewName,"%") !=-1){
			if (NameUnLock[id]==2){
				NameUnLock[id] = 2
				client_print_color(id,id,"^4%s^1 Please wait^4 %d seconds^1 before change the name",PrefixProtection,get_time_cvar)
				set_user_info(id,"name",longformate) 
				set_task(float(get_time_cvar),"SHIELD_NameDeBug",id+TASK_ONE2)
				return FMRES_SUPERCEDE
			}
			
			NameUnLock[id] = 0
			set_task(0.3,"SHIELD_NameDeBug2",id+TASK_ONE2)
			return FMRES_SUPERCEDE
			
		}
		if(szOldName[0]) {
			if(!equal(szOldName,szNewName)) {
				if (NameUnLock[id] == 1){
					NameUnLock[id] = 1
					client_print_color(id,id,"^4%s^1 Please wait^4 %d seconds^1 before change the name",PrefixProtection,get_time_cvar)
					set_user_info(id,"name",longformate)
					return FMRES_SUPERCEDE
				}
				NameUnLock[id] = 1
				set_task(float(get_time_cvar),"SHIELD_NameDeBug",id+TASK_ONE2)
			}
		}
	}
	if(ServerVersion == 0){
		if(get_pcvar_num(UnicodeName)>0){
			if(cmpStr2(Args())){
				locala[id]++
				if(locala[id] >=get_pcvar_num(LimitPrintf)){
					set_user_info(id,"name",longformate)
					return FMRES_SUPERCEDE
				}
				else{
					if(debug_s[id]==0){
						if(locala[id] == 3){
							locala[id]=1
							debug_s[id]=1
						}
					}
					HLDS_Shield_func(id,1,namebug,1,5,0)
					set_user_info(id,"name",longformate) 
					return FMRES_SUPERCEDE
				}
			}
		}
	}
	return FMRES_IGNORED
}
public Info_ValueForKey_Hook(index)
{
	if(get_pcvar_num(NameBug)>0){
		new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
		if(!is_linux_server()){ // windows
			if(is_user_connected(id)){
				new Count=admins_num()
				new NameList[b_max],PWList[b_max],MyPW[a_max],PlayerPW[a_max]
				
				for (new i = 0x00; i < Count; ++i){	
					admins_lookup(i,AdminProp_Auth,NameList,charsmax(NameList))
					admins_lookup(i,AdminProp_Password,PWList,charsmax(PWList))
					get_cvar_string("amx_password_field",MyPW,charsmax(MyPW))
					get_user_info(id,MyPW,PlayerPW,charsmax(PlayerPW))
					if(equal(UserName(id),NameList)){
						if(!equal(PlayerPW,PWList)){
							HLDS_Shield_func(id,2,adminbug,1,1,1)
						}
					}
				}
			}
		}
		if(!is_linux_server()){ // windows
			for (new i = 0x00; i < sizeof (MessageHook); i++){
				if(containi(Argv2(),MessageHook[i]) != -0x01){
					locala[id]++
					if(locala[id] >=get_pcvar_num(LimitPrintf)){
						return okapi_ret_supercede
					}
					else{
						if(debug_s[id]==0){
							if(locala[id] == 3){
								locala[id]=1
								debug_s[id]=1
							}
						}
						HLDS_Shield_func(id,1,namebug,1,5,0)
					}
					return okapi_ret_supercede;
				}
			}
		}
	}
	return okapi_ret_ignore
}
public plugin_pause(){
	new get[a_max]
	get_plugin(-1,get,charsmax(get))
	server_cmd("amxx unpause %s",get)
	log_to_file(settings,"%s Failed to pause plugin ^"%s^"",PrefixProtection,get)
	client_print_color(0,0,"^4%s^1 : Failed to pause plugin ^"%s^"",PrefixProtection,get)
}
public Host_Say_f_Hook(){
	if(get_pcvar_num(CommandBug)>0){
		for (new i = 0; i < sizeof (MessageHook); i++){
			if(containi(Args(),MessageHook[i]) != -1){
				hola++
				if(hola >=get_pcvar_num(LimitPrintf)){
					return okapi_ret_supercede
				}
				else{
					HLDS_Shield_func(0,0,cmdbug,0,10,0)
					return okapi_ret_supercede;
				}
			}
		}
	}
	new hostname[50]
	get_cvar_string("hostname",hostname,charsmax(hostname))
	if( strlen(Args())>=139 ){
		return okapi_ret_supercede;
	}
	client_print_color(0,0,"^4%s (Console)^1 : %s",hostname,Args())
	log_amx("%s (Console) : %s",hostname,Args())
	return okapi_ret_supercede;
}
public SV_ConnectClient_Hook()
{
	new data[net_adr],value[1024],buffer[128],getip[MAX_BUFFER_IP],checkduplicate[255]
	
	read_argv(0x04,value,charsmax(value))
	BufferName(value,charsmax(value),buffer)
	formatex(checkduplicate,charsmax(checkduplicate),"^x25^x73^x5C^x6E^x61^x6D^x65^x5C",buffer)
	
	if(get_pcvar_num(RandomSteamid)>0){
		//8af049309c7356585ae4b48ed7471802 = CT-Shield 1.0
		if(containi(Argv3(),"8af049309c7356585ae4b48ed7471802") != -0x01 ){ // for restrict cdkey
			okapi_get_ptr_array(net_adrr(),data,net_adr)
			formatex(getip,charsmax(getip),"%d.%d.%d.%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
			HLDS_Shield_func(0,0,steamidhack,0,8,0)
			if(get_pcvar_num(OptionSV_ConnectClient)==1){
				return okapi_ret_supercede
			}
			else if(get_pcvar_num(OptionSV_ConnectClient)==2){
				replace_all(buffer,charsmax(buffer),"%","^x00")
				
				replace_all(buffer,charsmax(buffer),"#","^x00")
				replace_all(buffer,charsmax(buffer),"&","^x00")
				server_cmd("kick ^%s^" ^"%s^"",buffer,steamidhack)
				server_cmd("kick %s ^"%s^"",buffer,steamidhack)
			}
			else if(get_pcvar_num(OptionSV_ConnectClient)>=3){
				server_cmd("addip %d %s",get_pcvar_num(PauseDlfile),getip)
				replace_all(buffer,charsmax(buffer),"%","^x00")
				
				replace_all(buffer,charsmax(buffer),"#","^x00")
				replace_all(buffer,charsmax(buffer),"&","^x00")
				server_cmd("kick ^"%s^" ^"%s^"",buffer,steamidhack)
				server_cmd("kick %s ^"%s^"",buffer,steamidhack)
			}
		}
	}
	
	if(get_pcvar_num(DumpConnector)>0){
		okapi_get_ptr_array(net_adrr(),data,net_adr)
		formatex(getip,charsmax(getip),"%d.%d.%d.%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
		log_to_file(dumpconnect,"------------------------------------------------------------------------")
		log_to_file(dumpconnect,"|UserName : %s",buffer)
		log_to_file(dumpconnect,"|Address  : %s",getip)
		log_to_file(dumpconnect,"|Protocol : %s",Argv3())
		log_to_file(dumpconnect,"|Userinfo : %s",Argv4())
		
	}
	if(IsInvalidFunction(2,"userinfo")){
		if(get_pcvar_num(OptionSV_ConnectClient)==3){
			server_cmd("addip %d %s",get_pcvar_num(PauseDlfile),getip)
			replace_all(buffer,charsmax(buffer),"%","^x00")
			
			replace_all(buffer,charsmax(buffer),"#","^x00")
			replace_all(buffer,charsmax(buffer),"&","^x00")
			server_cmd("kick ^"%s^" ^"%s^"",buffer,namebug)
			server_cmd("kick %s ^"%s^"",buffer,namebug)
		}
		return okapi_ret_supercede
	}
	
	if(get_pcvar_num(NameProtector)>0){
		for (new i = 0x00; i < sizeof (MessageHook); i++){
			if(containi(buffer,MessageHook[i]) != -0x01){
				replace_all(buffer,0x21,"%","^x20")
				okapi_get_ptr_array(net_adrr(),data,net_adr)
				formatex(getip,charsmax(getip),"%d.%d.%d.%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
				replace_all(buffer,charsmax(buffer),"%","^x00")
				
				replace_all(buffer,charsmax(buffer),"#","^x00")
				replace_all(buffer,charsmax(buffer),"&","^x00")
				server_cmd("kick ^"%s^" ^"%s^"",buffer,namebug)
				server_cmd("kick %s ^"%s^"",buffer,namebug)
				HLDS_Shield_func(0,0,namebug,0,9,5)
			}
		}
	}
	if((containi(buffer,"^x2e^x2e") != -0x01 || containi(buffer,"^x22") != -0x01
	|| containi(buffer,"^x2e^xfa^x2e") != -0x01) ){
		okapi_get_ptr_array(net_adrr(),data,net_adr)
		formatex(getip,charsmax(getip),"%d.%d.%d.%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
		HLDS_Shield_func(0,0,hldsbug,0,8,3)
		if(get_pcvar_num(OptionSV_ConnectClient)==1){
			return okapi_ret_supercede
		}
		else if(get_pcvar_num(OptionSV_ConnectClient)==2){
			replace_all(buffer,charsmax(buffer),"%","^x00")
			
			replace_all(buffer,charsmax(buffer),"#","^x00")
			replace_all(buffer,charsmax(buffer),"&","^x00")
			server_cmd("kick ^"%s^" ^"%s^"",buffer,namebug)
			server_cmd("kick %s ^"%s^"",buffer,namebug)
		}
		else if(get_pcvar_num(OptionSV_ConnectClient)>=3){
			server_cmd("addip %d %s",get_pcvar_num(PauseDlfile),getip)
			replace_all(buffer,charsmax(buffer),"%","^x00")
			
			replace_all(buffer,charsmax(buffer),"#","^x00")
			replace_all(buffer,charsmax(buffer),"&","^x00")
			server_cmd("kick ^"%s^" ^"%s^"",buffer,namebug)
			server_cmd("kick %s ^"%s^"",buffer,namebug)
		}
	}
	if(containi(Argv4(),checkduplicate) != -1){
		okapi_get_ptr_array(net_adrr(),data,net_adr)
		formatex(getip,charsmax(getip),"%d.%d.%d.%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
		HLDS_Shield_func(0,0,namebug,0,8,3)
		if(get_pcvar_num(OptionSV_ConnectClient)==1){
			return okapi_ret_supercede
		}
		else if(get_pcvar_num(OptionSV_ConnectClient)==2){
			replace_all(buffer,charsmax(buffer),"%","^x00")
			
			replace_all(buffer,charsmax(buffer),"#","^x00")
			replace_all(buffer,charsmax(buffer),"&","^x00")
			server_cmd("kick ^"%s^" ^"%s^"",buffer,namebug)
		}
		else if(get_pcvar_num(OptionSV_ConnectClient)>=3){
			server_cmd("addip %d %s",get_pcvar_num(PauseDlfile),getip)
			replace_all(buffer,charsmax(buffer),"%","^x00")
			
			replace_all(buffer,charsmax(buffer),"#","^x00")
			replace_all(buffer,charsmax(buffer),"&","^x00")
			server_cmd("kick ^"%s^" ^"%s^"",buffer,namebug)
		}
	}
	if(get_pcvar_num(HLTVFilter)>0){
		if((containi(value,"*hltv") != -0x01)){
			okapi_get_ptr_array(net_adrr(),data,net_adr)
			formatex(getip,charsmax(getip),"%d.%d.%d.%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
			HLDS_Shield_func(0,0,hltvbug,0,8,3)
			if(get_pcvar_num(OptionSV_ConnectClient)==1){
				return okapi_ret_supercede
			}
			else if(get_pcvar_num(OptionSV_ConnectClient)==2){
				replace_all(buffer,charsmax(buffer),"%","^x00")
				
				replace_all(buffer,charsmax(buffer),"#","^x00")
				replace_all(buffer,charsmax(buffer),"&","^x00")
				server_cmd("kick ^"%s^" ^"%s^"",buffer,hltvbug)
				server_cmd("kick %s ^"%s^"",buffer,hltvbug)
			}
			else if(get_pcvar_num(OptionSV_ConnectClient)>=3){
				server_cmd("addip %d %s",get_pcvar_num(PauseDlfile),getip)
				replace_all(buffer,charsmax(buffer),"%","^x00")
				
				replace_all(buffer,charsmax(buffer),"#","^x00")
				replace_all(buffer,charsmax(buffer),"&","^x00")
				server_cmd("kick ^"%s^" ^"%s^"",buffer,hltvbug)
				server_cmd("kick %s ^"%s^"",buffer,hltvbug)
			}
		}
	}
	if(get_pcvar_num(HLProxyFilter)>0){
		if((containi(value,"_ip") != -0x01)){
			SV_RejectConnection_Hook(1,"Hello") // merge doar ca fara dproto
			okapi_get_ptr_array(net_adrr(),data,net_adr)
			formatex(getip,charsmax(getip),"%d.%d.%d.%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
			HLDS_Shield_func(0,0,hlproxy,0,8,4)
			if(get_pcvar_num(OptionSV_ConnectClient)==1){
				return okapi_ret_supercede
			}
			else if(get_pcvar_num(OptionSV_ConnectClient)==2){
				replace_all(buffer,charsmax(buffer),"%","^x00")
				
				replace_all(buffer,charsmax(buffer),"#","^x00")
				replace_all(buffer,charsmax(buffer),"&","^x00")
				server_cmd("kick ^"%s^" ^"%s^"",buffer,hlproxy)
				server_cmd("kick %s ^"%s^"",buffer,hlproxy)
			}
			else if(get_pcvar_num(OptionSV_ConnectClient)>=3){
				server_cmd("addip %d %s",get_pcvar_num(PauseDlfile),getip)
				replace_all(buffer,charsmax(buffer),"%","^x00")
				replace_all(buffer,charsmax(buffer),"+","^x00")
				replace_all(buffer,charsmax(buffer),"#","^x00")
				replace_all(buffer,charsmax(buffer),"&","^x00")
				server_cmd("kick %s ^"%s^"",buffer,hlproxy)
				server_cmd("kick %s ^"%s^"",buffer,hlproxy)
			}
		}
	}
	if(get_pcvar_num(FakePlayerFilter)>0){
		new counterstrike[varmax]
		if(get_cvar_string("mp_c4timer",counterstrike,charsmax(counterstrike))){
			if(!(containi(value,"\_cl_autowepswitch\1\") != -0x01 || containi(value,"\_cl_autowepswitch\0\") != -0x01)){
				okapi_get_ptr_array(net_adrr(),data,net_adr)
				formatex(getip,charsmax(getip),"%d.%d.%d.%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
				HLDS_Shield_func(0,0,fakeplayer,0,8,0)
				if(get_pcvar_num(OptionSV_ConnectClient)==1){
					return okapi_ret_supercede
				}
				else if(get_pcvar_num(OptionSV_ConnectClient)==2){
					replace_all(buffer,charsmax(buffer),"%","^x00")
					replace_all(buffer,charsmax(buffer),"+","^x00")
					replace_all(buffer,charsmax(buffer),"#","^x00")
					replace_all(buffer,charsmax(buffer),"&","^x00")
					server_cmd("kick ^"%s^" ^"%s^"",buffer,fakeplayer)
					server_cmd("kick %s ^"%s^"",buffer,fakeplayer)
				}
				else if(get_pcvar_num(OptionSV_ConnectClient)>=3){
					server_cmd("addip %d %s",get_pcvar_num(PauseDlfile),getip)
					replace_all(buffer,charsmax(buffer),"%","^x00")
					replace_all(buffer,charsmax(buffer),"+","^x00")
					replace_all(buffer,charsmax(buffer),"#","^x00")
					replace_all(buffer,charsmax(buffer),"&","^x00")
					server_cmd("kick ^"%s^" ^"%s^"",buffer,fakeplayer)
					server_cmd("kick %s ^"%s^"",buffer,fakeplayer)
				}
			}
		}
		else{
			log_to_file(settings,"%s The function ^"shield_fakeplayer_filter^" is only Counter-Strike",PrefixProtection)
		}
	}
	return okapi_ret_ignore;
	
}

public SV_CheckProtocolSpamming(bruteforce){
	new data[net_adr],szTemp[444];
	
	if(hola >=get_pcvar_num(LimitPrintf)){
		return okapi_ret_supercede
	}
	else{
		for( new i; i < ArraySize( g_blackList ); i++ ){
			ArrayGetString( g_blackList, i, szTemp, charsmax( szTemp ) )
			if(equal(getip2, szTemp)){
				okapi_get_ptr_array(net_adrr(),data,net_adr)
				formatex(getip,charsmax(getip),"%d.%d.%d.%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
				formatex(getip2,charsmax(getip2),"%d%d%d%d",data[ip][0x00], data[ip][0x01], data[ip][0x02], data[ip][0x03])
			}
		}
		set_task(bruteforce+0.0, "checkQuery")
		ArrayPushCell(g_aArray,str_to_num((getip2)))
	}
	return okapi_ret_ignore
}

public SV_SendRes_f_Hook(){
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	
	locala[id]++
	
	if(locala[id] >=get_pcvar_num(LimitPrintf)){
		return okapi_ret_supercede
	}
	else{
		if(locala[id] >=get_pcvar_num(LimitExploit)){
			if(get_pcvar_num(SendBadDropClient)>0){
				SV_Drop_function(id)
			}
			else{
				HLDS_Shield_func(id,1,hldsprintf,1,5,1)
			}
			if(strlen(UserName(id))){
				HLDS_Shield_func(id,1,hldsres,1,5,0)
			}
			else{
				HLDS_Shield_func(0,0,hldsres,0,3,0)
			}		
			return okapi_ret_supercede
		}
	}
	return okapi_ret_ignore
}
public Host_ShutDown_Hook(){
	if(get_pcvar_num(ShutdownServer)>0){
		return okapi_ret_supercede
	}
	else{
		set_task(1.0,"SV_LostConnectionDelay",0,"",0,"b")
		return okapi_ret_supercede
	}
	return okapi_ret_ignore
}
public SV_LostConnectionDelay(){
	if(lostconnection==get_pcvar_num(LostConnectionSeconds)){
		for(new i = 1; i <= g_MaxClients; i++){
			if(is_user_connected(i)){
				SV_RejectConnection_user(i,"Server lost connection")
				lostconnection=0
				log_to_file(settings,"%s Server lost connection",PrefixProtection)
			}
			set_task(0.5,"force_exit")
		}
	}
	else{
		for(new i = 1; i <= g_MaxClients; i++){
			if(is_user_connected(i)){
				set_hudmessage(255, 0, 0, -1.0, 0.22, 0, 6.0, 1.0)
				show_hudmessage(i, "Warrning : Server lost connection in %d/%d",lostconnection,get_pcvar_num(LostConnectionSeconds))
			}
		}
	}
	lostconnection++	
}
public Con_Printf_Hook(pfnprint[])
{
	if(get_pcvar_num(SV_RconCvar)==3){
		if(containi(pfnprint,"Bad rcon_password.")!=-0x01){
			HLDS_Shield_func(0,0,hldsrcon,0,8,4)
			return okapi_ret_supercede
		}
	}
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	if(id){
		if(
		containi(pfnprint,"Info string length exceeded")!=-0x01 || 
		containi(pfnprint,"Can't set * keys")!=-0x01 || 
		containi(pfnprint,"Ignoring invalid custom decal from %s")!=-0x01 || 
		containi(pfnprint,"Non customization in upload queue!")!=-0x01 || 
		containi(pfnprint,"usage: setinfo [ <key> <value> ]")!=-0x01 || 
		containi(pfnprint,"Can't use keys or values with a ^x22")!=-0x01 || 
		containi(pfnprint,"usage:  kick < name > | < # userid >")!=-0x01 || 
		containi(pfnprint,"Can't use keys or values with a \")!=-0x01 || 
		containi(pfnprint,"Keys and values must be < %i characters and > 0.")!=-0x01){
			if(is_user_connected(id)){
				new build[varmax]
				get_cvar_string("hostname",build,charsmax(build))
				locala[id]++
				
				if(locala[id] >=get_pcvar_num(LimitPrintf)){
					return okapi_ret_supercede
				}
				else
				{
					if(locala[id] >=get_pcvar_num(LimitExploit)){
						if(get_pcvar_num(SendBadDropClient)>0){
							SV_Drop_function(id)
						}
						else{
							HLDS_Shield_func(id,1,hldsprintf,1,5,1)
						}
						return okapi_ret_supercede
					}
					if(strlen(UserName(id))){
						if(debug_s[id]==0){
							if(locala[id] == 3){
								locala[id]=1
								debug_s[id]=1
							}
						}
						HLDS_Shield_func(id,1,hldsprintf,1,5,0)
					}
					else{
						HLDS_Shield_func(0,0,hldsprintf,0,3,0)
					}
				}
			}
		}
		return okapi_ret_supercede
	}
	if(containi(pfnprint,"SV_ReadClientMessage: badread")!=-0x01){
		return okapi_ret_supercede
	}
	if(
	containi(pfnprint,"Invalid split packet length %i")!=-0x01 ||
	containi(pfnprint,"WARNING: reliable overflow for %s")!=-0x01 || 
	containi(pfnprint,"Split packet without all %i parts, part %i had wrong sequence %i/%i")!=-0x01||
	containi(pfnprint,"NET_GetLong:  Ignoring duplicated split packet %i of %i ( %i bytes )")!=-0x01||
	containi(pfnprint,"Malformed packet size (%i, %i)")!=-0x01||
	containi(pfnprint,"Malformed packet number (%i)")!=-0x01 ||
	containi(pfnprint,"SZ_GetSpace: overflow on %s")!=-0x01 || 
	containi(pfnprint,"NET_QueuePacket:  Oversize packet from %s")!=-0x01){
		if(hola >=get_pcvar_num(LimitPrintf)){
			return okapi_ret_supercede
		}
		hola++
		HLDS_Shield_func(0,0,netbug,0,11,0)
		return okapi_ret_supercede
	}
	return okapi_ret_ignore
}

public SV_RejectConnection_Hook(a,b[])
{
	long = OrpheuGetFunction("MSG_ReadLong")
	return OrpheuCallSuper(long)
}
public FalseAllFunction(id)
{
	UserCheckImpulse[id] = 0x01
	locala[id] = 0x00
	tralala = 0x00
	usercheck[id] = 0x00
	debug_s[id]  = 0x00
	limitexecute[id] = 0x00
	overflowed[id] = 0x00
	limit[id] = 0x00
	local = 0x00
	limitb[id] = 0x00
	mungelimit[id] = 0x00
}
public SV_DropClient_Hook(int,int2,string[],index)
{
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	checkuser[id] = 0x00
	
	if(containi(string,"Bad file %s")!=-0x01){
		return okapi_ret_supercede
	}
	if(get_pcvar_num(VAC)>0){
		if(containi(string,"VAC banned from secure server")!=-0x01){
			return okapi_ret_supercede
		}
	}
	if(containi(string,"Reliable channel overflowed")!=-0x01){
		locala[id]++
		if(locala[id] >=get_pcvar_num(MaxOverflowed)){
			if(is_user_connected(id)){
				new longtext[255]
				overflowed[id]++
				formatex(longtext,charsmax(longtext),"[%s] Reliable channel overflowed of %d",PrefixProtection,overflowed[id])
				SV_RejectConnection_user(id,longtext)
			}
			return okapi_ret_supercede
		}
		else{
			locala[id]++
			if(locala[id] >=get_pcvar_num(LimitPrintf)){
				return okapi_ret_supercede
			}
			else{
				if(!strlen(UserName(id))){
					HLDS_Shield_func(id,1,hldsoverflowed,1,3,1)	
				}
				else{
					HLDS_Shield_func(id,1,hldsoverflowed,1,1,0)
				}
			}
		}
		return okapi_ret_supercede
	}
	FalseAllFunction(id)
	return okapi_ret_ignore
}
public PfnClientDisconnect(id){
	if(get_pcvar_num(RandomSteamid)>0){
		Shield_CheckSteamID(id,2)
	}
	DelaySpamBotStop[id] = 0.0
	DelaySpamBotStart[id] = 0.0
	FalseAllFunction(id)
}
public SV_Spawn_f_Hook()
{
	new id = engfunc(EngFunc_GetCurrentPlayer)+0x01
	limit[id]++
	if(limit[id] >=get_pcvar_num(LimitExploit)){
		locala[id]++
		if(locala[id] >=get_pcvar_num(LimitPrintf)){
			return okapi_ret_supercede
		}
		else{
			if(!strlen(UserName(id))){
				if(get_pcvar_num(SendBadDropClient)>0){
					SV_Drop_function(id)
				}
				HLDS_Shield_func(id,1,hldspawn,1,5,1)
				return okapi_ret_supercede
			}
			else{
				if(get_pcvar_num(SendBadDropClient)>0){
					SV_Drop_function(id)
				}
				HLDS_Shield_func(id,2,hldspawn,1,5,1)
				return okapi_ret_supercede
			}
		}
		return okapi_ret_supercede
	}
	return okapi_ret_ignore	
}