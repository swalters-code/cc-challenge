-- Wrap the chest as a peripheral. The side is "top" in this case.
local chest = peripheral.wrap("top")

-- Check if a chest was successfully wrapped
if not chest then
    print("Error: No inventory peripheral found above the computer.")
    return
end

-- Get the detailed information for the item in slot 1
-- The slot number for the first slot is 1
local itemDetails = chest.getItemDetail(1)

-- Check if there is an item in the specified slot
if itemDetails then
    print("Item Details in Slot 1:")
    print("------------------------")
    
    -- Print the NBT Hash using a robust fallback mechanism
    print("NBT Hash: " .. (itemDetails.nbtHash or itemDetails.nbthash or "N/A"))

    -- Print the display name, defaulting to the registry name if no custom name exists
    print("Display Name: " .. (itemDetails.displayName or itemDetails.name))
    
    -- Print damage and maxDamage if the item is damageable (e.g., tools, armor)
    if itemDetails.maxDamage then
        print(string.format("Damage: %d/%d", itemDetails.damage, itemDetails.maxDamage))
    else
        print("Damage: N/A (Item is not damageable)")
    end
    
    -- Print enchantments if they exist
    if itemDetails.enchantments and #itemDetails.enchantments > 0 then
        print("Enchantments:")
        -- Iterate over the enchantments table and print each one
        for _, enchantment in pairs(itemDetails.enchantments) do
            print(string.format("  * %s (Level %d)", enchantment.name, enchantment.level))
        end
    elseif itemDetails.enchantments then
      -- If it's an enchanted book, the enchantments might be under a different structure or empty if no enchants
      -- A standard enchanted item will have the structure above.
      print("Enchantments: None listed")
    else
        print("Enchantments: N/A")
    end

else
    print("Slot 1 is empty.")
end
