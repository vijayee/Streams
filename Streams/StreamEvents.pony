use "Events"
use "Exception"

trait ThrottledNotify
  fun ref apply()
  fun box hash(): USize =>
    1
  fun box eq(that: box->ThrottledNotify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->ThrottledNotify): Bool =>
   this.hash() != that.hash()

primitive ThrottledKey is ThrottledNotify
  fun ref apply() => None

trait UnthrottledNotify
  fun ref apply()
  fun box hash(): USize =>
    2
  fun box eq(that: box->UnthrottledNotify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->UnthrottledNotify): Bool =>
   this.hash() != that.hash()

 primitive UnthrottledKey is UnthrottledNotify
   fun ref apply() => None

trait ErrorNotify
  fun ref apply(ex: Exception)
  fun box hash(): USize =>
    3
  fun box eq(that: box->ErrorNotify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->ErrorNotify): Bool =>
   this.hash() != that.hash()

primitive ErrorKey is ErrorNotify
   fun ref apply(ex: Exception) => None

trait PipeNotify[W: Any #send]
 fun ref apply(notify: ReadablePullNotify[W] tag)
 fun box hash(): USize =>
   4
 fun box eq(that: box->UnpipeNotify): Bool =>
  this.hash() == that.hash()
 fun box ne(that: box->UnpipeNotify): Bool =>
  this.hash() != that.hash()

primitive PipeKey[W: Any #send] is UnpipeNotify[W]
 fun ref apply() => None

trait UnpipeNotify[W: Any #send]
  fun ref apply(notify: ReadablePullNotify[W] tag)
  fun box hash(): USize =>
    5
  fun box eq(that: box->UnpipeNotify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->UnpipeNotify): Bool =>
   this.hash() != that.hash()

primitive UnpipeKey[W: Any #send] is UnpipeNotify[W]
  fun ref apply() => None

trait NextNotify
  fun ref apply()
  fun box hash(): USize =>
    6
  fun box eq(that: box->NextNotify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->NextNotify): Bool =>
   this.hash() != that.hash()

primitive NextKey is NextNotify
 fun ref apply() => None

trait PipedNotify
  fun ref apply()
  fun box hash(): USize =>
    7
  fun box eq(that: box->PipedNotify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->PipedNotify): Bool =>

primitive PipedKey is PipedNotify
  fun ref apply() => None

trait UnpipedNotify
  fun ref apply()
  fun box hash(): USize =>
    8
  fun box eq(that: box->UnpipedNotify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->UnpipedNotify): Bool =>
   this.hash() != that.hash()

primitive UnpipedKey is UnpipedNotify
  fun ref apply() => None

trait DataNotify[R: Any #send]
  fun ref apply(data: R)
  fun box hash(): USize =>
    9
  fun box eq(that: box->DataNotify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->DataNotify): Bool =>
   this.hash() != that.hash()

primitive DataKey[R: Any #send] is DataNotify[R]
  fun ref apply() => None

trait ReadableNotify
  fun ref apply()
  fun box hash(): USize =>
    10
  fun box eq(that: box->ReadableNotify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->ReadableNotify): Bool =>
   this.hash() != that.hash()

primitive ReadableKey is ReadableNotify
  fun ref apply() => None

trait FinishedNotify
  fun ref apply()
  fun box hash(): USize =>
    11
  fun box eq(that: box->FinishedNotify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->FinishedNotify): Bool =>
   this.hash() != that.hash()

primitive FinishedKey is FinishedNotify
  fun ref apply() => None


type WriteablePushNotify is (ThrottledNotify | UnthrottledNotify | ErrorNotify | PipedNotify| UnpipedNotify)

type WriteablePullNotify[W: Any #send] is (ThrottledNotify | UnthrottledNotify | ErrorNotify | UnpipeNotify[W] | NextNotify)

type ReadablePushNotify[R: Any #send] is (ThrottledNotify | UnthrottledNotify | ErrorNotify | PipeNotify| UnpipeNotify | DataNotify[R] | ReadableNotify | FinishedNotify)

type ReadablePullNotify[R: Any #send] is (ThrottledNotify | UnthrottledNotify | ErrorNotify | PipedNotify| UnpipedNotify | DataNotify[R] | ReadableNotify)

type DuplexPushNotify[D: Any #send] is (ReadablePushNotify[D] | WriteablePushNotify)

type DuplexPullNotify[D: Any #send] is (ReadablePushNotify[D] | WriteablePullNotify[D])
