/**
 * VILLEN Music Player - Audio Enhancements Module
 * Features: Equalizer, Crossfade, Audio Effects
 */

class AudioEnhancer {
    constructor(audioContext, sourceNode) {
        this.audioContext = audioContext;
        this.sourceNode = sourceNode;
        this.isEnabled = false;

        // Equalizer bands (Hz)
        this.eqBands = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];

        // Crossfade settings
        this.crossfadeDuration = 3; // seconds
        this.crossfadeEnabled = false;

        // Initialize nodes
        this.initializeEqualizer();
        this.initializeCrossfade();
    }

    initializeEqualizer() {
        // Create gain nodes for each frequency band
        this.eqFilters = {};
        this.eqGains = {};

        this.eqBands.forEach((freq, index) => {
            // Create biquad filter
            const filter = this.audioContext.createBiquadFilter();
            filter.type = 'peaking';
            filter.frequency.value = freq;
            filter.Q.value = 1; // Quality factor
            filter.gain.value = 0; // Initial gain (flat)

            // Create gain node for additional control
            const gainNode = this.audioContext.createGain();
            gainNode.gain.value = 1;

            this.eqFilters[freq] = filter;
            this.eqGains[freq] = gainNode;

            // Chain: source -> filter -> gain -> destination
            if (index === 0) {
                this.sourceNode.connect(filter);
            } else {
                this.eqGains[this.eqBands[index - 1]].connect(filter);
            }
            filter.connect(gainNode);
        });

        // Connect last gain to destination
        this.eqGains[this.eqBands[this.eqBands.length - 1]].connect(this.audioContext.destination);

        // Preset configurations
        this.presets = {
            flat: { name: 'Flat', gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] },
            rock: { name: 'Rock', gains: [2, 1, 0, -1, -1, 1, 2, 3, 3, 3] },
            pop: { name: 'Pop', gains: [-1, 0, 2, 3, 2, 0, -1, -1, 0, 1] },
            jazz: { name: 'Jazz', gains: [3, 2, 1, 2, -1, -1, 0, 2, 3, 4] },
            classical: { name: 'Classical', gains: [4, 3, 2, 1, 0, 0, -1, -1, -2, -3] },
            electronic: { name: 'Electronic', gains: [4, 2, 0, -2, -2, 0, 2, 4, 4, 2] },
            hiphop: { name: 'Hip Hop', gains: [3, 2, 1, 0, -1, -1, 0, 1, 2, 3] },
            vocal: { name: 'Vocal Boost', gains: [1, 1, 0, -2, -3, -2, 1, 2, 3, 4] },
            bass: { name: 'Bass Boost', gains: [4, 3, 2, 1, 0, 0, 0, 0, 0, 0] },
            treble: { name: 'Treble Boost', gains: [0, 0, 0, 0, 0, 0, 1, 2, 3, 4] }
        };

        this.currentPreset = 'flat';
    }

    initializeCrossfade() {
        // Crossfade uses gain nodes to smoothly transition between tracks
        this.crossfadeGain = this.audioContext.createGain();
        this.crossfadeGain.gain.value = 1;

        // Connect to the end of the equalizer chain
        this.eqGains[this.eqBands[this.eqBands.length - 1]].connect(this.crossfadeGain);
        this.crossfadeGain.connect(this.audioContext.destination);
    }

    // Equalizer Methods
    setEqBand(frequency, gain) {
        if (this.eqFilters[frequency]) {
            this.eqFilters[frequency].gain.value = Math.max(-20, Math.min(20, gain));
        }
    }

    getEqBand(frequency) {
        return this.eqFilters[frequency] ? this.eqFilters[frequency].gain.value : 0;
    }

    applyPreset(presetName) {
        if (this.presets[presetName]) {
            const preset = this.presets[presetName];
            this.eqBands.forEach((freq, index) => {
                this.setEqBand(freq, preset.gains[index]);
            });
            this.currentPreset = presetName;
            return preset;
        }
        return null;
    }

    resetEqualizer() {
        this.eqBands.forEach(freq => {
            this.setEqBand(freq, 0);
        });
        this.currentPreset = 'flat';
    }

    getCurrentPreset() {
        return this.currentPreset;
    }

    getPresets() {
        return Object.keys(this.presets).map(key => ({
            id: key,
            name: this.presets[key].name
        }));
    }

    // Crossfade Methods
    enableCrossfade(enabled = true) {
        this.crossfadeEnabled = enabled;
    }

    setCrossfadeDuration(duration) {
        this.crossfadeDuration = Math.max(0.5, Math.min(10, duration));
    }

    getCrossfadeDuration() {
        return this.crossfadeDuration;
    }

    // Crossfade between two audio sources
    async crossfadeToNext(currentSource, nextSource, onComplete) {
        if (!this.crossfadeEnabled) {
            if (onComplete) onComplete();
            return;
        }

        const duration = this.crossfadeDuration;

        // Fade out current
        const currentGain = this.audioContext.createGain();
        currentSource.connect(currentGain);
        currentGain.connect(this.crossfadeGain);

        currentGain.gain.setValueAtTime(1, this.audioContext.currentTime);
        currentGain.gain.linearRampToValueAtTime(0, this.audioContext.currentTime + duration);

        // Fade in next
        const nextGain = this.audioContext.createGain();
        nextSource.connect(nextGain);
        nextGain.connect(this.crossfadeGain);

        nextGain.gain.setValueAtTime(0, this.audioContext.currentTime);
        nextGain.gain.linearRampToValueAtTime(1, this.audioContext.currentTime + duration);

        // Clean up after crossfade
        setTimeout(() => {
            currentSource.disconnect();
            if (onComplete) onComplete();
        }, duration * 1000);
    }

    // Master enable/disable
    enable(enabled = true) {
        this.isEnabled = enabled;
        if (enabled) {
            // Ensure connections are active
            this.sourceNode.connect(this.eqFilters[this.eqBands[0]]);
        } else {
            // Disconnect from destination and connect directly
            this.sourceNode.disconnect();
            this.sourceNode.connect(this.audioContext.destination);
        }
    }

    // Cleanup
    dispose() {
        // Disconnect all nodes
        Object.values(this.eqFilters).forEach(filter => filter.disconnect());
        Object.values(this.eqGains).forEach(gain => gain.disconnect());
        this.crossfadeGain.disconnect();

        this.eqFilters = {};
        this.eqGains = {};
    }
}

