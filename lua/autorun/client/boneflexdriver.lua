--
local debugtime = 0
local function DEBUG()
	if CurTime() > debugtime then
		return true
	else
		return false
	end
end

matproxy.Add({
	name = "BoneFlexDriverProxy",
	init = function( self, mat, values )
		-- list separated by comma
		self.BoneFlexDrivers = values.boneflexdrivers --bone, axis, flexcontroller, [bone, axis, flexcontroller], [...]
		self.MatName = mat:GetName()
	end,
	bind = function( self, mat, ent )
		if not IsValid(ent) then
			if DEBUG() then print ( self.MatName, "ent is not valid" ) end
			return
		end

		--bones and controllers should not have spaces in names 
		self.BoneFlexDrivers = string.Replace( self.BoneFlexDrivers, " ", "" )
		local boneflexdrivers_split = string.Split( self.BoneFlexDrivers, "," )

		local numargs = #boneflexdrivers_split
		if numargs < 3 then
			if DEBUG() then print( self.MatName, "not enough args" ) end
			return
		end

		numargs = math.floor( numargs / 3 )
		for i = 1, numargs do
			local step = (i-1) * 3
			local bonename = tostring( boneflexdrivers_split[ step + 1 ] )

			local boneid = ent:LookupBone( bonename )
			if boneid then
				ent:SetupBones() --Might be performance hungry
				local parentid = ent:GetBoneParent( boneid )
				if DEBUG() and parentid == -1 then
					--print( ent:GetModel(), "could not find parent for bone", bonename )
				end

				local axisname = string.lower( tostring( boneflexdrivers_split[ step + 2 ] ) )
				local axisnum = 1
				if ( axisname == "ty" or axisname == "y" ) then axisnum = 2 end
				if ( axisname == "tz" or axisname == "z" ) then axisnum = 3 end

				local flexcontrollername = tostring( boneflexdrivers_split[ step + 3 ] )
				local flexid = ent:GetFlexIDByName( flexcontrollername )
				if flexid then
					local bonepos, boneang = ent:GetBonePosition( boneid )
					local parentpos, parentang = Vector(), Angle()

					if parentid == -1 then
						parentpos, parentang = ent:GetPos(), ent:GetAngles()
					else
						parentpos, parentang = ent:GetBonePosition( parentid )
					end

					local localpos, _ = WorldToLocal( bonepos, boneang, parentpos, parentang )
					local flexweight = localpos[ axisnum ]
					if DEBUG() then
						print(localpos, flexweight)
					end
					ent:SetFlexWeight( flexid, flexweight )
				elseif DEBUG() then
					print( ent:GetModel(), "could not find flex controller", flexcontrollername )
				end -- if flexid
			elseif DEBUG() then
				print( self.MatName, "failed to lookup bone", bonename, ent:GetModel() )
			end -- if boneid
		end --for i
	if CurTime() > debugtime then debugtime = CurTime() + .2 end
	end --fnc
})
