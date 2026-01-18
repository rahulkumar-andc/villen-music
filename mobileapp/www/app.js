/**
 * VILLEN Music Player - Premium Edition v2.0
 * Features: Audio playback, queue management, liked songs, keyboard shortcuts,
 * context menu, sleep timer, visualizer, recently played, and more!
 */

// const API_BASE = 'http://127.0.0.1:8000/api';
const API_BASE = "https://villen-music.onrender.com/api";
// ==================== STATE ====================
const state = {
    currentSong: null,
    queue: [],
    queueIndex: -1,
    liked: JSON.parse(localStorage.getItem('liked') || '[]'),
    recentlyPlayed: JSON.parse(localStorage.getItem('recentlyPlayed') || '[]'),
    searchHistory: JSON.parse(localStorage.getItem('searchHistory') || '[]'),
    isPlaying: false,
    volume: parseFloat(localStorage.getItem('volume') || '0.7'),
    shuffle: false,
    repeat: 'off', // off, all, one

    // Auth State
    user: JSON.parse(localStorage.getItem('user') || 'null'),
    // Auth State
    user: JSON.parse(localStorage.getItem('user') || 'null'),
    token: localStorage.getItem('token') || null,

    // Offline State
    offlineSongs: [],


    trendingIndex: 0,
    trending: [],
    sleepTimer: null,
    sleepTimerEnd: null,
    contextMenuSong: null,
    cache: {
        trending: null,
        trendingTime: 0,
    }
};

// Cache duration (5 minutes)
const CACHE_DURATION = 5 * 60 * 1000;

// ==================== AUDIO PLAYER ====================
const audio = new Audio();
audio.crossOrigin = 'anonymous'; // Enable CORS for mobile WebView
audio.volume = state.volume;

// Error handling for audio
audio.addEventListener('error', (e) => {
    console.error('Audio error:', e);
    const errorMessages = {
        1: 'Audio loading aborted',
        2: 'Network error',
        3: 'Audio decoding failed',
        4: 'Audio not supported'
    };
    const code = audio.error ? audio.error.code : 0;
    showToast(errorMessages[code] || 'Playback error - trying again...');
});

// Audio context for visualizer
let audioContext = null;
let analyser = null;
let visualizerAnimationId = null;

audio.addEventListener('timeupdate', updateProgress);
audio.addEventListener('ended', handleSongEnd);
audio.addEventListener('loadedmetadata', updateDuration);
audio.addEventListener('play', () => {
    state.isPlaying = true;
    updatePlayButton();
    updateMediaSession();
    startVisualizer();
});
audio.addEventListener('pause', () => {
    state.isPlaying = false;
    updatePlayButton();
    stopVisualizer();
});

// ==================== API FUNCTIONS WITH CACHING ====================
async function searchSongs(query) {
    if (!query.trim()) return [];

    try {
        const res = await fetch(`${API_BASE}/search/?q=${encodeURIComponent(query)}&limit=30`);
        const data = await res.json();
        return data.results || [];
    } catch (err) {
        console.error('Search failed:', err);
        showToast('Search failed. Please try again.');
        return [];
    }
}

async function getStreamUrl(songId, quality = '320') {
    try {
        const res = await fetch(`${API_BASE}/stream/${songId}/?quality=${quality}`);
        if (!res.ok) throw new Error('Stream not available');
        const data = await res.json();
        return data.url;
    } catch (err) {
        console.error('Stream fetch failed:', err);
        return null;
    }
}

async function getTrending() {
    // Check cache first
    if (state.cache.trending && (Date.now() - state.cache.trendingTime) < CACHE_DURATION) {
        return state.cache.trending;
    }

    try {
        const res = await fetch(`${API_BASE}/trending/`);
        const data = await res.json();
        const results = data.results || [];

        // Cache results
        state.cache.trending = results;
        state.cache.trendingTime = Date.now();

        return results;
    } catch (err) {
        console.error('Trending fetch failed:', err);
        return state.cache.trending || [];
    }
}

async function getRelated(songId) {
    try {
        const res = await fetch(`${API_BASE}/song/${songId}/related/`);
        const data = await res.json();
        return data.results || [];
    } catch (err) {
        console.error('Related fetch failed:', err);
        return [];
    }
}

async function getLyrics(songId) {
    try {
        const res = await fetch(`${API_BASE}/song/${songId}/lyrics/`);
        if (!res.ok) return null;
        const data = await res.json();
        return data.lyrics || null;
    } catch (err) {
        console.error('Lyrics fetch failed:', err);
        return null;
    }
}

// ==================== PLAYBACK ====================
async function playSong(song, addToQueue = true) {
    if (!song || !song.id) return;

    showToast(`Loading: ${song.title}`);

    const url = await getStreamUrl(song.id);
    if (!url) {
        showToast('Unable to play this song');
        return;
    }

    state.currentSong = song;
    addToRecentlyPlayed(song);

    if (addToQueue) {
        // Reset queue for new context (optional, but cleaner for "Play" from search)
        // If we want to append to existing queue, we keep it. 
        // But user complaint implies "starting a song" should start a radio.
        // Let's keep existing logic but append related.
        state.queue = state.queue.slice(0, state.queueIndex + 1);
        state.queue.push(song);
        state.queueIndex = state.queue.length - 1;
        updateQueueUI();

        // Auto-populate queue with related songs
        getRelated(song.id).then(related => {
            if (related && related.length > 0) {
                const existingIds = new Set(state.queue.map(s => s.id));
                const newSongs = related.filter(s => !existingIds.has(s.id));

                if (newSongs.length > 0) {
                    state.queue.push(...newSongs);
                    updateQueueUI();
                    updateNextSongsList();
                    // showToast(`Added ${newSongs.length} similar songs to queue`);
                }
            }
        });
    }

    audio.src = url;

    // Mobile-friendly play with error handling
    try {
        await audio.play();
        showToast(`Playing: ${song.title}`);
    } catch (err) {
        console.error('Play failed:', err);
        showToast('Tap play button to start');
    }

    updateNowPlaying();
    updateCurrentlyPlayingCard();
    updateNextSongsList();
    updateAlbumBackground(song);
    fetchAndDisplayLyrics(song.id);
}

