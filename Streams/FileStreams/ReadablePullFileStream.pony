use "collections"
use "files"
use ".."

class _ReadablePullFileStreamNotify is ReadablePullNotify[Array[U8] iso]
  let _stream: WriteablePullStream[Array[U8] iso] tag
  var _piped: Bool = false
  var _started: Bool = false
  new create(stream: WriteablePullStream[Array[U8] iso] tag) =>
    _stream = stream
  fun ref throttled() => None
  fun ref unthrottled() => None
  fun ref data(data': Array[U8] iso) =>    
    _stream.write(consume data')
  fun ref piped() =>
    _piped = true
    _stream.pull()
  fun ref exception(message: String) =>
    _stream.destroy(message)
  fun ref unpiped() => None
  fun ref readable() =>
    if (_piped == true) and (_started == false) then
      _started = true
    end
  fun ref finished() => None

actor ReadablePullFileStream is ReadablePullStream[Array[U8] iso]
  var _readable: Bool = false
  var _isDestroyed: Bool = false
  let _file: File
  let _subscribers: MapIs[ReadablePullNotify[Array[U8] iso] tag, ReadablePullNotify[Array[U8] iso]]
  let _chunkSize: USize

  new create(file: File iso, chunkSize: USize = 64000) =>
    _subscribers = MapIs[ReadablePullNotify[Array[U8] iso] tag, ReadablePullNotify[Array[U8] iso]](1)
    _file = consume file
    _chunkSize = chunkSize
    _readable = true
  fun readable(): Bool =>
    _readable
  fun ref _readSubscribers() : MapIs[ReadablePullNotify[Array[U8] iso] tag, ReadablePullNotify[Array[U8] iso]] =>
    _subscribers
  fun _destroyed(): Bool =>
    _isDestroyed
  be pull() =>
    if _destroyed() then
      _notifyException("Stream has been destroyed")
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
      _notifyException("Stream has been destroyed")
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

  be piped(stream: WriteablePullStream[Array[U8] iso] tag, notify: ReadablePullNotify[Array[U8] iso] iso) =>
    if _destroyed() then
      _notifyException("Stream has been destroyed")
    else
      _subscribeRead(consume notify)
      let notify': _WriteablePullFileStreamNotify iso = recover _WriteablePullFileStreamNotify(this) end
      stream.subscribeWrite(consume notify')
      _notifyPiped()
    end

  be subscribeRead(notify: ReadablePullNotify[Array[U8] iso] iso) =>
    _subscribeRead(consume notify)

  be destroy(message: String) =>
    _notifyException(message)
    _isDestroyed = true
