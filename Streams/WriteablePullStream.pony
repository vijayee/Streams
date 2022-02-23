use "Exception"
interface WriteablePullStream[W: Any #send] is Stream
  fun ref pipeNotifiers(): (Array[Notify tag] iso^ | None)

  fun ref subscribeInternal(notify: Notify iso, once: Bool = false) =>
    if destroyed() then
      notifyError(Exception("Stream has been destroyed"))
    else
      let subscribers': Subscribers = subscribers()
      let notify': Notify = consume notify
      try
        subscribers'(notify')?.push((notify', once))
      else
        let arr: Subscriptions = Subscriptions(10)
        arr.push((notify', once))
        subscribers'(notify') =  arr
      end
    end

  fun ref subscriberCount[A: Notify](): USize =>
    let subscribers': Subscribers = subscribers()
    try
      iftype A <: ThrottledNotify then
        subscribers'(ThrottledKey)?.size()
      elseif A <: UnthrottledNotify then
        subscribers'(ThrottledKey)?.size()
      elseif A <: ErrorNotify then
        subscribers'(ErrorKey)?.size()
      elseif A <: PipeNotify then
        subscribers'(PipeKey)?.size()
      elseif A <: UnpipeNotify then
        subscribers'(UnpipeKey)?.size()
      else
        0
      end
    else
      0
    end

  fun ref unsubscribeInternal(notify: Notify tag) =>
    try
      if destroyed() then
        notifyError(Exception("Stream has been destroyed"))
      else
        let subscribers': Subscribers  = subscribers()
        let arr': (Subscriptions | None) = match notify
          | let notifiers: ThrottledNotify tag =>
            subscribers'(ThrottledKey)?
          | let notifiers: UnthrottledNotify tag =>
            subscribers'(UnthrottledKey)?
          | let notifiers: ErrorNotify tag =>
            subscribers'(ErrorKey)?
          | let notifiers: PipedNotify tag =>
            subscribers'(PipedKey)?
          | let notifiers: UnpipedNotify tag =>
            subscribers'(UnpipedKey)?
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
            notifyError(Exception("Failed to Unsubscribe"))
          end
        end
      end
    end

  fun ref notifyPipe() =>
    try
      let subscribers': Subscribers = subscribers()
      let onces = Array[USize](subscribers'.size())
      var i: USize = 0
      for notify in subscribers'(PipeKey)?.values() do
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
        discardOnces(subscribers'(PipeKey)?, onces)
      end
    end

  fun ref notifyUnpipe() =>
    try
      let subscribers': Subscribers = subscribers()
      let onces = Array[USize](subscribers'.size())
      var notifiers: Array[Notify tag] iso = pipeNotifiers() as Array[Notify tag] iso^
      var notify'': (UnpipeNotify | None) = None
      var i: USize = 0
      for notify in subscribers'(UnpipeKey)?.values() do
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
        discardOnces(subscribers'(UnpipeKey)?, onces)
      end
    end

  be write(data: W)

  be pipe(stream: ReadablePullStream[W] tag)
