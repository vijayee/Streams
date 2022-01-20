use fs = "files"
use ".."
use "../FileStreams"
use "../HashStreams"
use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)
  new make () =>
    None
  fun tag tests(test: PonyTest) =>
    test(PushFileStreamTest)
    test(PullFileStreamTest)
    test(DuplexPushFileStreamWriteTest)
    test(DuplexPushFileStreamReadTest)
    test(PushTransformStreamTest)
    test(DuplexPullFileStreamWriteTest)
    test(DuplexPullFileStreamReadTest)
    test(PullTransformStreamTest)

class iso PushFileStreamTest is UnitTest
  fun name(): String => "Testing Push File Stream"
  fun apply(t: TestHelper) =>
    t.long_test(5000000000)
    t.expect_action("finish")
    t.expect_action("close")
    try
      let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file2.txt")
      let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")

      let file: fs.File iso = recover
        match fs.CreateFile(path)
          | let file: fs.File =>
            file
        else
          error
        end
      end

      let file2: fs.File iso = recover
        match fs.CreateFile(path2)
          | let file2: fs.File =>
            file2
        else
          error
        end
      end
      let ws: WriteablePushFileStream = WriteablePushFileStream(consume file)
      let rs: ReadablePushFileStream = ReadablePushFileStream(consume file2)
      let readComplete: CompleteNotify iso = object iso is CompleteNotify
        let _t: TestHelper = t
        fun ref apply() =>
          t.complete_action("finish")
      end
      rs.subscribe(consume readComplete, true)
      let writeClose: CloseNotify iso = object iso is CloseNotify
        let _t: TestHelper = t
        fun ref apply() =>
          try
            let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file2.txt")
            let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")
            let file: fs.File = match fs.CreateFile(path)
              | let file: fs.File =>
                file
            else
              error
            end

            let file2: fs.File = match fs.CreateFile(path2)
                | let file2: fs.File =>
                file2
            else
              error
            end
            let filetext: String = file.read_string(file.size())
            let file2text: String = file2.read_string(file.size())
            _t.assert_true(filetext == file2text)
            _t.complete_action("close")
            _t.log("files are equal")
            _t.complete(true)
          else
            _t.log("error comparing files")
            _t.complete(false)
          end
      end
      ws.subscribe(consume writeClose, true)
      rs.pipe(ws)
    else
      None
    end

class iso PullFileStreamTest is UnitTest
  fun name(): String => "Testing Pull File Stream"
  fun apply(t: TestHelper) =>
    t.long_test(5000000000)
    t.expect_action("finish")
    t.expect_action("close")
    try
      let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file3.txt")
      let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")

      let file: fs.File iso = recover
        match fs.CreateFile(path)
          | let file: fs.File =>
            file
        else
          error
        end
      end

      let file2: fs.File iso = recover
        match fs.CreateFile(path2)
          | let file2: fs.File =>
            file2
        else
          error
        end
      end
      let ws: WriteablePullFileStream = WriteablePullFileStream(consume file)
      let rs: ReadablePullFileStream = ReadablePullFileStream(consume file2)
      let readComplete: CompleteNotify iso = object iso is CompleteNotify
        let _t: TestHelper = t
        fun ref apply() =>
          t.complete_action("finish")
      end
      rs.subscribe(consume readComplete, true)
      let writeClose: CloseNotify iso = object iso is CloseNotify
        let _t: TestHelper = t
        fun ref apply() =>
          try
            let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file3.txt")
            let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")
            let file: fs.File = match fs.CreateFile(path)
              | let file: fs.File =>
                file
            else
              error
            end

            let file2: fs.File = match fs.CreateFile(path2)
                | let file2: fs.File =>
                file2
            else
              error
            end
            let filetext: String = file.read_string(file.size())
            let file2text: String = file2.read_string(file.size())
            _t.assert_true(filetext == file2text)
            _t.complete_action("close")
            _t.log("files are equal")
            _t.complete(true)
          else
            _t.log("error comparing files")
            _t.complete(false)
          end
      end
      ws.subscribe(consume writeClose, true)
      ws.pipe(rs)
    else
      None
    end

class iso DuplexPushFileStreamWriteTest is UnitTest
  fun name(): String => "Testing Duplex Push File Stream Writing"
  fun apply(t: TestHelper) =>
    t.long_test(5000000000)
    t.expect_action("finish")
    t.expect_action("close")
    try
      let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file4.txt")
      let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")

      let file: fs.File iso = recover
        match fs.CreateFile(path)
          | let file: fs.File =>
            file
        else
          error
        end
      end

      let file2: fs.File iso = recover
        match fs.CreateFile(path2)
          | let file2: fs.File =>
            file2
        else
          error
        end
      end
      let ds: DuplexPushFileStream = DuplexPushFileStream(consume file)
      let rs: ReadablePushFileStream = ReadablePushFileStream(consume file2)
      let readFinish: FinishedNotify iso = object iso is FinishedNotify
        let _t: TestHelper = t
        fun ref apply() =>
          t.complete_action("finish")
      end
      rs.subscribe(consume readFinish, true)
      let writeClose: CloseNotify iso = object iso is CloseNotify
        let _t: TestHelper = t
        fun ref apply() =>
          try
            let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file4.txt")
            let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")
            let file: fs.File = match fs.CreateFile(path)
              | let file: fs.File =>
                file
            else
              error
            end

            let file2: fs.File = match fs.CreateFile(path2)
                | let file2: fs.File =>
                file2
            else
              error
            end
            let filetext: String = file.read_string(file.size())
            let file2text: String = file2.read_string(file.size())
            _t.assert_true(filetext == file2text)
            _t.complete_action("close")
            _t.log("files are equal")
            _t.complete(true)
          else
            _t.log("error comparing files")
            _t.complete(false)
          end
      end
      ds.subscribe(consume writeClose, true)
      rs.pipe(ds)
    else
      None
    end

