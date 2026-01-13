-- Make links GLOBAL (remove 'local') so they persist!
r_link = nil
l_link = nil
mic_node = nil
target_node = nil

-- Simplified: Match by media class and check node name in the callback
mic_om = ObjectManager {
    Interest {
        type = "node",
        Constraint { "media.class", "equals", "Audio/Source" },
    }
}

target_om = ObjectManager {
    Interest {
        type = "node",
        Constraint { "node.name", "matches", "clean-mic-line-in" },
    }
}

-- ObjectManager to monitor existing links
link_om = ObjectManager {
    Interest {
        type = "link"
    }
}

function checkAndLink()
    -- Check if links already exist and are valid
    if l_link and l_link["bound-id"] and l_link["bound-id"] ~= -1 and
       r_link and r_link["bound-id"] and r_link["bound-id"] ~= -1 then
        print("Fifine Script: Links already exist (created by us), skipping...")
        return
    end

    if mic_node and target_node then
        local mic_id = mic_node["bound-id"]
        local target_id = target_node["bound-id"]
        
        if not mic_id or not target_id then
            print("Fifine Script: Nodes not bound yet...")
            return
        end
        
        -- CHECK IF LINKS ALREADY EXIST between these nodes!
        local existing_link_count = 0
        for link in link_om:iterate() do
            local out_node = tonumber(link.properties["link.output.node"])
            local in_node = tonumber(link.properties["link.input.node"])
            if out_node == mic_id and in_node == target_id then
                existing_link_count = existing_link_count + 1
                print("Fifine Script: Found existing link between nodes!")
            end
        end
        
        if existing_link_count >= 2 then
            print("Fifine Script: Both stereo links already exist (created elsewhere), nothing to do!")
            return
        end
        
        print("Fifine Script: Nodes confirmed.")
        print("   > Source: " .. (mic_node.properties["node.nick"] or mic_node.properties["node.name"]))
        print("   > Target: " .. target_node.properties["node.name"])
        print("   > Existing links: " .. existing_link_count .. "/2")
        print("   > Action: Creating " .. (2 - existing_link_count) .. " link(s)...")

        -- Only create links we need
        if existing_link_count < 1 then
            l_link = Link("link-factory", {
                ["link.output.node"] = mic_id,
                ["link.input.node"] = target_id,
                ["object.linger"] = 1
            })
            
            -- Use simple activation without callback!
            l_link:activate(1)
            print("Link #1 created and activated")
        end
        
        if existing_link_count < 2 then
            r_link = Link("link-factory", {
                ["link.output.node"] = mic_id,
                ["link.input.node"] = target_id,
                ["object.linger"] = 1
            })
            
            -- Use simple activation without callback!
            r_link:activate(1)
            print("Link #2 created and activated")
        end
    else
        local mic_status = mic_node and "Found" or "MISSING"
        local target_status = target_node and "Found" or "MISSING"
        print("Fifine Script: Waiting... Mic: [" .. mic_status .. "] | Target: [" .. target_status .. "]")
    end
end

target_om:connect("object-added", function(_, node)
    print("Target added: " .. node.properties["node.name"])
    target_node = node
    checkAndLink()
end)

target_om:connect("object-removed", function(_, node)
    if target_node == node then
        print("Target removed: " .. node.properties["node.name"])
        target_node = nil
        l_link = nil
        r_link = nil
    end
end)

mic_om:connect("object-added", function(_, node)
    local node_name = node.properties["node.name"] or "UNNAMED"
    print("Mic OM caught: " .. node_name)
    
    -- Only set mic_node if it matches our Fifine mic
    if node_name:match("3142_fifine_Microphone") then
        print("Mic added: " .. (node.properties["node.nick"] or node.properties["node.name"]))
        mic_node = node
        checkAndLink()
    end
end)

mic_om:connect("object-removed", function(_, node)
    if mic_node == node then
        print("Mic removed: " .. (node.properties["node.nick"] or node.properties["node.name"]))
        mic_node = nil
        l_link = nil
        r_link = nil
    end
end)

-- Add debug logging to see ALL nodes
debug_om = ObjectManager {
    Interest {
        type = "node",
        Constraint { "media.class", "equals", "Audio/Source" }
    }
}

debug_om:connect("object-added", function(_, node)
    print("DEBUG: Audio source node added: " .. (node.properties["node.name"] or "UNNAMED"))
end)

debug_om:activate()
link_om:activate()
target_om:activate()
mic_om:activate()

-- CRITICAL: Check for nodes that ALREADY EXIST before the script loaded!
Core.sync(function()
    print("Fifine Script: Checking for existing nodes after activation...")
    
    -- Check if target already exists
    for target in target_om:iterate() do
        if not target_node then
            print("Found existing target: " .. target.properties["node.name"])
            target_node = target
        end
    end
    
    -- Check if mic already exists
    for node in mic_om:iterate() do
        local node_name = node.properties["node.name"] or "UNNAMED"
        if node_name:match("3142_fifine_Microphone") and not mic_node then
            print("Found existing mic: " .. node_name)
            mic_node = node
        end
    end
    
    -- Try to link if both exist
    checkAndLink()
end)

print("Fifine Script: Loaded and monitoring for nodes...")

