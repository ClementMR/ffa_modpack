local C = core.colorize

core.register_chatcommand("ffa_whois", {
    description = "Show players in FFA",
    func = function(name)
        local players = ffa.get_names()
        local str_list = table.concat(players, ", ")
        return true, ("There is currently %s players in FFA. (%s)"):format(#players, C("#40AFE9", str_list))
    end
})

core.register_chatcommand("ffa_enter", {
    description = "Enter FFA",
    func = function(name)
        local player = core.get_player_by_name(name)
        if not player then return end
        if minigame.get_player_entry(player) then
            core.chat_send_player(name, "You are not allowed to join FFA while being in another minigame. Try /quit")
            return
        end
        ffa.on_enter(player)
    end
})

core.register_chatcommand("ffa_leave", {
    description = "Leave FFA",
    func = function(name)
        local player = core.get_player_by_name(name)
        ffa.on_leave(player)
    end
})