package tasklib;

@:access(tasklib.Trigger)
class Task<T> {

	var _state:State;
	var _data:Dynamic;
	var _executors:Array<Execute>;
	var _next:Array<Void -> Void>;

	inline function new(state:State, data:Dynamic) {
		_data = data;
		_state = state;
		if(state == State.PENDING) {
			_executors = [];
			_next = [];
		}
	}

	public function ifSuccess<R>(continuation:T -> Task<R>, ?execute:Execute):Task<R> {
		if (continuation == null) throw "null argument";

		var trigger = new Trigger<R>();

		function future() {
			if (_state == State.SUCCESS) {
				trigger.pipeFrom(continuation(cast _data));
			}
		}

		return addContinuation(trigger.task, execute, future);
	}

	public function ifError<R>(continuation:Dynamic -> Task<R>, ?execute:Execute):Task<R> {
		if (continuation == null) throw "null argument";

		var trigger = new Trigger<R>();

		function future() {
			if (_state == State.FAILED) {
				trigger.pipeFrom(continuation(_data));
			}
		}

		return addContinuation(trigger.task, execute, future);
	}

	/**
		Full handle: Task -> Task
	**/
	public function thenTask<R>(continuation:Task<T> -> Task<R>, ?execute:Execute):Task<R> {
		if (continuation == null) throw "null argument";

		var trigger = new Trigger<R>();

		function future() {
			trigger.pipeFrom(continuation(this));
		}

		return addContinuation(trigger.task, execute, future);
	}

	/**
		Success( Func(x) ) -> Success(y)
		Failed(e) -> Failed(e)
	**/

	public function then<R>(continuation:T -> R, ?execute:Execute):Task<R> {
		if (continuation == null) throw "null argument";

		var trigger = new Trigger<R>();

		function future() {
			if(_state == State.SUCCESS) {
				trigger.pipeFrom(Task.forResult(continuation(cast _data)));
			}
			else {
				trigger.pipeFrom(this);
			}
		}

		return addContinuation(trigger.task, execute, future);
	}

	/**
		Success( Func(x) ) -> Pending
		Failed(e) -> Failed(e)
	**/

	public function pipe<R>(continuation:T -> Task<R>, ?execute:Execute):Task<R> {
		if (continuation == null) throw "null argument";

		var trigger = new Trigger<R>();

		function future() {
			trigger.pipeFrom(
				_state == State.SUCCESS ?
				continuation(cast _data) :
				cast this
			);
		}

		return addContinuation(trigger.task, execute, future);
	}

	/**
		Transform Error to Success

		Error(Func(e)) -> Success(x)
	**/

	public function ifErrorThen(continuation:Dynamic -> T, ?execute:Execute):Task<T> {
		if (continuation == null) throw "null argument";

		var trigger = new Trigger<T>();

		function future() {
			trigger.pipeFrom(
				_state == State.FAILED ?
				Task.forResult(continuation(_data)) :
				this
			);
		}

		return addContinuation(trigger.task, execute, future);
	}

	/**
		Add side-callback for success result
		Returns current Task
	**/
	public function tap(callback:T -> Void, ?execute:Execute):Task<T> {
		if (callback == null) throw "null argument";

		return addContinuation(this, execute, function() {
			if(_state == State.SUCCESS) {
				callback(cast _data);
			}
		});
	}

	inline public static function forResult<T>(result:Null<T>):Task<T> {
		return new Task<T>(State.SUCCESS, result);
	}

	inline public static function forError<T>(error:Dynamic):Task<T> {
		return new Task<T>(State.FAILED, error);
	}

	inline public static function cancelled<T>(reason:String):Task<T> {
		return new Task<T>(State.CANCELLED, reason);
	}

	inline public static function nothing():Task<Nothing> {
		return new Task<Nothing>(State.SUCCESS, null);
	}

	public function toString() {
		return switch(_state) {
			case State.PENDING: 'Task(Pending)';
			case State.FAILED: 'Task(Failed(${Std.string(_data)}))';
			case State.SUCCESS: 'Task(Success(${Std.string(_data)}))';
			case State.CANCELLED: 'Task(Cancelled(${Std.string(_data)}))';
		};
	}

	function addContinuation<R>(resultTask:Task<R>, executor:Execute, future:Void -> Void):Task<R> {
		if (executor == null) {
			executor = Execute.IMMEDIATELY;
		}

		if (_state == State.PENDING) {
			_executors.push(executor);
			_next.push(future);
		}
		else {
			executor.run(future);
		}

		return resultTask;
	}

	function continueExecution() {
		for (i in 0..._executors.length) {
			_executors[i].run(_next[i]);
		}
		_next = null;
		_executors = null;
	}

	public function getResult():T {
		if(_state != State.SUCCESS) throw "Cannot get result from task: " + toString();
		return cast _data;
	}

	public function getError():Dynamic {
		if(_state != State.FAILED) throw "Cannot get error from task: " + toString();
		return _data;
	}

	public function getCancelledReason():String {
		if(_state != State.CANCELLED) throw "Cannot get cancelled reason from task: " + toString();
		return cast _data;
	}

	public static function retry<T>(block:Void -> Task<T>, count:Int = 5):Task<T> {
		var trigger = new Trigger<T>();
		retryBody(block, trigger, count);
		return trigger.task;
	}

	static function retryBody<T>(block:Void -> Task<T>, trigger:Trigger<T>, count:Int) {
		block()
		.thenTask(function(resultTask:Task<T>) {
			if (resultTask._state == State.FAILED && count > 0) {
				retryBody(block, trigger, count - 1);
			}
			else {
				trigger.pipeFrom(resultTask);
			}
			return null;
		});
	}

	public function delay(seconds:Float):Task<T> {
		if (seconds < 0) throw "invalid argument";

		var trigger = new Trigger<T>();

		function future() {
			#if (flash||js)
			haxe.Timer.delay(trigger.pipeFrom.bind(this), Std.int(seconds * 1000));
			#else
			trigger.pipeFrom(this);
			#end
		}

		return addContinuation(trigger.task, Execute.IMMEDIATELY, future);
	}

	public static function waitAll(list:Array<Task<Dynamic>>):Task<Nothing> {
		var trigger = new Trigger<Nothing>();
		var total = list.length;
		for(i in 0...list.length) {
			list[i].thenTask(function(_) {
				--total;
				if(total <= 0) {
					trigger.resolve(null);
				}
				return null;
			});
		}
		if(total == 0) {
			trigger.resolve(null);
		}
		return trigger.task;
	}
}