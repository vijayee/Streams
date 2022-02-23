use "Exception"
interface TransformPushStream[R: Any #send, W: Any #send] is (WriteablePushStream[W] & ReadablePushStream[R])
  fun ref subscriberCount[A: Notify](): USize =>
    let subscribers': Subscribers = subscribers()
    try
      iftype A <: ThrottledNotify then
        subscribers'(ThrottledKey)?.size()
      elseif A <: UnthrottledNotify then
        subscribers'(ThrottledKey)?.size()
      elseif A <: ErrorNotify then
        subscribers'(ErrorKey)?.size()
      elseif A <: PipedNotify then
        subscribers'(PipedKey)?.size()
      elseif A <: UnpipedNotify then
        subscribers'(UnpipedKey)?.size()
      elseif A <: PipeNotify then
        subscribers'(PipeKey)?.size()
      elseif A <: UnpipeNotify then
        subscribers'(UnpipeKey)?.size()
      elseif A <: DataNotify[R] then
        subscribers'(DataKey[R])?.size()
      elseif A <: ReadableNotify then
        subscribers'(ReadableKey)?.size()
      elseif A <: CompleteNotify then
        subscribers'(CompleteKey)?.size()
      elseif A <: FinishedNotify then
        subscribers'(FinishedKey)?.size()
      elseif A <: EmptyNotify then
        subscribers'(EmptyKey)?.size()
      elseif A <: OverflowNotify then
        subscribers'(OverflowKey)?.size()
      else
        0
      end
    else
      0
    end

  fun ref autoPush(): Bool =>
    false

  fun ref subscribeInternal(notify: Notify iso, once: Bool = false) =>
    let subscribers': Subscribers = subscribers()
    let notify': Notify = consume notify

    match notify'
      | let notify'': DataNotify[R]  =>
        if subscriberCount[DataNotify[R]]() < 1 then
          try
            subscribers'(notify')?.push((notify', once))
          else
            let arr: Subscriptions = Subscriptions(10)
            arr.push((notify', once))
            subscribers'(notify') =  arr
          end
        else
          notifyError(Exception("Multiple Data Subscribers"))
        end
      | let notify'': UnpipeNotify =>
        if subscriberCount[UnpipeNotify]() < 1 then
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
        | let notify': ThrottledNotify tag =>
          subscribers'(ThrottledKey)?
        | let notify': UnthrottledNotify tag =>
          subscribers'(ThrottledKey)?
        | let notify': ErrorNotify tag =>
          subscribers'(ErrorKey)?
        | let notifiers: PipedNotify tag =>
          subscribers'(PipedKey)?
        | let notifiers: UnpipedNotify tag =>
          subscribers'(UnpipedKey)?
        | let notify': PipeNotify tag =>
          subscribers'(PipeKey)?
        | let notify': UnpipeNotify tag =>
          subscribers'(UnpipeKey)?
        | let notify': DataNotify[R] tag =>
          subscribers'(DataKey[R])?
        | let notify': ReadableNotify tag =>
          subscribers'(ReadableKey)?
        | let notify': CompleteNotify tag =>
          subscribers'(CompleteKey)?
        | let notify': EmptyNotify tag =>
          subscribers'(EmptyKey)?
        | let notify': OverflowNotify tag =>
          subscribers'(OverflowKey)?
        | let notify': FinishedNotify tag =>
          subscribers'(FinishedKey)?
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
