use "collections"
use "Exception"
interface ReadablePullStream[R: Any #send]
  fun readable(): Bool

  fun _destroyed(): Bool

  fun ref _discardOnces(subscribers: Subscriptions, onces: Array[USize]) =>
    var i: USize = 0
    for index in onces.values() do
      try
        subscribers.delete((index - (i = i + 1)))?
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
      elseif A <: PipedNotify then
        subscribers(PipedKey)?.size()
      elseif A <: UnpipedNotify then
        subscribers(UnpipedKey)?.size()
      elseif A <: DataNotify[R] then
        subscribers(DataKey[R])?.size()
      elseif A <: ReadableNotify then
        subscribers(ReadableKey)?.size()
      elseif A <: FinishedNotify then
        subscribers(FinishedKey)?.size()
      else
        0
      end
    else
      0
    end
  fun ref _subscribers() : Subscribers

  fun ref _notifyError(ex: Exception) =>
    try
      let subscribers: Subscribers = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(ErrorKey)?.values() do
        match notify
        |  (let notify': ErrorNotify, let once: Bool) =>
            notify'(ex)
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        _discardOnces(subscribers(ErrorKey)?, onces)
      end
    end

  fun ref _notifyReadable() =>
    if readable() then
      try
        let subscribers: Subscribers = _subscribers()
        let onces = Array[USize](subscribers.size())
        var i: USize = 0
        for notify in subscribers(ReadableKey)?.values() do
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
          _discardOnces(subscribers(ReadableKey)?, onces)
        end
      end
    end

  fun ref _subscribe(notify: Notify iso, once: Bool = false) =>
    let subscribers: Subscribers = _subscribers()
    let notify': Notify = consume notify

    match notify'
      | let notify'': DataNotify[R]  =>
        if _subscriberCount[DataNotify[R]]() < 1 then
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
        | let notify': PipeNotify tag =>
          subscribers(PipeKey)?
        | let notify': UnpipeNotify tag =>
          subscribers(UnpipeKey)?
        | let notify': DataNotify[R] tag =>
          subscribers(DataKey[R])?
        | let notify': ReadableNotify tag =>
          subscribers(ReadableKey)?
        | let notify': FinishedNotify tag =>
          subscribers(FinishedKey)?
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
      _notifyError(Exception("Failed to Unsubscribe"))
    end

  fun ref _notifyData(data: R) =>
    try
      let subscribers: Subscribers  = _subscribers()
      var notify'': (DataNotify[R] | None) =  None
      let onces = Array[USize](subscribers.size())

      var i: USize = 0
      for notify in subscribers(DataKey[R])?.values() do
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
        _discardOnces(subscribers(DataKey[R])?,onces)
      end
    end

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

  fun ref _notifyClose() =>
    try
      let subscribers: Subscribers = _subscribers()
      let onces = Array[USize](subscribers.size())
      var i: USize = 0
      for notify in subscribers(CloseKey)?.values() do
        match notify
        |  (let notify': CloseNotify, let once: Bool) =>
            notify'()
            if once then
              onces.push(i)
            end
        end
        i = i + 1
      end
      if onces.size() > 0 then
        _discardOnces(subscribers(CloseKey)?, onces)
      end
      subscribers.clear()
    end

  be pull()

  be read(size:(USize | None) = None, cb: {(R)} val)

  be subscribe(notify: Notify iso, once: Bool = false) =>
    _subscribe(consume notify, once)

  be unsubscribe(notify: Notify tag) =>
    _unsubscribe(notify)

  be piped(stream: WriteablePullStream[R] tag)

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

  be destroy(message: (String | Exception)) =>
    match message
      | let message' : String =>
        _notifyError(Exception(message'))
      | let message' : Exception =>
        _notifyError(message')
    end

  be close()
