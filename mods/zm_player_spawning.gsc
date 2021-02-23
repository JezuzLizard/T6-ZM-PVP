spawnclient( timealreadypassed )
{
	pixbeginevent( "spawnClient" );
	if ( !self mayspawn() )
	{
		currentorigin = self.origin;
		currentangles = self.angles;
		self showspawnmessage();
		self thread [[ level.spawnspectator ]]( currentorigin + vectorScale( ( 0, 0, 1 ), 60 ), currentangles );
		pixendevent();
		return;
	}
	if ( self.waitingtospawn )
	{
		pixendevent();
		return;
	}
	self.waitingtospawn = 1;
	self.allowqueuespawn = undefined;
	self waitandspawnclient( timealreadypassed );
	if ( isDefined( self ) )
	{
		self.waitingtospawn = 0;
	}
	pixendevent();
}

waitandspawnclient( timealreadypassed )
{
	self endon( "disconnect" );
	self endon( "end_respawn" );
	level endon( "game_ended" );
	if ( !isDefined( timealreadypassed ) )
	{
		timealreadypassed = 0;
	}
	spawnedasspectator = 0;
	if ( is_true( self.teamkillpunish ) )
	{
		teamkilldelay = maps/mp/gametypes_zm/_globallogic_player::teamkilldelay();
		if ( teamkilldelay > timealreadypassed )
		{
			teamkilldelay -= timealreadypassed;
			timealreadypassed = 0;
		}
		else
		{
			timealreadypassed -= teamkilldelay;
			teamkilldelay = 0;
		}
		if ( teamkilldelay > 0 )
		{
			setlowermessage( &"MP_FRIENDLY_FIRE_WILL_NOT", teamkilldelay );
			self thread respawn_asspectator( self.origin + vectorScale( ( 0, 0, 1 ), 60 ), self.angles );
			spawnedasspectator = 1;
			wait teamkilldelay;
		}
		self.teamkillpunish = 0;
	}
	if ( !isDefined( self.wavespawnindex ) && isDefined( level.waveplayerspawnindex[ self.team ] ) )
	{
		self.wavespawnindex = level.waveplayerspawnindex[ self.team ];
		level.waveplayerspawnindex[ self.team ]++;
	}
	timeuntilspawn = timeuntilspawn( 0 );
	if ( timeuntilspawn > timealreadypassed )
	{
		timeuntilspawn -= timealreadypassed;
		timealreadypassed = 0;
	}
	else
	{
		timealreadypassed -= timeuntilspawn;
		timeuntilspawn = 0;
	}
	if ( timeuntilspawn > 0 )
	{
		if ( level.playerqueuedrespawn )
		{
			setlowermessage( game[ "strings" ][ "you_will_spawn" ], timeuntilspawn );
		}
		else
		{
			setlowermessage( game[ "strings" ][ "waiting_to_spawn" ], timeuntilspawn );
		}
		if ( !spawnedasspectator )
		{
			spawnorigin = self.origin + vectorScale( ( 0, 0, 1 ), 60 );
			spawnangles = self.angles;
			if ( isDefined( level.useintermissionpointsonwavespawn ) && [[ level.useintermissionpointsonwavespawn ]]() == 1 )
			{
				spawnpoint = maps/mp/gametypes_zm/_spawnlogic::getrandomintermissionpoint();
				if ( isDefined( spawnpoint ) )
				{
					spawnorigin = spawnpoint.origin;
					spawnangles = spawnpoint.angles;
				}
			}
			self thread respawn_asspectator( spawnorigin, spawnangles );
		}
		spawnedasspectator = 1;
		self maps/mp/gametypes_zm/_globallogic_utils::waitfortimeornotify( timeuntilspawn, "force_spawn" );
		self notify( "stop_wait_safe_spawn_button" );
	}
	if ( isDefined( level.gametypespawnwaiter ) )
	{
		if ( !spawnedasspectator )
		{
			self thread respawn_asspectator( self.origin + vectorScale( ( 0, 0, 1 ), 60 ), self.angles );
		}
		spawnedasspectator = 1;
		if ( !( self [[ level.gametypespawnwaiter ]]() ) )
		{
			self.waitingtospawn = 0;
			self clearlowermessage();
			self.wavespawnindex = undefined;
			self.respawntimerstarttime = undefined;
			return;
		}
	}
	wavebased = level.waverespawndelay > 0;
	if ( flag( "start_zombie_round_logic") )
	{
		setlowermessage( game[ "strings" ][ "press_to_spawn" ] );
		if ( !spawnedasspectator )
		{
			self thread respawn_asspectator( self.origin + vectorScale( ( 0, 0, 1 ), 60 ), self.angles );
		}
		spawnedasspectator = 1;
		self waitrespawnorsafespawnbutton();
	}
	self.waitingtospawn = 0;
	self clearlowermessage();
	self.wavespawnindex = undefined;
	self.respawntimerstarttime = undefined;
	self thread [[ level.spawnplayer ]]();
}

