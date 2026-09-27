import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import "../../reusables"
import "../../"

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 180
    property real minHeight: 60
    property real maxWidth: 1200
    property real maxHeight: 600
    property real minAspect: 1.2
    property real maxAspect: 5.0
    property bool isRound: false

    readonly property real widgetRadius: root.isRound ? (Math.min(root.width, root.height) / 2) : (ThemeBackend.borderRadius * 2)
    readonly property color primaryColor: ThemeBackend.mauve

    property var player: MprisController.activePlayer
    readonly property bool isMediaActive: player !== null && player.playbackState !== MprisPlaybackState.Stopped && (player.trackTitle || "") !== ""
    readonly property string trackTitle: player ? (player.trackTitle || "") : ""
    readonly property string trackArtist: player ? (player.trackArtist || "") : ""
    readonly property string currentTrackKey: isMediaActive ? (trackArtist.trim() + " - " + trackTitle.trim()) : ""

    property var lyrics: []
    property bool hasLyrics: false
    property bool loading: false
    property string activeFetchKey: ""
    property string lastFetchedKey: ""
    property real currentPosition: 0
    property var activeSession: null

    readonly property real sideMargin: Math.max(Scaler.s(12), root.width * 0.05)
    readonly property real availableContentWidth: Math.max(10, root.width - (sideMargin * 2))

    readonly property real dynBaseFont: Math.min(root.height * 0.15, root.width * 0.065)
    readonly property real baseActiveFont: Math.max(Scaler.s(13), Math.min(Scaler.s(22), dynBaseFont))
    readonly property real baseNormalFont: Math.max(Scaler.s(10), Math.min(Scaler.s(16), baseActiveFont * 0.82))

    readonly property real lineHeight: Math.max(Scaler.s(18), Math.min(Scaler.s(30), root.height * 0.125))
    readonly property real lineSpacing: Math.max(Scaler.s(2), Math.min(Scaler.s(6), root.height * 0.024))
    readonly property real itemStep: lineHeight + lineSpacing

    readonly property int currentIndex: {
        if (!hasLyrics || lyrics.length === 0) return -1;
        let pos = currentPosition;
        let idx = -1;
        for (let i = 0; i < lyrics.length; i++) {
            if (pos >= lyrics[i].time) {
                idx = i;
            } else {
                break;
            }
        }
        return idx;
    }

    readonly property real targetY: {
        let center = bgContainer.height * 0.44;
        if (currentIndex >= 0) {
            return center - (currentIndex * itemStep + lineHeight / 2);
        }
        return center - (lineHeight / 2);
    }

    function getPlayerDurationSec() {
        if (!root.player || !root.player.length) return 0;
        let len = root.player.length;
        if (len > 10000) return len / 1000000.0;
        return len;
    }

    function pickBestNetEaseSong(songs) {
        if (!songs || songs.length === 0) return null;
        let targetDur = getPlayerDurationSec();
        if (targetDur <= 0) return songs[0];
        let best = songs[0];
        let bestDiff = Math.abs(((songs[0].dt || songs[0].duration || 0) / 1000.0) - targetDur);
        for (let i = 1; i < songs.length; i++) {
            let dur = ((songs[i].dt || songs[i].duration || 0) / 1000.0);
            let diff = Math.abs(dur - targetDur);
            if (diff < bestDiff) {
                bestDiff = diff;
                best = songs[i];
            }
        }
        return best;
    }

    function computeFontSize(lineText, isActive) {
        let baseSize = isActive ? root.baseActiveFont : root.baseNormalFont;
        let str = lineText ? lineText.trim() : "";
        if (str.length === 0 || root.availableContentWidth <= 0) return baseSize;

        let charFactor = isActive ? 0.58 : 0.52;
        let estimatedWidth = str.length * baseSize * charFactor;

        if (estimatedWidth <= root.availableContentWidth) {
            return baseSize;
        }

        let scaledSize = baseSize * (root.availableContentWidth / estimatedWidth);
        let minAllowedSize = Math.max(Scaler.s(9), Math.min(Scaler.s(11), root.height * 0.07));

        return Math.max(minAllowedSize, scaledSize);
    }

    function getLineOpacity(idx) {
        if (root.currentIndex < 0) return 0.50;
        if (idx === root.currentIndex) return 1.0;
        let d = Math.abs(idx - root.currentIndex);
        if (d === 1) return 0.56;
        if (d === 2) return 0.32;
        return Math.max(0.14, 0.32 - ((d - 2) * 0.08));
    }

    function renderActiveLineText(modelData, pos) {
        if (!modelData.words || modelData.words.length === 0) {
            return modelData.text !== "" ? modelData.text : "♪";
        }
        let activeIdx = -1;
        for (let i = 0; i < modelData.words.length; i++) {
            let w = modelData.words[i];
            let end = (w.endTime !== undefined && w.endTime > w.time) ? w.endTime : (i < modelData.words.length - 1 ? modelData.words[i + 1].time : (w.time + 0.8));
            if (pos >= w.time && pos < end) {
                activeIdx = i;
                break;
            }
        }
        let highlight = root.primaryColor.toString();
        let past = ThemeBackend.text.toString();
        let upcoming = Qt.rgba(ThemeBackend.text.r, ThemeBackend.text.g, ThemeBackend.text.b, 0.40).toString();
        let html = "";
        for (let i = 0; i < modelData.words.length; i++) {
            let w = modelData.words[i];
            let escaped = w.text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
            let end = (w.endTime !== undefined && w.endTime > w.time) ? w.endTime : (i < modelData.words.length - 1 ? modelData.words[i + 1].time : (w.time + 0.8));

            let space = "";
            if (i < modelData.words.length - 1) {
                let nextW = modelData.words[i + 1];
                if (!w.text.endsWith(" ") && !nextW.text.startsWith(" ")) {
                    if (/[\w\.,!\?]/.test(w.text)) {
                        space = " ";
                    }
                }
            }

            if (i === activeIdx) {
                html += "<font color='" + highlight + "'>" + escaped + "</font>" + space;
            } else if (pos >= end || (activeIdx !== -1 && i < activeIdx)) {
                html += "<font color='" + past + "'>" + escaped + "</font>" + space;
            } else {
                html += "<font color='" + upcoming + "'>" + escaped + "</font>" + space;
            }
        }
        return html.trim();
    }

    Timer {
        id: positionTimer
        interval: 25
        repeat: true
        running: root.visible && root.isMediaActive && (root.player ? root.player.isPlaying : false)
        onTriggered: {
            if (root.player) {
                if (typeof root.player.positionChanged === "function") {
                    root.player.positionChanged();
                }
                root.currentPosition = root.player.position;
            } else {
                root.currentPosition = MprisController.livePosition;
            }
        }
    }

    Timer {
        id: searchTimeoutTimer
        interval: 3500
        repeat: false
        onTriggered: {
            if (root.loading && root.activeSession && !root.activeSession.done) {
                root.activeSession.netEaseDone = true;
                root.activeSession.lrclibDone = true;
                root.checkCompletion(root.activeSession);
            }
        }
    }

    Connections {
        target: MprisController
        function onLivePositionChanged() {
            if (!root.player || !root.player.isPlaying) {
                root.currentPosition = MprisController.livePosition;
            }
        }
        function onActivePlayerChanged() {
            root.triggerSearch();
        }
    }

    Connections {
        target: root.player
        function onPositionChanged() {
            if (root.player) root.currentPosition = root.player.position;
        }
        function onTrackTitleChanged() {
            root.triggerSearch();
        }
        function onTrackArtistChanged() {
            root.triggerSearch();
        }
        function onPlaybackStateChanged() {
            root.triggerSearch();
        }
    }

    onCurrentTrackKeyChanged: triggerSearch()

    Component.onCompleted: triggerSearch()

    function triggerSearch() {
        if (!isMediaActive || currentTrackKey === "") {
            lastFetchedKey = "";
            activeFetchKey = "";
            activeSession = null;
            lyrics = [];
            hasLyrics = false;
            loading = false;
            searchTimeoutTimer.stop();
            return;
        }

        if (currentTrackKey === lastFetchedKey) {
            return;
        }

        lastFetchedKey = currentTrackKey;
        activeFetchKey = currentTrackKey;
        fetchLyrics(trackArtist, trackTitle, currentTrackKey);
    }

    function cleanString(str) {
        return str.replace(/\s*[\(\[](?:feat\.|ft\.|official|video|audio|remastered|deluxe|version).*?[\)\]]/gi, "").trim();
    }

    function parseYrc(yrcText) {
        if (!yrcText || typeof yrcText !== "string") return null;
        let lines = yrcText.split("\n");
        let result = [];
        let hasAnyWord = false;

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim();
            if (!line) continue;

            let lineTime = -1;
            let content = "";

            let msMatch = line.match(/^\[(\d+),(\d+)\](.*)$/);
            if (msMatch) {
                lineTime = parseFloat(msMatch[1]) / 1000.0;
                content = msMatch[3];
            } else {
                let lrcMatch = line.match(/^\[(\d{1,2}):(\d{1,2}(?:\.\d{1,3})?)\](.*)$/);
                if (lrcMatch) {
                    lineTime = parseFloat(lrcMatch[1]) * 60 + parseFloat(lrcMatch[2]);
                    content = lrcMatch[3];
                }
            }

            if (lineTime < 0) continue;

            let words = [];
            let wordRegex = /\((\d+),(\d+)(?:,\d+)?\)([^\(\[\n\r]*)/g;
            let match;

            while ((match = wordRegex.exec(content)) !== null) {
                let rawStart = parseFloat(match[1]) / 1000.0;
                let dur = parseFloat(match[2]) / 1000.0;
                let wStart = (rawStart < lineTime) ? (lineTime + rawStart) : rawStart;
                let wEnd = wStart + (dur > 0 ? dur : 0.25);
                let wText = match[3];
                if (wText !== "") {
                    words.push({ time: wStart, endTime: wEnd, text: wText });
                }
            }

            if (words.length === 0) {
                let altRegex = /<(\d+),(\d+)>([^<]*)/g;
                while ((match = altRegex.exec(content)) !== null) {
                    let rawStart = parseFloat(match[1]) / 1000.0;
                    let dur = parseFloat(match[2]) / 1000.0;
                    let wStart = (rawStart < lineTime) ? (lineTime + rawStart) : rawStart;
                    let wEnd = wStart + (dur > 0 ? dur : 0.25);
                    let wText = match[3];
                    if (wText !== "") {
                        words.push({ time: wStart, endTime: wEnd, text: wText });
                    }
                }
            }

            let cleanLine = content.replace(/\(\d+,\d+(?:,\d+)?\)/g, "").replace(/<\d+,\d+>/g, "").trim();
            if (cleanLine === "" && words.length > 0) {
                cleanLine = words.map(function(w) { return w.text; }).join("").trim();
            }

            if (words.length > 0) {
                hasAnyWord = true;
                result.push({
                    time: lineTime,
                    text: cleanLine,
                    words: words
                });
            } else if (cleanLine !== "") {
                result.push({
                    time: lineTime,
                    text: cleanLine,
                    words: []
                });
            }
        }

        if (hasAnyWord && result.length > 0) {
            result.sort(function(a, b) { return a.time - b.time; });
            return result;
        }
        return null;
    }

    function parseEnhancedLrc(lrcText) {
        if (!lrcText || typeof lrcText !== "string") return null;
        let lines = lrcText.split("\n");
        let result = [];
        let hasAnyWord = false;

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim();
            if (!line) continue;

            let lineTimeMatch = line.match(/^\[(\d{1,2}):(\d{1,2}(?:\.\d{1,3})?)\]/);
            if (!lineTimeMatch) continue;

            let lineTime = parseFloat(lineTimeMatch[1]) * 60 + parseFloat(lineTimeMatch[2]);
            let content = line.replace(/^\[\d{1,2}:\d{1,2}(?:\.\d{1,3})?\]/, "").trim();

            let wordRegex = /<(\d{1,2}):(\d{1,2}(?:\.\d{1,3})?)>\s*([^<]*)/g;
            let wordMatch;
            let words = [];

            while ((wordMatch = wordRegex.exec(content)) !== null) {
                let wTime = parseFloat(wordMatch[1]) * 60 + parseFloat(wordMatch[2]);
                let wText = wordMatch[3].trim();
                if (wText !== "") {
                    words.push({ time: wTime, endTime: wTime + 0.3, text: wText });
                }
            }

            for (let j = 0; j < words.length - 1; j++) {
                words[j].endTime = words[j + 1].time;
            }

            if (words.length > 0) {
                hasAnyWord = true;
                let cleanLine = content.replace(/<\d{1,2}:\d{1,2}(?:\.\d{1,3})?>/g, " ").replace(/\s+/g, " ").trim();
                result.push({
                    time: lineTime,
                    text: cleanLine,
                    words: words
                });
            } else {
                result.push({
                    time: lineTime,
                    text: content.trim(),
                    words: []
                });
            }
        }

        if (hasAnyWord && result.length > 0) {
            result.sort(function(a, b) { return a.time - b.time; });
            return result;
        }
        return null;
    }

    function parseWordSynced(raw) {
        if (!raw) return null;
        let data = raw;
        if (typeof raw === "string") {
            let trimmed = raw.trim();
            if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
                try {
                    data = JSON.parse(trimmed);
                } catch(e) {
                    data = null;
                }
            }
        }

        if (data && typeof data === "object") {
            let linesArr = Array.isArray(data) ? data : (data.lines || data.lyrics || data.sync || null);
            if (Array.isArray(linesArr) && linesArr.length > 0) {
                let parsed = [];
                for (let i = 0; i < linesArr.length; i++) {
                    let l = linesArr[i];
                    let lineTime = 0;
                    if (l.time !== undefined) lineTime = parseFloat(l.time);
                    else if (l.start_ms !== undefined) lineTime = parseFloat(l.start_ms) / 1000;
                    else if (l.startTime !== undefined) lineTime = parseFloat(l.startTime) / 1000;
                    else if (l.start !== undefined) lineTime = parseFloat(l.start) > 1000 ? parseFloat(l.start) / 1000 : parseFloat(l.start);

                    let wordsArr = l.words || l.syllables || [];
                    let words = [];
                    let lineText = l.text || l.line || "";

                    if (Array.isArray(wordsArr) && wordsArr.length > 0) {
                        for (let j = 0; j < wordsArr.length; j++) {
                            let w = wordsArr[j];
                            let wTime = lineTime;
                            if (w.time !== undefined) wTime = parseFloat(w.time);
                            else if (w.start_ms !== undefined) wTime = parseFloat(w.start_ms) / 1000;
                            else if (w.startTime !== undefined) wTime = parseFloat(w.startTime) / 1000;
                            else if (w.start !== undefined) wTime = parseFloat(w.start) > 1000 ? parseFloat(w.start) / 1000 : parseFloat(w.start);

                            let wEnd = wTime + 0.3;
                            if (w.endTime !== undefined) wEnd = parseFloat(w.endTime) > 1000 ? parseFloat(w.endTime) / 1000 : parseFloat(w.endTime);
                            else if (w.end_ms !== undefined) wEnd = parseFloat(w.end_ms) / 1000;
                            else if (w.duration !== undefined) wEnd = wTime + (parseFloat(w.duration) > 1000 ? parseFloat(w.duration) / 1000 : parseFloat(w.duration));

                            let wText = w.text !== undefined ? w.text : (w.word !== undefined ? w.word : "");
                            if (wText !== "") {
                                words.push({ time: wTime, endTime: wEnd, text: wText });
                            }
                        }

                        for (let j = 0; j < words.length - 1; j++) {
                            if (words[j].endTime <= words[j].time) {
                                words[j].endTime = words[j + 1].time;
                            }
                        }
                    }

                    if (words.length > 0 && lineText === "") {
                        lineText = words.map(function(item) { return item.text; }).join(" ").trim();
                    }

                    if (words.length > 0 || lineText !== "") {
                        if (words.length > 0 && lineTime === 0) {
                            lineTime = words[0].time;
                        }
                        parsed.push({
                            time: lineTime,
                            text: lineText,
                            words: words
                        });
                    }
                }

                if (parsed.length > 0 && parsed.some(function(p) { return p.words && p.words.length > 0; })) {
                    parsed.sort(function(a, b) { return a.time - b.time; });
                    return parsed;
                }
            }
        }

        if (typeof raw === "string") {
            return parseEnhancedLrc(raw);
        }

        return null;
    }

    function parseWordLevelLyrics(raw) {
        if (!raw) return null;
        let res = parseYrc(raw);
        if (res && res.length > 0) return res;
        res = parseWordSynced(raw);
        if (res && res.length > 0) return res;
        return null;
    }

    function parseLrc(lrcText) {
        if (!lrcText || typeof lrcText !== "string") return [];
        let lines = lrcText.split("\n");
        let result = [];
        let timeRegex = /\[(\d{1,2}):(\d{1,2}(?:\.\d{1,3})?)\]/g;

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim();
            if (!line) continue;

            let times = [];
            let match;
            timeRegex.lastIndex = 0;

            while ((match = timeRegex.exec(line)) !== null) {
                times.push(parseFloat(match[1]) * 60 + parseFloat(match[2]));
            }

            if (times.length > 0) {
                let text = line.replace(/\[\d{1,2}:\d{1,2}(?:\.\d{1,3})?\]/g, "").trim();
                for (let j = 0; j < times.length; j++) {
                    result.push({ time: times[j], text: text, words: [] });
                }
            }
        }

        result.sort(function(a, b) { return a.time - b.time; });
        return result;
    }

    function applyLyrics(parsedList, key) {
        if (key !== root.activeFetchKey) return;
        searchTimeoutTimer.stop();
        root.lyrics = parsedList;
        root.hasLyrics = parsedList && parsedList.length > 0;
        root.loading = false;
    }

    function checkCompletion(session) {
        if (session.key !== root.activeFetchKey || session.done) return;
        if (session.netEaseDone && session.lrclibDone) {
            session.done = true;
            searchTimeoutTimer.stop();
            if (session.lineCandidate && session.lineCandidate.length > 0) {
                applyLyrics(session.lineCandidate, session.key);
            } else {
                root.loading = false;
                root.hasLyrics = false;
                root.lyrics = [];
            }
        }
    }

    function fetchLyrics(artist, title, requestKey) {
        loading = true;
        hasLyrics = false;
        lyrics = [];

        let cleanT = cleanString(title);
        let cleanA = cleanString(artist);

        let session = {
            key: requestKey,
            artist: cleanA,
            title: cleanT !== "" ? cleanT : title,
            done: false,
            hasWordLyrics: false,
            netEaseDone: false,
            lrclibDone: false,
            lineCandidate: null
        };

        activeSession = session;
        searchTimeoutTimer.restart();

        fetchNetEase(session);
        fetchLrclib(session);
    }

    function fetchNetEase(session) {
        let query = (session.artist + " " + session.title).trim();
        if (query === "") query = session.title;

        let url = "https://music.163.com/api/search/get/web?csrf_token=&hlpretag=&hlposttag=&s=" + encodeURIComponent(query) + "&type=1&offset=0&total=true&limit=5";
        let xhr = new XMLHttpRequest();
        xhr.open("GET", url);

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (session.key !== root.activeFetchKey || session.done) return;

            if (xhr.status === 200) {
                try {
                    let resp = JSON.parse(xhr.responseText);
                    let songs = resp.result && resp.result.songs ? resp.result.songs : [];
                    let bestSong = pickBestNetEaseSong(songs);

                    if (bestSong && bestSong.id) {
                        fetchNetEaseLyric(bestSong.id, session);
                        return;
                    }
                } catch(e) {}
            }

            session.netEaseDone = true;
            checkCompletion(session);
        };

        xhr.send();
    }

    function fetchNetEaseLyric(songId, session) {
        let url = "https://music.163.com/api/song/lyric?id=" + songId + "&lv=1&kv=1&tv=-1&yv=1";
        let xhr = new XMLHttpRequest();
        xhr.open("GET", url);

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (session.key !== root.activeFetchKey || session.done) return;

            if (xhr.status === 200) {
                try {
                    let resp = JSON.parse(xhr.responseText);
                    let wordLyrics = null;

                    if (resp.yrc && resp.yrc.lyric) {
                        wordLyrics = parseWordLevelLyrics(resp.yrc.lyric);
                    }
                    if (!wordLyrics && resp.klyric && resp.klyric.lyric) {
                        wordLyrics = parseWordLevelLyrics(resp.klyric.lyric);
                    }

                    if (wordLyrics && wordLyrics.length > 0) {
                        session.hasWordLyrics = true;
                        session.done = true;
                        applyLyrics(wordLyrics, session.key);
                        return;
                    }

                    if (resp.lrc && resp.lrc.lyric) {
                        let lines = parseLrc(resp.lrc.lyric);
                        if (lines && lines.length > 0 && !session.lineCandidate) {
                            session.lineCandidate = lines;
                        }
                    }
                } catch(e) {}
            }

            session.netEaseDone = true;
            checkCompletion(session);
        };

        xhr.send();
    }

    function fetchLrclib(session) {
        if (session.artist === "" || session.title === "") {
            fetchLrclibSearch(session);
            return;
        }

        let url = "https://lrclib.net/api/get?track_name=" + encodeURIComponent(session.title) + "&artist_name=" + encodeURIComponent(session.artist);
        let xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.setRequestHeader("Lrclib-Client", "serpantinum-shell");

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (session.key !== root.activeFetchKey || session.done) return;

            if (xhr.status === 200) {
                try {
                    let resp = JSON.parse(xhr.responseText);
                    let rawLyricsFile = resp.lyricsfile || resp.lyricsFile || resp.lyrics_file;
                    let wordLyrics = parseWordLevelLyrics(rawLyricsFile) || parseWordLevelLyrics(resp.syncedLyrics);

                    if (wordLyrics && wordLyrics.length > 0) {
                        session.hasWordLyrics = true;
                        session.done = true;
                        applyLyrics(wordLyrics, session.key);
                        return;
                    }

                    if (resp.syncedLyrics && resp.syncedLyrics.trim() !== "") {
                        let lines = parseLrc(resp.syncedLyrics);
                        if (lines && lines.length > 0 && !session.lineCandidate) {
                            session.lineCandidate = lines;
                        }
                    }

                    session.lrclibDone = true;
                    checkCompletion(session);
                    return;
                } catch(e) {}
            }

            fetchLrclibSearch(session);
        };

        xhr.send();
    }

    function fetchLrclibSearch(session) {
        let query = (session.artist + " " + session.title).trim();
        if (query === "") query = session.title;

        let url = "https://lrclib.net/api/search?q=" + encodeURIComponent(query);
        let xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.setRequestHeader("Lrclib-Client", "serpantinum-shell");

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (session.key !== root.activeFetchKey || session.done) return;

            if (xhr.status === 200) {
                try {
                    let list = JSON.parse(xhr.responseText);
                    if (Array.isArray(list) && list.length > 0) {
                        for (let i = 0; i < list.length; i++) {
                            let rawFile = list[i].lyricsfile || list[i].lyricsFile || list[i].lyrics_file;
                            let wordLyrics = parseWordLevelLyrics(rawFile) || parseWordLevelLyrics(list[i].syncedLyrics);
                            if (wordLyrics && wordLyrics.length > 0) {
                                session.hasWordLyrics = true;
                                session.done = true;
                                applyLyrics(wordLyrics, session.key);
                                return;
                            }
                        }

                        for (let i = 0; i < list.length; i++) {
                            if (list[i].syncedLyrics && list[i].syncedLyrics.trim() !== "") {
                                let lines = parseLrc(list[i].syncedLyrics);
                                if (lines && lines.length > 0 && !session.lineCandidate) {
                                    session.lineCandidate = lines;
                                    break;
                                }
                            }
                        }
                    }
                } catch(e) {}
            }

            session.lrclibDone = true;
            checkCompletion(session);
        };

        xhr.send();
    }

    Rectangle {
        id: bgContainer
        anchors.fill: parent
        color: ThemeBackend.surface0
        radius: root.widgetRadius
        clip: true

        Rectangle {
            id: bgMask
            anchors.fill: parent
            radius: root.widgetRadius
            color: "#ffffff"
            visible: false
            layer.enabled: true
        }

        Item {
            id: artMaskedContainer
            anchors.fill: parent
            visible: root.isMediaActive && Boolean(MprisController.artUrl)
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: bgMask
            }

            Image {
                id: bgArtImg
                anchors.fill: parent
                source: (root.isMediaActive && MprisController.artUrl) ? (MprisController.artUrl.startsWith("file://") || MprisController.artUrl.startsWith("http") ? MprisController.artUrl : "file://" + MprisController.artUrl) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: (status === Image.Ready && source !== "") ? 1.0 : 0.0
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 0.40
                    blurMax: 32
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Rectangle {
                id: artDarkScrim
                anchors.fill: parent
                color: Qt.rgba(ThemeBackend.crust.r, ThemeBackend.crust.g, ThemeBackend.crust.b, 0.45)
            }
        }

        Item {
            id: lyricsViewport
            anchors.fill: parent
            visible: root.hasLyrics
            clip: true

            Item {
                id: scrollContainer
                width: parent.width
                height: root.lyrics.length * root.itemStep
                y: root.targetY

                Behavior on y {
                    NumberAnimation {
                        duration: 520
                        easing.type: Easing.OutQuart
                    }
                }

                Repeater {
                    model: root.lyrics

                    delegate: Item {
                        width: scrollContainer.width
                        height: root.lineHeight
                        y: index * root.itemStep

                        property real calculatedFontSize: root.computeFontSize(modelData.text, index === root.currentIndex)

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: root.sideMargin
                            anchors.rightMargin: root.sideMargin
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignLeft
                            font.family: ThemeBackend.fontFamily
                            font.weight: index === root.currentIndex ? Font.Black : Font.Bold
                            font.pixelSize: parent.calculatedFontSize
                            color: (index === root.currentIndex && (!modelData.words || modelData.words.length === 0)) ? root.primaryColor : ThemeBackend.text
                            opacity: root.getLineOpacity(index)
                            scale: {
                                if (index === root.currentIndex) return 1.0;
                                let d = Math.abs(index - root.currentIndex);
                                if (d === 1) return 0.96;
                                return 0.92;
                            }
                            transformOrigin: Item.Left
                            elide: Text.ElideRight

                            textFormat: (index === root.currentIndex && modelData.words && modelData.words.length > 0) ? Text.StyledText : Text.PlainText

                            text: {
                                if (index === root.currentIndex && modelData.words && modelData.words.length > 0) {
                                    return root.renderActiveLineText(modelData, root.currentPosition);
                                }
                                return modelData.text !== "" ? modelData.text : "♪";
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 320
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 380
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 380
                                    easing.type: Easing.OutQuart
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: root.widgetRadius
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(ThemeBackend.text.r, ThemeBackend.text.g, ThemeBackend.text.b, 0.08)
            z: 10
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Scaler.s(6)
            visible: !root.hasLyrics
            z: 5

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "󰎈"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: Scaler.s(26)
                color: root.primaryColor
                opacity: 0.75
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    if (!root.isMediaActive) return I18n.t("music.nothing_playing");
                    if (root.loading) return I18n.t("music.searching_lyrics");
                    return I18n.t("music.no_lyrics");
                }
                font.family: ThemeBackend.fontFamily
                font.weight: Font.DemiBold
                font.pixelSize: Scaler.s(12)
                color: ThemeBackend.subtext0
            }
        }
    }
}
