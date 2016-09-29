package tasklib;

import tasklib.execution.TickExecutor;
import tasklib.execution.SyncExecutor;
import tasklib.execution.Executor;

@:final
class Execute {

	public static var DEFAULT(get, null):Executor;
	public static var SYNC(get, null):Executor;
	public static var TICK(get, null):Executor;

	static function get_SYNC() {
		if(SYNC == null) {
			SYNC = new SyncExecutor();
		}
		return SYNC;
	}

	static function get_TICK() {
		if(TICK == null) {
			TICK = new TickExecutor();
		}
		return TICK;
	}

	static function get_DEFAULT() {
		return get_TICK();
	}
}