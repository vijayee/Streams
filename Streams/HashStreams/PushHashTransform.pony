use "Blake2b"
use "collections"
use "Exception"
use ".."

actor HashPushTransform is TransformPushStream[Array[U8] iso, Array[U8] iso]
  var _readable: Bool = false
  var _isDestroyed: Bool = false
  let _hash: Blake2b
  let _subscribers': Subscribers
  var _pipeNotifiers': (Array[Notify tag] iso | None) = None
  var _isPiped: Bool = false
  
  new create(digestSize: USize = 32) =>
    _subscribers' = Subscribers(3)
    _hash = Blake2b(digestSize)

  fun ref _subscribers(): Subscribers=>
    _subscribers'

  fun _destroyed(): Bool =>
    _isDestroyed

  fun readable(): Bool =>
    _readable

  fun ref _piped(): Bool =>
    _isPiped

  fun ref _pipeNotifiers(): (Array[Notify tag] iso^ | None) =>
    _pipeNotifiers' = None

  be piped(stream: ReadablePushStream[Array[U8] iso] tag) =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      let dataNotify: DataNotify[Array[U8] iso] iso = object iso is DataNotify[Array[U8] iso]
        let _stream: TransformPushStream[Array[U8] iso, Array[U8] iso] tag = this
        fun ref apply(data': Array[U8] iso) =>
          _stream.write(consume data')
      end
      stream.subscribe(consume dataNotify)
      let errorNotify: ErrorNotify iso = object iso is ErrorNotify
        let _stream: TransformPushStream[Array[U8] iso, Array[U8] iso] tag = this
        fun ref apply(ex: Exception) => _stream.destroy(ex)
      end
      stream.subscribe(consume errorNotify)
      let completeNotify: CompleteNotify iso = object iso is CompleteNotify
        let _stream: TransformPushStream[Array[U8] iso, Array[U8] iso] tag = this
        fun ref apply() =>
          _stream.push()
      end
      stream.subscribe(consume completeNotify)
      let closeNotify: CloseNotify iso = object iso  is CloseNotify
        let _stream: TransformPushStream[Array[U8] iso, Array[U8] iso] tag = this
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

      let errorNotify: ErrorNotify iso = object iso  is ErrorNotify
        let _stream: TransformPushStream[Array[U8] iso, Array[U8] iso] tag = this
        fun ref apply (ex: Exception) => _stream.destroy(ex)
      end
      let errorNotify': ErrorNotify tag = errorNotify
      pipeNotifiers.push(errorNotify')
      stream.subscribe(consume errorNotify)

      _pipeNotifiers' = consume pipeNotifiers
      stream.piped(this)
      _isPiped = true
      _notifyPipe()
    end

  be push() =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      let data: Array[U8] iso = _hash.digest()
      _notifyData(consume data)
      _notifyComplete()
      _close()
    end

  be write(data: Array[U8] iso) =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      _hash.update(consume data)
      if not _readable then
        _readable = true
        _notifyReadable()
      end
    end

  be read(cb: {(Array[U8] iso)} val, size: (USize | None) = None) =>
    if _destroyed() then
      _notifyError(Exception("Stream has been destroyed"))
    else
      let data: Array[U8] iso = _hash.digest()
      cb(consume data)
      _notifyComplete()
    end

  fun ref _close() =>
    if not _destroyed() then
      _isDestroyed = true
      _notifyClose()
      let subscribers: Subscribers = _subscribers()
      subscribers.clear()
      _pipeNotifiers' = None
    end

  be close() =>
    _close()
