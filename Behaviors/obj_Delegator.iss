objectdef obj_Delegator
{
 variable string SVN_REVISION = "$Rev$"
 variable int Version
 variable string CurrentState = INSIDE
 variable int last_click_time = -1
 variable int current_click_interval = -1
 variable obj_Combat Combat

 method Initialize()
 {
  BotModules:Insert["Delegator"]
  UI:UpdateConsole["obj_Delegator: Initialized", LOG_MINOR]
 }

 method Shutdown()
 {
 }

 method SetState()
 {
 }

/*
480 575
650 603
*/
 function ProcessState()
 {
  if !${Config.Common.BotModeName.Equal[Delegator]}
   return
  if ${EVEBot.ReturnToStation}
  {
   call Combat.MyFlyToEnd
   return
  }
  if ${Social.IsSafe}
  {
   if ( \
    ${CurrentState.Equal[INSIDE]} || \
    ${Time.Timestamp} >= ${Math.Calc[${current_click_interval}+${last_click_time}]} \
   )
   {
    UI:UpdateConsole["time to orbit OUTSIDE!"]
    CurrentState:Set[OUTSIDE]
    Entity["GroupID = 365"]:Orbit[${Config.Combat.OutsideOrbit}]

    current_click_interval:Set[${Math.Rand[${Config.Combat.DelegatorClickIntervalRandom}]:Inc[${Config.Combat.DelegatorClickInterval}]}]
    last_click_time:Set[${Time.Timestamp}]
    UI:UpdateConsole["next click after ${current_click_interval} seconds."]
   }
   if ${Ship.Drones.DronesInSpace} <= 0 && ${Ship.Drones.DronesInBay} > 0
   {
    UI:UpdateConsole["launching ${Ship.Drones.DronesInBay} fighters."]
    Ship.Drones:SwitchCurrentDrones[FIGHTERS]
    Ship.Drones:LaunchAll
    wait 50
   }
   else
   {
    UI:UpdateConsole["fighters ${Ship.Drones.DronesInSpace} in space"]
   }
   if ${Ship.Drones.DronesInSpace} > 0
   {
    UI:UpdateConsole["delegating ${Ship.Drones.DronesInSpace} fighters"]
    variable index:fleetmember tgtIndex
    Me.Fleet:GetMembers[tgtIndex]
    variable iterator tgtIterator
    tgtIndex:GetIterator[tgtIterator]
    if ${tgtIterator:First(exists)}
    do
    {
     if ${tgtIterator.Value.ToPilot.CharID} != ${Me.CharID}
     {
      variable iterator DroneIterator
      variable index:activedrone ActiveDroneList
      variable index:int64 delegateIndex
      Me:GetActiveDrones[ActiveDroneList]
      ActiveDroneList:GetIterator[DroneIterator]
      delegateIndex:Clear
      if ${DroneIterator:First(exists)}
      do
      {
       if ${DroneIterator.Value.Owner.CharID} == ${DroneIterator.Value.Controller.CharID}
       {
        delegateIndex:Insert[${DroneIterator.Value.ID}]
        UI:UpdateConsole["delegating ${DroneIterator.Value.ID} to ${tgtIterator.Value.ToPilot.Name}"]
       }
      }
      while ${DroneIterator:Next(exists)}
      EVE:DelegateFighterControl[delegateIndex, ${tgtIterator.Value.ToPilot.CharID}]
      wait 50
     }
    }
    while ${tgtIterator:Next(exists)}
   }
  }
  else
  {
   if ( \
    ${CurrentState.Equal[OUTSIDE]} || \
    ${Time.Timestamp} >= ${Math.Calc[${current_click_interval}+${last_click_time}]} \
   )
   {
    UI:UpdateConsole["time to orbit INSIDE!"]
    CurrentState:Set[INSIDE]
    Entity["GroupID = 365"]:Orbit[${Config.Combat.InsideOrbit}]
    if ${Config.Combat.ScoopOnUnsafe}
     EVE:Execute[CmdDronesReturnToBay]
    current_click_interval:Set[${Math.Rand[${Config.Combat.DelegatorClickIntervalRandom}]:Inc[${Config.Combat.DelegatorClickInterval}]}]
    last_click_time:Set[${Time.Timestamp}]
    UI:UpdateConsole["next click after ${current_click_interval} seconds."]
   }
  }
 }
}
