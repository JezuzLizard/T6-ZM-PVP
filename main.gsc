#include maps/mp/gametypes_zm/_globallogic_spawn;
#include maps/mp/gametypes_zm/_spectating;
#include maps/mp/_challenges;
#include maps/mp/gametypes_zm/_globallogic;
#include maps/mp/_utility;
#include common_scripts/utility;
#include maps/mp/gametypes_zm/_globallogic_vehicle;
#include maps/mp/_burnplayer;
#include maps/mp/gametypes_zm/_deathicons;
#include maps/mp/gametypes_zm/_tweakables;
#include maps/mp/gametypes_zm/_globallogic_audio;
#include maps/mp/gametypes_zm/_spawnlogic;
#include maps/mp/_medals;
#include maps/mp/_challenges;
#include maps/mp/gametypes_zm/_rank;
#include maps/mp/teams/_teams;
#include maps/mp/_demo;
#include maps/mp/gametypes_zm/_weapon_utils;
#include maps/mp/gametypes_zm/_damagefeedback;
#include maps/mp/gametypes_zm/_weapons;
#include maps/mp/_scoreevents;
#include maps/mp/_vehicles;
#include maps/mp/gametypes_zm/_hud_message;
#include maps/mp/gametypes_zm/_spawning;
#include maps/mp/gametypes_zm/_globallogic_utils;
#include maps/mp/gametypes_zm/_globallogic_player;
#include maps/mp/gametypes_zm/_globallogic_ui;
#include maps/mp/gametypes_zm/_hostmigration;
#include maps/mp/gametypes_zm/_globallogic_score;
#include maps/mp/_gamerep;
#include maps/mp/gametypes_zm/_persistence;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm;

init() //checked matches cerberus output
{
	precachestring( &"PLATFORM_PRESS_TO_SKIP" );
	precachestring( &"PLATFORM_PRESS_TO_RESPAWN" );
	precacheshader( "white" );
	precacheshader( "zombies_rank_5" );
	precacheshader( "emblem_bg_default" );
	level.killcam = getgametypesetting( "allowKillcam" );
	level.finalkillcam = 1;
	level.allow_zombie_killcams = getDvarIntDefault( "allow_zombie_killcams", 0 );
	initfinalkillcam();
	level.round_wait_func = ::round_wait;
	level.callbackactorkilled = ::actor_killed_override;
    level.callbackplayerkilled = ::callback_playerkilled;
    level.playerlaststand_func = undefined;
	level.callbackplayerlaststand = undefined;
	level.spawnclient = ::spawnclient;
	level.spawnplayer = ::spawnplayer;
	level.spawnspectator = ::spawnspectator;
	level.allies = ::menuallieszombies;
	level.mayspawn = ::custommayspawn;
	level.player_becomes_zombie = ::zombify_player;
	level.autoassign = ::menuautoassign;
	level.teammenu = ::menuteam;
	level.hotjoin_player_setup = undefined;
    level thread on_player_connect();
	level.no_end_game_check = true;
	level thread doFinalKillcam();
	level thread open_seseme();

	maps\mp\gametypes_zm\_globallogic_utils::registerPostRoundEvent(::postRoundFinalKillcam);

	// hitmarker mod
	thread init_hitmarkers();
	level.test_team_index = 0;
}

on_player_connect()
{
    for(;;)
	{
        level waittill("connected", player);
		player thread check_for_end_respawn();
		//player thread [[ level.spawnplayer ]]();
		player thread on_player_spawned();
		//player thread save_player_loadout();
		player.overlayOn = false;
        player set_team();
		player.pers[ "lives" ] = 9999;
		player thread end_game_bind();
    }
}

on_player_spawned()
{
	self endon("disconnect");
	level endon("end_game");
    self.firstSpawn = true;
    for(;;)
    {
        self waittill("spawned_player");
		//self restore_player_loadout();
		self.score += 5000;
	}
}

end_game_bind()
{
	self endon("disconnect");
	level endon("end_game");
	level endon("game_emded");
	for(;;) {
		if (self ActionSlotOneButtonPressed()) {
			level thread customendgame(self, "Idk");
			wait 0.02;
		}
		if (self ActionSlotTwoButtonPressed()) {
			self iprintln("overlay attempted");
			if (!self.overlayOn) {
				self overlay(true, self, true);
				self setClientUIVisibilityFlag( "hud_visible", 0 );
				self.overlayOn = true;
			} else {
				self overlay(false);
				self setClientUIVisibilityFlag( "hud_visible", 1 );
				self.overlayOn = false;
			}
			wait 0.02;
		}
		if (self ActionSlotThreeButtonPressed()) {
			self iprintln("spawning test client");
			AddTestClient();
			wait 0.02;
		}
		wait 0.02;
	}
}

