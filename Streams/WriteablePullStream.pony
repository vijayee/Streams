use "collections"

interface WriteablePullStream[W: Any #send]
  fun ref _subscribers() : Array[WriteablePullNotify[W]]
  fun ref piped(): Bool =>
    match _pipeNotify()
      | let notify': ReadablePullNotify[W] tag => true
    else
      false
    end
  fun ref _pipeNotify(): (ReadablePullNotify[W] tag | None)
  fun _destroyed(): Bool
  fun ref _subscribeWrite(notify: WriteablePullNotify[W] iso) =>
    let writeSubscribers: MapIs[WriteablePullNotify[W] tag, WriteablePullNotify[W]] = _writeSubscribers()
    let notify': WriteablePullNotify[W] ref = consume notify
    writeSubscribers(notify') = notify'
  fun ref _notifyException(message: String) =>
    let writeSubscribers: MapIs[WriteablePullNotify[W] tag, WriteablePullNotify[W]] = _writeSubscribers()
    for notify in writeSubscribers.values() do
      notify.exception(message)
    end
  fun ref _notifyUnthrottled() =>
    let writeSubscribers: MapIs[WriteablePullNotify[W] tag, WriteablePullNotify[W]] = _writeSubscribers()
    for notify in writeSubscribers.values() do
      notify.unthrottled()
    end
  fun ref _notifyThrottled() =>
    let writeSubscribers: MapIs[WriteablePullNotify[W] tag, WriteablePullNotify[W]] = _writeSubscribers()
    for notify in writeSubscribers.values() do
      notify.throttled()
    end
  be subscribeWrite(notify: WriteablePullNotify[W] iso) =>
    _subscribeWrite(consume notify)
  be write(data: W) =>
    None

  be pipe(stream: ReadablePullStream[W] tag)/* =>
    let notify: ReadablePullNotify[W] iso = recover ReadablePullNotify[W] end
    stream.piped(stream, consume notify)
  */
  fun ref _notifyUnpipe() =>
    match _pipeNotify()
    | let pipeNotify: ReadablePullNotify[W] tag =>
        let writeSubscribers: MapIs[WriteablePullNotify[W] tag, WriteablePullNotify[W]] = _writeSubscribers()
        for notify in writeSubscribers.values() do
          notify.unpipe(pipeNotify)
        end
    end
  be unpipe() =>
    if piped() then
      _notifyUnpipe()
    end
    let writeSubscribers: MapIs[WriteablePullNotify[W] tag, WriteablePullNotify[W]] = _writeSubscribers()
    writeSubscribers.clear()

  fun ref _notifyPull() =>
    let writeSubscribers: MapIs[WriteablePullNotify[W] tag, WriteablePullNotify[W]] = _writeSubscribers()
    for notify in writeSubscribers.values() do
      notify.pull()
    end
  be pull() =>
    _notifyPull()

  be destroy(message: String) =>
    _notifyException(message)
