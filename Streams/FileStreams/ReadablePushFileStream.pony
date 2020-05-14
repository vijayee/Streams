use "collections"
use "files"
use ".."

actor ReadablePushFileStream is ReadablePushStream[Array[U8] iso]
  var _readable: Bool = true
  var _isDestroyed: Bool = false
  let _file: File
  let _subscribers: MapIs[ReadablePushNotify[Array[U8] iso] tag, ReadablePushNotify[Array[U8] iso]]
  let _chunkSize: USize
  var _notify: (WriteablePushNotify tag | None) = None

  new create(file: File iso, chunkSize: USize = 64000) =>
    _subscribers = MapIs[ReadablePushNotify[Array[U8] iso] tag, ReadablePushNotify[Array[U8] iso]](1)
    _file = consume file
    _chunkSize = chunkSize
  fun readable(): Bool =>
    _readable

  fun _destroyed(): Bool =>
    _isDestroyed
  fun ref _pipeNotify(): (WriteablePushNotify tag | None) =>
    _notify
  fun ref _readSubscribers() : MapIs[ReadablePushNotify[Array[U8] iso] tag, ReadablePushNotify[Array[U8] iso]] =>
    _subscribers
  be push() =>
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
      else
        push()
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

  be pipe(stream: WriteablePushStream[Array[U8] iso] tag) =>
    if _destroyed() then
      _notifyException("Stream has been destroyed")
    else
      let notify: _WriteablePushFileStreamNotify iso = recover _WriteablePushFileStreamNotify(this)  end
      _notify = notify
      stream.piped(this, consume notify)
    end

  be subscribeRead(notify: ReadablePushNotify[Array[U8] iso] iso) =>
    _subscribeRead(consume notify)

  be destroy(message: String) =>
    _notifyException(message)
    _isDestroyed = true



class _ReadablePushFileStreamNotify is ReadablePushNotify[Array[U8] iso]
  let _stream: WriteablePushStream[Array[U8] iso] tag
  new create(stream: WriteablePushStream[Array[U8] iso] tag) =>
    _stream = stream
  fun ref data(data': Array[U8] iso) =>
    _stream.write(consume data')
  fun ref throttled() => None
  fun ref unthrottled() => None
  fun ref readable() => None
  fun ref exception(message: String) =>
    _stream.destroy(message)
  fun ref finished() =>
    None
  fun ref unpipe(notify: WriteablePushNotify tag) =>
    _stream.unpiped(notify)
