/*
 Drone class

 Main object for interacting with the drones.  Instantiated by obj_Ship, only.

 -- CyberTech

*/

objectdef obj_Drones
{
 variable string SVN_REVISION = "$Rev$"
 variable int Version

 variable time NextPulse
 variable int PulseIntervalInSeconds = 2

 variable index:int64 ActiveDroneIDList
 variable int CategoryID_Drones = 18
 variable int LaunchedDrones = 0
 variable bool WaitingForDrones = FALSE
 variable bool DronesReady = FALSE
 variable int ShortageCount
 variable iterator ShipDroneIterator
 variable string CurrentDrones = FIGHTERS
 variable index:int64 UnsupportedDronesIndex
    variable index:int64 LightDronesIndex
    variable index:int64 MediumDronesIndex
  variable index:int64 HeavyDronesIndex
  variable index:int64 SentryDronesIndex
  variable index:int64 FighterDronesIndex
  variable iterator ShipDroneIterator
 variable index:item ShipDroneIndex
 ;variable string CurrentDrones = FIGHTERS

 method Initialize()
 {
  Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
  call This.ShipDroneList
  UI:UpdateConsole["obj_Drones: Initialized", LOG_MINOR]
 }
 method Shutdown()
 {
     UI:UpdateConsole["Recalling 1: !${Me.InStation}"]
     if !${Me.InStation}
     {

      UI:UpdateConsole["Recalling 2: (${Me.ToEntity.Mode} != 3)"]
         if (${Me.ToEntity.Mode} != 3)
         {
          UI:UpdateConsole["Recalling Drones prior to shutdown..."]
          EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
      }
  }
  Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
 }

 method Pulse()
 {
  if ${EVEBot.Paused}
  {
   return
  }

  if ${This.WaitingForDrones}
  {
      if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
   {
       if !${Me.InStation}
       {
        This.LaunchedDrones:Set[${This.DronesInSpace}]
        if  ${This.LaunchedDrones} > 0
        {
         This.WaitingForDrones:Set[FALSE]
         This.DronesReady:Set[TRUE]

         UI:UpdateConsole["${This.LaunchedDrones} drones deployed"]
        }
                }

       This.NextPulse:Set[${Time.Timestamp}]
       This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
       This.NextPulse:Update
   }
  }
 }

 method LaunchAll()
 {
  ;echo launching drones
  if ${This.DronesInBay} > 0
  {
   echo ${ActiveDroneIDList.Used}
   if ${This.DronesInSpace} < ${Me.MaxActiveDrones}
   {
     switch ${CurrentDrones}
     {
        case LIGHT
         EVE:LaunchDrones[LightDronesIndex]
         break
        case MEDIUM
         EVE:LaunchDrones[MediumDronesIndex]
         break
        case HEAVY
         EVE:LaunchDrones[HeavyDronesIndex]
         break
        case SENTRY
         EVE:LaunchDrones[SentryDronesIndex]
         break
        case FIGHTERS
         EVE:LaunchDrones[FighterDronesIndex]
         break
        default
        break
     }
     This.WaitingForDrones:Set[TRUE]
   }
  }
 }


 method SwitchCurrentDrones(string DronesToSwitch)
 {
  echo ${DronesToSwitch}
  if ${CurrentDrones.NotEqual[${DronesToSwitch}]}
  {

   call This.ReturnAllToDroneBay
   CurrentDrones:Set[${DronesToSwitch}]
   UI:UpdateConsole["obj_Drones:Current Drones Changed To "]
   This:LaunchAll
  }
 }




 member:int DronesInBay()
 {
  variable index:item DroneList
  MyShip:GetDrones[DroneList]
  return ${DroneList.Used}
 }

 member:int DronesInSpace()
 {
  Me:GetActiveDroneIDs[This.ActiveDroneIDList]
  return ${This.ActiveDroneIDList.Used}
 }

 member:bool CombatDroneShortage()
 {
  if !${This.DronesReady}
  {
   return
  }

  if (${Me.Ship.DronebayCapacity} > 0 && \
      ${This.DronesInBay} == 0 && \
      ${This.DronesInSpace} < ${Config.Combat.MinimumDronesInSpace})
     {
   ShortageCount:Inc
      if ${ShortageCount} > 10
      {
       return TRUE
      }
     }
     else
     {
      ShortageCount:Set[0]
     }
     return FALSE
 }

 ; Returns the number of Drones in our station hanger.
 member:int DronesInStation()
 {
  return ${Station.DronesInStation.Used}
 }

 function StationToBay()
 {
  variable int DroneQuantitiyToMove = ${Math.Calc[${Config.Common.DronesInBay} - ${This.DronesInBay}]}
  if ${This.DronesInStation} == 0 || \
   !${Me.Ship(exists)}
  {
   return
  }

  EVE:Execute[OpenDroneBayOfActiveShip]
  wait 15

  variable iterator CargoIterator
  Station.DronesInStation:GetIterator[CargoIterator]

  if ${CargoIterator:First(exists)}
  do
  {
   ;UI:UpdateConsole["obj_Drones:TransferToDroneBay: ${CargoIterator.Value.Name}"]
   CargoIterator.Value:MoveTo[DroneBay,1]
   wait 30
  }
  while ${CargoIterator:Next(exists)}
  wait 10
  EVEWindow[MyDroneBay]:Close
  wait 10
 }

 function ReturnAllToDroneBay()
 {
  while ${This.DronesInSpace} > 0
  {
   UI:UpdateConsole["Recalling ${This.ActiveDroneIDList.Used} Drones"]
   EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
   EVE:Execute[CmdDronesReturnToBay]
   if (${Me.Ship.ArmorPct} < ${Config.Combat.MinimumArmorPct} || \
   ${Me.Ship.ShieldPct} < ${Config.Combat.MinimumShieldPct}) || \
   !${Social.IsSafe}
   {
    ; We don't wait for drones if we're on emergency warp out
    wait 10
    return
   }
   wait 50
  }
 }
 method ActivateMiningDrones()
 {
  if !${This.DronesReady}
  {
   return
  }

  if (${This.DronesInSpace} > 0)
  {
   EVE:DronesMineRepeatedly[This.ActiveDroneIDList]
  }
 }
;========= важно активация дронов
 method SendDrones()
 {
  if !${This.DronesReady}
  {
   return
  }

  if (${This.DronesInSpace} > 0)
  {
   variable iterator DroneIterator
   variable index:activedrone ActiveDroneList
   Me:GetActiveDrones[ActiveDroneList]
   ActiveDroneList:GetIterator[DroneIterator]
   echo activedrones  is  - ${ActiveDroneList.Used}
   UI:UpdateConsole["ActiveDroneList: ${ActiveDroneList.Used}"]
   variable index:int64 returnIndex
   variable index:int64 engageIndex

   do
   {

    ;= проверка файтеров если дамажат и шилд меньше 70% заберает в дрон бей
    if ${DroneIterator.Value.ToEntity.ShieldPct} < 60
    {
     UI:UpdateConsole["Recalling Damaged Drone ${DroneIterator.Value.ID}"]
     UI:UpdateConsole["Debug: Shield: ${DroneIterator.Value.ToEntity.ShieldPct}, Armor: ${DroneIterator.Value.ToEntity.ArmorPct}, Structure: ${DroneIterator.Value.ToEntity.StructurePct}"]
     returnIndex:Insert[${DroneIterator.Value.ID}]
    }
    else
    {
     ;UI:UpdateConsole["Debug: Engage Target ${DroneIterator.Value.ID}"]
     ; !${Me.ActiveTarget.Left[${MeActiveTarget.Length}].Equal[DroneIterator.Value.Target]}

     ;if ${Me.ActiveTarget(exists)} && ${Me.ActiveTarget.StructurePct} >= 50 && ${Me.ActiveTarget.ID}!=${DroneIterator.Value.Target.ID}
     ;{
     ; engageIndex:Insert[${DroneIterator.Value.ID}]
     ;}

     if ${Me.ActiveTarget(exists)} && ${Me.ActiveTarget.ID}!=${DroneIterator.Value.Target.ID}
     {
      engageIndex:Insert[${DroneIterator.Value.ID}]
     }
    }
   }
   while ${DroneIterator:Next(exists)}
   EVE:DronesReturnToDroneBay[returnIndex]
   if ${Me.ActiveTarget(exists)} && ${Me.ActiveTarget.StructurePct} >= 50
   {
    EVE:DronesEngageMyTarget[engageIndex]
   }
   else
   {
    if  ${Me.ActiveTarget.ShieldPct} >= 20
    {
    EVE:DronesEngageMyTarget[engageIndex]
    }
   }
  }
 }
;==================================================================


function ShipDroneList()
{
 Me.Ship:GetDrones[ShipDroneIndex]
 ShipDroneIndex:GetIterator[ShipDroneIterator]
 do
 {
 echo NAME - ${ShipDroneIterator.Value.Name} TYPEID - ${ShipDroneIterator.Value.TypeID}  GROUPID - ${ShipDroneIterator.Value.GroupID}  CATEGORY - ${ShipDroneIterator.Value.Category} CATEGORYID - ${ShipDroneIterator.Value.Description}

  switch ${ShipDroneIterator.Value.Description}
  {
   case Light Scout Drone
    LightDronesIndex:Insert[${ShipDroneIterator.Value.ID}]
    continue
   case Medium Scout Drone
    MediumDronesIndex:Insert[${ShipDroneIterator.Value.ID}]
    continue
   case Heavy Attack Drone
    HeavyDronesIndex:Insert[${ShipDroneIterator.Value.ID}]
    continue
   case Sentry Drone
    SentryDronesIndex:Insert[${ShipDroneIterator.Value.ID}]
    continue
   case Caldari Fighter Craft
   case Minmatar Fighter Craft
   case Gallente Fighter Craft
   case Amarr Fighter Craft
    FighterDronesIndex:Insert[${ShipDroneIterator.Value.ID}]
    continue

   default
   UnsupportedDronesIndex:Insert[${ShipDroneIterator.Value.ID}]
   continue
  }
 }
 while ${ShipDroneIterator:Next(exists)}

 echo LIGHTDRONES - ${LightDronesIndex.Used} MEDUIMDRONES - ${MediumDronesIndex.Used}  HEAVYDRONES - ${HeavyDronesIndex.Used}  SENTRY  - ${SentryDronesIndex.Used}  FIGHTERS - ${FighterDronesIndex.Used} Unsupported - ${UnsupportedDronesIndex.Used}
}




;==================================================================







}