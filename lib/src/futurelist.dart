part of persist;

/**
 * Keeps a list of futures and associated functions which are executed
 * when each future completes. 
 */
class FutureList {
  List<Future> _futures;
  
  FutureList() : _futures = new List<Future>();
  
  void add(Future future, Function onSuccess) {
    Completer c = new Completer();
    future.then((x) {
      onSuccess(x);
      c.complete(x);
    });
    _futures.add(c.future);
  }
  
  
  Future<List> wait() {
    return Future.wait(_futures);
  }
}

