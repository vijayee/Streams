use "collections"
use "files"

actor WriteableFileStream is WriteablePushStream[Array[U8] iso]
  var _destroyed: Bool = false
  let _file: File
  let _subscribers: MapIs[WriteablePushNotify tag, WriteablePushNotify]
  new create(file: File iso) =>
    _subscribers = MapIs[WriteablePushNotify tag, WriteablePushNotify](1)
    _file = consume file
  fun ref _writeSubscribers() : MapIs[WriteablePushNotify tag, WriteablePushNotify] =>
    _subscribers
  be write(data: Array[U8] iso) =>
    if _destroyed then
      _notifyException("Stream has been destroyed")
    else
      let ok = _file.write(consume data)
      if not ok then
        _notifyException("Failed to write data")
      end
    end
  be subscribeWrite(notify: WriteablePushNotify iso) =>
    if _destroyed then
      _notifyException("Stream has been destroyed")
    else
      _subscribeWrite(consume notify)
    end
  be piped(stream: ReadablePushStream[Array[U8] iso] tag, notify: WriteablePushNotify iso) =>
    if _destroyed then
      _notifyException("Stream has been destroyed")
    else
      _subscribeWrite(consume notify)
      let notify': _ReadableFileStreamNotify iso = recover _ReadableFileStreamNotify(this) end
      stream.subscribeRead(consume notify')
      _notifyPiped()
    end
  be destroy(message: String) =>
    _notifyException(message)
    _destroyed = true


actor ReadableFileStream is ReadablePushStream[Array[U8] iso]
  var _readable: Bool = false
  var _piped: Bool = false
  var _destroyed: Bool = false
  let _file: File
  let _subscribers: MapIs[ReadablePushNotify[Array[U8] iso] tag, ReadablePushNotify[Array[U8] iso]]
  let _chunkSize: USize

  new create(file: File iso, chunkSize: USize = 64000) =>
    _subscribers = MapIs[ReadablePushNotify[Array[U8] iso] tag, ReadablePushNotify[Array[U8] iso]](1)
    _file = consume file
    _chunkSize = chunkSize
  fun readable(): Bool =>
    _readable
  fun piped(): Bool =>
    _piped
  fun ref _readSubscribers() : MapIs[ReadablePushNotify[Array[U8] iso] tag, ReadablePushNotify[Array[U8] iso]] =>
    _subscribers

  be _read() =>
    if _destroyed then
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
        _read()
      end
    end

  be pipe(stream: WriteablePushStream[Array[U8] iso] tag) =>
    if _destroyed then
      _notifyException("Stream has been destroyed")
    else
      let notify: _WriteableFileStreamNotify iso = recover _WriteableFileStreamNotify(this)  end
      stream.piped(this, consume notify)
      _piped= true
    end

  be subscribeRead(notify: ReadablePushNotify[Array[U8] iso] iso) =>
    _subscribeRead(consume notify)

  be destroy(message: String) =>
    _notifyException(message)
    _destroyed = true

class _WriteableFileStreamNotify is WriteablePushNotify
  let _stream: ReadableFileStream
  new create(stream: ReadableFileStream) =>
    _stream = stream
  fun ref throttled() => None
  fun ref unthrottled() => None
  fun ref readable() => None
  fun ref unpiped() => None
  fun ref piped() =>
    _stream._read()
  fun ref exception(message: String) =>
    _stream.destroy(message)

class _ReadableFileStreamNotify is ReadablePushNotify[Array[U8] iso]
  let _stream: WriteableFileStream
  new create(stream: WriteableFileStream) =>
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