class iso DuplexPushFileStreamReadTest is UnitTest
  fun name(): String => "Testing Duplex Push File Stream Reading"
  fun apply(t: TestHelper) =>
    t.long_test(5000000000)
    t.expect_action("finish")
    t.expect_action("close")
    try
      let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file5.txt")
      let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")

      let file: fs.File iso = recover
        match fs.CreateFile(path)
          | let file: fs.File =>
            file
        else
          error
        end
      end

      let file2: fs.File iso = recover
        match fs.CreateFile(path2)
          | let file2: fs.File =>
            file2
        else
          error
        end
      end
      let ws: WriteablePushFileStream = WriteablePushFileStream(consume file)
      let ds: DuplexPushFileStream = DuplexPushFileStream(consume file2)
      let readComplete: CompleteNotify iso = object iso is CompleteNotify
        let _t: TestHelper = t
        fun ref apply() =>
          t.complete_action("finish")
      end
      ds.subscribe(consume readComplete, true)
      let writeClose: CloseNotify iso = object iso is CloseNotify
        let _t: TestHelper = t
        fun ref apply() =>
          try
            let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file5.txt")
            let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")
            let file: fs.File = match fs.CreateFile(path)
              | let file: fs.File =>
                file
            else
              error
            end

            let file2: fs.File = match fs.CreateFile(path2)
                | let file2: fs.File =>
                file2
            else
              error
            end
            let filetext: String = file.read_string(file.size())
            let file2text: String = file2.read_string(file.size())
            _t.assert_true(filetext == file2text)
            _t.complete_action("close")
            _t.log("files are equal")
            _t.complete(true)
          else
            _t.log("error comparing files")
            _t.complete(false)
          end
      end
      ws.subscribe(consume writeClose, true)
      ds.pipe(ws)
    else
      None
    end

class iso PushTransformStreamTest is UnitTest
  fun name(): String => "Testing Push Transform Stream"
  fun apply(t: TestHelper) =>
    t.long_test(5000000000)
    t.expect_action("finish")
    t.expect_action("close")
    try
      let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file6.txt")
      let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")

      let file: fs.File iso = recover
        match fs.CreateFile(path)
          | let file: fs.File =>
            file
        else
          error
        end
      end

      let file2: fs.File iso = recover
        match fs.CreateFile(path2)
          | let file2: fs.File =>
            file2
        else
          error
        end
      end
      let ws: WriteablePushFileStream = WriteablePushFileStream(consume file)
      let rs: ReadablePushFileStream = ReadablePushFileStream(consume file2)
      let ht: HashPushTransform = HashPushTransform()

      let readFinish: CompleteNotify iso = object iso is CompleteNotify
        let _t: TestHelper = t
        fun ref apply() =>
          t.complete_action("finish")
      end
      rs.subscribe(consume readFinish, true)
      let writeClose: CloseNotify iso = object iso is CloseNotify
        let _t: TestHelper = t
        fun ref apply() =>
          try
            let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file6.txt")
            let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")
            let file: fs.File = match fs.CreateFile(path)
              | let file: fs.File =>
                file
            else
              error
            end

            let file2: fs.File = match fs.CreateFile(path2)
                | let file2: fs.File =>
                file2
            else
              error
            end
            let filetext: String = file.read_string(file.size())
            let file2text: String = file2.read_string(file.size())
            _t.assert_true(filetext != file2text)
            _t.assert_true(filetext.size() == 32)
            _t.complete_action("close")
            _t.log("files are equal")
            _t.complete(true)
          else
            _t.log("error comparing files")
            _t.complete(false)
          end
      end
      ws.subscribe(consume writeClose)
      ht.pipe(ws)
      rs.pipe(ht)
    else
      None
    end

