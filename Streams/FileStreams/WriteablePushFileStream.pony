use "collections"
use "files"
use ".."

actor WriteablePushFileStream is WriteablePushStream[Array[U8] iso]
  var _isDestroyed: Bool = false
  let _file: File
  let _subscribers': Array[(WriteablePushNotify tag, Bool)]

  new create(file: File iso) =>
    _subscribers = Array[(WriteablePushNotify tag, Bool)](10)
    _file = consume file
  fun ref _subscribers : Array[(WriteablePushNotify tag, Bool)] =>
    _subscribers'
  fun _destroyed(): Bool =>
    _isDestroyed
  be write(data: Array[U8] iso) =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      let ok = _file.write(consume data)
      if not ok then
        _notifyError(Exception("Failed to write data"))
      end
    end
  be piped(stream: ReadablePushStream[Array[U8] iso] tag) =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      let dataNotify: DataNotify iso = {(data': Array[U8] iso) is DataNotify (_stream: WriteablePushStream[Array[U8] iso] tag = this) => _stream.write(consume data') } iso
      stream.subscribe(consume dataNotify)
      let errorNotify: ErrorNotify iso = {(ex: Exception) is ErrorNotify (_stream: ReadablePushStream[Array[U8] iso] tag = this) => _stream.destroy(ex) } iso
      stream.subscribe(consume errorNotify)
      _notifyPiped()
    end

  be destroy(message: (String | Exception)) =>
    match message
      | let message' : String =>
        _notifyError(Exception(message))
      | let message' : Exception =>
        _notifyError(message')
    end
    _isDestroyed = true
