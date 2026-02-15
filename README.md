# **Hide & Seek: Wilderness Prototype**

## **Project Overview**

This is a mobile-first web game prototype. The goal is to find a "Friend" hidden on a 10x10 grid using compass hints before running out of turns.

## **Tech Stack**

* **Framework:** React (Single Component preferred for prototype speed).  
* **Styling:** Tailwind CSS.  
* **Platform:** Web (Responsive, optimized for iOS Safari touch targets).

## **Core Mechanics**

### **1\. The Grid**

* **Size:** 10x10.  
* **Terrain Generation:** Each tile has a visible "Terrain" type and a hidden "Content" type.  
  * **Visible Terrain:** Grass (Default), Trees, Rocks, Ponds (distributed randomly).  
  * **Hidden Content:**  
    * **1x Friend:** The Win Condition.  
    * **10x Coins:** Bonus items.  
    * **10x Traps:** Hazard items.  
    * **Remainder:** Empty.

### **2\. Turn System**

* **Starting Turns:** 15\.  
* **Game Over:** When Turns reach 0\.  
* **Interaction Costs:** Tapping a tile reveals Hidden Content:  
  * **Friend:** You WIN immediately.  
  * **Coin:** **\+1 Turn** added to total.  
  * **Trap:** **\-1 Turn** deducted from total.  
  * **Empty:** **\-2 Turns** deducted (Cost of searching a dead end).

### **3\. The Compass (HUD)**

* Displayed clearly at the top or bottom.  
* **Function:** Always points to the 8-way cardinal direction (N, NE, E, SE, S, SW, W, NW) best aligned with the Friend's location relative to the *last clicked tile* (or center if no clicks yet).

### **4\. Tuning / Settings**

* Provide a simple "Debug/Settings" collapsible menu to adjust:  
  * Starting Turns (Default: 15).  
  * Trap Count (Default: 10).  
  * Coin Count (Default: 10).

## **UI/UX Requirements**

* **Mobile First:** Grid must fit within the width of a phone screen. No horizontal scrolling.  
* **Visuals:** Use Emoji for all assets to keep the codebase lightweight.  
  * Tree: 🌲, Rock: 🪨, Pond: 💧, Friend: 🕵️‍♀️, Coin: 🪙, Trap: 🕸️, Compass: 🧭 (with rotating arrow or text).  
* **Feedback:** Show floating text or distinct color flashes when turns are gained/lost.

## **Implementation Plan (Cloud Agent)**

1. Setup state for Grid, Player Stats, and Game Status.  
2. Implement generateBoard() function with randomization.  
3. Implement handleTileClick() with the cost logic specified above.  
4. Implement getCompassDirection() logic.  
5. Render responsive Grid and HUD.
