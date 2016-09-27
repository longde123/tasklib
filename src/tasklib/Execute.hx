package tasklib;

class Execute {

	public static var IMMEDIATELY:Execute = new Execute();

	public function new() {}

	public function run<T>(func:Task<T> -> Void, task:Task<T>) {
		func(task);
	}
}