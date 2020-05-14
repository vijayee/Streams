use "collections"
use "files"
use ".."

actor WriteablePushFileStream is WriteablePushStream[Array[U8] iso]
  var _isDestroyed: Bool = false
  let _file: File
  let _subscribers: MapIs[WriteablePushNotify tag, WriteablePushNotify]
  new create(file: File iso) =>
    _subscribers = MapIs[WriteablePushNotify tag, WriteablePushNotify](1)
    _file = consume file
  fun ref _writeSubscribers() : MapIs[WriteablePushNotify tag, WriteablePushNotify] =>
    _subscribers
  fun _destroyed(): Bool =>
    _isDestroyed
  be write(data: Array[U8] iso) =>
    if _destroyed() then
      _notifyException("Stream has been destroyed")
    else
      let ok = _file.write(consume data)
      if not ok then
        _notifyException("Failed to write data")
      end
    end
  be subscribeWrite(notify: WriteablePushNotify iso) =>
    if _destroyed() then
      _notifyException("Stream has been destroyed")
    else
      _subscribeWrite(consume notify)
    end
  be piped(stream: ReadablePushStream[Array[U8] iso] tag, notify: WriteablePushNotify iso) =>
    if _destroyed() then
      _notifyException("Stream has been destroyed")
    else
      _subscribeWrite(consume notify)
      let notify': _ReadablePushFileStreamNotify iso = recover _ReadablePushFileStreamNotify(this) end
      stream.subscribeRead(consume notify')
      _notifyPiped()
    end

  be destroy(message: String) =>
    _notifyException(message)
    _isDestroyed = true

class _WriteablePushFileStreamNotify is WriteablePushNotify
  let _stream: ReadablePushStream[Array[U8] iso] tag
  new create(stream: ReadablePushStream[Array[U8] iso] tag) =>
    _stream = stream
  fun ref throttled() => None
  fun ref unthrottled() => None
  fun ref readable() => None
  fun ref unpiped() => None
  fun ref piped() =>
    _stream.push()
  fun ref exception(message: String) =>
    _stream.destroy(message)
