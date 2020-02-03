use "collections"
use "files"
interface WriteablePushNotify
  fun ref throttled()
  fun ref unthrottled()
  fun ref piped()
  fun ref unpiped()
  fun ref exception(message: String)


interface WriteablePushStream[W: Any #send]
  fun ref _writeSubscribers() : MapIs[WriteablePushNotify tag, WriteablePushNotify]
  fun ref _subscribeWrite(notify: WriteablePushNotify iso) =>
    let writeSubscribers: MapIs[WriteablePushNotify tag, WriteablePushNotify] = _writeSubscribers()
    let notify': WriteablePushNotify ref = consume notify
    writeSubscribers(notify') = notify'
  fun ref _notifyException(message: String) =>
    let writeSubscribers: MapIs[WriteablePushNotify tag, WriteablePushNotify] = _writeSubscribers()
    for notify in writeSubscribers.values() do
      notify.exception(message)
    end
  fun ref _notifyPiped() =>
    let writeSubscribers: MapIs[WriteablePushNotify tag, WriteablePushNotify] = _writeSubscribers()
    for notify in writeSubscribers.values() do
      notify.piped()
    end
  be subscribeWrite(notify: WriteablePushNotify iso) =>
    _subscribeWrite(consume notify)
  be write(data: W) =>
    None
  be piped(stream: ReadablePushStream[W] tag, notify: WriteablePushNotify iso) /* =>
    _subscribeWrite(consume notify)
    let notify': ReadablePushNotify[W] iso = ReadablePushNotify[W]
    stream.subscribeRead(consume notify')
    _notifyPiped()
  */
  be destroy(message: String) =>
    _notifyException(message)

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
interface ReadablePushNotify[R: Any #send]
  fun ref throttled()
  fun ref unthrottled()
  fun ref data(data': R)
  fun ref readable()
  fun ref exception(message: String)
  fun ref finished()

interface ReadablePushStream[R: Any #send]
  fun readable(): Bool
  fun piped(): Bool
  fun ref _readSubscribers() : MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]]
  fun ref _notifyException(message: String) =>
    let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()
    for notify in readSubscribers.values() do
      notify.exception(message)
    end
  fun ref _subscribeRead(notify: ReadablePushNotify[R] iso) =>
    let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()
    if _readSubscribers().size() >= 1 then
      let notify': ReadablePushNotify[R] ref = consume notify
      notify'.exception("Stream has multiple subscribers")
    else
      let notify': ReadablePushNotify[R] ref = consume notify
      readSubscribers(notify') = notify'
    end
  fun ref _notifyData(data: R) =>
    let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()

    var notify: (ReadablePushNotify[R] | None) =  None
    for notify' in readSubscribers.values() do
      notify = notify'
      break
    end
    match notify
      | let notify': ReadablePushNotify[R] =>
        notify'.data(consume data)
    end
  fun ref _notifyFinished() =>
    let readSubscribers: MapIs[ReadablePushNotify[R] tag, ReadablePushNotify[R]] = _readSubscribers()
    for notify in readSubscribers.values() do
      notify.finished()
    end
    readSubscribers.clear()
  be _read()
  be subscribeRead(notify: ReadablePushNotify[R] iso) =>
    _subscribeRead(consume notify)
    if ((_readSubscribers().size() == 1) and (not piped()) and readable()) then
      _read()
    end
  be pipe(stream: WriteablePushStream[R] tag)/* =>
    let notify: WriteablePushNotify[R] iso = WriteablePushNotify[R]
    stream.piped(stream, consume notify)
  */
  be destroy(message: String) =>
    _notifyException(message)

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

actor Main
  new create(env: Env) =>
    try
      let path: FilePath = FilePath(env.root as AmbientAuth, "./file.txt")?
      let path2: FilePath = FilePath(env.root as AmbientAuth, "./file2.txt")?

      let file: File iso = recover
        match CreateFile(path)
          | let file: File =>
            file
        else
          error
        end
      end

      let file2: File iso = recover
        match CreateFile(path2)
          | let file2: File =>
            file2
        else
          error
        end
      end
      let ws: WriteableFileStream = WriteableFileStream(consume file)
      let rs: ReadableFileStream = ReadableFileStream(consume file2)
      rs.pipe(ws)
    else
      None
    end
