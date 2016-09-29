package tasklib;

import tasklib.execution.Executor;

@:access(tasklib.Trigger)
class Task<T> {

	var _state:State;
	var _data:Dynamic;
	var _executors:Array<Executor>;
	var _next:Array<Task<T> -> Void>;

	#if debug
	var _pos:haxe.PosInfos;
	var _uid:Int = 0;
	static var NEXT_UID:Int = 0;
	#end

	inline function new(state:State, data:Dynamic #if debug , ?pos:haxe.PosInfos #end) {
		_state = state;
		_data = data;
		if (state == State.PENDING) {
			_executors = [];
			_next = [];
		}
		#if debug
		_pos = pos;
		_uid = ++NEXT_UID;
		#end
	}

	public function ifSuccess<R>(continuation:T -> Task<R>, ?execute:Executor):Task<R> {
		if (continuation == null) throw "null argument";

		var trigger = new Trigger<R>();

		function future(source:Task<T>) {
			if (source._state == State.SUCCESS) {
				trigger.fire(continuation(source.__unsafeResult()));
			}
		}

		return addContinuation(trigger.task, execute, future);
	}

	public function ifError<R>(continuation:Dynamic -> Task<R>, ?execute:Executor):Task<R> {
		if (continuation == null) throw "null argument";

		var trigger = new Trigger<R>();

		function future(source:Task<T>) {
			if (source._state == State.FAILED) {
				trigger.fire(continuation(source._data));
			}
		}

		return addContinuation(trigger.task, execute, future);
	}

	/**
		Full handle: Task -> Task
	**/

	public function thenTask<R>(continuation:Task<T> -> Task<R>, ?execute:Executor #if debug , ?pos:haxe.PosInfos #end):Task<R> {
		if (continuation == null) throw "null argument";

		var trigger = new Trigger<R>(#if debug pos #end);

		return addContinuation(
			trigger.task,
			execute,
			function(source:Task<T>) {
				#if tasklib_trace
				trace("thenTask future: " + source.toString());
				#end
				trigger.fire(continuation(source));
			}
		);
	}

	/**
		Success( Func(x) ) -> Success(y)
		Failed(e) -> Failed(e)
	**/

	public function then<R>(continuation:T -> R, ?execute:Executor):Task<R> {
		if (continuation == null) throw "null argument";

		var trigger = new Trigger<R>();

		function future(source:Task<T>) {
			trigger.fire(source._state == State.SUCCESS ? Task.forResult(continuation(source.__unsafeResult())) : (cast source));
		}

		return addContinuation(trigger.task, execute, future);
	}

	/**
		Success( Func(x) ) -> Pending
		Failed(e) -> Failed(e)
	**/

	public function pipe<R>(continuation:T -> Task<R>, ?execute:Executor #if debug , ?pos:haxe.PosInfos #end):Task<R> {
		if (continuation == null) throw "null argument";

		var trigger = new Trigger<R>(#if debug pos #end);
		var self = this;

		return addContinuation(
			trigger.task,
			execute,
			function(source:Task<T>) {
				#if tasklib_trace
				trace("pipe future: " + source.toString());
				#end
				trigger.fire(source._state == State.SUCCESS ? continuation(source.__unsafeResult()) : (cast source));
			}
		);
	}

	/**
		Transform Error to Success

		Error(Func(e)) -> Success(x)
	**/

	public function ifErrorThen(continuation:Dynamic -> T, ?execute:Executor):Task<T> {
		if (continuation == null) throw "null argument";

		var trigger = new Trigger<T>();

		function future(source:Task<T>) {
			trigger.fire(
				source._state == State.FAILED ? Task.forResult(continuation(source._data)) : source
			);
		}

		return addContinuation(trigger.task, execute, future);
	}

	/**
		Add side-callback for success result
		Returns current Task
	**/

	public function tap(callback:T -> Void, ?execute:Executor):Task<T> {
		if (callback == null) throw "null argument";

		return addContinuation(this, execute, function(source:Task<T>) {
			if (source._state == State.SUCCESS) {
				callback(source.__unsafeResult());
			}
		});
	}

	inline public static function forResult<T>(result:T #if debug , ?pos:haxe.PosInfos #end):Task<T> {
		return new Task<T>(State.SUCCESS, result #if debug , pos #end);
	}

	inline public static function forError<T>(error:Dynamic #if debug , ?pos:haxe.PosInfos #end):Task<T> {
		return new Task<T>(State.FAILED, error #if debug , pos #end);
	}

	inline public static function cancelled<T>(reason:String #if debug , ?pos:haxe.PosInfos #end):Task<T> {
		return new Task<T>(State.CANCELLED, reason #if debug , pos #end);
	}

	inline public static function nothing(#if debug ?pos:haxe.PosInfos #end):Task<Nothing> {
		return new Task<Nothing>(State.SUCCESS, null #if debug , pos #end);
	}

	public function toString() {
		var str = switch(_state) {
			case State.PENDING: 'Task(Pending)';
			case State.FAILED: 'Task(Failed(${Std.string(_data)}))';
			case State.SUCCESS: 'Task(Success(${Std.string(_data)}))';
			case State.CANCELLED: 'Task(Cancelled(${Std.string(_data)}))';
		};
		#if debug
		str += "#" + _uid + " >> " + _pos.fileName + ":" + _pos.lineNumber + " " + _pos.methodName;
		#end
		return str;
	}

	function addContinuation<R>(resultTask:Task<R>, executor:Executor, future:Task<T> -> Void):Task<R> {
		if (executor == null) {
			executor = Execute.DEFAULT;
		}

		if (_state == State.PENDING) {
			_executors.push(executor);
			_next.push(future);
		}
		else {
			executor.run(future, this);
		}

		return resultTask;
	}

	function continueExecution() {
		#if tasklib_trace
		trace('Continuation: ${toString()}');
		#end
		for (i in 0..._executors.length) {
			#if tasklib_trace
			trace('C. #$i');
			#end
			_executors[i].run(_next[i], this);
		}
		_next = null;
		_executors = null;
	}

	public function getResult():T {
		if (_state != State.SUCCESS) throw "Cannot get result from task: " + toString();
		return __unsafeResult();
	}

	public function getError():Dynamic {
		if (_state != State.FAILED) throw "Cannot get error from task: " + toString();
		return _data;
	}

	public function getCancelledReason():String {
		if (_state != State.CANCELLED) throw "Cannot get cancelled reason from task: " + toString();
		return Std.string(_data);
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
				trigger.fire(resultTask);
			}
			return null;
		});
	}

	public function delay(seconds:Float):Task<T> {
		if (seconds < 0) throw "invalid argument";

		var trigger = new Trigger<T>();

		function future(source:Task<T>) {
			#if (flash||js)
			haxe.Timer.delay(function() {
				trigger.fire(source);
			}, Std.int(seconds * 1000));
			#else
			trigger.fire(source);
			#end
		}

		return addContinuation(trigger.task, Execute.DEFAULT, future);
	}

	public static function waitAll(list:Array<Task<Dynamic>>):Task<Nothing> {
		var trigger = new Trigger<Nothing>();
		var total = list.length;
		if (total == 0) {
			trigger.resolve(null);
		}
		else {
			for (i in 0...list.length) {
				list[i].thenTask(function(_) {
					--total;
					if (total <= 0) {
						trigger.resolve(null);
					}
					return null;
				});
			}
		}
		return trigger.task;
	}

	@:extern inline function __unsafeResult():T {
		return cast _data;
	}
}