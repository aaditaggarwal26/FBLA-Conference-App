#!/bin/bash

# Reset iOS Simulator Permissions
# Run this script when you need to test permission flows from scratch

echo "🔄 Resetting iOS Simulator permissions..."

# For iOS Simulator
if command -v xcrun &> /dev/null; then
    echo "📱 Shutting down iOS Simulator..."
    xcrun simctl shutdown all
    
    echo "🗑️  Erasing all content and settings..."
    xcrun simctl erase all
    
    echo "✅ iOS Simulator permissions reset complete!"
    echo ""
    echo "Next steps:"
    echo "1. Rebuild and run your app: flutter run"
    echo "2. When prompted, allow location and camera permissions"
    echo ""
else
    echo "❌ xcrun not found. Make sure Xcode is installed."
fi

# Alternative: Reset permissions for specific bundle ID
# Uncomment and modify the bundle ID if needed
# BUNDLE_ID="com.example.fblaConferenceApp"
# xcrun simctl privacy booted revoke location $BUNDLE_ID
# xcrun simctl privacy booted revoke camera $BUNDLE_ID
# echo "✅ Permissions reset for $BUNDLE_ID"