waitrespawnorsafespawnbutton()
{
	self endon( "disconnect" );
	self endon( "end_respawn" );
	while ( 1 )
	{
		if ( self usebuttonpressed() )
		{
			return;
		}
		wait 0.05;
	}
}

spawnqueuedclient( dead_player_team, killer )
{
	maps/mp/gametypes_zm/_globallogic_utils::waittillslowprocessallowed();
	spawn_team = undefined;
	if ( isDefined( killer ) && isDefined( killer.team ) && isDefined( level.teams[ killer.team ] ) )
	{
		spawn_team = killer.team;
	}
	if ( isDefined( spawn_team ) )
	{
		spawnqueuedclientonteam( spawn_team );
		return;
	}
	foreach ( team in level.teams )
	{
		if ( team == dead_player_team )
		{
		}
		else
		{
			spawnqueuedclientonteam( team );
		}
	}
}

spawnqueuedclientonteam( team )
{
	player_to_spawn = undefined;
	for ( i = 0; i < level.deadplayers[ team ].size; i++ )
	{
		player = level.deadplayers[ team ][ i ];
		if ( player.waitingtospawn )
		{
		}
		else
		{
			player_to_spawn = player;
			break;
		}
	}
	if ( isDefined( player_to_spawn ) )
	{
		player_to_spawn.allowqueuespawn = 1;
		player_to_spawn maps/mp/gametypes_zm/_globallogic_ui::closemenus();
		player_to_spawn thread [[ level.spawnclient ]]();
	}
}

mayspawn() //checked partially changed to match cerberus output changed at own discretion
{
	if ( isDefined( level.mayspawn ) && !self [[ level.mayspawn ]]() )
	{
		return 0;
	}
	if ( level.inovertime )
	{
		return 0;
	}
	if ( level.playerqueuedrespawn && !isDefined( self.allowqueuespawn ) && !level.ingraceperiod && !level.usestartspawns )
	{
		return 0;
	}
	if ( level.numlives )
	{
		if ( level.teambased )
		{
			gamehasstarted = allteamshaveexisted();
		}
		else if ( level.maxplayercount > 1 || !isoneround() && !isfirstround() )
		{
			gamehasstarted = 1;
		}
		else
		{
			gamehasstarted = 0;
		}
		if ( !self.pers[ "lives" ] )
		{
			return 0;
		}
		else if ( gamehasstarted )
		{
			if ( !level.ingraceperiod && !self.hasspawned && !level.wagermatch )
			{
				return 0;
			}
		}
	}
	return 1;
}

