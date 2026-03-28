local C = core.colorize

core.register_chatcommand("ffa_whois", {
    description = "Show online players",
    func = function(name)
        local players = ffa.get_players()
        local str_list = table.concat(players, ", ")
        return true, ("There is currently %s players in FFA. (%s)"):format(#players, C("#40AFE9", str_list))
    end
})

core.register_chatcommand("ffa_enter", {
    description = "",
    func = function(name)
        local player = core.get_player_by_name(name)
        ffa.on_enter(player)
    end
})

core.register_chatcommand("ffa_leave", {
    description = "",
    func = function(name)
        local player = core.get_player_by_name(name)
        ffa.on_leave(player)
    end
})