set_team()
{
	/*
	if ( level.test_team_index == 0 )
	{
		self.team = "axis";
		self.sessionteam = "axis";
	 	self.pers[ "team" ] = "axis";
		self._encounters_team = "A";
	}
	else if ( level.test_team_index == 1 )
	{
		self.team = "allies";
		self.sessionteam = "allies";
		self.pers[ "team" ] = "allies";
		self._encounters_team = "B";
	}
	else 
	{
		if ( level.test_team_index < 3 )
		{
			level.test_team_index = 4;
		}
		self.team = "team" + level.test_team_index;
		self.sessionteam = "team" + level.test_team_index;
		self.pers[ "team" ] = "team" + level.test_team_index;
		self._encounters_team = "B";
	}
	level.test_team_index++;
	*/
	teamplayersallies = countplayers( "allies");
	teamplayersaxis = countplayers( "axis");
	if ( teamplayersallies > teamplayersaxis )
	{
		self.team = "axis";
		self.sessionteam = "axis";
	 	self.pers[ "team" ] = "axis";
		self._encounters_team = "A";
		logline1 = self.name + " placed on the axis team" + "\n";
		logprint( logline1 );
	}
	else if ( teamplayersallies < teamplayersaxis )
	{
		self.team = "allies";
		self.sessionteam = "allies";
		self.pers[ "team" ] = "allies";
		self._encounters_team = "B";
		logline1 = self.name + " placed on the allies team" + "\n";
		logprint( logline1 );
	}
	else
	{
		self.team = "allies";
		self.sessionteam = "allies";
		self.pers[ "team" ] = "allies";
		self._encounters_team = "B";
		logline1 = self.name + " placed on the allies team because teams are equal" + "\n";
		logprint( logline1 );
	}
}

/*

	hitmarker mod

*/