spawnplayer() //checked matches cerberus output dvars taken from beta dump
{
	pixbeginevent( "spawnPlayer_preUTS" );
	self endon( "disconnect" );
	self endon( "joined_spectators" );
	self notify( "spawned" );
	level notify( "player_spawned" );
	self notify( "end_respawn", "spawnplayer" );
	self setspawnvariables();
	if ( level.teambased )
	{
		self.sessionteam = self.team;
	}
	else
	{
		self.sessionteam = "none";
		self.ffateam = self.team;
	}
	hadspawned = self.hasspawned;
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.damagedplayers = [];
	if ( getDvarInt( "scr_csmode" ) > 0 )
	{
		self.maxhealth = getDvarInt( "scr_csmode" );
	}
	else
	{
		self.maxhealth = level.playermaxhealth;
	}
	self.health = self.maxhealth;
	self.friendlydamage = undefined;
	self.hasspawned = 1;
	self.spawntime = getTime();
	self.afk = 0;
	if ( self.pers[ "lives" ] && !isDefined( level.takelivesondeath ) || level.takelivesondeath == 0 )
	{
		self.pers[ "lives" ]--;
		if ( self.pers[ "lives" ] == 0 )
		{
			level notify( "player_eliminated" );
			self notify( "player_eliminated" );
		}
	}
	self.laststand = undefined;
	self.revivingteammate = 0;
	self.burning = undefined;
	self.nextkillstreakfree = undefined;
	self.activeuavs = 0;
	self.activecounteruavs = 0;
	self.activesatellites = 0;
	self.deathmachinekills = 0;
	self.disabledweapon = 0;
	self resetusability();
	self maps/mp/gametypes_zm/_globallogic_player::resetattackerlist();
	self.diedonvehicle = undefined;
	if ( !self.wasaliveatmatchstart )
	{
		if ( level.ingraceperiod || maps/mp/gametypes_zm/_globallogic_utils::gettimepassed() < 20000 )
		{
			self.wasaliveatmatchstart = 1;
		}
	}
	self setdepthoffield( 0, 0, 512, 512, 4, 0 );
	self resetfov();
	pixbeginevent( "onSpawnPlayer" );
	if ( isDefined( level.onspawnplayerunified ) )
	{
		self [[ level.onspawnplayerunified ]]();
	}
	else
	{
		self [[ level.onspawnplayer ]]( 0 );
	}
	if ( isDefined( level.playerspawnedcb ) )
	{
		self [[ level.playerspawnedcb ]]();
	}
	pixendevent();
	pixendevent();
	level thread maps/mp/gametypes_zm/_globallogic::updateteamstatus();
	pixbeginevent( "spawnPlayer_postUTS" );
	self thread stoppoisoningandflareonspawn();
	self stopburning();
	self giveloadoutlevelspecific( self.team, self.class );
	if ( level.inprematchperiod )
	{
		self freeze_player_controls( 1 );
	}
	else
	{
		self freeze_player_controls( 0 );
		self enableweapons();
	}
	pixendevent();
	waittillframeend;
	self notify( "spawned_player", "spawnplayer" );
	setdvar( "scr_selecting_location", "" );
	self maps/mp/zombies/_zm_perks::perk_set_max_health_if_jugg( "health_reboot", 1, 0 );
	if ( game[ "state" ] == "postgame" )
	{
		self maps/mp/gametypes_zm/_globallogic_player::freezeplayerforroundend();
	}
}

menuallieszombies() //checked changed to match cerberus output
{
	self maps/mp/gametypes_zm/_globallogic_ui::closemenus();
	if ( !level.console && level.allow_teamchange == "0" && is_true( self.hasdonecombat ) )
	{
		return;
	}
	if ( self.pers[ "team" ] != "allies" )
	{
		if ( level.ingraceperiod && !isDefined( self.hasdonecombat ) || !self.hasdonecombat )
		{
			self.hasspawned = 0;
		}
		if ( self.sessionstate == "playing" )
		{
			self.switching_teams = 1;
			self.joining_team = "allies";
			self.leaving_team = self.pers[ "team" ];
			self suicide();
		}
		self.pers["team"] = "allies";
		self.team = "allies";
		self.pers["class"] = undefined;
		self.class = undefined;
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;
		self updateobjectivetext();
		if ( level.teambased )
		{
			self.sessionteam = "allies";
		}
		else
		{
			self.sessionteam = "none";
			self.ffateam = "allies";
		}
		self setclientscriptmainmenu( game[ "menu_class" ] );
		self notify( "joined_team" );
		level notify( "joined_team" );
		self notify( "end_respawn", "menualliszombies" );
	}
}

spawnspectator( origin, angles ) //checked matches cerberus output
{
	self notify( "spawned" );
	self notify( "end_respawn", "spawnspectator" );
	in_spawnspectator( origin, angles );
}

respawn_asspectator( origin, angles ) //checked matches cerberus output
{
	in_spawnspectator( origin, angles );
}

in_spawnspectator( origin, angles ) //checked matches cerberus output
{
	pixmarker( "BEGIN: in_spawnSpectator" );
	self setspawnvariables();
	if ( self.pers[ "team" ] == "spectator" )
	{
		self clearlowermessage();
	}
	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;
	if ( self.pers[ "team" ] == "spectator" )
	{
		self.statusicon = "";
	}
	else
	{
		self.statusicon = "hud_status_dead";
	}
	maps/mp/gametypes_zm/_spectating::setspectatepermissionsformachine();
	[[ level.onspawnspectator ]]( origin, angles );
	if ( level.teambased && !level.splitscreen )
	{
		self thread spectatorthirdpersonness();
	}
	level thread maps/mp/gametypes_zm/_globallogic::updateteamstatus();
	pixmarker( "END: in_spawnSpectator" );
}