function togglePlay() {
    if (!state.currentSong) return;

    if (state.isPlaying) {
        audio.pause();
    } else {
        audio.play();
    }
}

function playNext() {
    if (state.repeat === 'one') {
        audio.currentTime = 0;
        audio.play();
        return;
    }

    if (state.shuffle) {
        const randomIndex = Math.floor(Math.random() * state.queue.length);
        state.queueIndex = randomIndex;
    } else {
        state.queueIndex++;
    }

    if (state.queueIndex >= state.queue.length) {
        if (state.repeat === 'all') {
            state.queueIndex = 0;
        } else {
            state.isPlaying = false;
            updatePlayButton();
            return;
        }
    }

    playSong(state.queue[state.queueIndex], false);
}

function playPrevious() {
    if (audio.currentTime > 3) {
        audio.currentTime = 0;
        return;
    }

    state.queueIndex = Math.max(0, state.queueIndex - 1);
    playSong(state.queue[state.queueIndex], false);
}

function handleSongEnd() {
    playNext();
}

function seekTo(percent) {
    if (!audio.duration) return;
    audio.currentTime = (percent / 100) * audio.duration;
}

function setVolume(value) {
    state.volume = Math.max(0, Math.min(1, value));
    audio.volume = state.volume;
    localStorage.setItem('volume', state.volume.toString());
    updateVolumeUI();
}

function toggleShuffle() {
    state.shuffle = !state.shuffle;
    const btn = document.getElementById('shuffleBtn');
    btn.classList.toggle('active', state.shuffle);
    showToast(state.shuffle ? 'Shuffle: On' : 'Shuffle: Off');
}

function toggleRepeat() {
    const modes = ['off', 'all', 'one'];
    const currentIndex = modes.indexOf(state.repeat);
    state.repeat = modes[(currentIndex + 1) % modes.length];

    const btn = document.getElementById('repeatBtn');
    btn.classList.toggle('active', state.repeat !== 'off');

    const labels = { off: 'Repeat: Off', all: 'Repeat: All', one: 'Repeat: One' };
    showToast(labels[state.repeat]);
}

// ==================== RECENTLY PLAYED ====================
function addToRecentlyPlayed(song) {
    // Remove if already exists
    state.recentlyPlayed = state.recentlyPlayed.filter(s => s.id !== song.id);
    // Add to front
    state.recentlyPlayed.unshift(song);
    // Keep only last 20
    state.recentlyPlayed = state.recentlyPlayed.slice(0, 20);
    localStorage.setItem('recentlyPlayed', JSON.stringify(state.recentlyPlayed));
}

function clearRecentlyPlayed() {
    state.recentlyPlayed = [];
    localStorage.setItem('recentlyPlayed', JSON.stringify([]));
    renderRecentlyPlayed();
    showToast('Recently played cleared');
}

