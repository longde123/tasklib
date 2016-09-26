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
		.thenTask(traceResult)
		.ifSuccess(function(x:Int) {
			actual = x;
			return Task.forResult(x);
		})
		.thenTask(function(_) {
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

	static function traceResult<T>(task:Task<T>):Task<T> {
		trace(task.toString());
		return task;
	}

	static public function parseInt(string:String):Task<Int> {
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

	static public function parseIntAsync(text:String):Task<Int> {
		return Task.forResult(text)
			.pipe(ensureStringValue)
			.pipe(parseInt);
	}
}
