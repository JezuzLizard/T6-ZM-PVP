callback_playerkilled( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration ) //checked partially changed to match cerberus output changed at own discretion
{
	profilelog_begintiming( 7, "ship" );
	self endon( "spawned" );
	self notify( "killed_player" );
	if ( self.sessionteam == "spectator" )
	{
		return;
	}
	if ( game[ "state" ] == "postgame" )
	{
		return;
	}
	self needsrevive( 0 );
	if ( isDefined( self.burning ) && self.burning == 1 )
	{
		self setburn( 0 );
	}
	self.suicide = 0;
	self.teamkilled = 0;
	if ( isDefined( level.takelivesondeath ) && level.takelivesondeath == 1 )
	{
		if ( self.pers[ "lives" ] )
		{
			self.pers[ "lives" ]--;

			if ( self.pers[ "lives" ] == 0 )
			{
				level notify( "player_eliminated" );
				self notify( "player_eliminated" );
			}
		}
	}
	self thread flushgroupdialogonplayer( "item_destroyed" );
	sweapon = updateweapon( einflictor, sweapon );
	pixbeginevent( "PlayerKilled pre constants" );
	wasinlaststand = 0;
	deathtimeoffset = 0;
	lastweaponbeforedroppingintolaststand = undefined;
	attackerstance = undefined;
	self.laststandthislife = undefined;
	self.vattackerorigin = undefined;
	if ( isDefined( self.uselaststandparams ) )
	{
		self.uselaststandparams = undefined;
		if ( !level.teambased || !isDefined( attacker ) || !isplayer( attacker ) || attacker.team != self.team || attacker == self )
		{
			einflictor = self.laststandparams.einflictor;
			attacker = self.laststandparams.attacker;
			attackerstance = self.laststandparams.attackerstance;
			idamage = self.laststandparams.idamage;
			smeansofdeath = self.laststandparams.smeansofdeath;
			sweapon = self.laststandparams.sweapon;
			vdir = self.laststandparams.vdir;
			shitloc = self.laststandparams.shitloc;
			self.vattackerorigin = self.laststandparams.vattackerorigin;
			deathtimeoffset = ( getTime() - self.laststandparams.laststandstarttime ) / 1000;
			if ( isDefined( self.previousprimary ) )
			{
				wasinlaststand = 1;
				lastweaponbeforedroppingintolaststand = self.previousprimary;
			}
		}
		self.laststandparams = undefined;
	}
	bestplayer = undefined;
	bestplayermeansofdeath = undefined;
	obituarymeansofdeath = undefined;
	bestplayerweapon = undefined;
	obituaryweapon = sweapon;
	assistedsuicide = 0;
	if ( !isDefined( attacker ) || attacker.classname == "trigger_hurt" || attacker.classname == "worldspawn" || isDefined( attacker.ismagicbullet ) && attacker.ismagicbullet != 1 || attacker == self && isDefined( self.attackers ) )
	{
		if ( !isDefined( bestplayer ) )
		{
			i = 0;
			while ( i < self.attackers.size )
			{
				player = self.attackers[ i ];
				if ( !isDefined( player ) )
				{
					i++;
					continue;
				}
				if ( !isDefined( self.attackerdamage[ player.clientid ] ) || !isDefined( self.attackerdamage[ player.clientid ].damage ) )
				{
					i++;
					continue;
				}
				if ( player == self || level.teambased && player.team == self.team )
				{
					i++;
					continue;
				}
				if ( ( self.attackerdamage[ player.clientid ].lasttimedamaged + 2500 ) < getTime() )
				{
					i++;
					continue;
				}
				if ( !allowedassistweapon( self.attackerdamage[ player.clientid ].weapon ) )
				{
					i++;
					continue;
				}
				if ( self.attackerdamage[ player.clientid ].damage > 1 && !isDefined( bestplayer ) )
				{
					bestplayer = player;
					bestplayermeansofdeath = self.attackerdamage[ player.clientid ].meansofdeath;
					bestplayerweapon = self.attackerdamage[ player.clientid ].weapon;
					i++;
					continue;
				}
				if ( isDefined( bestplayer ) && self.attackerdamage[ player.clientid ].damage > self.attackerdamage[ bestplayer.clientid ].damage )
				{
					bestplayer = player;
					bestplayermeansofdeath = self.attackerdamage[ player.clientid ].meansofdeath;
					bestplayerweapon = self.attackerdamage[ player.clientid ].weapon;
				}
				i++;
			}
		}
		if ( isDefined( bestplayer ) )
		{
			self recordkillmodifier( "assistedsuicide" );
			assistedsuicide = 1;
		}
	}
	if ( isDefined( bestplayer ) )
	{
		attacker = bestplayer;
		obituarymeansofdeath = bestplayermeansofdeath;
		obituaryweapon = bestplayerweapon;
		if ( isDefined( bestplayerweapon ) )
		{
			sweapon = bestplayerweapon;
		}
	}
	if ( isplayer( attacker ) )
	{
		attacker.damagedplayers[ self.clientid ] = undefined;
	}
	self.deathtime = getTime();
	attacker = updateattacker( attacker, sweapon );
	einflictor = updateinflictor( einflictor );
	smeansofdeath = self playerkilled_updatemeansofdeath( attacker, einflictor, sweapon, smeansofdeath, shitloc );
	if ( !isDefined( obituarymeansofdeath ) )
	{
		obituarymeansofdeath = smeansofdeath;
	}
	if ( isDefined( self.hasriotshieldequipped ) && self.hasriotshieldequipped == 1 )
	{
		self detachshieldmodel( level.carriedshieldmodel, "tag_weapon_left" );
		self.hasriotshield = 0;
		self.hasriotshieldequipped = 0;
	}
	self thread updateglobalbotkilledcounter();
	//self playerkilled_weaponstats( attacker, sweapon, smeansofdeath, wasinlaststand, lastweaponbeforedroppingintolaststand, einflictor );
	self playerkilled_obituary( attacker, einflictor, obituaryweapon, obituarymeansofdeath );
	maps/mp/gametypes_zm/_spawnlogic::deathoccured( self, attacker );
	self.sessionstate = "dead";
	self.statusicon = "hud_status_dead";
	self.pers[ "weapon" ] = undefined;
	self.killedplayerscurrent = [];
	self.deathcount++;
	//self playerkilled_killstreaks( attacker, sweapon );
	lpselfnum = self getentitynumber();
	lpselfname = self.name;
	lpattackguid = "";
	lpattackname = "";
	lpselfteam = self.team;
	lpselfguid = self getguid();
	lpattackteam = "";
	lpattackorigin = ( 0, 0, 0 );
	lpattacknum = -1;
	awardassists = 0;
	wasteamkill = 0;
	wassuicide = 0;
	pixendevent();
	self.pers[ "resetMomentumOnSpawn" ] = 1;
	if ( isplayer( attacker ) )
	{
		lpattackguid = attacker getguid();
		lpattackname = attacker.name;
		lpattackteam = attacker.team;
		lpattackorigin = attacker.origin;
		if ( attacker == self || assistedsuicide == 1 )
		{
			dokillcam = 0;
			wassuicide = 1;
			//awardassists = self playerkilled_suicide( einflictor, attacker, smeansofdeath, sweapon, shitloc );
		}
		else
		{
			pixbeginevent( "PlayerKilled attacker" );
			lpattacknum = attacker getentitynumber();
			dokillcam = 1;
			if ( level.teambased && self.team == attacker.team && smeansofdeath == "MOD_GRENADE" && level.friendlyfire == 0 )
			{
			}
			else if ( level.teambased && self.team == attacker.team )
			{
				wasteamkill = 1;
				//self playerkilled_teamkill( einflictor, attacker, smeansofdeath, sweapon, shitloc );
			}
			else
			{
				//self playerkilled_kill( einflictor, attacker, smeansofdeath, sweapon, shitloc );
				if ( level.teambased )
				{
					awardassists = 1;
				}
			}
			pixendevent();
		}
	}
	else if ( isDefined( attacker ) && attacker.classname == "trigger_hurt" || attacker.classname == "worldspawn" )
	{
		dokillcam = 0;
		lpattacknum = -1;
		lpattackguid = "";
		lpattackname = "";
		lpattackteam = "world";
		self maps/mp/gametypes_zm/_globallogic_score::incpersstat( "suicides", 1 );
		self.suicides = self maps/mp/gametypes_zm/_globallogic_score::getpersstat( "suicides" );
		self.suicide = 1;
		awardassists = 1;
	}
	else
	{
		dokillcam = 0;
		lpattacknum = -1;
		lpattackguid = "";
		lpattackname = "";
		lpattackteam = "world";
		wassuicide = 1;
		if ( isDefined( einflictor ) && isDefined( einflictor.killcament ) )
		{
			dokillcam = 1;
			lpattacknum = self getentitynumber();
			wassuicide = 0;
		}
		if ( isDefined( attacker ) && isDefined( attacker.team ) && isDefined( level.teams[ attacker.team ] ) )
		{
			if ( attacker.team != self.team )
			{
				if ( level.teambased )
				{
					maps/mp/gametypes_zm/_globallogic_score::giveteamscore( "kill", attacker.team, attacker, self );
				}
				wassuicide = 0;
			}
		}
		awardassists = 1;
	}
	if ( !level.ingraceperiod )
	{
		if ( smeansofdeath != "MOD_GRENADE" && smeansofdeath != "MOD_GRENADE_SPLASH" && smeansofdeath != "MOD_EXPLOSIVE" && smeansofdeath != "MOD_EXPLOSIVE_SPLASH" && smeansofdeath != "MOD_PROJECTILE_SPLASH" )
		{
			self maps/mp/gametypes_zm/_weapons::dropscavengerfordeath( attacker );
		}
		if ( !wasteamkill && !wassuicide )
		{
			self dropweaponfordeath( attacker, sweapon, smeansofdeath );
			self maps/mp/gametypes_zm/_weapons::dropoffhand();
		}
	}
	pixbeginevent( "PlayerKilled post constants" );
	self.lastattacker = attacker;
	self.lastdeathpos = self.origin;
	if ( ( !level.teambased || attacker.team != self.team ) && isDefined( attacker ) && isplayer( attacker ) && attacker != self )
	{
		self thread maps/mp/_challenges::playerkilled( einflictor, attacker, idamage, smeansofdeath, sweapon, shitloc, attackerstance );
	}
	else
	{
		self notify( "playerKilledChallengesProcessed" );
	}
	if ( isDefined( self.attackers ) )
	{
		self.attackers = [];
	}
	logprint( "K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sweapon + ";" + idamage + ";" + smeansofdeath + ";" + shitloc + "\n" );
	attackerstring = "none";
	if ( isplayer( attacker ) )
	{
		attackerstring = attacker getxuid() + "(" + lpattackname + ")";
	}
	self logstring( "d " + smeansofdeath + "(" + sweapon + ") a:" + attackerstring + " d:" + idamage + " l:" + shitloc + " @ " + int( self.origin[ 0 ] ) + " " + int( self.origin[ 1 ] ) + " " + int( self.origin[ 2 ] ) );
	level thread maps/mp/gametypes_zm/_globallogic::updateteamstatus();
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
	if ( isDefined( self.killstreak_waitamount ) && self.killstreak_waitamount > 0 )
	{
		dokillcam = 0;
	}
	self maps/mp/gametypes_zm/_weapons::detachcarryobjectmodel();
	died_in_vehicle = 0;
	if ( isDefined( self.diedonvehicle ) )
	{
		died_in_vehicle = self.diedonvehicle;
	}
	hit_by_train = 0;
	if ( isDefined( attacker ) && isDefined( attacker.targetname ) && attacker.targetname == "train" )
	{
		hit_by_train = 1;
	}
	pixendevent();
	pixbeginevent( "PlayerKilled body and gibbing" );
	if ( !died_in_vehicle && !hit_by_train )
	{
		vattackerorigin = undefined;
		if ( isDefined( attacker ) )
		{
			vattackerorigin = attacker.origin;
		}
		ragdoll_now = 0;
		if ( is_true( self.usingvehicle ) && isDefined( self.vehicleposition ) && self.vehicleposition == 1 )
		{
			ragdoll_now = 1;
		}
		body = self cloneplayer( deathanimduration );
		if ( isDefined( body ) )
		{
			self createdeadbody( idamage, smeansofdeath, sweapon, shitloc, vdir, vattackerorigin, deathanimduration, einflictor, ragdoll_now, body );
		}
	}
	pixendevent();
	thread spawnqueuedclient( self.team, attacker );
    self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;
	self thread [[ level.onplayerkilled ]]( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration );
	for ( icb = 0; icb < level.onplayerkilledextraunthreadedcbs.size; icb++ )
	{
		self [[ level.onplayerkilledextraunthreadedcbs[ icb ] ]]( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration );
	}
	self.wantsafespawn = 0;
	perks = [];
	//killstreaks = maps/mp/gametypes_zm/_globallogic::getkillstreaks( attacker );
	if ( !isDefined( self.killstreak_waitamount ) )
	{
		self thread [[ level.spawnplayerprediction ]]();
	}
	profilelog_endtiming( 7, "gs=" + game[ "state" ] + " zom=" + sessionmodeiszombiesgame() );
	if ( wasteamkill == 0 && assistedsuicide == 0 && hit_by_train == 0 && smeansofdeath != "MOD_SUICIDE" && isDefined( attacker ) && attacker.classname != "trigger_hurt" && attacker.classname != "worldspawn" && self != attacker && !isDefined( attacker.disablefinalkillcam ) )
	{
		level thread recordkillcamsettings( lpattacknum, self getentitynumber(), sweapon, self.deathtime, deathtimeoffset, psoffsettime, killcamentityindex, killcamentitystarttime, perks, attacker );
		//level thread recordkillcamsettings( lpattacknum, self getentitynumber(), sweapon, self.deathtime, deathtimeoffset, psoffsettime, killcamentityindex, killcamentitystarttime, perks, killstreaks, attacker );
	}
	wait 0.25;
	weaponclass = getweaponclasszm( sweapon );
	self.cancelkillcam = 0;
	self thread cancelkillcamonuse();
	defaultplayerdeathwatchtime = 1.75;
	if ( isDefined( level.overrideplayerdeathwatchtimer ) )
	{
		defaultplayerdeathwatchtime = [[ level.overrideplayerdeathwatchtimer ]]( defaultplayerdeathwatchtime );
	}
	maps/mp/gametypes_zm/_globallogic_utils::waitfortimeornotifies( defaultplayerdeathwatchtime );
	self notify( "death_delay_finished" );
	if ( hit_by_train )
	{
		if ( killcamentitystarttime > ( self.deathtime - 2500 ) )
		{
			dokillcam = 0;
		}
	}
	if ( game[ "state" ] != "playing" )
	{
		return;
	}
	self.respawntimerstarttime = getTime();
	if ( !self.cancelkillcam /*&& dokillcam*/ && level.killcam )
	{
		if ( !level.numLives && !self.pers[ "lives" ] )
		{
			livesleft = 0;
		}
		else
		{
			livesleft = 1;
		}
		timeuntilspawn = maps/mp/gametypes_zm/_globallogic_spawn::timeuntilspawn( 1 );
		if ( !level.playerqueuedrespawn && livesleft && timeuntilspawn <= 0 )
		{
			willrespawnimmediately = 1;
		}
		else
		{
			willrespawnimmediately = 0;
		}
		self killcam( lpattacknum, self getentitynumber(), killcamentity, killcamentityindex, killcamentitystarttime, sweapon, self.deathtime, deathtimeoffset, psoffsettime, willrespawnimmediately, maps/mp/gametypes_zm/_globallogic_utils::timeuntilroundend(), perks, attacker );
	}
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
	self thread [[ level.spawnclient ]]( timepassed );
	self.respawntimerstarttime = undefined;
}

playerkilled_updatemeansofdeath( attacker, einflictor, sweapon, smeansofdeath, shitloc ) //checked matches cerberus output
{
	if ( maps/mp/gametypes_zm/_globallogic_utils::isheadshot( sweapon, shitloc, smeansofdeath, einflictor ) && isplayer( attacker ) )
	{
		return "MOD_HEAD_SHOT";
	}
	switch( sweapon )
	{
		case "crossbow_mp":
		case "knife_ballistic_mp":
			if ( smeansofdeath != "MOD_HEAD_SHOT" && smeansofdeath != "MOD_MELEE" )
			{
				smeansofdeath = "MOD_PISTOL_BULLET";
			}
			break;
		case "dog_bite_mp":
			smeansofdeath = "MOD_PISTOL_BULLET";
			break;
		case "destructible_car_mp":
			smeansofdeath = "MOD_EXPLOSIVE";
			break;
		case "explodable_barrel_mp":
			smeansofdeath = "MOD_EXPLOSIVE";
			break;
	}
	return smeansofdeath;
}

playerkilled_obituary( attacker, einflictor, sweapon, smeansofdeath )
{
	if ( isplayer( attacker ) || self isenemyplayer( attacker ) == 0 )
	{
		level notify( "reset_obituary_count" );
		level.lastobituaryplayercount = 0;
		level.lastobituaryplayer = undefined;
	}
	else
	{
		if ( isDefined( level.lastobituaryplayer ) && level.lastobituaryplayer == attacker )
		{
			level.lastobituaryplayercount++;
		}
		else
		{
			level notify( "reset_obituary_count" );
			level.lastobituaryplayer = attacker;
			level.lastobituaryplayercount = 1;
		}
		if ( level.lastobituaryplayercount >= 4 )
		{
			level notify( "reset_obituary_count" );
			level.lastobituaryplayercount = 0;
			level.lastobituaryplayer = undefined;
		}
	}
	if ( level.teambased && isDefined( attacker.pers ) && self.team == attacker.team && smeansofdeath == "MOD_GRENADE" && level.friendlyfire == 0 )
	{
		obituary( self, self, sweapon, smeansofdeath );
	}
	else
	{
		obituary( self, attacker, sweapon, smeansofdeath );
	}
}

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
		logline1 = "Player already waiting to spawn" + "\n";
		logprint( logline1 );
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

save_player_loadout()
{
	level endon( "game_ended" );
	level endon( "end_game" );
	self endon( "disconnect" );
	while ( true )
	{
		while ( self.sessionstate == "spectator" || self.sessionstate == "dead" )
		{
			wait 0.5;
		}
		self.grief_savedweapon_weapons = self getweaponslist();
		self.grief_savedweapon_weaponsammo_stock = [];
		self.grief_savedweapon_weaponsammo_clip = [];
		self.grief_savedweapon_currentweapon = self getcurrentweapon();
		self.grief_savedweapon_grenades = self get_player_lethal_grenade();
		if ( isDefined( self.grief_savedweapon_grenades ) )
		{
			self.grief_savedweapon_grenades_clip = self getweaponammoclip( self.grief_savedweapon_grenades );
		}
		self.grief_savedweapon_tactical = self get_player_tactical_grenade();
		if ( isDefined( self.grief_savedweapon_tactical ) )
		{
			self.grief_savedweapon_tactical_clip = self getweaponammoclip( self.grief_savedweapon_tactical );
		}
		for ( i = 0; i < self.grief_savedweapon_weapons.size; i++ )
		{
			self.grief_savedweapon_weaponsammo_clip[ i ] = self getweaponammoclip( self.grief_savedweapon_weapons[ i ] );
			self.grief_savedweapon_weaponsammo_stock[ i ] = self getweaponammostock( self.grief_savedweapon_weapons[ i ] );
		}
		if ( isDefined( self.hasriotshield ) && self.hasriotshield )
		{
			self.grief_hasriotshield = 1;
		}
		if ( self hasweapon( "claymore_zm" ) )
		{
			self.grief_savedweapon_claymore = 1;
			self.grief_savedweapon_claymore_clip = self getweaponammoclip( "claymore_zm" );
		}
		if ( isDefined( self.current_equipment ) )
		{
			self.grief_savedweapon_equipment = self.current_equipment;
		}
		wait 1;
	}
}

restore_player_loadout()
{
	self takeallweapons();
	if ( !isDefined( self.grief_savedweapon_weapons ) )
	{
		return 0;
	}
	primary_weapons_returned = 0;
	i = 0;
	while ( i < self.grief_savedweapon_weapons.size )
	{
		if ( isdefined( self.grief_savedweapon_grenades ) && self.grief_savedweapon_weapons[ i ] == self.grief_savedweapon_grenades || ( isdefined( self.grief_savedweapon_tactical ) && self.grief_savedweapon_weapons[ i ] == self.grief_savedweapon_tactical ) )
		{
			i++;
			continue;
		}
		if ( isweaponprimary( self.grief_savedweapon_weapons[ i ] ) )
		{
			if ( primary_weapons_returned >= 2 )
			{
				i++;
				continue;
			}
			primary_weapons_returned++;
		}
		if ( "item_meat_zm" == self.grief_savedweapon_weapons[ i ] )
		{
			i++;
			continue;
		}
		self giveweapon( self.grief_savedweapon_weapons[ i ], 0, self maps/mp/zombies/_zm_weapons::get_pack_a_punch_weapon_options( self.grief_savedweapon_weapons[ i ] ) );
		if ( isdefined( self.grief_savedweapon_weaponsammo_clip[ index ] ) )
		{
			self setweaponammoclip( self.grief_savedweapon_weapons[ i ], self.grief_savedweapon_weaponsammo_clip[ index ] );
		}
		if ( isdefined( self.grief_savedweapon_weaponsammo_stock[ index ] ) )
		{
			self setweaponammostock( self.grief_savedweapon_weapons[ i ], self.grief_savedweapon_weaponsammo_stock[ index ] );
		}
		i++;
	}
	if ( isDefined( self.grief_savedweapon_grenades ) )
	{
		self giveweapon( self.grief_savedweapon_grenades );
		if ( isDefined( self.grief_savedweapon_grenades_clip ) )
		{
			self setweaponammoclip( self.grief_savedweapon_grenades, self.grief_savedweapon_grenades_clip );
		}
	}
	if ( isDefined( self.grief_savedweapon_tactical ) )
	{
		self giveweapon( self.grief_savedweapon_tactical );
		if ( isDefined( self.grief_savedweapon_tactical_clip ) )
		{
			self setweaponammoclip( self.grief_savedweapon_tactical, self.grief_savedweapon_tactical_clip );
		}
	}
	if ( isDefined( self.current_equipment ) )
	{
		self maps/mp/zombies/_zm_equipment::equipment_take( self.current_equipment );
	}
	if ( isDefined( self.grief_savedweapon_equipment ) )
	{
		self.do_not_display_equipment_pickup_hint = 1;
		self maps/mp/zombies/_zm_equipment::equipment_give( self.grief_savedweapon_equipment );
		self.do_not_display_equipment_pickup_hint = undefined;
	}
	if ( isDefined( self.grief_hasriotshield ) && self.grief_hasriotshield )
	{
		if ( isDefined( self.player_shield_reset_health ) )
		{
			self [[ self.player_shield_reset_health ]]();
		}
	}
	if ( isDefined( self.grief_savedweapon_claymore ) && self.grief_savedweapon_claymore )
	{
		self giveweapon( "claymore_zm" );
		self set_player_placeable_mine( "claymore_zm" );
		self setactionslot( 4, "weapon", "claymore_zm" );
		self setweaponammoclip( "claymore_zm", self.grief_savedweapon_claymore_clip );
	}
	primaries = self getweaponslistprimaries();
	foreach ( weapon in primaries )
	{
		if ( isDefined( self.grief_savedweapon_currentweapon ) && self.grief_savedweapon_currentweapon == weapon )
		{
			self switchtoweapon( weapon );
			return 1;
		}
	}
	if ( primaries.size > 0 )
	{
		self switchtoweapon( primaries[ 0 ] );
		return 1;
	}
	return 0;
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
	if ( !self.hasspawned )
	{
		self.underscorechance = 70;
		self thread maps/mp/gametypes_zm/_globallogic_audio::sndstartmusicsystem();
	}
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
		team = self.pers[ "team" ];
		if ( isDefined( self.pers[ "music" ].spawn ) && self.pers[ "music" ].spawn == 0 )
		{
			if ( level.wagermatch )
			{
				music = "SPAWN_WAGER";
			}
			else
			{
				music = game[ "music" ][ "spawn_" + team ];
			}
			self thread maps/mp/gametypes_zm/_globallogic_audio::set_music_on_player( music, 0, 0 );
			self.pers[ "music" ].spawn = 1;
		}
		if ( level.splitscreen )
		{
			if ( isDefined( level.playedstartingmusic ) )
			{
				music = undefined;
			}
			else
			{
				level.playedstartingmusic = 1;
			}
		}
		if ( !isDefined( level.disableprematchmessages ) || level.disableprematchmessages == 0 )
		{
			thread maps/mp/gametypes_zm/_hud_message::showinitialfactionpopup( team );
			hintmessage = getobjectivehinttext( self.pers[ "team" ] );
			if ( isDefined( hintmessage ) )
			{
				self thread maps/mp/gametypes_zm/_hud_message::hintmessage( hintmessage );
			}
			if ( isDefined( game[ "dialog" ][ "gametype" ] ) && !level.splitscreen || self == level.players[ 0 ] )
			{
				if ( !isDefined( level.infinalfight ) || !level.infinalfight )
				{
					if ( level.hardcoremode )
					{
						self maps/mp/gametypes_zm/_globallogic_audio::leaderdialogonplayer( "gametype_hardcore" );
					}
					else
					{
						self maps/mp/gametypes_zm/_globallogic_audio::leaderdialogonplayer( "gametype" );
					}
				}
			}
			if ( team == game[ "attackers" ] )
			{
				self maps/mp/gametypes_zm/_globallogic_audio::leaderdialogonplayer( "offense_obj", "introboost" );
			}
			else
			{
				self maps/mp/gametypes_zm/_globallogic_audio::leaderdialogonplayer( "defense_obj", "introboost" );
			}
		}
	}
	else
	{
		self freeze_player_controls( 0 );
		self enableweapons();
		if ( !hadspawned && game[ "state" ] == "playing" )
		{
			pixbeginevent( "sound" );
			team = self.team;
			if ( isDefined( self.pers[ "music" ].spawn ) && self.pers[ "music" ].spawn == 0 )
			{
				self thread maps/mp/gametypes_zm/_globallogic_audio::set_music_on_player( "SPAWN_SHORT", 0, 0 );
				self.pers[ "music" ].spawn = 1;
			}
			if ( level.splitscreen )
			{
				if ( isDefined( level.playedstartingmusic ) )
				{
					music = undefined;
				}
				else
				{
					level.playedstartingmusic = 1;
				}
			}
			if ( !isDefined( level.disableprematchmessages ) || level.disableprematchmessages == 0 )
			{
				thread maps/mp/gametypes_zm/_hud_message::showinitialfactionpopup( team );
				hintmessage = getobjectivehinttext( self.pers[ "team" ] );
				if ( isDefined( hintmessage ) )
				{
					self thread maps/mp/gametypes_zm/_hud_message::hintmessage( hintmessage );
				}
				if ( isDefined( game[ "dialog" ][ "gametype" ] ) || !level.splitscreen && self == level.players[ 0 ] )
				{
					if ( !isDefined( level.infinalfight ) || !level.infinalfight )
					{
						if ( level.hardcoremode )
						{
							self maps/mp/gametypes_zm/_globallogic_audio::leaderdialogonplayer( "gametype_hardcore" );
						}
						else
						{
							self maps/mp/gametypes_zm/_globallogic_audio::leaderdialogonplayer( "gametype" );
						}
					}
				}
				if ( team == game[ "attackers" ] )
				{
					self maps/mp/gametypes_zm/_globallogic_audio::leaderdialogonplayer( "offense_obj", "introboost" );
				}
				else
				{
					self maps/mp/gametypes_zm/_globallogic_audio::leaderdialogonplayer( "defense_obj", "introboost" );
				}
			}
			pixendevent();
		}
	}
	if ( getDvar( "scr_showperksonspawn" ) == "" )
	{
		setdvar( "scr_showperksonspawn", "0" );
	}
	if ( level.hardcoremode )
	{
		setdvar( "scr_showperksonspawn", "0" );
	}
	if ( !level.splitscreen && getDvarInt( "scr_showperksonspawn" ) == 1 && game[ "state" ] != "postgame" )
	{
		pixbeginevent( "showperksonspawn" );
		if ( level.perksenabled == 1 )
		{
			self maps/mp/gametypes_zm/_hud_util::showperks();
		}
		self thread maps/mp/gametypes_zm/_globallogic_ui::hideloadoutaftertime( 3 );
		self thread maps/mp/gametypes_zm/_globallogic_ui::hideloadoutondeath();
		pixendevent();
	}
	if ( isDefined( self.pers[ "momentum" ] ) )
	{
		self.momentum = self.pers[ "momentum" ];
	}
	pixendevent();
	waittillframeend;
	logline1 = self.name + " spawned " + "\n";
	logprint( logline1 ); 
	self notify( "spawned_player" );
	self logstring( "S " + self.origin[ 0 ] + " " + self.origin[ 1 ] + " " + self.origin[ 2 ] );
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
		logline1 = "check_for_end_respawn() " + who_ended + " " + self.name + "\n";
		logprint( logline1 );
	}
}