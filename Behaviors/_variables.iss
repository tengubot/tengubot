; This file is automatically generated by the top-level EVEBot.iss

#if ${EVEBotBehaviors.Element[obj_Delegator]}
	Logger:Log["Creating global obj_Delegator as Delegator", LOG_DEBUG]
	call CreateVariable Delegator obj_Delegator global
#endif

#if ${EVEBotBehaviors.Element[obj_Ratter]}
	Logger:Log["Creating global obj_Ratter as Ratter", LOG_DEBUG]
	call CreateVariable Ratter obj_Ratter global
#endif

