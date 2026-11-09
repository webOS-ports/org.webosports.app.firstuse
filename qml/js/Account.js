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

.pragma library

/*
 * What the Community Account pages say when com.palm.accountservices
 * (org.webosports.service.communityaccount) turns something down: a
 * sentence for each code it gives, and the code itself, shown small, so a
 * failure can be told apart and reported. The service's own errorText is
 * not shown: it is written for the log.
 */

var UNAVAILABLE = "Signing in is not available right now. You can sign in later from Accounts.";

// The bus call could not be made at all: no code from the service.
var NO_SERVICE = "NO_SERVICE";

var SENTENCES = {
    "AUTH_FAILED": "That e-mail address and password do not match an account.",
    "LOGIN_ERROR": "That e-mail address and password do not match an account.",
    "EMAIL_TAKEN": "There is already an account with this e-mail address. Sign in with it instead.",
    "INVALID_EMAIL": "Please enter a valid e-mail address.",
    "WEAK_PASSWORD": "The password needs at least 8 characters.",
    "MISSING_ARGS": "Please fill in every field that is needed.",
    "INVALID_REQUEST": "The account server could not read the request. Please check what you entered.",
    "ACCOUNT_CREATION_ERROR": "The account server could not make the account. Please try again later.",
    "SERVER_UNREACHABLE": "The account server cannot be reached. Check that the device is online, then try again.",
    "SERVER_ERROR": "The account server had a problem. Please try again later.",
    "BAD_REPLY": "The account server gave an answer this device does not understand. Please try again later.",
    "TERMS_ERROR": "The terms of service could not be fetched. Check that the device is online, then try again.",
    "DEVICE_ID_UNAVAILABLE": "This device could not identify itself to the account server. You can sign in later from Accounts.",
    "CONNECTOR_EXCEPTION": "Something went wrong on this device while signing in. You can sign in later from Accounts.",
    "NO_SERVICE": UNAVAILABLE
};

// The reply's JSON, or null.
function parse(message) {
    if (!message || !message.payload)
        return null;
    try {
        return JSON.parse(message.payload);
    } catch (e) {
        return null;
    }
}

// A code safe to show: letters, digits and "_" only, and not too long.
function codeOf(reply) {
    var code = reply && reply.errorCode !== undefined ? String(reply.errorCode) : "";
    return /^[A-Za-z0-9_-]{1,40}$/.test(code) ? code : "";
}

// {text, code} for a reply that is not returnValue true (or null: no reply
// that could be read).
function refusal(reply) {
    var code = codeOf(reply);
    var text = SENTENCES.hasOwnProperty(code) ? SENTENCES[code] : UNAVAILABLE;
    return { text: text, code: code !== "" ? code : (reply ? "UNKNOWN" : "BAD_REPLY") };
}

// What the server counts: bytes of UTF-8.
function utf8Length(s) {
    return unescape(encodeURIComponent(s)).length;
}

var MIN_PASSWORD = 8;
