use "Exception"
interface Stream
  fun ref subscribers(): Subscribers

  be subscribe(notify: Notify iso, once: Bool = false) =>
    subscribeInternal(consume notify, once)

  fun ref subscribeInternal(notify: Notify iso, once: Bool = false)

  fun ref subscriberCount[A: Notify](): USize

  fun ref discardOnces(subscribers': Subscriptions, onces: Array[USize]) =>
    var i: USize = 0
    for index in onces.values() do
      try
        subscribers'.delete((index - (i = i + 1)))?
      end
    end

  fun ref unsubscribeInternal(notify: Notify tag)

  be unsubscribe(notify: Notify tag) =>
    unsubscribeInternal(notify)


  fun ref notifyError(ex: Exception) =>
    try
      let subscribers': Subscribers = subscribers()
      let onces = Array[USize](subscribers'.size())
      var i: USize = 0
      for notify in subscribers'(ErrorKey)?.values() do
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
        discardOnces(subscribers'(ErrorKey)?, onces)
      end
    end

  fun ref notifyClose() =>
    try
      let subscribers': Subscribers = subscribers()
      let onces = Array[USize](subscribers'.size())
      var i: USize = 0
      for notify in subscribers'(CloseKey)?.values() do
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
        discardOnces(subscribers'(CloseKey)?, onces)
      end
    end

  fun ref notifyUnthrottled() =>
    try
      let subscribers': Subscribers = subscribers()
      let onces = Array[USize](subscribers'.size())
      var i: USize = 0
      for notify in subscribers'(UnthrottledKey)?.values() do
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
        discardOnces(subscribers'(UnthrottledKey)?, onces)
      end
    end

  fun ref notifyThrottled() =>
    try
      let subscribers': Subscribers = subscribers()
      let onces = Array[USize](subscribers'.size())
      var i: USize = 0
      for notify in subscribers'(ThrottledKey)?.values() do
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
        discardOnces(subscribers'(ThrottledKey)?, onces)
      end
    end

  fun destroyed(): Bool

  be destroy(message: (String | Exception)) =>
    match message
      | let message' : String =>
        notifyError(Exception(message'))
      | let message' : Exception =>
        notifyError(message')
    end

  be close()
