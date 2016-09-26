package tasklib;

@:enum
abstract State(Int) from Int to Int {
	var PENDING = 0;
	var SUCCESS = 1;
	var FAILED = 2;
	var CANCELLED = 3;
}