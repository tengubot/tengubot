/*
PC war v.5.1.7.PL
*/

objectdef obj_EVEDB_Spawns
{
 variable string SVN_REVISION = "$Rev$"
 variable int Version

 variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/EVEDB_Spawns.xml"
 variable string SET_NAME = "EVEDB_Spawns"

 method Initialize()
 {
  LavishSettings:Import[${CONFIG_FILE}]

  UI:UpdateConsole["obj_EVEDB_Spawns: Initialized", LOG_MINOR]
 }

 member:int SpawnBounty(string spawnName)
 {
  return ${LavishSettings[${This.SET_NAME}].FindSet[${spawnName}].FindSetting[bounty, NOTSET]}
 }
}

objectdef obj_Targets
{
 variable string SVN_REVISION = "$Rev$"
 variable int Version

 variable index:string PriorityTargets
 variable iterator PriorityTarget

 variable index:string SpecialTargets
 variable iterator SpecialTarget

 variable bool CheckChain
 variable bool Chaining
 variable int  TotalSpawnValue

 variable bool m_PriorityTargetPresent
 variable bool m_SpecialTargetPresent


 variable set DoNotKillList
 variable bool CheckedSpawnValues = FALSE

 variable bool MyMWDStatus = FALSE
 variable bool MyLock = FALSE
 variable bool PCWar:Set[FALSE]

 method Initialize()
 {
  m_SpecialTargetPresent:Set[FALSE]
  m_PriorityTargetPresent:Set[FALSE]

  ; TODO - load this all from XML files

  ; Priority targets will be targeted (and killed)
  ; before other targets, they often do special things
  ; which we cant use (scramble / web / damp / etc)
  ; You can specify the entire rat name, for example
  ; leave rats that dont scramble which would help
  ; later when chaining gets added

  UI:UpdateConsole["Loading target list Drones", LOG_CRITICAL]
  PriorityTargets:Insert["Strain Infester Drone"]  /* web/scram */
  PriorityTargets:Insert["Strain Render Drone"]  /* web/scram */
  PriorityTargets:Insert["Strain Splinter Drone"]  /* web/scram */
  PriorityTargets:Insert["Strain Decimator Drone"] /* web/scram */
  PriorityTargets:Insert["Strain Decimator Alvi"]  /* web/scram */
  PriorityTargets:Insert["Lockout Centry"]  /* web/scram */
  PriorityTargets:Insert["Strain Infester Alvi"]  /* web/scram */
  PriorityTargets:Insert["Strain Render Alvi"]  /* web/scram */
  PriorityTargets:Insert["Infestious Drone"]  /* web/scram */
  UI:UpdateConsole["Loading target list Angel", LOG_CRITICAL]
  PriorityTargets:Insert["Arch Angel Hijacker"]  /* web/scram */
  PriorityTargets:Insert["Arch Angel Outlaw"]  /* web/scram */
  PriorityTargets:Insert["Arch Angel Rogue"]  /* web/scram */
  PriorityTargets:Insert["Arch Angel Thug"]  /* web/scram */
  PriorityTargets:Insert["Arch Gistii Hijacker"]  /* web/scram */
  PriorityTargets:Insert["Arch Gistii Thug"]  /* web/scram */
  PriorityTargets:Insert["Arch Gistii Outlaw"]  /* web/scram */
  PriorityTargets:Insert["Arch Gistii Rogue"]  /* web/scram */
  SpecialTargets:Insert["Tobias"]    /* officers */
  SpecialTargets:Insert["Gotan"]    /* officers */
  SpecialTargets:Insert["Mizuro"]    /* officers */
  SpecialTargets:Insert["Hakim"]    /* officers */
  SpecialTargets:Insert["Domination"]   /* officers */
  UI:UpdateConsole["Loading target list Guristas", LOG_CRITICAL]
  PriorityTargets:Insert["Factory Defense Battery"]   /* web/scram */
  PriorityTargets:Insert["Dire Pithi Arrogator"] /* web/scram */
  PriorityTargets:Insert["Dire Pithi Despoiler"] /* jam */
  PriorityTargets:Insert["Dire Pithi Imputor"]  /* web/scram */
  PriorityTargets:Insert["Dire Pithi Infiltrator"] /* web/scram */
  PriorityTargets:Insert["Dire Pithi Invader"]  /* web/scram */
  PriorityTargets:Insert["Dire Pithi Saboteur"]  /* jam */
  PriorityTargets:Insert["Dire Pithum Annihilator"] /* jam */
  PriorityTargets:Insert["Dire Pithum Killer"]  /* jam */
  PriorityTargets:Insert["Dire Pithi Murderer"]  /* jam */
  PriorityTargets:Insert["Dire Pithum Nullifier"] /* jam */
  PriorityTargets:Insert["Pithi Defender"]  /* web/scram */
  PriorityTargets:Insert["Pithum Killer"]   /* jam */
  PriorityTargets:Insert["Pithum Nullifier"]  /* jam */
  PriorityTargets:Insert["Pith Eliminator"]  /* jam */
  PriorityTargets:Insert["Pith Exterminator"]  /* jam */
  SpecialTargets:Insert["Estamel"]   /* officers */
  SpecialTargets:Insert["Vepas"]    /* officers */
  SpecialTargets:Insert["Thon"]    /* officers */
  SpecialTargets:Insert["Kaikka"]    /* officers */
  SpecialTargets:Insert["Dread Guristas"]   /* officers */
  UI:UpdateConsole["Loading target list Sansha", LOG_CRITICAL]
  PriorityTargets:Insert["Sansha's Loyal"]  /* web/scram */
  SpecialTargets:Insert["Chelm"]    /* officers */
  SpecialTargets:Insert["Vizan"]    /* officers */
  SpecialTargets:Insert["Selynne"]   /* officers */
  SpecialTargets:Insert["Brokara"]   /* officers */
  SpecialTargets:Insert["True Sansha"]   /* officers */
  UI:UpdateConsole["Loading target list Serpentis", LOG_CRITICAL]
  PriorityTargets:Insert["Coreli Guardian Agent"]  /* web/scram */
  PriorityTargets:Insert["Coreli Guardian Initiate"]  /* web/scram */
  PriorityTargets:Insert["Coreli Guardian Scout"]  /* web/scram */
  PriorityTargets:Insert["Coreli Guardian Spy"]  /* web/scram */
  PriorityTargets:Insert["Guardian Agent"]  /* web/scram */
  PriorityTargets:Insert["Guardian Initiate"]  /* web/scram */
  PriorityTargets:Insert["Guardian Scout"]  /* web/scram */
  PriorityTargets:Insert["Guardian Spy"]  /* web/scram */
  PriorityTargets:Insert["Guardian Veteran"]  /* web */
  SpecialTargets:Insert["Shadow"]    /* faction */
  SpecialTargets:Insert["Brynn Jerdola"]    /* officers */
  SpecialTargets:Insert["Cormack Vaaja"]    /* officers */
  SpecialTargets:Insert["Setele Schellan"]    /* officers */
  SpecialTargets:Insert["Tuvan Orth"]    /* officers */

  ; Get the iterators
  PriorityTargets:GetIterator[PriorityTarget]
  SpecialTargets:GetIterator[SpecialTarget]

  DoNotKillList:Clear
 }

 method ResetTargets()
 {
  This.CheckChain:Set[TRUE]
  This.Chaining:Set[FALSE]
  This.CheckedSpawnValues:Set[FALSE]
  This.TotalSpawnValue:Set[0]
  This.MyLock:Set[FALSE]
  This.PCWar:Set[FALSE]
 }

 member:bool PriorityTargetPresent()
 {
  return ${m_PriorityTargetPresent}
 }

 member:bool IsPriorityTarget(string name)
 {
  ; Loop through the priority targets
  if ${PriorityTarget:First(exists)}
  do
  {
   if ${name.Find[${PriorityTarget.Value}]} > 0
   {
    return TRUE
   }
  }
  while ${PriorityTarget:Next(exists)}

  return FALSE
 }

 member:bool SpecialTargetPresent()
 {
  return ${m_SpecialTargetPresent}
 }

 member:bool IsSpecialTarget(string name)
 {
  ; Loop through the special targets
  if ${SpecialTarget:First(exists)}
  do
  {
   if ${name.Find[${SpecialTarget.Value}]} > 0
   {
    return TRUE
   }
  }
  while ${SpecialTarget:Next(exists)}

  return FALSE
 }

 member:bool TargetNPCs()
 {
  variable bool HasTargets = FALSE
  variable index:entity Targets
  variable iterator Target
  variable index:pilot MyPilotIndex
  variable iterator MyPilotIterator

  /* Me.Ship.MaxTargetRange contains the (possibly) damped value */
  EVE:QueryEntities[Targets,"CategoryID = CATEGORYID_ENTITY && Distance <= 150000"]
  Targets:GetIterator[Target]

  if !${Target:First(exists)}
  {
   if ${Ship.IsDamped}
   { /* Ship.MaxTargetRange contains the maximum undamped value */
    EVE:QueryEntities[Targets, "CategoryID = CATEGORYID_ENTITY && Distance <= ${Ship.MaxTargetRange}"]
    Targets:GetIterator[Target]

    if !${Target:First(exists)}
    {
     if ${Me.ToEntity.IsWarpScrambled}
     {
      UI:UpdateConsole["Me Is Warp Scrambled! Searching targets...", LOG_CRITICAL]
      EVE:GetLocalPilots[MyPilotIndex]
      MyPilotIndex:GetIterator[MyPilotIterator]
      if ${MyPilotIterator:First(exists)}
      {
       do
       {
        if ${MyPilotIterator.Value.ToEntity.IsTargetingMe}
        {
         PCWar:Set[TRUE]
         HasTargets:Set[TRUE]
         HasPriorityTarget:Set[TRUE]
         UI:UpdateConsole["Found attacker ${MyPilotIterator.Value.Name}", LOG_CRITICAL]
         if ${Me.TargetCount} < ${Ship.MaxLockedTargets}
         {
          if !${MyPilotIterator.Value.ToEntity.IsLockedTarget} && !${MyPilotIterator.Value.ToEntity.BeingTargeted}
          {
           UI:UpdateConsole["Locking ${MyPilotIterator.Value.Name}"]
           MyPilotIterator.Value.ToEntity:LockTarget
          }
         }
        }
       }
       while ${MyPilotIterator:Next(exists)}
      }
      This.MyPilotIndex:Clear
     }
     else
     {
      UI:UpdateConsole["(1) No targets found..."]
      return FALSE
     }
    }
    else
    {
     UI:UpdateConsole["Damped, cant target..."]
     return TRUE
    }
   }
   else
   {
    if ${Me.ToEntity.IsWarpScrambled}
    {
     UI:UpdateConsole["Me Is Warp Scrambled! Searching targets...", LOG_CRITICAL]
     EVE:GetLocalPilots[MyPilotIndex]
     MyPilotIndex:GetIterator[MyPilotIterator]
     if ${MyPilotIterator:First(exists)}
     {
      do
      {
       if ${MyPilotIterator.Value.ToEntity.IsTargetingMe}
       {
        PCWar:Set[TRUE]
        HasTargets:Set[TRUE]
        HasPriorityTarget:Set[TRUE]
        UI:UpdateConsole["Found attacker ${MyPilotIterator.Value.Name}", LOG_CRITICAL]
        if ${Me.TargetCount} < ${Ship.MaxLockedTargets}
        {
         if !${MyPilotIterator.Value.ToEntity.IsLockedTarget} && !${MyPilotIterator.Value.ToEntity.BeingTargeted}
         {
          UI:UpdateConsole["Locking ${MyPilotIterator.Value.Name}"]
          MyPilotIterator.Value.ToEntity:LockTarget
         }
        }
       }
      }
      while ${MyPilotIterator:Next(exists)}
     }
     This.MyPilotIndex:Clear
    }
    else
    {
     UI:UpdateConsole["(2) No targets found..."]
     return FALSE
    }
   }
  }

  if ${Me.Ship.MaxLockedTargets} == 0
  {
   UI:UpdateConsole["Jammed, cant target..."]
   return TRUE
  }

  ; Chaining means there might be targets here which we shouldnt kill

  ; Start looking for (and locking) priority targets
  ; special targets and chainable targets, only priority
  ; targets will be locked in this loop
  variable bool HasPriorityTarget = FALSE
  variable bool HasChainableTarget = FALSE
  variable bool HasSpecialTarget = FALSE
  variable bool HasMultipleTypes = FALSE

  m_PriorityTargetPresent:Set[FALSE]
  m_SpecialTargetPresent:Set[FALSE]

  ; Determine the total spawn value
  if ${Target:First(exists)} && !${This.CheckedSpawnValues}
  {
   This.CheckedSpawnValues:Set[TRUE]
   do
   {
    variable int pos
    variable string NPCName
    variable string NPCGroup
    variable string NPCShipType

    NPCName:Set[${Target.Value.Name}]
    NPCGroup:Set[${Target.Value.Group}]
    pos:Set[1]
    while ${NPCGroup.Token[${pos}, " "](exists)}
    {
    ;echo ${NPCGroup.Token[${pos}, " "]}
     NPCShipType:Set[${NPCGroup.Token[${pos}, " "]}]
     pos:Inc
    }
    UI:UpdateConsole["npc ${NPCName} (${NPCShipType}) ${EVEBot.ISK_To_Str[${Target.Value.Bounty}]}"]

    ;UI:UpdateConsole["DEBUG: Type: ${Target.Value.Type}(${Target.Value.TypeID})"]
    ;UI:UpdateConsole["DEBUG: Category: ${Target.Value.Category}(${Target.Value.CategoryID})"]

    switch ${Target.Value.GroupID}
    {
     case GROUP_LARGECOLLIDABLEOBJECT
     case GROUP_LARGECOLLIDABLESHIP
     case GROUP_LARGECOLLIDABLESTRUCTURE
     case GROUP_SENTRYGUN
     case GROUP_CONCORDDRONE
     case GROUP_CUSTOMSOFFICIAL
     case GROUP_POLICEDRONE
     case GROUP_CONVOYDRONE
     case GROUP_FACTIONDRONE
     case GROUP_BILLBOARD
      continue
     default
      break
    }
    This.TotalSpawnValue:Inc[${Target.Value.Bounty}]
   }
   while ${Target:Next(exists)}
   UI:UpdateConsole["--- total ${EVEBot.ISK_To_Str[${This.TotalSpawnValue}]}"]
  }

  if ${This.TotalSpawnValue} >= ${Config.Combat.MinChainBounty}
  {
   ;UI:UpdateConsole["NPC: Spawn value exceeds minimum.  Should chain this spawn."]
   HasChainableTarget:Set[TRUE]
  }


  if ${Target:First(exists)}
  {
   variable int TypeID
   TypeID:Set[${Target.Value.TypeID}]
   do
   {
    switch ${Target.Value.GroupID}
    {
     case GROUP_LARGECOLLIDABLEOBJECT
     case GROUP_LARGECOLLIDABLESHIP
     case GROUP_LARGECOLLIDABLESTRUCTURE
     case GROUP_SENTRYGUN
     case GROUP_CONCORDDRONE
     case GROUP_CUSTOMSOFFICIAL
     case GROUP_POLICEDRONE
     case GROUP_CONVOYDRONE
     case GROUP_FACTIONDRONE
     case GROUP_BILLBOARD
      continue
     default
      break
    }

    ; If the Type ID is different then there's more then 1 type in the belt
    if ${TypeID} != ${Target.Value.TypeID}
    {
     HasMultipleTypes:Set[TRUE]
    }

    ; Check for a special target
    if ${This.IsSpecialTarget[${Target.Value.Name}]}
    {
     HasSpecialTarget:Set[TRUE]
     m_SpecialTargetPresent:Set[TRUE]
    }

    ; Loop through the priority targets
    if ${This.IsPriorityTarget[${Target.Value.Name}]}
    {
     m_PriorityTargetPresent:Set[TRUE]
     ; Yes, is it locked?
     if !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
     {
      ; No, report it and lock it.
      UI:UpdateConsole["Locking priority target ${Target.Value.Name}"]
      Target.Value:LockTarget
     }

     ; By only saying there's priority targets when they arent
     ; locked yet, the npc bot will target non-priority targets
     ; after it has locked all the priority targets
     ; (saves time once the priority targets are dead)
     if !${Target.Value.IsLockedTarget}
     {
      HasPriorityTarget:Set[TRUE]
     }

     ; We have targets
     HasTargets:Set[TRUE]
    }
   }
   while ${Target:Next(exists)}
  }

  if ${Me.ToEntity.IsWarpScrambled} && !${m_PriorityTargetPresent}
  {
   if !${This.MyLock}
   {
    UI:UpdateConsole["Player Me Is Warp Scrambled! Reset targets...", LOG_CRITICAL]
    Ship:UnlockAllTargets[]
    This.MyLock:Set[TRUE]
    UI:UpdateConsole["Searching targets...", LOG_CRITICAL]
   }
   EVE:GetLocalPilots[MyPilotIndex]
   MyPilotIndex:GetIterator[MyPilotIterator]
   if ${MyPilotIterator:First(exists)}
   {
    do
    {
     if ${MyPilotIterator.Value.ToEntity.IsTargetingMe}
     {
      PCWar:Set[TRUE]
      HasTargets:Set[TRUE]
      HasPriorityTarget:Set[TRUE]
      UI:UpdateConsole["Found attacker ${MyPilotIterator.Value.Name}", LOG_CRITICAL]
      if ${Me.TargetCount} < ${Me.Ship.MaxLockedTargets}
      {
       if !${MyPilotIterator.Value.ToEntity.IsLockedTarget} && !${MyPilotIterator.Value.ToEntity.BeingTargeted}
       {
        UI:UpdateConsole["Locking ${MyPilotIterator.Value.Name}", LOG_CRITICAL]
        MyPilotIterator.Value.ToEntity:LockTarget
       }
      }
     }
    }
    while ${MyPilotIterator:Next(exists)}
   }
   MyPilotIndex:Clear
  }


  ; Do we need to determin if we need to chain ?
  if ${Config.Combat.ChainSpawns} && ${CheckChain}
  {
   ; Is there a chainable target? Is there a special or priority target?
   if ${HasChainableTarget} && !${HasSpecialTarget} && !${HasPriorityTarget}
   {
    Chaining:Set[TRUE]
   }

   ; Special exception, if there is only 1 type its most likely
   ; a chain in progress
   if !${HasMultipleTypes} && !${HasPriorityTarget}
   {
    Chaining:Set[TRUE]
   }

   /* skip chaining if chain solo == false and we are alone */
   if !${Config.Combat.ChainSolo} && ${EVE.LocalsCount} == 1
   {
    ;UI:UpdateConsole["NPC: We are alone.  Skip chaining!!"]
    Chaining:Set[FALSE]
   }

   if ${Chaining}
   {
    UI:UpdateConsole["NPC: Chaining Spawn"]
   }
   else
   {
    UI:UpdateConsole["NPC: Not Chaining Spawn"]
   }
   CheckChain:Set[FALSE]
  }

  ; unlock targets if there are priority targets
  if ${HasPriorityTarget} && ${Target:First(exists)}
  do
  {
   if !${This.IsPriorityTarget[${Target.Value.Name}]}
   {
    if ${Target.Value.IsLockedTarget}
    {
     UI:UpdateConsole["Unlocking regular target ${Target.Value.Name}"]
     Target.Value:UnlockTarget
    }
   }
  }
  while ${Target:Next(exists)}

  ; count being targeted npc
  variable int new_target_count = 0
  if ${Target:First(exists)}
  do
  {
   if ${Target.Value.BeingTargeted}
   {
    UI:UpdateConsole["Being targeted t ${Target.Value.Group} g ${Target.Value.Name}"]
    new_target_count:Inc
   }
  }
  while ${Target:Next(exists)}

  ; If there was a priority target, dont worry about targeting the rest
  if !${HasPriorityTarget} && ${Target:First(exists)}
  do
  {
   switch ${Target.Value.GroupID}
   {
    case GROUP_LARGECOLLIDABLEOBJECT
    case GROUP_LARGECOLLIDABLESHIP
    case GROUP_LARGECOLLIDABLESTRUCTURE
    case GROUP_SENTRYGUN
    case GROUP_CONCORDDRONE
    case GROUP_CUSTOMSOFFICIAL
    case GROUP_POLICEDRONE
    case GROUP_CONVOYDRONE
    case GROUP_FACTIONDRONE
    case GROUP_BILLBOARD
     continue

    default
     break
   }

   variable bool DoTarget = FALSE
   if ${Chaining}
   {
    ; We're chaining, only kill chainable spawns'
    if ${Target.Value.Group.Find["Battleship"](exists)}
    {
     DoTarget:Set[TRUE]
    }
   }
   else
   {
    ; Target everything
    DoTarget:Set[TRUE]
   }

   ; override DoTarget to protect partially spawned chains
   if ${DoNotKillList.Contains[${Target.Value.ID}]}
   {
    DoTarget:Set[FALSE]
   }

   ; Do we have to target this target?
   if ${DoTarget}
   {
    if !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
    {
     if ${Math.Calc[${Me.TargetCount}+${new_target_count}]} < ${Ship.MaxLockedTargets}
     {
      if ${Target.Value.Distance} > ${Me.Ship.MaxTargetRange}
      {
       Target.Value:Approach
      }
      else
      {
       UI:UpdateConsole["Locking t ${Target.Value.Group} g ${Target.Value.Name}"]
       Target.Value:LockTarget
       new_target_count:Inc
      }
     }
    }

    ; Set the return value so we know we have targets
    HasTargets:Set[TRUE]
   }
   else
   {
    if !${DoNotKillList.Contains[${Target.Value.ID}]}
    {
     UI:UpdateConsole["NPC: Adding ${Target.Value.Name} (${Target.Value.Group})(${Target.Value.ID}) to the \"do not kill list\"!"]
     DoNotKillList:Add[${Target.Value.ID}]
    }
    ; Make sure (due to auto-targeting) that its not targeted
    if ${Target.Value.IsLockedTarget}
    {
     Target.Value:UnlockTarget
    }
   }
  }
  while ${Target:Next(exists)}

/*
ненужная хуита, переделать если буду фармить махой
  if ${HasTargets}
  {
   if (!${Config.Combat.FullDeactivateOrbit})
   {
    variable int OOORange
    variable int OOORange2
    if ${HasTargets} && ${Me.ActiveTarget(exists)}
    {
     if ${Config.Combat.MyOrbitRange} == 1
     {
      OOORange:Set[40000]
      OOORange2:Set[45000]
     }
     elseif ${Config.Combat.MyOrbitRange} == 2
     {
      OOORange:Set[7000]
      OOORange2:Set[10000]
     }
     else
     {
      OOORange:Set[35000]
      OOORange2:Set[39000]
     }
     Me.ActiveTarget:Orbit[${OOORange}]
    }

    if ${MyMWDStatus}
    {
     if ${Config.Combat.DeactivateMWD}
     {
      if ${Me.ActiveTarget.Distance} < ${OOORange2}
      {
       Ship:Deactivate_AfterBurner
      }
     }
    }
    else
    {
     if ${Config.Combat.DeactivateMWD}
     {
      if ${Me.ActiveTarget.Distance} > ${OOORange2}
      {
       Ship:Activate_AfterBurner
      }
     }
     else
     {
      Ship:Activate_AfterBurner
     }
    }
   }
  }
*/

  return ${HasTargets}
 }

 member:bool PC()
 {
  variable index:entity tgtIndex
  variable iterator tgtIterator

  EVE:QueryEntities[tgtIndex, "CategoryID = CATEGORYID_SHIP"]
  tgtIndex:GetIterator[tgtIterator]

  if ${tgtIterator:First(exists)}
  do
  {
   if ${tgtIterator.Value.Owner.CharID} != ${Me.CharID}
   { /* A player is already present here ! */
    UI:UpdateConsole["Player found ${tgtIterator.Value.Owner}"]
    return TRUE
   }
  }
  while ${tgtIterator:Next(exists)}

  ; No other players around
  return FALSE
 }

 member:bool NPC()
 {
  variable index:entity tgtIndex
  variable iterator tgtIterator

  EVE:QueryEntities[tgtIndex, "CategoryID = CATEGORYID_ENTITY"]
  UI:UpdateConsole["DEBUG: Found ${tgtIndex.Used} entities."]

  tgtIndex:GetIterator[tgtIterator]
  if ${tgtIterator:First(exists)}
  do
  {
   switch ${tgtIterator.Value.GroupID}
   {
    case GROUP_CONCORDDRONE
    case GROUP_CONVOYDRONE
    case GROUP_CONVOY
    case GROUP_LARGECOLLIDABLEOBJECT
    case GROUP_LARGECOLLIDABLESHIP
    case GROUP_LARGECOLLIDABLESTRUCTURE
     continue
     break
    default
     UI:UpdateConsole["DEBUG: NPC found: ${tgtIterator.Value.Group} (${tgtIterator.Value.GroupID})"]
     return TRUE
     break
   }
  }
  while ${tgtIterator:Next(exists)}

  ; No NPCs around
  return FALSE
 }

 member:bool BomzhTargetPresent()
 {
  variable index:entity Targets
  variable iterator Target

  if !${Config.Common.BotModeName.Equal[Bomzh]} && !${Config.Common.BotModeName.Equal[Taxist]}
  {
   return FALSE
  }

  EVE:QueryEntities[Targets, "CategoryID = CATEGORYID_ENTITY && Distance <= 500000"]
  Targets:GetIterator[Target]

  if ${Target:First(exists)}
  {
   variable int TypeID
   TypeID:Set[${Target.Value.TypeID}]
   do
   {
    switch ${Target.Value.GroupID}
    {
     case GROUP_LARGECOLLIDABLEOBJECT
     case GROUP_LARGECOLLIDABLESHIP
     case GROUP_LARGECOLLIDABLESTRUCTURE
     case GROUP_SENTRYGUN
     case GROUP_CONCORDDRONE
     case GROUP_CUSTOMSOFFICIAL
     case GROUP_POLICEDRONE
     case GROUP_CONVOYDRONE
     case GROUP_FACTIONDRONE
     case GROUP_BILLBOARD
      continue
     default
      break
    }
    if ${This.IsPriorityTarget[${Target.Value.Name}]}
    {
     return TRUE
     break
    }
   }
   while ${Target:Next(exists)}
  }
  return FALSE
 }

 member:bool IsRatterTargetPresent()
 {
  variable index:entity Targets
  variable iterator Target

  if !${Config.Common.BotModeName.Equal[Ratter]}
  {
   return FALSE
  }

  EVE:QueryEntities[Targets, "CategoryID = CATEGORYID_ENTITY && Distance <= 500000"]
  Targets:GetIterator[Target]

  if ${Target:First(exists)}
  {
   variable int TypeID
   TypeID:Set[${Target.Value.TypeID}]
   do
   {
    switch ${Target.Value.GroupID}
    {
     case GROUP_LARGECOLLIDABLEOBJECT
     case GROUP_LARGECOLLIDABLESHIP
     case GROUP_LARGECOLLIDABLESTRUCTURE
     case GROUP_SENTRYGUN
     case GROUP_CONCORDDRONE
     case GROUP_CUSTOMSOFFICIAL
     case GROUP_POLICEDRONE
     case GROUP_CONVOYDRONE
     case GROUP_FACTIONDRONE
     case GROUP_BILLBOARD
      continue
     default
      break
    }
    return TRUE
    break
   }
   while ${Target:Next(exists)}
  }
  return FALSE
 }


 member:bool RatterTargetPresent()
 {
  variable index:entity Targets
  variable iterator Target

  if !${Config.Common.BotModeName.Equal[Ratter]}
  {
   return FALSE
  }

  EVE:QueryEntities[Targets, "CategoryID = CATEGORYID_ENTITY && Distance <= 1000000"]
  Targets:GetIterator[Target]

  if ${Target:First(exists)}
  {
   variable int TypeID
   TypeID:Set[${Target.Value.TypeID}]
   do
   {
    switch ${Target.Value.GroupID}
    {
     case GROUP_LARGECOLLIDABLEOBJECT
     case GROUP_LARGECOLLIDABLESHIP
     case GROUP_LARGECOLLIDABLESTRUCTURE
     case GROUP_SENTRYGUN
     case GROUP_CONCORDDRONE
     case GROUP_CUSTOMSOFFICIAL
     case GROUP_POLICEDRONE
     case GROUP_CONVOYDRONE
     case GROUP_FACTIONDRONE
     case GROUP_BILLBOARD
      continue
     default
      break
    }
    if ${This.IsPriorityTarget[${Target.Value.Name}]}
    {
     return TRUE
     break
    }
   }
   while ${Target:Next(exists)}
  }
  return FALSE
 }

 member:bool myPC()
 {
  variable index:entity tgtIndex
  variable iterator tgtIterator

  EVE:QueryEntities[tgtIndex, "CategoryID = CATEGORYID_SHIP"]
  tgtIndex:GetIterator[tgtIterator]

  if ${tgtIterator:First(exists)}
  do
  {
   if ${tgtIterator.Value.Owner.CharID} != ${Me.CharID}
   {
    if ${tgtIterator.Value.Owner.Name.Equal["LoveLu"]}
    {
     /* A player is already present here ! */
;     UI:UpdateConsole["Player found ${tgtIterator.Value.Owner}"]
     return TRUE
    }
   }
  }
  while ${tgtIterator:Next(exists)}
  ; No other players around
  return FALSE
 }

;================================================================================================================
 member:bool SearchBoobleTarget()
 {
  variable index:entity BubbleTargets
  BubbleTargets:Clear
  EVE:QueryEntities[BubbleTargets, "GroupID = GROUP_MOBILEWARPDISRUPTOR && Distance <= 400000"]
  if ${BubbleTargets.Used} > 0
  {
   return TRUE
  }
  return FALSE
 }
;==================================================================================================================
 member:bool HaveAllAggro()
 {
  variable int pos
  variable string NPCName2
  variable string NPCGroup2
  variable string NPCShipType2
  variable index:entity Targets2
  variable iterator Target2
  Targets2:Clear
  ;EVE:QueryEntities[Targets2, CategoryID, CATEGORYID_ENTITY, radius, 250000]
  EVE:QueryEntities[Targets2, "CategoryID = CATEGORYID_ENTITY && Distance <= 250000"]
  Targets2:GetIterator[Target2]
  ; echo ====== 2${Target2.Value.Name}
  ;UI:UpdateConsole["ship named ${Target2.Value.Name}."]
  do
  {
   switch ${Target2.Value.GroupID}
   {
    case GROUP_LARGECOLLIDABLESHIP
    case GROUP_LARGECOLLIDABLESTRUCTURE
    case GROUP_SENTRYGUN
    case GROUP_CONCORDDRONE
    case GROUP_CUSTOMSOFFICIAL
    case GROUP_POLICEDRONE
    case GROUP_CONVOYDRONE
    case GROUP_FACTIONDRONE
    case GROUP_BILLBOARD
     continue
    default
     break
   }
   ;echo ${Target2.Value.Name}
   ;UI:UpdateConsole["ship named ${Target2.Value.Name}."]
   if !${Target2.Value.IsTargetingMe}
   {
    return FALSE
   }
  }
  while ${Target2:Next(exists)}
  return TRUE
 }
}
