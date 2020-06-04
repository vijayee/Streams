
interface ReadablePushStream[R: Any #send]
  fun readable(): Bool

  fun _destroyed(): Bool

  fun ref _piped(): Bool =>
    let notify: (Array[(ReadablePushNotify tag, Bool)] iso | None) = _pipeNotify()
    match notify
      | let notify': ReadablePushNotify[R] tag => true
      else
        false
    end

  fun _subscriberCount[A: ReadablePushNotify[R] tag](): USize =>
    var i = 0
    let subscribers: Array[ReadablePushNotify[R] tag] = _subscribers()
    for notify in subscribers.values() do
      match notify
      | let notify': A =>
          i = i + 1
      end
    end
    i

  fun ref _discardOnces(onces: Array[USize]) =>
    let subscribers: Array[(ReadablePushNotify[R] tag, Bool)] = _subscribers()
    vare i: USize = 0
    for index in onces.values() do
      try
        subscribers.delete((index - (i = i + 1)))?
      end
    end

  fun ref _pipeNotifiers(): (Array[ReadablePushNotify] tag iso | None)

  fun ref _subscribers() : Array[(ReadablePushNotify tag, Bool)]

  fun ref _notifyError(ex: Exception) =>
    let subscribers: Array[(ReadablePushNotify[R] tag, Bool)] = _subscribers()
    let onces = Array[USize](subscribers.size())
    var i: USize = 0
    for notify in subscribers.values() do
      match notify
      |  (let notify': ErrorNotify, let once: Bool) =>
          notify'._1(ex)
          if once then
            onces.push(i)
          end
      end
      i = i + 1
    end
    if onces.size() > 0 then
      _discardOnces(onces)
    end

  fun ref _notifyReadable() =>
    if readable() then
      let subscribers: Array[(ReadablePushNotify[R] tag, Bool)] = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers.values() do
        match notify
        |  (let notify': ReadablePushNotify[R], let once: Bool) =>
            notify'._1(ex)
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        _discardOnces(onces)
      end
    end

  fun ref _subscribe(notify: ReadablePushNotify[R] iso, once: Bool = false) =>
    let subscribers: Array[(ReadablePushNotify[R] tag, Bool)] = _subscribers()
    match notify
      | let notify': DataNotify iso =>
        if _subscriberCount[DataNotify tag]() < 1 then
          subscribers.push((consume notify, once))
        else
          _notifyError(Exception("Multiple Data Subscribers"))
        end
      | let notify': UnpipeNotify iso =>
        if _subscriberCount[UnpipeNotify tag]() < 1 then
          subscribers.push((consume notify, once))
        else
          _notifyError(Exception("Multiple Unpipe Subscribers"))
        end
      | let notify': ReadablePushNotify[R] iso =>
        subscribers.push((consume notify, once))
        if readable() then
          _notifyReadable()
        end
      else
        subscribers.push((consume notify, once))
    end

  fun ref _unsubscribe(notify: ReadablePushNotify[R] tag) =>
    let subscribers: Array[ReadablePushNotify[R]] = _subscribers()
    try
      var i: USize = 0
      while i < _subscribers.size() do
        if _subscribers(i)? is notify then
          _subscribers.delete(i)?
          break
        else
          i = i + 1
        end
      end
    else
      _notifyError(Exception("Failed to Unsubscribe"))
    end

  fun ref _notifyData(data: R) =>
    let subscribers: Array[(ReadablePushNotify[R] tag, Bool)] = _subscribers()
    var notify'': (ReadablePushNotify[R] | None) =  None
    let onces = Array[USize](subscribers.size())

    var i: USize = 0
    for notify in subscribers.values() do
      match notify
      |  (let notify': DataNotify, let once: Bool) =>
          notify'' = notify'._1
          if once then
            onces.push(i)
          end
      end
      i = i + 1
    end

    match notify''
    | let notify''': DataNotify =>
        notify'''(consume data)
    end
    if onces.size() > 0 then
      _discardOnces(onces)
    end

  fun ref _notifyFinished() =>
    let subscribers: Array[(ReadablePushNotify[R] tag, Bool)] = _subscribers()
    let onces = Array[USize](subscribers.size())
    var i: USize = 0
    for notify in subscribers.values() do
      match notify
      |  (let notify': FinishedNotify, let once: Bool) =>
          notify'._1()
          if once then
            onces.push(i)
          end
      end
      i = i + 1
    end
    if onces.size() > 0 then
      _discardOnces(onces)
    end
    subscribers.clear()

  be push()

  be read(size:(USize | None) = None, cb: {(R)} val)

  be subscribe(notify: ReadablePushNotify[R] iso, once: Bool = false) =>
    match notify
    | let notify': DataNotify iso  =>
      _subscribe(consume notify, once)
      if ((_subscriberCount[DataNotify tag]()) >= 1) and (not _piped()) and _readable()) then
        push()
      end
    else
      _subscribe(consume notify, once)
    end

  be unsubscribe(notify: ReadablePushNotify[R] tag) =>
    _unsubscribe(notify)

  be pipe(stream: WriteablePushStream[R] tag)

  fun ref _notifyPipe() =>
    let subscribers: Array[(ReadablePushNotify[R] tag, Bool)] = _subscribers()
    let onces = Array[USize](subscribers.size())
    var i: USize = 0
    for notify in subscribers.values() do
      match notify
      |  (let notify': PipeNotify, let once: Bool) =>
          notify'._1()
          if once then
            onces.push(i)
          end
      end
      i = i + 1
    end
    if onces.size() > 0 then
      _discardOnces(onces)
    end
    if onces.size() > 0 then
      _discardOnces(onces)
    end
  fun ref _notifyUnpipe(notifiers: (Array[ReadablePushNotify tag] iso | None)) =>
    let subscribers: Array[(ReadablePushNotify[R] tag, Bool)] = _subscribers()
    let onces = Array[USize](subscribers.size())
    var notify'': (UnpipeNotify | None) = None
    var i: USize = 0
    for notify in subscribers.values() do
      match notify
      |  (let notify': UpipeNotify, let once: Bool) =>
          notify'' = notify'._1
          if once then
            onces.push(i)
          end
      end
      i = i + 1
    end
    match notify''
    | let notify''': DataNotify =>
        match notifiers
        | let notifiers': Array[ReadablePushNotify tag] iso =>
          notify'''(consume notifiers')
        | None =>
          notify'''(None)
        end
    end
    if onces.size() > 0 then
      _discardOnces(onces)
    end

  be unpipe() =>
    if piped() then
      _notifyUnpipe()
    end
    let readSubscribers: (Array[ReadablePushNotify tag] iso | None) = _pipeNotifiers()
    readSubscribers.clear()

  be destroy(message: (String | Exception)) =>
    _notifyError(Exception(message))
