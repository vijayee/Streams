use "collections"
interface ReadablePullNotify[R: Any #send]
  fun ref throttled()
  fun ref unthrottled()
  fun ref data(data': R)
  fun ref readable()
  fun ref piped()
  fun ref unpiped()
  fun ref exception(message: String)
  fun ref finished()

  interface ReadablePullStream[R: Any #send]
    fun readable(): Bool
    fun _destroyed(): Bool
    fun ref _readSubscribers() : MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]]
    fun ref _notifyException(message: String) =>
      let readSubscribers: MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]] = _readSubscribers()
      for notify in readSubscribers.values() do
        notify.exception(message)
      end
    fun ref _notifyReadable() =>
      if readable() then
        let readSubscribers: MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]] = _readSubscribers()
        for notify in readSubscribers.values() do
          notify.readable()
        end
      end
    fun ref _subscribeRead(notify: ReadablePullNotify[R] iso) =>
      let readSubscribers: MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]] = _readSubscribers()
      if readSubscribers.size() >= 1 then
        let notify': ReadablePullNotify[R] ref = consume notify
        notify'.exception("Stream has multiple subscribers")
      else
        let notify': ReadablePullNotify[R] ref = consume notify
        readSubscribers(notify') = notify'
        if readable() then
          _notifyReadable()
        end
      end
    fun ref _unsubscribeRead(notify: ReadablePullNotify[R] tag) =>
      let readSubscribers: MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]] = _readSubscribers()
      try
        readSubscribers.remove(notify)?
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
    be pull()
    be read(size:(USize | None) = None, cb: {(R)} val)
    be subscribeRead(notify: ReadablePullNotify[R] iso) =>
      _subscribeRead(consume notify)
    be unsubscribeRead(notify: ReadablePullNotify[R] tag) =>
      _unsubscribeRead(notify)

    be piped(stream: WriteablePullStream[R] tag, notify: ReadablePullNotify[R] iso) /* =>
      _subscribeRead(consume notify)
      let notify': WriteablePullNotify[W] iso = WriteablePullNotify[W]
      stream.subscribeWrite(consume notify')
      _notifyPiped()
    */

    be unpiped(notify: ReadablePullNotify[R] tag) =>
      let readSubscribers: MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]] = _readSubscribers()
      try
        readSubscribers.remove(notify)?
      end

    fun ref _notifyPiped() =>
      let readSubscribers: MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]] = _readSubscribers()
      for notify in readSubscribers.values() do
        notify.piped()
      end
    fun ref _notifyUnpiped() =>
      let readSubscribers: MapIs[ReadablePullNotify[R] tag, ReadablePullNotify[R]] = _readSubscribers()
      for notify in readSubscribers.values() do
        notify.unpiped()
      end

    be destroy(message: String) =>
      _notifyException(message)
