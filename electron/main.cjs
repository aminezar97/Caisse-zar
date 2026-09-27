const { app, BrowserWindow, Menu } = require("electron");
const path = require("path");

const APP_ID = "com.zarouali.caisse";

app.setAppUserModelId(APP_ID);

function createWindow() {
  const win = new BrowserWindow({
    title: "Zarouali POS",
    width: 1400,
    height: 900,
    minWidth: 1000,
    minHeight: 650,

    // Windows POS: start directly in full-screen mode.
    fullscreen: true,
    fullscreenable: true,
    resizable: false,
    maximizable: false,
    minimizable: false,

    backgroundColor: "#F1EDE1",
    autoHideMenuBar: true,
    icon: path.join(__dirname, "..", "resources", "icon.png"),

    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true
    }
  });

  win.loadFile(path.join(__dirname, "..", "www", "index.html"));

  Menu.setApplicationMenu(null);
}

app.whenReady().then(() => {
  createWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});