function renderRecentlyPlayed() {
    const container = document.getElementById('recentContainer');

    if (!state.recentlyPlayed.length) {
        container.innerHTML = `
            <div class="empty-state">
                <p>No recently played songs</p>
            </div>
        `;
        return;
    }

    container.innerHTML = `
        <div class="recently-played-scroll">
            ${state.recentlyPlayed.map(song => `
                <div class="recently-played-card" onclick="playSong(${JSON.stringify(song).replace(/"/g, '&quot;')})" oncontextmenu="showContextMenu(event, ${JSON.stringify(song).replace(/"/g, '&quot;')})">
                    <img class="recently-played-image" src="${song.image || ''}" alt="" loading="lazy" onerror="this.style.background='var(--bg-tertiary)'">
                    <div class="recently-played-title">${song.title}</div>
                    <div class="recently-played-artist">${song.artist}</div>
                </div>
            `).join('')}
        </div>
    `;
}

// ==================== QUEUE MANAGEMENT ====================
function addToQueue(song) {
    state.queue.push(song);
    updateQueueUI();
    updateNextSongsList();
    showToast(`Added to queue: ${song.title}`);
}

function playNextInQueue(song) {
    state.queue.splice(state.queueIndex + 1, 0, song);
    updateQueueUI();
    updateNextSongsList();
    showToast(`Playing next: ${song.title}`);
}

function removeFromQueue(index) {
    state.queue.splice(index, 1);
    if (index < state.queueIndex) {
        state.queueIndex--;
    }
    updateQueueUI();
    updateNextSongsList();
}

function clearQueue() {
    const current = state.currentSong;
    state.queue = current ? [current] : [];
    state.queueIndex = current ? 0 : -1;
    updateQueueUI();
    updateNextSongsList();
}

// ==================== LIKED SONGS ====================
function toggleLike(song) {
    const index = state.liked.findIndex(s => s.id === song.id);

    if (index > -1) {
        state.liked.splice(index, 1);
        showToast(`Removed from Liked Songs`);
    } else {
        state.liked.unshift(song);
        showToast(`Added to Liked Songs`);
    }

    localStorage.setItem('liked', JSON.stringify(state.liked));
    updateLikeButtons();
}

function isLiked(songId) {
    return state.liked.some(s => s.id === songId);
}

function playAllLiked() {
    if (state.liked.length === 0) {
        showToast('No liked songs to play');
        return;
    }
    state.queue = [...state.liked];
    state.queueIndex = 0;
    playSong(state.queue[0], false);
    updateQueueUI();
    showToast('Playing all liked songs');
}

// ==================== SEARCH ====================
let searchTimeout;

function handleSearch(query) {
    clearTimeout(searchTimeout);

    if (!query.trim()) {
        showSection('home');
        return;
    }

    searchTimeout = setTimeout(async () => {
        document.getElementById('resultsContainer').innerHTML = renderSkeletonGrid(8);
        showSection('search');

        const results = await searchSongs(query);
        renderSearchResults(results);

        if (query.length > 2) {
            state.searchHistory = [query, ...state.searchHistory.filter(q => q !== query)].slice(0, 10);
            localStorage.setItem('searchHistory', JSON.stringify(state.searchHistory));
        }
    }, 300);
}

// ==================== SKELETON LOADERS ====================
function renderSkeletonGrid(count) {
    return `
        <div class="songs-grid">
            ${Array(count).fill('').map(() => `
                <div class="skeleton-card">
                    <div class="skeleton skeleton-image"></div>
                    <div class="skeleton skeleton-title"></div>
                    <div class="skeleton skeleton-text"></div>
                </div>
            `).join('')}
        </div>
    `;
}

function renderSkeletonArtists(count) {
    return `
        <div class="artists-grid">
            ${Array(count).fill('').map(() => `
                <div class="artist-card">
                    <div class="skeleton skeleton-circle" style="width: 110px; height: 110px;"></div>
                    <div class="skeleton skeleton-text" style="width: 80px; margin-top: 12px;"></div>
                </div>
            `).join('')}
        </div>
    `;
}

// ==================== ALBUM BACKGROUND ====================
function updateAlbumBackground(song) {
    const bg = document.getElementById('albumBackground');
    if (song && song.image) {
        bg.style.backgroundImage = `url(${song.image})`;
    } else {
        bg.style.backgroundImage = '';
    }
}

// ==================== VISUALIZER ====================
function initVisualizer() {
    if (!audioContext) {
        audioContext = new (window.AudioContext || window.webkitAudioContext)();
        const source = audioContext.createMediaElementSource(audio);
        analyser = audioContext.createAnalyser();
        analyser.fftSize = 64;
        source.connect(analyser);
        analyser.connect(audioContext.destination);
    }
}

function startVisualizer() {
    const visualizer = document.getElementById('visualizer');
    if (!visualizer) return;

    try {
        initVisualizer();
        visualizer.style.display = 'flex';

        const bars = visualizer.querySelectorAll('.visualizer-bar');
        const bufferLength = analyser.frequencyBinCount;
        const dataArray = new Uint8Array(bufferLength);

        function animate() {
            visualizerAnimationId = requestAnimationFrame(animate);
            analyser.getByteFrequencyData(dataArray);

            bars.forEach((bar, i) => {
                const value = dataArray[i * 2] || 0;
                const height = Math.max(4, (value / 255) * 40);
                bar.style.height = `${height}px`;
            });
        }

        animate();
    } catch (e) {
        console.log('Visualizer not supported');
    }
}

function stopVisualizer() {
    if (visualizerAnimationId) {
        cancelAnimationFrame(visualizerAnimationId);
        visualizerAnimationId = null;
    }

    const visualizer = document.getElementById('visualizer');
    if (visualizer) {
        const bars = visualizer.querySelectorAll('.visualizer-bar');
        bars.forEach(bar => bar.style.height = '4px');
    }
}

// ==================== LYRICS ====================
async function fetchAndDisplayLyrics(songId) {
    const lyricsSection = document.getElementById('lyricsSection');
    const lyricsPanel = document.getElementById('lyricsPanel');

    lyricsPanel.innerHTML = '<p class="lyrics-line">Loading lyrics...</p>';
    lyricsSection.style.display = 'block';

    const lyrics = await getLyrics(songId);

    if (lyrics) {
        const lines = lyrics.split('\n').filter(l => l.trim());
        lyricsPanel.innerHTML = lines.map((line, i) =>
            `<p class="lyrics-line" data-index="${i}">${line}</p>`
        ).join('');
    } else {
        lyricsPanel.innerHTML = '<p class="lyrics-line" style="color: var(--text-muted);">Lyrics not available</p>';
    }
}

// ==================== SLEEP TIMER ====================
function showTimerModal() {
    document.getElementById('timerModal').classList.add('show');
    updateTimerStatus();
}

function hideTimerModal() {
    document.getElementById('timerModal').classList.remove('show');
}

function closeTimerModal(event) {
    if (event.target === event.currentTarget) {
        hideTimerModal();
    }
}

function setSleepTimer(minutes) {
    // Clear existing timer
    if (state.sleepTimer) {
        clearTimeout(state.sleepTimer);
        state.sleepTimer = null;
        state.sleepTimerEnd = null;
    }

    if (minutes === 0) {
        showToast('Sleep timer turned off');
        hideTimerModal();
        updateTimerStatus();
        return;
    }

    const ms = minutes * 60 * 1000;
    state.sleepTimerEnd = Date.now() + ms;

    state.sleepTimer = setTimeout(() => {
        audio.pause();
        showToast('Sleep timer: Playback stopped');
        state.sleepTimer = null;
        state.sleepTimerEnd = null;
    }, ms);

    showToast(`Sleep timer: ${minutes} minutes`);
    hideTimerModal();
    updateTimerStatus();
}

function updateTimerStatus() {
    const status = document.getElementById('timerStatus');
    if (state.sleepTimerEnd) {
        const remaining = Math.max(0, state.sleepTimerEnd - Date.now());
        const mins = Math.ceil(remaining / 60000);
        status.textContent = `Timer active: ${mins} minute${mins !== 1 ? 's' : ''} remaining`;
    } else {
        status.textContent = 'No timer set';
    }
}

// ==================== CONTEXT MENU ====================
function showContextMenu(event, song) {
    event.preventDefault();
    event.stopPropagation();

    state.contextMenuSong = song;
    const menu = document.getElementById('contextMenu');

    // Update like text
    const likeText = document.getElementById('contextLikeText');
    likeText.textContent = isLiked(song.id) ? 'Remove from Liked' : 'Add to Liked';

    // Position menu
    let x = event.clientX;
    let y = event.clientY;

    // Ensure menu stays in viewport
    const menuWidth = 180;
    const menuHeight = 240;

    if (x + menuWidth > window.innerWidth) {
        x = window.innerWidth - menuWidth - 10;
    }
    if (y + menuHeight > window.innerHeight) {
        y = window.innerHeight - menuHeight - 10;
    }

    menu.style.left = `${x}px`;
    menu.style.top = `${y}px`;
    menu.classList.add('show');

    // Close on click outside
    document.addEventListener('click', hideContextMenu);
}

function hideContextMenu() {
    document.getElementById('contextMenu').classList.remove('show');
    document.removeEventListener('click', hideContextMenu);
}

function contextMenuAction(action) {
    const song = state.contextMenuSong;
    if (!song) return;

    switch (action) {
        case 'play':
            playSong(song);
            break;
        case 'playNext':
            playNextInQueue(song);
            break;
        case 'addQueue':
            addToQueue(song);
            break;
        case 'like':
            toggleLike(song);
            break;
        case 'artist':
            handleSearch(song.artist);
            document.getElementById('searchInput').value = song.artist;
            break;
    }

    hideContextMenu();
}

// ==================== KEYBOARD SHORTCUTS MODAL ====================
function showShortcutsModal() {
    document.getElementById('shortcutsModal').classList.add('show');
}

function hideShortcutsModal() {
    document.getElementById('shortcutsModal').classList.remove('show');
}

function closeShortcutsModal(event) {
    if (event.target === event.currentTarget) {
        hideShortcutsModal();
    }
}

// ==================== MEDIA SESSION API ====================
function updateMediaSession() {
    if (!('mediaSession' in navigator)) return;

    const song = state.currentSong;
    if (!song) return;

    navigator.mediaSession.metadata = new MediaMetadata({
        title: song.title || 'Unknown',
        artist: song.artist || 'Unknown Artist',
        album: song.album || '',
        artwork: song.image ? [{ src: song.image, sizes: '512x512', type: 'image/jpeg' }] : []
    });

    navigator.mediaSession.setActionHandler('play', () => audio.play());
    navigator.mediaSession.setActionHandler('pause', () => audio.pause());
    navigator.mediaSession.setActionHandler('previoustrack', playPrevious);
    navigator.mediaSession.setActionHandler('nexttrack', playNext);
    navigator.mediaSession.setActionHandler('seekto', (details) => {
        audio.currentTime = details.seekTime;
    });
}

// ==================== UI UPDATES ====================
function updateNowPlaying() {
    const container = document.getElementById('nowPlaying');
    const song = state.currentSong;

    if (!song) {
        container.innerHTML = '';
        return;
    }

    const liked = isLiked(song.id);

    container.innerHTML = `
    <img class="thumb" src="${song.image || ''}" alt="" onerror="this.style.display='none'">
    <div class="info">
      <div class="title">${song.title || 'Unknown'}</div>
      <div class="artist">${song.artist || 'Unknown Artist'}</div>
    </div>
    <button class="like-btn ${liked ? 'liked' : ''}" onclick="toggleLike(state.currentSong)">
      ${liked ? svgIcons.heartFilled : svgIcons.heart}
    </button>
  `;

    document.title = `${song.title} - VILLEN`;
}

function updateCurrentlyPlayingCard() {
    const song = state.currentSong;
    const imgEl = document.getElementById('nowPlayingImage');
    const detailsEl = document.getElementById('nowPlayingDetails');
    const visualizer = document.getElementById('visualizer');

    if (!song) {
        imgEl.style.display = 'none';
        visualizer.style.display = 'none';
        detailsEl.innerHTML = '<p style="color: var(--text-muted); font-size: 13px;">No song playing</p>';
        return;
    }

    imgEl.src = song.image || '';
    imgEl.style.display = song.image ? 'block' : 'none';

    detailsEl.innerHTML = `
        <div class="now-playing-title">${song.title || 'Unknown'}</div>
        <div class="now-playing-artist">${song.artist || 'Unknown Artist'}</div>
        <div class="now-playing-meta">${song.album || ''} ${song.year ? '• ' + song.year : ''}</div>
        <button class="control-btn" style="margin-top: 10px; font-size: 12px; padding: 5px 10px;" onclick="downloadSong(state.currentSong)">
            ⬇ Download
        </button>
    `;
}

function updateNextSongsList() {
    const container = document.getElementById('nextSongsList');
    const nextSongs = state.queue.slice(state.queueIndex + 1, state.queueIndex + 5);

    if (!nextSongs.length) {
        container.innerHTML = `
            <div class="empty-state">
                <p>Queue is empty</p>
            </div>
        `;
        return;
    }

    container.innerHTML = nextSongs.map((song, i) => `
        <div class="next-song-item" onclick="playFromQueue(${state.queueIndex + 1 + i})" oncontextmenu="showContextMenu(event, ${JSON.stringify(song).replace(/"/g, '&quot;')})">
            <img class="next-song-thumb" src="${song.image || ''}" alt="" loading="lazy" onerror="this.style.background='var(--bg-tertiary)'">
            <div class="next-song-info">
                <div class="next-song-title">${song.title}</div>
                <div class="next-song-artist">${song.artist}</div>
            </div>
            <span class="next-song-duration">${formatTime(song.duration)}</span>
        </div>
    `).join('');

    // Efficient DOM update
    container.innerHTML = html;
}

function updatePlayButton() {
    const btn = document.getElementById('playPauseBtn');
    if (btn) {
        btn.innerHTML = state.isPlaying ? svgIcons.pause : svgIcons.play;
    }
}

function updateProgress() {
    const fill = document.getElementById('progressFill');
    const currentTime = document.getElementById('currentTime');

    if (audio.duration) {
        const percent = (audio.currentTime / audio.duration) * 100;
        fill.style.width = `${percent}%`;
        currentTime.textContent = formatTime(audio.currentTime);
    }
}

function updateDuration() {
    const duration = document.getElementById('duration');
    duration.textContent = formatTime(audio.duration);
}

function updateVolumeUI() {
    const fill = document.getElementById('volumeFill');
    const btn = document.getElementById('volumeBtn');

    fill.style.width = `${state.volume * 100}%`;

    if (state.volume === 0) {
        btn.innerHTML = svgIcons.volumeMute;
    } else if (state.volume < 0.5) {
        btn.innerHTML = svgIcons.volumeLow;
    } else {
        btn.innerHTML = svgIcons.volumeHigh;
    }
}

function updateLikeButtons() {
    document.querySelectorAll('.like-btn').forEach(btn => {
        const songId = btn.dataset.songId;
        if (songId) {
            const liked = isLiked(songId);
            btn.classList.toggle('liked', liked);
            btn.innerHTML = liked ? svgIcons.heartFilled : svgIcons.heart;
        }
    });

    updateNowPlaying();
}

function updateQueueUI() {
    const container = document.getElementById('queueList');

    if (!state.queue.length) {
        container.innerHTML = `
      <div class="empty-state">
        ${svgIcons.queue}
        <p>Queue is empty</p>
      </div>
    `;
        return;
    }

    container.innerHTML = state.queue.map((song, i) => `
    <div class="song-row ${i === state.queueIndex ? 'playing' : ''}" onclick="playFromQueue(${i})" oncontextmenu="showContextMenu(event, ${JSON.stringify(song).replace(/"/g, '&quot;')})">
      <span class="index">${i + 1}</span>
      <img class="thumb" src="${song.image || ''}" alt="" loading="lazy" onerror="this.style.background='var(--bg-tertiary)'">
      <div class="info">
        <div class="title">${song.title}</div>
        <div class="artist">${song.artist}</div>
      </div>
      <span class="duration">${formatTime(song.duration)}</span>
      <button class="like-btn" onclick="event.stopPropagation(); removeFromQueue(${i})">✕</button>
    </div>
  `).join('');
}

function playFromQueue(index) {
    state.queueIndex = index;
    playSong(state.queue[index], false);
}

// ==================== RENDERING ====================
function renderSearchResults(songs) {
    const container = document.getElementById('resultsContainer');

    if (!songs.length) {
        container.innerHTML = `
      <div class="empty-state">
        ${svgIcons.search}
        <p>No songs found</p>
      </div>
    `;
        return;
    }

    container.innerHTML = renderSongList(songs);
}

function renderTrendingHero(songs) {
    if (!songs.length) return '';

    const song = songs[state.trendingIndex % songs.length];

    return `
        <div class="trending-hero" onclick="playSong(${JSON.stringify(song).replace(/"/g, '&quot;')})" oncontextmenu="showContextMenu(event, ${JSON.stringify(song).replace(/"/g, '&quot;')})">
            <img class="trending-hero-bg" src="${song.image || ''}" alt="">
            <div class="trending-hero-overlay"></div>
            <div class="trending-hero-content">
                <div class="trending-hero-title">${song.title}</div>
                <div class="trending-hero-artist">${song.artist} • ${song.plays || '63M'} Plays</div>
            </div>
            <div class="trending-hero-actions">
                <button class="hero-like-btn" onclick="event.stopPropagation(); toggleLike(${JSON.stringify(song).replace(/"/g, '&quot;')})">
                    ${isLiked(song.id) ? svgIcons.heartFilled : svgIcons.heart}
                </button>
                <button class="hero-nav-btn" onclick="event.stopPropagation(); changeTrendingHero(-1)">
                    <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z"/></svg>
                </button>
                <button class="hero-nav-btn" onclick="event.stopPropagation(); changeTrendingHero(1)">
                    <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z"/></svg>
                </button>
            </div>
        </div>
    `;
}

function changeTrendingHero(direction) {
    state.trendingIndex = (state.trendingIndex + direction + state.trending.length) % state.trending.length;
    renderHome();
}

function renderArtistsCircles(songs) {
    const artistMap = new Map();
    songs.forEach(song => {
        if (song.artist && !artistMap.has(song.artist)) {
            artistMap.set(song.artist, {
                name: song.artist,
                image: song.image,
                plays: song.plays || Math.floor(Math.random() * 100) + 'M Plays'
            });
        }
    });

    const artists = Array.from(artistMap.values()).slice(0, 6);

    if (!artists.length) return '';

    return `
        <div class="section">
            <div class="section-header">
                <h2 class="section-title">
                    <span class="emoji">👤</span> Top Artists
                </h2>
                <span class="see-all" onclick="showSection('artists')">View All</span>
            </div>
            <div class="artists-grid">
                ${artists.map(artist => `
                    <div class="artist-card" onclick="handleSearch('${artist.name.replace(/'/g, "\\'")}')">
                        <img class="artist-image" src="${artist.image || ''}" alt="${artist.name}" onerror="this.style.background='var(--bg-tertiary)'">
                        <div class="artist-name">${artist.name}</div>
                        <div class="artist-plays">${artist.plays}</div>
                    </div>
                `).join('')}
            </div>
        </div>
    `;
}

function renderRecentlyPlayedSection() {
    if (!state.recentlyPlayed.length) return '';

    return `
        <div class="section">
            <div class="section-header">
                <h2 class="section-title">🕐 Recently Played</h2>
                <span class="see-all" onclick="showSection('recent')">View All</span>
            </div>
            <div class="recently-played-scroll">
                ${state.recentlyPlayed.slice(0, 8).map(song => `
                    <div class="recently-played-card" onclick="playSong(${JSON.stringify(song).replace(/"/g, '&quot;')})" oncontextmenu="showContextMenu(event, ${JSON.stringify(song).replace(/"/g, '&quot;')})">
                        <img class="recently-played-image" src="${song.image || ''}" alt="" onerror="this.style.background='var(--bg-tertiary)'">
                        <div class="recently-played-title">${song.title}</div>
                        <div class="recently-played-artist">${song.artist}</div>
                    </div>
                `).join('')}
            </div>
        </div>
    `;
}

function renderSongGrid(songs, title = '') {
    if (!songs.length) return '';

    return `
    <div class="section">
      ${title ? `<div class="section-header"><h2 class="section-title">${title}</h2><span class="see-all">View All</span></div>` : ''}
      <div class="songs-grid">
        ${songs.slice(0, 8).map(song => `
          <div class="song-card" onclick="playSong(${JSON.stringify(song).replace(/"/g, '&quot;')})" oncontextmenu="showContextMenu(event, ${JSON.stringify(song).replace(/"/g, '&quot;')})">
            <img class="song-image" src="${song.image || ''}" alt="" onerror="this.style.background='var(--bg-tertiary)'">
            <button class="play-btn" onclick="event.stopPropagation(); playSong(${JSON.stringify(song).replace(/"/g, '&quot;')})">${svgIcons.play}</button>
            <div class="song-title">${song.title}</div>
            <div class="song-artist">${song.artist}</div>
            <button class="control-btn" style="position:absolute; top:10px; right:10px; background:rgba(0,0,0,0.5); border-radius:50%; width:30px; height:30px; display:flex; align-items:center; justify-content:center; border:none; color:white; opacity:0; transition:opacity 0.2s;"
                    onclick="event.stopPropagation(); downloadSong(${JSON.stringify(song).replace(/"/g, '&quot;')})"
                    onmouseover="this.parentElement.querySelector('.control-btn').style.opacity=1">
               ⬇
            </button>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