check_for_end_respawn()
{
	while ( true )
	{
		self waittill( "end_respawn", who_ended );
        if ( isDefined( who_ended ) )
        {
		    logline1 = "check_for_end_respawn() " + who_ended + " " + self.name + "\n";
		    logprint( logline1 );
        }
        else 
        {
            logline1 = "check_for_end_respawn() notify parameter is undefined" + "\n";
		    logprint( logline1 );
        }
	}
}

custommayspawn() //checked matches cerberus output
{
	if ( isDefined( level.custommayspawnlogic ) )
	{
		return self [[ level.custommayspawnlogic ]]();
	}
	if ( self.pers[ "lives" ] == 0 )
	{
		level notify( "player_eliminated" );
		self notify( "player_eliminated" );
		return 0;
	}
	return 1;
}

zombify_player() //checked matches cerberus output
{
	self maps/mp/zombies/_zm_score::player_died_penalty();
	bbprint( "zombie_playerdeaths", "round %d playername %s deathtype %s x %f y %f z %f", level.round_number, self.name, "died", self.origin );
	self recordplayerdeathzombies();
	if ( isDefined( level.deathcard_spawn_func ) )
	{
		self [[ level.deathcard_spawn_func ]]();
	}
	if ( !isDefined( level.zombie_vars[ "zombify_player" ] ) || !level.zombie_vars[ "zombify_player" ] )
	{
		self thread spawnspectatorzm();
		return;
	}
	self.ignoreme = 1;
	self.is_zombie = 1;
	self.zombification_time = getTime();
	self.team = level.zombie_team;
	self notify( "zombified" );
	if ( isDefined( self.revivetrigger ) )
	{
		self.revivetrigger delete();
	}
	self.revivetrigger = undefined;
	self setmovespeedscale( 0.3 );
	self reviveplayer();
	self takeallweapons();
	self giveweapon( "zombie_melee", 0 );
	self switchtoweapon( "zombie_melee" );
	self disableweaponcycling();
	self disableoffhandweapons();
	setclientsysstate( "zombify", 1, self );
	self thread maps/mp/zombies/_zm_spawner::zombie_eye_glow();
	self thread playerzombie_player_damage();
	self thread playerzombie_soundboard();
}

spawnspectatorzm() //checked matches cerberus output
{
	self endon( "disconnect" );
	self endon( "spawned_spectator" );
	self notify( "spawned" );
	self notify( "end_respawn", "spawnspectatorzm" );
	if ( level.intermission )
	{
		return;
	}
	if ( is_true( level.no_spectator ) )
	{
		wait 3;
		exitlevel();
	}
	self.is_zombie = 1;
	level thread failsafe_revive_give_back_weapons( self );
	self notify( "zombified" );
	if ( isDefined( self.revivetrigger ) )
	{
		self.revivetrigger delete();
		self.revivetrigger = undefined;
	}
	self.zombification_time = getTime();
	resettimeout();
	self stopshellshock();
	self stoprumble( "damage_heavy" );
	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.maxhealth = self.health;
	self.shellshocked = 0;
	self.inwater = 0;
	self.friendlydamage = undefined;
	self.hasspawned = 1;
	self.spawntime = getTime();
	self.afk = 0;
	self detachall();
	if ( isDefined( level.custom_spectate_permissions ) )
	{
		self [[ level.custom_spectate_permissions ]]();
	}
	else
	{
		self setspectatepermissions( 1 );
	}
	self thread spectator_thread();
	self spawn( self.origin, self.angles );
	self notify( "spawned_spectator" );
}

