use "Exception"
interface WriteablePushStream[W: Any #send] is Stream
  be write(data: W)

  fun ref notifyPiped() =>
    notify(PipedEvent)

  fun ref notifyUnpiped() =>
    notify(UnpipedEvent)

  be piped(stream: ReadablePushStream[W] tag)

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

  fun ref notifyFinished() =>
    notify(FinishedEvent)

  fun ref subscribeInternal(notify': Notify iso, once: Bool = false) =>
   if destroyed() then
     notifyError(Exception("Stream has been destroyed"))
   else
     let subscribers': Subscribers = subscribers()
     let notify'': Notify = consume notify'
     try
       subscribers'(notify'')?.push((notify'', once))
     else
       let arr: Subscriptions = Subscriptions(10)
       arr.push((notify'', once))
       subscribers'(notify'') =  arr
     end
   end

  fun ref unsubscribeInternal(notify': Notify tag) =>
    try
      if destroyed() then
        notifyError(Exception("Stream has been destroyed"))
      else
        let subscribers': Subscribers  = subscribers()
        let arr: (Subscriptions | None) = match notify'
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
        match arr
        | let arr': Subscriptions =>
          try
            var i: USize = 0
            while i < arr'.size() do
              if arr'(i)?._1 is notify' then
                arr'.delete(i)?
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
