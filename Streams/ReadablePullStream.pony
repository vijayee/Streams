use "Exception"
interface ReadablePullStream[R: Any #send] is Stream
  fun readable(): Bool

  fun destroyed(): Bool

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
      elseif A <: DataNotify[R] then
        subscribers'(DataKey[R])?.size()
      elseif A <: ReadableNotify then
        subscribers'(ReadableKey)?.size()
      elseif A <: CompleteNotify then
        subscribers'(CompleteKey)?.size()
      else
        0
      end
    else
      0
    end

  fun ref notifyReadable() =>
    if readable() then
      try
        let subscribers': Subscribers = subscribers()
        let onces = Array[USize](subscribers'.size())
        var i: USize = 0
        for notify in subscribers'(ReadableKey)?.values() do
          match notify
          |  (let notify': ReadableNotify, let once: Bool) =>
              notify'()
              if once then
                onces.push(i)
              end
          end
          i = i + 1
        end
        if onces.size() > 0 then
          discardOnces(subscribers'(ReadableKey)?, onces)
        end
      end
    end

  fun ref notifyComplete() =>
    try
      let subscribers': Subscribers = subscribers()
      let onces = Array[USize](subscribers'.size())
      var i: USize = 0
      for notify in subscribers'(CompleteKey)?.values() do
        match notify
        |  (let notify': CompleteNotify, let once: Bool) =>
            notify'()
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        discardOnces(subscribers'(FinishedKey)?, onces)
      end
    end

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
      end
      match arr
        | let arr': Subscriptions =>
          var i: USize = 0
          while i < arr'.size() do
            if arr'(i)? is notify then
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

  fun ref notifyData(data: R) =>
    try
      let subscribers': Subscribers  = subscribers()
      var notify'': (DataNotify[R] | None) =  None
      let onces = Array[USize](subscribers'.size())

      var i: USize = 0
      for notify in subscribers'(DataKey[R])?.values() do
        match notify
        |  (let notify': DataNotify[R], let once: Bool) =>
            notify'' = notify'
            if once then
              onces.push(i)
            end
            break
        end
        i = i + 1
      end

      match notify''
      | let notify''': DataNotify[R] =>
        notify'''(consume data)
      end
      if onces.size() > 0 then
        discardOnces(subscribers'(DataKey[R])?,onces)
      end
    end

  be pull()

  be read(cb: {(R)} val, size:(USize | None) = None)

  be piped(stream: WriteablePullStream[R] tag)

  be unpiped(notifiers: Array[Notify tag] iso) =>
    let subscribers': Subscribers = subscribers()
    let notifiers': Array[Notify tag] =  consume notifiers

    let j: USize = 0
    while j < notifiers'.size() do
      try
        unsubscribe(notifiers'(j)?)
      end
    end
    notifyUnpiped()

  fun ref notifyPiped() =>
    try
      let subscribers': Subscribers = subscribers()
      let onces = Array[USize](subscribers'.size())
      var i: USize = 0
      for notify in subscribers'(PipedKey)?.values() do
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
        discardOnces(subscribers'(PipedKey)?, onces)
      end
    end

  fun ref notifyUnpiped() =>
    try
      let subscribers': Subscribers = subscribers()
      let onces = Array[USize](subscribers'.size())
      var i: USize = 0
      for notify in subscribers'(UnpipedKey)?.values() do
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
        discardOnces(subscribers'(UnpipedKey)?, onces)
      end
    end

  fun ref notifyOverflow() =>
    try
      let subscribers': Subscribers = subscribers()
      let onces = Array[USize](subscribers'.size())
      var i: USize = 0
      for notify in subscribers'(OverflowKey)?.values() do
        match notify
        |  (let notify': OverflowNotify, let once: Bool) =>
            notify'()
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        discardOnces(subscribers'(OverflowKey)?, onces)
      end
    end

  be close()
