package com.discordbridge.listeners;

import com.discordbridge.DiscordBridge;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.event.player.PlayerQuitEvent;
import java.awt.Color;
import java.util.List;
import java.util.Random;

public class JoinLeaveListener implements Listener {

    private final DiscordBridge plugin;
    private final Random random = new Random();

    private final List<String> joinMessages = List.of(
        "\u043F\u0440\u0438\u0441\u043E\u0435\u0434\u0438\u043D\u0438\u043B\u0441\u044F \u043A \u0438\u0433\u0440\u0435",
        "\u0437\u0430\u043B\u0435\u0442\u0430\u0435\u0442 \u043D\u0430 \u0441\u0435\u0440\u0432\u0435\u0440",
        "\u0437\u0430\u043F\u0440\u044B\u0433\u0438\u0432\u0430\u0435\u0442 \u043D\u0430 \u0431\u043E\u0440\u0442"
    );

    private final List<String> quitMessages = List.of(
        "\u0438\u0433\u0440\u043E\u043A\u0443 \u0441\u0442\u0430\u043B\u043E \u0441\u043A\u0443\u0447\u043D\u043E",
        "\u043F\u043E\u0448\u0435\u043B \u0434\u0435\u043B\u0430\u0442\u044C \u0443\u0440\u043E\u043A\u0438",
        "\u0432\u044B\u0448\u0435\u043B \u0438\u0437 \u0438\u0433\u0440\u044B"
    );

    public JoinLeaveListener(DiscordBridge plugin) {
        this.plugin = plugin;
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void onPlayerJoin(PlayerJoinEvent event) {
        if (!plugin.getDiscordBot().isConnected()) return;

        Player player = event.getPlayer();
        String randomMsg = joinMessages.get(random.nextInt(joinMessages.size()));
        String thumbnail = "https://mc-heads.net/head/" + player.getName();
        plugin.getDiscordBot().sendEmbed(
            player.getName() + " " + randomMsg,
            null,
            Color.GREEN,
            thumbnail
        );
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void onPlayerQuit(PlayerQuitEvent event) {
        if (!plugin.getDiscordBot().isConnected()) return;

        Player player = event.getPlayer();
        String randomMsg = quitMessages.get(random.nextInt(quitMessages.size()));
        String thumbnail = "https://mc-heads.net/head/" + player.getName();
        plugin.getDiscordBot().sendEmbed(
            player.getName() + " " + randomMsg,
            null,
            Color.RED,
            thumbnail
        );
    }
}
