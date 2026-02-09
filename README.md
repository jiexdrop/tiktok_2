# 🎮 Viral TikTok Combat Game - Godot 4.6

## 🎯 Overview
A super satisfying, modular combat game perfect for TikTok! Two different fighter types battle it out in an arena with juicy animations and sound effects.

## 🎨 Features
- **Two Fighter Types:**
  - **RED (Melee)**: Charges and rams enemies with knockback
  - **BLUE (Ranged)**: Keeps distance and shoots projectiles

- **Satisfying Mechanics:**
  - Screen shake on death
  - Squash & stretch animations
  - Health bars
  - Knockback physics
  - Collision-based damage
  - Victory announcements

- **Modular Design:**
  - Separate fighter scenes (easy to swap types)
  - Base Fighter class for creating new types
  - Contained arena with wall collisions

## 🎵 Sound Effects to Add

Search for these sounds on **Freesound.org** or **Pixabay**:

### 1. HitSound (On each fighter)
**Search terms:** "punch impact", "hit thud", "body hit"
- Short, punchy impact sound (0.1-0.3s)
- Recommended: Medium-pitched thud or punch

### 2. AttackSound (On each fighter)
**For Melee Fighter:**
- **Search terms:** "whoosh", "sword swing", "swipe"
- Fast whoosh sound for charge attack

**For Ranged Fighter:**
- **Search terms:** "laser shoot", "pew", "projectile fire"
- Quick sci-fi shooting sound

### 3. DeathSound (On each fighter)
**Search terms:** "explosion small", "defeat", "knockout"
- Dramatic but short explosion or impact
- Duration: 0.5-1.0s

### 4. ImpactSound (On Projectile)
**Search terms:** "ping", "ricochet", "bullet hit"
- High-pitched metallic impact
- Very short (0.05-0.15s)

### 5. VictorySound (On Main scene)
**Search terms:** "victory fanfare", "success jingle", "win sound"
- Triumphant, upbeat sound
- Duration: 1-2s

## 📁 File Structure
```
project.godot           # Main project file
main.tscn              # Main game scene
main.gd                # Game manager script
arena.gd               # Arena boundary script

fighter.gd             # Base fighter class
melee_fighter.gd       # Melee fighter behavior
melee_fighter.tscn     # Melee fighter scene (RED)

ranged_fighter.gd      # Ranged fighter behavior
ranged_fighter.tscn    # Ranged fighter scene (BLUE)

projectile.gd          # Projectile behavior
projectile.tscn        # Projectile scene
```

## 🎮 How to Use

1. **Import to Godot 4.6**
   - Copy all files to your project folder
   - Open project.godot in Godot

2. **Add Sound Effects**
   - Download sounds from Freesound.org or Pixabay
   - Import as .wav or .ogg files
   - Drag sounds onto the AudioStreamPlayer nodes in the scenes

3. **Customize Fighters**
   - Open melee_fighter.tscn or ranged_fighter.tscn
   - Adjust exported variables in Inspector:
	 - `fighter_color`: Visual color
	 - `max_health`: Starting health
	 - `move_speed`: Movement force
	 - `attack_damage`: Damage per hit
	 - `attack_cooldown`: Time between attacks
	 - `knockback_force`: Hit pushback strength

4. **Create New Fighter Types**
   - Duplicate a fighter scene
   - Create new script extending Fighter class
   - Override `perform_attack()` function
   - Add unique behavior!

## 🔧 Easy Modifications

### Change Fighter Matchup
In `main.tscn`:
- Replace Fighter1 or Fighter2 instance with different fighter type
- Both can be melee, both ranged, or mixed!

### Adjust Arena Size
In `main.tscn`, select Arena node:
- Modify collision shapes to change arena boundaries
- Update Background ColorRect to match

### Add More Fighters
1. Create new script extending Fighter
2. Implement custom `perform_attack()` logic
3. Create scene with new script
4. Add satisfying animations!

## 🎬 TikTok Recording Tips
- Screen resolution is 9:16 (540x960) - perfect for TikTok!
- Record in fullscreen mode
- Capture multiple rounds for variety
- Add dramatic music over the sound effects
- Use slow-mo on death moments

## 💡 Future Enhancement Ideas
- Spinning fighter that bounces around
- Healer fighter that regenerates
- Tank fighter with high HP, slow movement
- Teleporting fighter
- Area-of-effect attacks
- Power-ups that spawn randomly
- Round counter with multiple wins needed
- Particle effects on hit/death

## 🎪 Example Fighter Ideas

### Spinning Fighter
- Constant rotation
- Damages on contact
- High knockback resistance

### Tank Fighter
- 200+ HP
- Slow movement
- High damage but long cooldown

### Assassin Fighter
- Low HP
- Very fast
- High damage, quick attacks

Enjoy creating viral content! 🎉
