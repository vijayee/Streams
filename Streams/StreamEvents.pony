use "Exception"
use "collections"

trait ThrottledNotify is VoidNotify
  fun ref apply()
  fun box hash(): USize =>
    1

primitive ThrottledEvent is ThrottledNotify
  fun ref apply() => None

trait UnthrottledNotify is VoidNotify
  fun ref apply()
  fun box hash(): USize =>
    2

 primitive UnthrottledEvent is UnthrottledNotify
   fun ref apply() => None

trait ErrorNotify is PayloadNotify[Exception]
  fun ref apply(data: Exception)
  fun box hash(): USize =>
    3

primitive ErrorEvent is ErrorNotify
   fun ref apply(ex: Exception) => None

trait PipeNotify is VoidNotify
 fun ref apply()
 fun box hash(): USize =>
   4

primitive PipeEvent is PipeNotify
 fun ref apply() => None

trait UnpipeNotify is PayloadNotify[Array[Notify tag] iso]
  fun ref apply(data: Array[Notify tag] iso)
  fun box hash(): USize =>
    5

primitive UnpipeEvent is UnpipeNotify
  fun ref apply(notifiers: Array[Notify tag] iso) => None

trait NextNotify is VoidNotify
  fun ref apply()
  fun box hash(): USize =>
    6

primitive NextEvent is NextNotify
 fun ref apply() => None

trait PipedNotify is VoidNotify
  fun ref apply()
  fun box hash(): USize =>
    7

primitive PipedEvent is PipedNotify
  fun ref apply() => None

trait UnpipedNotify is VoidNotify
  fun ref apply()
  fun box hash(): USize =>
    8

primitive UnpipedEvent is UnpipedNotify
  fun ref apply() => None

trait DataNotify[R: Any #send] is PayloadNotify[R]
  fun ref apply(data: R)
  fun box hash(): USize =>
    9

primitive DataEvent[R: Any #send] is DataNotify[R]
  fun ref apply(data: R) => None

trait ReadableNotify is VoidNotify
  fun ref apply()
  fun box hash(): USize =>
    10

primitive ReadableEvent is ReadableNotify
  fun ref apply() => None

trait FinishedNotify is VoidNotify
  fun ref apply()
  fun box hash(): USize =>
    11

primitive FinishedEvent is FinishedNotify
  fun ref apply() => None

trait CloseNotify is VoidNotify
  fun ref apply()
  fun box hash(): USize =>
    12

primitive CloseEvent is CloseNotify
  fun ref apply() => None

trait EmptyNotify is VoidNotify
  fun ref apply()
  fun box hash(): USize =>
    13
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

primitive EmptyEvent is EmptyNotify
  fun ref apply() => None

trait OverflowNotify is VoidNotify
  fun ref apply()
  fun box hash(): USize =>
    14

primitive OverflowEvent is OverflowNotify
  fun ref apply() => None

trait CompleteNotify is VoidNotify
  fun ref apply()
  fun box hash(): USize =>
    15

primitive CompleteEvent is CompleteNotify
  fun ref apply() => None

trait Notify
  fun box hash(): USize
  fun box eq(that: box->Notify): Bool =>
   this.hash() == that.hash()
  fun box ne(that: box->Notify): Bool =>
   this.hash() != that.hash()

trait Void
  fun ref apply()

trait Payload[R: Any #send]
   fun ref apply(data: R)


type PayloadNotify[A: Any #send] is (Notify & Payload[A])
type VoidNotify is (Notify & Void)
type Subscriptions is Array[(Notify, Bool)]
type Subscribers is Map[Notify, Subscriptions]
