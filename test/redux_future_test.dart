import 'dart:async';

import 'package:redux/redux.dart';
import 'package:test/test.dart';
import 'package:redux_future/redux_future.dart';

main() {
  group('Future Middleware', () {
    String futureReducer(String state, action) {
      if (action is String) {
        return action;
      } else if (action is FutureFulfilledAction<String>) {
        return action.result;
      } else if (action is FutureRejectedAction<Exception>) {
        return action.error.toString();
      } else {
        return state;
      }
    }

    test('is a Redux Middleware', () {
      expect(futureMiddleware, isA<Middleware>());
    });

    group('FutureAction', () {
      test('can synchronously dispatch an initial action', () {
        final store = Store<String>(
          futureReducer,
          middleware: [futureMiddleware],
          initialState: '',
        );
        final action = FutureAction(
          Future<String>.value("Fetch Complete"),
          initialAction: "Fetching",
        );

        store.dispatch(action);

        expect(store.state, action.initialAction);
      });

      test(
          'dispatches a FutureFulfilledAction if the future completes successfully',
          () async {
        final store = Store<String>(
          futureReducer,
          middleware: [futureMiddleware],
          initialState: '',
        );
        final dispatchedAction = "Friend";
        final future = Future.value(dispatchedAction);
        final action = FutureAction(
          future,
          initialAction: "Hi",
        );

        store.dispatch(action);

        await future;

        expect(store.state, dispatchedAction);
      });

      test('dispatches a FutureRejectedAction if the future returns an error',
          () {
        final store = Store<String>(
          futureReducer,
          middleware: [futureMiddleware],
          initialState: '',
        );
        final exception = Exception("Error Message");
        final future = Future.error(exception);
        final action = FutureAction(
          future,
          initialAction: "Hi",
        );

        store.dispatch(action);

        expect(
          future.catchError((_) => store.state),
          completion(contains(exception.toString())),
        );
      });

      test('returns the result of the Future after it has been dispatched',
          () async {
        final store = Store<String>(
          futureReducer,
          middleware: [futureMiddleware],
          initialState: '',
        );
        final dispatchedAction = "Friend";
        final future = Future.value(dispatchedAction);
        final action = FutureAction(
          future,
          initialAction: "Hi",
        );

        store.dispatch(action);

        expect(
          await action.result,
          FutureFulfilledAction(dispatchedAction),
        );
      });

      test('returns the error of the Future after it has been dispatched',
          () async {
        final store = Store<String>(
          futureReducer,
          middleware: [futureMiddleware],
          initialState: '',
        );
        final exception = Exception("Khaaaaaaaaaan");
        final future = Future.error(exception);
        final action = FutureAction(
          future,
          initialAction: "Hi",
        );

        store.dispatch(action);

        expect(
          await action.result,
          FutureRejectedAction(exception),
        );
      });

      test('dispatchs initial action through Store.dispatch', () async {
        List<String> logs = <String>[];
        void loggingMiddleware<State>(Store<State> store, dynamic action, NextDispatcher next) {
          logs.add(action.toString());
          next(action);
        }

        final store = Store<String>(
          futureReducer,
          middleware: [loggingMiddleware, futureMiddleware],
          initialState: '',
        );
        final action = FutureAction(
          Future.value("Friend"),
          initialAction: "Hi",
        );

        store.dispatch(action);

        final fulfilledAction = await action.result;

        expect(logs, <String>[
          action.toString(),
          "Hi",
          fulfilledAction.toString(),
        ]);
      });
    });

    group('Future', () {
      test(
          'dispatches a FutureFulfilledAction if the future completes successfully',
          () async {
        final store = Store<String>(
          futureReducer,
          middleware: [futureMiddleware],
          initialState: '',
        );
        final dispatchedAction = "Friend";
        final future = Future.value(dispatchedAction);

        store.dispatch(future);

        await future;

        expect(store.state, dispatchedAction);
      });

      test('dispatches a FutureRejectedAction if the future returns an error',
          () {
        final store = Store<String>(
          futureReducer,
          middleware: [futureMiddleware],
          initialState: '',
        );
        final exception = Exception("Error Message");
        final future = Future.error(exception);

        store.dispatch(future);

        expect(
          future.catchError((_) => store.state),
          completion(contains(exception.toString())),
        );
      });
    });
  });
}
