/*
        Ratter Class Behaviors v.5.1.7
*/

objectdef obj_Ratter
{
 variable string SVN_REVISION = "$Rev$"
 variable int Version

 variable string CurrentState
 variable string CombatState
 variable string MyErrMess
 variable time NextPulse
 variable int PulseIntervalInSeconds = 2
 variable obj_Combat Combat

 method Initialize()
 {
  Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
  BotModules:Insert["Ratter"]
  This.CurrentState:Set["FIGHT"]
  Targets:ResetTargets
  This.Combat:Initialize
  This.Combat:SetMode["AGGRESSIVE"]
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
  This.Combat:Pulse
 }

 method Shutdown()
 {
  Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
 }

 method SetState()
 {
  switch ${This.CurrentState}
  {
   case IDLE
    if ${EVEBot.ReturnToStation}
    {
     This.CurrentState:Set["GAMEEND"]
    }
    else
    {
     This.CurrentState:Set["NEXT_MYBOOK"]
    }
    break
   default
    break
  }
 }

 function ProcessState()
 {
  if !${Config.Common.BotModeName.Equal[Ratter]}
   return

  call This.Combat.ProcessState

  if ${This.Combat.Override}
  {
   This.CurrentState:Set["SAFE"]
   UI:UpdateConsole["Status changed to ${This.CurrentState}."]
   return
  }

  switch ${This.CurrentState}
  {
   case FIGHT
    call This.Fight
    break
   case SAFE
    call This.CheckMySafe
    break
   case NEXT_MYBOOK
    call This.Next_MyBooks
    break
   case GAMEOVER
    call This.MyQuitGames
    break
   case GAMEEND
    call This.MyFlyToEnd
    break
  }
 }

 function Next_MyBooks()
 {
  UI:UpdateConsole["Wapring next point"]
  if ${Me.Ship.Name.Right[10].Equal["'s Capsule"]} || \
   ${Me.ToEntity.GroupID} == GROUP_CAPSULE
  {
   MyErrMess:Set["WARNING: LOST SHIP - WAR ENDED !"]
   This.CurrentState:Set["GAMEOVER"]
   return
  }

  Ship:Deactivate_AfterBurner
  if ${Social.IsSafe}
  {
   call This.CheckAmmo
   call This.MyFly
   if ${Targets.RatterTargetPresent}
   {
    This.CurrentState:Set["NEXT_MYBOOK"]
    UI:UpdateConsole["WARNING!!!! Found Scrambled targets warp to NextBook", LOG_CRITICAL]
    return
   }
   else
   {
    if ${Targets.myPC}
    {
     This.CurrentState:Set["NEXT_MYBOOK"]
     UI:UpdateConsole["Found other Hanter warp to NextBook", LOG_CRITICAL]
     return
    }
    if ${Targets.IsRatterTargetPresent}
    {
     BeltFromBook:Set[${Ratterpoints.RatterPointIterator.Value.Label}]
     BeltFromBook:Set[${BeltFromBook.Mid[6,${Math.Calc[${BeltFromBook.Length}-6]}]}]
     UI:UpdateConsole["Warp to ${BeltFromBook}"]
     Entity[${BeltFromBook}]:WarpTo[0]
     wait 100
     do
     {
      wait 10
     }
     while (${Me.ToEntity.Mode} == 3)
    }
    else
    {
     This.CurrentState:Set["NEXT_MYBOOK"]
     UI:UpdateConsole["No targets prezent warp to NextBook", LOG_CRITICAL]
     return
    }
   }
   Me.Ship:StackAllCargo
   Targets:ResetTargets
   This.CurrentState:Set["FIGHT"]
  }
 }

 function Fight()
 {
  if ${Targets.TargetNPCs}
  {
   if ${Targets.SpecialTargetPresent}
   {
    UI:UpdateConsole["Special spawn Detected!", LOG_CRITICAL]
    call Sound.PlayDetectSound
    wait 50
   }
  }
  else
  {
   if !${Me.ToEntity.IsWarpScrambled}
   {
    This.CurrentState:Set["IDLE"]
   }
  }
 }



;   ==================
;     Main function
;   ==================


;-------------------------------------------------------------------------------

 function MyFly()
 {
  if ${Config.Labels.RatterUseMyBook}
  {
   call Ratterpoints.WarpToNextRatterPoint
  }
  else
  {
   call Belts.WarpToNextBelt
  }
 }

;-------------------------------------------------------------------------------

 function CheckMySafe()
 {
  call Safespots.ApproachSafeSpot

  if ${Targets.SearchBoobleTarget}
  {
   This.CurrentState:Set["FIGHT"]
   return
  }

  variable int MyWaitTimeSec
  switch ${Config.Combat.WaitSecSafe}
  {
   case 1
    MyWaitTimeSec:Set[120]
    break
   case 2
    MyWaitTimeSec:Set[240]
    break
   case 3
    MyWaitTimeSec:Set[360]
    break
   case 4
    MyWaitTimeSec:Set[480]
    break
   default
    MyWaitTimeSec:Set[120]
    break
  }

  variable bool WaitRats
  variable int idx
  variable int tmpidx
  variable int tmpleft

  tmpleft:Set[${MyWaitTimeSec}]
  if ${Social.IsRatsEnable}
  {
   UI:UpdateConsole["Safe: Rats Enable - activate long wait interval"]
   variable int TTT
   TTT:Set[${Math.Calc[180+${Math.Rand[60]}]}]
   MyWaitTimeSec:Set[${Math.Calc[${tmpleft}+${Math.Rand[${TTT}]:Inc[${TTT}]}]}]

  }

  if ${Social.IsBlackUser}
  {
   MyWaitTimeSec:Set[${Math.Calc[${tmpleft}*2]}]
   UI:UpdateConsole["BlackList: Activate long time waiting (Time wait * 2) ..."]
  }

  do
  {
   UI:UpdateConsole["Safe is bad, waiting ..."]
   do
   {
    if ${Me.ToEntity.IsWarpScrambled}
    {
     UI:UpdateConsole["Safe: Change status SAFE->FIGHT (WAR PC)"]
    }
    wait 10
   }
   while !${Social.IsSafe}

   WaitRats:Set[FALSE]
   tmpidx:Set[0]
   tmpleft:Set[${MyWaitTimeSec}]

   UI:UpdateConsole["Safe: waiting ${MyWaitTimeSec} sec..."]
   for ( idx:Set[0]; ${idx} < ${MyWaitTimeSec}; idx:Inc )
   {
    wait 10
    tmpidx:Inc
    if ${tmpidx} == 60
    {
     tmpleft:Set[${Math.Calc[${tmpleft}-60]}]
     UI:UpdateConsole["Safe: left ${tmpleft} sec ..."]
     tmpidx:Set[0]
    }
    if !${Social.IsSafe}
    {
     WaitRats:Set[TRUE]
    }
    if ${Me.ToEntity.IsWarpScrambled}
    {
     UI:UpdateConsole["Safe: Change status SAFE->FIGHT (WAR PC)"]
     This.CurrentState:Set["FIGHT"]
     return
    }
   }
   if ${Targets.SearchBoobleTarget}
   {
    UI:UpdateConsole["Safe: waiting : found bubble...."]
    WaitRats:Set[TRUE]
   }
  }
  while ${WaitRats}

  UI:UpdateConsole["Safe(${Social.IsSafe}) , return prevision books ...", LOG_MINOR]

  call This.CheckAmmo
  wait 10
  call This.MyFly
  wait 20
  This.CurrentState:Set["FIGHT"]
 }

;-------------------------------------------------------------------------------

 function CheckAmmo()
 {
  variable int MyWWW
  variable index:item CargoIndex

  Me.Ship:StackAllCargo
  Me.Ship:GetCargo[CargoIndex]

  if ${Config.Combat.MyOrbitRange} > 2
  {
   MyWWW:Set[5]
  }
  else
  {
   MyWWW:Set[1500]
  }


  if ${CargoIndex.Get[1].Quantity} > ${MyWWW}
  {
   UI:UpdateConsole["Count ammo (${CargoIndex.Get[1].Quantity})"]
  }
  else
  {
   UI:UpdateConsole["Low count ammo (${CargoIndex.Get[1].Quantity}), to refill", LOG_MINOR]

   variable string MyHangar = "Corporate Hangar Array"
   variable int idx

   call Safespots.WarpTo
   wait 10

   if (!${Entity[${MyHangar}](exists)})
   {
    MyErrMess:Set["WARNING: HANGAR NOT FOUNT - WAR ENDED !"]
    This.CurrentState:Set["GAMEOVER"]
    return
   }

   if (${Entity[${MyHangar}].Distance} > 2000)
   {
    Entity[${MyHangar}]:Approach
    do
    {
     wait 5
    }
    while ${Entity[${MyHangar}].Distance} > 2000
   }
   EVE:Execute[CmdStopShip]
   Entity[${MyHangar}]:OpenCargo
   wait 10

   ;-------------------------------------------------------

   variable int NotCharges
   variable float MyVolumeCharges
   variable int MyHangarItemCount
   variable int MyNeedCharges
   variable index:item MyHangarItem
   variable string MyChargesS
   variable string MyChargesSHungar


   Me.Ship:StackAllCargo
   wait 20
   Me.Ship:GetCargo[CargoIndex]
   wait 10
   MyChargesS:Set[${CargoIndex.Get[1].Name}]
   wait 10
   MyVolumeCharges:Set[${Math.Calc[ ${Me.Ship.UsedCargoCapacity}/${CargoIndex.Get[1].Quantity}]}]
   MyNeedCharges:Set[${Math.Calc[ ${Ship.CargoFreeSpace} / ${MyVolumeCharges} - 1 ]}]
   MyHangarItemCount:Set[${Entity[${MyHangar}].GetCargo[MyHangarItem]}]

   if ${Config.Combat.MyOrbitRange} > 2
   {
    if ${MyNeedCharges} > 50
    {
     MyNeedCharges:Set[50]
    }
   }

   UI:UpdateConsole["Serching ${MyChargesS} in ${MyHangar}"]
   NotCharges:Set[0]
   idx:Set[1]
   do
   {
    if ${MyHangarItem.Get[${idx}].CategoryID} == 8
    {
     MyChargesSHungar:Set[${MyHangarItem.Get[${idx}].Name}]
     if ${MyChargesS.Equal[${MyChargesSHungar}]}
     {
      variable int MyNeedChargesOld
      MyNeedChargesOld:Set[${MyNeedCharges}]
      if ${MyHangarItem.Get[${idx}].Quantity} > ${MyNeedCharges}
      {
       UI:UpdateConsole["FOUND: getting ${MyNeedCharges} in my cargo"]
       MyHangarItem.Get[${idx}]:MoveTo[MyShip,${MyNeedCharges}]
       wait 10
       idx:Set[${MyHangarItemCount}]
      }
      else
      {
       UI:UpdateConsole["FOUND: low charges - getting ${MyHangarItem.Get[${idx}].Quantity} in my cargo"]
       MyHangarItem.Get[${idx}]:MoveTo[MyShip,${MyHangarItem.Get[${idx}].Quantity}]
       wait 10
       MyNeedCharges:Set[ ${Math.Calc[${MyNeedChargesOld}-${MyHangarItem.Get[${idx}].Quantity} ]}]
      }
      NotCharges:Set[1]
      wait 5
      Me.Ship:StackAllCargo
      if ${MyNeedCharges} == 0
      {
       idx:Set[${Math[${MyHangarItemCount}+1]}]
      }
     }
     wait 10
    }
   }
   while ${idx:Inc} <= ${MyHangarItemCount}

   if ${NotCharges} == 0
   {
    MyErrMess:Set["WARNING: AMMO NOT FOUNT - WAR ENDED !"]
    This.CurrentState:Set["GAMEOVER", LOG_MINOR]
    call This.MyQuitGames
   }
    else
   {
    wait 10
    Me.Ship:StackAllCargo
    wait 10
    Entity[${MyHangar}]:CloseCargo
    wait 10
   }
  }
 }

;-------------------------------------------------------------------------------

 function MyFlyToEnd()
 {
  UI:UpdateConsole["Time: Status changed to ${This.CurrentState} - end game."]

  call Safespots.WarpTo
  wait 10
  call This.CheckAmmo
  wait 300
  exit
 }

;-------------------------------------------------------------------------------

 function MyQuitGames()
 {
  variable int WTT = 10

  call Safespots.WarpTo
  wait 10

  do
  {
   UI:UpdateConsole[${MyErrMess}]
   wait 10
   UI:UpdateConsole["WARNING: Client exit through ${WTT} min !", LOG_CRITICAL]
   wait 580
   WTT:Dec
  }
  while ${WTT} > 0
  exit
 }

; -----------------------------------------  END OBJECT --------------------------------------------------
}
