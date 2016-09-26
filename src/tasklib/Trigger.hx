package tasklib;

@:access(tasklib.Task)
abstract Trigger<T>(Task<T>) {

	public var task(get, never):Task<T>;

	inline public function new(#if debug ?pos:haxe.PosInfos #end) {
		this = new Task<T>(State.PENDING, null #if debug , pos #end);
	}

	public function resolve(result:T) {
		if(this._state != State.PENDING) throw "Cannot resolve completed task: " + this.toString();

		this._data = result;
		this._state = State.SUCCESS;
		this.continueExecution();
	}

	public function fail(error:Dynamic) {
		if(this._state != State.PENDING) throw "Cannot fail completed task: " + this.toString();

		this._data = error;
		this._state = State.FAILED;
		this.continueExecution();
	}

	public function cancel(reason:Dynamic) {
		if(this._state != State.PENDING) throw "Cannot cancel completed task: " + this.toString();

		this._data = reason;
		this._state = State.CANCELLED;
		this.continueExecution();
	}

	function resolveFrom<TPrev>(task:Task<TPrev>):Task<Nothing> {
		if(task == null) {
			resolve(null);
		}
		else if(task._state == State.PENDING) throw "Task should be completed: " + this.toString();
		else {
			this._state = task._state;
			this._data = task._data;
			this.continueExecution();
		}
		return null;
	}

	function pipeFrom<TPrev>(task:Task<TPrev>) {
		if(task == null) {
			resolve(null);
		}
		else {
			task.thenTask(resolveFrom);
		}
	}

	inline function get_task():Task<T> {
		return this;
	}
}
