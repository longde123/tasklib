package tasklib;

import utest.Assert;

class ParseIntTest {

	public function new() {}

	public function testParsing() {

		var expected = 2;
		var actual = 0;
		var done = Assert.createAsync(function() {
			Assert.equals(expected, actual);
		});

		var trigger = new Trigger<String>();

		trigger.task
		.pipe(ensureStringValue)
		.pipe(parseInt)
		.thenTask(traceTask)
		.ifSuccess(function(x) {
			actual = x;
			return Task.forResult(x);
		})
		.thenTask(function(t) {
			done();
			return null;
		});

		trigger.resolve("2");
	}

	public function testParse1() {

		var expected = 2;
		var actual = 0;
		var done = Assert.createAsync(function() {
			Assert.equals(expected, actual);
		});

		parseIntAsync("2")
		.then(function(x) {
			return actual = x;
		})
		.thenTask(function(_) {
			done();
			return null;
		});
	}

	public function testParseError() {

		var expected = 0;
		var actual = 0;
		var done = Assert.createAsync(function() {
			Assert.equals(expected, actual);
		});

		parseIntAsync("--")
		.then(function(x) {
			return actual = x;
		})
		.thenTask(function(_) {
			done();
			return null;
		});
	}

	static function traceTask<T>(task:Task<T>):Task<T> {
		trace(task.toString());
		return task;
	}

	static public function parseInt(string:String):Task<IntObject> {
		var value = Std.parseInt(string);
		if(value == null) {
			return Task.forError('Cannot parse Int: $string');
		}
		return Task.forResult(value);
	}

	static public function ensureStringValue(string:String):Task<String> {
		return (string != null && string.length > 0) ?
		Task.forResult(string) :
		Task.forError("Empty string");
	}

	static public function parseIntAsync(text:String):Task<IntObject> {
		return Task.forResult(text)
			.pipe(ensureStringValue)
			.pipe(parseInt);
	}
}

typedef IntObject = Null<Int>;