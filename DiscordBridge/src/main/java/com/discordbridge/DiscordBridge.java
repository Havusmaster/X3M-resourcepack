package com.discordbridge;

import com.discordbridge.listeners.ChatListener;
import com.discordbridge.listeners.JoinLeaveListener;
import org.bukkit.plugin.java.JavaPlugin;

public class DiscordBridge extends JavaPlugin {

    private static DiscordBridge instance;
    private DiscordBot discordBot;

    @Override
    public void onEnable() {
        instance = this;

        saveDefaultConfig();
        reloadConfig();

        String token = getConfig().getString("bot-token", "");
        String channelId = getConfig().getString("chat-channel-id", "1506295560427012286");
        String botUserId = getConfig().getString("bot-user-id", "1506292700784365748");

        if (token.isEmpty() || token.equals("YOUR_BOT_TOKEN")) {
            getLogger().severe("Bot token is not configured! Set bot-token in config.yml");
            getServer().getPluginManager().disablePlugin(this);
            return;
        }

        discordBot = new DiscordBot(token, channelId, botUserId);

        DiscordCommandListener commandListener = new DiscordCommandListener(this, channelId);
        discordBot.setCommandListener(commandListener);

        if (discordBot.connect()) {
            getLogger().info("Discord bot connected successfully!");
        } else {
            getLogger().severe("Failed to connect Discord bot. Check your token.");
            getServer().getPluginManager().disablePlugin(this);
            return;
        }

        getServer().getPluginManager().registerEvents(new ChatListener(this), this);
        getServer().getPluginManager().registerEvents(new JoinLeaveListener(this), this);

        getLogger().info("DiscordBridge enabled!");

        if (discordBot.isConnected()) {
            discordBot.sendMessage("\u2705 **Minecraft \u0441\u0435\u0440\u0432\u0435\u0440 \u0437\u0430\u043F\u0443\u0449\u0435\u043D!**");
        }
    }

    @Override
    public void onDisable() {
        if (discordBot != null && discordBot.isConnected()) {
            discordBot.sendMessage("\u274C **Minecraft \u0441\u0435\u0440\u0432\u0435\u0440 \u043E\u0441\u0442\u0430\u043D\u043E\u0432\u043B\u0435\u043D!**");
            discordBot.disconnect();
        }
        getLogger().info("DiscordBridge disabled!");
    }

    public static DiscordBridge getInstance() {
        return instance;
    }

    public DiscordBot getDiscordBot() {
        return discordBot;
    }
}
