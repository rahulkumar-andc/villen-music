# VILLEN Music - Update Release Guide

## 🔄 Quick Update Process

### Step 1: Update Version Number
Edit `package.json` and change the version:
```json
"version": "1.0.1"  // Change from 1.0.0 to 1.0.1
```

### Step 2: Make Your Code Changes
- Edit files as needed (`app.js`, `index.html`, `styles.css`, etc.)
- Test locally with `npm start`

### Step 3: Build New Releases

**Linux Only:**
```bash
cd frontend
npm run build:linux
```

**Windows (using Docker):**
```bash
cd frontend
sudo docker run --rm -v $(pwd):/project -v $(pwd)/dist:/project/dist \
  electronuserland/builder:wine \
  /bin/bash -c "cd /project && npm install && npm run build:win"
```

**Both Platforms:**
```bash
# Linux first
npm run build:linux

# Then Windows via Docker
sudo docker run --rm -v $(pwd):/project -v $(pwd)/dist:/project/dist \
  electronuserland/builder:wine \
  /bin/bash -c "cd /project && npm install && npm run build:win"
```

### Step 4: Check Output Files
```bash
ls -lah dist/
```

You should see:
- `VILLEN Music-X.X.X.AppImage` (Linux)
- `villen-music_X.X.X_amd64.deb` (Linux)
- `VILLEN Music X.X.X.exe` (Windows)

---

## 📝 Version Numbering Guide

| Change Type | Example | When to Use |
|-------------|---------|-------------|
| **Major** (1.0.0 → 2.0.0) | Complete redesign | Big UI changes, breaking changes |
| **Minor** (1.0.0 → 1.1.0) | New feature | Added lyrics, new playlist feature |
| **Patch** (1.0.0 → 1.0.1) | Bug fix | Fixed playback issue, small fixes |

---

## 🚀 GitHub Release (Optional)

### Push to GitHub:
```bash
git add .
git commit -m "Release v1.0.1 - Description of changes"
git tag v1.0.1
git push origin main --tags
```

### Create GitHub Release:
1. Go to GitHub → Releases → "Create new release"
2. Select tag `v1.0.1`
3. Upload these files:
   - `dist/VILLEN Music-1.0.1.AppImage`
   - `dist/villen-music_1.0.1_amd64.deb`
   - `dist/VILLEN Music 1.0.1.exe`
4. Write changelog and publish

---

## 🔧 Troubleshooting

### Windows build fails?
```bash
# Re-pull Docker image
sudo docker pull electronuserland/builder:wine

# Clear cache and rebuild
rm -rf dist/win-*
sudo docker run --rm -v $(pwd):/project -v $(pwd)/dist:/project/dist \
  electronuserland/builder:wine \
  /bin/bash -c "cd /project && rm -rf node_modules && npm install && npm run build:win"
```

### Linux build fails?
```bash
rm -rf dist/linux-* dist/*.AppImage dist/*.deb
npm run build:linux
```

---

## 📋 Checklist Before Release

- [ ] Version updated in `package.json`
- [ ] Tested locally with `npm start`
- [ ] Linux build successful
- [ ] Windows build successful
- [ ] All files present in `dist/`
- [ ] (Optional) Pushed to GitHub with tag
