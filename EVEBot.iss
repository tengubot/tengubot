#include core/defines.iss

/* Cache Objects */
#include core/obj_Cache.iss

/* Base Requirements */
#include core/obj_EVEBot.iss
#include core/obj_Configuration.iss

/* Support File Includes */
#include core/obj_Drones.iss
#include core/obj_Ship.iss
#include core/obj_Station.iss
#include core/obj_Cargo.iss
#include core/obj_EVEBotUI.iss
#include core/obj_Bookmarks.iss
#include core/obj_Jetcan.iss
#include core/obj_Social.iss
#include core/obj_Gang.iss
#include core/obj_Assets.iss
#include core/obj_Safespots.iss
#include core/obj_Ratterpoints.iss
#include core/obj_Belts.iss
#include core/obj_Targets.iss
#include core/obj_Sound.iss
#include core/obj_Combat.iss
#include core/obj_Items.iss
#include core/obj_Autopilot.iss

/* Behavior/Mode Includes */
#include Behaviors/obj_Ratter.iss
#include Behaviors/obj_Delegator.iss
;#include Behaviors/obj_Bomzh.iss
;#include Behaviors/obj_Anomaly.iss

/* Cache Objects */
variable(global) obj_Cache_Me _Me
variable(global) obj_Cache_EVETime _EVETime
variable(global) bool evebot_crashed=TRUE
;variable(global) bool evebot_crashed=FALSE     ; debug

function atexit()
{
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
 if ${evebot_crashed}
 {
  EVE:Execute[CmdQuitGame]
 }
; redirect profile.txt Script:DumpProfiling
}

function main()
{
 ;echo "${Time} EVEBot: Starting"
 ;Script:Unsquelch
 ;Script:EnableDebugLogging[debug.txt]
 ;Script:EnableProfiling
 ;Script[EVEBot]:EnableDebugLogging[debug.txt]
 ;Script[EVEBot]:EnableProfiling

 while !${_Me.Name(exists)} || ${_Me.Name.Equal[NULL]} || ${_Me.Name.Length} == 0
 {
  echo " ${Time} EVEBot: Waiting for cache to initialize - ${_Me.Name} != ${Me.Name}"
  wait 30
  _Me:Initialize
  _EVETime:Initialize
 }

 echo "${Time} EVEBot: Loading Objects..."

 /* Script-Defined Support Objects */
 declarevariable EVEBot obj_EVEBot script
 declarevariable UI obj_EVEBotUI script
 declarevariable BaseConfig obj_Configuration_BaseConfig script

 declarevariable Config obj_Configuration script
 declarevariable Whitelist obj_Config_Whitelist script
 declarevariable Blacklist obj_Config_Blacklist script
 declarevariable EVEDB_Stations obj_EVEDB_Stations script
 declarevariable EVEDB_StationID obj_EVEDB_StationID script
 declarevariable EVEDB_Spawns obj_EVEDB_Spawns script
 declarevariable EVEDB_Items obj_EVEDB_Items script

 /* Core Objects */
 declarevariable Ship obj_Ship script
 declarevariable Station obj_Station script
 declarevariable Cargo obj_Cargo script
 declarevariable Bookmarks obj_Bookmarks script
 declarevariable JetCan obj_JetCan script
 declarevariable CorpHangarArray obj_CorpHangerArray script
 declarevariable XLargeShipAssemblyArray obj_XLargeShipAssemblyArray script
 declarevariable Social obj_Social script
 declarevariable Fleet obj_Fleet script
 declarevariable Assets obj_Assets script
 declarevariable Safespots obj_Safespots script
 declarevariable Ratterpoints obj_Ratterpoints script
 declarevariable Belts obj_Belts script
 declarevariable Targets obj_Targets script
 declarevariable Sound obj_Sound script
 declarevariable Autopilot obj_Autopilot script

 /* Script-Defined Behavior Objects */
 declarevariable BotModules index:string script
 declarevariable Ratter obj_Ratter script
 declarevariable Delegator obj_Delegator script
 ;declarevariable Bomzh obj_Bomzh script

 ;echo "${Time} EVEBot: Loaded"

 /* Set Turbo to lowest value to try and avoid overloading the EVE Python engine */

 variable iterator BotModule
 BotModules:GetIterator[BotModule]

 variable iterator VariableIterator
 Script[EVEBot].VariableScope:GetIterator[VariableIterator]

 ;echo "Listing EVEBot Class Versions:"



 EVEBot:SetVersion[${VersionNum}]

 UI:Reload

; WindowText EVE - ${Me.Name}
 WindowText EVE

 run hideall

 UI:UpdateConsole["-=Paused: Press Run-="]
 Script:Pause

 while ${EVEBot.Paused}
 {
  wait 10
 }

 while TRUE
 {
  if ${BotModule:First(exists)}
  do
  {
   while ${EVEBot.Paused}
   {
    wait 10
   }
   call ${BotModule.Value}.ProcessState
   wait 10
  }
  while ${BotModule:Next(exists)}
  waitframe
 }
}
