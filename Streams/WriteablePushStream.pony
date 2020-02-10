use "collections"

interface WriteablePushNotify
  fun ref throttled()
  fun ref unthrottled()
  fun ref piped()
  fun ref unpiped()
  fun ref exception(message: String)


interface WriteablePushStream[W: Any #send]
  fun ref _writeSubscribers() : MapIs[WriteablePushNotify tag, WriteablePushNotify]
  fun ref _subscribeWrite(notify: WriteablePushNotify iso) =>
    let writeSubscribers: MapIs[WriteablePushNotify tag, WriteablePushNotify] = _writeSubscribers()
    let notify': WriteablePushNotify ref = consume notify
    writeSubscribers(notify') = notify'
  fun ref _notifyException(message: String) =>
    let writeSubscribers: MapIs[WriteablePushNotify tag, WriteablePushNotify] = _writeSubscribers()
    for notify in writeSubscribers.values() do
      notify.exception(message)
    end
  fun ref _notifyPiped() =>
    let writeSubscribers: MapIs[WriteablePushNotify tag, WriteablePushNotify] = _writeSubscribers()
    for notify in writeSubscribers.values() do
      notify.piped()
    end
  be subscribeWrite(notify: WriteablePushNotify iso) =>
    _subscribeWrite(consume notify)
  be write(data: W) =>
    None
  be piped(stream: ReadablePushStream[W] tag, notify: WriteablePushNotify iso) /* =>
    _subscribeWrite(consume notify)
    let notify': ReadablePushNotify[W] iso = ReadablePushNotify[W]
    stream.subscribeRead(consume notify')
    _notifyPiped()
  */
  be destroy(message: String) =>
    _notifyException(message)