class iso DuplexPullFileStreamWriteTest is UnitTest
  fun name(): String => "Testing Duplex Pull File Stream Writing"
  fun apply(t: TestHelper) =>
    t.long_test(5000000000)
    t.expect_action("finish")
    t.expect_action("close")
    try
      let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file7.txt")
      let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")

      let file: fs.File iso = recover
        match fs.CreateFile(path)
          | let file: fs.File =>
            file
        else
          error
        end
      end

      let file2: fs.File iso = recover
        match fs.CreateFile(path2)
          | let file2: fs.File =>
            file2
        else
          error
        end
      end
      let ds: DuplexPullFileStream = DuplexPullFileStream(consume file)
      let rs: ReadablePullFileStream = ReadablePullFileStream(consume file2)
      let readFinish: FinishedNotify iso = object iso is FinishedNotify
        let _t: TestHelper = t
        fun ref apply() =>
          t.complete_action("finish")
      end
      rs.subscribe(consume readFinish, true)
      let writeClose: CloseNotify iso = object iso is CloseNotify
        let _t: TestHelper = t
        fun ref apply() =>
          try
            let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file7.txt")
            let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")
            let file: fs.File = match fs.CreateFile(path)
              | let file: fs.File =>
                file
            else
              error
            end

            let file2: fs.File = match fs.CreateFile(path2)
                | let file2: fs.File =>
                file2
            else
              error
            end
            let filetext: String = file.read_string(file.size())
            let file2text: String = file2.read_string(file.size())
            _t.assert_true(filetext == file2text)
            _t.complete_action("close")
            _t.log("files are equal")
            _t.complete(true)
          else
            _t.log("error comparing files")
            _t.complete(false)
          end
      end
      ds.subscribe(consume writeClose, true)
      ds.pipe(rs)
    else
      None
    end
class iso DuplexPullFileStreamReadTest is UnitTest
  fun name(): String => "Testing Duplex Pull File Stream Reading"
  fun apply(t: TestHelper) =>
    t.long_test(5000000000)
    t.expect_action("finish")
    t.expect_action("close")
    try
      let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file8.txt")
      let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")

      let file: fs.File iso = recover
        match fs.CreateFile(path)
          | let file: fs.File =>
            file
        else
          error
        end
      end

      let file2: fs.File iso = recover
        match fs.CreateFile(path2)
          | let file2: fs.File =>
            file2
        else
          error
        end
      end
      let ws: WriteablePullFileStream = WriteablePullFileStream(consume file)
      let ds: DuplexPullFileStream = DuplexPullFileStream(consume file2)
      let readComplete: CompleteNotify iso = object iso is CompleteNotify
        let _t: TestHelper = t
        fun ref apply() =>
          t.complete_action("finish")
      end
      ds.subscribe(consume readComplete, true)
      let writeClose: CloseNotify iso = object iso is CloseNotify
        let _t: TestHelper = t
        fun ref apply() =>
          try
            let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file8.txt")
            let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")
            let file: fs.File = match fs.CreateFile(path)
              | let file: fs.File =>
                file
            else
              error
            end

            let file2: fs.File = match fs.CreateFile(path2)
                | let file2: fs.File =>
                file2
            else
              error
            end
            let filetext: String = file.read_string(file.size())
            let file2text: String = file2.read_string(file.size())
            _t.assert_true(filetext == file2text)
            _t.complete_action("close")
            _t.log("files are equal")
            _t.complete(true)
          else
            _t.log("error comparing files")
            _t.complete(false)
          end
      end
      ws.subscribe(consume writeClose, true)
      ws.pipe(ds)
    else
      None
    end


class iso PullTransformStreamTest is UnitTest
  fun name(): String => "Testing Pull Transform Stream"
  fun apply(t: TestHelper) =>
    t.long_test(5000000000)
    t.expect_action("finish")
    t.expect_action("close")
    try
      let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file9.txt")
      let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")

      let file: fs.File iso = recover
        match fs.CreateFile(path)
          | let file: fs.File =>
            file
        else
          error
        end
      end

      let file2: fs.File iso = recover
        match fs.CreateFile(path2)
          | let file2: fs.File =>
            file2
        else
          error
        end
      end
      let ws: WriteablePullFileStream = WriteablePullFileStream(consume file)
      let rs: ReadablePullFileStream = ReadablePullFileStream(consume file2)
      let ht: HashPullTransform = HashPullTransform()

      let readFinish: CompleteNotify iso = object iso is CompleteNotify
        let _t: TestHelper = t
        fun ref apply() =>
          t.complete_action("finish")
      end
      rs.subscribe(consume readFinish, true)
      let writeClose: CloseNotify iso = object iso is CloseNotify
        let _t: TestHelper = t
        fun ref apply() =>
          try
            let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file9.txt")
            let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")
            let file: fs.File = match fs.CreateFile(path)
              | let file: fs.File =>
                file
            else
              error
            end

            let file2: fs.File = match fs.CreateFile(path2)
                | let file2: fs.File =>
                file2
            else
              error
            end
            let filetext: String = file.read_string(file.size())
            let file2text: String = file2.read_string(file.size())
            _t.assert_true(filetext != file2text)
            _t.assert_true(filetext.size() == 32)
            _t.complete_action("close")
            _t.log("files are equal")
            _t.complete(true)
          else
            _t.log("error comparing files")
            _t.complete(false)
          end
      end
      ws.subscribe(consume writeClose)
      ht.pipe(rs)
      ws.pipe(ht)
    else
      None
    end
