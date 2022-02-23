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

  fun ref subscribers(): Subscribers=>
    _subscribers'

  fun destroyed(): Bool =>
    _isDestroyed

  fun readable(): Bool =>
    _readable

  fun ref isPiped(): Bool =>
    _isPiped

  fun ref pipeNotifiers(): (Array[Notify tag] iso^ | None) =>
    _pipeNotifiers' = None

  be piped(stream: ReadablePushStream[Array[U8] iso] tag) =>
    if destroyed() then
      notifyError(Exception("Stream has been destroyed"))
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
      notifyPiped()
    end

  be pipe(stream: WriteablePushStream[Array[U8] iso] tag) =>
    if destroyed() then
      notifyError(Exception("Stream has been destroyed"))
    else
      let pipeNotifiers': Array[Notify tag] iso = try
         pipeNotifiers() as Array[Notify tag] iso^
      else
        let pipeNotifiers'' = recover Array[Notify tag] end
        consume pipeNotifiers''
      end

      let errorNotify: ErrorNotify iso = object iso  is ErrorNotify
        let _stream: TransformPushStream[Array[U8] iso, Array[U8] iso] tag = this
        fun ref apply (ex: Exception) => _stream.destroy(ex)
      end
      let errorNotify': ErrorNotify tag = errorNotify
      pipeNotifiers'.push(errorNotify')
      stream.subscribe(consume errorNotify)

      _pipeNotifiers' = consume pipeNotifiers'
      stream.piped(this)
      _isPiped = true
      notifyPipe()
    end

  be push() =>
    if destroyed() then
      notifyError(Exception("Stream has been destroyed"))
    else
      let data: Array[U8] iso = _hash.digest()
      notifyData(consume data)
      notifyComplete()
      close()
    end

  be write(data: Array[U8] iso) =>
    if destroyed() then
      notifyError(Exception("Stream has been destroyed"))
    else
      _hash.update(consume data)
      if not _readable then
        _readable = true
        notifyReadable()
      end
    end

  be read(cb: {(Array[U8] iso)} val, size: (USize | None) = None) =>
    if destroyed() then
      notifyError(Exception("Stream has been destroyed"))
    else
      let data: Array[U8] iso = _hash.digest()
      cb(consume data)
      notifyComplete()
    end

  fun ref _close() =>
    if not destroyed() then
      _isDestroyed = true
      notifyClose()
      let subscribers': Subscribers = subscribers()
      subscribers'.clear()
      _pipeNotifiers' = None
    end

  be close() =>
    _close()
