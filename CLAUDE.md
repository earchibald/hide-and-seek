# Hide & Seek — project guidance

## Approval process

Before an issue is considered ready for the `/op:resolve` approval step, a build must be deployed to **EA16** (the user's paired iPhone 16, identifier `83848554-306E-5E1F-B6FA-95162E164770`). A simulator build is not sufficient.

Typical command:

```bash
xcodebuild -project HideAndSeekiOS/HideAndSeek.xcodeproj \
  -scheme HideAndSeek \
  -destination 'id=83848554-306E-5E1F-B6FA-95162E164770' \
  build
xcrun devicectl device install app --device EA16 <path-to-.app>
xcrun devicectl device process launch --device EA16 <bundle-id>
```

Include the install + launch as part of the approval request so the user can confirm on-device behavior before the issue is moved to `RESOLVED ISSUES/`.
