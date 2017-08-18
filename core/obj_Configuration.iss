/*
 Configuration Classes

 Main object for interacting with the config file, and for wrapping access to the config items.

 -- CyberTech

 Description:
 obj_Configuration defines the config file and the root.  It contains an instantiation of obj_Configuration_MODE,
 where MODE is Hauler,Miner, Combat, etc.

 Each obj_Configuration_MODE is responsible for setting it's own default values and for providing access members
 and update methods for the config items. ALL configuration items should receive both a member and a method.

 Instructions:
  To add a new module, add a variable to obj_Configuration, name it with the thought that it will be accessed
  as Config.Module (ie, Config.Miner).  Create the class, and it's members and methods, following the example
  of the existing classes below.
*/

/* ************************************************************************* */
objectdef obj_Configuration_BaseConfig
{
 variable string SVN_REVISION = "$Rev$"
 variable int Version

 variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/Config"
 variable string ORG_CONFIG_FILE = "evebot.xml"
 variable string NEW_CONFIG_FILE = "${Me.Name} Config.xml"
 variable string CONFIG_FILE = "${Me.Name} Config.xml"
 variable settingsetref BaseRef

 method Initialize()
 {
  LavishSettings[EVEBotSettings]:Clear
  LavishSettings:AddSet[EVEBotSettings]
  LavishSettings[EVEBotSettings]:AddSet[${Me.Name}]

  ; Check new config file first, then fallball to original name for import

  CONFIG_FILE:Set["${CONFIG_PATH}/${NEW_CONFIG_FILE}"]

  if !${CONFIG_PATH.FileExists[${NEW_CONFIG_FILE}]}
  {
   UI:UpdateConsole["${CONFIG_FILE} not found - looking for ${ORG_CONFIG_FILE}"]
   UI:UpdateConsole["Configuration will be copied from ${ORG_CONFIG_FILE} to ${NEW_CONFIG_FILE}"]

   LavishSettings[EVEBotSettings]:Import[${CONFIG_PATH}/${ORG_CONFIG_FILE}]
  }
  else
  {
   UI:UpdateConsole["Configuration file is ${CONFIG_FILE}"]
   LavishSettings[EVEBotSettings]:Import[${CONFIG_FILE}]
  }

  BaseRef:Set[${LavishSettings[EVEBotSettings].FindSet[${Me.Name}]}]
  UI:UpdateConsole["obj_Configuration_BaseConfig: Initialized", LOG_MINOR]
 }

 method Shutdown()
 {
  This:Save[]
  LavishSettings[EVEBotSettings]:Clear
 }

 method Save()
 {
  LavishSettings[EVEBotSettings]:Export[${CONFIG_FILE}]
 }
}

/* ************************************************************************* */
objectdef obj_Configuration
{
 variable obj_Configuration_Common Common
 variable obj_Configuration_Combat Combat
 variable obj_Configuration_Salvager Salvager
 variable obj_Configuration_Labels Labels
 variable obj_Configuration_Coords Coords
 variable obj_Configuration_AllowedAnomalies AllowedAnomalies

 method Save()
 {
  BaseConfig:Save[]
 }
}

