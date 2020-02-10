use fs ="files"
use ".."
use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)
  new make () =>
    None
  fun tag tests(test: PonyTest) =>
    test(FileStream)

class iso FileStream is UnitTest
  fun name(): String => "Testing File Stream"
  fun apply(t: TestHelper) =>
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
      let ws: WriteableFileStream = WriteableFileStream(consume file)
      let rs: ReadableFileStream = ReadableFileStream(consume file2)
      rs.pipe(ws)
    else
      None
    end
