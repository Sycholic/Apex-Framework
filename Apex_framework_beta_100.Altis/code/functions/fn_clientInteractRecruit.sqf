/*
File: fn_clientInteractRecruit.sqf
Author:

	Quiksilver
	
Last Modified:

	19/10/2015 ArmA 3 1.52
	
Description:

	-
_____________________________________________________________*/

private ['_t','_exit'];
_exit = FALSE;
_t = cursorTarget;
if (!isNull (objectParent _t)) exitWith {};
if (isPlayer _t) exitWith {};
if (!alive _t) exitWith {};
private _text = '';
if (['heli',(typeOf _t),FALSE] call (missionNamespace getVariable 'QS_fnc_inString')) then {
	if (!(['heli',(typeOf player),FALSE] call (missionNamespace getVariable 'QS_fnc_inString'))) then {
		_exit = TRUE;
		_text = parseText format ['Only Pilots can recruit %1<br/> ( %2 )',(name _t),(getText (configFile >> 'CfgVehicles' >> (typeOf _t) >> 'displayName'))];
		(missionNamespace getVariable 'QS_managed_hints') pushBack [5,TRUE,5,-1,_text,[],-1];
	};
} else {
	if ((['heli',(typeOf player),FALSE] call (missionNamespace getVariable 'QS_fnc_inString')) || {(['pilot',(typeOf player),FALSE] call (missionNamespace getVariable 'QS_fnc_inString'))}) then {
		_exit = TRUE;
		_text = parseText format ['Pilots and Aircrew <t underline="true">cannot</t> recruit %1<br/> ( %2 )',(name _t),(getText (configFile >> 'CfgVehicles' >> (typeOf _t) >> 'displayName'))];
		(missionNamespace getVariable 'QS_managed_hints') pushBack [5,TRUE,5,-1,_text,[],-1];
	};	
};
if (_exit) exitWith {};
player playActionNow 'gestureHi';
[_t] joinSilent (group player);
_text = format ['Recruited %1 ( %2 )',(name _t),(getText (configFile >> 'CfgVehicles' >> (typeOf _t) >> 'displayName'))];
50 cutText [_text,'PLAIN DOWN',0.5];
_t enableStamina FALSE;
_t setAnimSpeedCoef 1.1;
{
	_t enableAI _x;
} count [
	'FSM',
	'TEAMSWITCH',
	'AIMINGERROR',
	'SUPPRESSION',
	'TARGET',
	'AUTOTARGET',
	'MOVE',
	'CHECKVISIBLE'
];
_t disableAI 'AUTOCOMBAT';
_t disableAI 'COVER';
{
	if (['heli',(typeOf _x),FALSE] call (missionNamespace getVariable 'QS_fnc_inString')) then {
		_x setSkill 0.1;
		_x setSkill ['aimingAccuracy',0.1];
	} else {
		_x setSkill 0.5;
		_x setSkill ['aimingAccuracy',0.3];
	};
} forEach (units (group player));
(group _t) setBehaviour 'AWARE';
(group player) setBehaviour 'AWARE';
(group _t) setSpeedMode 'FULL';
for '_x' from 0 to 1 step 1 do {
	_t setVariable ['QS_unit_isRecruited',TRUE,TRUE];
};
_t addEventHandler [
	'FiredMan',
	{
		if (!isNull (assignedTarget (_this select 0))) then {
			_assignedTarget = assignedTarget (_this select 0);
			if ((isPlayer _assignedTarget) || {(isPlayer (effectiveCommander _assignedTarget))}) then {
				deleteVehicle (_this select 6);
			};
		};
	}
];
if (isMultiplayer) then {
	[19,_t,player] remoteExec ['QS_fnc_remoteExec',0,FALSE];
} else {
	_t allowDamage TRUE;
};
TRUE;