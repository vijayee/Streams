use "collections"
use "files"
use ".."

actor ReadablePushFileStream is ReadablePushStream[Array[U8] iso]
  var _readable: Bool = true
  var _isDestroyed: Bool = false
  let _file: File
  let _subscribers': Array[(WriteablePushNotify tag, Bool)]
  let _chunkSize: USize
  var _pipeNotifiers': (Array[WriteablePushNotify tag] iso | None)= None

  new create(file: File iso, chunkSize: USize = 64000) =>
    _subscribers = Array[(WriteablePushNotify tag, Bool)](10)
    _file = consume file
    _chunkSize = chunkSize
  fun readable(): Bool =>
    _readable

  fun _destroyed(): Bool =>
    _isDestroyed

  fun ref _pipeNotifiers: (Array[WriteablePushNotify tag] iso | None) =>
    _pipeNotifiers'

  fun ref _subscribers() : Array[(WriteablePushNotify tag, Bool)] =>
    _subscribers'

  be push() =>
    if _destroyed() then
      _notifyError(Exeption("Stream has been destroyed"))
    else
      let chunk: Array[U8] iso = if ((_file.size() - _file.position()) < _chunkSize) then
        _file.read((_file.size() - _file.position()))
      else
        _file.read(_chunkSize)
      end
      _notifyData(consume chunk)
      if (_file.size() == _file.position()) then
        _notifyFinished()
      else
        push()
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

  be pipe(stream: WriteablePushStream[Array[U8] iso] tag) =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      let pipeNotifiers: Array[WriteablePushNotify tag] iso = match _pipeNotifers()
      | None =>
        _pipeNotifiers' = recover Array[WriteablePushNotify tag] end
        _pipeNotifiers'
      | let pipeNotifiers': Array[WriteablePushNotify tag] iso =>
        pipeNotifiers'
      end

      let pipedNotify: PipeNotify iso = {() (_stream: ReadablePushStream[Array[U8] iso] tag = this) => _stream.push() } iso
      let pipedNotify': PipeNotify tag = pipedNotify
      pipeNotifiers.push(pipedNotify')
      stream.subscribe(consume pipedNotify)

      let errorNotify: ErrorNotify iso = {(ex: Exception) is ErrorNotify (_stream: ReadablePushStream[Array[U8] iso] tag = this) => _stream.destroy(ex) } iso
      let errorNotify': ErrorNotify tag = errorNotify
      pipeNotifiers.push(errorNotify')
      stream.subscribe(consume errorNotify)

      stream.piped(this)
      _notifyPipe()
    end

  be destroy(message: (String | Exception)) =>
    _notifyError(message)
    _isDestroyed = true