function renderSongList(songs) {
    return `
    <div class="songs-list">
      ${songs.map((song, i) => `
        <div class="song-row" onclick="playSong(${JSON.stringify(song).replace(/"/g, '&quot;')})" oncontextmenu="showContextMenu(event, ${JSON.stringify(song).replace(/"/g, '&quot;')})">
          <span class="index">${i + 1}</span>
          <img class="thumb" src="${song.image || ''}" alt="" onerror="this.style.display='none'">
          <div class="info">
            <div class="title">${song.title}</div>
            <div class="artist">${song.artist}</div>
          </div>
          <span class="duration">${formatTime(song.duration)}</span>
          <div class="actions">
            <button class="like-btn ${isLiked(song.id) ? 'liked' : ''}" 
                    data-song-id="${song.id}"
                    onclick="event.stopPropagation(); toggleLike(${JSON.stringify(song).replace(/"/g, '&quot;')})">
              ${isLiked(song.id) ? svgIcons.heartFilled : svgIcons.heart}
            </button>
            <button class="control-btn" style="background:transparent; border:none; color:var(--text-muted);"
                    onclick="event.stopPropagation(); downloadSong(${JSON.stringify(song).replace(/"/g, '&quot;')})"
                    title="Download">
               ⬇
            </button>
          </div>
        </div>
      `).join('')}
    </div>
  `;
}

