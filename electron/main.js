const { app, BrowserWindow, Menu } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1320,
    height: 820,
    minWidth: 1000,
    minHeight: 650,
    backgroundColor: '#204A37',
    icon: path.join(__dirname, '..', 'resources', 'icon.png'),
    webPreferences: { nodeIntegration: false, contextIsolation: true, spellcheck: false }
  });
  Menu.setApplicationMenu(null);
  win.loadFile(path.join(__dirname, '..', 'www', 'index.html'));
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
