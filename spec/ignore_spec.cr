require "./spec_helper"

describe Ignore do
  describe "VERSION" do
    it "has a version" do
      Ignore::VERSION.should_not be_nil
    end
  end

  describe Ignore::Pattern do
    describe "basic patterns" do
      it "matches simple filename" do
        pattern = Ignore::Pattern.new("foo.txt")
        pattern.matches?("foo.txt").should be_true
        pattern.matches?("bar.txt").should be_false
      end

      it "matches at any depth when no slash" do
        pattern = Ignore::Pattern.new("foo.txt")
        pattern.matches?("foo.txt").should be_true
        pattern.matches?("a/foo.txt").should be_true
        pattern.matches?("a/b/foo.txt").should be_true
      end

      it "matches with * wildcard" do
        pattern = Ignore::Pattern.new("*.txt")
        pattern.matches?("foo.txt").should be_true
        pattern.matches?("bar.txt").should be_true
        pattern.matches?("foo.log").should be_false
      end

      it "* does not match across directories" do
        pattern = Ignore::Pattern.new("*.txt")
        pattern.matches?("a/b.txt").should be_true  # matches b.txt at any level
        pattern = Ignore::Pattern.new("a*.txt")
        pattern.matches?("a/b.txt").should be_false # a*.txt doesn't match a/b.txt
      end

      it "matches with ? wildcard" do
        pattern = Ignore::Pattern.new("foo?.txt")
        pattern.matches?("foo1.txt").should be_true
        pattern.matches?("fooa.txt").should be_true
        pattern.matches?("foo.txt").should be_false
        pattern.matches?("foo12.txt").should be_false
      end
    end

    describe "directory patterns" do
      it "trailing slash matches only directories" do
        pattern = Ignore::Pattern.new("build/")
        pattern.directory_only?.should be_true
        pattern.matches?("build/").should be_true
        pattern.matches?("build").should be_false
      end

      it "trailing slash matches directories at any depth" do
        pattern = Ignore::Pattern.new("build/")
        pattern.matches?("build/").should be_true
        pattern.matches?("a/build/").should be_true
        pattern.matches?("a/b/build/").should be_true
      end
    end

    describe "anchored patterns" do
      it "leading slash anchors to root" do
        pattern = Ignore::Pattern.new("/foo.txt")
        pattern.anchored?.should be_true
        pattern.matches?("foo.txt").should be_true
        pattern.matches?("a/foo.txt").should be_false
      end

      it "middle slash anchors pattern" do
        pattern = Ignore::Pattern.new("a/foo.txt")
        pattern.anchored?.should be_true
        pattern.matches?("a/foo.txt").should be_true
        pattern.matches?("b/a/foo.txt").should be_false
      end
    end

    describe "negation" do
      it "detects negation" do
        pattern = Ignore::Pattern.new("!important.txt")
        pattern.negated?.should be_true
        pattern.matches?("important.txt").should be_true
      end

      it "escaped ! is not negation" do
        pattern = Ignore::Pattern.new("\\!important.txt")
        pattern.negated?.should be_false
        pattern.matches?("!important.txt").should be_true
      end
    end

    describe "double asterisk **" do
      it "**/foo matches foo anywhere" do
        pattern = Ignore::Pattern.new("**/foo")
        pattern.matches?("foo").should be_true
        pattern.matches?("a/foo").should be_true
        pattern.matches?("a/b/foo").should be_true
      end

      it "foo/** matches everything inside foo" do
        pattern = Ignore::Pattern.new("foo/**")
        pattern.matches?("foo/a").should be_true
        pattern.matches?("foo/a/b").should be_true
        pattern.matches?("foo").should be_false
      end

      it "a/**/b matches zero or more directories between" do
        pattern = Ignore::Pattern.new("a/**/b")
        pattern.matches?("a/b").should be_true
        pattern.matches?("a/x/b").should be_true
        pattern.matches?("a/x/y/b").should be_true
      end
    end

    describe "character classes" do
      it "matches character class" do
        pattern = Ignore::Pattern.new("[abc].txt")
        pattern.matches?("a.txt").should be_true
        pattern.matches?("b.txt").should be_true
        pattern.matches?("c.txt").should be_true
        pattern.matches?("d.txt").should be_false
      end

      it "matches character range" do
        pattern = Ignore::Pattern.new("[a-z].txt")
        pattern.matches?("a.txt").should be_true
        pattern.matches?("m.txt").should be_true
        pattern.matches?("z.txt").should be_true
        pattern.matches?("1.txt").should be_false
      end

      it "negated character class" do
        pattern = Ignore::Pattern.new("[!abc].txt")
        pattern.matches?("a.txt").should be_false
        pattern.matches?("d.txt").should be_true
        pattern.matches?("1.txt").should be_true
      end
    end

    describe "escaping" do
      it "escaped # is literal" do
        pattern = Ignore::Pattern.new("\\#file")
        pattern.matches?("#file").should be_true
      end

      it "escaped * is literal" do
        pattern = Ignore::Pattern.new("foo\\*.txt")
        pattern.matches?("foo*.txt").should be_true
        pattern.matches?("foobar.txt").should be_false
      end
    end

    describe "base_path" do
      it "pattern with base_path only matches within that path" do
        pattern = Ignore::Pattern.new("*.log", "src/")
        pattern.base_path.should eq("src/")
        pattern.matches?("src/debug.log").should be_true
        pattern.matches?("src/sub/debug.log").should be_true
        pattern.matches?("debug.log").should be_false
        pattern.matches?("other/debug.log").should be_false
      end

      it "anchored pattern with base_path anchors to base" do
        pattern = Ignore::Pattern.new("/build", "src/")
        pattern.matches?("src/build").should be_true
        pattern.matches?("src/sub/build").should be_false
        pattern.matches?("build").should be_false
      end

      it "normalizes base_path with trailing slash" do
        pattern = Ignore::Pattern.new("*.log", "src")
        pattern.base_path.should eq("src/")
      end
    end
  end

  describe Ignore::Matcher do
    it "ignores comments" do
      matcher = Ignore::Matcher.new
      matcher.add("# this is a comment")
      matcher.size.should eq(0)
    end

    it "ignores blank lines" do
      matcher = Ignore::Matcher.new
      matcher.add("")
      matcher.add("   ")
      matcher.size.should eq(0)
    end

    it "applies patterns in order, last match wins" do
      matcher = Ignore::Matcher.new
      matcher.add("*.txt")
      matcher.add("!important.txt")
      matcher.ignores?("foo.txt").should be_true
      matcher.ignores?("important.txt").should be_false
    end

    it "parses multiline content" do
      content = <<-GITIGNORE
      # Build output
      build/
      *.o

      # Keep important files
      !important.o
      GITIGNORE

      matcher = Ignore.parse(content)
      matcher.ignores?("build/").should be_true
      matcher.ignores?("foo.o").should be_true
      matcher.ignores?("important.o").should be_false
    end

    describe "hierarchical patterns" do
      it "add with base restricts pattern to subtree" do
        matcher = Ignore::Matcher.new
        matcher.add("*.log", "src/")
        matcher.ignores?("src/debug.log").should be_true
        matcher.ignores?("debug.log").should be_false
      end

      it "parse with base restricts all patterns to subtree" do
        matcher = Ignore::Matcher.new
        matcher.parse("*.log\n*.tmp", "src/")
        matcher.ignores?("src/debug.log").should be_true
        matcher.ignores?("src/cache.tmp").should be_true
        matcher.ignores?("debug.log").should be_false
      end

      it "deeper patterns take precedence" do
        matcher = Ignore::Matcher.new
        matcher.add("*.log")           # ignore all .log files
        matcher.add("!debug.log", "src/")  # but not debug.log in src/
        matcher.ignores?("app.log").should be_true
        matcher.ignores?("src/app.log").should be_true
        matcher.ignores?("src/debug.log").should be_false
      end
    end
  end

  describe "module-level API" do
    it "Ignore.parse returns a Matcher" do
      matcher = Ignore.parse("*.txt")
      matcher.should be_a(Ignore::Matcher)
      matcher.ignores?("foo.txt").should be_true
    end

    it "Ignore.ignores? provides quick check" do
      Ignore.ignores?("foo.txt", "*.txt").should be_true
      Ignore.ignores?("foo.log", "*.txt").should be_false
    end
  end

  describe "file and directory loading" do
    it "add_file loads patterns from a file" do
      Dir.cd(Dir.tempdir) do
        File.write(".gitignore", "*.log\n*.tmp")
        matcher = Ignore::Matcher.new
        matcher.add_file(".gitignore")
        matcher.ignores?("debug.log").should be_true
        matcher.ignores?("cache.tmp").should be_true
        matcher.ignores?("main.cr").should be_false
        File.delete(".gitignore")
      end
    end

    it "add_file with base restricts to subtree" do
      Dir.cd(Dir.tempdir) do
        File.write("test.gitignore", "*.log")
        matcher = Ignore::Matcher.new
        matcher.add_file("test.gitignore", "src/")
        matcher.ignores?("src/debug.log").should be_true
        matcher.ignores?("debug.log").should be_false
        File.delete("test.gitignore")
      end
    end

    it "add_file returns self for missing files" do
      matcher = Ignore::Matcher.new
      matcher.add_file("/nonexistent/.gitignore")
      matcher.size.should eq(0)
    end

    it "from_directory loads all .gitignore files" do
      Dir.cd(Dir.tempdir) do
        # Create test directory structure
        Dir.mkdir_p("testproj/src/lib")

        File.write("testproj/.gitignore", "*.log")
        File.write("testproj/src/.gitignore", "*.tmp\n!important.tmp")
        File.write("testproj/src/lib/.gitignore", "!debug.log")

        matcher = Ignore.from_directory("testproj")

        # Root patterns apply everywhere
        matcher.ignores?("app.log").should be_true
        matcher.ignores?("src/app.log").should be_true

        # src patterns only in src/
        matcher.ignores?("src/cache.tmp").should be_true
        matcher.ignores?("cache.tmp").should be_false
        matcher.ignores?("src/important.tmp").should be_false

        # Deeper negation overrides
        matcher.ignores?("src/lib/debug.log").should be_false

        # Cleanup
        File.delete("testproj/src/lib/.gitignore")
        File.delete("testproj/src/.gitignore")
        File.delete("testproj/.gitignore")
        Dir.delete("testproj/src/lib")
        Dir.delete("testproj/src")
        Dir.delete("testproj")
      end
    end
  end

  describe Ignore::Dir do
    around_each do |example|
      Dir.cd(Dir.tempdir) do
        # Create test directory structure
        Dir.mkdir_p("testproj/src/lib")
        Dir.mkdir_p("testproj/build")
        File.write("testproj/main.cr", "main")
        File.write("testproj/debug.log", "log")
        File.write("testproj/src/app.cr", "app")
        File.write("testproj/src/app.log", "log")
        File.write("testproj/src/lib/util.cr", "util")
        File.write("testproj/build/output.o", "output")

        example.run

        # Cleanup
        File.delete("testproj/build/output.o")
        File.delete("testproj/src/lib/util.cr")
        File.delete("testproj/src/app.log")
        File.delete("testproj/src/app.cr")
        File.delete("testproj/debug.log")
        File.delete("testproj/main.cr")
        Dir.delete("testproj/build")
        Dir.delete("testproj/src/lib")
        Dir.delete("testproj/src")
        Dir.delete("testproj")
      end
    end

    describe "initialization" do
      it "initializes with path and patterns" do
        dir = Ignore::Dir.new("testproj", "*.log")
        dir.path.should eq("testproj")
        dir.ignores?("debug.log").should be_true
      end

      it "initializes with multiple patterns" do
        dir = Ignore::Dir.new("testproj", "*.log", "*.o")
        dir.ignores?("debug.log").should be_true
        dir.ignores?("output.o").should be_true
      end

      it "initializes with file: parameter" do
        File.write("testproj/.gitignore", "*.log")
        dir = Ignore::Dir.new("testproj", file: "testproj/.gitignore")
        dir.ignores?("debug.log").should be_true
        File.delete("testproj/.gitignore")
      end

      it "initializes with root: parameter" do
        File.write("testproj/.gitignore", "*.log")
        File.write("testproj/src/.gitignore", "!app.log")
        dir = Ignore::Dir.new("testproj", root: ".gitignore")
        dir.ignores?("debug.log").should be_true
        dir.ignores?("src/app.log").should be_false
        File.delete("testproj/src/.gitignore")
        File.delete("testproj/.gitignore")
      end
    end

    describe "#glob" do
      it "returns files not matching ignore patterns" do
        dir = Ignore::Dir.new("testproj", "*.log")
        results = dir.glob("**/*").map { |p| p.sub("testproj/", "") }.sort
        results.should contain("main.cr")
        results.should contain("src/app.cr")
        results.should_not contain("debug.log")
        results.should_not contain("src/app.log")
      end

      it "filters directories and their contents" do
        dir = Ignore::Dir.new("testproj", "build/")
        results = dir.glob("**/*").map { |p| p.sub("testproj/", "") }
        results.should_not contain("build/output.o")
        results.should contain("main.cr")
      end

      it "yields to block" do
        dir = Ignore::Dir.new("testproj", "*.log")
        results = [] of String
        dir.glob("**/*.cr") { |p| results << p }
        results.size.should be > 0
        results.all? { |p| p.ends_with?(".cr") }.should be_true
      end
    end

    describe "#children" do
      it "returns filtered children of base directory" do
        dir = Ignore::Dir.new("testproj", "*.log")
        children = dir.children
        children.should contain("main.cr")
        children.should contain("src")
        children.should_not contain("debug.log")
      end

      it "filters directories" do
        dir = Ignore::Dir.new("testproj", "build/")
        children = dir.children
        children.should contain("src")
        children.should_not contain("build")
      end
    end

    describe "#entries" do
      it "returns filtered entries including . and .." do
        dir = Ignore::Dir.new("testproj", "*.log")
        entries = dir.entries
        entries.should contain(".")
        entries.should contain("..")
        entries.should contain("main.cr")
        entries.should_not contain("debug.log")
      end
    end

    describe "#each_child" do
      it "yields filtered children" do
        dir = Ignore::Dir.new("testproj", "*.log")
        children = [] of String
        dir.each_child { |c| children << c }
        children.should contain("main.cr")
        children.should_not contain("debug.log")
      end
    end

    describe "#add" do
      it "adds patterns and returns self" do
        dir = Ignore::Dir.new("testproj", "*.log")
        dir.add("*.o").should be(dir)
        dir.ignores?("output.o").should be_true
      end
    end

    describe "parent directory filtering" do
      it "filters files inside ignored directories" do
        dir = Ignore::Dir.new("testproj", "src/")
        results = dir.glob("**/*").map { |p| p.sub("testproj/", "") }
        results.should_not contain("src/app.cr")
        results.should_not contain("src/lib/util.cr")
        results.should contain("main.cr")
      end
    end
  end

  describe "Dir monkey patch" do
    around_each do |example|
      Dir.cd(Dir.tempdir) do
        Dir.mkdir_p("testproj/src")
        File.write("testproj/main.cr", "main")
        File.write("testproj/debug.log", "log")
        File.write("testproj/src/app.cr", "app")

        example.run

        File.delete("testproj/src/app.cr")
        File.delete("testproj/debug.log")
        File.delete("testproj/main.cr")
        Dir.delete("testproj/src")
        Dir.delete("testproj")
      end
    end

    describe "class methods" do
      it "Dir.ignore returns Ignore::Dir" do
        dir = Dir.ignore("*.log")
        dir.should be_a(Ignore::Dir)
      end

      it "Dir.ignore with patterns uses current directory" do
        Dir.cd("testproj") do
          dir = Dir.ignore("*.log")
          dir.path.should eq(Dir.current)
        end
      end

      it "Dir.ignore with root: loads ignore files" do
        File.write("testproj/.gitignore", "*.log")
        Dir.cd("testproj") do
          dir = Dir.ignore(root: ".gitignore")
          dir.ignores?("debug.log").should be_true
        end
        File.delete("testproj/.gitignore")
      end
    end

    describe "instance methods" do
      it "Dir#ignore returns Ignore::Dir with Dir's path" do
        dir = Dir.new("testproj").ignore("*.log")
        dir.should be_a(Ignore::Dir)
        dir.path.should eq("testproj")
      end

      it "Dir#ignore chains with glob" do
        results = Dir.new("testproj").ignore("*.log").glob("**/*")
        results.any? { |p| p.ends_with?(".cr") }.should be_true
        results.none? { |p| p.ends_with?(".log") }.should be_true
      end

      it "Dir#ignore with root: loads ignore files from Dir's path" do
        File.write("testproj/.gitignore", "*.log")
        dir = Dir.new("testproj").ignore(root: ".gitignore")
        dir.ignores?("debug.log").should be_true
        File.delete("testproj/.gitignore")
      end
    end
  end
end