// ==================== NAVIGATION ====================
function showSection(section) {
    const sections = ['home', 'search', 'liked', 'artists', 'albums', 'recent'];
    sections.forEach(s => {
        const el = document.getElementById(`${s}Section`);
        if (el) el.style.display = s === section ? 'block' : 'none';
    });

    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.toggle('active', item.dataset.section === section);
    });

    if (section === 'liked') {
        renderLikedSongs();
    }
    if (section === 'artists') {
        renderArtistsSection();
    }
    if (section === 'recent') {
        renderRecentlyPlayed();
    }
}

function renderLikedSongs() {
    const container = document.getElementById('likedContainer');

    if (!state.liked.length) {
        container.innerHTML = `
      <div class="empty-state">
        ${svgIcons.heartFilled}
        <p>No liked songs yet</p>
      </div>
    `;
        return;
    }

    container.innerHTML = renderSongList(state.liked);
}

function renderArtistsSection() {
    const container = document.getElementById('artistsContainer');

    if (!state.trending.length) {
        container.innerHTML = '<div class="empty-state"><p>No artists to display</p></div>';
        return;
    }

    const artistMap = new Map();
    state.trending.forEach(song => {
        if (song.artist && !artistMap.has(song.artist)) {
            artistMap.set(song.artist, {
                name: song.artist,
                image: song.image,
                plays: Math.floor(Math.random() * 200) + 'M Plays'
            });
        }
    });

    const artists = Array.from(artistMap.values());

    container.innerHTML = artists.map(artist => `
        <div class="artist-card" onclick="handleSearch('${artist.name.replace(/'/g, "\\'")}')">
            <img class="artist-image" src="${artist.image || ''}" alt="${artist.name}" onerror="this.style.background='var(--bg-tertiary)'">
            <div class="artist-name">${artist.name}</div>
            <div class="artist-plays">${artist.plays}</div>
        </div>
    `).join('');
}

