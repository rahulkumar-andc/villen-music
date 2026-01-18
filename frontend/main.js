const { app, BrowserWindow, dialog, ipcMain } = require("electron");
const fs = require('fs');
const path = require('path');
const https = require('https');
const { autoUpdater } = require("electron-updater");

// 1. Update ke logs dekhne ke liye (optional)
autoUpdater.logger = require("electron-log");
autoUpdater.logger.transports.file.level = "info";

let mainWindow;

// Disable sandbox on Linux to avoid crash
if (process.platform === 'linux') {
  app.commandLine.appendSwitch('no-sandbox');
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1000,
    height: 700,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false // Security risk in prod, but needed for 'fs' usage in renderer or simple IPC
    }
  });

  mainWindow.loadFile("index.html");

  // Open DevTools for debugging (remove in production)
  mainWindow.webContents.openDevTools();

  // 2. Window banne ke baad update check karo
  mainWindow.once('ready-to-show', () => {
    autoUpdater.checkForUpdatesAndNotify();
  });
}

// 3. Agar update mil gaya aur download ho gaya
autoUpdater.on('update-downloaded', () => {
  dialog.showMessageBox({
    type: 'info',
    title: 'Update Available',
    message: 'Naya version download ho gaya hai. Abhi restart karein?',
    buttons: ['Yes', 'No']
  }).then((result) => {
    if (result.response === 0) { // Agar user ne 'Yes' dabaya
      autoUpdater.quitAndInstall();
    }
  });
});

// ==================== OFF-LINE DOWNLOADS ====================
// Default download path: User's Music/Villen folder
const DOWNLOAD_DIR = path.join(app.getPath('music'), 'Villen');

if (!fs.existsSync(DOWNLOAD_DIR)) {
  fs.mkdirSync(DOWNLOAD_DIR, { recursive: true });
}

ipcMain.handle('download-song', async (event, { url, filename }) => {
  return new Promise((resolve, reject) => {
    const filePath = path.join(DOWNLOAD_DIR, filename);
    const file = fs.createWriteStream(filePath);

    https.get(url, (response) => {
      if (response.statusCode !== 200) {
        return reject('Download failed: ' + response.statusCode);
      }

      response.pipe(file);

      file.on('finish', () => {
        file.close(() => resolve(filePath));
      });
    }).on('error', (err) => {
      fs.unlink(filePath, () => { }); // Delete partial file
      reject(err.message);
    });
  });
});

ipcMain.handle('get-offline-songs', async () => {
  try {
    const files = fs.readdirSync(DOWNLOAD_DIR);
    // Filter mp3s and return details. 
    // We'll trust filename format "Artist - Title.mp3" for now or just return filenames
    return files
      .filter(f => f.endsWith('.mp3'))
      .map(f => ({
        path: path.join(DOWNLOAD_DIR, f),
        filename: f
      }));
  } catch (e) {
    return [];
  }
});

app.whenReady().then(createWindow);