/* ************************************************************************* */
objectdef obj_Configuration_Common
{
 variable string SetName = "Common"
 variable int AboutCount = 0

 method Initialize()
 {
  if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
  {
   UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
   This:Set_Default_Values[]
  }
  UI:UpdateConsole["obj_Configuration_Common: Initialized", LOG_MINOR]
 }

 member:settingsetref CommonRef()
 {
  return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
 }

 method Set_Default_Values()
 {
  BaseConfig.BaseRef:AddSet[${This.SetName}]

  ; We use both so we have an ID to use to set the default selection in the UI.
  This.CommonRef:AddSetting[Bot Mode,1]
  This.CommonRef:AddSetting[Bot Mode Name,RATTER]
  This.CommonRef:AddSetting[Home Station,1]
  This.CommonRef:AddSetting[Use Development Build,FALSE]
  This.CommonRef:AddSetting[Drones In Bay,0]
  This.CommonRef:AddSetting[Login Name, ""]
  This.CommonRef:AddSetting[Login Password, ""]
  This.CommonRef:AddSetting[AutoLogin, FALSE]
  This.CommonRef:AddSetting[AutoLoginCharID, 0]
  This.CommonRef:AddSetting[Maximum Runtime, 0]
  This.CommonRef:AddSetting[Use Sound, FALSE]
  This.CommonRef:AddSetting[Disable 3D, FALSE]
  This.CommonRef:AddSetting[TrainFastest, FALSE]
 }

 member:int BotMode()
 {
  return ${This.CommonRef.FindSetting[Bot Mode, 1]}
 }

 method SetBotMode(int value)
 {
  This.CommonRef:AddSetting[Bot Mode, ${value}]
 }

 member:string BotModeName()
 {
  return ${This.CommonRef.FindSetting[Bot Mode Name, MINER]}
 }

 method SetBotModeName(string value)
 {
  This.CommonRef:AddSetting[Bot Mode Name,${value}]
 }

 member:int DronesInBay()
 {
  return ${This.CommonRef.FindSetting[Drones In Bay, NOTSET]}
 }

 method SetDronesInBay(int value)
 {
  This.CommonRef:AddSetting[Drones In Bay,${value}]
 }

 member:string HomeStation()
 {
  return ${This.CommonRef.FindSetting[Home Station, NOTSET]}
 }

 method SetHomeStation(string value)
 {
  This.CommonRef:AddSetting[Home Station,${value}]
 }

 member:bool UseDevelopmentBuild()
 {
  return ${This.CommonRef.FindSetting[Use Development Build, FALSE]}
 }

 method SetUseDevelopmentBuild(bool value)
 {
  This.CommonRef:AddSetting[Home Station,${value}]
 }

 /* TODO - Encrypt this as much as lavishcript will allow */
 member:string LoginName()
 {
  return ${This.CommonRef.FindSetting[Login Name, ""]}
 }

 method SetLoginName(string value)
 {
  This.CommonRef:AddSetting[Login Name, ${value}]
 }

 member:string LoginPassword()
 {
  return ${This.CommonRef.FindSetting[Login Password, ""]}
 }

 method SetLoginPassword(string value)
 {
  This.CommonRef:AddSetting[Login Password,${value}]
 }

 member:bool AutoLogin()
 {
  return ${This.CommonRef.FindSetting[AutoLogin, FALSE]}
 }

 method SetAutoLogin(bool value)
 {
  This.CommonRef:AddSetting[AutoLogin,${value}]
 }

 member:int64 AutoLoginCharID()
 {
  return ${This.CommonRef.FindSetting[AutoLoginCharID, 0]}
 }

 method SetAutoLoginCharID(int64 value)
 {
  This.CommonRef:AddSetting[AutoLoginCharID,${value}]
 }

 member:int OurAbortCount()
 {
  return ${AbortCount}
 }

 function IncAbortCount()
 {
  This.AbortCount:Inc
 }

 member:int MaxRuntime()
 {
  return ${This.CommonRef.FindSetting[Maximum Runtime, NOTSET]}
 }

 method SetMaxRuntime(int value)
 {
  This.CommonRef:AddSetting[Maximum Runtime,${value}]
 }

 member:bool UseSound()
 {
  return ${This.CommonRef.FindSetting[Use Sound, FALSE]}
 }

 method SetUseSound(bool value)
 {
  This.CommonRef:AddSetting[Use Sound,${value}]
 }

 member:bool Disable3D()
 {
  return ${This.CommonRef.FindSetting[Disable 3D, FALSE]}
 }

 method SetDisable3D(bool value)
 {
  This.CommonRef:AddSetting[Disable 3D,${value}]
 }

 member:bool TrainFastest()
 {
  return ${This.CommonRef.FindSetting[TrainFastest, FALSE]}
 }

 method SetTrainFastest(bool value)
 {
  This.CommonRef:AddSetting[TrainFastest,${value}]
 }
}

