# Powah Uraninite Reactor Monitor - Design Document

## Overview

This document describes a CC:Tweaked Lua program for monitoring and controlling a Powah mod Uraninite Reactor.  The program displays reactor status on an attached monitor and provides automatic shutdown protection when resources are low.

---

## Hardware Configuration

### Physical Layout
```
        [Monitor - 3 wide x 4 tall]
              [Modem] (front)
[Reactor] [Computer] [Flux Plug] (ignored)
        [Ender Modem] (bottom)
```

### Peripherals
| Peripheral | Location | Wrap Method |
|------------|----------|-------------|
| Uraninite Reactor | top | `peripheral.wrap("top")` |
| Monitor (3x4 blocks) | via modem | `peripheral.wrap("monitor_0")` |
| Wired Modem | front | Network access to monitor |
| Ender Modem | bottom | Telemetry to central display |

### Monitor Specifications
| Property | Value |
|----------|-------|
| Physical Size | 3 wide × 4 tall blocks |
| Character Size (scale 1. 0) | 29 × 26 characters |
| Color | Advanced (full color support) |

---

## Reactor Peripheral API

### Peripheral Type
`uraninite_reactor`

### Available Methods

#### Energy Methods
| Method | Returns | Description |
|--------|---------|-------------|
| `getEnergy()` | number | Same as stored energy (generic method) |
| `getStoredEnergy()` | number | Current energy stored in reactor buffer (FE) |
| `getMaxEnergy()` | number | Maximum energy storage capacity (FE) |
| `getEnergyCapacity()` | number | Same as getMaxEnergy() |

**Note:** There is no direct method to get current FE/t generation.  Net energy output must be calculated by measuring change in `getStoredEnergy()` over time.

#### Status Methods
| Method | Returns | Description |
|--------|---------|-------------|
| `isRunning()` | boolean | Whether reactor is actively running |
| `getTemperature()` | number | Temperature value (0-100 range, multiply by 10 for °C display) |

#### Internal Buffer Methods
| Method | Returns | Description |
|--------|---------|-------------|
| `getFuel()` | number | Uraninite buffer level as percentage (0-100) |
| `getCarbon()` | number | Carbon buffer level as percentage (0-100) |
| `getRedstone()` | number | Redstone buffer level as percentage (0-100) |

**Note:** These represent internal "liquified" buffers converted from solid items, not the slot contents. 

#### Inventory Methods
| Method | Returns | Description |
|--------|---------|-------------|
| `size()` | number | Inventory size (5 slots) |
| `list()` | table | Contents of all slots with name and count |
| `getItemDetail(slot)` | table | Detailed item info for specific slot |
| `getItemLimit(slot)` | number | Max stack size for slot (64) |
| `getUraniniteSlot()` | table | Detailed info for uraninite slot |
| `getCarbonSlot()` | table | Detailed info for carbon slot |
| `getRedstoneSlot()` | table | Detailed info for redstone slot |

#### Tank Methods
| Method | Returns | Description |
|--------|---------|-------------|
| `tanks()` | table | Array of tank contents |

**Tank Structure:**
```lua
tanks()[1] = {
    name = "cognition:cognitium_source",  -- Fluid type
    amount = 1000                          -- Current amount in mB
}
```

#### Item Transfer Methods (not used in this program)
| Method | Description |
|--------|-------------|
| `pullItems()` | Pull items from adjacent inventory |
| `pushItems()` | Push items to adjacent inventory |
| `pullFluid()` | Pull fluid from adjacent tank |
| `pushFluid()` | Push fluid to adjacent tank |

### Inventory Slot Layout
| Slot | Purpose | Contents |
|------|---------|----------|
| 1 | Charging | Batteries and energy items (ignored by monitor) |
| 2 | Fuel | Uraninite |
| 3 | Carbon | Coal (or other carbon source) |
| 4 | Redstone | Redstone dust |
| 5 | Solid Coolant | Snowballs (or other solid coolant) |

### Temperature Conversion
- **API Value:** 0 to 100
- **Display Value:** 0°C to 1000°C
- **Formula:** `displayTemp = getTemperature() * 10`

