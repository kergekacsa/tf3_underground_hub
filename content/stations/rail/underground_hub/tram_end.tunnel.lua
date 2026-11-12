-- Built by tools/build_tram_tunnel.js from the concrete car tunnel of the game. Do not edit.
-- The outer end of a tram level uses it: it closes the tunnel while no street is connected.
function data()
	local newdir = "::/infrastructure/tunnel/b_car/"
	local tunnel_b_car_add_lamp_side_lft = {
        newdir .. "tunnel_b_car_add_lamp_side_lft.mdl",
        { { 0, 1, 0, }, { 6, -2, 8, } },
	}
	local tunnel_b_car_add_lamp_side_rgt = {
			newdir .. "tunnel_b_car_add_lamp_side_rgt.mdl",
			{ { 0, 1, 0, }, { 6, -2, 8, } },
	}
	local tunnel_b_car_add_lamp_s_side_lft = {
			newdir .. "tunnel_b_car_add_lamp_s_side_lft.mdl",
			{ { 0, 1, 0, }, { 6, -2, 8, } },
	}
	local tunnel_b_car_add_lamp_s_side_rgt = {
			newdir .. "tunnel_b_car_add_lamp_s_side_rgt.mdl",
			{ { 0, 1, 0, }, { 6, -2, 8, } },
	}
	local tunnel_b_car_add_light_absorber_lft = {
			newdir .. "tunnel_b_car_add_light_absorber_lft.mdl",
			{ { -0.00185844837687909603118896484375, -0.00231060595251619815826416015625, -0.0000000208616253161153508699499070644378662109375, }, { 0.00185844837687909603118896484375, 0.00188140780664980411529541015625, 0.000000006556509557498202411807142198085784912109375, } },
	}
	local tunnel_b_car_add_light_absorber_mid = {
			newdir .. "tunnel_b_car_add_light_absorber_mid.mdl",
			{ { -0.00185844837687909603118896484375, -0.00231060595251619815826416015625, -0.0000000208616253161153508699499070644378662109375, }, { 0.00185844837687909603118896484375, 0.00188140780664980411529541015625, 0.000000006556509557498202411807142198085784912109375, } },
	}
	local tunnel_b_car_add_light_absorber_rgt = {
			newdir .. "tunnel_b_car_add_light_absorber_rgt.mdl",
			{ { -0.00185844837687909603118896484375, -0.00231060595251619815826416015625, -0.0000000208616253161153508699499070644378662109375, }, { 0.00185844837687909603118896484375, 0.00188140780664980411529541015625, 0.000000006556509557498202411807142198085784912109375, } },
	}
	local tunnel_b_car_add_vent_rep = {
			newdir .. "tunnel_b_car_add_vent_rep.mdl",
			{ { 2.2054941654205322265625, 2.093100070953369140625, 4.48086261749267578125, }, { 3.229915618896484375, 2.861748218536376953125, 5.50879669189453125, } },
	}
	local tunnel_b_car_dead_lft = {
			newdir .. "tunnel_b_car_dead_lft.mdl",
			{ { -0.88256740570068359375, -1.9948132038116455078125, -2.550000667572021484375, }, { 0.00000095367431640625, 2.0015499591827392578125, 9.02826404571533203125, } },
	}
	local tunnel_b_car_dead_rep = {
			newdir .. "tunnel_b_car_dead_rep.mdl",
			{ { -0.88257086277008056640625, 0.000000391351562711861333809792995452880859375, -2.550001621246337890625, }, { 0.000000476837158203125, 4.99999904632568359375, 9.028263092041015625, } },
	}
	local tunnel_b_car_dead_rgt = {
			newdir .. "tunnel_b_car_dead_rgt.mdl",
			{ { -0.88256740570068359375, -1.9948132038116455078125, -2.550000667572021484375, }, { 0.00000095367431640625, 2.0015499591827392578125, 9.02826404571533203125, } },
	}
	local tunnel_b_car_endportal_lft = {
			newdir .. "tunnel_b_car_endportal_lft.mdl",
			{ { -2.5, -2.0002124309539794921875, -2.550000667572021484375, }, { 10.7318172454833984375, 2, 9.028263092041015625, } },
	}
	local tunnel_b_car_endportal_rep = {
			newdir .. "tunnel_b_car_endportal_rep.mdl",
			{ { -2.5, -0.000002247770453323028050363063812255859375, -2.5500080585479736328125, }, { 10.685504913330078125, 4.999997615814208984375, 9.028293609619140625, } },
	}
	local tunnel_b_car_endportal_rgt = {
			newdir .. "tunnel_b_car_endportal_rgt.mdl",
			{ { -2.5, -2, -2.550000667572021484375, }, { 10.7318172454833984375, 2.0002124309539794921875, 9.028263092041015625, } },
	}
	local tunnel_b_car_end_rep_switch = {
			newdir .. "tunnel_b_car_end_rep_switch.mdl",
			{ { 0, -0.0000009090728099181433208286762237548828125, -0.112700067460536956787109375, }, { 6.000000476837158203125, 4.99999904632568359375, 9.028263092041015625, } },
	}
	local tunnel_b_car_end_side_lft = {
			newdir .. "tunnel_b_car_end_side_lft.mdl",
			{ { -0.000001430511474609375, -2.0019378662109375, -2.5500004291534423828125, }, { 6, 1.9911787509918212890625, 9.02707576751708984375, } },
	}
	local tunnel_b_car_end_side_rgt = {
			newdir .. "tunnel_b_car_end_side_rgt.mdl",
			{ { -0.00036345236003398895263671875, -1.99655616283416748046875, -2.5500004291534423828125, }, { 5.989960193634033203125, 1.99980795383453369140625, 9.028263092041015625, } },
	}
	local tunnel_b_car_m1_rep_switch = {
			newdir .. "tunnel_b_car_m1_rep_switch.mdl",
			{ { 0, -0.0000040263994378619827330112457275390625, -0.112700067460536956787109375, }, { 6, 4.999995708465576171875, 9.028263092041015625, } },
	}
	local tunnel_b_car_m1_side_lft = {
			newdir .. "tunnel_b_car_m1_side_lft.mdl",
			{ { -0.00000071525556677443091757595539093017578125, -2.000194549560546875, -2.5500009059906005859375, }, { 6, 1.99292337894439697265625, 9.0282611846923828125, } },
	}
	local tunnel_b_car_m1_side_rgt = {
			newdir .. "tunnel_b_car_m1_side_rgt.mdl",
			{ { -0.00000071525556677443091757595539093017578125, -1.99481379985809326171875, -2.5500004291534423828125, }, { 5.999998569488525390625, 2.0015513896942138671875, 9.028263092041015625, } },
	}
	local tunnel_b_car_m1_switch_lft = {
			newdir .. "tunnel_b_car_m1_switch_lft.mdl",
			{ { 0.000000476837072937996708787977695465087890625, -2.000002384185791015625, -0.112699650228023529052734375, }, { 6.000000476837158203125, 1.9759504795074462890625, 9.0609607696533203125, } },
	}
	local tunnel_b_car_m1_switch_rgt = {
			newdir .. "tunnel_b_car_m1_switch_rgt.mdl",
			{ { 0.000000476837072937996708787977695465087890625, -1.994814395904541015625, -0.112697802484035491943359375, }, { 6.000000476837158203125, 2.0015504360198974609375, 9.0609607696533203125, } },
	}
	local tunnel_b_car_startportal_lft = {
			newdir .. "tunnel_b_car_startportal_lft.mdl",
			{ { -10.7318172454833984375, -2.0002124309539794921875, -2.550000667572021484375, }, { 2.5, 2, 9.028263092041015625, } },
	}
	local tunnel_b_car_startportal_rep = {
			newdir .. "tunnel_b_car_startportal_rep.mdl",
			{ { -10.78999996185302734375, -0.000002247770453323028050363063812255859375, -2.650000095367431640625, }, { 2.5, 4.999997615814208984375, 9.028293609619140625, } },
	}
	local tunnel_b_car_startportal_rgt = {
			newdir .. "tunnel_b_car_startportal_rgt.mdl",
			{ { -10.7318172454833984375, -2, -2.550000667572021484375, }, { 2.5, 2.0002124309539794921875, 9.028263092041015625, } },
	}
	local tunnel_b_car_start_rep_switch = {
			newdir .. "tunnel_b_car_start_rep_switch.mdl",
			{ { -0.0000014305115882962127216160297393798828125, 0.0002512807841412723064422607421875, -0.112668596208095550537109375, }, { 5.999998569488525390625, 5.00025081634521484375, 9.0282917022705078125, } },
	}
	local tunnel_b_car_start_side_lft = {
			newdir .. "tunnel_b_car_start_side_lft.mdl",
			{ { -0.0000002384185364689983543939888477325439453125, -2.000194072723388671875, -2.550000667572021484375, }, { 6, 1.99980831146240234375, 9.02870845794677734375, } },
	}
	local tunnel_b_car_start_side_rgt = {
			newdir .. "tunnel_b_car_start_side_rgt.mdl",
			{ { -0.00000030517577442878973670303821563720703125, -2.0000002384185791015625, -2.550000667572021484375, }, { 6, 2.0000040531158447265625, 9.028263092041015625, } },
	}
