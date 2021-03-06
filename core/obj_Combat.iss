/*
v. 5.1.6
*/

 #ifndef __OBJ_COMBAT__
 #define __OBJ_COMBAT__

objectdef obj_Combat
{
 variable string SVN_REVISION = "$Rev$"
 variable int Version

 variable time NextPulse
 variable int PulseIntervalInSeconds = 1

 variable bool Override
 variable string CombatMode
 variable string CurrentState
 variable bool Fled
 variable bool ResetTarget
 variable bool PlayWarnSound
 variable bool docking_in_progress = FALSE
 variable int last_orbit_time = 0
 variable int last_active_target = 0

 method Initialize()
 {
  This.CurrentState:Set["IDLE"]
  This.Fled:Set[FALSE]
  This.ResetTarget:Set[FALSE]
  This.PlayWarnSound:Set[FALSE]
  UI:UpdateConsole["obj_Combat: Initialized", LOG_MINOR]

;���������� ������ ��� �������� ������ ��� ��������� EVEBot.ReturnToStation:Set[TRUE]

 }

 method Shutdown()
 {
 }

 method Pulse()
 {
  if ${EVEBot.Paused}
  {
   return
  }

  if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
  {
   This:SetState

   This.NextPulse:Set[${Time.Timestamp}]
   This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
   This.NextPulse:Update

   if (!${Me.ToEntity.IsWarpScrambled} && !${Social.IsPlayerMeTarget} && !${Targets.PCWar} && !${This.docking_in_progress} && !${Station.Docked} && !${Station.InProgress})
   {
    if ${Config.Combat.GameOverShield}
    {
     if ${Me.Ship.ShieldPct} < ${Config.Combat.GameOverShieldTrashHold}
     {
      UI:UpdateConsole["Low Shield: ${Me.Ship.ShieldPct}. Quitting game.", LOG_CRITICAL]
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
      wait 1000
      exit
     }
    }

    if ${Config.Combat.GameOverArmor}
    {
     if ${Me.Ship.ArmorPct} < ${Config.Combat.GameOverArmorTrashHold}
     {
      UI:UpdateConsole["Low Armor: ${Me.Ship.ArmorPct}. Quitting game.", LOG_CRITICAL]
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
      wait 10
      exit
     }
    }
   }
  }
 }

 method SetState()
 {
  if ${Me.InStation} == TRUE
  {
   This.CurrentState:Set["INSTATION"]
   return
  }

  if ${EVEBot.ReturnToStation}
  {
   This.CurrentState:Set["GAMEEND"]
   return
  }

  if ${Me.TargetCount} > 0
  {
   This.CurrentState:Set["FIGHT"]
  }
  else
  {
   This.CurrentState:Set["IDLE"]
  }
 }

 method SetMode(string newMode)
 {
  This.CombatMode:Set[${newMode}]
 }

 member:string Mode()
 {
  return ${This.CombatMode}
 }

 member:bool Override()
 {
  return ${This.Override}
 }

 function ProcessState()
 {
  This.Override:Set[FALSE]

  if ${This.CurrentState.NotEqual["INSTATION"]}
  {
   if ${Me.ToEntity.IsWarpScrambled}
   {
    if !${Config.Combat.GameOverHostileScrambled}
    {
     UI:UpdateConsole["Warp Scrambled: Ignoring System Status"]
     This.CurrentState:Set["FIGHT"]
    }
    elseif !${Social.IsSafe}
    {
     UI:UpdateConsole["!!! warp scrambled while hostile !!! emergency logoff !!!"]
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
     wait 10
     exit
    }
   }
   elseif (!${Social.IsSafe} || ${Social.IsPlayerMeTarget})
   {
    This.CurrentState:Set["FLEE"]
    call This.Flee
    This.Override:Set[TRUE]
    return
   }
   call This.ManageTank
  }

  switch ${This.CurrentState}
  {
   case INSTATION
    if ${Social.IsSafe}
    {
     call Station.Undock
    }
    break
   case IDLE
    break
   case GAMEEND
    call This.MyFlyToEnd
    break
   case FLEE
    call This.Flee
    This.Override:Set[TRUE]
    break
   case FLEETANK
    call This.FleeTank
    This.Override:Set[TRUE]
    break
   case FIGHT
    call This.Fight
    break
  }
 }

 function Fight()
 {
  Ship:Deactivate_Cloak
  while ${Count:Inc} < 10 && ${Ship.IsCloaked}
  {
   wait 5
  }
  if ${Ship.IsCloaked}
  {
   UI:UpdateConsole["Error: Ship.IsCloaked still true after 5 seconds", LOG_CRITICAL]
  }
  ;Ship:Offline_Cloak
  ;Ship:Online_Salvager

  ; Reload the weapons -if- ammo is below 30% and they arent firing
  Ship:Reload_Weapons[FALSE]

  if ${Config.Combat.Navigate}
  {
   switch ${Config.Combat.NavigateEntity}
   {
    case anomaly
     if ${Entity["TypeID = 28356"].ID(exists)}
     {
      Ship:Navigate[${Entity["TypeID = 28356"]}, ${Config.Combat.NavigateAction}, ${Config.Combat.NavigateDistance}, ${Config.Combat.NavigateMWDAccuracy}, ${Config.Combat.NavigateMWD}]
     }
     else
     {
      UI:UpdateConsole["cannot navigate: anomaly beacon not found"]
     }
     break
    case target
     if ${Me.ActiveTarget.ID(exists)}
     {
      Ship:Navigate[${Me.ActiveTarget}, ${Config.Combat.NavigateAction}, ${Config.Combat.NavigateDistance}, ${Config.Combat.NavigateMWDAccuracy}, ${Config.Combat.NavigateMWD}]
     }
     else
     {
      UI:UpdateConsole["cannot navigate: active target not found"]
     }
     break
    default
     UI:UpdateConsole["cannot navigate: unknown navigate entity"]
     break
   }
  }

  ; Activate the weapons, the modules class checks if there's a target (no it doesn't - ct)
  Ship:Activate_StasisWebs
  Ship:Activate_TargetPainters
  if ${Config.Combat.FireRange} >= ${Me.ActiveTarget.Distance}
   Ship:Activate_Weapons
  else
   Ship:Deactivate_Weapons
  if ${Targets.HaveAllAggro} && ${Config.Combat.LaunchCombatDrones} && !${Ship.InWarp}
  {
   Ship.Drones:LaunchAll[]
  }
  else
  {
   wait 20
   if !${Targets.HaveAllAggro} && ${Config.Combat.LaunchCombatDrones} && !${Ship.InWarp}
   {
    if ${Ship.Drones.DronesInSpace} > 0
    {
     Call Ship.Drones.ReturnAllToDroneBay
     echo returning drones
     wait 20
    }
   }
  }
  wait 20
  Ship.Drones:SendDrones
 }

 function Flee()
 {
  This.Fled:Set[TRUE]
  This.PlayWarnSound:Set[FALSE]
  Ship:Deactivate_AfterBurner

  if ${Config.Combat.RunToStation}
  {
   call This.FleeToStation
  }
  else
  {
   call This.FleeToSafespot
   if ${Targets.SearchBoobleTarget}
   {
    UI:UpdateConsole["Waiting: found bubble!!! 0_0"]
   }
   call Safespots.ApproachSafeSpot
/*
   ;----------------------------------------------- ������  �������� ������ �� ����� ���� ���� � ������. +
   ;���� � ������� �������� ���� ������ ��� ��� �� ������� ��������.----------------------------
   variable int sswait
   for (sswait:Set[${Math.Rand[9]:Inc[18]}] ; ${sswait}>=1 ; sswait:Dec)
   {
    if !${Social.IsSafe}
    {
     sswait:Set[${Math.Rand[9]:Inc[18]}]
     wait 200
     if !${Safespots.IsAtSafespot}
     {
      call This.FleeToSafespot
     }
     call Safespots.ApproachSafeSpot
    }
    elseif ${Targets.SearchBoobleTarget}
    {
     UI:UpdateConsole["Waiting: found bubble!!! 0_0"]
     call Safespots.ApproachSafeSpot
    }
    else
    {
     wait 200
     UI:UpdateConsole["Obj_Combat:Local Is Clear! ${Math.Calc[(${sswait}*20)]} Sec.(${Math.Calc[(${sswait}*20)/60]}Min.)To Wait"]
     call Safespots.ApproachSafeSpot
    }
   }
   ;------------------------------------------------------------------------------------------
*/
  }
 }


 function FleeTank()
 {
  This.Fled:Set[TRUE]
  This.PlayWarnSound:Set[FALSE]
  if ${Config.Combat.RunToStation}
  {
   call This.FleeToStation
  }
  else
  {
   call This.FleeToSafespot
   ;----------------------------------------------- ������  �������� ������ �� ����� ���� �� ��������� ���� +
   ;���� � ������� �������� ���� ������ ��� ��� �� ������� ��������.----------------------------
    variable int sswait
    for (sswait:Set[3] ; ${sswait}>=1 ; sswait:Dec)
      {
       if !${Social.IsSafe}
       {
        This.CurrentState:Set["FLEE"]
       }
       else
       {
        if ${_Me.Ship.CapacitorPct} < 70 || ${_Me.Ship.ArmorPct} < 80 || ${_Me.Ship.ShieldPct} < 90
        {
         if ${_Me.Ship.ShieldPct} < 98 && ${_Me.Ship.CapacitorPct} > 25
         {
          Ship:Activate_Shield_Booster[]
         }
         elseif ${_Me.Ship.ShieldPct} > 99 || ${_Me.Ship.CapacitorPct} < 20
         {
          Ship:Deactivate_Shield_Booster[]
         }
         sswait:Set[3]
         wait 200
         if !${Safespots.IsAtSafespot}
         {
          call This.FleeToSafespot
         }
         call Safespots.ApproachSafeSpot
         UI:UpdateConsole["Obj_Combat_F_FleeTank_: Tank is NOT ready! WAITING!"]
        }
        else
        {
         wait 200
         UI:UpdateConsole["Obj_Combat_F_FleeTank_: Tank is ready! ${Math.Calc[(${sswait}*20)]} Sec.(${Math.Calc[(${sswait}*20)/60]}Min.)To Wait"]
         call Safespots.ApproachSafeSpot
        }
       }
      }
    ;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  }
 }
 function FleeToStation()
 {
  if !${Station.Docked}
  {
   call Station.Dock
  }
 }

 function FleeToSafespot()
 {
  if ${Safespots.IsAtSafespot}
  {
   if !${Ship.IsCloaked}
   {
    Ship:Activate_Cloak[]
   }
  }
  else
  {
   ; Are we at the safespot and not warping?
   if ${Me.ToEntity.Mode} != 3
   {
    call Safespots.WarpTo
    wait 20
   }
  }
 }

 method CheckTank()
 {
  if ${This.Fled}
  {
   if ( ${Me.Ship.CapacitorPct} < ${Config.Combat.MinimumCapPct} || ${Me.Ship.ArmorPct} < ${Config.Combat.MinimumArmorPct} || ${Me.Ship.ShieldPct} < ${Config.Combat.MinimumShieldPct} )
   {
    This.CurrentState:Set["FLEETANK"]
   }
   else
   {
    This.Fled:Set[FALSE]
    This.CurrentState:Set["IDLE"]
   }
  }
  elseif ( ${Me.Ship.ArmorPct}  < ${Config.Combat.MinimumArmorPct} || \
   ${Me.Ship.ShieldPct} < ${Config.Combat.MinimumShieldPct} )
  {
   UI:UpdateConsole["Armor is at ${Me.Ship.ArmorPct.Int}%: ${Me.Ship.Armor.Int}/${Me.Ship.MaxArmor.Int}", LOG_CRITICAL]
   UI:UpdateConsole["Shield is at ${Me.Ship.ShieldPct.Int}%: ${Me.Ship.Shield.Int}/${Me.Ship.MaxShield.Int}", LOG_CRITICAL]

   This.PlayWarnSound:Set[TRUE]

   if !${Config.Combat.RunOnLowTank}
   {
    UI:UpdateConsole["Run On Low Tank Disabled: Fighting", LOG_CRITICAL]
   }
   else
   {
    if !${Me.ToEntity.IsWarpScrambled}
    {
     UI:UpdateConsole["Fleeing due to defensive status", LOG_CRITICAL]
     This.CurrentState:Set["FLEETANK"]
    }
   }
  }
  elseif (${Me.Ship.CapacitorPct} < ${Config.Combat.MinimumCapPct})
  {
   UI:UpdateConsole["Cap is at ${Me.Ship.CapacitorPct.Int}%: ${Me.Ship.Capacitor.Int}/${Me.Ship.MaxCapacitor.Int}", LOG_CRITICAL]

   This.PlayWarnSound:Set[TRUE]

   if !${Config.Combat.RunOnLowCap}
   {
    UI:UpdateConsole["Run On Low Capacitor Disabled: Fighting", LOG_CRITICAL]
   }
   else
   {
    if !${Me.ToEntity.IsWarpScrambled}
    {
     UI:UpdateConsole["Fleeing due to cap status", LOG_CRITICAL]
     This.CurrentState:Set["FLEETANK"]
    }
   }
  }
 }

 function ManageTank()
 {
  if ${Me.Ship.ArmorPct} < 100 || ${Config.Combat.AlwaysArmorBoost}
  {
   /* Turn on armor reps, if you have them
    Armor reps do not rep right away -- they rep at the END of the cycle.
    To counter this we start the rep as soon as any damage occurs.
   */
   Ship:Activate_Armor_Reps[]
  }
  elseif ${Me.Ship.ArmorPct} > 98 && !${Config.Combat.AlwaysArmorBoost}
  {
   Ship:Deactivate_Armor_Reps[]
  }

  if ${Me.Ship.ShieldPct} < 85 || ${Config.Combat.AlwaysShieldBoost}
  {   /* Turn on the shield booster, if present */
   Ship:Activate_Shield_Booster[]
  }
  elseif ${Me.Ship.ShieldPct} > 95 && !${Config.Combat.AlwaysShieldBoost}
  {
   Ship:Deactivate_Shield_Booster[]
  }

  if ${Me.Ship.CapacitorPct} < 20
  {   /* Turn on the cap booster, if present */
   Ship:Activate_Cap_Booster[]
  }
  elseif ${Me.Ship.CapacitorPct} > 75
  {
   Ship:Deactivate_Cap_Booster[]
  }

  if ${Me.TargetedByCount} > 0
  {
   Ship:Activate_Hardeners[]

   if ${Config.Combat.LaunchCombatDrones}
   {
    if !${This.Fled} && ${Ship.Drones.DronesInSpace} == 0 && !${Ship.InWarp}
    {
     wait 70
     Ship.Drones:LaunchAll[]
    }
   }
   elseif ${Config.Combat.LaunchDronesSpec}
   {
    if ${Ship.Drones.DronesInSpace} > 0
    {
     if !${Targets.PriorityTargetPresent} && !${Targets.SpecialTargetPresent} && !${Me.ToEntity.IsWarpScrambled}
     {
      call Ship.Drones.ReturnAllToDroneBay
     }
    }
    else
    {
     if ${Targets.PriorityTargetPresent} || ${Targets.SpecialTargetPresent} || ${Me.ToEntity.IsWarpScrambled}
     {
      if !${Ship.InWarp}
      {
       UI:UpdateConsole["Launch Drone Priority Target Present", LOG_CRITICAL]
       wait 70
       Ship.Drones:LaunchAll[]
      }
     }
    }
   }
  }
  This:CheckTank
 }

 function MyFlyToEnd()
 {
  UI:UpdateConsole["MyFlyToEnd: Status CHANGED to ${This.CurrentState} - end game."]

  call Safespots.WarpToNextSafeSpot
  wait 10

; +++ storing vessel
  if (${Config.Coords.1stProbeX}>=0 && ${Config.Coords.1stProbeY}>=0)
  {
   UI:UpdateConsole["storring vessel is enabled, lets try"]
   if ${Entity["TypeID = 12237"]} != NULL
   {
    UI:UpdateConsole["ship maint array found"]
    Entity["TypeID = 12237"]:Approach
    wait 20
    while ${Entity["TypeID = 12237"].Distance} > 2900
    {
     UI:UpdateConsole["ship maint array: ${Entity["TypeID = 12237"].Distance} - approaching"]
     Entity["TypeID = 12237"]:Approach
     wait 50
    }
    UI:UpdateConsole["closing inventory windows"]
    while ${EVEWindow[ByCaption,"Inventory"](exists)}
    {
     UI:UpdateConsole["closing inventory ${EVEWindow[ByCaption,"Inventory"].ItemID} c ${EVEWindow[ByCaption,"Inventory"].Caption} n ${EVEWindow[ByCaption,"Inventory"].Name}"]
     EVEWindow[ByCaption,"Inventory"]:Close
     wait 10
    }
    variable int X=${Config.Coords.1stProbeX}
    variable int Y=${Config.Coords.1stProbeY}
    UI:UpdateConsole["opening main inventory window"]
    EVE:Execute[OpenInventory]
    wait ${Config.Coords.MouseDelay}
    Mouse:SetPosition[${X},${Y}]
    wait ${Config.Coords.MouseDelay}
    Mouse:LeftClick
    wait ${Config.Coords.MouseDelay}
    Mouse:RightClick
    wait ${Config.Coords.MouseDelay}
    X:Set[${Math.Calc[${X}+50]}]
    Y:Set[${Math.Calc[${Y}+195]}]
    Mouse:SetPosition[${X},${Y}]
    wait ${Config.Coords.MouseDelay}
    This.docking_in_progress:Set[TRUE]
    Mouse:LeftClick
    wait ${Config.Coords.MouseDelay}
    UI:UpdateConsole["ship stored, closing inventory windows"]
    wait 50
    while ${EVEWindow[ByCaption,"Inventory"](exists)}
    {
     UI:UpdateConsole["closing inventory ${EVEWindow[ByCaption,"Inventory"].ItemID} c ${EVEWindow[ByCaption,"Inventory"].Caption} n ${EVEWindow[ByCaption,"Inventory"].Name}"]
     EVEWindow[ByCaption,"Inventory"]:Close
     wait 10
    }
   }
   else
   {
    UI:UpdateConsole["ship maint array not found, cannot store vessel"]
    wait 10
   }
  }
  else
  {
   UI:UpdateConsole["storring vessel is not enabled, skipping"]
  }
  wait 50
  call Safespots.WarpTo
; --- storing vessel

  wait 30
  UI:UpdateConsole["Quitting in 30 sec."]
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
  wait 300
  exit
 }
}


#endif /* __OBJ_COMBAT__ */