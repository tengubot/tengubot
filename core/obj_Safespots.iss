objectdef obj_Safespots
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable index:bookmark SafeSpots
	variable iterator SafeSpotIterator

        variable int RangeMyHome = 0

	method Initialize()
	{
		UI:UpdateConsole["obj_Safespots: Initialized", LOG_MINOR]
	}

	method ResetSafeSpotList()
	{
		SafeSpots:Clear
		EVE:GetBookmarks[SafeSpots]

		variable int idx
		idx:Set[${SafeSpots.Used}]

		while ${idx} > 0
		{
			variable string Prefix
			Prefix:Set[${Config.Labels.SafeSpotPrefix}]

			variable string Label
			Label:Set["${SafeSpots.Get[${idx}].Label.Escape}"]
			if ${Label.Left[${Prefix.Length}].NotEqual[${Prefix}]}
			{
				SafeSpots:Remove[${idx}]
			}
			elseif ${SafeSpots.Get[${idx}].SolarSystemID} != ${Me.SolarSystemID}
			{
				SafeSpots:Remove[${idx}]
			}

			idx:Dec
		}
		SafeSpots:Collapse
		SafeSpots:GetIterator[SafeSpotIterator]

		UI:UpdateConsole["ResetSafeSpotList found ${SafeSpots.Used} safespots in this system."]
	}

	function WarpToNextSafeSpot()
	{
		if ${SafeSpots.Used} == 0
		{
			This:ResetSafeSpotList
		}

		if ${SafeSpots.Get[1](exists)} && ${SafeSpots.Get[1].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:ResetSafeSpotList
		}

		if !${SafeSpotIterator:Next(exists)}
		{
			SafeSpotIterator:First
		}

		if ${SafeSpotIterator.Value(exists)}
		{
			call Ship.WarpToBookMark ${SafeSpotIterator.Value.ID}
		}
		else
		{
			UI:UpdateConsole["ERROR: obj_Safespots.WarpToNextSafeSpot found an invalid bookmark!"]
		}
	}

	function AlignToNextSafeSpot()
	{
		if ${SafeSpots.Used} == 0
		{
			This:ResetSafeSpotList
		}

		if ${SafeSpots.Get[1](exists)} && ${SafeSpots.Get[1].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:ResetSafeSpotList
		}

		if !${SafeSpotIterator:Next(exists)}
		{
			SafeSpotIterator:First
		}

		if ${SafeSpotIterator.Value(exists)}
		{
			SafeSpotIterator.Value:AlignTo
			UI:UpdateConsole["Aligning to ${SafeSpotIterator.Value.Label}"]
		}
		else
		{
			UI:UpdateConsole["ERROR: obj_Safespots.WarpToNextSafeSpot found an invalid bookmark!"]
		}
	}

	member:bool IsAtSafespot()
	{
		if ${SafeSpots.Used} == 0
		{
			This:ResetSafeSpotList
		}

		; big debug block to get to the bottom of the "safe spot problem"
		;UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: ItemID = ${SafeSpotIterator.Value.ItemID}"]
		;UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: SS_X = ${SafeSpotIterator.Value.X}"]
		;UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: SS_Y = ${SafeSpotIterator.Value.Y}"]
		;UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: SS_Z = ${SafeSpotIterator.Value.Z}"]
		;UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: ME_X = ${Me.ToEntity.X}"]
		;UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: ME_Y = ${Me.ToEntity.Y}"]
		;UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: ME_Z = ${Me.ToEntity.Z}"]
		;UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: DIST = ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]}"]

		; Are we within warp range of the bookmark?
		if ${SafeSpotIterator.Value.ItemID} > -1
		{
            ;UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: ItemID = ${SafeSpotIterator.Value.ItemID}"]
			if ${Me.ToEntity.DistanceTo[${SafeSpotIterator.Value.ItemID}]} < WARP_RANGE
			{
				return TRUE
			}
		}
		elseif ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]} < WARP_RANGE
		{
			return TRUE
		}

		return FALSE
	}

	member:bool IsAtSafespot()
	{
		RangeMyHome:Set[0]

		if ${SafeSpots.Used} == 0
		{
			This:ResetSafeSpotList
		}

		if ${SafeSpotIterator.Value.ItemID} > -1
		{
			RangeMyHome:Set[${Me.ToEntity.DistanceTo[${SafeSpotIterator.Value.ItemID}]}]
			UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: ${RangeMyHome} km do seifa"]

			if ${RangeMyHome} < 5000
			{
				return TRUE
			}
		}
		elseif ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]} < 5000
		{
			RangeMyHome:Set[${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]}]
			UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: ${RangeMyHome} km do seifa"]
			return TRUE
		}
		return FALSE
	}

	member:bool IsNearSafespot()
	{
		RangeMyHome:Set[0]

		if ${SafeSpots.Used} == 0
		{
			This:ResetSafeSpotList
		}

		if ${SafeSpotIterator.Value.ItemID} > -1
		{
			RangeMyHome:Set[${Me.ToEntity.DistanceTo[${SafeSpotIterator.Value.ItemID}]}]
			UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: ${RangeMyHome} km do seifa"]

			if ${RangeMyHome} < 155000
			{
				return TRUE
			}
		}
		elseif ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]} < 155000
		{
			RangeMyHome:Set[${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]}]
			UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: ${RangeMyHome} km do seifa"]
			return TRUE
		}
		return FALSE
	}

	function WarpTo()
	{
		call This.WarpToNextSafeSpot
		call This.ApproachSafeSpot
	}


        function ApproachSafeSpot()
        {
                while ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]} > WARP_RANGE
                {
                        UI:UpdateConsole["Safespot distance: ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]} - aligning..."]
			SafeSpotIterator.Value:AlignTo
			call This.WarpToNextSafeSpot
			wait 10
                }

		while ((${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]} < WARP_RANGE) && (${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]} > 3000))
		{
                        UI:UpdateConsole["Safespot distance: ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]} - approaching..."]
			SafeSpotIterator.Value:Approach
			wait 10
		}
        }

}

