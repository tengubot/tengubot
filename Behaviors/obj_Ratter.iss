objectdef obj_Ratter
{
 variable string SVN_REVISION = "$Rev: 1003 $"
 variable int Version
 variable int last_orbit_time = 0

 variable string CurrentState
 variable time NextPulse
 variable int PulseIntervalInSeconds = 2
 variable obj_Combat Combat
 variable string Moon = "MOCW-2 - Moon 1"
 variable bool FirstInPlex = TRUE
; =========================================
 variable string CombatState
 variable string MyErrMess
;==========================================

 ;координаты первой пробки
 variable int X=${Config.Coords.1stResultX}
 variable int Y=${Config.Coords.1stResultY}
 variable int HY=16
 variable int HX1=60
 variable int HX2=80
 variable index:bookmark ScanMarkIndex
 variable iterator ScanMarkIterator
 variable int s
 variable string AnomalyName
 variable string ScanMarkLabel
 variable index:fleetmember FleetMembers
 variable iterator FleetMember
 variable float MyVolumeCharges
 variable string MyChargesS

 method Initialize()
 {
  Event[OnFrame]:AttachAtom[This:Pulse]

  variable index:module ModuleList
  variable iterator ModuleIter
  Me.Ship:GetModules[ModuleList]
  ModuleList:GetIterator[ModuleIter]
  if ${ModuleIter:First(exists)}
  do
  {
   if ${ModuleIter.Value.ToItem.Slot.Left[6].Equal[HiSlot]} == TRUE && ${ModuleIter.Value.Charge.Volume} != NULL && ${ModuleIter.Value.Charge.Name.Equal[NULL]} == FALSE
   {
    MyVolumeCharges:Set[${ModuleIter.Value.Charge.Volume}]
    MyChargesS:Set[${ModuleIter.Value.Charge.Name}]
    break
   }
  }
  while ${ModuleIter:Next(exists)}

  BotModules:Insert["Ratter"]
  This.CurrentState:Set["FIGHT"]
  Targets:ResetTargets
  This.Combat:Initialize
  This.Combat:SetMode["AGGRESSIVE"]
  UI:UpdateConsole["My Charges - ${MyChargesS}", LOG_MINOR]
  UI:UpdateConsole["My VolumeCharges - ${MyVolumeCharges}", LOG_MINOR]
  UI:UpdateConsole["obj_Ratter: Initialized", LOG_MINOR]
 }

 method Pulse()
 {
  if ${EVEBot.Paused}
  {
   return
  }

  if !${Config.Common.BotModeName.Equal[Ratter]}
  {
   return
  }

  if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
  {
   This:SetState[]
   This.NextPulse:Set[${Time.Timestamp}]
   This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
   This.NextPulse:Update
  }
  ;; call the combat frame action code
  This.Combat:Pulse
 }

 method Shutdown()
 {
  Event[OnFrame]:DetachAtom[This:Pulse]
 }

; STATE MACHINE:  * -> IDLE -> MOVE -> PCCHECK -> FIGHT -> *
 method SetState()
 {
  /* Combat module handles all fleeing states now */
  switch ${This.CurrentState}
  {
   case IDLE
    This.CurrentState:Set["MOVE"]
    break
   default
    break
  }
 }
;====================================================

;====================================================
 function ProcessState()
 {
  /* don't do anything if we aren't in Ratter bot mode! */
  if !${Config.Common.BotModeName.Equal[Ratter]}
   return

  ; call the combat object state processing
  call This.Combat.ProcessState

  ; see if combat object wants to
  ; override bot module state.
  if ${This.Combat.Override}
   return

  UI:UpdateConsole["DEBUG: ${This.CurrentState}"]
  switch ${This.CurrentState}
  {

   case FIGHT
    call This.Fight
    break
   case MOVE
    call This.Move
    break
  }
 }

 function Move()
 {
  Ship:Activate_SensorBoost
  if ${Social.IsSafe}
  {
   if ${Me.Ship.CargoCapacity} < 1
   {
    call Safespots.WarpTo
    wait 10
    UI:UpdateConsole["obj_Ratter: TEBYA EBNYLI, KEREBIRKO! Log Off in 3 seconds!!!"]
    wait 10
    UI:UpdateConsole["obj_Ratter: 3"]
    wait 10
    UI:UpdateConsole["obj_Ratter: 2"]
    wait 10
    UI:UpdateConsole["obj_Ratter: 1"]
    wait 10
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
    wait 100
    EVE:Execute[CmdQuitGame]
   }
   wait 5
   ;UI:UpdateConsole["obj_Ratter: There are 1:${EVE.GetLocalPilots} 2:${GetLocalPilots} pilots in system."]

   This.FirstInPlex:Set[TRUE]

   if ${Config.Coords.AmmoReload}
   {
    call This.CheckAmmo
   }


   if ${Config.Coords.Support}
   {
   ;echo SUPPORT!
    call This.WarpToPilot
    return
   }
   else
   {
    echo ScaNNEr
    Ship:Deactivate_Weapons
    Ship:Deactivate_Tracking_Computer
    Ship:Deactivate_ECCM
    Ship:Reload_Weapons[TRUE]
    if ${Me.ToEntity.IsWarpScrambled}
    {
     Ship:Activate_SmartBomb
    }
    call This.Scanner
   }
   Targets:ResetTargets
  }
  ; Wait for the rats to warp into the belt. Reports are between 10 and 20 seconds.
  variable int Count
  for (Count:Set[0] ; ${Count}<=1 ; Count:Inc)
  {
   if ${Targets.PC} || ${Targets.NPC} || !${Social.IsSafe}
   {
    break
   }
   wait 10
  }

  if (${Count} > 1)
  {
   ; If we had to wait for rats, Wait another second to try to let them get into range/out of warp
   wait 10
  }

  Count:Set[0]
  while (${Count:Inc} < 5) && ${Social.IsSafe} && !${Targets.PC} && ${Targets.NPC}
  {
   wait 10
  }
  This.CurrentState:Set["FIGHT"]
 }



 function Fight()
 {

  ;if ${This.Social.GankWereHere} && ${Entity["TypeID = 28356"].ID(exists)}
  ;{
  ; if ${Entity["TypeID = 28356"].Distance} < 80000
  ; {
  ;  UI:UpdateConsole["Keeping align to POS"]
  ;  call Safespots.AlignToNextSafeSpot
  ; }
  ; else
  ; {
  ;  EVE:Execute[CmdStopShip]
  ;  UI:UpdateConsole["We at 80 km from anomaly, canceling align"]
  ; }
  ;}

  Ship:Activate_SensorBoost
  Ship:Activate_Tracking_Computer
  Ship:Activate_ECCM
  ;UI:UpdateConsole["Activate SensorBoost"]

  if ${Ship.Drones.DronesInSpace} > 0
  {
      ;echo Rater_Fight_sendingdrones
   Ship.Drones:SendDrones
  }

  if ${Config.Coords.OrbitAnomaly}
;&& !${This.Social.GankWereHere}
  {
   call This.OrbitCenterOfAnomaly ${Config.Coords.OrbitDistance}
  }

  if ${Config.Coords.Support}
  {
   call This.WarpToPilot
  }

  if ${Targets.TargetNPCs}
  {
   ; активация смарты по активному таргету если он в рейдже активации. потому что порой нпс в рейндже смарты и не скрамбит, но дроны ее убить не могут.
   ;UI:UpdateConsole["NPC: ${NPCName}(${NPCShipType}) ${EVEBot.ISK_To_Str[${EVEDB_Spawns.SpawnBounty[${NPCName}]}]}"]
   ;UI:UpdateConsole[" ${Me.Targets} distance ${NPC.Value.Distance}"]
   ; ToEntity.Distance
   if ${Me.ToEntity.IsWarpScrambled} || (${Me.ActiveTarget(exists)} && ${Me.ActiveTarget.Distance} < ${Config.Coords.SmartBombRange})
   {
    Ship:Activate_SmartBomb
   }
   else
   {
    Ship:Deactivate_SmartBomb
   }
   ;если нас скрамбят и есть приорити таргет, то это 100% скрамбит нпс в рейндже смарты.  Так что можно отследить и врубить смарту без лока цели.
   ;echo prioryty present ? - ${Targets.PriorityTargetPresent} scrambled? - ${Me.ToEntity.IsWarpScrambled}
   ;UI:UpdateConsole["prioryty present ? - ${Targets.PriorityTargetPresent} scrambled? - ${Me.ToEntity.IsWarpScrambled}"]

   if !${This.FirstInPlex}
   {
    UI:UpdateConsole["Found another Player is making that plex.", LOG_CRITICAL]
    call This.AnomalyBookmark
    This.CurrentState:Set["MOVE"]
    return
   }

   ;--------------------------------------------------
   if ${Config.Coords.AnomalyName.Right[7].Equal[Sanctum]} == TRUE
   {
    if ${Config.Coords.Sanctum1} == TRUE && ${Entity["complex"].ID(exists)}
    {
    }
    else
    {
     if (${Config.Coords.Sanctum2} == TRUE) && !${Entity["complex"].ID(exists)}
     {
     }
     else
     {
      call This.AnomalyBookmark
      This.CurrentState:Set["MOVE"]
      return
     }
    }
   }
   if ${Social.IsSafe}
   {
    call Combat.ManageTank
    This.CurrentState:Set["FIGHT"]
    wait 30
    return
   }
  }

; COMPLEX - AGGRO
  if ${Entity["Pirate Complex"].ID(exists)} && !${Config.Coords.Support}
  {
   if ${Social.IsSafe}
   {
    UI:UpdateConsole["Pirate Complexes found. Making aggro and wait for rats."]
    Entity["Pirate Complex"]:LockTarget
    do
    {
     wait 10
    }
    while !${Me.ActiveTarget(exists)}
    call Combat.Fight
    wait 70
    Entity["Pirate Complex"]:UnlockTarget
   }
  }

; BUNKER - AGGRO
  if ${Entity["Bunker"].Name(exists)} && !${Config.Coords.Support}
  {
   if ${Social.IsSafe}
   {
    UI:UpdateConsole["Bunkers found. Making aggro and wait for rats."]
    variable index:entity BunkerStructures
    variable iterator BunkerStructure
    EVE:DoGetEntities[BunkerStructures,  CategoryID, CATEGORYID_ENTITY, radius, 300000]
    BunkerStructures:GetIterator[BunkerStructure]

    if ${BunkerStructure:First(exists)}
    {
     do
     {
      if ${BunkerStructure.Value.TypeID} == 18012 && ${BunkerStructure.Value.Name.Left[6].Equal["Bunker"]}
      {
       BunkerStructure.Value:LockTarget
       do
       {
        wait 10
       }
       while !${Me.ActiveTarget(exists)}

       wait 20

       if ${_Me.GetTargets} > 0
       {
        call Combat.Fight
        wait 10
        return
       }
      }
     }
     while ${BunkerStructure:Next(exists)}

    }
   }
  }

; GHOST COLONY - AGGRO

  if ${Entity["Ghost Colony"].ID(exists)} && !${Config.Coords.Support}
  {
   if ${Social.IsSafe}
   {
    UI:UpdateConsole["Ghost Colonies found. Making aggro and wait for rats."]
    Entity["Ghost Colony"]:LockTarget
    do
    {
     wait 10
    }
    while !${Me.ActiveTarget(exists)}
    call Combat.Fight
    wait 20
    Entity["Ghost Colony"]:UnlockTarget
   }
  }
  if ${Targets.TargetNPCs} && ${Social.IsSafe}
  {
   if ${Targets.SpecialTargetPresent}
   {
    UI:UpdateConsole["Special spawn Detected!", LOG_CRITICAL]
    call Sound.PlayDetectSound
    ; Wait 5 seconds
    wait 50
   }
  }
; COSMIC - WAIT
  variable int waitinplex

  if ${Entity["TypeID = 28356"].ID(exists)}
  {
   UI:UpdateConsole["Waiting stupid rats at 30 seconds."]
   for (waitinplex:Set[6] ; ${waitinplex}>=1 ; waitinplex:Dec)
   {
    if ${Targets.NPC}
    {
     This.CurrentState:Set["FIGHT"]
     return
    }
    else
    {
     wait 70
    }
   }
  }
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if ${Entity["Drone Structure I"].ID(exists)} && !${Config.Coords.Support}
  {
   if ${Social.IsSafe}
   {
    UI:UpdateConsole["Drone Structure I found. Making aggro and wait for rats."]
    Entity["Drone Structure I"]:LockTarget
    do
    {
     wait 10
    }
    while !${Me.ActiveTarget(exists)}
    call Combat.Fight
    wait 20
    ;Entity["Drone structure 1"]:UnlockTarget
   }
  }
; STANTION - KILLING THEM

;  if  ${Entity["Wreck"].ID(exists)}
;  {
;   if ${Social.IsSafe}
;   {
;    UI:UpdateConsole["Seeking fucking bumpage dick such as Stantion and killing them."]
;    variable index:entity FinalStructures
;    variable iterator FinalStructure
;    EVE:DoGetEntities[FinalStructures,  CategoryID, CATEGORYID_ENTITY, radius, 300000]
;    FinalStructures:GetIterator[FinalStructure]
;
;    if ${FinalStructure:First(exists)}
;    {
;     do
;     {
;      if ${FinalStructure.Value.TypeID} == 16736 || ${FinalStructure.Value.TypeID} == 23663 || ${FinalStructure.Value.TypeID} == 16733
;      {
;       FinalStructure.Value:LockTarget
;       do
;       {
;        wait 10
;       }
;       while !${Me.ActiveTarget(exists)}
;      }
;     }
;     while ${FinalStructure:Next(exists)}
;    }
;
;    wait 30
;
;    if ${_Me.GetTargets} > 0
;    {
;     while ${_Me.GetTargets} > 0 && ${Social.IsSafe}
;     {
;      Ship:Activate_Weapons
;     }
;    }
;   }
;  }

; WRECK - SQUADCOMM

  if ${Entity["Wreck"].ID(exists)} && !${Config.Coords.Support}
  {
   variable index:fleetmember FMembers
   variable iterator FMember

   FMembers:Clear
   Me.Fleet:GetMembers[FMembers]
   FMembers:GetIterator[FMember]

   FMember:First

   if ${FMember:First(exists)}
   {
    do
    {
     if ${FMember.Value.CharID} == ${Me.CharID}
      {
       UI:UpdateConsole["SelfMoving to SquadCommanders and waiting looter. WAKE UP, LOOTER!"]
       EVE:Execute[CmdStopShip]
       FMember.Value:MoveToSquadCommander[${FMember.Value.WingID},${FMember.Value.SquadID}]
       wait 50
       while ${FMember.Value.RoleID} == 3 && ${Social.IsSafe}
       {
        UI:UpdateConsole["Waiting while we will be moved by looter."]
        wait 50
       }
      }
    }
    while ${FMember:Next(exists)}
   }
  }

; NOSUPPORT - SCAN

  if !${Config.Coords.Support}
  {
   UI:UpdateConsole["Flying to next anomaly."]

; for inventory debug only
;   if ${Config.Coords.AmmoReload}
;   {
;    call This.CheckAmmo
;   }

   call This.AnomalyBookmark
   return
  }
 }

function Scanner()
{

 if ${Config.Coords.AmmoReload}
 {
  call This.CheckAmmo
 }

 Ship:Reload_Weapons[TRUE]

 UI:UpdateConsole["WARNING! DO NOT MOVE MOUSE WHILE WE NOT IN PLEX OR EVE WINDOW IS ACTIVE!"]
 call Safespots.WarpTo

 if !${EVEWindow[ByCaption,Scanner](exists)}
 {
  UI:UpdateConsole["scanner closed. trying to open it"]
  EVE:Execute[OpenScanner]
 }
 wait 10
 EVEWindow[ByCaption,Scanner]:Maximize

/* модуль кликанья по сканеру  и варп на метку плекса по префиксу */
;варп на спот перед тем как сканить . а то еще найдут и епнут....
 if ${Social.IsSafe}
 {
  wait ${Config.Coords.WaitBeforeScan}
  variable int v
  Mouse:SetPosition[${Config.Coords.ReConX},${Config.Coords.ReConY}]
  wait ${Config.Coords.MouseDelay}
  Mouse:LeftClick
  wait ${Config.Coords.MouseDelay}
  Mouse:SetPosition[${Config.Coords.ScanX},${Config.Coords.ScanY}]
  wait ${Config.Coords.MouseDelay}
  Mouse:LeftClick
  wait ${Config.Coords.MouseDelay}

  if ${Config.Coords.AmmoReload}
  {
   call This.CheckAmmo
   ;call Safespots.WarpTo
  }

  ; ждем пока пройдет скан
  wait ${Config.Coords.AnalyzeTime}
  ;возвращаем пробки назад. ибо они не нужны уже чтобы оперировать результатами сканера
  ;Mouse:SetPosition[${Config.Coords.RecoverX},${Config.Coords.RecoverY}]
  ;wait ${Config.Coords.MouseDelay}
  ;Mouse:LeftClick
  ;wait ${Config.Coords.MouseDealy}

/* модуль букмарка первого результата */
  X:Set[${Config.Coords.1stResultX}]
  Y:Set[${Config.Coords.1stResultY}]
  for (v:Set[1] ; ${v}<=5 ; v:Inc)
  {
   if ${Social.IsSafe}
   {
    Mouse:SetPosition[${X},${Y}]
    wait ${Config.Coords.MouseDelay}
    Mouse:LeftClick
    wait ${Config.Coords.MouseDelay}
    Mouse:RightClick
    wait ${Config.Coords.MouseDelay}
    X:Set[${Math.Calc[${X}+${HX1}]}]
    Y:Set[${Math.Calc[${Y}+(3*${HY})-(${HY}/2)]}]
    Mouse:SetPosition[${X},${Y}]
    wait ${Config.Coords.MouseDelay}
    Mouse:LeftClick
    wait ${Config.Coords.MouseDelay}

    variable int anomaly_name_count
    variable int kbd_pause
    variable string current_char
    kbd_pause:Set[${Math.Calc[${Config.Coords.MouseDelay}\3]}]
    Keyboard:Release[Alt]
    wait ${kbd_pause}
    Keyboard:Release[Ctrl]
    wait ${kbd_pause}
    for (anomaly_name_count:Set[1] ; ${anomaly_name_count} <= ${Config.Coords.AnomalyName.Length} ; anomaly_name_count:Inc)
    {
     current_char:Set[${Config.Coords.AnomalyName.Mid[${anomaly_name_count},1]}]
     if ${current_char.Equal[""]}
      current_char:Set["Space"]
     Keyboard:Press[${current_char}]
     wait ${kbd_pause}
    }

    Keyboard:Press[Enter]
    X:Set[${Config.Coords.1stResultX}]
    Y:Set[${Config.Coords.1stResultY}]
    Ship:Reload_Weapons[TRUE]

    wait 30
    ScanMarkIndex:Clear
    EVE:GetBookmarks[ScanMarkIndex]

    s:Set[${ScanMarkIndex.Used}]

    while ${s} > 0
    {
     AnomalyName:Set[${Config.Coords.AnomalyName}]
     ScanMarkLabel:Set[${ScanMarkIndex.Get[${s}].Label}]

     if ${ScanMarkLabel.Right[${AnomalyName.Length}].Equal[${AnomalyName}]}
     {
      variable string old_scan_mark_label
      variable int new_label_length
      old_scan_mark_label:Set[${ScanMarkLabel}]
      new_label_length:Set[${Math.Calc[${ScanMarkLabel.Length}-${AnomalyName.Length}]}];
      ScanMarkLabel:Set[${old_scan_mark_label.Left[${new_label_length}]}]
      if !${Config.AllowedAnomalies.IsListed[${ScanMarkLabel}]}
      {
       ScanMarkIndex.Get[${s}]:Remove
       ScanMarkIndex:Remove[${s}]
      }
     }
     else
     {
      ScanMarkIndex:Remove[${s}]
     }

     s:Dec
    }
    ScanMarkIndex:Collapse
    ScanMarkIndex:GetIterator[ScanMarkIterator]
    UI:UpdateConsole["Obj_Ratter_F_Scanner1: Found ${ScanMarkIndex.Used} ${Config.Coords.AnomalyName} bookmarks "]

    if ${ScanMarkIndex.Used} >=1
    {
     if ${ScanMarkIterator:First(exists)}
     {
      do
      {
       X:Set[${Config.Coords.1stResultX}]
       Y:Set[${Config.Coords.1stResultY}]
       Mouse:SetPosition[${X},${Y}]
       wait ${Config.Coords.MouseDelay}
       Mouse:RightClick
       wait ${Config.Coords.MouseDelay}
       X:Set[${Math.Calc[${X}+${HX1}]}]
       Y:Set[${Math.Calc[${Y}+(4*${HY})-(${HY}/2)]}]
       Mouse:SetPosition[${X},${Y}]
       wait ${Config.Coords.MouseDelay}
       Mouse:LeftClick
       wait ${Config.Coords.MouseDelay}
       X:Set[${Config.Coords.1stResultX}]
       Y:Set[${Config.Coords.1stResultY}]

       if ${Social.IsSafe}
       {
        if ${This.Social.GankWereHere}
        {
         call Ship.WarpToBookMark ${ScanMarkIterator.Value.ID}, ${Config.Coords.WarpRange}

         wait 50

         ;if ${Config.Combat.MySingleLocal}
         ;{
          if !${Social.IsPlayerInMyRange}
          {
           UI:UpdateConsole["CHECK N1: Seeking another Player is making that plex"]
           wait 10
           if !${Social.IsPlayerInMyRange}
           {
            UI:UpdateConsole["CHECK N2: Seeking another Player is making that plex"]
            wait 10
            if !${Social.IsPlayerInMyRange}
            {
             UI:UpdateConsole["CHECK N3: No one makes that plex, IT IS MY PLEX!"]
            }
            else
            {
             UI:UpdateConsole["CHECK N3: Found another player, LEAVING PLEX!"]
             This.FirstInPlex:Set[FALSE]
             return
            }
           }
           else
           {
            UI:UpdateConsole["CHECK N2: Found another player, LEAVING PLEX!"]
            This.FirstInPlex:Set[FALSE]
            return
           }
          }
          else
          {
           UI:UpdateConsole["CHECK N1: Found another player, LEAVING PLEX!"]
           This.FirstInPlex:Set[FALSE]
           return
          }
         ;}
        }
        else
        {
         call Ship.WarpToBookMark ${ScanMarkIterator.Value.ID}, ${Config.Coords.WarpRange}

         wait 50

         ;if ${Config.Combat.MySingleLocal}
         ;{
          if !${Social.IsPlayerInMyRange}
                        {
           UI:UpdateConsole["CHECK N1: Seeking another Player is making that plex"]
           wait 10
           if !${Social.IsPlayerInMyRange}
           {
            UI:UpdateConsole["CHECK N2: Seeking another Player is making that plex"]
            wait 10
            if !${Social.IsPlayerInMyRange}
            {
             UI:UpdateConsole["CHECK N3: No one makes that plex, IT IS MY PLEX!"]
            }
            else
            {
             UI:UpdateConsole["CHECK N3: Found another player, LEAVING PLEX!"]
             This.FirstInPlex:Set[FALSE]
               return
            }
           }
           else
           {
            UI:UpdateConsole["CHECK N2: Found another player, LEAVING PLEX!"]
            This.FirstInPlex:Set[FALSE]
              return
           }
          }
          else
          {
           UI:UpdateConsole["CHECK N1: Found another player, LEAVING PLEX!"]
           This.FirstInPlex:Set[FALSE]
           return
          }
         ;}
        }
       }
       else
       {
        return
       }
       wait 20
       EVE:Execute[CmdStopShip]
       UI:UpdateConsole["We are in plex!"]
      }
      while ${ScanMarkIterator:Next(exists)}
      break
     }
    }
    else
    {
     X:Set[${Config.Coords.1stResultX}]
     Y:Set[${Config.Coords.1stResultY}]
     Mouse:SetPosition[${X},${Y}]
     wait ${Config.Coords.MouseDelay}
     Mouse:RightClick
     wait ${Config.Coords.MouseDelay}
     X:Set[${Math.Calc[${X}+${HX1}]}]
     Y:Set[${Math.Calc[${Y}+(4*${HY})-(${HY}/2)]}]
     Mouse:SetPosition[${X},${Y}]
     wait ${Config.Coords.MouseDelay}
     Mouse:LeftClick
     wait ${Config.Coords.MouseDelay}
     X:Set[${Config.Coords.1stResultX}]
     Y:Set[${Config.Coords.1stResultY}]
    }
   }
  }
 }
}


function AnomalyBookmark()
{
 ScanMarkIndex:Clear
 EVE:GetBookmarks[ScanMarkIndex]
 s:Set[${ScanMarkIndex.Used}]
 while ${s} > 0
 {
  AnomalyName:Set[${Config.Coords.AnomalyName}]
  ScanMarkLabel:Set[${ScanMarkIndex.Get[${s}].Label}]

  if ${ScanMarkLabel.Right[${AnomalyName.Length}].Equal[${AnomalyName}]}
  {
   variable string old_scan_mark_label
   variable int new_label_length
   old_scan_mark_label:Set[${ScanMarkLabel}]
   new_label_length:Set[${Math.Calc[${ScanMarkLabel.Length}-${AnomalyName.Length}]}];
   ScanMarkLabel:Set[${old_scan_mark_label.Left[${new_label_length}]}]
   if !${Config.AllowedAnomalies.IsListed[${ScanMarkLabel}]}
   {
    ScanMarkIndex.Get[${s}]:Remove
    ScanMarkIndex:Remove[${s}]
   }
  }
  else
  {
   ScanMarkIndex:Remove[${s}]
  }
  s:Dec
 }
 ScanMarkIndex:Collapse
 ScanMarkIndex:GetIterator[ScanMarkIterator]
 UI:UpdateConsole["Obj_Ratter_F_Scanner2: Found ${ScanMarkIndex.Used} ${Config.Coords.AnomalyName} bookmarks "]
 if ${ScanMarkIndex.Used} >=1
 {
  if ${ScanMarkIterator:First(exists)}
  {
   do
   {
    echo ZXZXZXZXX distance ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${ScanMarkIterator.Value.X}, ${ScanMarkIterator.Value.Y}, ${ScanMarkIterator.Value.Z}]}
    if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${ScanMarkIterator.Value.X}, ${ScanMarkIterator.Value.Y}, ${ScanMarkIterator.Value.Z}]} > 250000
    {
     if ${This.Social.GankWereHere}
     {
      call Ship.WarpToBookMark ${ScanMarkIterator.Value.ID}, ${Config.Coords.WarpRange}
      wait 50
      if !${Social.IsPlayerInMyRange}
      {
       UI:UpdateConsole["CHECK N1: Seeking another Player is making that plex"]
       wait 10
       if !${Social.IsPlayerInMyRange}
       {
        UI:UpdateConsole["CHECK N2: Seeking another Player is making that plex"]
        wait 10
        if !${Social.IsPlayerInMyRange}
        {
         UI:UpdateConsole["CHECK N3: No one makes that plex, IT IS MY PLEX!"]
        }
        else
        {
         UI:UpdateConsole["CHECK N3: Found another player, LEAVING PLEX!"]
         ScanMarkIterator.Value:Remove
         This.CurrentState:Set["MOVE"]
         return
        }
       }
       else
       {
        UI:UpdateConsole["CHECK N2: Found another player, LEAVING PLEX!"]
        ScanMarkIterator.Value:Remove
        This.CurrentState:Set["MOVE"]
          return
       }
      }
      else
      {
       UI:UpdateConsole["CHECK N1: Found another player, LEAVING PLEX!"]
       ScanMarkIterator.Value:Remove
       This.CurrentState:Set["MOVE"]
        return
      }
     }
     else
     {
      call Ship.WarpToBookMark ${ScanMarkIterator.Value.ID}, ${Config.Coords.WarpRange}
      wait 50
      if !${Social.IsPlayerInMyRange}
      {
       UI:UpdateConsole["CHECK N1: Seeking another Player is making that plex"]
       wait 10
       if !${Social.IsPlayerInMyRange}
       {
        UI:UpdateConsole["CHECK N2: Seeking another Player is making that plex"]
        wait 10
        if !${Social.IsPlayerInMyRange}
        {
         UI:UpdateConsole["CHECK N3: No one makes that plex, IT IS MY PLEX!"]
        }
        else
        {
         UI:UpdateConsole["CHECK N3: Found another player, LEAVING PLEX!"]
         ScanMarkIterator.Value:Remove
         This.CurrentState:Set["MOVE"]
         return
        }
       }
       else
       {
        UI:UpdateConsole["CHECK N2: Found another player, LEAVING PLEX!"]
        ScanMarkIterator.Value:Remove
        This.CurrentState:Set["MOVE"]
        return
       }
      }
      else
      {
       UI:UpdateConsole["CHECK N1: Found another player, LEAVING PLEX!"]
       ScanMarkIterator.Value:Remove
       This.CurrentState:Set["MOVE"]
       return
      }
     }
     wait 20
     EVE:Execute[CmdStopShip]
     This.CurrentState:Set["FIGHT"]
     return
    }
    else
    {
     ScanMarkIterator.Value:Remove
     This.CurrentState:Set["MOVE"]
     This.Social:ResetGankWereHere
     return
    }
   }
   while ${ScanMarkIterator:Next(exists)}
  }
 }
 else
 {
  This.CurrentState:Set["MOVE"]
  return
 }
}

