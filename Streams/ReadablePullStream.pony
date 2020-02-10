/*
interface ReadablePullNotify[R: Any #send]
  fun ref throttled()
  fun ref unthrottled()
  fun ref data(data': R)
  fun ref readable()
  fun ref exception(message: String)
  fun ref finished()

interface ReadablePullStream[R: Any #send]
  fun readable(): Bool
  fun piped(): Bool
  fun ref _readSubscribers() : MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]]
  fun ref _notifyException(message: String) =>
    let readSubscribers: MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]] = _readSubscribers()
    for notify in readSubscribers.values() do
      notify.exception(message)
    end
  fun ref _subscribeRead(notify: ReadablePullNotify[R] iso) =>
    let readSubscribers: MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]] = _readSubscribers()
    if _readSubscribers().size() >= 1 then
      let notify': ReadablePullNotify[R] ref = consume notify
      notify'.exception("Stream has multiple subscribers")
    else
      let notify': ReadablePullNotify[R] ref = consume notify
      readSubscribers(notify') = notify'
    end
  fun ref _notifyData(data: R) =>
    let readSubscribers: MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]] = _readSubscribers()

    var notify: (ReadablePullNotify[R] | None) =  None
    for notify' in readSubscribers.values() do
      notify = notify'
      break
    end
    match notify
      | let notify': ReadablePullNotify[R] =>
        notify'.data(consume data)
    end
  fun ref _notifyFinished() =>
    let readSubscribers: MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]] = _readSubscribers()
    for notify in readSubscribers.values() do
      notify.finished()
    end
    readSubscribers.clear()
  be _read()
  be pull()
  be subscribeRead(notify: ReadablePullNotify[R] iso) =>
    _subscribeRead(consume notify)
    if ((_readSubscribers().size() == 1) and (not piped()) and readable()) then
      _read()
    end
  be pipe(stream: WriteablePullStream[R] tag)/* =>
    let notify: WriteablePushNotify[R] iso = WriteablePushNotify[R]
    stream.piped(stream, consume notify)
  */
  be destroy(message: String) =>
    _notifyException(message)
*/
