# 🎮 Apocalypse Tycoon

A Roblox tycoon game with wave-based survival mechanics. Build your base, defend against meteor waves, and survive the apocalypse!

---

## 🚀 Quick Start

### For Developers
1. Open the project in **Roblox Studio**
2. Ensure you have **Rojo** installed for syncing (optional but recommended)
3. Press **Play** to test locally

### For Players
- Join the game on Roblox (link TBD)
- Build generators to earn money
- Defend your base from meteor waves
- Upgrade your defenses and survive!

---

## 🏗️ Architecture

This project uses a **hybrid architecture** as we migrate from legacy to Knit framework:

### **Legacy System (Original)**
- `Main.Server.lua` - Monolithic server entry point (2,405 LOC)
- `EconomyModule.lua` - Currency, purchases, prestige system
- `BaseModule.lua` - Base HP, damage, shields
- `EventManager.lua` - Wave system, meteor spawning
- `PowerUpModule.lua` - Power-up mechanics

### **Knit System (New - Gradual Migration)**
- `BaseSpawnerService` - Archimedes spiral base spawning ✅
- `BasePlacementService` - Grid snapping, collision detection ✅
- `BaseOwnershipService` - Multi-level permissions ✅
- `BaseDataService` - DataStore persistence ✅
- `UpgradeService` - Generators, turrets, repair stations ✅
- `PlayerDataService` - Wrapper for legacy economy (temporary)

**Migration Strategy:** New features are built in Knit. Legacy systems will be migrated gradually to avoid disrupting development velocity.

---

## 🎮 Game Systems

### **Core Loop**
1. **Spawn Base** - Players get a personal base on join (Archimedes spiral algorithm)
2. **Build Generators** - Earn money passively (Tier 1 → 2 → 3)
3. **Defend** - Waves of meteors attack your base (escalating difficulty)
4. **Upgrade** - Place turrets, repair stations, and other defenses
5. **Survive** - Boss waves every 5/10 waves with increased rewards

### **Economy**
- **Generators**: T1 ($5/s), T2 ($15/s), T3 ($50/s)
- **Prestige System**: Reset for permanent income bonuses
- **Offline Earnings**: Earn money while offline (capped)
- **Daily Rewards**: 7-day login streak with increasing rewards

### **Combat**
- **Base HP**: 150 HP with regeneration
- **Shields**: Temporary damage absorption
- **Turrets**: Automatic defenses (targeting, damage, cooldown)
- **Power-Ups**: Speed, Shield, Damage, SuperDash, Invincibility

### **Placement System**
- **Grid Snapping**: 5x5 stud grid for organized bases
- **Collision Detection**: AABB (Axis-Aligned Bounding Box) algorithm
- **Zone Validation**: Only build within your base zone
- **Permissions**: Owner/Team/Public access levels

---

## 🧪 Testing & Debug Commands

### **In-Game Chat Commands**
```
/testbase           - Spawn a test base
/clearobjects       - Clear all objects from your base
/baseinfo           - Show detailed base information
/meteors [count]    - Spawn meteors for testing
/givecash [player] [amount] - Give money to a player
```

### **Studio Hotkeys**
- **H Key**: Show debug help menu (in Studio only)

### **Manual Testing**
See testing documentation in:
- `TESTING_GENERATOR_INTEGRATION.md`
- `GENERATOR_PHASE2_TESTING.md`
- `GENERATOR_PHASE3_TESTING.md`
- `GENERATOR_PHASE4_TESTING.md`

---

## 📁 Project Structure

```
Apocalypse-Tycoon/
├── src/
│   ├── ServerScriptService/
│   │   ├── Main.Server.lua           # Legacy entry point
│   │   ├── EconomyModule.lua         # Economy (legacy)
│   │   ├── BaseModule.lua            # Base HP system (legacy)
│   │   ├── EventManager.lua          # Wave system (legacy)
│   │   ├── PowerUpModule.lua         # Power-ups (legacy)
│   │   └── Services/                 # Knit Services (new)
│   ├── ServerStorage/
│   │   ├── Config/                   # Game balance configuration
│   │   └── Managers/                 # VFX, environment, utilities
│   ├── StarterPlayer/StarterPlayerScripts/
│   │   ├── KnitControllers/          # Client-side Knit controllers
│   │   └── Controllers/              # Legacy client controllers
│   ├── StarterGui/                   # UI components
│   └── ReplicatedStorage/
│       └── Knit/                     # Knit framework
├── Documentation/
│   ├── BASE_SYSTEM_DOCUMENTATION.md  # Comprehensive technical docs
│   ├── KNIT_MIGRATION_STATUS.md      # Migration progress tracker
│   └── TESTING_*.md                  # Testing guides
└── README.md                         # This file
```

---

## 📚 Documentation

### **For Developers**
- **[BASE_SYSTEM_DOCUMENTATION.md](BASE_SYSTEM_DOCUMENTATION.md)** - Complete technical reference (785 lines)
  - Architecture diagrams
  - Algorithm explanations (Archimedes spiral, AABB collision)
  - Integration patterns
  - Testing procedures

- **[KNIT_MIGRATION_STATUS.md](KNIT_MIGRATION_STATUS.md)** - Migration roadmap and status

### **For Testing**
- **[TESTING_GENERATOR_INTEGRATION.md](TESTING_GENERATOR_INTEGRATION.md)** - Generator system testing
- **[GENERATOR_PHASE*_TESTING.md](GENERATOR_PHASE2_TESTING.md)** - Phase-by-phase testing guides

---

## 🔧 Configuration

### **Game Balance** (`src/ServerStorage/Config/Config.lua`)
- Difficulty scaling
- Economy rates
- Base HP/regeneration
- Power-up probabilities

### **Upgrade Definitions** (`src/ServerStorage/Config/Upgrades.lua`)
- Generator tiers and costs
- Turret stats
- Repair station costs

---

## 🛠️ Development Team

- **2 AI Assistants** (Claude instances)
- **1 Human Developer** (project lead)

**Development Philosophy:**
- Gameplay first, visuals later
- Iterative development with frequent testing
- Hybrid architecture during migration
- Documentation-driven development

---

## 🎯 Current Phase: Phase 5 - Turret System

**Status:** In Development

**Recent Fixes:**
- ✅ Generator StatsBillboard preservation after upgrade (cd6314d)
- ✅ AddMoney validation fixes (07fcdfb)
- ✅ ProximityPrompt for upgrades (6c8b218)

**Next Up:**
- 🔫 Complete turret testing with meteors
- 🎨 Add turret VFX (laser beams, impact effects)
- 📊 Implement stats dashboard

---

## 🐛 Known Issues

- None currently (last batch of critical bugs fixed in Phase 4)

---

## 📝 Contributing

This is a private project currently. If you're collaborating:
1. Always create a new branch with `claude/` prefix
2. Test thoroughly before merging
3. Update documentation for new features
4. Use descriptive commit messages

---

## 📄 License

Private project - All rights reserved

---

## 🙏 Credits

- **Knit Framework** by Sleitnick (simplified version included)
- **Roblox Studio** for development environment
- **Claude AI** for development assistance

---

**Last Updated:** 2025-11-21
**Version:** Phase 5 (Turret System)
**Game Status:** In Active Development