;================================================================================================================================================================================
function CheckAmmo()
{
 variable int totalammo=0
 variable index:item CargoIndex
 variable iterator CargoIndexIterator

 MyChargesS:Set[${Me.Ship.Module[HiSlot0].Charge}]

 Me.Ship:GetCargo[CargoIndex,GroupID,84]
 CargoIndex:GetIterator[CargoIndexIterator]

 if ${CargoIndexIterator:First(exists)}
 {
  do
  {
   if ${CargoIndexIterator.Value.Name.Equal[${MyChargesS}]}
   {
   ;MyVolumeCharges:Set[${CargoIndexIterator.Value.Volume}]
   totalammo:Set[${Math.Calc[${totalammo}+${CargoIndexIterator.Value.Quantity}]}]
   }
  }
  while ${CargoIndexIterator:Next(exists)}
 }

 if ${totalammo} < ${Config.Coords.AmmoReloadValue}
 {
  UI:UpdateConsole["Low OF ${MyChargesS}. -=${totalammo}=-"]
  variable int idx
  call Safespots.WarpTo
  wait 10

  if ${Entity["TypeID = 17621"]} != NULL
  {
   if ${Entity["TypeID = 17621"].Distance} > 2000
   {
    do
    {
     Entity["TypeID = 17621"]:Approach
     wait 20
    }
    while ${Entity["TypeID = 17621"].Distance} > 2000
   }
  }
  else
  {
   MyErrMess:Set["WARNING: HANGAR NOT FOUND - WAR ENDED !"]
   This.CurrentState:Set["GAMEOVER", LOG_MINOR]
   UI:UpdateConsole["WARNING: AMMO NOT FOUND - WAR ENDED!", LOG_CRITICAL]
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
   wait 100
   EVE:Execute[CmdQuitGame]
  }

  EVE:Execute[CmdStopShip]
  call CloseInventory
  wait 10
  EVE:Execute[OpenInventory]
  wait 10
  EVEWindow[ByName,"Inventory"]:MakeChildActive[${Entity["TypeID = 17621"]}, Folder1]
  wait 10

  variable bool NoCharges
  variable float MyVolumeCharges
  variable int MyHangarItemCount
  variable int MyNeedCharges
  variable index:item MyHangarItem
  variable string MyChargesS
  variable string MyChargesSHungar


  Me.Ship:GetCargo[CargoIndex]
  wait 10


  MyChargesS:Set[${Me.Ship.Module[HiSlot0].Charge}]
  wait 10
  MyVolumeCharges:Set[${Me.Ship.Module[HiSlot0].Volume}]
  MyNeedCharges:Set[${Math.Calc[ ${Ship.CargoFreeSpace} / ${MyVolumeCharges} - 10]}]

  UI:UpdateConsole["MyNeedCharges -- ${MyNeedCharges}"]


  Entity["TypeID = 17621"]:GetCargo[MyHangarItem]
  MyHangarItemCount:Set[${MyHangarItem.Used}]

  UI:UpdateConsole["Serching ${MyChargesS} in ${Entity["TypeID=17621"].Name}"]
  NoCharges:Set[TRUE]
  idx:Set[1]
  do
  {
   UI:UpdateConsole["Seeking items. Now is ${MyHangarItem.Get[${idx}].Name}"]
   if ${MyHangarItem.Get[${idx}].CategoryID} == 8
   {
    UI:UpdateConsole["Seeking ammo. Now is ${MyHangarItem.Get[${idx}].Name}"]
    MyChargesSHungar:Set[${MyHangarItem.Get[${idx}].Name}]
    if ${MyChargesS.Equal[${MyChargesSHungar}]}
    {
     UI:UpdateConsole["Seeking exact ammo. Now is ${MyHangarItem.Get[${idx}].Name}"]
     variable int MyNeedChargesOld
     MyNeedChargesOld:Set[${MyNeedCharges}]
     if ${MyHangarItem.Get[${idx}].Quantity} > ${MyNeedCharges}
     {
      UI:UpdateConsole["FOUND: getting ${MyNeedCharges} in my cargo"]
      MyHangarItem.Get[${idx}]:MoveTo[${MyShip.ID},CargoHold,${MyNeedCharges}]
      wait 10
      idx:Set[${MyHangarItemCount}]
     }
     else
     {
      UI:UpdateConsole["FOUND: low charges - getting ${MyHangarItem.Get[${idx}].Quantity} in my cargo"]
      MyHangarItem.Get[${idx}]:MoveTo[${MyShip.ID},CargoHold,${MyHangarItem.Get[${idx}].Quantity}]
      wait 10
      MyNeedCharges:Set[ ${Math.Calc[${MyNeedChargesOld}-${MyHangarItem.Get[${idx}].Quantity} ]}]
     }
     NoCharges:Set[FALSE]
     wait 20
     if ${MyNeedCharges} == 0
     {
      idx:Set[${Math[${MyHangarItemCount}+1]}]
     }
    }
    wait 10
   }
  }
  while ${idx:Inc} <= ${MyHangarItemCount}

  if ${NoCharges}
  {
   MyErrMess:Set["WARNING: AMMO NOT FOUND - WAR ENDED!"]
   This.CurrentState:Set["GAMEOVER", LOG_MINOR]
   UI:UpdateConsole["last WARNING: AMMO NOT FOUND - WAR ENDED!", LOG_CRITICAL]
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
   wait 100
   EVE:Execute[CmdQuitGame]
  }
  else
  {
   wait 30
   EVEWindow[ByName,"Inventory"]:MakeChildActive[${MyShip.ID}, CargoHold]
   wait 10
   EVEWindow[ByItemID,${MyShip.ID}]:StackAll
   wait 10
   EVEWindow[ByItemID,${MyShip.ID}]:Close
   wait 10
  }
  call CloseInventory
  UI:UpdateConsole["end of check ammo"]
 }
}
;========================================================================================================================================================================
function CloseInventory()
{
 UI:UpdateConsole["CloseInventory()"]
 while ${EVEWindow[ByName,"Inventory"](exists)}
 {
  UI:UpdateConsole["closing inventory ${EVEWindow[ByName,"Inventory"].ItemID} c ${EVEWindow[ByName,"Inventory"].Caption} n ${EVEWindow[ByName,"Inventory"].Name}"]
  EVEWindow[ByName,"Inventory"]:Close
  wait 10
 }
 EVEWindow[ByItemID,${MyShip.ID}]:Close
 wait 10
}

