package com.discordbridge.listeners;

import com.discordbridge.DiscordBridge;
import io.papermc.paper.event.player.AsyncChatEvent;
import net.kyori.adventure.text.serializer.plain.PlainTextComponentSerializer;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;

public class ChatListener implements Listener {

    private final DiscordBridge plugin;

    public ChatListener(DiscordBridge plugin) {
        this.plugin = plugin;
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void onPlayerChat(AsyncChatEvent event) {
        if (!plugin.getDiscordBot().isConnected()) return;

        Player player = event.getPlayer();
        String playerName = player.getName();
        String message = PlainTextComponentSerializer.plainText().serialize(event.message());

        String format = plugin.getConfig().getString("format.minecraft-to-discord", "**%s**: %s");
        String discordMessage = format.formatted(playerName, message);

        plugin.getDiscordBot().sendMessage(discordMessage);
    }
}
