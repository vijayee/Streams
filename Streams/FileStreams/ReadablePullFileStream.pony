use "collections"
use "files"
use "Exception"
use ".."

actor ReadablePullFileStream is ReadablePullStream[Array[U8] iso]
  var _readable: Bool = true
  var _isDestroyed: Bool = false
  let _file: File
  let _subscribers': Subscribers
  let _chunkSize: USize

  new create(file: File iso, chunkSize: USize = 64000) =>
    _subscribers' = Subscribers(3)
    _file = consume file
    _chunkSize = chunkSize

  fun readable(): Bool =>
    _readable

  fun _destroyed(): Bool =>
    _isDestroyed

  fun ref _subscribers() : Subscribers =>
    _subscribers'

  be pull() =>
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
        _notifyFinished()
        _isDestroyed = true
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
        _notifyFinished()
      end
    end

  be destroy(message: (String | Exception)) =>
    match message
      | let message' : String =>
        _notifyError(Exception(message'))
      | let message' : Exception =>
        _notifyError(message')
    end
  _isDestroyed = true

  be close() =>
    if not _destroyed() then
      _isDestroyed = true
      _notifyClose()
      _file.dispose()
      let subscribers: Subscribers = _subscribers()
      subscribers.clear()
    end

  be piped(stream: WriteablePullStream[Array[U8] iso] tag) =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      let errorNotify: ErrorNotify iso = object iso is ErrorNotify
        let _stream: ReadablePullStream[Array[U8] iso] tag = this
        fun ref apply(ex: Exception) => _stream.destroy(ex)
      end
      stream.subscribe(consume errorNotify)
      let finishedNotify: FinishedNotify iso = object iso is FinishedNotify
        let _stream: ReadablePullStream[Array[U8] iso] tag = this
        fun ref apply() => _stream.close()
      end
      stream.subscribe(consume finishedNotify)
      let closeNotify: CloseNotify iso = object iso  is CloseNotify
        let _stream: ReadablePullStream[Array[U8] iso] tag = this
        fun ref apply () => _stream.close()
      end
      let closeNotify': CloseNotify tag = closeNotify
      stream.subscribe(consume closeNotify)
      _notifyPiped()
    end
