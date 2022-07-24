import haxe.io.Path;
import haxe.Exception;
import sys.thread.Thread;
import steamworks.Steamworks;

class Main
{
	static function main()
	{
		if (Steamworks.init())
		{
			cpp.asio.Signal.open(result -> {
				switch result
				{
					case Success(signal):
						final thread = Thread.current();
						final swPump = thread.events.repeat(() -> Steamworks.pump(), 100);
						final bot    = new Bot(sys.io.File.getContent(Path.join([ Path.directory(Sys.programPath()), 'token.txt' ])));

						signal.start(Interrupt, result -> {
							switch result
							{
								case Success(_):
									bot.shutdown();
	
									thread.events.cancel(swPump);
	
									Steamworks.shutdown();
	
									signal.close();
								case Error(error):
									throw new Exception('Unable to listen for interrupt exception : $error');
							}
						});
					case Error(error):
						throw new Exception('Unable to open signal : $error');
				}
			});	
		}
		else
		{
			throw new Exception('failed to init steam');
		}
	}
}
