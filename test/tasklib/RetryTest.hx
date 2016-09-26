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
			Assert.pass("yeah");
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
			Assert.pass("yeah");
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

		function d0() {
			var value = Std.int(1000 * Math.random());
			var failed = Math.random() < failRate;
			if (failed) {
				trigger.fail("Failed to read universe values");
			}
			else {
				trigger.resolve(value);
			}
		}

		#if (flash||js)
		haxe.Timer.delay(d0, 2);
		#else
		d0();
		#end

		return trigger.task;
	}
}
