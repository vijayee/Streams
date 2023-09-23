use "Exception"
interface TransformPushStream[R: Any #send, W: Any #send] is (ReadablePushStream[R] & WriteablePushStream[W])
  fun ref autoPush(): Bool =>
    false

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
        notifyReadable()
      else
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
      let subscribers': Subscribers = subscribers()
      let arr: (Subscriptions | None) = match notify
        | let notifiers: ThrottledNotify tag =>
          subscribers'(ThrottledEvent)?
        | let notifiers: UnthrottledNotify tag =>
          subscribers'(ThrottledEvent)?
        | let notifiers: ErrorNotify tag =>
          subscribers'(ErrorEvent)?
        | let notifiers: PipedNotify tag =>
          subscribers'(PipedEvent)?
        | let notifiers: UnpipedNotify tag =>
          subscribers'(UnpipedEvent)?
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
        | let notifiers: EmptyNotify tag =>
          subscribers'(EmptyEvent)?
        | let notifiers: OverflowNotify tag =>
          subscribers'(OverflowEvent)?
        | let notifiers: FinishedNotify tag =>
          subscribers'(FinishedEvent)?
      end
      match arr
      | let arr': Subscriptions =>
        var i: USize = 0
        while i < arr'.size() do
          if arr'(i)?._1 is notify then
            arr'.delete(i)?
            return
          else
            i = i + 1
          end
        end
      end
    else
      notifyError(Exception("Failed to Unsubscribe"))
    end

  be push() =>
    None
