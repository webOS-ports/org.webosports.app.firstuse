/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

/*
 * firstuse::writeHandoff on its own, in a temporary directory per case: what
 * it writes, that nothing is left behind, and that a symlink or a file
 * already there is replaced rather than written through.
 */

#include "handoff.h"

#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

#include <dirent.h>
#include <ftw.h>
#include <sys/stat.h>
#include <unistd.h>

namespace {

int g_failed = 0;
int g_checks = 0;

#define CHECK(cond) check((cond), #cond, __FILE__, __LINE__)
#define CHECK_EQ(a, b) checkEq((a), (b), #a, __FILE__, __LINE__)

void check(bool ok, const char *what, const char *file, int line)
{
    ++g_checks;
    if (!ok) {
        ++g_failed;
        (void)std::fprintf(stderr, "%s:%d: FAILED: %s\n", file, line, what);
    }
}

void checkEq(const std::string &a, const std::string &b, const char *what, const char *file, int line)
{
    ++g_checks;
    if (a != b) {
        ++g_failed;
        (void)std::fprintf(stderr, "%s:%d: FAILED: %s\n  got:      %s\n  expected: %s\n",
                     file, line, what, a.c_str(), b.c_str());
    }
}

void checkEq(long a, long b, const char *what, const char *file, int line)
{
    checkEq(std::to_string(a), std::to_string(b), what, file, line);
}

int removeOne(const char *path, const struct stat * /*st*/, int /*type*/, struct FTW * /*ftw*/)
{
    return ::remove(path);
}

struct TempDir
{
    std::string path;

    TempDir()
    {
        const char *base = std::getenv("TMPDIR");
        std::string pattern = std::string(base && *base ? base : "/tmp") + "/firstuse-handoff-XXXXXX";
        const char *made = ::mkdtemp(pattern.data());
        path = made != nullptr ? made : "";
    }

    ~TempDir()
    {
        if (!path.empty())
            (void)::nftw(path.c_str(), removeOne, 8, FTW_DEPTH | FTW_PHYS);
    }

    std::string file(const char *name) const { return path + "/" + name; }

