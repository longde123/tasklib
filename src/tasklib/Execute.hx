package tasklib;

class Execute {

	public static var IMMEDIATELY:Execute = new Execute();

	public function new() {}

	public function run(func:Void -> Void) {
		func();
	}
}