/* ************************************************************************* */
objectdef obj_Configuration_Combat
{
 variable string SetName = "Combat"

 method Initialize()
 {
  if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
  {
   UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
   This:Set_Default_Values[]
  }
  UI:UpdateConsole["obj_Configuration_Combat: Initialized", LOG_MINOR]
 }

 member:settingsetref CombatRef()
 {
  return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
 }

 method Set_Default_Values()
 {
  BaseConfig.BaseRef:AddSet[${This.SetName}]

  This.CombatRef:AddSetting[MinimumDronesInSpace,3]
  This.CombatRef:AddSetting[MinimumArmorPct, 99]
  This.CombatRef:AddSetting[MinimumShieldPct, 55]
  This.CombatRef:AddSetting[MinimumCapPct, 11]
  This.CombatRef:AddSetting[AlwaysShieldBoost, FALSE]
  This.CombatRef:AddSetting[AlwaysArmorBoost, FALSE]
  This.CombatRef:AddSetting[Launch Combat Drones, FALSE]
  This.CombatRef:AddSetting[Run On Low Cap, FALSE]
  This.CombatRef:AddSetting[Run On Low Tank, FALSE]
  This.CombatRef:AddSetting[Run To Station, FALSE]
  This.CombatRef:AddSetting[Use Whitelist, FALSE]
  This.CombatRef:AddSetting[Use Blacklist, FALSE]
  This.CombatRef:AddSetting[Chain Spawns, TRUE]
  This.CombatRef:AddSetting[Chain Solo, TRUE]
  This.CombatRef:AddSetting[Min Chain Bounty, 1500000]

  This.CombatRef:AddSetting[LaunchDronesSpec, FALSE]
  This.CombatRef:AddSetting[MyWarRegion, 1]
  This.CombatRef:AddSetting[WaitSecSafe, 1]
  This.CombatRef:AddSetting[MySingleLocal, FALSE]
  This.CombatRef:AddSetting[FullDeactivateOrbit, FALSE]
  This.CombatRef:AddSetting[DeactivateMWD, FALSE]
  This.CombatRef:AddSetting[MyOrbitRange, 1]
  This.CombatRef:AddSetting[GameOverShield, TRUE]
  This.CombatRef:AddSetting[GameOverShieldTrashHold, 11]
  This.CombatRef:AddSetting[GameOverArmor, TRUE]
  This.CombatRef:AddSetting[GameOverArmorTrashHold, 99]
  This.CombatRef:AddSetting[GameOverBlackList, FALSE]
 }

 member:bool RunOnLowAmmo()
 {
  return ${This.CombatRef.FindSetting[Run On Low Ammo, FALSE]}
 }

 method SetRunOnLowAmmo(bool value)
 {
  This.CombatRef:AddSetting[Run On Low Ammo, ${value}]
 }

 member:bool RunOnLowCap()
 {
  return ${This.CombatRef.FindSetting[Run On Low Cap, FALSE]}
 }

 method SetRunOnLowCap(bool value)
 {
  This.CombatRef:AddSetting[Run On Low Cap, ${value}]
 }

 member:bool RunOnLowTank()
 {
  return ${This.CombatRef.FindSetting[Run On Low Tank, TRUE]}
 }

 method SetRunOnLowTank(bool value)
 {
  This.CombatRef:AddSetting[Run On Low Tank, ${value}]
 }

 member:bool RunToStation()
 {
  return ${This.CombatRef.FindSetting[Run To Station, FALSE]}
 }

 method SetRunToStation(bool value)
 {
  This.CombatRef:AddSetting[Run To Station, ${value}]
 }

 member:bool UseWhiteList()
 {
  return ${This.CombatRef.FindSetting[Use Whitelist, FALSE]}
 }

 method SetUseWhiteList(bool value)
 {
  This.CombatRef:AddSetting[Use Whitelist, ${value}]
 }

 member:bool UseBlackList()
 {
  return ${This.CombatRef.FindSetting[Use Blacklist, FALSE]}
 }

 method SetUseBlackList(bool value)
 {
  This.CombatRef:AddSetting[Use Blacklist, ${value}]
 }

 member:bool UseStandings()
 {
  return ${This.CombatRef.FindSetting[Use Standings, TRUE]}
 }

 method SetUseStandings(bool value)
 {
  This.CombatRef:AddSetting[Use Standings, ${value}]
 }

 member:bool TakeBreaks()
 {
  return ${This.CombatRef.FindSetting[Take Breaks, TRUE]}
 }

 method SetTakeBreaks(bool value)
 {
  This.CombatRef:AddSetting[Take Breaks, ${value}]
 }

 member:bool UseSafeCooldown()
 {
  return ${This.CombatRef.FindSetting[Use Safe Cooldown, TRUE]}
 }

 method SetUseSafeCooldown(bool value)
 {
  This.CombatRef:AddSetting[Use Safe Cooldown, ${value}]
 }

 member:bool ChainSpawns()
 {
  return ${This.CombatRef.FindSetting[Chain Spawns, TRUE]}
 }

 method SetChainSpawns(bool value)
 {
  This.CombatRef:AddSetting[Chain Spawns, ${value}]
 }

 member:bool ChainSolo()
 {
  return ${This.CombatRef.FindSetting[Chain Solo, TRUE]}
 }

 method SetChainSolo(bool value)
 {
  This.CombatRef:AddSetting[Chain Solo, ${value}]
 }

 member:bool MySingleLocal()
 {
  return ${This.CombatRef.FindSetting[MySingleLocal, FALSE]}
 }

 method SetMySingleLocal(bool value)
 {
  This.CombatRef:AddSetting[MySingleLocal, ${value}]
 }

 member:int MinChainBounty()
 {
  return ${This.CombatRef.FindSetting[Min Chain Bounty, 1500000]}
 }

 method SetMinChainBounty(int value)
 {
  This.CombatRef:AddSetting[Min Chain Bounty,${value}]
 }

 member:int MinStanding()
 {
  return ${This.CombatRef.FindSetting[Min Standing, 1]}
 }

 method SetMinStanding(int value)
 {
  This.CombatRef:AddSetting[Min Standing,${value}]
 }

 member:int SafeCooldown()
 {
  return ${This.CombatRef.FindSetting[SafeCooldown, 10]}
 }

 method SetSafeCooldown(int value)
 {
  This.CombatRef:AddSetting[SafeCooldown, ${value}]
 }

 member:int SafeCooldownRandom()
 {
  return ${This.CombatRef.FindSetting[SafeCooldownRandom, 5]}
 }

 method SetSafeCooldownRandom(int value)
 {
  This.CombatRef:AddSetting[SafeCooldownRandom, ${value}]
 }

 member:int BreakDuration()
 {
  return ${This.CombatRef.FindSetting[Break Duration, 2]}
 }

 method SetBreakDuration(int value)
 {
  This.CombatRef:AddSetting[Break Duration, ${value}]
 }

 member:int TimeBetweenBreaks()
 {
  return ${This.CombatRef.FindSetting[Time Between Breaks, 5]}
 }

 method SetTimeBetweenBreaks(int value)
 {
  This.CombatRef:AddSetting[Time Between Breaks, ${value}]
 }

 member:bool LaunchDronesSpec()
 {
  return ${This.CombatRef.FindSetting[LaunchDronesSpec, FALSE]}
 }

 method SetLaunchDronesSpec(bool value)
 {
  This.CombatRef:AddSetting[LaunchDronesSpec, ${value}]
 }

 member:int MyWarRegion()
 {
  return ${This.CombatRef.FindSetting[MyWarRegion, 1]}
 }

 method SetMyWarRegion(int value)
 {
  This.CombatRef:AddSetting[MyWarRegion,${value}]
 }
 member:int WaitSecSafe()
 {
  return ${This.CombatRef.FindSetting[WaitSecSafe, 1]}
 }

 method SetWaitSecSafe(int value)
 {
  This.CombatRef:AddSetting[WaitSecSafe,${value}]
 }

 member:bool LaunchCombatDrones()
 {
  return ${This.CombatRef.FindSetting[Launch Combat Drones, FALSE]}
 }

 method SetLaunchCombatDrones(bool value)
 {
  This.CombatRef:AddSetting[Launch Combat Drones, ${value}]
 }

 member:int MinimumDronesInSpace()
 {
  return ${This.CombatRef.FindSetting[MinimumDronesInSpace, 3]}
 }

 method SetMinimumDronesInSpace(int value)
 {
  This.CombatRef:AddSetting[MinimumDronesInSpace,${value}]
 }

 member:int MinimumArmorPct()
 {
  return ${This.CombatRef.FindSetting[MinimumArmorPct, 99]}
 }

 method SetMinimumArmorPct(int value)
 {
  This.CombatRef:AddSetting[MinimumArmorPct, ${value}]
 }

 member:int MinimumShieldPct()
 {
  return ${This.CombatRef.FindSetting[MinimumShieldPct, 55]}
 }

 method SetMinimumShieldPct(int value)
 {
  This.CombatRef:AddSetting[MinimumShieldPct, ${value}]
 }

 member:int MinimumCapPct()
 {
  return ${This.CombatRef.FindSetting[MinimumCapPct, 11]}
 }

 method SetMinimumCapPct(int value)
 {
  This.CombatRef:AddSetting[MinimumCapPct, ${value}]
 }

 member:bool AlwaysShieldBoost()
 {
  return ${This.CombatRef.FindSetting[AlwaysShieldBoost, FALSE]}
 }

 method SetAlwaysShieldBoost(bool value)
 {
  This.CombatRef:AddSetting[AlwaysShieldBoost, ${value}]
 }

 member:bool AlwaysArmorBoost()
 {
  return ${This.CombatRef.FindSetting[AlwaysArmorBoost, FALSE]}
 }

 method SetAlwaysArmorBoost(bool value)
 {
  This.CombatRef:AddSetting[AlwaysArmorBoost, ${value}]
 }

 member:bool DeactivateMWD()
 {
  return ${This.CombatRef.FindSetting[DeactivateMWD, FALSE]}
 }
 method SetDeactivateMWD(bool value)
 {
  This.CombatRef:AddSetting[DeactivateMWD, ${value}]
 }

 member:bool FullDeactivateOrbit()
 {
  return ${This.CombatRef.FindSetting[FullDeactivateOrbit, FALSE]}
 }

 method SetFullDeactivateOrbit(bool value)
 {
  This.CombatRef:AddSetting[FullDeactivateOrbit, ${value}]
 }

 member:int MyOrbitRange()
 {
  return ${This.CombatRef.FindSetting[MyOrbitRange, 2]}
 }
 method SetMyOrbitRange(int value)
 {
  This.CombatRef:AddSetting[MyOrbitRange,${value}]
 }

 member:bool GameOverBlackList()
 {
  return ${This.CombatRef.FindSetting[GameOverBlackList, FALSE]}
 }

 method SetGameOverBlackList(bool value)
 {
  This.CombatRef:AddSetting[GameOverBlackList, ${value}]
 }

 member:bool LootFaction()
 {
  return ${This.CombatRef.FindSetting[LootFaction, TRUE]}
 }

 method SetLootFaction(bool value)
 {
  This.CombatRef:AddSetting[LootFaction, ${value}]
 }

 member:bool GameOverGrid()
 {
  return ${This.CombatRef.FindSetting[GameOverGrid, TRUE]}
 }

 method SetGameOverGrid(bool value)
 {
  This.CombatRef:AddSetting[GameOverGrid, ${value}]
 }

 member:bool GameOverHostileScrambled()
 {
  return ${This.CombatRef.FindSetting[GameOverHostileScrambled, TRUE]}
 }

 method SetGameOverHostileScrambled(bool value)
 {
  This.CombatRef:AddSetting[GameOverHostileScrambled, ${value}]
 }

 member:bool GameOverShield()
 {
  return ${This.CombatRef.FindSetting[GameOverShield, TRUE]}
 }

 method SetGameOverShield(bool value)
 {
  This.CombatRef:AddSetting[GameOverShield, ${value}]
 }

 member:int GameOverShieldTrashHold()
 {
  return ${This.CombatRef.FindSetting[GameOverShieldTrashHold, 11]}
 }

 method SetGameOverShieldTrashHold(int value)
 {
  This.CombatRef:AddSetting[GameOverShieldTrashHold, ${value}]
 }

 member:bool GameOverArmor()
 {
  return ${This.CombatRef.FindSetting[GameOverArmor, TRUE]}
 }

 method SetGameOverArmor(bool value)
 {
  This.CombatRef:AddSetting[GameOverArmor, ${value}]
 }

 member:int GameOverArmorTrashHold()
 {
  return ${This.CombatRef.FindSetting[GameOverArmorTrashHold, 99]}
 }

 method SetGameOverArmorTrashHold(int value)
 {
  This.CombatRef:AddSetting[GameOverArmorTrashHold, ${value}]
 }

}