function toggleQueue() {
    const panel = document.getElementById('queuePanel');
    const btn = document.getElementById('queueToggle');
    panel.classList.toggle('open');
    btn.classList.toggle('active');
}

// ==================== KEYBOARD SHORTCUTS ====================
document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') {
        if (e.key === 'Escape') {
            e.target.blur();
        }
        return;
    }

    switch (e.code) {
        case 'Space':
            e.preventDefault();
            togglePlay();
            break;
        case 'ArrowRight':
            if (e.shiftKey) playNext();
            else audio.currentTime = Math.min(audio.duration, audio.currentTime + 10);
            break;
        case 'ArrowLeft':
            if (e.shiftKey) playPrevious();
            else audio.currentTime = Math.max(0, audio.currentTime - 10);
            break;
        case 'ArrowUp':
            e.preventDefault();
            setVolume(state.volume + 0.1);
            break;
        case 'ArrowDown':
            e.preventDefault();
            setVolume(state.volume - 0.1);
            break;
        case 'KeyM':
            setVolume(state.volume > 0 ? 0 : 0.7);
            break;
        case 'KeyL':
            if (state.currentSong) toggleLike(state.currentSong);
            break;
        case 'KeyQ':
            toggleQueue();
            break;
        case 'KeyS':
            toggleShuffle();
            break;
        case 'KeyR':
            toggleRepeat();
            break;
        case 'Slash':
            e.preventDefault();
            document.getElementById('searchInput').focus();
            break;
        case 'Escape':
            hideContextMenu();
            hideShortcutsModal();
            hideTimerModal();
            break;
    }

    // ? key for shortcuts
    if (e.key === '?') {
        showShortcutsModal();
    }
});

// ==================== PROGRESS BAR INTERACTION ====================
function initProgressBar() {
    const bar = document.getElementById('progressBar');
    let isDragging = false;

    bar.addEventListener('mousedown', (e) => {
        isDragging = true;
        updateSeek(e);
    });

    document.addEventListener('mousemove', (e) => {
        if (isDragging) updateSeek(e);
    });

    document.addEventListener('mouseup', () => {
        isDragging = false;
    });

    function updateSeek(e) {
        const rect = bar.getBoundingClientRect();
        const percent = Math.max(0, Math.min(100, ((e.clientX - rect.left) / rect.width) * 100));
        seekTo(percent);
    }
}

