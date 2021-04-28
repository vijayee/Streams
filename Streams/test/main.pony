use fs = "files"
use ".."
use "../FileStreams"

use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)
  new make () =>
    None
  fun tag tests(test: PonyTest) =>
    test(PushFileStream)
    test(PullFileStream)

class iso PushFileStream is UnitTest
  fun name(): String => "Testing Push File Stream"
  fun apply(t: TestHelper) =>
    t.long_test(5000000000)
    t.expect_action("finish")
    t.expect_action("close")
    try
      let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file2.txt")?
      let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")?

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
            let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file2.txt")?
            let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")?
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

class iso PullFileStream is UnitTest
  fun name(): String => "Testing Pull File Stream"
  fun apply(t: TestHelper) =>
    t.long_test(5000000000)
    try
      let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file3.txt")?
      let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")?

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
            let path: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./build/test/file3.txt")?
            let path2: fs.FilePath = fs.FilePath(t.env.root as AmbientAuth, "./Streams/test/file.txt")?
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
