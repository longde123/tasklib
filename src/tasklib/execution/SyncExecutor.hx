package tasklib.execution;

class SyncExecutor extends Executor {

	public function new() {}

	override public function run<T>(func:Task<T> -> Void, task:Task<T>) {
		func(task);
	}
}