    //! How many entries the directory holds.
    long entries() const
    {
        long n = 0;
        DIR *d = ::opendir(path.c_str());
        if (!d)
            return -1;
        while (const struct dirent *e = ::readdir(d)) {
            if (std::strcmp(e->d_name, ".") != 0 && std::strcmp(e->d_name, "..") != 0)
                ++n;
        }
        ::closedir(d);
        return n;
    }
};

std::string read(const std::string &path)
{
    std::FILE *f = std::fopen(path.c_str(), "r");
    if (!f)
        return "<missing>";
    std::string out;
    char buf[256];
    size_t n;
    while ((n = std::fread(buf, 1, sizeof(buf), f)) > 0) {
        out.append(buf, n);
        if (std::feof(f) != 0 || std::ferror(f) != 0)
            break;
    }
    (void)std::fclose(f);
    return out;
}

bool write(const std::string &path, const std::string &content)
{
    std::FILE *f = std::fopen(path.c_str(), "w");
    if (!f)
        return false;
    const bool ok = std::fwrite(content.data(), 1, content.size(), f) == content.size();
    return std::fclose(f) == 0 && ok;
}

bool exists(const std::string &path)
{
    struct stat st;
    return ::lstat(path.c_str(), &st) == 0;
}

void restoreOnly()
{
    TempDir dir;
    const std::string path = dir.file("firstuse-handoff.json");
    CHECK_EQ(firstuse::writeHandoff(path.c_str(), true, false), 0L);
    CHECK_EQ(read(path), "{\"restore\":true,\"accounts\":false}\n");
    CHECK_EQ(dir.entries(), 1L);
    struct stat st;
    CHECK(::stat(path.c_str(), &st) == 0 && (st.st_mode & 07777) == 0644);
}

void both()
{
    TempDir dir;
    const std::string path = dir.file("firstuse-handoff.json");
    CHECK_EQ(firstuse::writeHandoff(path.c_str(), true, true), 0L);
    CHECK_EQ(read(path), "{\"restore\":true,\"accounts\":true}\n");
}

void accountsOnly()
{
    TempDir dir;
    const std::string path = dir.file("firstuse-handoff.json");
    CHECK_EQ(firstuse::writeHandoff(path.c_str(), false, true), 0L);
    CHECK_EQ(read(path), "{\"restore\":false,\"accounts\":true}\n");
}

void neitherRemovesWhatWasThere()
{
    TempDir dir;
    const std::string path = dir.file("firstuse-handoff.json");
    CHECK(write(path, "{\"restore\":true}"));
    CHECK_EQ(firstuse::writeHandoff(path.c_str(), false, false), 0L);
    CHECK(!exists(path));
    // and with nothing there, there is nothing to do.
    CHECK_EQ(firstuse::writeHandoff(path.c_str(), false, false), 0L);
    CHECK_EQ(dir.entries(), 0L);
}

void anOldFileIsReplaced()
{
    TempDir dir;
    const std::string path = dir.file("firstuse-handoff.json");
    CHECK(write(path, "{\"restore\":true,\"accounts\":true,\"more\":\"from before\"}"));
    CHECK_EQ(firstuse::writeHandoff(path.c_str(), false, true), 0L);
    CHECK_EQ(read(path), "{\"restore\":false,\"accounts\":true}\n");
    CHECK_EQ(dir.entries(), 1L);
}

void aSymlinkIsReplacedNotFollowed()
{
    TempDir dir;
    const std::string path = dir.file("firstuse-handoff.json");
    const std::string target = dir.file("elsewhere");
    CHECK(write(target, "keep me"));
    CHECK_EQ(::symlink(target.c_str(), path.c_str()), 0L);
    CHECK_EQ(firstuse::writeHandoff(path.c_str(), true, false), 0L);
    CHECK_EQ(read(target), "keep me");
    struct stat st;
    CHECK(::lstat(path.c_str(), &st) == 0 && S_ISREG(st.st_mode));
    CHECK_EQ(read(path), "{\"restore\":true,\"accounts\":false}\n");

    // Neither: the link goes, its target stays.
    CHECK_EQ(::symlink(target.c_str(), dir.file("again").c_str()), 0L);
    CHECK_EQ(firstuse::writeHandoff(dir.file("again").c_str(), false, false), 0L);
    CHECK(!exists(dir.file("again")));
    CHECK_EQ(read(target), "keep me");
}

void aMissingDirectoryFailsAndLeavesNothing()
{
    TempDir dir;
    const std::string path = dir.file("no-such-dir/firstuse-handoff.json");
    CHECK_EQ(firstuse::writeHandoff(path.c_str(), true, true), long(ENOENT));
    CHECK_EQ(dir.entries(), 0L);
}

void aDirectoryInTheWayFailsAndLeavesNoTempFile()
{
    TempDir dir;
    const std::string path = dir.file("firstuse-handoff.json");
    CHECK_EQ(::mkdir(path.c_str(), 0700), 0L);
    CHECK(firstuse::writeHandoff(path.c_str(), true, false) != 0);
    // Only the directory: the temporary file was cleaned up.
    CHECK_EQ(dir.entries(), 1L);
}

void noPathIsRefused()
{
    CHECK_EQ(firstuse::writeHandoff(nullptr, true, true), long(EINVAL));
    CHECK_EQ(firstuse::writeHandoff("", true, true), long(EINVAL));
}

void thePathIsWhereLunaAppManagerLooks()
{
    CHECK_EQ(std::string(firstuse::kHandoffPath), "/var/luna/preferences/firstuse-handoff.json");
}

} // namespace

int main()
{
    restoreOnly();
    both();
    accountsOnly();
    neitherRemovesWhatWasThere();
    anOldFileIsReplaced();
    aSymlinkIsReplacedNotFollowed();
    aMissingDirectoryFailsAndLeavesNothing();
    aDirectoryInTheWayFailsAndLeavesNoTempFile();
    noPathIsRefused();
    thePathIsWhereLunaAppManagerLooks();

    std::printf("%d checks, %d failed\n", g_checks, g_failed);
    return g_failed ? 1 : 0;
}