// Audio Visualizer Enhancer
class AudioVisualizer {
    constructor(audioContext, sourceNode, canvas) {
        this.audioContext = audioContext;
        this.sourceNode = sourceNode;
        this.canvas = canvas;
        this.canvasContext = canvas.getContext('2d');
        this.animationId = null;
        this.isEnabled = false;

        // Analyzer settings
        this.analyzer = this.audioContext.createAnalyser();
        this.analyzer.fftSize = 256;
        this.bufferLength = this.analyzer.frequencyBinCount;
        this.dataArray = new Uint8Array(this.bufferLength);

        // Connect analyzer
        this.sourceNode.connect(this.analyzer);

        // Visual settings
        this.barCount = 64;
        this.sensitivity = 1.5;
        this.colorScheme = 'default';

        this.colorSchemes = {
            default: {
                background: '#0a0a0a',
                bars: ['#ff6b35', '#ff8f65', '#ffb088'],
                glow: 'rgba(255, 107, 53, 0.5)'
            },
            neon: {
                background: '#000011',
                bars: ['#00ffff', '#ff00ff', '#ffff00'],
                glow: 'rgba(0, 255, 255, 0.5)'
            },
            fire: {
                background: '#1a0a00',
                bars: ['#ff4500', '#ff6600', '#ff8800'],
                glow: 'rgba(255, 69, 0, 0.5)'
            },
            ocean: {
                background: '#001122',
                bars: ['#0066cc', '#0099ff', '#33ccff'],
                glow: 'rgba(0, 102, 204, 0.5)'
            }
        };
    }

    start() {
        if (this.isEnabled) return;

        this.isEnabled = true;
        this.animate();
    }

    stop() {
        this.isEnabled = false;
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
            this.animationId = null;
        }
        this.clearCanvas();
    }

    animate() {
        if (!this.isEnabled) return;

        this.animationId = requestAnimationFrame(() => this.animate());

        this.analyzer.getByteFrequencyData(this.dataArray);

        this.draw();
    }

    draw() {
        const { width, height } = this.canvas;
        const ctx = this.canvasContext;
        const scheme = this.colorSchemes[this.colorScheme];

        // Clear canvas
        ctx.fillStyle = scheme.background;
        ctx.fillRect(0, 0, width, height);

        // Calculate bar width
        const barWidth = width / this.barCount;
        let barHeight;
        let x = 0;

        // Draw bars
        for (let i = 0; i < this.barCount; i++) {
            // Get average of frequency bins for this bar
            const startBin = Math.floor(i * this.bufferLength / this.barCount);
            const endBin = Math.floor((i + 1) * this.bufferLength / this.barCount);
            let sum = 0;

            for (let j = startBin; j < endBin; j++) {
                sum += this.dataArray[j];
            }

            barHeight = (sum / (endBin - startBin)) * this.sensitivity;

            // Color based on height
            const colorIndex = Math.floor((barHeight / height) * scheme.bars.length);
            const color = scheme.bars[Math.min(colorIndex, scheme.bars.length - 1)];

            // Draw bar with gradient
            const gradient = ctx.createLinearGradient(0, height - barHeight, 0, height);
            gradient.addColorStop(0, color);
            gradient.addColorStop(1, scheme.background);

            ctx.fillStyle = gradient;
            ctx.fillRect(x, height - barHeight, barWidth - 2, barHeight);

            // Add glow effect
            ctx.shadowColor = scheme.glow;
            ctx.shadowBlur = 10;
            ctx.fillRect(x, height - barHeight, barWidth - 2, barHeight);
            ctx.shadowBlur = 0;

            x += barWidth;
        }
    }

    clearCanvas() {
        const ctx = this.canvasContext;
        ctx.fillStyle = this.colorSchemes[this.colorScheme].background;
        ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
    }

    setColorScheme(scheme) {
        if (this.colorSchemes[scheme]) {
            this.colorScheme = scheme;
        }
    }

    setSensitivity(value) {
        this.sensitivity = Math.max(0.1, Math.min(3, value));
    }

    setBarCount(count) {
        this.barCount = Math.max(16, Math.min(128, count));
    }

    getColorSchemes() {
        return Object.keys(this.colorSchemes);
    }

    dispose() {
        this.stop();
        this.analyzer.disconnect();
    }
}

// Export for use in main app
window.AudioEnhancer = AudioEnhancer;
window.AudioVisualizer = AudioVisualizer;