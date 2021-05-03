use "Exception"
interface WriteablePullStream[W: Any #send] is Stream
  fun ref _pipeNotifiers(): (Array[Notify tag] iso^ | None)

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

  fun ref _subscriberCount[A: Notify](): USize =>
    let subscribers: Subscribers = _subscribers()
    try
      iftype A <: ThrottledNotify then
        subscribers(ThrottledKey)?.size()
      elseif A <: UnthrottledNotify then
        subscribers(ThrottledKey)?.size()
      elseif A <: ErrorNotify then
        subscribers(ErrorKey)?.size()
      elseif A <: PipeNotify then
        subscribers(PipeKey)?.size()
      elseif A <: UnpipeNotify then
        subscribers(UnpipeKey)?.size()
      else
        0
      end
    else
      0
    end

  fun ref _unsubscribe(notify: Notify tag) =>
    try
      if _destroyed() then
        _notifyError(Exception("Stream has been destroyed"))
      else
        let subscribers: Subscribers  = _subscribers()
        let arr': (Subscriptions | None) = match notify
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
        match arr'
        | let arr: Subscriptions =>
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
    end

  fun ref _notifyPipe() =>
    try
      let subscribers: Subscribers = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(PipeKey)?.values() do
        match notify
        |  (let notify': PipeNotify, let once: Bool) =>
            notify'()
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        _discardOnces(subscribers(PipeKey)?, onces)
      end
    end

  fun ref _notifyUnpipe() =>
    try
      let subscribers: Subscribers = _subscribers()
      let onces = Array[USize](subscribers.size())
      var notifiers: Array[Notify tag] iso = _pipeNotifiers() as Array[Notify tag] iso^
      var notify'': (UnpipeNotify | None) = None
      var i: USize = 0
      for notify in subscribers(UnpipeKey)?.values() do
        match notify
          |  (let notify': UnpipeNotify, let once: Bool) =>
            notify'' = notify'
            if once then
              onces.push(i)
            end
            break
        end
        i = i + 1
      end
      match notify''
        | let notify''': UnpipeNotify =>
          notify'''(consume notifiers)
      end
      if onces.size() > 0 then
        _discardOnces(subscribers(UnpipeKey)?, onces)
      end
    end

  be write(data: W)

  be pipe(stream: ReadablePullStream[W] tag)

  
