#include maps/mp/gametypes_zm/_globallogic_spawn;
#include maps/mp/gametypes_zm/_spectating;
#include maps/mp/_tacticalinsertion;
#include maps/mp/_challenges;
#include maps/mp/gametypes_zm/_globallogic;
#include maps/mp/gametypes_zm/_hud_util;
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
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/gametypes_zm/_spawning;
#include maps/mp/gametypes_zm/_globallogic_utils;
#include maps/mp/gametypes_zm/_spectating;
#include maps/mp/gametypes_zm/_globallogic_spawn;
#include maps/mp/gametypes_zm/_globallogic_player;
#include maps/mp/gametypes_zm/_globallogic_ui;
#include maps/mp/gametypes_zm/_hostmigration;
#include maps/mp/_flashgrenades;
#include maps/mp/gametypes_zm/_globallogic_score;
#include maps/mp/_gamerep;
#include maps/mp/gametypes_zm/_persistence;
#include maps/mp/gametypes_zm/_globallogic;
#include common_scripts/utility;
#include maps/mp/_utility;
#include maps/mp/zombies/_zm_utility;

init() //checked matches cerberus output
{
	precachestring( &"PLATFORM_PRESS_TO_SKIP" );
	precachestring( &"PLATFORM_PRESS_TO_RESPAWN" );
	precacheshader( "white" );
	level.killcam = getgametypesetting( "allowKillcam" );
	level.finalkillcam = 1;
	initfinalkillcam();
	level.round_wait_func = ::round_wait;
	level.callbackactorkilled = ::actor_killed_override;
    level.callbackplayerkilled = ::callback_playerkilled;
    level.playerlaststand_func = undefined;
	level.callbackplayerlaststand = undefined;
	level.spawnclient = ::spawnclient;
    level thread on_player_connect();
	level.no_end_game_check = 1;
	level thread doFinalKillcam();

	// hitmarker mod
	thread init_hitmarkers();
}

on_player_connect()
{
    while ( true )
    {
        level waittill( "connected", player );
        player set_team();
		player thread end_game_bind();
    }
}

end_game_bind()
{
	self endon("disconnect");
	level endon("end_game");
	for(;;) {
		if (self ActionSlotOneButtonPressed()) {
			self iprintln("called endgame");
			//postRoundFinalKillcam();
			//level waittill("final_killcam_done");
			// spawn
			self thread customendgame(self, "Killcam test!!!!");
			//break;
		}
		wait 0.02;
	}
}

set_team()
{
	teamplayersallies = countplayers( "allies");
	teamplayersaxis = countplayers( "axis");
	if ( teamplayersallies > teamplayersaxis && !level.isresetting_grief )
	{
		self.team = "axis";
		self.sessionteam = "axis";
	 	self.pers[ "team" ] = "axis";
		self._encounters_team = "A";
	}
	else if ( teamplayersallies < teamplayersaxis && !level.isresetting_grief)
	{
		self.team = "allies";
		self.sessionteam = "allies";
		self.pers[ "team" ] = "allies";
		self._encounters_team = "B";
	}
	else
	{
		self.team = "allies";
		self.sessionteam = "allies";
		self.pers[ "team" ] = "allies";
		self._encounters_team = "B";
	}
}

/*

	hitmarker mod

*/

customendgame(winner, reason)
{
	// return if already ending via host quit or victory
	if ( game["state"] == "postgame" || level.gameEnded )
		return;

	if ( isDefined( level.onEndGame ) )
		[[level.onEndGame]]( winner );

	//This wait was added possibly for wager match issues, but we think is no longer necessary. 
	//It was creating issues with multiple players calling this fuction when checking game score. In modes like HQ,
	//The game score is given to every player on the team that captured the HQ, so when the points are dished out it loops through
	//all players on that team and checks if the score limit has been reached. But since this wait occured before the game["state"]
	//could be set to "postgame" the check score thread would send the next player that reached the score limit into this function,
	//when the following code should only be hit once. If this wait turns out to be needed, we need to try pulling the game["state"] = "postgame";
	//up above the wait.
	//wait 0.05;
	
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
	
		//Added "if" check for FFA - Leif
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
	
	setGameEndTime( 0 ); // stop/hide the timers
	
	maps\mp\gametypes_zm\_globallogic::updatePlacement();

	maps\mp\gametypes_zm\_globallogic::updateRankedMatch( winner );
	
	// freeze players
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
		
		// Update weapon usage stats
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

	// temporarily disabling round end sound call to prevent the final killcam from not having sound
	if ( !level.inFinalKillcam )
	{
		//		clientnotify ( "snd_end_rnd" );
	}

	//maps\mp\_gamerep::gameRepUpdateInformationForRound();
	//	maps\mp\gametypes_zm\_wager::finalizeWagerRound();
	//	maps\mp\gametypes_zm\_gametype_variants::onRoundEnd();
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
	
	if ( isOneRound() )
	{
		maps\mp\gametypes_zm\_globallogic_utils::executePostRoundEvents();
	}
		
	level.intermission = true;

	//maps\mp\_gamerep::gameRepAnalyzeAndReport();

	//maps\mp\gametypes_zm\_wager::finalizeWagerGame();
	
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
	
	if ( !isDefined( level.skipGameEnd ) || !level.skipGameEnd ) {
		postRoundFinalKillcam();
		wait 5.0;
	}
	
	exitLevel( false );
}

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
	/*
	if ( isDefined( self.deathfunction ) ) //added from bo3 _zm.gsc
	{
		self [[ self.deathfunction ]]( eInflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime );
	}
	*/
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

