use "Exception"
interface Stream is NotificationEmitter
  fun destroyed(): Bool

  be destroy(message: (String | Exception)) =>
    match message
      | let message' : String =>
        notifyError(Exception(message'))
      | let message' : Exception =>
        notifyError(message')
    end

  fun ref notifyClose() =>
    notify(CloseEvent)

  fun ref notifyUnthrottled() =>
    notify(UnthrottledEvent)

  fun ref notifyThrottled() =>
    notify(ThrottledEvent)

  be close()
