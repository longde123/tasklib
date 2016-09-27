# tasklib

Slim task-based library for Haxe

Work in progress...

## Exceptions

`Task.forError` / `Task.ifError` are used for rejection and errors handling.

All exceptions will be throw loudly and not muted by task execution.

## C# Specifics

Avoid usage of ValueType generic types for Task<T> to increase cross-platform compatibility.

For example to wrap Int `typedef IntObject = Null<Int>;` would be enough.

## Options

- `-debug`: generates uid for each task, track additional position information for created tasks/triggers
- `-D tasklib_trace` enables tracing of tasks execution
