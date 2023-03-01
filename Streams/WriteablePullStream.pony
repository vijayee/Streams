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

  fun ref unsubscribeInternal(notify: Notify tag) =>
    try
      if destroyed() then
        notifyError(Exception("Stream has been destroyed"))
      else
        let subscribers': Subscribers  = subscribers()
        let arr': (Subscriptions | None) = match notify
          | let notifiers: ThrottledNotify tag =>
            subscribers'(ThrottledEvent)?
          | let notifiers: UnthrottledNotify tag =>
            subscribers'(UnthrottledEvent)?
          | let notifiers: ErrorNotify tag =>
            subscribers'(ErrorEvent)?
          | let notifiers: PipedNotify tag =>
            subscribers'(PipedEvent)?
          | let notifiers: UnpipedNotify tag =>
            subscribers'(UnpipedEvent)?
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
    notify(PipeEvent)

  fun ref notifyUnpipe() =>
    try
      var notifiers: Array[Notify tag] iso = pipeNotifiers() as Array[Notify tag] iso^
      notifyPayload[Array[Notify tag] iso](UnpipeEvent, consume notifiers)
    end

  be write(data: W)

  be pipe(stream: ReadablePullStream[W] tag)
