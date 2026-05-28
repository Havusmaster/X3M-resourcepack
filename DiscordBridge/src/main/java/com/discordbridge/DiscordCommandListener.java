package com.discordbridge;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.events.message.MessageReceivedEvent;
import net.dv8tion.jda.api.hooks.ListenerAdapter;
import org.bukkit.Bukkit;
import org.bukkit.entity.Player;
import java.awt.Color;
import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

public class DiscordCommandListener extends ListenerAdapter {

    private final DiscordBridge plugin;
    private final String channelId;

    public DiscordCommandListener(DiscordBridge plugin, String channelId) {
        this.plugin = plugin;
        this.channelId = channelId;
    }

    @Override
    public void onMessageReceived(MessageReceivedEvent event) {
        if (event.getAuthor().isBot()) return;

        String messageChannelId = event.getChannel().getId();
        if (!messageChannelId.equals(channelId)) return;

        long authorId = event.getAuthor().getIdLong();
        long botUserId = plugin.getDiscordBot().getBotUserId();
        if (authorId == botUserId) return;

        String message = event.getMessage().getContentRaw();

        if (message.equalsIgnoreCase("list")) {
            handleListCommand(event);
            return;
        }

        String authorName = event.getAuthor().getName();
        Bukkit.broadcastMessage(
            plugin.getConfig().getString("format.discord-to-minecraft", "<gray>[Discord] <aqua>%s: <white>%s")
                .formatted(authorName, message)
        );
    }

    private void handleListCommand(MessageReceivedEvent event) {
        if (!plugin.getDiscordBot().isConnected()) return;

        List<Player> players = List.copyOf(Bukkit.getOnlinePlayers());

        EmbedBuilder builder = new EmbedBuilder()
            .setColor(Color.decode("#5865F2"))
            .setTimestamp(Instant.now());

        if (players.isEmpty()) {
            builder.setTitle("\u0418\u0433\u0440\u043e\u043A\u043E\u0432 \u043E\u043D\u043B\u0430\u0439\u043D: 0");
            builder.setDescription("\u041D\u0435\u0442 \u0438\u0433\u0440\u043E\u043A\u043E\u0432 \u043D\u0430 \u0441\u0435\u0440\u0432\u0435\u0440\u0435");
        } else {
            builder.setTitle("\u0418\u0433\u0440\u043E\u043A\u043E\u0432 \u043E\u043D\u043B\u0430\u0439\u043D: " + players.size());
            String playerList = players.stream()
                .map(Player::getName)
                .collect(Collectors.joining("\n\u2022 ", "\u2022 ", ""));
            builder.setDescription(playerList);
        }

        event.getChannel().sendMessageEmbeds(builder.build()).queue();
    }
}