### Reactor Behavior Notes
- Reactor does not explode at high temperatures
- Lower temperatures provide better efficiency
- Reactor has auto-mode: stops when energy storage is full, restarts at 70% if redstone signal is present
- Redstone signal ON = reactor enabled, OFF = reactor disabled

---

## Program Behavior

### Redstone Control

The program outputs a redstone signal to the **top** side to control the reactor. 

| Condition | Redstone Output | Result |
|-----------|-----------------|--------|
| All resources ≥ 50% | ON | Reactor enabled |
| Any resource < 50% | OFF | Reactor disabled |

**Resource Thresholds for Shutdown:**
| Resource | Source | Shutdown Threshold |
|----------|--------|-------------------|
| Uraninite | Slot 2 count | < 32 items |
| Coal | Slot 3 count | < 32 items |
| Redstone | Slot 4 count | < 32 items |
| Solid Coolant | Slot 5 count | < 32 items |
| Liquid Coolant | tanks()[1].amount | < 500 mB |

### Status Detection Logic

```lua
if isRunning() then
    status = "RUNNING"      -- Green
elseif getStoredEnergy() >= getEnergyCapacity() then
    status = "PAUSED"       -- Yellow (auto-stopped, full)
else
    status = "STOPPED"      -- Red (stopped due to problem)
end
```

### Net Energy Calculation

Since no direct FE/t method exists, calculate from storage change:

```lua
local deltaEnergy = currentStoredEnergy - lastStoredEnergy
local deltaTime = currentTime - lastTime
local netFEPerTick = deltaEnergy / (deltaTime * 20)  -- 20 ticks/second
```

- **Current:** Most recent calculated value
- **Average:** Rolling average over approximately 60 seconds

**Note:** This shows NET energy (generation minus consumption).  Value may be negative if consumption exceeds generation.

---

## Display Specification

### Color Scheme

#### Status Colors
| Status | Color |
|--------|-------|
| RUNNING | Green |
| PAUSED | Yellow |
| STOPPED | Red |

#### Temperature Colors
| API Value | Temperature | Color |
|-----------|-------------|-------|
| 0 - 25 | 0°C - 250°C | Green (coldest 25%) |
| 25. 1 - 75 | 250°C - 750°C | Yellow (middle 50%) |
| 75.1 - 100 | 750°C - 1000°C | Red (hottest 25%) |

#### Resource Colors (Slot Items)
| Count | Percentage | Color |
|-------|------------|-------|
| 64 | 100% | Green |
| 32 - 63 | 50% - 98% | Yellow |
| 0 - 31 | 0% - 49% | Red |

#### Liquid Coolant Colors
| Amount | Percentage | Color |
|--------|------------|-------|
| 800 - 1000 mB | 80% - 100% | Green |
| 500 - 799 mB | 50% - 79% | Yellow |
| 0 - 499 mB | 0% - 49% | Red |

#### Energy Storage Bar
| Element | Color |
|---------|-------|
| Filled portion | Blue |
| Empty portion | Gray |

### Energy Formatting

Display large numbers with K and M suffixes:

| Value | Display |
|-------|---------|
| 0 - 999 | "0 FE" |
| 1,000 - 999,999 | "1. 0K FE" |
| 1,000,000+ | "1.0M FE" |

### Screen Layout (29 × 26 characters)

```
-----------------------------
|       REACTOR STATUS        |  Line 1: Title (centered)
|          RUNNING            |  Line 2: Status (centered, color coded)
|-----------------------------|  Line 3: Separator
| Temp: 166.0°C               |  Line 4: Temperature (color coded)
|-----------------------------|  Line 5: Separator
| RESOURCES                   |  Line 6: Section header
| Uraninite:  100%            |  Line 7: Slot 2 (color coded)
| Coal:       100%            |  Line 8: Slot 3 (color coded)
| Redstone:   100%            |  Line 9: Slot 4 (color coded)
| Solid:      100%            |  Line 10: Slot 5 (color coded)
| Coolant:    100%            |  Line 11: Liquid tank (color coded)
|-----------------------------|  Line 12: Separator
| NET ENERGY OUTPUT           |  Line 13: Section header
| Current:  +10. 2K FE/t       |  Line 14: Current net FE/t
| Average:  +9.8K FE/t        |  Line 15: 60-second average
|-----------------------------|  Line 16: Separator
| ENERGY STORAGE              |  Line 17: Section header
| [############............ ] |  Line 18: Progress bar (blue)
| 12.5M / 25. 0M FE            |  Line 19: Current / Max
|                             |  Line 20: Empty
|           50.0%             |  Line 21: Percentage (centered)
|                             |  Lines 22-26: Empty/Reserved
-----------------------------
```

