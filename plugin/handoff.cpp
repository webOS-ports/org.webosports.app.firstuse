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

#include "handoff.h"

#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <string>

#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

namespace firstuse {

const char *const kHandoffPath = "/var/luna/preferences/firstuse-handoff.json";

namespace {

int writeAll(int fd, const std::string &data)
{
    size_t done = 0;
    while (done < data.size()) {
        const ssize_t n = ::write(fd, data.data() + done, data.size() - done);
        if (n < 0) {
            if (errno == EINTR)
                continue;
            return errno;
        }
        done += static_cast<size_t>(n);
    }
    return 0;
}

} // namespace

int writeHandoff(const char *path, bool restore, bool accounts)
{
    if (path == nullptr || *path == '\0')
        return EINVAL;

    if (!restore && !accounts) {
        if (::unlink(path) != 0 && errno != ENOENT)
            return errno;
        return 0;
    }

    const std::string data = std::string("{\"restore\":") + (restore ? "true" : "false") +
                             ",\"accounts\":" + (accounts ? "true" : "false") + "}\n";

    // mkstemp: a name nobody could have guessed or planted, made O_EXCL.
    std::string temp = std::string(path) + ".XXXXXX";
    const int fd = ::mkostemp(temp.data(), O_CLOEXEC);
    if (fd < 0)
        return errno;

    int err = writeAll(fd, data);
    if (err == 0 && ::fchmod(fd, 0644) != 0)
        err = errno;
    if (err == 0 && ::fsync(fd) != 0)
        err = errno;
    if (::close(fd) != 0 && err == 0)
        err = errno;
    // rename replaces whatever is at path - a symlink included - itself.
    if (err == 0 && ::rename(temp.c_str(), path) != 0)
        err = errno;
    if (err != 0)
        (void)::unlink(temp.c_str());
    return err;
}

} // namespace firstuse
