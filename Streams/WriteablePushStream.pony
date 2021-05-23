use "Exception"
interface WriteablePushStream[W: Any #send] is Stream
  be write(data: W)

  fun ref _notifyPiped() =>
    try
      let subscribers: Subscribers = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(PipedKey)?.values() do
        match notify
        |  (let notify': PipedNotify, let once: Bool) =>
            notify'()
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        _discardOnces(subscribers(PipedKey)?, onces)
      end
    end

  fun ref _notifyUnpiped() =>
    try
      let subscribers: Subscribers = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(UnpipedKey)?.values() do
        match notify
        |  (let notify': UnpipedNotify, let once: Bool) =>
            notify'()
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        _discardOnces(subscribers(UnpipedKey)?, onces)
      end
    end

  be piped(stream: ReadablePushStream[W] tag)

  be unpiped(notifiers: Array[Notify tag] iso) =>
    let subscribers: Subscribers = _subscribers()
    let notifiers': Array[Notify tag] =  consume notifiers

    let j: USize = 0
    while j < notifiers'.size() do
      try
        _unsubscribe(notifiers'(j)?)
      end
    end
    _notifyUnpiped()

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

  fun ref _subscriberCount[A: Notify](): USize =>
    let subscribers: Subscribers = _subscribers()
    try
      iftype A <: ThrottledNotify then
        subscribers(ThrottledKey)?.size()
      elseif A <: UnthrottledNotify then
        subscribers(ThrottledKey)?.size()
      elseif A <: ErrorNotify then
        subscribers(ErrorKey)?.size()
      elseif A <: PipedNotify then
        subscribers(PipedKey)?.size()
      elseif A <: UnpipedNotify then
        subscribers(UnpipedKey)?.size()
      else
        0
      end
    else
      0
    end

  fun ref _subscribe(notify: Notify iso, once: Bool = false) =>
   if _destroyed() then
     _notifyError(Exception("Stream has been destroyed"))
   else
     let subscribers: Subscribers = _subscribers()
     let notify': Notify = consume notify
     try
       subscribers(notify')?.push((notify', once))
     else
       let arr: Subscriptions = Subscriptions(10)
       arr.push((notify', once))
       subscribers(notify') =  arr
     end
   end

  fun ref _unsubscribe(notify: Notify tag) =>
    try
      if _destroyed() then
        _notifyError(Exception("Stream has been destroyed"))
      else
        let subscribers: Subscribers  = _subscribers()
        let arr: (Subscriptions | None) = match notify
          | let notifiers: ThrottledNotify tag =>
            subscribers(ThrottledKey)?
          | let notifiers: UnthrottledNotify tag =>
            subscribers(UnthrottledKey)?
          | let notifiers: ErrorNotify tag =>
            subscribers(ErrorKey)?
          | let notifiers: PipedNotify tag =>
            subscribers(PipedKey)?
          | let notifiers: UnpipedNotify tag =>
            subscribers(UnpipedKey)?
        end
        match arr
        | let arr': Subscriptions =>
          try
            var i: USize = 0
            while i < arr'.size() do
              if arr'(i)?._1 is notify then
                arr'.delete(i)?
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
    end
