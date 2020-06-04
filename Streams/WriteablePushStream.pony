use "collections"
interface WriteablePushStream[W: Any #send]
  fun ref _subscribers(): Map[WriteablePushNotify, Array[(WriteablePushNotify, Bool)]]

  fun ref _subscribe(notify: WriteablePushNotify iso, once: Bool = false) =>
    if _destroyed() then
      _notifyError("Stream has been destroyed")
    else
      let subscribers: Map[WriteablePushNotify, Array[(WriteablePushNotify, Bool)]] = _subscriber()
      let notify': WriteablePushNotify = consume notify
      try
        subscribers(notify')?.push((notify', once))
      else
        let arr: Array[(WriteablePushNotify, Bool)] = Array[(WriteablePushNotify, Bool)](10)
        arr.push((notify', once))
        subscribers(notify')? =  arr
      end
    end

  fun _subscriberCount[A: WriteablePushNotify](): USize =>
    let subscribers: Map[WriteablePushNotify, Array[(WriteablePushNotify, Bool)]] = _subscribers()
    var i: USize = 0
    for notify in subscribers.keys() do
      match notify
        | let notify': A =>
          try
            i = subscribers(notify')?.size()
          end
          break
      end
    end
    i

  fun ref _discardOnces(subscribers: Array[(WriteablePushNotify, Bool)], let onces: Array[USize]) =>
    vare i: USize = 0
    for index in onces.values() do
      try
        subscribers.delete((index - (i = i + 1)))?
      end
    end

  fun ref _unsubscribe(notify: WriteablePushNotify tag) =>
    if _destroyed() then
      _notifyException("Stream has been destroyed")
    else
      let subscribers: Map[WriteablePushNotify, Array[(WriteablePushNotify, Bool)]]  = _subscribers()
      try
        var i: USize = 0
        for type in subscribers.values() do
          i = 0
          while i < _type.size() do
            if type(i)?._1 is notify then
              type.delete(i)?
              return
            else
              i = i + 1
            end
          end
        end
      else
        _notifyError(Exception("Failed to Unsubscribe"))
      end
    end

  fun _destroyed(): Bool

  fun ref _notifyError(ex: Exception) =>
    try
      let subscribers: Map[WriteablePushNotify, Array[(WriteablePushNotify, Bool)]] = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(ErrorKey)?.values() do
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
    end

  fun ref _notifyPiped() =>
    try
      let subscribers: Array[(WriteablePushNotify tag, Bool)] = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(PipedKey)?.values() do
        match notify
        |  (let notify': PipedNotify, let once: Bool) =>
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
    end

  fun ref _notifyUnpiped() =>
    try
      let subscribers: Array[(WriteablePushNotify tag, Bool)] = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(UnpipedKey)?.values() do
        match notify
        |  (let notify': UnpipedNotify, let once: Bool) =>
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
    end

  fun ref _notifyUnthrottled() =>
    try
      let subscribers: Array[(WriteablePushNotify tag, Bool)] = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(UnthrottledKey)?.values() do
        match notify
        |  (let notify': UnthrottledNotify, let once: Bool) =>
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
    end

  fun ref _notifyThrottled() =>
    try
      let subscribers: Array[(WriteablePushNotify tag, Bool)] = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(ThrottledKey)?.values() do
        match notify
        |  (let notify': ThrottledNotify, let once: Bool) =>
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
    end

  be subscribe(notify: WriteablePushNotify iso, once: Bool = false) =>
    _subscribe(consume notify, once)

  be unsubscribe(notify: WriteablePushNotify tag) =>
    _unsubscribe(notify)

  be write(data: W)

  be piped(stream: ReadablePushStream[W] tag) /* =>
    _subscribeWrite(consume notify)
    let notify': ReadablePushNotify[W] iso = ReadablePushNotify[W]
    stream.subscribeRead(consume notify')
    _notifyPiped()
  */
  be unpiped(notifiers: Array[WriteablePushNotify tag] iso) =>
    let subscribers: Map[WriteablePushNotify, Array[(WriteablePushNotify, Bool)]] = _subscribers()
    let notifiers': Array[WriteablePushNotify tag] =  consume notifiers
    let i: USize = 0
    while i < subscribers.size() do
      let j: USize = 0
      while j < notifiers'.size() do
        try
          if subscribers(i)? is notify(i)? then
            notifiers'.delete(j)?
            subscribers.delete(i)?
            i = i - 1
            break
          end
        end
      end
      if notifiers'.size() == 0 then
        break
      end
      i = i + 1
    end
    _notifyUnpiped()

  be destroy(message: (String | Exception)) =>
    match message
      | let message' : String =>
        _notifyError(Exception(message))
      | let message' : Exception =>
        _notifyError(message')
    end
