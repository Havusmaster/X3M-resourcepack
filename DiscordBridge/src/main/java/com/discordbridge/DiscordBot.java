package com.discordbridge;

import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.JDABuilder;
import net.dv8tion.jda.api.entities.Activity;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.requests.GatewayIntent;
import net.dv8tion.jda.api.utils.MemberCachePolicy;
import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.entities.MessageEmbed;
import java.awt.Color;
import java.time.Instant;

public class DiscordBot {

    private JDA jda;
    private final String token;
    private final String channelId;
    private final String botUserId;
    private DiscordCommandListener commandListener;

    public DiscordBot(String token, String channelId, String botUserId) {
        this.token = token;
        this.channelId = channelId;
        this.botUserId = botUserId;
    }

    public void setCommandListener(DiscordCommandListener listener) {
        this.commandListener = listener;
    }

    public boolean connect() {
        try {
            jda = JDABuilder.createDefault(token)
                .setActivity(Activity.playing("Minecraft"))
                .enableIntents(GatewayIntent.MESSAGE_CONTENT, GatewayIntent.GUILD_MESSAGES)
                .setMemberCachePolicy(MemberCachePolicy.NONE)
                .build();

            if (commandListener != null) {
                jda.addEventListener(commandListener);
            }

            jda.awaitReady();
            return true;
        } catch (Exception e) {
            DiscordBridge.getInstance().getLogger().severe("Failed to connect to Discord: " + e.getMessage());
            return false;
        }
    }

    public void disconnect() {
        if (jda != null) {
            jda.shutdown();
        }
    }

    public boolean isConnected() {
        return jda != null && jda.getStatus() == JDA.Status.CONNECTED;
    }

    public void sendMessage(String message) {
        if (!isConnected() || channelId.isEmpty()) return;
        TextChannel channel = jda.getTextChannelById(channelId);
        if (channel != null) {
            channel.sendMessage(message).queue();
        }
    }

    public void sendEmbed(String title, String description, Color color, String thumbnailUrl) {
        if (!isConnected() || channelId.isEmpty()) return;
        TextChannel channel = jda.getTextChannelById(channelId);
        if (channel == null) return;

        EmbedBuilder builder = new EmbedBuilder()
            .setTitle(title)
            .setColor(color)
            .setTimestamp(Instant.now());

        if (description != null && !description.isEmpty()) {
            builder.setDescription(description);
        }

        if (thumbnailUrl != null && !thumbnailUrl.isEmpty()) {
            builder.setThumbnail(thumbnailUrl);
        }

        channel.sendMessageEmbeds(builder.build()).queue();
    }

    public void sendPlainEmbed(String title, String description, Color color) {
        sendEmbed(title, description, color, null);
    }

    public long getBotUserId() {
        try {
            return Long.parseLong(botUserId);
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    public JDA getJda() {
        return jda;
    }
}