function initVolumeSlider() {
    const slider = document.getElementById('volumeSlider');
    let isDragging = false;

    slider.addEventListener('mousedown', (e) => {
        isDragging = true;
        updateVolume(e);
    });

    document.addEventListener('mousemove', (e) => {
        if (isDragging) updateVolume(e);
    });

    document.addEventListener('mouseup', () => {
        isDragging = false;
    });

    function updateVolume(e) {
        const rect = slider.getBoundingClientRect();
        const value = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
        setVolume(value);
    }
}

// ==================== UTILITIES ====================
function formatTime(seconds) {
    if (!seconds || isNaN(seconds)) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
}

function showToast(message) {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.classList.add('show');

    setTimeout(() => {
        toast.classList.remove('show');
    }, 2500);
}

// ==================== SVG ICONS ====================
const svgIcons = {
    play: '<svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z" fill="currentColor"/></svg>',
    pause: '<svg viewBox="0 0 24 24"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z" fill="currentColor"/></svg>',
    skipNext: '<svg viewBox="0 0 24 24"><path d="M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z" fill="currentColor"/></svg>',
    skipPrev: '<svg viewBox="0 0 24 24"><path d="M6 6h2v12H6zm3.5 6l8.5 6V6z" fill="currentColor"/></svg>',
    shuffle: '<svg viewBox="0 0 24 24"><path d="M10.59 9.17L5.41 4 4 5.41l5.17 5.17 1.42-1.41zM14.5 4l2.04 2.04L4 18.59 5.41 20 17.96 7.46 20 9.5V4h-5.5zm.33 9.41l-1.41 1.41 3.13 3.13L14.5 20H20v-5.5l-2.04 2.04-3.13-3.13z" fill="currentColor"/></svg>',
    repeat: '<svg viewBox="0 0 24 24"><path d="M7 7h10v3l4-4-4-4v3H5v6h2V7zm10 10H7v-3l-4 4 4 4v-3h12v-6h-2v4z" fill="currentColor"/></svg>',
    heart: '<svg viewBox="0 0 24 24"><path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z" fill="currentColor"/></svg>',
    heartFilled: '<svg viewBox="0 0 24 24"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" fill="currentColor"/></svg>',
    volumeHigh: '<svg viewBox="0 0 24 24"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z" fill="currentColor"/></svg>',
    volumeLow: '<svg viewBox="0 0 24 24"><path d="M18.5 12c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM5 9v6h4l5 5V4L9 9H5z" fill="currentColor"/></svg>',
    volumeMute: '<svg viewBox="0 0 24 24"><path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z" fill="currentColor"/></svg>',
    search: '<svg viewBox="0 0 24 24"><path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z" fill="currentColor"/></svg>',
    home: '<svg viewBox="0 0 24 24"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z" fill="currentColor"/></svg>',
    queue: '<svg viewBox="0 0 24 24"><path d="M15 6H3v2h12V6zm0 4H3v2h12v-2zM3 16h8v-2H3v2zM17 6v8.18c-.31-.11-.65-.18-1-.18-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3V8h3V6h-5z" fill="currentColor"/></svg>',
    close: '<svg viewBox="0 0 24 24"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z" fill="currentColor"/></svg>',
};

// ==================== RENDER HOME ====================
function renderHome() {
    const homeSection = document.getElementById('homeSection');
    const songs = state.trending;

    if (!songs.length) {
        homeSection.innerHTML = `
            <div class="section">
                <h2 class="section-title">Welcome to VILLEN</h2>
                <p style="color: var(--text-secondary); margin-top: 8px;">Search for songs to get started</p>
            </div>
        `;
        return;
    }

    homeSection.innerHTML = `
        <div class="section">
            <div class="section-header">
                <h2 class="section-title">
                    <span class="emoji">🔥</span> Trending
                </h2>
                <span class="see-all">View All</span>
            </div>
            ${renderTrendingHero(songs)}
        </div>
        ${renderRecentlyPlayedSection()}
        ${renderArtistsCircles(songs)}
        ${renderSongGrid(songs.slice(4), '🎵 Popular Songs')}
    `;
}

// ==================== INITIALIZATION ====================
async function init() {
    initProgressBar();
    initVolumeSlider();
    updateVolumeUI();
    updateQueueUI();
    updateNextSongsList();

    showSection('home');

    // Show skeleton loaders
    document.getElementById('homeSection').innerHTML = `
        <div class="section">
            <div class="section-header">
                <h2 class="section-title">🔥 Trending</h2>
            </div>
            <div class="skeleton" style="width: 100%; height: 240px; border-radius: 20px; margin-bottom: 24px;"></div>
        </div>
        <div class="section">
            <div class="section-header">
                <h2 class="section-title">👤 Top Artists</h2>
            </div>
            ${renderSkeletonArtists(6)}
        </div>
        <div class="section">
            <div class="section-header">
                <h2 class="section-title">🎵 Popular Songs</h2>
            </div>
            ${renderSkeletonGrid(8)}
        </div>
    `;

    // Load trending
    const trending = await getTrending();
    state.trending = trending;

    renderHome();
}

// Start app
document.addEventListener('DOMContentLoaded', () => {
    init();
    initTheme();
});

// ==================== AUTHENTICATION ====================
let isLoginMode = true;

function toggleAuthModal() {
    if (state.user) {
        if (confirm("Logout from " + state.user.username + "?")) {
            logout();
        }
    } else {
        document.getElementById('authModal').style.display = 'flex';
        setTimeout(() => document.getElementById('authModal').classList.add('visible'), 10);
    }
}

function closeAuthModal(event) {
    if (event.target === document.getElementById('authModal')) {
        document.getElementById('authModal').classList.remove('visible');
        setTimeout(() => document.getElementById('authModal').style.display = 'none', 300);
    }
}

function switchAuthMode() {
    isLoginMode = !isLoginMode;
    const title = document.getElementById('authTitle');
    const emailInfo = document.getElementById('authEmail');
    const btn = document.getElementById('authSubmitBtn');
    const switchTxt = document.getElementById('authSwitch');

    if (isLoginMode) {
        title.innerText = 'Login';
        emailInfo.style.display = 'none';
        btn.innerText = 'Login';
        switchTxt.innerText = "Don't have an account? Register";
    } else {
        title.innerText = 'Register';
        emailInfo.style.display = 'block';
        btn.innerText = 'Register';
        switchTxt.innerText = "Already have an account? Login";
    }
}

