objectdef obj_Social
{
 variable string SVN_REVISION = "$Rev$"
 variable int Version

 variable index:pilot PilotIndex
 variable index:entity EntityIndex
 variable collection:time WhiteListPilotLog
 variable collection:time BlackListPilotLog

 variable time NextPulse
 variable int PulseIntervalInSeconds = 1

 variable iterator WhiteListPilotIterator
 variable iterator WhiteListCorpIterator
 variable iterator WhiteListAllianceIterator
 variable iterator BlackListPilotIterator
 variable iterator BlackListCorpIterator
 variable iterator BlackListAllianceIterator
 variable bool SystemSafe
 variable bool NotSafe = FALSE

 variable set PilotBlackList
 variable set CorpBlackList
 variable set AllianceBlackList
 variable set PilotWhiteList
 variable set CorpWhiteList
 variable set AllianceWhiteList

 variable bool SystemChecker
 variable bool MyRoller = FALSE
 variable bool m_PlayerInMyRange = FALSE
 variable bool m_PlayerMeTarget  = FALSE
 variable bool m_RatsEnable = FALSE
 variable bool m_BlackUser = FALSE
 variable int MyTimeCheckWithRats  = 0
 variable int MyTimeCheckOutRats  = 0
 variable int IsSafeCooldown=0

 method Initialize()
 {
  This:ResetWhiteBlackLists

  SystemSafe:Set[TRUE]

  Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
  Event[EVE_OnChannelMessage]:AttachAtom[This:OnChannelMessage]

  UI:UpdateConsole["obj_Social: Initialized", LOG_MINOR]
 }

 method AddWL(string list, int64 id, string Comment)
 {
  if ${Whitelist.${list}sRef.FindSetting[${Comment}]}
  {
   return
  }
  Whitelist.${list}sRef:AddSetting[${Comment},${id}]
  Whitelist.${list}sRef.FindSetting[${Comment}]:AddAttribute[Auto,TRUE]
  Whitelist.${list}sRef.FindSetting[${Comment}]:AddAttribute[Timestamp,${Time.Timestamp}]
  Whitelist.${list}sRef.FindSetting[${Comment}]:AddAttribute[Expiration,0]
  Whitelist:Save
  This:ResetWhiteBlackLists
 }

 method DelWL(string list, int64 id, string Comment)
 {
  if !${Whitelist.${list}sRef.FindSetting[${Comment}](exists)}
  {
   return
  }
  Whitelist.${list}sRef.FindSetting[${Comment}]:Remove
  if !${Whitelist.BaseRef.FindSet[${list}s](exists)}
  {
   Whitelist.BaseRef:AddSet[${list}s]
  }
  Whitelist:Save
  This:ResetWhiteBlackLists
 }

 method AddBL(string list, int64 id, string Comment)
 {
  if ${Blacklist.${list}sRef.FindSetting[${Comment}]}
  {
   return
  }
  Blacklist.${list}sRef:AddSetting[${Comment},${id}]
  Blacklist.${list}sRef.FindSetting[${Comment}]:AddAttribute[Auto,TRUE]
  Blacklist.${list}sRef.FindSetting[${Comment}]:AddAttribute[Timestamp,${Time.Timestamp}]
  Blacklist.${list}sRef.FindSetting[${Comment}]:AddAttribute[Expiration,0]
  Blacklist:Save
  This:ResetWhiteBlackLists
 }

 method DelBL(string list, int64 id, string Comment)
 {
  if !${Blacklist.${list}sRef.FindSetting[${Comment}](exists)}
  {
   return
  }
  Blacklist.${list}sRef.FindSetting[${Comment}]:Remove
  if !${Blacklist.BaseRef.FindSet[${list}s](exists)}
  {
   Blacklist.BaseRef:AddSet[${list}s]
  }
  Blacklist:Save
  This:ResetWhiteBlackLists
 }

 method ResetWhiteBlackLists()
 {
  Whitelist.PilotsRef:GetSettingIterator[This.WhiteListPilotIterator]
  Whitelist.CorporationsRef:GetSettingIterator[This.WhiteListCorpIterator]
  Whitelist.AlliancesRef:GetSettingIterator[This.WhiteListAllianceIterator]

  Blacklist.PilotsRef:GetSettingIterator[This.BlackListPilotIterator]
  Blacklist.CorporationsRef:GetSettingIterator[This.BlackListCorpIterator]
  Blacklist.AlliancesRef:GetSettingIterator[This.BlackListAllianceIterator]

  UI:UpdateConsole["obj_Social: Initializing whitelist...", LOG_MINOR]
  PilotWhiteList:Add[${Me.CharID}]
  if ${Me.Corp.ID} > 0
  {
   This.CorpWhiteList:Add[${Me.Corp.ID}]
  }
;  if ${Me.AllianceID} > 0
;  {
;   This.AllianceWhiteList:Add[${Me.AllianceID}]
;  }

  if ${This.WhiteListPilotIterator:First(exists)}
  do
  {
   This.PilotWhiteList:Add[${This.WhiteListPilotIterator.Value}]
  }
  while ${This.WhiteListPilotIterator:Next(exists)}

  if ${This.WhiteListCorpIterator:First(exists)}
  do
  {
   This.CorpWhiteList:Add[${This.WhiteListCorpIterator.Value}]
  }
  while ${This.WhiteListCorpIterator:Next(exists)}

  if ${This.WhiteListAllianceIterator:First(exists)}
  do
  {
   This.AllianceWhiteList:Add[${This.WhiteListAllianceIterator.Value}]
  }
  while ${This.WhiteListAllianceIterator:Next(exists)}

  UI:UpdateConsole["obj_Social: Initializing blacklist...", LOG_MINOR]
  if ${This.BlackListPilotIterator:First(exists)}
  do
  {
   This.PilotBlackList:Add[${This.BlackListPilotIterator.Value}]
  }
  while ${This.BlackListPilotIterator:Next(exists)}

  if ${This.BlackListCorpIterator:First(exists)}
  do
  {
   This.CorpBlackList:Add[${This.BlackListCorpIterator.Value}]
  }
  while ${This.BlackListCorpIterator:Next(exists)}

  if ${This.BlackListAllianceIterator:First(exists)}
  do
  {
   This.AllianceBlackList:Add[${This.BlackListAllianceIterator.Value}]
  }
  while ${This.BlackListAllianceIterator:Next(exists)}
 }

 method Shutdown()
 {
  Event[EVE_OnChannelMessage]:DetachAtom[This:OnChannelMessage]
  Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
 }
;====================================================================================


;====================================================================================
 method Pulse()
 {
  if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
  {
   EVE:GetLocalPilots[This.PilotIndex]
   if ${This.PilotIndex.Used} == 1
   {
    This.PilotIndex:Clear
   }

   if !${Me.InStation}
   {
    EVE:QueryEntities[This.EntityIndex,"CategoryID = CATEGORYID_ENTITY"]
   }
   else
   {
    This.EntityIndex:Clear
   }

   if !${Config.Combat.UseWhiteList} && !${Config.Combat.UseStandings}
   {
    UI:UpdateConsole["WARNING! LOCAL IGNORED! use whitelist and use standings both disabled!"]
   }

   SystemSafe:Set[${Math.Calc[${This.CheckLocalWhiteList} & ${This.CheckLocalBlackList} & ${This.CheckLocalStanding}].Int(bool)}]

; begin of cooldown timer:
   if ${IsSafeCooldown} == 0 && !${SystemSafe} && ${Config.Combat.UseSafeCooldown}
   {
    IsSafeCooldown:Set[${Math.Calc[${Time.Timestamp} + (${Config.Combat.SafeCooldown} * 60)]}]
   }
   if ${IsSafeCooldown} != 0 && ${Config.Combat.UseSafeCooldown}
   {
    if ${Time.Timestamp} >= ${IsSafeCooldown}
    {
     IsSafeCooldown:Set[0]
    }
    else
    {
     if !${SystemSafe}
     {
      IsSafeCooldown:Set[${Math.Calc[${Time.Timestamp} + ${Math.Rand[${Config.Combat.SafeCooldownRandom}*60]:Inc[${Config.Combat.SafeCooldown}*60]}]}]
      DeclareVariable remain_cooldown string ${Math.Calc[((${IsSafeCooldown}-${Time.Timestamp})/3600)%60].Int.LeadingZeroes[2]}
      remain_cooldown:Concat[:]
      remain_cooldown:Concat[${Math.Calc[((${IsSafeCooldown}-${Time.Timestamp})/60)%60].Int.LeadingZeroes[2]}]
      remain_cooldown:Concat[:]
      remain_cooldown:Concat[${Math.Calc[((${IsSafeCooldown}-${Time.Timestamp}))%60].Int.LeadingZeroes[2]}]
      UI:UpdateConsole["unsafe, reset timer to ${remain_cooldown}"]
     }
     else
     {
      DeclareVariable remain_cooldown string ${Math.Calc[((${IsSafeCooldown}-${Time.Timestamp})/3600)%60].Int.LeadingZeroes[2]}
      remain_cooldown:Concat[:]
      remain_cooldown:Concat[${Math.Calc[((${IsSafeCooldown}-${Time.Timestamp})/60)%60].Int.LeadingZeroes[2]}]
      remain_cooldown:Concat[:]
      remain_cooldown:Concat[${Math.Calc[((${IsSafeCooldown}-${Time.Timestamp}))%60].Int.LeadingZeroes[2]}]
      UI:UpdateConsole["safe, remain cooldown ${remain_cooldown}"]
     }
     SystemSafe:Set[FALSE]
    }
   }
; end of cooldown timer

; new awoxer protection:
   if ${Config.Combat.GameOverGrid} && \
    !${Safespots.IsAtSafespot} && \
    !${EVEBot.Paused}
   {
    variable index:entity tgtIndex
    variable iterator tgtIterator

    EVE:QueryEntities[tgtIndex, "CategoryID = CATEGORYID_SHIP"]
    tgtIndex:GetIterator[tgtIterator]

    if ${tgtIterator:First(exists)}
    do
    {
     variable bool badgrid
     badgrid:Set[FALSE]
     if !${Config.Combat.GameOverGridNeutral}
     {
      if ${tgtIterator.Value.Owner.Corp.ID} != ${Me.Corp.ID}
      {
       UI:UpdateConsole["1"]
       badgrid:Set[TRUE]
      }
     } else {
      if !${This.goodguy[${tgtIterator.Value.Owner}]}
      {
       UI:UpdateConsole["2"]
       badgrid:Set[TRUE]
      }
     }
     if ${badgrid}
     {
      UI:UpdateConsole["!!! hostile ${tgtIterator.Value.Owner.Name} in grid at ${tgtIterator.Value.Distance} !!! emergency logoff !!!"]
 ;----- start screenshot -----
 Display:Screencap[ \
  ${Me.Name}- \
  ${Time.Year.LeadingZeroes[4]}_ \
  ${Time.Month.LeadingZeroes[2]}_ \
  ${Time.Day.LeadingZeroes[2]}- \
  ${Time.Hour.LeadingZeroes[2]}_ \
  ${Time.Minute.LeadingZeroes[2]}_ \
  ${Time.Second.LeadingZeroes[2]}. \
  jpg \
 ]
 ;----- end screenshot -----
      EVE:Execute[CmdQuitGame]
     }
    }
    while ${tgtIterator:Next(exists)}
   }
; end of

; legacy awoxer protection:
   if ${SystemSafe}
   {
    MyTimeCheckOutRats:Inc
    m_RatsEnable:Set[FALSE]
    MyTimeCheckWithRats:Set[0]
    MyRoller:Set[FALSE]
   }
   else
   {
    NotSafe:Set[TRUE]
;    UI:UpdateConsole["need to be carefull. danger status: ${NotSafe}"]
    if ${MyRoller}
    {
     MyRoller:Set[FALSE]
    }
    else
    {
     MyRoller:Set[TRUE]
    }
    if ${MyTimeCheckOutRats} > 0 && ${MyTimeCheckOutRats} < 180
    {
     m_RatsEnable:Set[TRUE]
    }
    MyTimeCheckOutRats:Set[0]
    MyTimeCheckWithRats:Inc
   }
; end of


   This.NextPulse:Set[${Time.Timestamp}]
   This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
   This.NextPulse:Update
  }
 }


;====================================================================================


 method OnChannelMessage(int ChannelID, int64 CharID, int64 CorpID, int64 AllianceID, string CharName, string MessageText)
 {
  if ${ChannelID} == ${Me.SolarSystemID}
  {
   if ${CharName.NotEqual["EVE System"]}
   {
    Play "c:\\tmp\\detect.wav"
;    call Sound.PlayTellSound
    UI:UpdateConsole["Channel Local: ${CharName.Escape}: ${MessageText.Escape}", LOG_CRITICAL]
   }
  }
 }

 member:bool IsSafe()
 {
  return ${This.SystemSafe}
 }
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 member:bool GankWereHere()
 {
  return ${This.NotSafe}
 }

 method ResetGankWereHere()
 {
  This.NotSafe:Set[FALSE]
 }

 member:bool IsPlayerInMyRange()
 {
  return ${This.m_PlayerInMyRange}
 }

 member:bool IsPlayerMeTarget()
 {
  return ${This.m_PlayerMeTarget}
 }

 member:bool IsRatsEnable()
 {
  return ${This.m_RatsEnable}
 }

 member:bool IsBlackUser()
 {
  return ${This.m_BlackUser}
 }
;=========================================================

 member:bool goodguy(pilot guy)
 {
  variable index:float standings
  variable iterator standings_iterator

  standings:Clear
  standings:Insert[${guy.Standing.MeToPilot}]
  standings:Insert[${guy.Standing.MeToCorp}]
  standings:Insert[${guy.Standing.MeToAlliance}]
  standings:Insert[${guy.Standing.CorpToPilot}]
  standings:Insert[${guy.Standing.CorpToCorp}]
  standings:Insert[${guy.Standing.CorpToAlliance}]
  standings:Insert[${guy.Standing.AllianceToPilot}]
  standings:Insert[${guy.Standing.AllianceToCorp}]
  standings:Insert[${guy.Standing.AllianceToAlliance}]
  standings:GetIterator[standings_iterator]
  if ${standings_iterator:First(exists)}
  do
  {
   if ${standings_iterator.Value} > 0
   {
    return TRUE
    break
   }
   elseif ${standings_iterator.Value} < 0
   {
    return FALSE
    break
   }
  }
  while ${standings_iterator:Next(exists)}
  return FALSE
 }

 ; Returns false if pilots with failed standing are in system
 member:bool CheckLocalStanding()
 {
  variable index:pilot pilot_index
  variable iterator pilot_iterator

  EVE:GetLocalPilots[pilot_index]
  if ( \
   ${pilot_index.Used} < 2 || \
   !${Config.Combat.UseStandings}\
  )
  {
   return TRUE
  }

  pilot_index:GetIterator[pilot_iterator]
  if ${pilot_iterator:First(exists)}
  do
  {
   if ( \
    ${pilot_iterator.Value.CharID} != -1 && \
    ${pilot_iterator.Value.CharID} != ${Me.CharID} && \
    ${pilot_iterator.Value.Corp.ID} != ${Me.Corp.ID} && \
    !${Me.Fleet.IsMember[${pilot_iterator.Value.CharID}]} && \
    !${This.goodguy[${pilot_iterator.Value}]} \
   )
   {
    UI:UpdateConsole["bad standing ${pilot_iterator.Value.Name} p ${pilot_iterator.Value.CharID} c ${pilot_iterator.Value.Corp.ID} a ${pilot_iterator.Value.AllianceID}", LOG_CRITICAL]
    return FALSE
   }
  }
  while ${pilot_iterator:Next(exists)}
  return TRUE
 }


;=========================================================

 member:bool CheckLocalWhiteList()
 {
  m_PlayerInMyRange:Set[FALSE]
  m_PlayerMeTarget:Set[FALSE]
  variable iterator PilotIterator
  variable int CorpID
  variable int AllianceID
  variable int PilotID
  variable string PilotName
  variable int PilotDistance

  if !${Config.Combat.UseWhiteList}
  {
   return TRUE
  }

  if ${This.PilotIndex.Used} < 2
  {
   return TRUE
  }

  This.PilotIndex:GetIterator[PilotIterator]
  if ${PilotIterator:First(exists)}
  do
  {
   CorpID:Set[${PilotIterator.Value.Corp.ID}]
   AllianceID:Set[${PilotIterator.Value.AllianceID}]
   PilotID:Set[${PilotIterator.Value.CharID}]
   PilotName:Set[${PilotIterator.Value.Name}]
   PilotDistance:Set[${PilotIterator.Value.ToEntity.Distance}]

   if !${This.AllianceWhiteList.Contains[${AllianceID}]} && \
    !${This.CorpWhiteList.Contains[${CorpID}]} && \
    !${This.PilotWhiteList.Contains[${PilotID}]} && \
    !${Me.Fleet.IsMember[${PilotID}]}
   {
    UI:UpdateConsole["unlisted ${PilotName} p ${PilotID} c ${CorpID} a ${AllianceID}", LOG_CRITICAL]
    return FALSE
   }
   if ${Me.CharID} != ${PilotIterator.Value.CharID} && ${PilotIterator.Value.ToEntity(exists)} && ${PilotIterator.Value.ToEntity.IsPC}
   {
    m_PlayerInMyRange:Set[TRUE]
    if ${PilotIterator.Value.ToEntity.IsTargetingMe}
    {
     SystemChecker:Set[FALSE]
     m_PlayerMeTarget:Set[TRUE]
    }
   }
  }
  while ${PilotIterator:Next(exists)}
  return TRUE
 }

 member:bool CheckLocalBlackList()
 {
  variable iterator PilotIterator
  if !${Config.Combat.UseBlackList}
  {
   return TRUE
  }

  if ${This.PilotIndex.Used} < 2
  {
   return TRUE
  }

  This.PilotIndex:GetIterator[PilotIterator]
  if ${PilotIterator:First(exists)}
  do
  {
   if !${Me.Fleet.IsMember[${PilotIterator.Value.CharID}]} && \
    ${Me.CharID} != ${PilotIterator.Value.CharID} && \
    ( ${This.PilotBlackList.Contains[${PilotIterator.Value.CharID}]} || \
     ${This.AllianceBlackList.Contains[${PilotIterator.Value.AllianceID}]} || \
     ${This.CorpBlackList.Contains[${PilotIterator.Value.Corp.ID}]} \
    )
   {
    UI:UpdateConsole["blacklisted ${PilotIterator.Value.Name} p ${PilotIterator.Value.CharID} c ${PilotIterator.Value.Corp.ID} a ${PilotIterator.Value.AllianceID}", LOG_CRITICAL]
    return FALSE
   }
  }
  while ${PilotIterator:Next(exists)}
  return TRUE
 }

 member:bool PlayerInRange(float Range=0)
 {
  if ${Range} == 0
  {
   return FALSE
  }

  if ${This.PilotIndex.Used} < 2
  {
   return FALSE
  }

  variable iterator PilotIterator
  This.PilotIndex:GetIterator[PilotIterator]

  if ${PilotIterator:First(exists)}
  {
   do
   {
    if ${Me.CharID} != ${PilotIterator.Value.CharID} && \
     ${PilotIterator.Value.ToEntity(exists)} && \
     ${PilotIterator.Value.ToEntity.IsPC} && \
     ${PilotIterator.Value.ToEntity.Distance} < ${Config.Miner.AvoidPlayerRange} && \
     !${PilotIterator.Value.ToFleetMember}
    {
     UI:UpdateConsole["PlayerInRange: ${PilotIterator.Value.Name} - ${EVEBot.MetersToKM_Str[${PilotIterator.Value.ToEntity.Distance}]"]
     return TRUE
    }
   }
   while ${PilotIterator:Next(exists)}
  }
  return FALSE
 }

 member:bool NPCDetection()
 {
  if !${This.EntityIndex.Used}
  {
   return FALSE
  }

  variable iterator EntityIterator
  This.EntityIndex:GetIterator[EntityIterator]

  if ${EntityIterator:First(exists)}
  {
   do
   {
    if ${EntityIterator.Value.IsNPC}
    {
     return TRUE
    }
   }
   while ${EntityIterator:Next(exists)}
  }

  return FALSE
 }

 member:bool StandingDetection(int Standing)
 {
  return FALSE
  ; TODO - this is broken, isxeve standing check doesn't work atm.

  echo ${This.PilotIndex.Used}

  if ${This.PilotIndex.Used} < 2
  {
   return FALSE
  }

  variable iterator PilotIterator
  This.PilotIndex:GetIterator[PilotIterator]


  if ${PilotIterator:First(exists)}
  {
   do
   {
    echo ${PilotIterator.Value.Name} ${PilotIterator.Value.CharID} ${PilotIterator.Value.Corp.ID} ${PilotIterator.Value.AllianceID}
    echo ${Me.Standing[${PilotIterator.Value.CharID}]}
    echo ${Me.Standing[${PilotIterator.Value.Corp.ID}]}
    echo ${Me.Standing[${PilotIterator.Value.AllianceID}]}

    if ${Me.CharID} == ${PilotIterator.Value.CharID}
    {
     echo "StandingDetection: Ignoring Self"
     continue
    }

    if ${PilotIterator.Value.ToFleetMember(exists)}
    {
     echo "StandingDetection Ignoring Fleet Member: ${PilotIterator.Value.Name}"
     continue
    }

    /* Check Standing */
    echo Me -> Them ${EVE.Standing[${Me.CharID},${PilotIterator.Value.CharID}]}
    echo Corp -> Them ${EVE.Standing[${Me.Corp.ID},${PilotIterator.Value.CharID}]}
    echo Alliance -> Them ${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.CharID}]}
    echo Me -> TheyCorp ${EVE.Standing[${Me.CharID},${PilotIterator.Value.Corp.ID}]}
    echo MeCorp -> TheyCorp ${EVE.Standing[${Me.Corp.ID},${PilotIterator.Value.Corp.ID}]}
    echo MeAlliance -> TheyCorp ${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.Corp.ID}]}
    echo Me -> TheyAlliance ${EVE.Standing[${Me.CharID},${PilotIterator.Value.AllianceID}]}
    echo MeCorp -> TheyAlliance ${EVE.Standing[${Me.Corp.ID},${PilotIterator.Value.AllianceID}]}
    echo MeAlliance -> TheyAlliance ${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.AllianceID}]}

    echo They -> Me ${EVE.Standing[${PilotIterator.Value.CharID},${Me.CharID}]}
    echo TheyCorp -> Me ${EVE.Standing[${PilotIterator.Value.Corp.ID},${Me.CharID}]}
    echo TheyAlliance -> Me ${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.CharID}]}
    echo They -> MeCorp ${EVE.Standing[${PilotIterator.Value.CharID},${Me.Corp.ID}]}
    echo TheyCorp -> MeCorp ${EVE.Standing[${PilotIterator.Value.Corp.ID},${Me.Corp.ID}]}
    echo TheyAlliance -> MeCorp ${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.Corp.ID}]}
    echo They -> MeAlliance ${EVE.Standing[${PilotIterator.Value.CharID},${Me.AllianceID}]}
    echo TheyCorp -> MeAlliance ${EVE.Standing[${PilotIterator.Value.Corp.ID},${Me.AllianceID}]}
    echo TheyAlliance -> MeAlliance ${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.AllianceID}]}

    if ${EVE.Standing[${Me.CharID},${PilotIterator.Value.CharID}]} < ${Standing} || \
     ${EVE.Standing[${Me.Corp.ID},${PilotIterator.Value.CharID}]} < ${Standing} || \
     ${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.CharID}]} < ${Standing} || \
     ${EVE.Standing[${Me.CharID},${PilotIterator.Value.Corp.ID}]} < ${Standing} || \
     ${EVE.Standing[${Me.Corp.ID},${PilotIterator.Value.Corp.ID}]} < ${Standing} || \
     ${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.Corp.ID}]} < ${Standing} || \
     ${EVE.Standing[${Me.CharID},${PilotIterator.Value.AllianceID}]} < ${Standing} || \
     ${EVE.Standing[${Me.Corp.ID},${PilotIterator.Value.AllianceID}]} < ${Standing} || \
     ${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.AllianceID}]} < ${Standing} || \
     ${EVE.Standing[${PilotIterator.Value.CharID},${Me.CharID}]} < ${Standing} || \
     ${EVE.Standing[${PilotIterator.Value.Corp.ID},${Me.CharID}]} < ${Standing} || \
     ${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.CharID}]} < ${Standing} || \
     ${EVE.Standing[${PilotIterator.Value.CharID},${Me.Corp.ID}]} < ${Standing} || \
     ${EVE.Standing[${PilotIterator.Value.Corp.ID},${Me.Corp.ID}]} < ${Standing} || \
     ${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.Corp.ID}]} < ${Standing} || \
     ${EVE.Standing[${PilotIterator.Value.CharID},${Me.AllianceID}]} < ${Standing} || \
     ${EVE.Standing[${PilotIterator.Value.Corp.ID},${Me.AllianceID}]} < ${Standing} || \
     ${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.AllianceID}]} < ${Standing}
    {
     /* Yep, I'm laughing right now as well -- CyberTech */
     UI:UpdateConsole["obj_Social: StandingDetection in local: ${PilotIterator.Value.Name} - ${PilotIterator.Value.Standing}!", LOG_CRITICAL]
     return TRUE
    }
   }
   while ${PilotIterator:Next(exists)}

  }

  return FALSE
 }

 member:bool PilotsWithinDetection(int Dist)
 {
  if ${This.PilotIndex.Used} < 2
  {
   return FALSE
  }

  variable iterator PilotIterator
  This.PilotIndex:GetIterator[PilotIterator]

  if ${PilotIterator:First(exists)}
  {
   do
   {
    if (${Me.ShipID} != ${PilotIterator.Value.ID}) && \
     !${PilotIterator.Value.ToFleetMember} && \
     ${PilotIterator.Value.Distance} < ${Dist}
    {
     return TRUE
    }
   }
   while ${PilotIterator:Next(exists)}
  }

  return FALSE
 }

 member:bool PossibleHostiles()
 {
  if ${This.PilotIndex.Used} < 2
  {
   return FALSE
  }

  variable bool bReturn = FALSE
  variable iterator PilotIterator
  variable float PilotSecurityStatus

  This.PilotIndex:GetIterator[PilotIterator]

  if ${PilotIterator:First(exists)}
  {
   do
   {
    if  ${Me.CharID} == ${PilotIterator.Value.CharID} || \
     !${PilotIterator.Value.ToEntity(exists)} || \
     ${PilotIterator.Value.ToFleetMember(exists)}
    {
     continue
    }

    if ${PilotIterator.Value.ToEntity.IsTargetingMe}
    {
     UI:UpdateConsole["obj_Social: Hostile on grid: ${PilotIterator.Value.Name} is targeting me", LOG_CRITICAL]
     bReturn:Set[TRUE]
    }

    ; Entity.Security returns -9999.00 if it fails, so we need to check for that
    PilotSecurityStatus:Set[${PilotIterator.Value.ToEntity.Security}]
    if ${PilotSecurityStatus} > -11.0 && \
     ${PilotSecurityStatus} < ${Config.Miner.MinimumSecurityStatus}
    {
     UI:UpdateConsole["obj_Social: Possible hostile: ${PilotIterator.Value.Name} Sec Status: ${PilotSecurityStatus.Centi}", LOG_CRITICAL]
     bReturn:Set[TRUE]
    }
   }
   while ${PilotIterator:Next(exists)}
  }

  return ${bReturn}
 }

}
