/*
	Cache class

	Caches isxeve result data:
		StaticList: collection of var/member pairs which are initialized once.
		ObjectList: collection of var/member pairs which are retrieved every 2 seconds
		FastObjectList: collection of var/member pairs which are retrieved every 1/2 second

*/

objectdef obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable float RunTime
	variable float NextPulse2Sec = 0
	variable float NextPulse1Sec = 0
	variable float NextPulseHalfSec = 0

	variable collection:string StaticList
	variable collection:string ObjectList
	variable collection:string FastObjectList
	variable collection:string OneSecondObjectList

	method Initialize()
	{
		if ${StaticList.FirstKey(exists)}
		{
			This:UpdateStaticList
		}

		This:Pulse
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	/* Runs every other frame, and updates one member per run */
	method Pulse()
	{
		; Changing the /1000 is not going to make your script faster or your dog smarter. it will just break things.
		This.RunTime:Set[${Math.Calc[${Script.RunningTime}/1000]}]

		variable string temp

		/* Process FastObjectList every half second */
		if ${This.RunTime} > ${This.NextPulseHalfSec}
		{
			if ${FastObjectList.FirstKey(exists)}
			{
				do
				{
					;redirect -append "crash.txt" echo "[${FastObjectList.CurrentKey}]: ${FastObjectList.CurrentValue}"
					temp:Set[${${FastObjectList.CurrentValue}}]
					if ${temp.NotEqual["NULL"]}
					{
						${FastObjectList.CurrentKey}:Set[${temp}]
					}
					;redirect -append "crash.txt" echo "    ${${FastObjectList.CurrentKey}}"
				}
				while ${FastObjectList.NextKey(exists)}
			}

			This.NextPulseHalfSec:Set[${This.RunTime}]
    		This.NextPulseHalfSec:Inc[0.5]
		}

		/* Process ObjectList every 1 second */
		if ${This.RunTime} > ${This.NextPulse1Sec}
		{
			if ${OneSecondObjectList.FirstKey(exists)}
			{
				do
				{
					;redirect -append "crash.txt" echo "[${OneSecondObjectList.CurrentKey}]: ${OneSecondObjectList.CurrentValue}"
					temp:Set[${${OneSecondObjectList.CurrentValue}}]
					if ${temp.NotEqual["NULL"]}
					{
						${OneSecondObjectList.CurrentKey}:Set[${temp}]
					}
					;redirect -append "crash.txt" echo "${${OneSecondObjectList.CurrentKey}}"
				}
				while ${OneSecondObjectList.NextKey(exists)}
			}
			This.NextPulse1Sec:Set[${This.RunTime}]
    		This.NextPulse1Sec:Inc[2.0]
		}

		/* Process ObjectList every 2 seconds */
		if ${This.RunTime} > ${This.NextPulse2Sec}
		{
			if ${ObjectList.FirstKey(exists)}
			{
				do
				{
					;redirect -append "crash.txt" echo "[${ObjectList.CurrentKey}]: ${ObjectList.CurrentValue}"
					temp:Set[${${ObjectList.CurrentValue}}]
					if ${temp.NotEqual["NULL"]}
					{
						${ObjectList.CurrentKey}:Set[${temp}]
					}
					;redirect -append "crash.txt" echo "${${ObjectList.CurrentKey}}"
				}
				while ${ObjectList.NextKey(exists)}
			}
			This.NextPulse2Sec:Set[${This.RunTime}]
    		This.NextPulse2Sec:Inc[2.0]
		}
	}

	method UpdateStaticList()
	{
		if ${StaticList.FirstKey(exists)}
		{
			do
			{
				;echo "[${StaticList.CurrentKey}]: ${StaticList.CurrentValue}"
				if ${${StaticList.CurrentValue}(exists)}
				{
					${StaticList.CurrentKey}:Set[${${StaticList.CurrentValue}}]
				}
				;echo "\"==${${StaticList.CurrentKey}}\""
			}
			while ${StaticList.NextKey(exists)}
		}
	}
}

