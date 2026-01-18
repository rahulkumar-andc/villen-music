const { app, BrowserWindow, dialog } = require("electron");
const { autoUpdater } = require("electron-updater");

// 1. Update ke logs dekhne ke liye (optional)
autoUpdater.logger = require("electron-log");
autoUpdater.logger.transports.file.level = "info";

function createWindow() {
  const win = new BrowserWindow({
    width: 1000,
    height: 700,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  win.loadFile("index.html");

  // 2. Window banne ke baad update check karo
  win.once('ready-to-show', () => {
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

app.whenReady().then(createWindow);