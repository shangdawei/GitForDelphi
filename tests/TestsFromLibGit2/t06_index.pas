﻿unit t06_index;

interface

uses
   TestFramework, SysUtils, Windows,
   uTestsFromLibGit2, uGitForDelphi;

type
   Test06_index_read = class(TTestFromLibGit2)
      procedure load_an_empty_index;
      procedure load_a_standard_index__default_test_index_;
      procedure load_a_standard_index__git_git_index_;
   end;

   Test06_index_find = class(TTestFromLibGit2)
      procedure find_an_entry_on_an_index;
      procedure find_an_entry_in_an_empty_index;
   end;

   Test06_index_write = class(TTestFromLibGit2)
      procedure write_an_index_back_to_disk;
   end;

   Test06_index_add = class(TTestFromLibGit2)
      procedure add_a_new_file_to_the_index;
   end;

implementation

uses
   Classes;

{ Test06_index_read }

procedure Test06_index_read.load_an_empty_index;
var
   index: Pgit_index;
begin
   must_pass(git_index_open(index, PAnsiChar('in-memory-index')));
//   CheckTrue(index.on_disk = 0);

   must_pass(git_index_read(index));

//   CheckTrue(index.on_disk = 0);
   CheckTrue(git_index_entrycount(index) = 0);
//   CheckTrue(index.entries.sorted = 1);

   git_index_free(index);
end;

procedure Test06_index_read.load_a_standard_index__default_test_index_;
var
   index: Pgit_index;
   i: Integer;
//   entries: PPgit_index_entry;
   e: Pgit_index_entry;
begin
   must_pass(git_index_open(index, TEST_INDEX_PATH));

//   CheckTrue(index.on_disk = 1);

   must_pass(git_index_read(index));

//   CheckTrue(index.on_disk = 1);
   CheckTrue(git_index_entrycount(index) = TEST_INDEX_ENTRY_COUNT);
//   CheckTrue(index.entries.sorted = 1);

   for i := Low(TEST_ENTRIES) to High(TEST_ENTRIES) do
   begin
//      entries := PPgit_index_entry(index.entries.contents);
//
//      Inc(entries, TEST_ENTRIES[i].index);
//      e := entries^;
//
//      CheckTrue(StrComp(e.path, TEST_ENTRIES[i].path) = 0);
//      CheckTrue(e.mtime.seconds = TEST_ENTRIES[i].mtime);
//      CheckTrue(e.file_size = TEST_ENTRIES[i].file_size);
      e := git_index_get(index, i);
      must_be_true(Assigned(e));
   end;

   git_index_free(index);
end;

procedure Test06_index_read.load_a_standard_index__git_git_index_;
var
   index: Pgit_index;
begin
   must_pass(git_index_open(index, TEST_INDEX2_PATH));
//   CheckTrue(index.on_disk = 1);

   must_pass(git_index_read(index));

//   CheckTrue(index.on_disk = 1);
   CheckTrue(git_index_entrycount(index) = TEST_INDEX2_ENTRY_COUNT);
//   CheckTrue(index.entries.sorted = 1);
//   CheckTrue(index.tree <> nil);

   git_index_free(index);
end;

{ Test06_index_find }

procedure Test06_index_find.find_an_entry_on_an_index;
var
   index: Pgit_index;
   i, idx: Integer;
begin
   must_pass(git_index_open(index, TEST_INDEX_PATH));
   must_pass(git_index_read(index));

   for i := 0 to 4 do
   begin
      idx := git_index_find(index, TEST_ENTRIES[i].path);
      CheckTrue(idx = TEST_ENTRIES[i].index);
   end;

   git_index_free(index);
end;

procedure Test06_index_find.find_an_entry_in_an_empty_index;
var
   index: Pgit_index;
   i, idx: Integer;
begin
   must_pass(git_index_open(index, 'fake-index'));

   for i := 0 to 4 do
   begin
      idx := git_index_find(index, TEST_ENTRIES[i].path);
      CheckTrue(idx = GIT_ENOTFOUND);
   end;

   git_index_free(index);
end;

{ Test06_index_write }

procedure Test06_index_write.write_an_index_back_to_disk;
var
   index: Pgit_index;
begin
   CopyFile(TEST_INDEXBIG_PATH, 'index_rewrite', true);

   must_pass(git_index_open(index, 'index_rewrite'));
   must_pass(git_index_read(index));
//   must_be_true(index.on_disk > 0);

   must_pass(git_index_write(index));
   must_pass(cmp_files(TEST_INDEXBIG_PATH, 'index_rewrite'));

   git_index_free(index);

   SysUtils.DeleteFile('index_rewrite');
end;

{ Test06_index_add }

procedure Test06_index_add.add_a_new_file_to_the_index;
var
   path: AnsiString;

   index: Pgit_index;
//   fil: git_filebuf;
   repo: Pgit_repository;
   entry: Pgit_index_entry;
   id1: git_oid;

   fs: TFileStream;
   buf: AnsiString;
begin
   try
      path := TEMP_REPO_FOLDER + AnsiString('myrepo');

      //* Intialize a new repository */
      must_pass(git_repository_init(repo, PAnsiChar(path), 0));

      //* Ensure we're the only guy in the room */
      must_pass(git_repository_index(index, repo));
      must_be_true(git_index_entrycount(index) = 0);

      //* Create a new file in the working directory */
      ForceDirectories(TEMP_REPO_FOLDER + 'myrepo');
      fs := TFileStream.Create(TEMP_REPO_FOLDER + 'myrepo/test.txt', fmCreate or fmOpenWrite);
      try
      //   must_pass(gitfo_mkdir_2file(TEMP_REPO_FOLDER + 'myrepo/test.txt'));
      //   must_pass(git_filebuf_open(&file, TEMP_REPO_FOLDER "myrepo/test.txt", 0));
      //   must_pass(git_filebuf_write(&file, "hey there\n", 10));
      //   must_pass(git_filebuf_commit(&file));
         buf := 'hey there'#10;
         fs.Write(buf[1], 10);
      finally
         fs.Free;
      end;
      //* Store the expected hash of the file/blob
      // * This has been generated by executing the following
      // * $ echo "hey there" | git hash-object --stdin
      // */
      must_pass(git_oid_fromstr(@id1, 'a8233120f6ad708f843d861ce2b7228ec4e3dec6'));

      //* Add the new file to the index */
      must_pass(git_index_add(index, 'test.txt', 0));

      //* Wow... it worked! */
      must_be_true(git_index_entrycount(index) = 1);
      entry := git_index_get(index, 0);

      //* And the built-in hashing mechanism worked as expected */
      must_be_true(git_oid_cmp(@id1, @entry.oid) = 0);

      git_index_free(index);
      git_repository_free(repo);
   finally
      rmdir_recurs(TEMP_REPO_FOLDER);
   end;
end;

initialization
   RegisterTest('From libgit2.t06-index', Test06_index_read.NamedSuite('read'));
   RegisterTest('From libgit2.t06-index', Test06_index_find.NamedSuite('find'));
   RegisterTest('From libgit2.t06-index', Test06_index_write.NamedSuite('write'));
   RegisterTest('From libgit2.t06-index', Test06_index_add.NamedSuite('add'));

end.