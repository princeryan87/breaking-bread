# Breaking Bread - Godot 4 Project

A mobile-friendly game about running a bakery from an RV while avoiding the police.

## Project Structure

```
breaking-bread/
├── project.godot          # Project settings (Compatibility renderer)
├── export_presets.cfg     # Web & Android export presets
├── .github/workflows/ci.yml  # GitHub Actions CI/CD
├── scenes/
│   └── main.tscn          # Main scene
├── scripts/
│   ├── rv_controller.gd   # RV driving mechanics
│   ├── kitchen.gd         # Baking system
│   ├── ui_manager.gd      # UI panels & HUD
│   ├── location_manager.gd # Location system
│   ├── customer_spawner.gd # Customer AI
│   ├── police.gd          # Police patrols & heat system
│   └── world_map.gd       # World map navigation
├── autoload/
│   └── game_manager.gd    # Singleton game state
└── assets/
    └── icon.png           # App icon (placeholder)
```

## Quick Start

### 1. Push to GitHub
```bash
cd breaking-bread
git init
git add .
git commit -m "Initial Godot project + CI"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/breaking-bread.git
git push -u origin main
```

### 2. Enable GitHub Pages
Go to your repo Settings → Pages → Source: "GitHub Actions"

### 3. Watch the Build
- Push to `main` triggers the workflow
- Web build deploys to `https://YOUR_USERNAME.github.io/breaking-bread/`
- APK downloads from Actions artifacts

## Game Mechanics

- **Drive RV** → WASD/Arrows to move on map
- **Visit Locations** → Suburbs, Downtown, Park, Market, Industrial, Supplier, Mechanic
- **Bake Goods** → Bread, Cookies, Cakes, Brownies, Fruit Tarts
- **Sell** → Match customer preferences for bonus prices
- **Manage Heat** → High heat = more police patrols
- **Upgrades** → Better oven, Fridge, Solar panel, Bigger tank, Stealth paint

## Controls

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | WASD / Arrows | Left Stick |
| Interact | Space / Enter | A Button |
| Pause | Escape | Start |

## Development

### Local Testing (if Godot runs)
```bash
godot --path .
```

### Export Manually
```bash
# Web
godot --headless --export-release "Web" export/web/index.html

# Android
godot --headless --export-release "Android" export/android/breaking-bread.apk
```

## Assets

Replace placeholder assets in `assets/` with:
- Kenney.nl "Tiny Town" or "Road Textures"
- Quaternius.com low-poly food models
- Custom pixel art for baked goods

## License

MIT License - Feel free to use for learning or commercial projects.