/* ************************************************************************* */
objectdef obj_Configuration_Salvager
{
 variable string SetName = "Salvager"

 method Initialize()
 {
  return
  if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
  {
   UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
   This:Set_Default_Values[]
  }
  UI:UpdateConsole["obj_Configuration_Salvager: Initialized", LOG_MINOR]
 }

 member:settingsetref SalvagerRef()
 {
  return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
 }

 method Set_Default_Values()
 {
  BaseConfig.BaseRef:AddSet[${This.SetName}]

 }

}


/* ************************************************************************* */
objectdef obj_Configuration_Labels
{
 variable string SetName = "Labels"

 method Initialize()
 {
  if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
  {
   UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
   This:Set_Default_Values[]
  }
  UI:UpdateConsole["obj_Configuration_Labels: Initialized", LOG_MINOR]
 }

 member:settingsetref LabelsRef()
 {
  return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
 }

 method Set_Default_Values()
 {
  BaseConfig.BaseRef:AddSet[${This.SetName}]
  This.LabelsRef:AddSetting[Safe Spot Prefix,"SPOT"]
  This.LabelsRef:AddSetting[RatterPointsPrefix, "empty"]
  This.LabelsRef:AddSetting[RatterUseMyBook, FALSE]
  This.LabelsRef:AddSetting[Loot Prefix,"empty"]
  This.LabelsRef:AddSetting[WreckSalvage, FALSE]
  This.LabelsRef:AddSetting[LootSizeWreck, 1]
  This.LabelsRef:AddSetting[SalvageSizeWreck, 1]
 }

 member:string SafeSpotPrefix()
 {
  return ${This.LabelsRef.FindSetting[Safe Spot Prefix,"SPOT"]}
 }

 method SetSafeSpotPrefix(string value)
 {
  This.LabelsRef:AddSetting[Safe Spot Prefix,${value}]
 }

 member:string AmmoSpot()
 {
  return ${This.LabelsRef.FindSetting[Ammo Spot,"AMMO"]}
 }

 method SetAmmoSpot(string value)
 {
  This.LabelsRef:AddSetting[Ammo Spot,${value}]
 }

 member:string RatterPointsPrefix()
 {
  return ${This.LabelsRef.FindSetting[RatterPoints Prefix,"empty"]}
 }
 method SetRatterPointsPrefix(string value)
 {
  This.LabelsRef:AddSetting[RatterPoints Prefix,${value}]
 }

 member:bool RatterUseMyBook()
 {
  return ${This.LabelsRef.FindSetting[RatterUseMyBook, FALSE]}
 }
 method SetRatterUseMyBook(bool value)
 {
  This.LabelsRef:AddSetting[RatterUseMyBook, ${value}]
 }

 member:settingsetref LabelsRef()
 {
  return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
 }

 method Set_Default_Values()
 {
  BaseConfig.BaseRef:AddSet[${This.SetName}]
 }

 member:string LootPrefix()
 {
  return ${This.LabelsRef.FindSetting[Loot Prefix,"empty"]}
 }
 method SetLootPrefix(string value)
 {
  This.LabelsRef:AddSetting[Loot Prefix,${value}]
 }

 member:int LootSizeWreck()
 {
  return ${This.LabelsRef.FindSetting[LootSizeWreck, 1]}
 }
 method SetLootSizeWreck(int value)
 {
  This.LabelsRef:AddSetting[LootSizeWreck,${value}]
 }

 member:int SalvageSizeWreck()
 {
  return ${This.LabelsRef.FindSetting[SalvageSizeWreck, 1]}
 }
 method SetSalvageSizeWreck(int value)
 {
  This.LabelsRef:AddSetting[SalvageSizeWreck,${value}]
 }

 member:bool WreckSalvage()
 {
  return ${This.LabelsRef.FindSetting[WreckSalvage, FALSE]}
 }
 method SetWreckSalvage(bool value)
 {
  This.LabelsRef:AddSetting[WreckSalvage, ${value}]
 }

}
/* ************************************************************************* */
objectdef obj_Configuration_Coords
{
 variable string SetName = "Coords"

 method Initialize()
 {
  if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
  {
   UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
   This:Set_Default_Values[]
  }
  UI:UpdateConsole["obj_Configuration_Coords: Initialized", LOG_MINOR]
 }

 member:settingsetref CoordsRef()
 {
  return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
 }

 method Set_Default_Values()
 {
  BaseConfig.BaseRef:AddSet[${This.SetName}]
  This.CoordsRef:AddSetting[ScanX, 56]
  This.CoordsRef:AddSetting[ScanY, 56"]
  This.CoordsRef:AddSetting[RecoverX, 104]
  This.CoordsRef:AddSetting[RecoverY, 56]
  This.CoordsRef:AddSetting[ReConX, 136]
  This.CoordsRef:AddSetting[ReConY, 56]
  This.CoordsRef:AddSetting[1stProbeX, -1]
  This.CoordsRef:AddSetting[1stProbeY, -1]
  This.CoordsRef:AddSetting[1stResultX, 64]
  This.CoordsRef:AddSetting[1stResultY, 274]
  This.CoordsRef:AddSetting[MouseDelay, 15]
  This.CoordsRef:AddSetting[AnalyzeTime, 300]
  This.CoordsRef:AddSetting[ProbeLauncher, F8]
  This.CoordsRef:AddSetting[AnomalyName, "Type Name Here"]
  This.CoordsRef:AddSetting[WarpRange, 50000"]
  This.CoordsRef:AddSetting[OrbitAnomaly, FALSE]
  This.CoordsRef:AddSetting[OrbitDistance, 0"]
  This.CoordsRef:AddSetting[AmmoReload, TRUE]
  This.CoordsRef:AddSetting[AmmoReloadValue, 1000"]
  This.CoordsRef:AddSetting[Support, FALSE]
  This.CoordsRef:AddSetting[PilotToSupport,"TypeNameHere"]
  This.CoordsRef:AddSetting[Sanctum1, FALSE]
  This.CoordsRef:AddSetting[Sanctum2, FALSE]
  This.CoordsRef:AddSetting[WaitBeforeScan, 0"]
  This.CoordsRef:AddSetting[SmartBombRange, 5000"]
 }


 member:int ScanX()
 {
  return ${This.CoordsRef.FindSetting[ScanX, 56]}
 }

 method SetScanX(int ScanX)
 {
  This.CoordsRef:AddSetting[ScanX, ${ScanX}]
 }
 member:int ScanY()
 {
  return ${This.CoordsRef.FindSetting[ScanY, 56]}
 }
 method SetScanY(int ScanY)
 {
  This.CoordsRef:AddSetting[ScanY, ${ScanY}]
 }
 member:int RecoverX()
 {
  return ${This.CoordsRef.FindSetting[RecoverX, 104]}
 }

 method SetRecoverX(int RecoverX)
 {
  This.CoordsRef:AddSetting[RecoverX, ${RecoverX}]
 }
 member:int RecoverY()
 {
  return ${This.CoordsRef.FindSetting[RecoverY, 56]}
 }

 method SetRecoverY(int RecoverY)
 {
  This.CoordsRef:AddSetting[RecoverY, ${RecoverY}]
 }
 member:int ReConX()
 {
  return ${This.CoordsRef.FindSetting[ReConX, 136]}
 }

 method SetReConX(int ReConX)
 {
  This.CoordsRef:AddSetting[ReConX, ${ReConX}]
 }
 member:int ReConY()
 {
  return ${This.CoordsRef.FindSetting[ReConY, 56]}
 }

 method SetReConY(int ReConY)
 {
  This.CoordsRef:AddSetting[ReConY, ${ReConY}]
 }
 member:int 1stProbeX()
 {
  return ${This.CoordsRef.FindSetting[1stProbeX, -1]}
 }

 method Set1stProbeX(int 1stProbeX)
 {
  This.CoordsRef:AddSetting[1stProbeX, ${1stProbeX}]
 }
 member:int 1stProbeY()
 {
  return ${This.CoordsRef.FindSetting[1stProbeY, -1]}
 }

 method Set1stProbeY(int 1stProbeY)
 {
  This.CoordsRef:AddSetting[1stProbeY, ${1stProbeY}]
 }
 member:int 1stResultX()
 {
  return ${This.CoordsRef.FindSetting[1stResultX, 64]}
 }

 method Set1stResultX(int 1stResultX)
 {
  This.CoordsRef:AddSetting[1stResultX, ${1stResultX}]
 }
 member:int 1stResultY()
 {
  return ${This.CoordsRef.FindSetting[1stResultY, 274]}
 }

 method Set1stResultY(int 1stResultY)
 {
  This.CoordsRef:AddSetting[1stResultY, ${1stResultY}]
 }
 member:string ProbeLauncher()
 {
  return ${This.CoordsRef.FindSetting[ProbeLauncher, F8]}
 }

 method SetProbeLauncher(string ProbeLauncher)
 {
  This.CoordsRef:AddSetting[ProbeLauncher, ${ProbeLauncher}]
 }



 member:int MouseDelay()
 {
  return ${This.CoordsRef.FindSetting[MouseDelay, 0]}
 }

 method SetMouseDelay(int MouseDelay)
 {
  This.CoordsRef:AddSetting[MouseDelay, ${MouseDelay}]
 }

 member:int AnalyzeTime()
 {
  return ${This.CoordsRef.FindSetting[AnalyzeTime, 0]}
 }

 method SetAnalyzeTime(int AnalyzeTime)
 {
  This.CoordsRef:AddSetting[AnalyzeTime, ${AnalyzeTime}]
 }

 member:string AnomalyName()
 {
  return ${This.CoordsRef.FindSetting[AnomalyName, "Type Name Here"]}
 }

 method SetAnomalyName(string AnomalyName)
 {
  This.CoordsRef:AddSetting[AnomalyName, ${AnomalyName}]
 }


 member:int WarpRange()
 {
  return ${This.CoordsRef.FindSetting[WarpRange, 0]}
 }

 method SetWarpRange(int WarpRange)
 {
  This.CoordsRef:AddSetting[WarpRange, ${WarpRange}]
 }

 member:bool OrbitAnomaly()
 {
  return ${This.CoordsRef.FindSetting[OrbitAnomaly, FALSE]}
 }

 method SetOrbitAnomaly(bool value)
 {
  This.CoordsRef:AddSetting[OrbitAnomaly, ${value}]
 }
 member:int OrbitDistance()
 {
  return ${This.CoordsRef.FindSetting[OrbitDistance, 0]}
 }

 method SetOrbitDistance(int OrbitDistance)
 {
  This.CoordsRef:AddSetting[OrbitDistance, ${OrbitDistance}]
 }
 member:bool AmmoReload()
 {
  return ${This.CoordsRef.FindSetting[AmmoReload, TRUE]}
 }

 method SetAmmoReload(bool value)
 {
  This.CoordsRef:AddSetting[AmmoReload, ${value}]
 }
 member:int AmmoReloadValue()
 {
  return ${This.CoordsRef.FindSetting[AmmoReloadValue, 0]}
 }

 method SetAmmoReloadValue(int AmmoReloadValue)
 {
  This.CoordsRef:AddSetting[AmmoReloadValue, ${AmmoReloadValue}]
 }
 member:bool Support()
 {
  return ${This.CoordsRef.FindSetting[Support, FALSE]}
 }

 method SetSupport(bool value)
 {
  This.CoordsRef:AddSetting[Support, ${value}]
 }

 member:string PilotToSupport()
 {
  return ${This.CoordsRef.FindSetting[PilotToSupport, "Type Name Here"]}
 }

 method SetPilotToSupport(string PilotToSupport)
 {
  This.CoordsRef:AddSetting[PilotToSupport, ${PilotToSupport}]
 }

 member:bool Sanctum1()
 {
  return ${This.CoordsRef.FindSetting[Sanctum1, FALSE]}
 }

 method SetSanctum1(bool value)
 {
  This.CoordsRef:AddSetting[Sanctum1, ${value}]
 }
 member:bool Sanctum2()
 {
  return ${This.CoordsRef.FindSetting[Sanctum2, FALSE]}
 }

 method SetSanctum2(bool value)
 {
  This.CoordsRef:AddSetting[Sanctum2, ${value}]
 }
 member:int WaitBeforeScan()
 {
  return ${This.CoordsRef.FindSetting[WaitBeforeScan, 0]}
 }

 method SetWaitBeforeScan(int WaitBeforeScan)
 {
  This.CoordsRef:AddSetting[WaitBeforeScan, ${WaitBeforeScan}]
 }
 member:int SmartBombRange()
 {
  return ${This.CoordsRef.FindSetting[SmartBombRange, 5000]}
 }

 method SetSmartBombRange(int SmartBombRange)
 {
  This.CoordsRef:AddSetting[SmartBombRange, ${SmartBombRange}]
 }
}





/* ************************************************************************* */
/* ************************************************************************* */
objectdef obj_Config_Whitelist
{
 variable string DATA_FILE = "${BaseConfig.CONFIG_PATH}/${Me.Name} Whitelist.xml"
 variable settingsetref BaseRef

 method Initialize()
 {
  LavishSettings[EVEBotWhitelist]:Clear
  LavishSettings:AddSet[EVEBotWhitelist]
  This.BaseRef:Set[${LavishSettings[EVEBotWhitelist]}]
  UI:UpdateConsole["obj_Config_Whitelist: Loading ${DATA_FILE}"]
  This.BaseRef:Import[${This.DATA_FILE}]

  if !${This.BaseRef.FindSet[Pilots](exists)}
  {
   This.BaseRef:AddSet[Pilots]
   This.PilotsRef:AddSetting[Sample_Pilot_Comment, 0]
  }

  if !${This.BaseRef.FindSet[Corporations](exists)}
  {
   This.BaseRef:AddSet[Corporations]
   This.CorporationsRef:AddSetting[Sample_Corporation_Comment, 0]
  }

  if !${This.BaseRef.FindSet[Alliances](exists)}
  {
   This.BaseRef:AddSet[Alliances]
   This.AlliancesRef:AddSetting[Sample_Alliance_Comment, 0]
  }

  UI:UpdateConsole["obj_Config_Whitelist: Initialized", LOG_MINOR]
 }

 method Shutdown()
 {
;-  This:Save[]
;-  LavishSettings[EVEBotWhitelist]:Clear
 }

 method Save()
 {
  LavishSettings[EVEBotWhitelist]:Export[${This.DATA_FILE}]
 }

 member:settingsetref PilotsRef()
 {
  return ${This.BaseRef.FindSet[Pilots]}
 }

 member:settingsetref CorporationsRef()
 {
  return ${This.BaseRef.FindSet[Corporations]}
 }

 member:settingsetref AlliancesRef()
 {
  return ${This.BaseRef.FindSet[Alliances]}
 }
}

/* ************************************************************************* */
objectdef obj_Config_Blacklist
{
 variable string DATA_FILE = "${BaseConfig.CONFIG_PATH}/${Me.Name} Blacklist.xml"
 variable settingsetref BaseRef

 method Initialize()
 {
  LavishSettings[EVEBotBlacklist]:Clear
  LavishSettings:AddSet[EVEBotBlacklist]
  This.BaseRef:Set[${LavishSettings[EVEBotBlacklist]}]
  UI:UpdateConsole["obj_Config_Blacklist: Loading ${DATA_FILE}"]
  This.BaseRef:Import[${This.DATA_FILE}]

  if !${This.BaseRef.FindSet[Pilots](exists)}
  {
   This.BaseRef:AddSet[Pilots]
   This.PilotsRef:AddSetting[Sample_Pilot_Comment, 0]
  }

  if !${This.BaseRef.FindSet[Corporations](exists)}
  {
   This.BaseRef:AddSet[Corporations]
   This.CorporationsRef:AddSetting[Sample_Corporation_Comment, 0]
  }

  if !${This.BaseRef.FindSet[Alliances](exists)}
  {
   This.BaseRef:AddSet[Alliances]
   This.AlliancesRef:AddSetting[Sample_Alliance_Comment, 0]
  }

  UI:UpdateConsole["obj_Config_Blacklist: Initialized", LOG_MINOR]
 }

 method Shutdown()
 {
;-  This:Save[]
;-  LavishSettings[EVEBotBlacklist]:Clear
 }

 method Save()
 {
  LavishSettings[EVEBotBlacklist]:Export[${This.DATA_FILE}]
 }

 member:settingsetref PilotsRef()
 {
  return ${This.BaseRef.FindSet[Pilots]}
 }

 member:settingsetref CorporationsRef()
 {
  return ${This.BaseRef.FindSet[Corporations]}
 }

 member:settingsetref AlliancesRef()
 {
  return ${This.BaseRef.FindSet[Alliances]}
 }
}

/* ************************************************************************* */
objectdef obj_AllowedAnomaly
{
 variable string Name

 method Initialize(string arg_Name)
 {
  Name:Set[${arg_Name}]
 }
}

objectdef obj_Configuration_AllowedAnomalies
{
 variable string SetName = "AllowedAnomalies"
 variable index:obj_AllowedAnomaly AllowedAnomalyNames

 method Initialize()
 {
  if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
  {
   UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
   This:Set_Default_Values[]
  }

  UI:UpdateConsole["obj_Configuration_AllowedAnomalies: Initialized"]
 }

 member:settingsetref AllowedAnomaliesRef()
 {
  return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
 }
 method Set_Default_Values()
 {
  BaseConfig.BaseRef:AddSet[${This.SetName}]
 }

 method AddAllowedAnomaly(string value)
 {
  if !${This.IsListed[${value}]}
   This.AllowedAnomaliesRef:AddSetting[${value},1]
 }
 method RemoveAllowedAnomaly(string value)
 {
  This.AllowedAnomaliesRef.FindSetting[${value}]:Remove
 }
 member:bool IsListed(string value)
 {
  This:RefreshAllowedAnomalies
  variable iterator InfoFromSettings
  This.AllowedAnomalyNames:GetIterator[InfoFromSettings]
  if ${InfoFromSettings:First(exists)}
   do
   {
    if ${InfoFromSettings.Value.Name.Equal[${value}]}
     return TRUE
   }
   while ${InfoFromSettings:Next(exists)}
  return FALSE
 }

 method RefreshAllowedAnomalies()
 {
  AllowedAnomalyNames:Clear
  variable iterator InfoFromSettings
  This.AllowedAnomaliesRef:GetSettingIterator[InfoFromSettings]
  if ${InfoFromSettings:First(exists)}
  {
   do
   {
    AllowedAnomalyNames:Insert[${InfoFromSettings.Key},${InfoFromSettings.Value}]
   }
   while ${InfoFromSettings:Next(exists)}
  }
 }
}

/* ************************************************************************* */