local railing = {
	tunnel_b_car_m1_side_rgt,
	tunnel_b_car_m1_side_rgt,
	tunnel_b_car_m1_switch_rgt,
	tunnel_b_car_m1_rep_switch,
	tunnel_b_car_m1_rep_switch,
	tunnel_b_car_m1_side_lft,
	tunnel_b_car_m1_side_lft,
	tunnel_b_car_m1_switch_lft,
}
local startrailing = {
	tunnel_b_car_start_side_rgt,
	tunnel_b_car_start_side_rgt,
	tunnel_b_car_m1_switch_rgt,
	tunnel_b_car_start_rep_switch,
	tunnel_b_car_start_rep_switch,
	tunnel_b_car_start_side_lft,
	tunnel_b_car_start_side_lft,
	tunnel_b_car_m1_switch_lft,
}
local endrailing = {
	tunnel_b_car_end_side_rgt,
	tunnel_b_car_end_side_rgt,
	tunnel_b_car_m1_switch_rgt,
	tunnel_b_car_end_rep_switch,
	tunnel_b_car_end_rep_switch,
	tunnel_b_car_end_side_lft,
	tunnel_b_car_end_side_lft,
	tunnel_b_car_m1_switch_lft,
}

local config = {
	railingBegin = startrailing,
	railingRepeat = railing,
	railingEnd = endrailing,
	portalsConfig = { tunnel_b_car_startportal_rgt, tunnel_b_car_startportal_rep, tunnel_b_car_startportal_lft },
	endPortalsConfig= { tunnel_b_car_endportal_rgt, tunnel_b_car_endportal_rep, tunnel_b_car_endportal_lft },
	deadConfig = { tunnel_b_car_dead_rgt, tunnel_b_car_dead_rep, tunnel_b_car_dead_lft, tunnel_b_car_dead_rgt, tunnel_b_car_dead_lft },
	assetsConfig = {
		{ tunnel_b_car_m1_side_lft[1], tunnel_b_car_add_lamp_s_side_lft[1], 2, 0},
		{ tunnel_b_car_m1_side_rgt[1], tunnel_b_car_add_lamp_side_rgt[1], 2, 0},
		-- { tunnel_b_car_start_rep_switch[1], tunnel_b_car_add_vent_rep[1], 4, 2},
		{ tunnel_b_car_end_rep_switch[1], tunnel_b_car_add_vent_rep[1], 1, 0},
		{ tunnel_b_car_m1_rep_switch[1], tunnel_b_car_add_light_absorber_mid[1], 2, 0},
		{ tunnel_b_car_m1_side_lft[1], tunnel_b_car_add_light_absorber_lft[1], 2, 0},
		{ tunnel_b_car_m1_side_rgt[1], tunnel_b_car_add_light_absorber_rgt[1], 2, 0},
		{ tunnel_b_car_start_side_rgt[1], tunnel_b_car_add_light_absorber_rgt[1], 1, 0},
		{ tunnel_b_car_start_side_lft[1], tunnel_b_car_add_light_absorber_lft[1], 1, 0},
		{ tunnel_b_car_start_rep_switch[1], tunnel_b_car_add_light_absorber_mid[1], 1, 0},
		{ tunnel_b_car_end_side_rgt[1], tunnel_b_car_add_light_absorber_rgt[1], 1, 0},
		{ tunnel_b_car_end_side_lft[1], tunnel_b_car_add_light_absorber_lft[1], 1, 0},
		{ tunnel_b_car_end_rep_switch[1], tunnel_b_car_add_light_absorber_mid[1], 1, 0},
	}
}

return {
	description = {
		name = _("INFRA_TUNNEL_CONCRETE_NAME"),
		icon = newdir .."icon/b_car.tga",
	},
	menuCategory = {
		categories = {},
	},
	carriers = { "ROAD" },
	cost = 600.0,
	availability = {
		yearFrom = -1,
		yearTo = -1,
	},

	updateScript = {
		fileName = "::/infrastructure/tunnel/tunnel.script@tunnel.updateFn",
		params = config
	},

	padding = 2,
	height = 9.03 + 1.0,
	version = 1,
}
end
