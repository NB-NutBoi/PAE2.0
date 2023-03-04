package;
//------------------------------------------------------------
//------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------|
/* This file is under protection and belongs to the PA: AUN project team.                                  |
 * You may learn from this code and / or modify the source code for redistribution with proper accrediting.|
 * -NUT                                                                                                    |
 *///                                                                                                      |
//---------------------------------------------------------------------------------------------------------|

import utility.LogFile;
#if windows
import Sys.sleep;
import discord_rpc.DiscordRpc;

using StringTools;

class DiscordClient
{
    public static var daemon:sys.thread.Thread;
    public static var active:Bool = false;
    public static var ready:Bool = false;
    public function new()
    {   
        #if debug trace("Discord Client starting..."); #end
        DiscordRpc.start({
            clientID: Main.discordRPC_id,
            onReady: onReady,
            onError: onError,
            onDisconnected: onDisconnected
        });
        #if debug trace("Discord Client prepared, waiting for start..."); #end

        while (true)
        {
            DiscordRpc.process();
            sleep(2);
        }

        DiscordRpc.shutdown();
    }

    public static function shutdown()
    {
        active = false;
        ready = false;
        DiscordRpc.shutdown();
    }

    static var d:String = 'ENGINE LOADING';
    static var s:String = null;
    static var lik:String = 'icon';
    static var sik:String = '';


    //takes a sec
    static function onReady()
    {
        DiscordRpc.presence({
            details: s,
            state: d,
            largeImageKey: lik,
            largeImageText: Main.GameVersion,
            smallImageKey: sik
        });
        #if debug trace("Discord Client started."); #end
        ready = true;
    }

    static function onError(_code:Int, _message:String)
    {
        LogFile.error('Discord rich pressence Error! $_code : $_message', true, true);
    }

    static function onDisconnected(_code:Int, _message:String)
    {
        LogFile.error('Discord rich pressence disconnected! $_code : $_message', true, true);
    }

    public static function initialize()
    {
        #if debug trace("Discord Client initialized"); #end
        active = true;
        var DiscordDaemon = sys.thread.Thread.create(() ->
        {
            new DiscordClient();
        });
        daemon =DiscordDaemon;
    }

    public static function changePresence(state:Null<String>, details:String,  ?icon:String = 'icon', ?smallImageKey : String = '')
    {//funni
        if(!active)
            return;
        
        d = details;
        s = state;
        lik = icon;
        sik = smallImageKey;

        LogFile.log('Discord RPC Updated. Arguments: $details, $state, $icon, $smallImageKey\n');

        if(!ready)
            return;
        
        DiscordRpc.presence({
            details: s,
            state: d,
            largeImageKey: lik,
            largeImageText: Main.GameVersion,
            smallImageKey : sik,
        });
    }
}
#end