---

## Telemetry Specification

### Communication Protocol
- **Method:** Rednet via Ender Modem
- **Modem Location:** bottom
- **Protocol Name:** `"reactor_telemetry"`
- **Transmission Frequency:** Same as display refresh rate

### Data Packet Structure

```lua
{
    id = "reactor_01",           -- Unique reactor identifier (string)
    status = "running",          -- "running" | "paused" | "stopped"
    temperature = 16.6,          -- Raw API value (0-100)
    storedEnergy = 12500000,     -- Current stored energy (FE)
    maxEnergy = 25000000,        -- Maximum capacity (FE)
    netFET = 10200,              -- Current net FE/t (number, can be negative)
    avgFET = 9800,               -- 60-second average FE/t (number)
    resources = {
        uraninite = 64,          -- Slot 2 count (0-64)
        coal = 64,               -- Slot 3 count (0-64)
        redstone = 64,           -- Slot 4 count (0-64)
        solid = 64,              -- Slot 5 count (0-64)
        coolant = 1000           -- Tank amount (0-1000 mB)
    },
    alerts = {},                 -- Array of active alert strings
    timestamp = 1732968000000    -- os.epoch("utc") value
}
```

### Alert Types

| Alert String | Trigger Condition |
|--------------|-------------------|
| `"low_uraninite"` | Slot 2 count < 32 |
| `"low_coal"` | Slot 3 count < 32 |
| `"low_redstone"` | Slot 4 count < 32 |
| `"low_solid"` | Slot 5 count < 32 |
| `"low_coolant"` | Tank amount < 500 mB |
| `"high_temp"` | Temperature > 75 (750°C) |
| `"stopped"` | Reactor stopped unexpectedly |

### Telemetry Usage

Each reactor computer:
1. Opens rednet on bottom modem
2. Collects all reactor data
3. Broadcasts packet with protocol `"reactor_telemetry"`
4. Central display receives and aggregates from all reactors

---

## Configuration Constants

```lua
-- Peripheral locations
local REACTOR_SIDE = "top"
local MONITOR_NAME = "monitor_0"
local REDSTONE_OUTPUT_SIDE = "top"
local TELEMETRY_MODEM_SIDE = "bottom"

-- Telemetry
local REACTOR_ID = "reactor_01"  -- Unique per reactor
local TELEMETRY_PROTOCOL = "reactor_telemetry"

-- Tank capacity (not provided by API)
local COOLANT_TANK_CAPACITY = 1000  -- mB

-- Resource thresholds (item counts)
local SLOT_WARNING_THRESHOLD = 63   -- Yellow if below this
local SLOT_CRITICAL_THRESHOLD = 32  -- Red if below this

-- Coolant thresholds (mB)
local COOLANT_WARNING_THRESHOLD = 800   -- Yellow if below (80%)
local COOLANT_CRITICAL_THRESHOLD = 500  -- Red if below (50%)

-- Temperature thresholds (API value 0-100)
local TEMP_GREEN_MAX = 25    -- Green: 0-25 (0-250°C)
local TEMP_YELLOW_MAX = 75   -- Yellow: 25-75 (250-750°C)
                             -- Red: 75-100 (750-1000°C)

-- Redstone control threshold (50%)
local SHUTDOWN_ITEM_THRESHOLD = 32      -- Items
local SHUTDOWN_COOLANT_THRESHOLD = 500  -- mB

-- Energy averaging
local AVERAGE_WINDOW_SECONDS = 60
```

---

## Future Considerations

1. **Central Display:** A separate computer will receive telemetry from all 12+ reactors and display aggregate status
2. **Solid Coolant Types:** Currently snowballs, but may change - program should handle any item in slot 5
3. **Liquid Coolant Types:** Currently cognitium, but may be upgraded
4. **Refresh Rate:** To be determined during testing
5. **Additional Reactors:** System designed to scale to 12+ reactors

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-30 | 1.0 | Initial design document |
