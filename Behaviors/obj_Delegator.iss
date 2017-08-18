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
    if ${Ship.Drones.DronesInSpace} <= 0 && ${Ship.Drones.DronesInBay} > 0
    {
     UI:UpdateConsole["launching fighters."]
     Ship.Drones:SwitchCurrentDrones[FIGHTERS]
     Ship.Drones:LaunchAll
     wait 20
    }
    else
    {
     UI:UpdateConsole["fighters ${Ship.Drones.DronesInSpace} in space"]
    }
    if ${Ship.Drones.DronesInSpace} > 0
    {
     UI:UpdateConsole["delegating fighters"]
     variable int i=-1
     while ${i:Inc} < ${Config.Combat.FleetQty}
     {
      Mouse:SetPosition[${Config.Coords.RecoverX},${Config.Coords.RecoverY}]
      wait ${Config.Coords.MouseDelay}
      Mouse:RightClick
      wait ${Config.Coords.MouseDelay}
      Mouse:SetPosition[${Math.Calc[${Config.Coords.RecoverX}+160]}, ${Math.Calc[${Config.Coords.RecoverY}+28]}]
      wait ${Config.Coords.MouseDelay}
      Mouse:SetPosition[${Math.Calc[${Config.Coords.RecoverX}+220]}, ${Math.Calc[${Config.Coords.RecoverY}+28+18*${i}]}]
      wait ${Config.Coords.MouseDelay}
      Mouse:LeftClick
      wait ${Config.Coords.MouseDelay*3}
     }
    }
    current_click_interval:Set[${Math.Rand[${Config.Combat.DelegatorClickIntervalRandom}]:Inc[${Config.Combat.DelegatorClickInterval}]}]
    last_click_time:Set[${Time.Timestamp}]
    UI:UpdateConsole["next click after ${current_click_interval} seconds."]
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
