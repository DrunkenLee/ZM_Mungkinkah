# ZM_Ticket System Tutorial

## Overview
The **ZM_Ticket** system allows players to use special tickets for permanent mechanical boosts and car repairs. Each ticket can only be used once per player and the usage is tracked server-wide.

---

## Available Ticket Types

### 🔧 Permanent Mechanical Boost Ticket
- **Effect**: Gives permanent XP boost for Mechanics skill
- **Item ID**: `ZM_PermanentMechanicalBoostTicket`

### 🚗 Car Repair Ticket
- **Effect**: Allows instant car repair with cooldown reset
- **Item ID**: `ZM_CarRepairTicket`

---

## How to Use Tickets

### Step 1: Obtain a Ticket
1. Find or acquire either a `ZM_PermanentMechanicalBoostTicket` or `ZM_CarRepairTicket` item from boss drop and hardzone random lootcrate
2. Add it to your inventory

### Step 2: Use the Ticket
1. **Right-click** the ticket in your inventory
2. Select either:
   - 🔧 **"Use Mechanical Boost Ticket"** (for mechanical boost tickets)
   - 🚗 **"Use Car Repair Ticket"** (for car repair tickets)

### Step 3: System Processing
The system will automatically:
1. ✅ Check if you've already used this specific ticket
2. ❌ If already used: Display *"This ticket has already been used"*
3. ✅ If available: Process the ticket and apply the benefit

### Step 4: Ticket Effects

#### 🔧 For Mechanical Boost Tickets:
- ✅ Gives permanent XP boost for Mechanics skill
- 🔊 Plays success sound effect
- 💬 Shows confirmation message

#### 🚗 For Car Repair Tickets:
- ✅ Resets your car repair cooldown
- ✅ Allows immediate car repairs
- 🔊 Plays success sound effect
- 💬 Shows confirmation message

---

## Important Notes

| Feature | Description |
|---------|-------------|
| **One-time use** | Each ticket can only be used once per player |
| **Server tracking** | Usage is tracked across server restarts |
| **Instant effect** | Benefits apply immediately upon successful use |
| **Audio feedback** | Success sound confirms ticket activation |
| **Automatic removal** | Ticket is removed from inventory when used |

---

## Troubleshooting

### Common Issues:
- ❓ **Ticket doesn't work**: Check console for error messages
- ❓ **No context menu**: Ensure you're holding the correct ticket type
- ❓ **Not saving progress**: Server must be running for proper ticket validation
- ❓ **Sharing tickets**: Tickets are player-specific and cannot be shared

---

## Summary
The system provides a **secure, one-time-use mechanism** for special gameplay benefits with full server-side validation.

> 💡 **Tip**: Always check the console output for debugging information if tickets aren't working as expected.

