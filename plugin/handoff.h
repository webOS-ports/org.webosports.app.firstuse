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

#ifndef FIRSTUSE_HANDOFF_H_
#define FIRSTUSE_HANDOFF_H_

/*
 * What to open once first use is over, for LunaAppManager.
 *
 * Restoring a backup and adding accounts cannot happen while first use runs,
 * so first use only records the choice and LunaAppManager's BootManager opens
 * the apps when it enters the normal state (luna-appmanager
 * Src/base/FirstUseHandoff.h). The file is a JSON object with the keys
 * "restore" and "accounts"; BootManager reads it once and removes it.
 */
namespace firstuse {

//! Where BootManager looks for it.
extern const char *const kHandoffPath;

/*
 * Writes {"restore":..,"accounts":..} to path, whole or not at all: into a
 * new file next to it, then renamed over it, so BootManager never reads half
 * a file and a symlink at path is replaced, not followed. With neither set,
 * removes path instead, so nothing left from before is opened. Returns 0, or
 * the errno of what failed.
 */
int writeHandoff(const char *path, bool restore, bool accounts);

} // namespace firstuse

#endif