menuautoassign( comingfrommenu ) //checked changed to match cerberus output
{
	teamkeys = getarraykeys( level.teams );
	assignment = teamkeys[ randomint( teamkeys.size ) ];
	self closemenus();
	if ( is_true( level.forceallallies ) )
	{
		assignment = "allies";
	}
	else if ( level.teambased )
	{
		if ( getDvarInt( "party_autoteams" ) == 1 )
		{
			if ( level.allow_teamchange == "1" || self.hasspawned && comingfrommenu )
			{
				assignment = "";
			}
		}
		else
		{
			team = getassignedteam( self );
			switch( team )
			{
				case 1:
					assignment = teamkeys[ 1 ];
					break;
				case 2:
					assignment = teamkeys[ 0 ];
					break;
				case 3:
					assignment = teamkeys[ 2 ];
					break;
				case 4:
					if ( !isDefined( level.forceautoassign ) || !level.forceautoassign )
					{
						self setclientscriptmainmenu( game[ "menu_class" ] );
						return;
					}
				default:
					assignment = "";
					if ( isDefined( level.teams[ team ] ) )
					{
						assignment = team;
					}
					else if ( team == "spectator" && !level.forceautoassign )
					{
						self setclientscriptmainmenu( game[ "menu_class" ] );
						return;
					}
			}
		}
		if ( assignment == "" || getDvarInt( "party_autoteams" ) == 0 )
		{
			if ( sessionmodeiszombiesgame() )
			{
				assignment = "allies";
			}
		}
		if ( assignment == self.pers[ "team" ] && self.sessionstate == "playing" || self.sessionstate == "dead" )
		{
			self beginclasschoice();
			return;
		}
	}
	else if ( getDvarInt( "party_autoteams" ) == 1 )
	{
		if ( level.allow_teamchange != "1" || !self.hasspawned && !comingfrommenu )
		{
			team = getassignedteam( self );
			if ( isDefined( level.teams[ team ] ) )
			{
				assignment = team;
			}
			else if ( team == "spectator" && !level.forceautoassign )
			{
				self setclientscriptmainmenu( game[ "menu_class" ] );
				return;
			}
		}
	}
	if ( assignment != self.pers[ "team" ] && self.sessionstate == "playing" || self.sessionstate == "dead" )
	{
		self.switching_teams = 1;
		self.joining_team = assignment;
		self.leaving_team = self.pers[ "team" ];
		self suicide();
	}
	self.pers[ "team" ] = assignment;
	self.team = assignment;
	self.pers["class"] = undefined;
	self.class = undefined;
	self.pers["weapon"] = undefined;
	self.pers["savedmodel"] = undefined;
	self updateobjectivetext();
	if ( level.teambased )
	{
		self.sessionteam = assignment;
	}
	else
	{
		self.sessionteam = "none";
		self.ffateam = assignment;
	}
	if ( !isalive( self ) )
	{
		self.statusicon = "hud_status_dead";
	}
	self notify( "joined_team" );
	level notify( "joined_team" );
	self notify( "end_respawn", "menuautoassign" );
	if ( ispregamegamestarted() )
	{
		if ( self is_bot() && isDefined( self.pers[ "class" ] ) )
		{
			pclass = self.pers[ "class" ];
			self closemenu();
			self closeingamemenu();
			self.selectedclass = 1;
			self [[ level.class ]]( pclass );
			return;
		}
	}
	self beginclasschoice();
	self setclientscriptmainmenu( game[ "menu_class" ] );
}


menuteam( team ) //checked changed to match cerberus output
{
	self closemenus();
	if ( !level.console && level.allow_teamchange == "0" && is_true( self.hasdonecombat ) )
	{
		return;
	}
	if ( self.pers[ "team" ] != team )
	{
		if ( level.ingraceperiod && !isDefined( self.hasdonecombat ) || !self.hasdonecombat )
		{
			self.hasspawned = 0;
		}
		if ( self.sessionstate == "playing" )
		{
			self.switching_teams = 1;
			self.joining_team = team;
			self.leaving_team = self.pers[ "team" ];
			self suicide();
		}
		self.pers[ "team" ] = team;
		self.team = team;
		self.pers[ "class" ] = undefined;
		self.class = undefined;
		self.pers[ "weapon" ] = undefined;
		self.pers[ "savedmodel" ] = undefined;
		self updateobjectivetext();
		if ( !level.rankedmatch && !level.leaguematch )
		{
			self.sessionstate = "spectator";
		}
		if ( level.teambased )
		{
			self.sessionteam = team;
		}
		else
		{
			self.sessionteam = "none";
			self.ffateam = team;
		}
		self setclientscriptmainmenu( game[ "menu_class" ] );
		self notify( "joined_team" );
		level notify( "joined_team" );
		self notify( "end_respawn", "menuteam" );
	}
	self beginclasschoice();
}

giveloadoutlevelspecific( team, class ) //checked matches cerberus output
{
	pixbeginevent( "giveLoadoutLevelSpecific" );
	if ( isDefined( level.givecustomcharacters ) )
	{
		self [[ level.givecustomcharacters ]]();
	}
	if ( isDefined( level.givecustomloadout ) )
	{
		self [[ level.givecustomloadout ]]();
	}
	pixendevent();
}