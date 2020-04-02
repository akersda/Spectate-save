local specteam = 1 -- spectator team
local jointeams = {2,3} -- teams to join to
if SERVER then

	util.AddNetworkString( "specsave_message_out" )
	util.AddNetworkString( "specsave_message_in" )
	local spfile = "specsave_players.txt"
	local specplayers = {}
	if file.Exists( spfile, "DATA" ) then
		print("Loading players to spectate...")
		specplayers = util.JSONToTable(file.Read( spfile, "DATA" ))
		print("Players:")
		PrintTable( specplayers )
	end
	
	hook.Add( "PlayerSpawn", "spawnplayerasspec", function(ply)
		if specplayers[ply:SteamID()] == true then
			print("Setting " .. ply:Nick() .. " to spectate.")
			specplayers[ply:SteamID()] = false
			timer.Simple(0.1,function()
				ply:SetTeam( specteam )
				if ply:Alive() then
					ply:Kill()
				end
				net.Start( "specsave_message_out" )
				net.Send( ply )
			end)
		end
	end)
	
	timer.Create( "updatespecplayers", 10, 0, function()
		if team.NumPlayers( specteam ) > 0 then
			local filetable = {}
			for k, ply in pairs( team.GetPlayers( specteam ) ) do
				filetable[ply:SteamID()] = true
			end
			file.Write( spfile, util.TableToJSON(filetable) )
		else
			if file.Exists( spfile, "DATA" ) then
				file.Delete( spfile )
			end
		end
	end)
	
	net.Receive( "specsave_message_in", function(leng,ply) 
		local jointab = {}
		jointab.team = nil
		jointab.num = 100
		for k, teamn in pairs( jointeams ) do
			local numpl = team.NumPlayers(teamn)
			if numpl < jointab.num then
				jointab.team = teamn
				jointab.num = numpl
			end
		end
		ply:SetTeam( jointab.team )
		if ply:Alive() then
			ply:Kill()
		end
	end)
	
else

	net.Receive( "specsave_message_out", function() 
		local messagebox = vgui.Create("DFrame")
		messagebox:SetSize(300,110)
		messagebox:SetTitle("Server message")
		messagebox:Center()
		messagebox:MakePopup()
		
		messagebox.message = vgui.Create("DLabel",messagebox)
		messagebox.message:SetText("You have been moved to spectator because\nyou were spectating last map.")
		messagebox.message:SetTall(40)
		messagebox.message:Dock(TOP)
		
		messagebox.join = vgui.Create("DButton",messagebox)
		messagebox.join:SetText("Join the game!")
		messagebox.join:DockMargin( 15,5,15,5 )
		messagebox.join:SetWidth(120)
		messagebox.join:Dock(LEFT)
		function messagebox.join:DoClick()
			net.Start( "specsave_message_in" )
			net.SendToServer()
			self:GetParent():Remove()
		end
		
		messagebox.stay = vgui.Create("DButton",messagebox)
		messagebox.stay:SetText("Stay in spectate.")
		messagebox.stay:DockMargin( 15,5,15,5 )
		messagebox.stay:SetWidth(120)
		messagebox.stay:Dock(LEFT)
		function messagebox.stay:DoClick()
			self:GetParent():Remove()
		end
	end)
	
end
