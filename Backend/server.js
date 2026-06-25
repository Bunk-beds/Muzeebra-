const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'muzeebra-super-secret-key-12345';

app.use(cors());
app.use(express.json());

const fs = require('fs');

// Initialize SQLite database
// Use /data/database.sqlite if the /data directory exists (common for persistent mounts on Render/Fly.io)
const dataDir = '/data';
const dbPath = fs.existsSync(dataDir) 
    ? path.join(dataDir, 'database.sqlite') 
    : path.join(__dirname, 'database.sqlite');

const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Failed to connect to database:', err.message);
    } else {
        console.log('Connected to SQLite database at:', dbPath);
        initializeDatabase();
    }
});

function initializeDatabase() {
    db.serialize(() => {
        // Users table
        db.run(`CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`);

        // Playback history table
        db.run(`CREATE TABLE IF NOT EXISTS playback_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            track_name TEXT NOT NULL,
            artist TEXT NOT NULL,
            album_name TEXT,
            spotify_uri TEXT,
            mode TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )`);
    });
}

// Auth Middleware
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid or expired token' });
        }
        req.user = user;
        next();
    });
}

// --- API ROUTES ---

// 1. Register User
app.post('/api/auth/register', (req, res) => {
    const { email, password } = req.body;
    if (!email || !password || email.trim() === '' || password.trim() === '') {
        return res.status(400).json({ error: 'Email and password are required' });
    }

    const hash = bcrypt.hashSync(password, 10);
    db.run(
        `INSERT INTO users (email, password_hash) VALUES (?, ?)`,
        [email.trim().toLowerCase(), hash],
        function(err) {
            if (err) {
                if (err.message.includes('UNIQUE constraint failed')) {
                    return res.status(409).json({ error: 'Email is already registered' });
                }
                return res.status(500).json({ error: 'Failed to create user: ' + err.message });
            }
            res.status(201).json({ success: true, message: 'User registered successfully' });
        }
    );
});

// 2. Login User
app.post('/api/auth/login', (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required' });
    }

    db.get(
        `SELECT * FROM users WHERE email = ?`,
        [email.trim().toLowerCase()],
        (err, user) => {
            if (err) {
                return res.status(500).json({ error: 'Database error: ' + err.message });
            }
            if (!user) {
                return res.status(401).json({ error: 'Invalid email or password' });
            }

            const validPassword = bcrypt.compareSync(password, user.password_hash);
            if (!validPassword) {
                return res.status(401).json({ error: 'Invalid email or password' });
            }

            const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '30d' });
            res.json({ token, email: user.email });
        }
    );
});

// 3. Post Playback History
app.post('/api/history', authenticateToken, (req, res) => {
    const { trackName, artist, albumName, spotifyUri, mode } = req.body;
    if (!trackName || !artist) {
        return res.status(400).json({ error: 'Track name and artist are required' });
    }

    db.run(
        `INSERT INTO playback_history (user_id, track_name, artist, album_name, spotify_uri, mode)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [req.user.id, trackName, artist, albumName || '', spotifyUri || '', mode || 'web'],
        function(err) {
            if (err) {
                return res.status(500).json({ error: 'Failed to log play: ' + err.message });
            }
            res.status(201).json({ success: true, playId: this.lastID });
        }
    );
});

// 4. Get Analytics Dashboard Data
app.get('/api/analytics', authenticateToken, (req, res) => {
    const userId = req.user.id;

    // We will run multiple queries in parallel and respond with a combined JSON payload
    const stats = {
        totalPlays: 0,
        topTracks: [],
        topArtists: [],
        modeDistribution: { local: 0, web: 0 }
    };

    // Query 1: Total plays
    db.get(
        `SELECT COUNT(*) as count FROM playback_history WHERE user_id = ?`,
        [userId],
        (err, row) => {
            if (err) return res.status(500).json({ error: err.message });
            stats.totalPlays = row.count || 0;

            // Query 2: Top Tracks
            db.all(
                `SELECT track_name as trackName, artist, COUNT(*) as playCount, spotify_uri as uri
                 FROM playback_history 
                 WHERE user_id = ? 
                 GROUP BY trackName, artist 
                 ORDER BY playCount DESC 
                 LIMIT 5`,
                [userId],
                (err, rows) => {
                    if (err) return res.status(500).json({ error: err.message });
                    stats.topTracks = rows;

                    // Query 3: Top Artists
                    db.all(
                        `SELECT artist, COUNT(*) as playCount 
                         FROM playback_history 
                         WHERE user_id = ? 
                         GROUP BY artist 
                         ORDER BY playCount DESC 
                         LIMIT 5`,
                        [userId],
                        (err, rows) => {
                            if (err) return res.status(500).json({ error: err.message });
                            stats.topArtists = rows;

                            // Query 4: Mode Distribution
                            db.all(
                                `SELECT mode, COUNT(*) as count 
                                 FROM playback_history 
                                 WHERE user_id = ? 
                                 GROUP BY mode`,
                                [userId],
                                (err, rows) => {
                                    if (err) return res.status(500).json({ error: err.message });
                                    rows.forEach(r => {
                                        if (r.mode === 'local') stats.modeDistribution.local = r.count;
                                        if (r.mode === 'web') stats.modeDistribution.web = r.count;
                                    });

                                    // Return combined stats
                                    res.json(stats);
                                }
                            );
                        }
                    );
                }
            );
        }
    );
});

// Start Server
app.listen(PORT, () => {
    console.log(`Muzeebra Analytics Server running on http://localhost:${PORT}`);
});