objectdef obj_Cache_Me inherits obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable obj_Cache_Me_Ship Ship
	variable obj_Cache_Me_ToEntity ToEntity

	variable string Name
	variable int CharID
	variable int ShipID
	variable int StationID

	variable bool InStation = FALSE
	variable int TargetCount
	variable int TargetingCount
	variable int TargetedByCount
	variable int MaxLockedTargets
	variable int MaxActiveDrones
	variable float64 DroneControlDistance
	variable int SolarSystemID
	variable int AllianceID
	variable int Corp
;	variable string CorporationTicker
	variable bool AutoPilotOn = FALSE

	method Initialize()
	{
		StaticList:Set["Name", "Me.Name"]
		StaticList:Set["CharID", "Me.CharID"]

		ObjectList:Set["ShipID", "Me.ShipID"]
		ObjectList:Set["MaxLockedTargets", "Me.MaxLockedTargets"]
		ObjectList:Set["MaxActiveDrones", "Me.MaxActiveDrones"]
		ObjectList:Set["DroneControlDistance", "Me.DroneControlDistance"]
		ObjectList:Set["SolarSystemID", "Me.SolarSystemID"]
		ObjectList:Set["AllianceID", "Me.AllianceID"]
		ObjectList:Set["Corp", "Me.Corp"]
;		ObjectList:Set["CorporationTicker", "Me.CorporationTicker"]

		FastObjectList:Set["StationID", "Me.StationID"]
		FastObjectList:Set["InStation", "Me.InStation"]
		FastObjectList:Set["AutoPilotOn", "Me.AutoPilotOn"]
		FastObjectList:Set["TargetCount", "Me.TargetCount"]
		FastObjectList:Set["TargetingCount", "Me.TargetingCount"]
		FastObjectList:Set["TargetedByCount", "Me.TargetedByCount"]

		This[parent]:Initialize
	}

	method Shutdown()
	{
		This[parent]:Shutdown
	}
}

objectdef obj_Cache_Me_ToEntity inherits obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable bool IsCloaked
	variable bool IsWarpScrambled
	variable int Mode

	method Initialize()
	{
		FastObjectList:Set["IsCloaked", "Me.ToEntity.IsCloaked"]
		FastObjectList:Set["IsWarpScrambled", "Me.ToEntity.IsWarpScrambled"]
		FastObjectList:Set["Mode", "Me.ToEntity.Mode"]

		This[parent]:Initialize
	}

	method Shutdown()
	{
		This[parent]:Shutdown
	}
}

objectdef obj_Cache_Me_Ship inherits obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable float ArmorPct
	variable float StructurePct
	variable float ShieldPct
	variable float CapacitorPct
	variable float _UsedCargoCapacity
	variable float _CargoCapacity
	variable int MaxLockedTargets
	variable float MaxTargetRange

	method Initialize()
	{
		FastObjectList:Set["ArmorPct", "Me.Ship.ArmorPct"]
		FastObjectList:Set["StructurePct", "Me.Ship.StructurePct"]
		FastObjectList:Set["ShieldPct", "Me.Ship.ShieldPct"]
		FastObjectList:Set["CapacitorPct", "Me.Ship.CapacitorPct"]

		ObjectList:Set["_UsedCargoCapacity", "Me.Ship.UsedCargoCapacity"]
		ObjectList:Set["_CargoCapacity", "Me.Ship.CargoCapacity"]
		ObjectList:Set["MaxLockedTargets", "Me.Ship.MaxLockedTargets"]
		ObjectList:Set["MaxTargetRange", "Me.Ship.MaxTargetRange"]

		This[parent]:Initialize
	}

	member:float UsedCargoCapacity()
	{
		if ${Me.Ship.UsedCargoCapacity(exists)}
		{
			return ${Me.Ship.UsedCargoCapacity}
		}

		return 0
	}

	member:float CargoCapacity()
	{
		if ${Me.Ship.CargoCapacity(exists)}
		{
			return ${Me.Ship.CargoCapacity}
		}

		return 0
	}

	method Shutdown()
	{
		This[parent]:Shutdown
	}
}

objectdef obj_Cache_EVETime inherits obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string _Time

	method Initialize()
	{
		OneSecondObjectList:Set["_Time", "EVETime.Time"]
		This[parent]:Initialize
	}

	method Shutdown()
	{
		This[parent]:Shutdown
	}

	member Time()
	{
		return ${This._Time}
	}
}