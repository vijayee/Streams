use "collections"
use "Exception"
use "files"
use ".."

actor WriteablePullFileStream is WriteablePullStream[Array[U8] iso]
  var _isDestroyed: Bool = false
  let _file: File
  let _subscribers': Subscribers
  var _pipeNotifiers': (Array[Notify tag] iso | None) = None
  var _isPiped: Bool = false

  new create(file: File iso) =>
    _subscribers' = Subscribers(3)
    _file = consume file

  fun ref subscribers(): Subscribers=>
    _subscribers'

  fun ref pipeNotifiers(): (Array[Notify tag] iso^ | None) =>
    _pipeNotifiers' = None

  fun destroyed(): Bool =>
    _isDestroyed

  be write(data: Array[U8] iso) =>
    if destroyed() then
      notifyError(Exception("Stream has been destroyed"))
    else
      let ok = _file.write(consume data)
      if not ok then
        notifyError(Exception("Failed to write data"))
      end
    end

  be pipe(stream: ReadablePullStream[Array[U8] iso] tag) =>
    if destroyed() then
      notifyError(Exception("Stream has been destroyed"))
    else
      let pipeNotifiers': Array[Notify tag] iso = try
         pipeNotifiers() as Array[Notify tag] iso^
      else
        let pipeNotifiers'' = recover Array[Notify tag] end
        consume pipeNotifiers''
      end

      let dataNotify: DataNotify[Array[U8] iso] iso = object iso is DataNotify[Array[U8] iso]
        let _stream: WriteablePullStream[Array[U8] iso] tag = this
        fun ref apply(data': Array[U8] iso) =>
          _stream.write(consume data')
          stream.pull()
      end
      stream.subscribe(consume dataNotify)

      let pipedNotify: PipedNotify iso =  object iso is PipedNotify
        fun ref apply() =>
          stream.pull()
      end
      let pipedNotify': PipedNotify tag = pipedNotify
      pipeNotifiers'.push(pipedNotify')
      stream.subscribe(consume pipedNotify)

      let errorNotify: ErrorNotify iso = object iso  is ErrorNotify
        let _stream: WriteablePullStream[Array[U8] iso] tag = this
        fun ref apply (ex: Exception) => _stream.destroy(ex)
      end
      let errorNotify': ErrorNotify tag = errorNotify
      pipeNotifiers'.push(errorNotify')
      stream.subscribe(consume errorNotify)

      let completeNotify: CompleteNotify iso = object iso  is CompleteNotify
        let _stream: WriteablePullStream[Array[U8] iso] tag = this
        fun ref apply () => _stream.close()
      end
      let completeNotify': CompleteNotify tag = completeNotify
      pipeNotifiers'.push(completeNotify')
      stream.subscribe(consume completeNotify)

      let closeNotify: CloseNotify iso = object iso  is CloseNotify
        let _stream: WriteablePullStream[Array[U8] iso] tag = this
        fun ref apply () => _stream.close()
      end
      let closeNotify': CloseNotify tag = closeNotify
      pipeNotifiers'.push(closeNotify')
      stream.subscribe(consume closeNotify)

      _pipeNotifiers' = consume pipeNotifiers'
      stream.piped(this)
      _isPiped = true
      notifyPipe()
    end

  be destroy(message: (String | Exception)) =>
    match message
      | let message' : String =>
        notifyError(Exception(message'))
      | let message' : Exception =>
        notifyError(message')
    end
    _isDestroyed = true
    _file.dispose()
    let subscribers': Subscribers = subscribers()
    subscribers'.clear()

  be close() =>
    if not destroyed() then
      _isDestroyed = true
      _file.dispose()
      notifyClose()
      let subscribers': Subscribers = subscribers()
      subscribers'.clear()
      _pipeNotifiers' = None
      _isPiped = false
    end