customendgame(winner, reason)
{
	if ( game["state"] == "postgame" || level.gameEnded )
		return;

	if ( isDefined( level.onEndGame ) )
		[[level.onEndGame]]( winner );
	
	if ( !level.wagerMatch )
		setMatchFlag( "enable_popups", 0 );
	if ( !isdefined( level.disableOutroVisionSet ) || level.disableOutroVisionSet == false ) 
	{
		if ( SessionModeIsZombiesGame() && level.forcedEnd )
		{
			visionSetNaked( "zombie_last_stand", 2.0 );
		}
		else
		{
			visionSetNaked( "mpOutro", 2.0 );
		}
	}
	
	setmatchflag( "cg_drawSpectatorMessages", 0 );
	setmatchflag( "game_ended", 1 );

	game_over = [];
	survived = [];
	players = get_players();
	setmatchflag( "disableIngameMenu", 1 );
	foreach ( player in players )
	{
		player closemenu();
		player closeingamemenu();
	}
	if ( !isDefined( level._supress_survived_screen ) )
	{
		for ( i = 0; i < players.size; i++ )
		{
			if ( isDefined( level.custom_game_over_hud_elem ) )
			{
				game_over[ i ] = [[ level.custom_game_over_hud_elem ]]( players[ i ] );
			}
			else
			{
				game_over[ i ] = newclienthudelem( players[ i ] );
				game_over[ i ].alignx = "center";
				game_over[ i ].aligny = "middle";
				game_over[ i ].horzalign = "center";
				game_over[ i ].vertalign = "middle";
				game_over[ i ].y -= 130;
				game_over[ i ].foreground = 1;
				game_over[ i ].fontscale = 3;
				game_over[ i ].alpha = 0;
				game_over[ i ].color = ( 1, 1, 1 );
				game_over[ i ].hidewheninmenu = 1;
				game_over[ i ] settext( &"ZOMBIE_GAME_OVER" );
				game_over[ i ] fadeovertime( 1 );
				game_over[ i ].alpha = 1;
			}
			survived[ i ] = newclienthudelem( players[ i ] );
			survived[ i ].alignx = "center";
			survived[ i ].aligny = "middle";
			survived[ i ].horzalign = "center";
			survived[ i ].vertalign = "middle";
			survived[ i ].y -= 100;
			survived[ i ].foreground = 1;
			survived[ i ].fontscale = 2;
			survived[ i ].alpha = 0;
			survived[ i ].color = ( 1, 1, 1 );
			survived[ i ].hidewheninmenu = 1;
			if ( level.round_number < 2 )
			{
				if ( level.script == "zombie_moon" )
				{
					if ( !isDefined( level.left_nomans_land ) )
					{
						nomanslandtime = level.nml_best_time;
						player_survival_time = int( nomanslandtime / 1000 );
						player_survival_time_in_mins = maps/mp/zombies/_zm::to_mins( player_survival_time );
						survived[ i ] settext( &"ZOMBIE_SURVIVED_NOMANS", player_survival_time_in_mins );
					}
					else if ( level.left_nomans_land == 2 )
					{
						survived[ i ] settext( &"ZOMBIE_SURVIVED_ROUND" );
					}
				}
				else
				{
					survived[ i ] settext( &"ZOMBIE_SURVIVED_ROUND" );
				}
			}
			else
			{
				survived[ i ] settext( &"ZOMBIE_SURVIVED_ROUNDS", level.round_number );
			}
			survived[ i ] fadeovertime( 1 );
			survived[ i ].alpha = 1;
		}
	}

	game["state"] = "postgame";
	level.gameEndTime = getTime();
	level.gameEnded = true;
	SetDvar( "g_gameEnded", 1 );
	level.inGracePeriod = false;
	level notify ( "game_ended" );
	level.allowBattleChatter = false;
	maps\mp\gametypes_zm\_globallogic_audio::flushDialog();

	if ( !IsDefined( game["overtime_round"] ) || wasLastRound() ) // Want to treat all overtime rounds as a single round
	{
		game["roundsplayed"]++;
		game["roundwinner"][game["roundsplayed"]] = winner;
	
		if( level.teambased )
		{
			game["roundswon"][winner]++;	
		}
	}

	if ( isdefined( winner ) && isdefined( level.teams[winner] ) )
	{
		level.finalKillCam_winner = winner;
	}
	else
	{
		level.finalKillCam_winner = "none";
	}
	
	setGameEndTime( 0 );
	
	maps\mp\gametypes_zm\_globallogic::updatePlacement();

	maps\mp\gametypes_zm\_globallogic::updateRankedMatch( winner );
	
	players = level.players;
	
	newTime = getTime();
	gameLength = getGameLength();
	
	SetMatchTalkFlag( "EveryoneHearsEveryone", 1 );

	bbGameOver = 0;
	if ( isOneRound() || wasLastRound() )
	{
		bbGameOver = 1;

		if ( level.teambased )
		{
			if ( winner == "tie" )
			{
				recordGameResult( "draw" );
			}
			else
			{
				recordGameResult( winner );
			}
		}
		else
		{
			if ( !isDefined( winner ) )
			{
				recordGameResult( "draw" );
			}
			else
			{
				recordGameResult( winner.team );
			}
		}
	}

	index = 0;
	while ( index < players.size )
	{
		player = players[index];
		player maps\mp\gametypes_zm\_globallogic_player::freezePlayerForRoundEnd();
		player thread roundEndDoF( 4.0 );

		player maps\mp\gametypes_zm\_globallogic_ui::freeGameplayHudElems();
		
		player maps\mp\gametypes_zm\_weapons::updateWeaponTimings( newTime );
		
		player maps\mp\gametypes_zm\_globallogic::bbPlayerMatchEnd( gameLength, endReasonText, bbGameOver );

		if( isPregame() )
		{
			index++;
			continue;
		}

		if( level.rankedMatch || level.wagerMatch || level.leagueMatch )
		{
			if ( isDefined( player.setPromotion ) )
			{
				player setDStat( "AfterActionReportStats", "lobbyPopup", "promotion" );
			}
			else
			{
				player setDStat( "AfterActionReportStats", "lobbyPopup", "summary" );
			}
		}
		index++;
	}

	maps\mp\_music::setmusicstate( "SILENT" );

	if ( !level.inFinalKillcam )
	{
		// why does nothing happen here? lmaooo -mikey
	}

	thread maps\mp\_challenges::roundEnd( winner );

	if ( startNextRound( winner, endReasonText ) )
	{
		return;
	}
	
	///////////////////////////////////////////
	// After this the match is really ending //
	///////////////////////////////////////////

	if ( !isOneRound() )
	{
		if ( isDefined( level.onRoundEndGame ) )
		{
			winner = [[level.onRoundEndGame]]( winner );
		}

		endReasonText = getEndReasonText();
	}
	
	skillUpdate( winner, level.teamBased );
	recordLeagueWinner( winner );
	
	maps\mp\gametypes_zm\_globallogic::setTopPlayerStats();
	thread maps\mp\_challenges::gameEnd( winner );

	if ( ( !isDefined( level.skipGameEnd ) || !level.skipGameEnd ) && IsDefined( winner ) )
		maps\mp\gametypes_zm\_globallogic::displayGameEnd( winner, endReasonText );
	
	players = get_players();
	if ( !isDefined( level._supress_survived_screen ) )
	{
		for(i = 0; i < players.size; i++)
		{
			survived[ i ] destroy();
			game_over[ i ] destroy();
		}
	}
	for ( i = 0; i < players.size; i++ )
	{
		if ( isDefined( players[ i ].survived_hud ) )
		{
			players[ i ].survived_hud destroy();
		}
		if ( isDefined( players[ i ].game_over_hud ) )
		{
			players[ i ].game_over_hud destroy();
		}
	}

	//postroundfinalkillcam();
	//level waittill("final_killcam_done");

	if ( isOneRound() )
	{
		maps\mp\gametypes_zm\_globallogic_utils::executePostRoundEvents();
	}
		
	level.intermission = true;
	
	SetMatchTalkFlag( "EveryoneHearsEveryone", 1 );

	//regain players array since some might've disconnected during the wait above
	players = level.players;
	for ( index = 0; index < players.size; index++ )
	{
		player = players[index];
		
		recordPlayerStats( player, "presentAtEnd", 1 );

		player closeMenu();
		player closeInGameMenu();
		player notify ( "reset_outcome" );
		player thread [[level.spawnIntermission]]();
        player setClientUIVisibilityFlag( "hud_visible", 1 );
	}
	//Eckert - Fading out sound
	level notify ( "sfade");
	logString( "game ended" );

	exitLevel( false );
} 

