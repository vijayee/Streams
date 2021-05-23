use "Exception"
use "files"
use ".."

actor DuplexPushFileStream is DuplexPushStream[Array[U8] iso]
  var _readable: Bool = true
  var _isDestroyed: Bool = false
  let _file: File
  let _subscribers': Subscribers
  let _chunkSize: USize
  var _pipeNotifiers': (Array[Notify tag] iso | None) = None
  var _isPiped: Bool = false

  new create(file: File iso, chunkSize: USize = 64000) =>
    _subscribers' = Subscribers(3)
    _file = consume file
    _chunkSize = chunkSize

  fun ref _subscribers(): Subscribers=>
    _subscribers'

  fun _destroyed(): Bool =>
    _isDestroyed

  fun readable(): Bool =>
    _readable

  be push() =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      let chunk: Array[U8] iso = if ((_file.size() - _file.position()) < _chunkSize) then
        _file.read((_file.size() - _file.position()))
      else
        _file.read(_chunkSize)
      end
      _notifyData(consume chunk)
      if (_file.size() == _file.position()) then
        _notifyComplete()
        closeRead()
      else
        push()
      end
    end

  be write(data: Array[U8] iso) =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      let ok = _file.write(consume data)
      if not ok then
        _notifyError(Exception("Failed to write data"))
      end
    end

  be read(size: (USize | None) = None, cb: {(Array[U8] iso)} val) =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      let chunk: Array[U8] iso = match size
        | let size': USize =>
          if ((_file.size() - _file.position()) < size') then
            _file.read((_file.size() - _file.position()))
          else
            _file.read(size')
          end
        else
          _file.read(_file.size())
      end
      cb(consume chunk)
      if (_file.size() == _file.position()) then
        _notifyComplete()
      end
    end

  fun ref _piped(): Bool =>
    _isPiped

  fun ref _pipeNotifiers(): (Array[Notify tag] iso^ | None) =>
    _pipeNotifiers' = None

  be piped(stream: ReadablePushStream[Array[U8] iso] tag) =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      let dataNotify: DataNotify[Array[U8] iso] iso = object iso is DataNotify[Array[U8] iso]
        let _stream: DuplexPushStream[Array[U8] iso] tag = this
        fun ref apply(data': Array[U8] iso) =>
          _stream.write(consume data')
      end
      stream.subscribe(consume dataNotify)
      let errorNotify: ErrorNotify iso = object iso is ErrorNotify
        let _stream: DuplexPushStream[Array[U8] iso] tag = this
        fun ref apply(ex: Exception) => _stream.destroy(ex)
      end
      stream.subscribe(consume errorNotify)
      let completeNotify: CompleteNotify iso = object iso is CompleteNotify
        let _stream: DuplexPushStream[Array[U8] iso] tag = this
        fun ref apply() => _stream.close()
      end
      stream.subscribe(consume completeNotify)
      let closeNotify: CloseNotify iso = object iso  is CloseNotify
        let _stream: DuplexPushStream[Array[U8] iso] tag = this
        fun ref apply () => _stream.close()
      end
      let closeNotify': CloseNotify tag = closeNotify
      stream.subscribe(consume closeNotify)
      _notifyPiped()
    end

  be pipe(stream: WriteablePushStream[Array[U8] iso] tag) =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      let pipeNotifiers: Array[Notify tag] iso = try
         _pipeNotifiers() as Array[Notify tag] iso^
      else
        let pipeNotifiers' = recover Array[Notify tag] end
        consume pipeNotifiers'
      end

      let pipedNotify: PipedNotify iso =  object iso is PipedNotify
        let _stream: DuplexPushStream[Array[U8] iso] tag = this
        fun ref apply() =>
          _stream.push()
      end
      let pipedNotify': PipedNotify tag = pipedNotify
      pipeNotifiers.push(pipedNotify')
      stream.subscribe(consume pipedNotify)

      let errorNotify: ErrorNotify iso = object iso  is ErrorNotify
        let _stream: DuplexPushStream[Array[U8] iso] tag = this
        fun ref apply (ex: Exception) => _stream.destroy(ex)
      end
      let errorNotify': ErrorNotify tag = errorNotify
      pipeNotifiers.push(errorNotify')
      stream.subscribe(consume errorNotify)

      let closeNotify: CloseNotify iso = object iso  is CloseNotify
        let _stream: DuplexPushStream[Array[U8] iso] tag = this
        fun ref apply () => _stream.close()
      end
      let closeNotify': CloseNotify tag = closeNotify
      pipeNotifiers.push(closeNotify')
      stream.subscribe(consume closeNotify)

      _pipeNotifiers' = consume pipeNotifiers
      stream.piped(this)
      _isPiped = true
      _notifyPipe()
    end

  be destroy(message: (String | Exception)) =>
    match message
      | let message' : String =>
        _notifyError(Exception(message'))
      | let message' : Exception =>
        _notifyError(message')
    end
    _isDestroyed = true
    _file.dispose()
    let subscribers: Subscribers = _subscribers()
    subscribers.clear()
    _pipeNotifiers' = None

  fun ref _close() =>
    if not _destroyed() then
      _isDestroyed = true
      _file.dispose()
      _notifyClose()
      let subscribers: Subscribers = _subscribers()
      subscribers.clear()
      _pipeNotifiers' = None
    end

  be close() =>
    _close()

  be closeRead() =>
    _close()

  be closeWrite() =>
    _close()
