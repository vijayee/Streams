use "Exception"
use "collections"

trait ThrottledNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    1
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

primitive ThrottledKey is ThrottledNotify
  fun ref apply() => None

trait UnthrottledNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    2
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

 primitive UnthrottledKey is UnthrottledNotify
   fun ref apply() => None

trait ErrorNotify is Notify
  fun ref apply(ex: Exception)
  fun box hash(): USize =>
    3
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

primitive ErrorKey is ErrorNotify
   fun ref apply(ex: Exception) => None

trait PipeNotify is Notify
 fun ref apply()
 fun box hash(): USize =>
   4
 fun box eq(that: box->Notify): Bool =>
  this.hash() == that.hash()
 fun box ne(that: box->Notify): Bool =>
  this.hash() != that.hash()

primitive PipeKey is PipeNotify
 fun ref apply() => None

trait UnpipeNotify is Notify
  fun ref apply(notifiers:Array[Notify tag] iso)
  fun box hash(): USize =>
    5
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

primitive UnpipeKey is UnpipeNotify
  fun ref apply(notifiers: Array[Notify tag] iso) => None

trait NextNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    6
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

primitive NextKey is NextNotify
 fun ref apply() => None

trait PipedNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    7
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
    this.hash() != that.hash()
primitive PipedKey is PipedNotify
  fun ref apply() => None

trait UnpipedNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    8
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

primitive UnpipedKey is UnpipedNotify
  fun ref apply() => None

trait DataNotify[R: Any #send] is Notify
  fun ref apply(data: R)
  fun box hash(): USize =>
    9
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

primitive DataKey[R: Any #send] is DataNotify[R]
  fun ref apply(data: R) => None

trait ReadableNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    10
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

primitive ReadableKey is ReadableNotify
  fun ref apply() => None

trait FinishedNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    11
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

primitive FinishedKey is FinishedNotify
  fun ref apply() => None

trait CloseNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    12
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

primitive CloseKey is CloseNotify
  fun ref apply() => None

trait Notify
  fun box hash(): USize
  fun box eq(that: box->Notify): Bool
  fun box ne(that: box->Notify):Bool

type Subscriptions is Array[(Notify, Bool)]
type Subscribers is Map[Notify, Subscriptions]
/*
type WriteablePushNotify is (ThrottledNotify | UnthrottledNotify | ErrorNotify | PipedNotify| UnpipedNotify )

type WriteablePullNotify[W: Any #send] is (ThrottledNotify | UnthrottledNotify | ErrorNotify | UnpipeNotify[W] | NextNotify)

type ReadablePushNotify[R: Any #send] is (ThrottledNotify | UnthrottledNotify | ErrorNotify | PipeNotify[R] | UnpipeNotify[R] | DataNotify[R] | ReadableNotify | FinishedNotify)

type ReadablePullNotify[R: Any #send] is (ThrottledNotify | UnthrottledNotify | ErrorNotify | PipedNotify | UnpipedNotify | DataNotify[R] | ReadableNotify)

type DuplexPushNotify[D: Any #send] is (ReadablePushNotify[D] | WriteablePushNotify)

type DuplexPullNotify[D: Any #send] is (ReadablePushNotify[D] | WriteablePullNotify[D])
*/