//callback_playerkilled( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration )
actor_killed_override( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime ) //checked matches cerberus output
{
	if ( isDefined( game[ "state" ] ) && game[ "state" ] == "postgame" )
	{
		return;
	}
	if ( isai( attacker ) && isDefined( attacker.script_owner ) )
	{
		if ( attacker.script_owner.team != self.team ) //changed to match bo3 _zm.gsc
		{
			attacker = attacker.script_owner;
		}
	}
	if ( attacker.classname == "script_vehicle" && isDefined( attacker.owner ) )
	{
		attacker = attacker.owner;
	}
	if ( isDefined( attacker ) && isplayer( attacker ) )
	{
		multiplier = 1;
		if ( is_headshot( sweapon, shitloc, smeansofdeath ) )
		{
			multiplier = 1.5;
		}
		type = undefined;
		if ( isDefined( self.animname ) )
		{
			switch( self.animname )
			{
				case "quad_zombie":
					type = "quadkill";
					break;
				case "ape_zombie":
					type = "apekill";
					break;
				case "zombie":
					type = "zombiekill";
					break;
				case "zombie_dog":
					type = "dogkill";
					break;
			}
		}
	}
	if ( is_true( self.is_ziplining ) )
	{
		self.deathanim = undefined;
	}
	if ( isDefined( self.actor_killed_override ) )
	{
		self [[ self.actor_killed_override ]]( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime );
	}
	
	attacker = updateattacker( attacker, sweapon );
	einflictor = updateinflictor( einflictor );

	if (!isPlayer(attacker) || !is_true( level.allow_zombie_killcams ) ) {
		return;
	}

	// killcam here?
	killcamentity = self getkillcamentity( attacker, einflictor, sweapon );
	killcamentityindex = -1;
	killcamentitystarttime = 0;
	if ( isDefined( killcamentity ) )
	{
		killcamentityindex = killcamentity getentitynumber();
		if ( isDefined( killcamentity.starttime ) )
		{
			killcamentitystarttime = killcamentity.starttime;
		}
		else
		{
			killcamentitystarttime = killcamentity.birthtime;
		}
		if ( !isDefined( killcamentitystarttime ) )
		{
			killcamentitystarttime = 0;
		}
	}
	lpattacknum = attacker getentitynumber();
	dokillcam = 1;
	willrespawnimmediately = 0;
	self.deathtime = getTime();
	deathtimeoffset = 0;
	perks = [];
	level thread recordkillcamsettings( lpattacknum, self getentitynumber(), sweapon, self.deathtime, deathtimeoffset, psoffsettime, killcamentityindex, killcamentitystarttime, perks, attacker );
	wait 0.05;
	weaponclass = getweaponclasszm( sweapon );
	self.cancelkillcam = 0;
	self thread cancelkillcamonuse();
	defaultplayerdeathwatchtime = 1.75;
	self.respawntimerstarttime = getTime();
	self thread killcam( lpattacknum, self getentitynumber(), killcamentity, killcamentityindex, killcamentitystarttime, sweapon, self.deathtime, deathtimeoffset, psoffsettime, willrespawnimmediately, maps/mp/gametypes_zm/_globallogic_utils::timeuntilroundend(), perks, attacker );
	if ( game[ "state" ] != "playing" )
	{
		logline1 = "game state isn't playing" + "\n";
		logprint( logline1 );
		self.sessionstate = "dead";
		self.spectatorclient = -1;
		self.killcamtargetentity = -1;
		self.killcamentity = -1;
		self.archivetime = 0;
		self.psoffsettime = 0;
		return;
	}
	userespawntime = 1;
	if ( isDefined( level.hostmigrationtimer ) )
	{
		userespawntime = 0;
	}
	timepassed = undefined;
	if ( isDefined( self.respawntimerstarttime ) && userespawntime )
	{
		timepassed = ( getTime() - self.respawntimerstarttime ) / 1000;
	}
	//self thread [[ level.spawnclient ]]( timepassed );
	self.respawntimerstarttime = undefined;
}

