tell application "System Events"
    tell process "Simulator"
        -- Make sure Simulator is frontmost
        set frontmost to true
        delay 1
        
        -- Click on the Home button to go to home screen
        key code 36 using command down
        delay 1
        
        -- Look for and click on JubileeMobileBay app
        -- The app should be visible on the home screen
        click at {200, 400}
        delay 2
    end tell
end tell
