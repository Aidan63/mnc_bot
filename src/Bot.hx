import haxe.Json;
import cpp.asio.Result;
import haxe.io.BytesOutput;
import haxe.Http;
import sys.thread.EventLoop;
import haxe.Timer;
import sys.thread.Thread;
import steamworks.MncServerList;
import sys.thread.EventLoop.EventHandler;

using Lambda;

class Bot
{
    private static final ONE_MINUTE = 60 * 1000;

    final authentication : String;

    final thread : Thread;

    final knownServers : Map<String, KnownServer>;

    final servers : Array<Server>;

    final serverList : cpp.Pointer<MncServerList>;

    final serverRefresh : EventHandler;

    public function new(_botToken)
    {
        thread         = Thread.current();
        authentication = 'Bot $_botToken';
        knownServers   = [
            'Ice Trap Users Will Be Banned' => new KnownServer(thread.events, '1000064002476474388', 'eu-xfire'),
            'Porter on Bacon VS Popeye on Spinach' => new KnownServer(thread.events, '1000064055941267476', 'na-xfire'),
            'MNCDS - Sudden Death Blitz' => new KnownServer(thread.events, '1000066766162112512', 'eu-blitz'),
            'Wheels Wants Waves' => new KnownServer(thread.events, '1000066836831928452', 'na-blitz')
        ];
        servers       = [];
        serverList    = MncServerList.create(onServerResponse, onServerFailedToRespond, onServerRefresh);
        serverRefresh = thread.events.repeat(refresh, ONE_MINUTE);
    }

    public function shutdown()
    {
        if (serverRefresh != null)
        {
            thread.events.cancel(serverRefresh);
        }

        if (serverList != null)
        {
            serverList.destroy();
        }
    }

    function refresh()
    {
        servers.resize(0);

        serverList.ptr.refresh();
    }

    function onServerResponse(_index : Int, _players : Int, _maxPlayers : Int, _name : String, _tags : String)
    {
        servers.push(new Server(_index, _name, _players, _maxPlayers, _tags.split('!')[0]));
    }

    function onServerFailedToRespond(_index : Int)
    {
        //
    }

    function onServerRefresh(_result : Int)
    {
        if (_result == 0)
        {
            for (name => known in knownServers)
            {
                switch servers.find(server -> server.name == name)
                {
                    case null:
                        known.update(authentication, '（its-dead-jim）', null);
                    case found:
                        known.update(authentication, '（${ found.players }／${ found.maxPlayers }）', found.players);
                }
            }
        }
        else
        {
            trace('server refresh failed');
        }
    }
}

private class KnownServer
{
    private static inline final TEN_MINUTES = 600;

    final events : EventLoop;

    final prefix : String;

    final id : String;

    var queuedUpdate : Null<EventHandler>;

    var lastKnowPlayers : Null<Int>;

    var lastUpdateTime : Float;

    var updateCount : Int;

    public function new(_events, _id, _prefix)
    {
        events          = _events;
        id              = _id;
        prefix          = _prefix;
        queuedUpdate    = null;
        lastKnowPlayers = -1;
        lastUpdateTime  = Timer.stamp();
        updateCount     = 0;
    }

	public function update(_auth : String, _suffix : String, _players : Null<Int>)
    {
        if (_players == lastKnowPlayers)
        {
            return;
        }
        
        lastKnowPlayers = _players;

        if (rateLimited())
        {
            if (queuedUpdate != null)
            {
                events.cancel(queuedUpdate);
            }

            final now   = Timer.stamp();
            final delay = Math.ceil((TEN_MINUTES - (now - lastUpdateTime)) * 1000);

            queuedUpdate = events.repeat(() -> {
                send(_auth, _suffix, updateResponse);

                events.cancel(queuedUpdate);

                queuedUpdate = null;
            }, delay);
        }
        else
        {
            if (queuedUpdate != null)
            {
                trace('cancelled current update');

                events.cancel(queuedUpdate);
            }

            trace('immediate update');

            send(_auth, _suffix, updateResponse);
        }
    }

    function send(_auth : String, _suffix : String, _response : Result<Int, String>->Void)
    {
        Thread.create(() -> {
            final body    = Json.stringify({ name : prefix + _suffix });
            final output  = new BytesOutput();
            final request = new Http('https://discordapp.com/api/channels/$id');

            request.addHeader('Authorization', _auth);
            request.addHeader('Content-Type', 'application/json');
            request.setPostData(body);

            request.onStatus = (_status) -> {
                if (_status == 200)
                {
                    events.run(() -> _response(Result.Success(_status)));
                }
            }
            request.onError = (_error) -> {
                events.run(() -> _response(Result.Error(_error)));
            }

            request.customRequest(false, output, null, 'PATCH');
        });
    }

    function updateResponse(_respose : Result<Int, String>)
    {
        switch _respose
        {
            case Success(_):
                lastUpdateTime = Timer.stamp();
                updateCount++;
                trace('channel updated');
            case Error(error):
                trace('failed to update channel : $error');
        }
    }

    function rateLimited()
    {
        return updateCount >= 2 && (Timer.stamp() - lastUpdateTime) < TEN_MINUTES;
    }
}

private class Server
{
    public final index : Int;

    public final name : String;

    public final players : Int;

    public final maxPlayers : Int;

    public final gamemode : String;

	public function new(_index, _name, _players, _maxPlayers, _gamemode)
    {
		index      = _index;
		name       = _name;
		players    = _players;
		maxPlayers = _maxPlayers;
		gamemode   = _gamemode;
	}
}