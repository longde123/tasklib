package tasklib;

import haxe.Timer;
import utest.Assert;

class RetryTest {
	public function new() {}

	public function testRetry() {
		var done = Assert.createAsync(function() {

		});
		Task.retry(function() {
			trace("Try..");
			return outRandom(0.1);
		}, 5)
		.ifSuccess(function(_) {
			done();
			return null;
		});
	}

	public function testRetryAsync() {
		var done = Assert.createAsync(function() {

		});
		Task.retry(function() {
			trace("Try..");
			return outRandomAsync(1);
		}, 5)
		.ifError(function(_) {
			done();
			return null;
		});
	}

	public function outRandom(failRate:Float = 0.5):Task<Int> {
		var value = Std.int(1000 * Math.random());
		var failed = Math.random() < failRate;
		return failed ? Task.forError("Failed to read universe values") : Task.forResult(value);
	}

	public function outRandomAsync(failRate:Float = 0.5):Task<Int> {
		var trigger = new Trigger<Int>();

		Timer.delay(function() {
			var value = Std.int(1000 * Math.random());
			var failed = Math.random() < failRate;
			if (failed) {
				trigger.fail("Failed to read universe values");
			}
			else {
				trigger.resolve(value);
			}
		}, 2);

		return trigger.task;
	}
}
