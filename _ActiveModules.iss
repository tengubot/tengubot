; This file is automatically generated by the top-level EVEBot.iss

;	 To disable a module:
;		 1) Change TRUE to FALSE for the module you want
;		 2) Run EVEBot.ISS with -nocreate option

function main()
{
	EVEBotBehaviors:Set[obj_Delegator, TRUE]
	EVEBotBehaviors:Set[obj_Ratter, TRUE]
}
