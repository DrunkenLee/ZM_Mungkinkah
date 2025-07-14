# ZM Autoshop Tutorial - Vehicle Trading System

Welcome to the ZM Autoshop! This tutorial will guide you through how to use the vehicle trading system to sell your vehicles for points.

## What is ZM Autoshop?

ZM Autoshop is a vehicle trading system that allows you to sell specific vehicles at a designated location in exchange for points. The amount of points you receive depends on the vehicle's condition and the base price set by the server administrator.

## How It Works

### 1. Location Requirements

- You must bring your vehicle to the **Autoshop Endpoint Area**
- The default location coordinates are: **X: 11329-11334, Y: 8225-8232**
- Both you (the player) and your vehicle must be within this area to complete a sale

### 2. Acceptable Vehicles

The system only accepts specific vehicles that are configured by the server administrator. examples:
- admin will defines the vehicles type.
- server only buy spesific type of vehicle that defined by admins

**Note:** Only vehicles that match the exact script names in the server configuration will be accepted.

### 3. Vehicle Condition Assessment

When you attempt to sell a vehicle, the system will automatically assess its condition based on:

#### **Parts Condition (70% of final score)**
- Engine condition
- Tire condition
- Battery status
- All other vehicle parts
- Each part's condition is evaluated as a percentage

#### **Rust Factor (20% of final score)**
- Less rust = higher condition score
- Rust-free vehicles get maximum points in this category

#### **Impact Damage (10% of final score)**
- Vehicles with less collision damage score higher
- This includes damage from crashes and zombie impacts

### 4. Payment Calculation

Your payment is calculated using this formula:
```
Final Points = Base Vehicle Price × (Vehicle Condition ÷ 100)
```

**Example:**
- Base price for ambulance: 100,000 points
- Vehicle condition: 85%
- Payment: 100,000 × 0.85 = 85,000 points

## Step-by-Step Trading Process

### Step 1: Prepare Your Vehicle
1. **Drive your vehicle to the Autoshop area**
2. **Position both yourself and the vehicle within the endpoint zone**
3. **Make sure the vehicle is one of the accepted types**

### Step 2: Initiate the Sale
1. **Talk to Autoshop NPC to check and sell your vehicle
2. **The system will check if you're in the correct location**
3. **If not in the area, you'll receive a message telling you to move to the endpoint**

### Step 3: Vehicle Assessment
The system will automatically:
1. **Generate a detailed condition report**
2. **Calculate the final payment based on condition**
3. **Display the results to you**

You'll see information like:
- "Vehicle condition: 85%"
- "Vehicle sold! Base price: 100,000, Condition: 85%, Points awarded: 85,000"

### Step 4: Payment and Removal
1. **Points are automatically added to your account**
2. **A success sound will play**
3. **The vehicle will be processed for removal**
4. **You'll receive confirmation when the vehicle is completely removed**

## Condition Report Details

When selling a vehicle, you'll see a detailed report including:

### **Key Systems Status**
- **Engine:** Condition percentage and status (Good/Fair/Poor)
- **Battery:** Charge level percentage
- **Fuel:** Current fuel level and capacity

### **Tire Condition**
- Individual condition of each tire
- Status rating for each tire

### **Overall Summary**
- Base parts condition average
- Rust factor impact
- Impact damage factor
- Final calculated condition percentage

## Tips for Maximum Profit

### 🔧 **Maintain Your Vehicle**
- Keep the engine in good condition
- Replace worn tires
- Maintain battery charge
- Keep fuel levels reasonable

### 🛡️ **Avoid Damage**
- Drive carefully to minimize collision damage
- Avoid letting the vehicle get rusty
- Park safely away from zombies

### 💰 **Know Your Values**
- Check which vehicles have the highest base prices
- Focus on acquiring and maintaining high-value vehicles
- Remember that condition directly affects your payout

## Troubleshooting

### "You are not at the endpoint area"
- **Solution:** Move both yourself and your vehicle into the designated area
- Double-check the coordinates: X: 11329-11334, Y: 8225-8232

### "No matching vehicle found"
- **Solution:** Your vehicle type isn't configured for trading
- Check with server administrators for the list of acceptable vehicles

### "No price configured for this vehicle type"
- **Solution:** Contact server administrators - the vehicle may need price configuration

### "Vehicle condition too poor - no payment awarded"
- **Solution:** Repair your vehicle before attempting to sell it
- Focus on fixing the engine and major components first

## Server Administrator Notes

The autoshop system supports up to 10 different vehicle types, each with configurable base prices. Vehicle types and prices are set through sandbox options in the server configuration.

---

**Happy Trading!** 🚗💰

The ZM Autoshop provides a fair and transparent way to convert your vehicles into valuable points based on their actual condition. Take care of your vehicles, and they'll take care of your wallet!
