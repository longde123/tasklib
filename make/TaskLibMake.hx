import hxmake.haxelib.HaxelibExt;
import hxmake.test.TestTask;
import hxmake.idea.IdeaPlugin;
import hxmake.haxelib.HaxelibPlugin;

using hxmake.haxelib.HaxelibPlugin;

class TaskLibMake extends hxmake.Module {

	function new() {
		config.classPath = ["src"];
		config.testPath = ["test"];
		config.devDependencies = [
			"utest" => "haxelib"
		];

		apply(HaxelibPlugin);
		apply(IdeaPlugin);

		library(function (ext:HaxelibExt) {
			ext.config.description = "Slim task-based programming";
			ext.config.contributors = ["eliasku"];
			ext.config.url = "https://github.com/eliasku/tasklib";
			ext.config.license = "MIT";
			ext.config.version = "0.0.1";
			ext.config.releasenote = "Initial release";
			ext.config.tags = ["continuation", "async", "task", "cross", "lightweight", "common"];

			ext.pack.includes = ["src", "haxelib.json", "README.md"];
		});

		var testTask = new TestTask();
		testTask.targets = ["neko", "swf", "js", "cpp", "java", "php", "cs", "node"];
		testTask.libraries = ["tasklib"];
		task("test", testTask);
	}
}