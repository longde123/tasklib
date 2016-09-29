package tasklib.execution;

class Executor {
	public function run<T>(func:Task<T> -> Void, task:Task<T>) {}
}
