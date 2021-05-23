use "Exception"
use "collections"

trait ThrottledNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    1

primitive ThrottledKey is ThrottledNotify
  fun ref apply() => None

trait UnthrottledNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    2

 primitive UnthrottledKey is UnthrottledNotify
   fun ref apply() => None

trait ErrorNotify is Notify
  fun ref apply(ex: Exception)
  fun box hash(): USize =>
    3

primitive ErrorKey is ErrorNotify
   fun ref apply(ex: Exception) => None

trait PipeNotify is Notify
 fun ref apply()
 fun box hash(): USize =>
   4

primitive PipeKey is PipeNotify
 fun ref apply() => None

trait UnpipeNotify is Notify
  fun ref apply(notifiers:Array[Notify tag] iso)
  fun box hash(): USize =>
    5

primitive UnpipeKey is UnpipeNotify
  fun ref apply(notifiers: Array[Notify tag] iso) => None

trait NextNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    6

primitive NextKey is NextNotify
 fun ref apply() => None

trait PipedNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    7

primitive PipedKey is PipedNotify
  fun ref apply() => None

trait UnpipedNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    8

primitive UnpipedKey is UnpipedNotify
  fun ref apply() => None

trait DataNotify[R: Any #send] is Notify
  fun ref apply(data: R)
  fun box hash(): USize =>
    9

primitive DataKey[R: Any #send] is DataNotify[R]
  fun ref apply(data: R) => None

trait ReadableNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    10

primitive ReadableKey is ReadableNotify
  fun ref apply() => None

trait FinishedNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    11

primitive FinishedKey is FinishedNotify
  fun ref apply() => None

trait CloseNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    12

primitive CloseKey is CloseNotify
  fun ref apply() => None

trait EmptyNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    13
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

primitive EmptyKey is EmptyNotify
  fun ref apply() => None

trait OverflowNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    14

primitive OverflowKey is OverflowNotify
  fun ref apply() => None

trait CompleteNotify is Notify
  fun ref apply()
  fun box hash(): USize =>
    15

primitive CompleteKey is CompleteNotify
  fun ref apply() => None

trait Notify
  fun box hash(): USize
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

type Subscriptions is Array[(Notify, Bool)]
type Subscribers is Map[Notify, Subscriptions]
