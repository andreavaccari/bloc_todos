import 'dart:async';

import 'package:bloc_todos/todos/todos.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'todo_bloc.g.dart';
part 'todo_event.dart';
part 'todo_state.dart';

class TodoBloc extends HydratedBloc<TodoEvent, TodoState> {
  TodoBloc({@required Todo todo, @required TodosBloc todosBloc})
      : assert(todo != null),
        assert(todosBloc != null),
        _todo = todo,
        _todosBloc = todosBloc {
    _subscription = todosBloc.listen((state) {
      if (state is TodosLoadSuccess) {
        final todo = state.todos.firstWhere(
          (element) => element.id == _todo.id,
          orElse: () => null,
        );
        if (todo != null) {
          add(TodoUpdated(todo));
        }
      }
    });
  }

  StreamSubscription<TodosState> _subscription;
  Todo _todo;
  final TodosBloc _todosBloc;

  @override
  String get id => _todo.id;

  @override
  TodoState get initialState {
    final cachedState = super.initialState;
    return cachedState != null
        ? TodoState(_merge(_todo, cachedState.todo, cachedState.invalidated))
        : TodoState(_todo);
  }

  @override
  Stream<TodoState> mapEventToState(
    TodoEvent event,
  ) async* {
    if (event is TodoTaskChanged) {
      yield _mapTodoTaskChangedToState(event, state);
    } else if (event is TodoCompleteChanged) {
      yield _mapTodoCompleteChangedToState(event, state);
    } else if (event is TodoSaved) {
      _todo = state.todo;
      _todosBloc.add(TodoSavedUpstream(state.todo));
      yield TodoState(state.todo, invalidated: true);
    } else if (event is TodoUpdated) {
      yield TodoState(
        _merge(event.todo, state.todo, state.invalidated),
        dirty: event.todo != state.todo,
      );
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  TodoState _mapTodoTaskChangedToState(TodoTaskChanged event, TodoState state) {
    final newTodo = state.todo.copyWith(task: event.task);
    return TodoState(
      newTodo,
      dirty: newTodo != _todo,
    );
  }

  TodoState _mapTodoCompleteChangedToState(
      TodoCompleteChanged event, TodoState state) {
    final newTodo = state.todo.copyWith(complete: event.complete);
    return TodoState(
      newTodo,
      dirty: newTodo != _todo,
    );
  }

  Todo _merge(Todo remote, Todo local, bool invalidated) {
    return invalidated ? remote : local;
  }

  @override
  TodoState fromJson(Map<String, dynamic> json) => TodoState.fromJson(json);

  @override
  Map<String, dynamic> toJson(TodoState state) => state.toJson();
}
