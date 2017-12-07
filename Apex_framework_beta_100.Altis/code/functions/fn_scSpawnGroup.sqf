/*/
File: fn_scSpawnGroup.sqf
Author: 

	Quiksilver

Last Modified:

	13/09/2017 A3 1.76 by Quiksilver

Description:

	SC Spawn Group
	
To Do:

	Try to spawn them closer and also set max attempts/iterations, allow it to fail if no position found
____________________________________________________________________________/*/

params ['_sectorData','_count'];
private _grp = grpNull;
if (_sectorData isEqualType []) exitWith {
	_sectorData params [
		'_sectorID',
		'_isActive',
		'_nextEvaluationTime',
		'_increment',
		'_minConversionTime',
		'_interruptMultiplier',
		'_areaType',
		'_centerPos',
		'_areaOrRadiusConvert',
		'_areaOrRadiusInterrupt',
		'_sidesOwnedBy',
		'_sidesCanConvert',
		'_sidesCanInterrupt',
		'_conversionValue',
		'_conversionValuePrior',
		'_conversionAlgorithm',
		'_importance',
		'_flagData',
		'_sectorAreaObjects',
		'_locationData',
		'_objectData',
		'_markerData',
		'_taskData',
		'_initFunction',
		'_manageFunction',
		'_exitFunction',
		'_conversionRate',
		'_isBeingInterrupted'
	];
	comment 'Find position';
	private _position = [0,0,0];
	private _positionFound = FALSE;
	private _iterations = 0;
	private _aoSize = _areaOrRadiusInterrupt * 2;
	private _aoSizeIncrement = 5;
	private _checkVisibleDistance = 500;
	private _players = allPlayers;
	private _playersOnGround = (_players unitsBelowHeight 25) select {((side _x) in [WEST,CIVILIAN,SIDEFRIENDLY])};
	for '_x' from 0 to 1 step 0 do {
		_position = ['RADIUS',_centerPos,_aoSize,'LAND',[1.5,0,0.5,3,0,FALSE,objNull],TRUE,[],[],FALSE] call (missionNamespace getVariable 'QS_fnc_findRandomPos');
		if ((_position distance2D _centerPos) < 1500) then {
			if (({((_x distance2D _position) < 250)} count _players) isEqualTo 0) then {
				if ((([_position select 0,_position select 1] nearRoads 25) select {((_x isEqualType objNull) && (!((roadsConnectedTo _x) isEqualTo [])))}) isEqualTo []) then {
					if (!([_position,_centerPos,25] call (missionNamespace getVariable 'QS_fnc_waterIntersect'))) then {
						if (([(AGLToASL _position),_checkVisibleDistance,_playersOnGround,[WEST,CIVILIAN,SIDEFRIENDLY],0,0] call (missionNamespace getVariable 'QS_fnc_isPosVisible')) <= 0.1) then {
							_positionFound = TRUE;
						};
					};
				};
			};
		};
		if (_positionFound) exitWith {};
		_aoSize = _aoSize + _aoSizeIncrement;
		_iterations = _iterations + 1;
	};
	comment 'Spawn group';
	_side = EAST;
	private _infantryGroupType = [];
	
	private _heliInsert = FALSE;
	if ((random 1) > 0.666) then {
		if (missionNamespace getVariable ['QS_AI_insertHeli_enabled',FALSE]) then {
			if (({(alive _x)} count (missionNamespace getVariable ['QS_AI_insertHeli_helis',[]])) < (missionNamespace getVariable ['QS_AI_insertHeli_maxHelis',3])) then {
				if (diag_tickTime > ((missionNamespace getVariable ['QS_AI_insertHeli_lastEvent',-1]) + (missionNamespace getVariable ['QS_AI_insertHeli_cooldown',900]))) then {
					if ((missionNamespace getVariable ['QS_AI_insertHeli_spawnedAO',0]) < (missionNamespace getVariable ['QS_AI_insertHeli_maxAO',3])) then {
						if (([4,EAST,(missionNamespace getVariable 'QS_aoPos'),2000] call (missionNamespace getVariable 'QS_fnc_AIGetKnownEnemies')) < 2) then {
							if (([3,EAST,(missionNamespace getVariable 'QS_aoPos'),2000] call (missionNamespace getVariable 'QS_fnc_AIGetKnownEnemies')) < 2) then {
								missionNamespace setVariable ['QS_AI_insertHeli_spawnedAO',((missionNamespace getVariable 'QS_AI_insertHeli_spawnedAO') + 1),FALSE];
								missionNamespace setVariable ['QS_AI_insertHeli_lastEvent',diag_tickTime,FALSE];
								_heliInsert = TRUE;
								_infantryGroupType = ['OIA_InfSquad','OIA_InfAssault'] selectRandomWeighted [0.5,0.5];
								_grp = [_position,(random 360),EAST,_infantryGroupType,FALSE] call (missionNamespace getVariable 'QS_fnc_spawnGroup');
								[
									_centerPos,
									EAST,
									(['O_Heli_Transport_04_covered_F','O_Heli_Transport_04_covered_black_F'] select (worldName isEqualTo 'Tanoa')),
									0.75,
									[],
									((random 1) > 0.9),
									(['O_Heli_Attack_02_dynamicLoadout_F','O_Heli_Attack_02_dynamicLoadout_black_F'] select (worldName isEqualTo 'Tanoa')),
									(units _grp),
									FALSE
								] spawn (missionNamespace getVariable 'QS_fnc_AIXHeliInsert');
							};
						};
					};
				};
			};
		};
	};
	if (!(_heliInsert)) then {
		if (missionNamespace getVariable ['QS_virtualSectors_sub_3_active',TRUE]) then {
			_infantryGroupType = ['OIA_InfSquad','OIA_InfTeam','OIA_InfTeam_LAT','OIA_InfAssault','OIA_InfTeam_AA','OIA_InfTeam_AT','OIA_InfSentry',(['OG_InfTeam','O_T_ViperPatrol'] select ((count _players) > 30)),'OI_reconSentry'] selectRandomWeighted [0.2,0.4,0.2,0.2,0.2,0.2,0.2,0.2,0.2];
		} else {
			_infantryGroupType = ['OIA_InfSquad','OIA_InfTeam','OIA_InfTeam_LAT','OIA_InfAssault','OIA_InfTeam_AA','OIA_InfTeam_AT','OIA_InfSentry','OI_reconSentry','OG_InfTeam','OG_InfTeam_AT'] selectRandomWeighted [0.2,0.4,0.1,0.2,0.1,0.1,0.2,0.1,0.2,0.2];
		};
		_direction = _position getDir _centerPos;
		_grp = [_position,_direction,_side,_infantryGroupType,FALSE] call (missionNamespace getVariable 'QS_fnc_spawnGroup');
	};	
	{
		if (!(_heliInsert)) then {
			_x setVehiclePosition [(getPosWorld _x),[],0,'CAN_COLLIDE'];
		};
		_x disableAI 'AUTOCOMBAT';
		_x disableAI 'COVER';
		_x call (missionNamespace getVariable 'QS_fnc_unitSetup');
		_x setVariable ['QS_AI_UNIT_enabled',TRUE,FALSE];
	} forEach (units _grp);
	[(units _grp),([1,1] select (_infantryGroupType in ['OI_reconPatrol','O_T_ViperPatrol','OI_reconSentry']))] call (missionNamespace getVariable 'QS_fnc_serverSetAISkill');
	comment 'configure group';
	_grp setVariable ['QS_AI_GRP',TRUE,FALSE];
	_grp setVariable ['QS_AI_GRP_CONFIG',['SC','INF_GENERAL',(count (units _grp))],FALSE];
	_grp setVariable ['QS_AI_GRP_DATA',[_centerPos,_areaOrRadiusConvert,_areaOrRadiusInterrupt,_locationData],FALSE];
	_grp setVariable ['QS_AI_GRP_TASK',['DEFEND',_centerPos,diag_tickTime,-1],FALSE];
	comment 'Initial movement so they move from spawn';
	if (!(_heliInsert)) then {
		_grp move [((_centerPos select 0) + (50 - (random 100))),((_centerPos select 1) + (50 - (random 100))),(_centerPos select 2)];
	};
	comment 'return';
	_grp;
};
if (_sectorData isEqualType 0) exitWith {
	if (_sectorData isEqualTo -1) then {
		comment 'AI which move between sectors';
		comment 'Get owned sectors';
		private _getOwnedSectors = [];
		private _centerPos = [0,0,0];
		private _radius = -1;
		private _sector = [];
		{
			if (EAST in (_x select 10)) then {
				_getOwnedSectors pushBack _x;
			};
		} forEach (missionNamespace getVariable 'QS_virtualSectors_data');
		if (_getOwnedSectors isEqualTo []) then {
			_centerPos = missionNamespace getVariable ['QS_virtualSectors_centroid',(markerPos 'QS_marker_aoMarker')];
			_radius = ((markerSize 'QS_marker_aoCircle') select 0) * 1.25;
		} else {
			_sector = selectRandom _getOwnedSectors;
			_centerPos = _sector select 7;
			_radius = (_sector select 9) * 2;
		};
		private _position = [0,0,0];
		private _positionFound = FALSE;
		private _iterations = 0;
		private _radiusIncrement = 5;
		private _checkVisibleDistance = 500;
		private _players = allPlayers;
		private _playersOnGround = (_players unitsBelowHeight 25) select {((side _x) in [WEST,CIVILIAN,SIDEFRIENDLY])};
		for '_x' from 0 to 1 step 0 do {
			_position = ['RADIUS',_centerPos,_radius,'LAND',[1.5,0,0.5,3,0,FALSE,objNull],TRUE,[],[],FALSE] call (missionNamespace getVariable 'QS_fnc_findRandomPos');
			if ((_position distance2D _centerPos) < 600) then {
				if (({((_x distance2D _position) < 250)} count _players) isEqualTo 0) then {
					if (!([_position,_centerPos,25] call (missionNamespace getVariable 'QS_fnc_waterIntersect'))) then {
						if (([(AGLToASL _position),_checkVisibleDistance,_playersOnGround,[WEST,CIVILIAN,SIDEFRIENDLY],0,0] call (missionNamespace getVariable 'QS_fnc_isPosVisible')) <= 0.25) then {
							_positionFound = TRUE;
						};
					};
				};
			};
			if (_positionFound) exitWith {};
			_radius = _radius + _radiusIncrement;
			_iterations = _iterations + 1;
		};
		comment 'Spawn group';
		_side = EAST;
		private _infantryGroupType = [];
		if (missionNamespace getVariable ['QS_virtualSectors_sub_3_active',TRUE]) then {
			_infantryGroupType = ['OIA_InfSquad','OIA_InfTeam','OIA_InfTeam_LAT','OIA_InfAssault','OIA_InfTeam_AA','OIA_InfTeam_AT','OIA_InfSentry','OI_reconSentry',(['OG_InfTeam','O_T_ViperPatrol'] select ((count _players) > 30))] selectRandomWeighted [0.2,0.4,0.1,0.2,0.1,0.1,0.2,0.1,0.2,0.2];
		} else {
			_infantryGroupType = ['OIA_InfSquad','OIA_InfTeam','OIA_InfTeam_LAT','OIA_InfAssault','OIA_InfTeam_AA','OIA_InfTeam_AT','OIA_InfSentry','OI_reconSentry','OG_InfTeam','OG_InfTeam_AT'] selectRandomWeighted [0.2,0.4,0.1,0.2,0.1,0.1,0.1,0.1,0.2,0.2];
		};
		_direction = _position getDir _centerPos;
		_grp = [_position,_direction,_side,_infantryGroupType,FALSE] call (missionNamespace getVariable 'QS_fnc_spawnGroup');
		{
			_x setAnimSpeedCoef 1.1;
			_x disableAI 'AUTOCOMBAT';
			_x disableAI 'COVER';
			_x disableAI 'SUPPRESSION';
			_x forceSpeed 24;
			_x call (missionNamespace getVariable 'QS_fnc_unitSetup');
			_x setVehiclePosition [(getPosWorld _x),[],0,'CAN_COLLIDE'];
			_x setVariable ['QS_AI_UNIT_enabled',TRUE,FALSE];
		} forEach (units _grp);
		[(units _grp),([1,1] select (_infantryGroupType in ['OI_reconPatrol','O_T_ViperPatrol','OI_reconSentry']))] call (missionNamespace getVariable 'QS_fnc_serverSetAISkill');
		comment 'configure group';
		_grp setVariable ['QS_AI_GRP',TRUE,FALSE];
		_grp setVariable ['QS_AI_GRP_CONFIG',['SC','INF_GENERAL',(count (units _grp))],FALSE];
		_grp setVariable ['QS_AI_GRP_DATA',[],FALSE];
		_grp setVariable ['QS_AI_GRP_TASK',['ATTACK',[0,0,0],diag_tickTime,-1],FALSE];
		comment 'Initial movement so they move from spawn';
		_grp setSpeedMode 'FULL';
		_grp setBehaviour 'AWARE';
		_grp setCombatMode 'YELLOW';
		_grp setFormation 'WEDGE';
		private _movePos = [];
		{
			_movePos = [_x,(position (leader _grp)),(side _grp)] call (missionNamespace getVariable 'QS_fnc_scGetNearestSector');
			if (!(_movePos isEqualTo [])) exitWith {};
		} forEach [2,3];
		if (_movePos isEqualTo []) then {
			_movePos = [1,(position (leader _grp)),WEST] call (missionNamespace getVariable 'QS_fnc_scGetNearestSector');
		};
		if (!(_movePos isEqualTo [])) then {
			_grp move [((_movePos select 0) + (25 - (random 50))),((_movePos select 1) + (25 - (random 50))),(_movePos select 2)];
		} else {
			_grp move [((_centerPos select 0) + (50 - (random 100))),((_centerPos select 1) + (50 - (random 100))),(_centerPos select 2)];
		};
	};
	if (_sectorData isEqualTo -2) then {
		diag_log 'Spawning more radial patrols';
		comment 'Infantry radial patrols';
		_centerPos = missionNamespace getVariable 'QS_AOpos';
		_centerRadius = missionNamespace getVariable 'QS_aoSize';
		_worldName = worldName;
		_worldSize = worldSize;
		_side = EAST;
		private _iterations = 0;
		private _aoSizeIncrement = 5;
		private _positionFound = FALSE;
		private _checkVisibleDistance = 500;
		private _players = allPlayers;
		private _playersOnGround = (_players unitsBelowHeight 25) select {((side _x) in [WEST,CIVILIAN,SIDEFRIENDLY])};
		private _randomPos = [0,0,0];
		for '_x' from 0 to 1 step 0 do {
			_randomPos = ['RADIUS',_centerPos,_centerRadius,'LAND',[1.5,0,0.5,3,0,FALSE,objNull],TRUE,[],[],TRUE] call (missionNamespace getVariable 'QS_fnc_findRandomPos');
			if ((_randomPos distance2D _centerPos) < 1500) then {
				if (({((_x distance2D _randomPos) < 250)} count _players) isEqualTo 0) then {
					if ((([_randomPos select 0,_randomPos select 1] nearRoads 25) select {((_x isEqualType objNull) && (!((roadsConnectedTo _x) isEqualTo [])))}) isEqualTo []) then {
						if (!([_randomPos,_centerPos,25] call (missionNamespace getVariable 'QS_fnc_waterIntersect'))) then {
							if (([(AGLToASL _randomPos),_checkVisibleDistance,_playersOnGround,[WEST,CIVILIAN,SIDEFRIENDLY],0,0] call (missionNamespace getVariable 'QS_fnc_isPosVisible')) <= 0.1) then {
								_positionFound = TRUE;
							};
						};
					};
				};
			};
			if (_positionFound) exitWith {};
			_centerRadius = _centerRadius + _aoSizeIncrement;
			_iterations = _iterations + 1;
		};
		
		private _infantryGroupType = [];
		if (missionNamespace getVariable ['QS_virtualSectors_sub_3_active',TRUE]) then {
			_infantryGroupType = ['OIA_InfSquad','OIA_InfTeam','OIA_InfTeam_LAT','OIA_InfAssault','OIA_InfTeam_AA','OIA_InfTeam_AT','OIA_InfSentry',(['OG_InfTeam','O_T_ViperPatrol'] select ((count _players) > 30)),'OI_reconSentry'] selectRandomWeighted [0.2,0.4,0.2,0.2,0.2,0.2,0.1,0.2,0.15];
		} else {
			_infantryGroupType = ['OIA_InfSquad','OIA_InfTeam','OIA_InfTeam_LAT','OIA_InfAssault','OIA_InfTeam_AA','OIA_InfTeam_AT','OIA_InfSentry','OI_reconSentry','OG_InfTeam','OG_InfTeam_AT'] selectRandomWeighted [0.2,0.4,0.1,0.2,0.1,0.1,0.1,0.1,0.2,0.2];
		};
		_grp = [_randomPos,(random 360),_side,_infantryGroupType,FALSE] call (missionNamespace getVariable 'QS_fnc_spawnGroup');
		[(units _grp),([1,1] select (_infantryGroupType in ['OI_reconPatrol','O_T_ViperPatrol','OI_reconSentry']))] call (missionNamespace getVariable 'QS_fnc_serverSetAISkill');
		{
			[_x] call (missionNamespace getVariable 'QS_fnc_setCollectible');
			_x setVehiclePosition [(getPosWorld _x),[],0,'CAN_COLLIDE'];
			_x setVariable ['QS_AI_UNIT_enabled',TRUE,FALSE];
			_x disableAI 'AUTOCOMBAT';
			_x disableAI 'COVER';
			_x call (missionNamespace getVariable 'QS_fnc_unitSetup');
		} forEach (units _grp);
		comment 'Radial positions';
		private _radialIncrement = 45;
		private _radialStart = round (random 360);
		_radialOffset = _centerRadius * (0.75 + (random 0.4));
		private _radialPatrolPositions = [];
		private _patrolPosition = _centerPos getPos [_radialOffset,_radialStart];
		if (!surfaceIsWater _patrolPosition) then {
			_radialPatrolPositions pushBack _patrolPosition;
		};
		for '_x' from 0 to 6 step 1 do {
			_radialStart = _radialStart + _radialIncrement;
			_patrolPosition = _centerPos getPos [_radialOffset,_radialStart];
			if (!surfaceIsWater _patrolPosition) then {
				_radialPatrolPositions pushBack _patrolPosition;
			};
		};
		if (!(_radialPatrolPositions isEqualTo [])) then {
			_radialPatrolPositions = _radialPatrolPositions call (missionNamespace getVariable 'QS_fnc_arrayShuffle');
			comment 'Initial movement';
			_grp move (_radialPatrolPositions select 0);
			_grp setFormDir (_randomPos getDir (_radialPatrolPositions select 0));
		};
		_grp setSpeedMode 'NORMAL';
		_grp setBehaviour 'AWARE';
		_grp setCombatMode 'YELLOW';
		_grp setFormation 'WEDGE';
		_grp setVariable ['QS_AI_GRP',TRUE,FALSE];
		_grp setVariable ['QS_AI_GRP_CONFIG',['SC','INF_PATROL_RADIAL',(count (units _grp))],FALSE];
		_grp setVariable ['QS_AI_GRP_DATA',[],FALSE];
		_grp setVariable ['QS_AI_GRP_TASK',['PATROL',_radialPatrolPositions,diag_tickTime,-1],FALSE];
		_grp setVariable ['QS_AI_GRP_PATROLINDEX',0,FALSE];
	};
	if (_sectorData isEqualTo -3) then {
		comment 'Spawn infantry assault squads';
		diag_log 'Spawning assault squad';
		_centerPos = missionNamespace getVariable 'QS_AOpos';
		_centerRadius = missionNamespace getVariable 'QS_aoSize';
		_worldName = worldName;
		_worldSize = worldSize;
		_side = EAST;
		private _grp = grpNull;
		comment 'GET TARGETED SECTOR';
		_attackPosition = _this select 2;
		comment 'CALCULATE FORCE REQUIREMENTS';
		private _quantity = 24; comment 'Placeholder, also check player count';
		
		
		private _position = [0,0,0];
		private _radius = 350;
		private _positionFound = FALSE;
		private _iterations = 0;
		private _maxAttempts = 300;
		private _radiusIncrement = 5;
		private _checkVisibleDistance = 300;
		private _players = allPlayers;
		private _playersOnGround = (_players unitsBelowHeight 25) select {((side _x) in [WEST,CIVILIAN,SIDEFRIENDLY])};
		for '_x' from 0 to 1 step 0 do {
			_position = ['RADIUS',_attackPosition,_radius,'LAND',[1.5,0,0.5,3,0,FALSE,objNull],TRUE,[],[],FALSE] call (missionNamespace getVariable 'QS_fnc_findRandomPos');
			if (((_position distance2D _attackPosition) < 350) && ((_position distance2D _attackPosition) > 125)) then {
				if (({((_x distance2D _position) < 150)} count _players) isEqualTo 0) then {
					if (!([_position,_attackPosition,25] call (missionNamespace getVariable 'QS_fnc_waterIntersect'))) then {
						if (([(AGLToASL _position),_checkVisibleDistance,_playersOnGround,[WEST,CIVILIAN,SIDEFRIENDLY],0,0] call (missionNamespace getVariable 'QS_fnc_isPosVisible')) <= 0.25) then {
							_positionFound = TRUE;
						};
					};
				};
			};
			if (_positionFound) exitWith {};
			_radius = _radius + _radiusIncrement;
			_iterations = _iterations + 1;
		};		
		comment 'Create force';
		private _infantryGroupType = [];
		if (missionNamespace getVariable ['QS_virtualSectors_sub_3_active',TRUE]) then {
			_infantryGroupType = ['OIA_InfSquad','OIA_InfTeam','OIA_InfTeam_LAT','OIA_InfAssault','OIA_InfTeam_AA','OIA_InfTeam_AT','OIA_InfSentry','OI_reconSentry',(['OG_InfTeam','O_T_ViperPatrol'] select ((count _players) > 30))] selectRandomWeighted [0.2,0.4,0.1,0.2,0.1,0.1,0.2,0.1,0.2,0.2];
		} else {
			_infantryGroupType = ['OIA_InfSquad','OIA_InfTeam','OIA_InfTeam_LAT','OIA_InfAssault','OIA_InfTeam_AA','OIA_InfTeam_AT','OIA_InfSentry','OI_reconSentry','OG_InfTeam','OG_InfTeam_AT'] selectRandomWeighted [0.2,0.4,0.1,0.2,0.1,0.1,0.1,0.1,0.2,0.2];
		};
		_direction = _position getDir _attackPosition;
		_assaultGrp = createGroup [EAST,TRUE];
		comment 'Spawn units offsite';
		while {((count (units _assaultGrp)) < _quantity)} do {
			_grp = [[(_worldSize + (random 1000)),(_worldSize + (random 1000)),(50 + (random 50))],_direction,_side,_infantryGroupType,FALSE] call (missionNamespace getVariable 'QS_fnc_spawnGroup');
			{
				_x setVariable ['QS_dynSim_ignore',TRUE,TRUE];
				_x allowDamage FALSE;
				_x enableSimulation FALSE;
				_x setAnimSpeedCoef 1.1;
				_x disableAI 'AUTOCOMBAT';
				_x disableAI 'COVER';
				_x disableAI 'SUPPRESSION';
				_x disableAI 'ANIM';
				_x forceSpeed 24;
				_x call (missionNamespace getVariable 'QS_fnc_unitSetup');
				_x setVariable ['QS_AI_UNIT_enabled',TRUE,FALSE];
				_x setUnitPos 'DOWN'; 
				_x switchMove 'amovppnemstpsraswrfldnon';
			} forEach (units _grp);
			(units _grp) joinSilent _assaultGrp;
		};
		comment 'Propagate animation to get prone';
		[(units _assaultGrp),{{_x switchMove 'amovppnemstpsraswrfldnon';} forEach _this;}] remoteExec ['spawn',(_players select {((_x distance2D _position) < 1000)}),FALSE];
		comment 'Small delay then put units where they belong';
		[_assaultGrp,_direction] spawn {
			params ['_assaultGrp','_direction'];
			uiSleep 2;
			{
				_x setUnitPos 'UP';
				_x enableAI 'ANIM';
				_x setVehiclePosition [_position,[],15,'NONE'];
				uiSleep 0.01;
				_x call (missionNamespace getVariable 'QS_fnc_unitSetup');
				_x setVehiclePosition [(getPosWorld _x),[],0,'CAN_COLLIDE'];
				_x setVariable ['QS_dynSim_ignore',FALSE,TRUE];
				_x allowDamage TRUE;
				_x enableSimulation TRUE;
			} forEach (units _assaultGrp);
			_assaultGrp setFormDir _direction;
		};
		_grp = _assaultGrp;	/*/Transpose back to grp/*/
	};
	comment 'return';
	_grp;
};