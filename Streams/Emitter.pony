use "Exception"
interface NotificationEmitter
  fun ref subscribers(): Subscribers

  be subscribe(notify': Notify iso, once: Bool = false) =>
    subscribeInternal(consume notify', once)

  fun ref subscribeInternal(notify': Notify iso, once: Bool = false) =>
    let subscribers': Subscribers = subscribers()
    let notify'': Notify = consume notify'
    try
      subscribers'(notify'')?.push((notify'', once))
    else
      let arr: Subscriptions = Subscriptions(10)
      arr.push((notify'', once))
      subscribers'(notify'') =  arr
    end

  fun ref subscriberCount(notify':(Notify box | None) = None): USize =>
    let subscribers': Subscribers = subscribers()
    try
      match notify'
        | None =>
          var i: USize = 0
          for bucket in subscribers'.values() do
            i = i + bucket.size()
          end
          i
        | let notify'': Notify box =>
          subscribers'(notify'')?.size()
      end
    else
      0
    end

  fun ref discardOnces(subscribers': Subscriptions, onces: Array[USize]) =>
    var i: USize = 0
    for index in onces.values() do
      try
        subscribers'.delete((index - (i = i + 1)))?
      end
    end

  fun ref unsubscribeInternal(notify': Notify tag) =>
    let subscribers': Subscribers = subscribers()
    try
      for bucket in subscribers'.values() do
        var i: USize = 0
        while i < bucket.size() do
          if bucket(i)?._1 is notify' then
            bucket.delete(i)?
            return
          else
            i = i + 1
          end
        end
      end
    end

  be unsubscribe(notify': Notify tag) =>
    unsubscribeInternal(notify')


  fun ref notifyPayload[A: Any #send] (event: PayloadNotify[A] box, data: A) =>
    let subscribers': Subscribers  = subscribers()
    let onces = Array[USize](subscribers'.size())
    try
      iftype A <: Any #share then
        var i: USize = 0
        for notify' in subscribers'(event)?.values() do
          match notify'
          |  (let notify'': PayloadNotify[A], let once: Bool) =>
              notify''(data)
              if once then
                onces.push(i)
              end
          end
          i = i + 1
        end
        if onces.size() > 0 then
          discardOnces(subscribers'(event)?, onces)
        end
      else
        let notify' = subscribers'(event)?(0)?
        match notify'
        |  (let notify'': PayloadNotify[A], let once: Bool) =>
            notify''(consume data)
            if once then
              onces.push(0)
            end
        end
        if onces.size() > 0 then
          discardOnces(subscribers'(event)?,onces)
        end
      end
    end


  fun ref notify(event: VoidNotify box) =>
    try
      let subscribers': Subscribers = subscribers()
      let onces = Array[USize](subscribers'.size())
      var i: USize = 0
      for notify' in subscribers'(event)?.values() do
        match notify'
        |  (let notify'': VoidNotify, let once: Bool) =>
            notify''()
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        discardOnces(subscribers'(event)?, onces)
      end
    end


  fun ref notifyError(ex: Exception) =>
    notifyPayload[Exception](ErrorEvent, ex)
