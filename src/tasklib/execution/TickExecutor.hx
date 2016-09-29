package tasklib.execution;

class TickExecutor extends Executor {

	var _tasks:Array<Task<Dynamic>>;
	var _funcs:Array<Task<Dynamic> -> Void>;

	public function new() {
		_tasks = [];
		_funcs = [];

		#if flash
		flash.Lib.current.stage.addEventListener(
			flash.events.Event.ENTER_FRAME,
			function(_) {
				onTick();
			}
		);
		#end
	}

	override public function run<T>(func:Task<T> -> Void, task:Task<T>) {
		#if flash
		_tasks.push(cast task);
		_funcs.push(cast func);
		#else
		func(task);
		#end
	}

	#if flash
	function onTick() {
		if (_tasks.length > 0) {
			var t = _tasks.shift();
			var f = _funcs.shift();
			f(t);
		}
	}
	#end
}
