use "collections"

interface ReadablePushNotify[R: Any #send]
  fun ref throttled()
  fun ref unthrottled()
  fun ref data(data': R)
  fun ref readable()
  fun ref exception(message: String)
  fun ref finished()

interface ReadablePushStream[R: Any #send]
  fun readable(): Bool
  fun piped(): Bool
  fun ref _readSubscribers() : MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]]
  fun ref _notifyException(message: String) =>
    let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()
    for notify in readSubscribers.values() do
      notify.exception(message)
    end
  fun ref _subscribeRead(notify: ReadablePushNotify[R] iso) =>
    let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()
    if _readSubscribers().size() >= 1 then
      let notify': ReadablePushNotify[R] ref = consume notify
      notify'.exception("Stream has multiple subscribers")
    else
      let notify': ReadablePushNotify[R] ref = consume notify
      readSubscribers(notify') = notify'
    end
  fun ref _notifyData(data: R) =>
    let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()

    var notify: (ReadablePushNotify[R] | None) =  None
    for notify' in readSubscribers.values() do
      notify = notify'
      break
    end
    match notify
      | let notify': ReadablePushNotify[R] =>
        notify'.data(consume data)
    end
  fun ref _notifyFinished() =>
    let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()
    for notify in readSubscribers.values() do
      notify.finished()
    end
    readSubscribers.clear()
  be _read()
  be subscribeRead(notify: ReadablePushNotify[R] iso) =>
    _subscribeRead(consume notify)
    if ((_readSubscribers().size() == 1) and (not piped()) and readable()) then
      _read()
    end
  be pipe(stream: WriteablePushStream[R] tag)/* =>
    let notify: WriteablePushNotify[R] iso = WriteablePushNotify[R]
    stream.piped(stream, consume notify)
  */
  be destroy(message: String) =>
    _notifyException(message)
