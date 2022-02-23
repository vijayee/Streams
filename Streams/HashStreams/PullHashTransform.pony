use "Blake2b"
use "collections"
use "Exception"
use ".."

actor HashPullTransform is TransformPullStream[Array[U8] iso, Array[U8] iso]
  var _readable: Bool = false
  var _isDestroyed: Bool = false
  let _hash: Blake2b
  let _subscribers': Subscribers
  var _pipeNotifiers': (Array[Notify tag] iso | None) = None
  var _isPiped: Bool = false
  var _hasBeenPulled: Bool = false
  var _pullSource: {()} val = {() => None} val


  new create(digestSize: USize = 32) =>
    _subscribers' = Subscribers(3)
    _hash = Blake2b(digestSize)

  fun ref subscribers(): Subscribers=>
    _subscribers'

  fun destroyed(): Bool =>
    _isDestroyed

  fun readable(): Bool =>
    _readable

  fun ref _hasReaders(): Bool =>
    subscriberCount[DataNotify[Array[U8] iso]]() > 0

  fun ref _shouldPull(): Bool =>
      _isPiped and _hasReaders() and _hasBeenPulled

  fun ref isPiped(): Bool =>
    _isPiped

  be _setPiped() =>
    _isPiped = true
    if _shouldPull() then
      _pullSource()
    end

  fun ref subscribeInternal(notify: Notify iso, once: Bool = false) =>
    let subscribers': Subscribers = subscribers()
    let notify': Notify = consume notify

    match notify'
      | let notify'': DataNotify[Array[U8] iso]  =>
        if subscriberCount[DataNotify[Array[U8] iso]]() < 1 then
          try
            subscribers'(notify')?.push((notify', once))
          else
            let arr: Subscriptions = Subscriptions(10)
            arr.push((notify', once))
            subscribers'(notify') =  arr
            if _shouldPull() then
              _pullSource()
            end
          end
        else
          notifyError(Exception("Multiple Data Subscribers"))
        end
      | let notify'': UnpipeNotify =>
        if subscriberCount[UnpipeNotify]() < 1 then
          try
            subscribers'(notify')?.push((notify', once))
          else
            let arr: Subscriptions = Subscriptions(10)
            arr.push((notify', once))
            subscribers'(notify') =  arr
          end
        else
          notifyError(Exception("Multiple Unpipe Subscribers"))
        end
      | let notify'': ReadableNotify =>
        try
          subscribers'(notify')?.push((notify', once))
        else
          let arr: Subscriptions = Subscriptions(10)
          arr.push((notify', once))
          subscribers'(notify') =  arr
        end
        notifyReadable()
      else
        try
          subscribers'(notify')?.push((notify', once))
        else
          let arr: Subscriptions = Subscriptions(10)
          arr.push((notify', once))
          subscribers'(notify') =  arr
        end
    end

  fun ref pipeNotifiers(): (Array[Notify tag] iso^ | None) =>
    _pipeNotifiers' = None

  be piped(stream: WriteablePullStream[Array[U8] iso] tag) =>
    if destroyed() then
      notifyError(Exception("Stream has been destroyed"))
    else
      let errorNotify: ErrorNotify iso = object iso is ErrorNotify
        let _stream: HashPullTransform tag = this
        fun ref apply(ex: Exception) => _stream.destroy(ex)
      end
      stream.subscribe(consume errorNotify)
      let finishedNotify: FinishedNotify iso = object iso is FinishedNotify
        let _stream: HashPullTransform tag = this
        fun ref apply() => _stream.close()
      end
      stream.subscribe(consume finishedNotify)
      let closeNotify: CloseNotify iso = object iso  is CloseNotify
        let _stream: HashPullTransform tag = this
        fun ref apply () => _stream.close()
      end
      let closeNotify': CloseNotify tag = closeNotify
      stream.subscribe(consume closeNotify)
      notifyPiped()
    end

  be pipe(stream: ReadablePullStream[Array[U8] iso] tag) =>
    if destroyed() then
      notifyError(Exception("Stream has been destroyed"))
    else
      _pullSource = {() => stream.pull()} val

      let pipeNotifiers': Array[Notify tag] iso = try
         pipeNotifiers() as Array[Notify tag] iso^
      else
        let pipeNotifiers'' = recover Array[Notify tag] end
        consume pipeNotifiers''
      end

      let dataNotify: DataNotify[Array[U8] iso] iso = object iso is DataNotify[Array[U8] iso]
        let _stream: HashPullTransform tag = this
        fun ref apply(data': Array[U8] iso) =>
          _stream.write(consume data')
          stream.pull()
      end
      stream.subscribe(consume dataNotify)

      let pipedNotify: PipedNotify iso =  object iso is PipedNotify
        let _stream: HashPullTransform tag = this
        fun ref apply() => _stream._setPiped()
      end
      let pipedNotify': PipedNotify tag = pipedNotify
      pipeNotifiers'.push(pipedNotify')
      stream.subscribe(consume pipedNotify)

      let errorNotify: ErrorNotify iso = object iso  is ErrorNotify
        let _stream: HashPullTransform tag = this
        fun ref apply (ex: Exception) => _stream.destroy(ex)
      end
      let errorNotify': ErrorNotify tag = errorNotify
      pipeNotifiers'.push(errorNotify')
      stream.subscribe(consume errorNotify)

      let completeNotify: CompleteNotify iso = object iso  is CompleteNotify
        let _stream: HashPullTransform tag = this
        fun ref apply () => _stream._sourceComplete()
      end
      let completeNotify': CompleteNotify tag = completeNotify
      pipeNotifiers'.push(completeNotify')
      stream.subscribe(consume completeNotify)

      let closeNotify: CloseNotify iso = object iso  is CloseNotify
        let _stream: HashPullTransform tag = this
        fun ref apply () => _stream.close()
      end
      let closeNotify': CloseNotify tag = closeNotify
      pipeNotifiers'.push(closeNotify')
      stream.subscribe(consume closeNotify)
      _pipeNotifiers' = consume pipeNotifiers'
      stream.piped(this)
      notifyPipe()
    end

  be pull() =>
    if destroyed() then
      notifyError(Exception("Stream has been destroyed"))
    else
      _hasBeenPulled = true
      if _readable and not _isPiped then
        let data: Array[U8] iso = _hash.digest()
        notifyData(consume data)
        notifyComplete()
        _close()
      elseif _shouldPull() then
        _pullSource()
      end
    end

  be _sourceComplete() =>
    if destroyed() then
      notifyError(Exception("Stream has been destroyed"))
    elseif  not _readable then
      notifyError(Exception("Stream Error: Cannot Read"))
      _close()
    else
      let data: Array[U8] iso = _hash.digest()
      notifyData(consume data)
      notifyComplete()
      _close()
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
