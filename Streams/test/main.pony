use fs ="files"
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
      ws.pipe(rs)
    else
      None
    end
