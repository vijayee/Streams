use "collections"
use "Exception"
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
    try
      iftype A <: ThrottledNotify then
        subscribers(ThrottledKey)?.size()
      elseif A <: UnthrottledNotify then
        subscribers(ThrottledKey)?.size()
      elseif A <: ErrorNotify then
        subscribers(ErrorKey)?.size()
      elseif A <: PipeNotify then
        subscriebers(PipeKey)?.size()
      elseif A <: UnpipeNotify then
        subscriebers(UnpipeKey)?.size()
      end
    else
      0
    end

  fun ref _discardOnces(subscribers: Array[(WriteablePushNotify, Bool)], let onces: Array[USize]) =>
    vare i: USize = 0
    for index in onces.values() do
      try
        subscribers.delete((index - (i = i + 1)))?
      end
    end

  fun ref _unsubscribe(notify: WriteablePushNotify tag) =>
    try
      if _destroyed() then
        _notifyException("Stream has been destroyed")
      else
        let subscribers: Map[WriteablePushNotify, Array[(WriteablePushNotify, Bool)]]  = _subscribers()
        let arr: Array[(WriteablePushNotify, Bool)] = match WriteablePushNotify
        | let notifiers: ThrottledNotify tag =>
            subscribers(ThrottledKey)?
          | let notifiers: UnthrottledNotify tag =>
            subscribers(ThrottledKey)?
          | let notifiers: ErrorNotify tag =>
            subscribers(ErrorKey)?
          | let notifiers: PipeNotify tag =>
            subscribers(PipeKey)?
          | let notifiers: UnpipeNotify tag =>
            subscribers(UnpipeKey)?
        end
        try
          var i: USize = 0
          while i < arr.size() do
            if arr(i)?._1 is notify then
              arr.delete(i)?
              return
            else
              i = i + 1
            end
          end
        else
          _notifyError(Exception("Failed to Unsubscribe"))
        end
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

  be piped(stream: ReadablePushStream[W] tag)

  be unpiped(notifiers: Array[WriteablePushNotify tag] iso) =>
    let subscribers: Map[WriteablePushNotify, Array[(WriteablePushNotify, Bool)]] = _subscribers()
    let notifiers': Array[WriteablePushNotify tag] =  consume notifiers

    let j: USize = 0
    while j < notifiers'.size() do
      try
        _unsubscribe(notifiers'(i)?)
      end
    end
    _notifyUnpiped()

  be destroy(message: (String | Exception)) =>
    match message
      | let message' : String =>
        _notifyError(Exception(message))
      | let message' : Exception =>
        _notifyError(message')
    end