async function handleAuthSubmit(e) {
    e.preventDefault();
    const username = document.getElementById('authUsername').value;
    const password = document.getElementById('authPassword').value;
    const email = document.getElementById('authEmail').value;
    const msg = document.getElementById('authMessage');

    try {
        msg.innerText = "Processing...";

        let success = false;
        if (isLoginMode) {
            success = await login(username, password);
        } else {
            success = await register(username, email, password);
        }

        if (success) {
            msg.innerText = "Success! Closing...";
            setTimeout(() => {
                document.getElementById('authModal').classList.remove('visible');
                document.getElementById('authModal').style.display = 'none';
                updateAuthUI();
            }, 1000);
        }
    } catch (error) {
        msg.innerText = error.message || "Error occurred";
    }
}

async function login(username, password) {
    const res = await fetch(`${API_BASE}/auth/login/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.detail || "Login failed");

    localStorage.setItem('token', data.access);
    localStorage.setItem('refresh_token', data.refresh);
    state.token = data.access;

    state.user = { username };
    localStorage.setItem('user', JSON.stringify(state.user));

    showToast(`Welcome back, ${username}!`);
    await syncLikes();
    return true;
}

async function register(username, email, password) {
    const res = await fetch(`${API_BASE}/auth/register/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, email, password })
    });

    const data = await res.json();
    if (!res.ok) throw new Error(JSON.stringify(data) || "Registration failed");

    return await login(username, password);
}

function logout() {
    state.user = null;
    state.token = null;
    localStorage.removeItem('user');
    localStorage.removeItem('token');
    localStorage.removeItem('refresh_token');

    updateAuthUI();
    showToast("Logged out");
}

function updateAuthUI() {
    const btn = document.getElementById('authNavBtn');
    const txt = document.getElementById('authBtnText');

    if (state.user) {
        txt.innerText = state.user.username;
        btn.classList.add('active');
    } else {
        txt.innerText = "Login";
        btn.classList.remove('active');
    }
}

// ==================== SYNC LOGIC ====================
async function syncLikes() {
    if (!state.user || !state.token) return;

    try {
        showToast("Syncing library...");

        const res = await fetch(`${API_BASE}/user/likes/`, {
            headers: { 'Authorization': `Bearer ${state.token}` }
        });
        if (!res.ok) return;

        const cloudLikes = await res.json();

        const cloudIds = new Set(cloudLikes.map(l => l.song_id));
        const localOnly = state.liked.filter(s => !cloudIds.has(s.id));

        for (const song of localOnly) {
            await fetch(`${API_BASE}/user/likes/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${state.token}`
                },
                body: JSON.stringify({
                    song_id: song.id,
                    title: song.title,
                    artist: song.artist,
                    image: song.image,
                    duration: song.duration
                })
            });
        }

        const merged = [...cloudLikes.map(l => ({
            id: l.song_id,
            title: l.title,
            artist: l.artist,
            image: l.image,
            duration: l.duration
        })), ...localOnly];

        const seen = new Set();
        const uniqueMerged = [];
        for (const s of merged) {
            if (!seen.has(s.id)) {
                seen.add(s.id);
                uniqueMerged.push(s);
            }
        }

        state.liked = uniqueMerged;
        localStorage.setItem('liked', JSON.stringify(state.liked));
        updateLikeButtons();

        showToast("Library synced!");

    } catch (e) {
        console.error("Sync failed", e);
    }
}

const originalToggleLike = toggleLike;
toggleLike = async function (song) {
    if (!song) return;

    const index = state.liked.findIndex(s => s.id === song.id);
    if (index > -1) {
        state.liked.splice(index, 1);
        showToast(`Removed from Liked Songs`);
    } else {
        state.liked.unshift(song);
        showToast(`Added to Liked Songs`);
    }
    localStorage.setItem('liked', JSON.stringify(state.liked));
    updateLikeButtons();

    if (state.user && state.token) {
        const isLikedNow = state.liked.some(s => s.id === song.id);
        if (isLikedNow) {
            fetch(`${API_BASE}/user/likes/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${state.token}`
                },
                body: JSON.stringify({
                    song_id: song.id,
                    title: song.title,
                    artist: song.artist,
                    image: song.image,
                    duration: song.duration
                })
            });
        } else {
            fetch(`${API_BASE}/user/likes/`, {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${state.token}`
                },
                body: JSON.stringify({ song_id: song.id })
            });
        }
    }
}

// ==================== THEMES ====================
function showThemesModal() {
    document.getElementById('themesModal').classList.add('show');
}

function closeThemesModal(event) {
    if (event.target === document.getElementById('themesModal')) {
        document.getElementById('themesModal').classList.remove('show');
    }
}

function setTheme(themeName) {
    const body = document.body;
    // Remove all theme classes
    body.classList.remove('theme-ocean', 'theme-crimson', 'theme-emerald', 'theme-gold');

    // Add new theme class if not default
    if (themeName !== 'default') {
        body.classList.add(themeName);
    }

    // Save to local storage
    localStorage.setItem('theme', themeName);
    showToast(`Theme set to ${themeName.replace('theme-', '').toUpperCase() || 'Default'}`);

    document.getElementById('themesModal').classList.remove('show');
}

function initTheme() {
    const savedTheme = localStorage.getItem('theme') || 'default';
    setTheme(savedTheme);
}

// ==================== OFFLINE MODE (Mobile) ====================
// Note: Download feature is not available on mobile - use streaming instead
async function downloadSong(song) {
    showToast('Downloads not available on mobile. Stream songs instead!');
}

async function loadOfflineSongs() {
    // On mobile, we don't support offline downloads yet
    state.offlineSongs = [];
    renderOfflineSongs();
}

function renderOfflineSongs() {
    const container = document.getElementById('offlineContainer');
    if (!container) return;

    container.innerHTML = `
        <div class="empty-state">
            <p>📱 Offline downloads not available on mobile</p>
            <p style="font-size: 12px; color: var(--text-muted); margin-top: 8px;">
                Stream songs using your internet connection
            </p>
        </div>
    `;
}

// Init Offline
loadOfflineSongs();

