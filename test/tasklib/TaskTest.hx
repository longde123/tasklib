package tasklib;

import utest.Assert;

class TaskTest {

	public function new() {}

	public function testThenOnErroredPromise() {
		var p = new Trigger<Int>();
		var expected = 7;
		var actual = 0;
		var async = Assert.createAsync(function() {
			Assert.equals(expected, actual);
		});

		p.task.then(function(a) {
			trace("then1");
			return 1;
		}).ifError(function(e) {
			actual += 3;
			trace("ifError1");
			return null;
		});

		p.fail(2);

		p.task.then(function(a) {
			trace("then2");
			return 1;
		}).ifError(function(e) {
			actual += 4;
			trace("ifError2");
			async();
			return null;
		});
	}

	public function testSimplePipe() {
		var expected = 1;
		var actual = 0;
		var trigger1 = new Trigger<Int>();
		var trigger2 = new Trigger<Int>();
		var task1 = trigger1.task;
		var task2 = trigger2.task;
		var async = Assert.createAsync(function() {
			Assert.equals(expected, actual);
		});
		task1.pipe(function(x) {
			trigger2.resolve(expected);
			return task2;
		});
		task2.then(function(x) {
			actual = x;
			async();
		});
		trigger1.resolve(0);
	}

//	public function testPromiseUnlinkError(){
//		var p = new Promise<Int>();
//		var p2 = p.then(function(x){
//			return x + 1;
//		});
//		var expected = true;
//		var actual = false;
//		var async = Assert.createAsync(function(){
//			Assert.equals(expected,actual);
//		});
//		p.unlink(p2);
//		p.catchError(function(x){
//			actual = true;
//			async();
//		});
//	}

//	public function testEmptyWhenAll() {
//		var expected = 0;
//		var actual = 1;
//		var async = Assert.createAsync(function() {
//			Assert.equals(expected, actual);
//		});
//		Promise.whenAll([]).then(function(x) {
//			actual = x.length;
//			async();
//		});
//	}

	public function testSimpleThen() {
		var trigger1 = new Trigger<Int>();
		var task1 = trigger1.task;
		var expected = 1;
		var actual:Int = 0;
		var async = Assert.createAsync(function() {
			Assert.equals(expected, actual);
		});
		task1.then(function(x) {
			actual = x;
			async();
		});
		trigger1.resolve(expected);
	}

	public function testResolved() {
		var expected = 1;
		var actual = 0;
		var trigger = new Trigger<Int>();
		var task1 = trigger.task;
		var async = Assert.createAsync(function() {
			Assert.equals(expected, actual);
		});
		task1.then(function(x) {
			actual = x;
			async();
		});
		trigger.resolve(expected);
	}

//	public function testAsynchronousResolving() {
//		var d1 = new Trigger<Int>();
//		var p1 = d1.promise();
//		d1.resolve(0);
//		Assert.isTrue(d1.isPending(), "d1 was not resolving, should be asynchronous");
//	}
//
//	public function testSimpleWhen() {
//		var expected1 = 4;
//		var expected2 = 5;
//		var d1 = new Deferred<Int>();
//		var d2 = new Deferred<Int>();
//		var p1 = d1.promise();
//		var p2 = d2.promise();
//		var expected = expected1 + expected2;
//		var actual = 0;
//		var async = Assert.createAsync(function() {
//			Assert.equals(expected, actual);
//		});
//		var p3 = Promise.when(p1, p2).then(function(x, y) {
//			actual = x + y;
//			async();
//		});
//		d1.resolve(expected1);
//		d2.resolve(expected2);
//	}
//
//	public function testSimpleWhenError() {
//		var trigger1 = new Trigger<Int>();
//		var trigger2 = new Trigger<Int>();
//		var task1 = trigger1.task;
//		var task2 = trigger2.task;
//		var error = false;
//		var async = Assert.createAsync(function() {
//			Assert.isTrue(error);
//		});
//		Promise.when(task1, task2).then(function(x, y) {
//			throw "an error";
//		}).catchError(function(e) {
//			error = true;
//			async();
//		});
//		trigger1.resolve(0);
//		trigger2.resolve(0);
//	}

	public function errorThen() {
		var trigger1 = new Trigger<Int>();
		var task1 = trigger1.task;
		var expected = 1;
		var actual = 0;
		var async = Assert.createAsync(function() {
			Assert.equals(expected, actual);
		});
		task1.then(function(x) {
			throw true;
			return 2;
		}).ifErrorThen(function(x) {
			return 1;
		}).then(function(x) {
			actual = x;
			async();
			return 2;
		});
		trigger1.resolve(1);
	}

//	public function testSimpleWhenReject() {
//		var d1 = new Deferred<Int>();
//		var d2 = new Deferred<Int>();
//		var p1 = d1.promise();
//		var p2 = d2.promise();
//		var error = false;
//		var async = Assert.createAsync(function() {
//			Assert.isTrue(error);
//		});
//		Promise.when(p1, p2).then(function(x, y) {
//			Assert.isTrue(false, "The 'then' method should not trigger"); //or whatever make the test fail
//		}).catchError(function(e) {
//			error = true;
//			async();
//		});
//		p1.reject("error");
//		d2.resolve(0);
//	}

	public function testChainedThen() {
		var resolved1 = 1;
		var resolved2 = 2;
		var trigger1 = new Trigger<Int>();
		var task1 = trigger1.task;
		var task2 = task1.then(function(x) {
			return resolved2;
		});
		var expected = resolved2;
		var actual = 0;
		var async = Assert.createAsync(function() {
			Assert.equals(expected, actual);
		});
		task2.then(function(x) {
			actual = x;
			async();
		});
		trigger1.resolve(resolved1);
	}
//
//#if debug
//	public function testPromiseConstuctorStack(){
//
//		var p = Promise.promise('foo');
//		var endPromise = p.then(function(_) {
//			return true;
//		}).then(function(_) {
//			return true;
//		}).then(function(_) {
//			return 'end';
//		});
//
//		var async = Assert.createAsync(function(){
//			Assert.isTrue(endPromise.parentConstructorPos.exists(function(e) {
//				return e.fileName == 'TestPromise.hx' && e.lineNumber == 231;
//			}));
//			Assert.isTrue(endPromise.parentConstructorPos.exists(function(e) {
//				return e.fileName == 'TestPromise.hx' && e.lineNumber == 232;
//			}));
//		});
//		endPromise.then(function(x){
//			var actual = x;
//			async();
//		});
//	}
//#end

}
