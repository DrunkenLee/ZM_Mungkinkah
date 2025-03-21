--***********************************************************
--**                    BLACKSMITH UI CONTROLLER           **
--***********************************************************

if isServer() then
  return
end

if not getBlacksmithUIInstance then
  require('shared/BlacksmithUtils')
end

local BlacksmithUI = getBlacksmithUIInstance()

-- Function to toggle the Blacksmith UI visibility
function toggleBlacksmithUI()
  if BlacksmithUI.isVisible then
      if ISBlacksmithUI.instance then
          ISBlacksmithUI.instance:close()
      end
      BlacksmithUI.isVisible = false
  else
      showBlacksmithUI()
  end
end

-- Function to show the Blacksmith UI
function showBlacksmithUI()
  if not BlacksmithUI.isVisible then
      local window = ISBlacksmithUI:new(
          (getCore():getScreenWidth() / 2) - 150,
          (getCore():getScreenHeight() / 2) - 200,
          300,
          400,
          function() BlacksmithUI.isVisible = false end
      )
      window:initialise()
      window:addToUIManager()
      BlacksmithUI.isVisible = true
  end
end

-- Function to hide the Blacksmith UI
function hideBlacksmithUI()
  if BlacksmithUI.isVisible and ISBlacksmithUI.instance then
      ISBlacksmithUI.instance:close()
  end
end

-- Exports
BlacksmithUI.toggle = toggleBlacksmithUI
BlacksmithUI.show = showBlacksmithUI
BlacksmithUI.hide = hideBlacksmithUI