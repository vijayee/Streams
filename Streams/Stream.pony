use "Exception"
interface Stream
  fun ref _subscribers(): Subscribers

  be subscribe(notify: Notify iso, once: Bool = false) =>
    _subscribe(consume notify, once)

  fun ref _subscribe(notify: Notify iso, once: Bool = false)

  fun ref _subscriberCount[A: Notify](): USize

  fun ref _discardOnces(subscribers: Subscriptions, onces: Array[USize]) =>
    var i: USize = 0
    for index in onces.values() do
      try
        subscribers.delete((index - (i = i + 1)))?
      end
    end

  fun ref _unsubscribe(notify: Notify tag)

  be unsubscribe(notify: Notify tag) =>
    _unsubscribe(notify)

  fun ref _notifyFinished() =>
    try
      let subscribers: Subscribers = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(FinishedKey)?.values() do
        match notify
        |  (let notify': FinishedNotify, let once: Bool) =>
            notify'()
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        _discardOnces(subscribers(FinishedKey)?, onces)
      end
      subscribers.clear()
    end

  fun ref _notifyError(ex: Exception) =>
    try
      let subscribers: Subscribers = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(ErrorKey)?.values() do
        match notify
        |  (let notify': ErrorNotify, let once: Bool) =>
            notify'(ex)
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        _discardOnces(subscribers(ErrorKey)?, onces)
      end
    end

  fun ref _notifyClose() =>
    try
      let subscribers: Subscribers = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(CloseKey)?.values() do
        match notify
        |  (let notify': CloseNotify, let once: Bool) =>
            notify'()
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        _discardOnces(subscribers(CloseKey)?, onces)
      end
    end

  fun ref _notifyUnthrottled() =>
    try
      let subscribers: Subscribers = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(UnthrottledKey)?.values() do
        match notify
        |  (let notify': UnthrottledNotify, let once: Bool) =>
            notify'()
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        _discardOnces(subscribers(UnthrottledKey)?, onces)
      end
    end

  fun ref _notifyThrottled() =>
    try
      let subscribers: Subscribers = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(ThrottledKey)?.values() do
        match notify
        |  (let notify': ThrottledNotify, let once: Bool) =>
            notify'()
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        _discardOnces(subscribers(ThrottledKey)?, onces)
      end
    end

  fun _destroyed(): Bool

  be destroy(message: (String | Exception)) =>
    match message
      | let message' : String =>
        _notifyError(Exception(message'))
      | let message' : Exception =>
        _notifyError(message')
    end

  be close()
