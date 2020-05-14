use "collections"

interface ReadablePushNotify[R: Any #send]
  fun ref throttled()
  fun ref unthrottled()
  fun ref data(data': R)
  fun ref readable()
  fun ref unpipe(notify: WriteablePushNotify tag)
  fun ref exception(message: String)
  fun ref finished()

interface ReadablePushStream[R: Any #send]
  fun readable(): Bool
  fun _destroyed(): Bool
  fun ref piped(): Bool =>
    let notify: (WriteablePushNotify tag | None) = _pipeNotify()
    match notify
      | let notify': WriteablePushNotify tag => true
      else
        false
    end
  fun ref _pipeNotify(): (WriteablePushNotify tag | None)
  fun ref _readSubscribers() : MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]]
  fun ref _notifyException(message: String) =>
    let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()
    for notify in readSubscribers.values() do
      notify.exception(message)
    end
  fun ref _notifyReadable() =>
    if readable() then
      let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()
      for notify in readSubscribers.values() do
        notify.readable()
      end
    end
  fun ref _subscribeRead(notify: ReadablePushNotify[R] iso) =>
    let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()
    if readSubscribers.size() >= 1 then
      let notify': ReadablePushNotify[R] ref = consume notify
      notify'.exception("Stream has multiple subscribers")
    else
      let notify': ReadablePushNotify[R] ref = consume notify
      readSubscribers(notify') = notify'
    end
    if readable() then
      _notifyReadable()
    end
  fun ref _unsubscribeRead(notify: ReadablePushNotify[R] tag) =>
    let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()
    try
      readSubscribers.remove(notify)?
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
  be push()
  be read(size:(USize | None) = None, cb: {(R)} val)
  be subscribeRead(notify: ReadablePushNotify[R] iso) =>
    _subscribeRead(consume notify)
    if ((_readSubscribers().size() == 1) and (not piped()) and readable()) then
      push()
    end
  be unsubscribeRead(notify: ReadablePushNotify[R] tag) =>
    _unsubscribeRead(notify)

  be pipe(stream: WriteablePushStream[R] tag)/* =>
    let notify: WriteablePushNotify[R] iso = WriteablePushNotify[R]
    stream.piped(stream, consume notify)
  */
  fun ref _notifyUnpipe() =>
    match _pipeNotify()
    | let pipeNotify: WriteablePushNotify tag =>
        let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()
        for notify in readSubscribers.values() do
          notify.unpipe(pipeNotify)
        end
    end
  be unpipe() =>
    if piped() then
      _notifyUnpipe()
    end
    let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()
    readSubscribers.clear()

  be destroy(message: String) =>
    _notifyException(message)
