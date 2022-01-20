use "Exception"
interface DuplexPushStream[D: Any #send] is (WriteablePushStream[D] & ReadablePushStream[D])
  be close() =>
    closeRead()
    closeWrite()

  be closeRead()

  be closeWrite()

  fun ref _autoPush(): Bool=>
    false
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
      elseif A <: PipeNotify then
        subscribers(PipeKey)?.size()
      elseif A <: UnpipeNotify then
        subscribers(UnpipeKey)?.size()
      elseif A <: DataNotify[D] then
        subscribers(DataKey[D])?.size()
      elseif A <: ReadableNotify then
        subscribers(ReadableKey)?.size()
      elseif A <: CompleteNotify then
        subscribers(CompleteKey)?.size()
      elseif A <: FinishedNotify then
        subscribers(FinishedKey)?.size()
      elseif A <: EmptyNotify then
        subscribers(EmptyKey)?.size()
      elseif A <: OverflowNotify then
        subscribers(OverflowKey)?.size()
      else
        0
      end
    else
      0
    end

  fun ref _subscribe(notify: Notify iso, once: Bool = false) =>
    let subscribers: Subscribers = _subscribers()
    let notify': Notify = consume notify

    match notify'
      | let notify'': DataNotify[D]  =>
        if _subscriberCount[DataNotify[D]]() < 1 then
          try
            subscribers(notify')?.push((notify', once))
          else
            let arr: Subscriptions = Subscriptions(10)
            arr.push((notify', once))
            subscribers(notify') =  arr
          end
        else
          _notifyError(Exception("Multiple Data Subscribers"))
        end
      | let notify'': UnpipeNotify =>
        if _subscriberCount[UnpipeNotify]() < 1 then
          try
            subscribers(notify')?.push((notify', once))
          else
            let arr: Subscriptions = Subscriptions(10)
            arr.push((notify', once))
            subscribers(notify') =  arr
          end
        else
          _notifyError(Exception("Multiple Unpipe Subscribers"))
        end
      | let notify'': ReadableNotify =>
        try
          subscribers(notify')?.push((notify', once))
        else
          let arr: Subscriptions = Subscriptions(10)
          arr.push((notify', once))
          subscribers(notify') =  arr
        end
        _notifyReadable()
      else
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
      let subscribers: Subscribers = _subscribers()
      let arr: (Subscriptions | None) = match notify
        | let notify': ThrottledNotify tag =>
          subscribers(ThrottledKey)?
        | let notify': UnthrottledNotify tag =>
          subscribers(ThrottledKey)?
        | let notify': ErrorNotify tag =>
          subscribers(ErrorKey)?
        | let notifiers: PipedNotify tag =>
          subscribers(PipedKey)?
        | let notifiers: UnpipedNotify tag =>
          subscribers(UnpipedKey)?
        | let notify': PipeNotify tag =>
          subscribers(PipeKey)?
        | let notify': UnpipeNotify tag =>
          subscribers(UnpipeKey)?
        | let notify': DataNotify[D] tag =>
          subscribers(DataKey[D])?
        | let notify': ReadableNotify tag =>
          subscribers(ReadableKey)?
        | let notify': CompleteNotify tag =>
          subscribers(CompleteKey)?
        | let notify': FinishedNotify tag =>
          subscribers(FinishedKey)?
        | let notify': OverflowNotify tag =>
          subscribers(OverflowKey)?
        | let notify': EmptyNotify tag =>
          subscribers(EmptyKey)?
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
      _notifyError(Exception("Failed to Unsubscribe"))
    end
