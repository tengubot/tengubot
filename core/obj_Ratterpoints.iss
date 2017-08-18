objectdef obj_Ratterpoints
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable index:bookmark RatterPoints
	variable iterator RatterPointIterator

	method Initialize()
	{
		UI:UpdateConsole["obj_Ratterpoints: Initialized", LOG_MINOR]
	}

	method ResetRatterPointList()
	{
		RatterPoints:Clear
		EVE:GetBookmarks[RatterPoints]

		variable int idx
		idx:Set[${RatterPoints.Used}]
		while ${idx} > 0
		{
			variable string Prefix
			Prefix:Set[${Config.Labels.RatterPointsPrefix}]

			variable string Label
			Label:Set["${RatterPoints.Get[${idx}].Label}"]
			if ${Label.Left[${Prefix.Length}].NotEqual[${Prefix}]}
			{
				RatterPoints:Remove[${idx}]
			}
			elseif ${RatterPoints.Get[${idx}].SolarSystemID} != ${Me.SolarSystemID}
			{
				RatterPoints:Remove[${idx}]
			}

			idx:Dec
		}
		RatterPoints:Collapse
		RatterPoints:GetIterator[RatterPointIterator]

		UI:UpdateConsole["ResetRatterPointList found ${RatterPoints.Used} safespots in this system."]
	}

	function WarpToNextRatterPoint()
	{
		if ${RatterPoints.Used} == 0
		{
			This:ResetRatterPointList
		}

		if ${RatterPoints.Get[1](exists)} && ${RatterPoints.Get[1].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:ResetRatterPointList
		}

		if !${RatterPointIterator:Next(exists)}
		{
			RatterPointIterator:First
		}

		if ${RatterPointIterator.Value(exists)}
		{
			call Ship.WarpToBookMark ${RatterPointIterator.Value.ID}
		}
		else
		{
			UI:UpdateConsole["ERROR: obj_Ratterpoints.WarpToNextRatterPoint found an invalid bookmark!"]
		}
	}

	member:bool IsAtRatterpoint()
	{
		if ${RatterPoints.Used} == 0
		{
			This:ResetRatterPointList
		}

		if ${RatterPointIterator.Value.ItemID} > -1
		{
	                ;UI:UpdateConsole["DEBUG: obj_Ratterpoints.IsAtRatterpoint: ItemID = ${RatterPointIterator.Value.ItemID}"]
			if ${Me.ToEntity.DistanceTo[${RatterPointIterator.Value.ItemID}]} < WARP_RANGE
			{
				return TRUE
			}
		}
		elseif ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${RatterPointIterator.Value.X}, ${RatterPointIterator.Value.Y}, ${RatterPointIterator.Value.Z}]} < WARP_RANGE
		{
			return TRUE
		}

		return FALSE
	}

	function WarpTo()
	{
		call This.WarpToNextRatterPoint
	}
}