sendtoplayers(msg)
{
	foreach (player in level.players)
		player iprintln(msg);
}

round_wait() //checked changed to match cerberus output
{
	level endon( "restart_round" );
	wait 1;
	if ( flag( "dog_round" ) )
	{
		wait 7 ;
		while ( level.dog_intermission )
		{
			wait 0.5;
		}
	}
	while( 1 )
	{
		should_wait = 0;
		if ( isdefined( level.is_ghost_round_started ) && [[ level.is_ghost_round_started ]]() )
		{
			should_wait = 1;
		}
		//changed the logic here to make more sense
		//if ( get_current_zombie_count() > 0 && level.zombie_total > 0 && !level.intermission )
		if ( get_current_zombie_count() > 0 || level.zombie_total > 0 )
		{
			should_wait = 1;
		}
		if ( !should_wait )
		{
			return;
		}
		if ( flag( "end_round_wait" ) )
		{
			return;
		}
		wait 1;
	}
}

dropweaponfordeath( attacker, sweapon, smeansofdeath ) //checked matches cerberus output dvars taken from beta dump
{
	if ( level.disableweapondrop == 1 )
	{
		return;
	}
	weapon = self.lastdroppableweapon;
	if ( isDefined( self.droppeddeathweapon ) )
	{
		return;
	}
	if ( !isDefined( weapon ) )
	{
		return;
	}
	if ( weapon == "none" )
	{
		return;
	}
	if ( !self hasweapon( weapon ) )
	{
		return;
	}
	if ( !self anyammoforweaponmodes( weapon ) )
	{
		return;
	}
	if ( !shoulddroplimitedweapon( weapon, self ) )
	{
		return;
	}
	clipammo = self getweaponammoclip( weapon );
	stockammo = self getweaponammostock( weapon );
	clip_and_stock_ammo = clipammo + stockammo;
	if ( !clip_and_stock_ammo )
	{
		return;
	}
	stockmax = weaponmaxammo( weapon );
	if ( stockammo > stockmax )
	{
		stockammo = stockmax;
	}
	item = self dropitem( weapon );
	if ( !isDefined( item ) )
	{
		return;
	}
	droplimitedweapon( weapon, self, item );
	self.droppeddeathweapon = 1;
	item itemweaponsetammo( clipammo, stockammo );
	item.owner = self;
	item.ownersattacker = attacker;
	item.sweapon = sweapon;
	item.smeansofdeath = smeansofdeath;
	item thread watchpickup();
	item thread deletepickupafterawhile();
}

open_seseme()
{
	flag_wait( "initial_blackscreen_passed" );
	setdvar("zombie_unlock_all", 1);
	flag_set("power_on");
	players = get_players();
	zombie_doors = getentarray("zombie_door", "targetname");
	for(i = 0; i < zombie_doors.size; i++)
	{
		zombie_doors[i] notify("trigger");
		if(is_true(zombie_doors[i].power_door_ignore_flag_wait))
		{
			zombie_doors[i] notify("power_on");
		}
		wait(0.05);
	}
	zombie_airlock_doors = getentarray("zombie_airlock_buy", "targetname");
	for(i = 0; i < zombie_airlock_doors.size; i++)
	{
		zombie_airlock_doors[i] notify("trigger");
		wait(0.05);
	}
	zombie_debris = getentarray("zombie_debris", "targetname");
	for(i = 0; i < zombie_debris.size; i++)
	{
		zombie_debris[i] notify("trigger", players[0]);
		wait(0.05);
	}
	setdvar("zombie_unlock_all", 0);
}