;========================================================================================================================================================================
function OrbitCenterOfAnomaly(int OrbitDistance)
{
 if ${Time.Timestamp} > ${Math.Calc[${last_orbit_time}+60]}
 {
  if ${Entity["TypeID = 28356"].ID(exists)}
  {
   Entity["TypeID = 28356"]:Orbit[${OrbitDistance}]
   last_orbit_time:Set[${Time.Timestamp}];
   UI:UpdateConsole["DEBUG: Orbit anomaly at ${OrbitDistance}"]
  }
 }
}
;========================================================================================================================================================================
function ResetFleetMembers()
{
  FleetMembers:Clear
  Me.Fleet:GetMembers[FleetMembers]
  FleetMembers:GetIterator[FleetMember]
  if ${FleetMember:First(exists)}
  {
    do
    {
    if ${FleetMember.Value.ToPilot.Name.NotEqual[${Config.Coords.PilotToSupport}]}
    {
    echo wowowow
    FleetMembers:Remove[${FleetMember.Key}]
    }
    }
    while ${FleetMember:Next(exists)}
  }
  FleetMembers:Collapse
  echo ${FleetMembers.Used} - after collapse
}
;========================================================================================================================================================================
function WarpToPilot()
{

 ;if ${Config.Coords.AmmoReload}
 ;{
 ;call This.CheckAmmo
 ;}

 echo  function warptopilot used ${FleetMembers.Used} and ${FleetMembers.Used} <= 0
 echo ${Config.Coords.PilotToSupport} - pilot name
 if ${FleetMembers.Used} <= 0
 {
  Call This.ResetFleetMembers
 }
 if  ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${FleetMembers.Get[1].ToPilot.ToEntity.X}, ${FleetMembers.Get[1].ToPilot.ToEntity.Y}, ${FleetMembers.Get[1].ToPilot.ToEntity.Z}]} > WARP_RANGE
 {
 if ${Config.Coords.AmmoReload}
 {
  call This.CheckAmmo
 }
  echo WARPING!
 FleetMembers.Get[1]:WarpTo
 This.CurrentState:Set["FIGHT"]
 wait 100
 }
 else
 {
  echo else 2
  echo  ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${FleetMembers.Get[1].ToPilot.ToEntity.X}, ${FleetMembers.Get[1].ToPilot.ToEntity.Y}, ${FleetMembers.Get[1].ToPilot.ToEntity.Z}]}

  ;if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${FleetMembers.Get[1].ToPilot.ToEntity.X}, ${FleetMembers.Get[1].ToPilot.ToEntity.Y}, ${FleetMembers.Get[1].ToPilot.ToEntity.Z}]} < 70000
  ;{
   call This.OrbitCenterOfAnomaly ${Config.Coords.OrbitDistance}
  ;if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${FleetMembers.Get[1].ToPilot.ToEntity.X}, ${FleetMembers.Get[1].ToPilot.ToEntity.Y}, ${FleetMembers.Get[1].ToPilot.ToEntity.Z}]} > 5000
  ;{
  ; UI:UpdateConsole["Aproaching ${FleetMembers.Get[1].ToEntity.Name}"]
  ; FleetMembers.Get[1].ToEntity:Approach
  ;}

  ;UI:UpdateConsole["Approaching? - ${Me.ToPilot.Following.Name.Left[4].Equal[${Config.Coords.PilotToSupport}"]
  ;UI:UpdateConsole["Name1? - ${Config.Coords.PilotToSupport}"]
  ;UI:UpdateConsole["Name2? - ${Me.ToPilot.Name.Left[4]}"]
  ;UI:UpdateConsole["Name3? - ${Me.ToPilot.Approaching.Name.Left[4]}"]
  ;UI:UpdateConsole["Name4? - ${Me.ToPilot.Approaching.Name.Left[4].Equal["Mp C"]}"]

  ;if !${Me.ToPilot.Following.Name.Left[4].Equal["Mp C"]}
  ;{
  ; Echo Aproaching!!!!
  ; FleetMembers.Get[1].ToEntity:Approach
  ; Ship:Activate_AfterBurner[]
  ; This.CurrentState:Set["FIGHT"]
  ;}
  ;else
  ;{
  ; UI:UpdateConsole["Already aproaching ${FleetMembers.Get[1].ToEntity.Name}"]
  ; This.CurrentState:Set["FIGHT"]
  ;}
  ;}

  ;elseif ${Safespots.IsNearSafespot} && ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${FleetMembers.Get[1].ToPilot.ToEntity.X}, ${FleetMembers.Get[1].ToPilot.ToEntity.Y}, ${FleetMembers.Get[1].ToPilot.ToEntity.Z}]} > 70000
  ;{
  ; echo  ${Me.ToEntity.Approaching.Name.Left[4].Equal[${Config.Coords.PilotToSupport}]} - PILOT NAME
  ; if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${FleetMembers.Get[1].ToPilot.ToEntity.X}, ${FleetMembers.Get[1].ToPilot.ToEntity.Y}, ${FleetMembers.Get[1].ToPilot.ToEntity.Z}]} > 1000
  ; {
  ;  FleetMembers.Get[1].ToEntity:Approach
  ; }
  ;if !${Me.ToEntity.Following.Name.Left[4].Equal["Mp C"]}
  ;{
  ; Echo Aproaching!!!!
  ; FleetMembers.Get[1].ToEntity:Approach
  ; Ship:Activate_AfterBurner[]
  ; This.CurrentState:Set["FIGHT"]
  ;}
  ; else
  ; {
  ;  echo Curently approaching!
  ;  This.CurrentState:Set["FIGHT"]
  ; }
  ;}

  ;else
  ;{
  ; UI:UpdateConsole["REWARPING!"]
  ; call Safespots.WarpTo
  ; This.CurrentState:Set["MOVE"]
  ;}
 }
}
;========================================================================================================================================================================











;Wall Elevation ID - 2100059405 TypeID - 16758 Size is - Angel Elevator distance 30871.132813
;Munition Storage ID - 2100059429 TypeID - 12554 Size is - Munition Storage distance 30966.031250
;Wall ID - 2100059327 TypeID - 16764 Size is - Angel Fence distance 31028.732422


;angel haven lvl4 (stargate)
;Cosmic Anomaly ID - 2100025180 TypeID - 28356 Size is - Cosmic Anomaly distance 98311.937500

;Cosmic Anomaly ID - 2100333464 TypeID - 28356 Size is - Cosmic Anomaly distance 130240.671875





;end
}
