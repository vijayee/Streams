use "Exception"
interface ReadablePushStream[R: Any #send] is Stream
  fun readable(): Bool

  fun ref notifyReadable() =>
    notify(ReadableEvent)

  fun ref notifyData(data: R) =>
    notifyPayload[R](DataEvent[R], consume data)

  fun ref notifyComplete() =>
    notify(CompleteEvent)

  fun ref notifyOverflow() =>
    notify(OverflowEvent)

  be push()

  be read(cb: {(R)} val, size:(USize | None) = None)

  fun ref isPiped(): Bool

  fun ref autoPush(): Bool

  fun ref pipeNotifiers(): (Array[Notify tag] iso^ | None)

  be pipe(stream: WriteablePushStream[R] tag)

  fun ref notifyPipe() =>
    notify(PipeEvent)

  fun ref notifyEmpty() =>
    notify(EmptyEvent)

  fun ref notifyUnpipe() =>
    try
      var notifiers: Array[Notify tag] iso = pipeNotifiers() as Array[Notify tag] iso^
      notifyPayload[Array[Notify tag] iso](UnpipeEvent, consume notifiers)
    end

  be unpipe() =>
    if isPiped() then
      notifyUnpipe()
    end
    let subscribers': Subscribers = subscribers()
    subscribers'.clear()

  fun ref subscribeInternal(notify: Notify iso, once: Bool = false) =>
    let subscribers': Subscribers = subscribers()
    let notify': Notify = consume notify

    match notify'
      | let notify'': DataNotify[R]  =>
        iftype R <: Any #share then
          try
            subscribers'(notify')?.push((notify', once))
          else
            let arr: Subscriptions = Subscriptions(10)
            arr.push((notify', once))
            subscribers'(notify') =  arr
          end
          if (not isPiped()) and autoPush() then
            push()
          end
        else
          if subscriberCount(DataEvent[R]) < 1 then
            try
              subscribers'(notify')?.push((notify', once))
            else
              let arr: Subscriptions = Subscriptions(10)
              arr.push((notify', once))
              subscribers'(notify') =  arr
            end
            if (not isPiped()) and autoPush() then
              push()
            end
          else
            notifyError(Exception("Multiple Data Subscribers"))
          end
        end
      | let notify'': UnpipeNotify =>
        if subscriberCount(UnpipeEvent) < 1 then
          try
            subscribers'(notify')?.push((notify', once))
          else
            let arr: Subscriptions = Subscriptions(10)
            arr.push((notify', once))
            subscribers'(notify') =  arr
          end
        else
          notifyError(Exception("Multiple Unpipe Subscribers"))
        end
      | let notify'': ReadableNotify =>
        try
          subscribers'(notify')?.push((notify', once))
        else
          let arr: Subscriptions = Subscriptions(10)
          arr.push((notify', once))
          subscribers'(notify') =  arr
        end
        if readable() then
          notify''()
        end
      else
        try
          subscribers'(notify')?.push((notify', once))
        else
          let arr: Subscriptions = Subscriptions(10)
          arr.push((notify', once))
          subscribers'(notify') =  arr
        end
    end

  fun ref unsubscribeInternal(notify': Notify tag) =>
    try
      let subscribers': Subscribers = subscribers()
      let arr: (Subscriptions | None) = match notify'
        | let notifiers: ThrottledNotify tag =>
          subscribers'(ThrottledEvent)?
        | let notifiers: UnthrottledNotify tag =>
          subscribers'(ThrottledEvent)?
        | let notifiers: ErrorNotify tag =>
          subscribers'(ErrorEvent)?
        | let notifiers: PipeNotify tag =>
          subscribers'(PipeEvent)?
        | let notifiers: UnpipeNotify tag =>
          subscribers'(UnpipeEvent)?
        | let notifiers: DataNotify[R] tag =>
          subscribers'(DataEvent[R])?
        | let notifiers: ReadableNotify tag =>
          subscribers'(ReadableEvent)?
        | let notifiers: CompleteNotify tag =>
          subscribers'(CompleteEvent)?
      end
      match arr
        | let arr': Subscriptions =>
          var i: USize = 0
          while i < arr'.size() do
            if arr'(i)?._1 is notify' then
              arr'.delete(i)?
              break
            else
              i = i + 1
            end
          end
      end
    else
      notifyError(Exception("Failed to Unsubscribe"))
    end
