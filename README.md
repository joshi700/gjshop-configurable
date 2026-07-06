# GJShop Configurable

SwiftUI e-commerce demo app with a **configurable Mastercard Hosted Checkout (HCO)** integration.
Version 2.0 of the GJShop demo: the same native shopping flow, plus an in-app **API Configuration**
module so the app can be pointed at *any* MPGS merchant profile without rebuilding anything.

Companion backend: [gjshop-configurable-backend](https://github.com/joshi700/gjshop-configurable-backend)
— a stateless proxy that signs and forwards whatever gateway configuration the app sends.

## Features

- Product catalogue → cart → checkout → **MPGS Hosted Checkout** in a WKWebView → receipt
- Deep-link return from the hosted page (`myapp://receipt`)
- **Settings → API Configuration**: Merchant ID, auto-generated API username, masked API password
  (stored in the iOS **Keychain**), gateway base URL, API version, TEST/LIVE badge, Test Connection,
  Reset to Defaults
- **Advanced JSON mode**: edit the raw `INITIATE_CHECKOUT` payload (fresh `order.id` / live cart
  `order.amount` injected at request time), Copy JSON / Copy as cURL (password redacted)
- **Server-side payment verification**: the receipt only shows success after the backend confirms
  the order via `RETRIEVE_ORDER`, and the deep link's `resultIndicator` is compared with the
  session's `successIndicator`
- Real cart total sent to the gateway; configuration persists across launches

## Requirements

- Xcode 16+ (project generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen))
- The companion backend running locally (`node server.js`, port 3002) or deployed on Vercel

## Getting started

```bash
brew install xcodegen   # once
xcodegen generate       # regenerates GJShop_Configurable.xcodeproj from project.yml
open GJShop_Configurable.xcodeproj
```

Build and run on an iPhone simulator. Out of the box the app talks to the backend configured in
`ConfigStore.swift`; change the **Backend URL** in Settings to your own deployment or
`http://<your-mac-LAN-ip>:3002` for a physical device.

To run real MTF test payments, enter your gateway **API password** in Settings (kept in the
Keychain), or configure `API_PASSWORD` on the backend as a fallback.

> **Note** — credentials are intended for gateway TEST/demo profiles. Passing merchant API
> credentials through a demo backend is not a production pattern.
