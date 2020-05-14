use "collections"
use "files"
use ".."

class _WriteablePullFileStreamNotify is WriteablePullNotify[Array[U8] iso]
  let _stream: ReadablePullStream[Array[U8] iso] tag
  new create(stream: ReadablePullStream[Array[U8] iso] tag) =>
    _stream = stream
  fun ref throttled() => None
  fun ref unthrottled() => None
  fun ref exception(message: String) =>
    _stream.destroy(message)
  fun ref unpipe(notify: ReadablePullNotify[Array[U8] iso] tag) =>
    _stream.unpiped(notify)
  fun ref pull() =>
    _stream.pull()

actor WriteablePullFileStream is WriteablePullStream[Array[U8] iso]
  var _isDestroyed: Bool = false
  let _file: File
  let _subscribers: MapIs[WriteablePullNotify[Array[U8] iso] tag, WriteablePullNotify[Array[U8] iso]]
  var _notify: (ReadablePullNotify[Array[U8] iso] tag | None) = None
  new create(file: File iso) =>
    _subscribers = MapIs[WriteablePullNotify[Array[U8] iso] tag, WriteablePullNotify[Array[U8] iso]](1)
    _file = consume file
  fun ref _writeSubscribers() : MapIs[WriteablePullNotify[Array[U8] iso] tag, WriteablePullNotify[Array[U8] iso]] =>
    _subscribers
  fun ref _pipeNotify(): (ReadablePullNotify[Array[U8] iso] tag | None) =>
    _notify
  fun _destroyed(): Bool =>
    _isDestroyed
  be write(data: Array[U8] iso) =>
    if _destroyed() then
      _notifyException("Stream has been destroyed")
    else
      let data': Array[U8] val = consume data
      let ok = _file.write(data')
      if not ok then
        _notifyException("Failed to write data")
      else
        pull()
      end
    end
  be subscribeWrite(notify: WriteablePullNotify[Array[U8] iso] iso) =>
    if _destroyed() then
      _notifyException("Stream has been destroyed")
    else
      _subscribeWrite(consume notify)
    end

  be destroy(message: String) =>
    _notifyException(message)
    _isDestroyed = true

  be pipe(stream: ReadablePullStream[Array[U8] iso] tag) =>
    if _destroyed() then
      _notifyException("Stream has been destroyed")
    else
      let notify: _ReadablePullFileStreamNotify iso = recover _ReadablePullFileStreamNotify(this) end
      _notify = notify
      stream.piped(this, consume notify)
    end
